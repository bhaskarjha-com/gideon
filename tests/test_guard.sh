#!/usr/bin/env bash
# tests/test_guard.sh — Tests for lib/guard.sh
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

source_gitsetu_libs

# --- Helpers ---
setup_repo() {
    local dir="$1"
    mkdir -p "$dir"
    git -C "$dir" init --quiet
}

# --- Tests ---
test_install_guard() {
    GITSETU_DRY_RUN=0
    install_guard 2>/dev/null
    
    assert_file_exists "$GITSETU_HOOKS_DIR/pre-commit" "hook file created" || return 1
    local hooks_path
    hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")
    assert_equals "$GITSETU_HOOKS_DIR" "$hooks_path" "core.hooksPath set globally" || return 1
}

test_guard_blocks_mismatch() {
    GITSETU_DRY_RUN=0
    # Mock profiles.conf
    mkdir -p "$(dirname "$GITSETU_PROFILES_CONF")"
    echo "work:work@example.com:$HOME/work:github.com:0:" > "$GITSETU_PROFILES_CONF"
    
    install_guard 2>/dev/null
    
    setup_repo "$HOME/work"
    git -C "$HOME/work" config user.email "wrong@example.com"
    git -C "$HOME/work" config user.name "Test"
    
    touch "$HOME/work/test.txt"
    git -C "$HOME/work" add test.txt
    
    local output
    output=$(git -C "$HOME/work" commit -m "Test" 2>&1 || echo "FAILED")
    
    assert_contains "$output" "Identity mismatch detected" "hook blocks mismatch" || return 1
}

test_guard_allows_match() {
    GITSETU_DRY_RUN=0
    mkdir -p "$(dirname "$GITSETU_PROFILES_CONF")"
    echo "work:work@example.com:$HOME/work:github.com:0:" > "$GITSETU_PROFILES_CONF"
    
    install_guard 2>/dev/null
    
    setup_repo "$HOME/work"
    git -C "$HOME/work" config user.email "work@example.com"
    git -C "$HOME/work" config user.name "Test"
    
    touch "$HOME/work/test.txt"
    git -C "$HOME/work" add test.txt
    
    local output
    # Git requires author/committer names, provide env to satisfy it since no global config
    output=$(GIT_AUTHOR_NAME="T" GIT_AUTHOR_EMAIL="work@example.com" GIT_COMMITTER_NAME="T" GIT_COMMITTER_EMAIL="work@example.com" git -C "$HOME/work" commit -m "Test" 2>&1 || echo "FAILED")
    
    assert_not_contains "$output" "Identity mismatch detected" "hook allows match" || return 1
}

test_guard_pass_through() {
    GITSETU_DRY_RUN=0
    mkdir -p "$(dirname "$GITSETU_PROFILES_CONF")"
    echo "work:work@example.com:$HOME/work:github.com:0:" > "$GITSETU_PROFILES_CONF"
    install_guard 2>/dev/null
    
    setup_repo "$HOME/work"
    git -C "$HOME/work" config user.email "work@example.com"
    git -C "$HOME/work" config user.name "Test"
    
    # Create local hook
    mkdir -p "$HOME/work/.git/hooks"
    cat > "$HOME/work/.git/hooks/pre-commit" <<'EOF'
#!/bin/bash
echo "LOCAL HOOK PASSTHROUGH SUCCESS"
exit 0
EOF
    chmod +x "$HOME/work/.git/hooks/pre-commit"
    
    touch "$HOME/work/test2.txt"
    git -C "$HOME/work" add test2.txt
    
    local output
    output=$(GIT_AUTHOR_NAME="T" GIT_AUTHOR_EMAIL="work@example.com" GIT_COMMITTER_NAME="T" GIT_COMMITTER_EMAIL="work@example.com" git -C "$HOME/work" commit -m "Test 2" 2>&1 || echo "FAILED")
    
    assert_contains "$output" "LOCAL HOOK PASSTHROUGH SUCCESS" "local hook ran" || return 1
}

printf '\n%btest_guard.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "install_guard links hook" test_install_guard
run_test "guard blocks mismatched email" test_guard_blocks_mismatch
run_test "guard allows matched email" test_guard_allows_match
run_test "guard passes through to local hooks" test_guard_pass_through
print_results "Guard tests"
