#!/usr/bin/env bash
# tests/test_resilience.sh — Resilience tests against external corruption
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

source_gitsetu_libs

test_survives_malformed_gitconfig() {
    GITSETU_DRY_RUN=0
    
    PROFILE_COUNT=1
    PROFILE_LABELS=("global")
    PROFILE_NAMES=("Test")
    PROFILE_EMAILS=("global@test.com")
    PROFILE_DIRS=("")
    PROFILE_PROVIDERS=("github.com")
    PROFILE_SIGNS=("0")
    PROFILE_KEYS=("$HOME/.ssh/id_ed25519_global")

    # Create a corrupted gitconfig
    cat > "$HOME/.gitconfig" <<'EOF'
[alias]
    co = checkout
    st = status

# This section is missing a closing bracket
[core
    editor = vim

[user]
    name = Old
    email = old@test.com
EOF

    # The awk script should safely append the managed block and preserve the bad syntax
    write_global_gitconfig 2>/dev/null
    
    assert_file_exists "$HOME/.gitconfig" "gitconfig preserved"
    assert_file_contains "$HOME/.gitconfig" "co = checkout" "preserves valid data"
    assert_file_contains "$HOME/.gitconfig" "\[core" "preserves malformed data"
    assert_file_contains "$HOME/.gitconfig" "useConfigOnly = true" "successfully appends managed block"
}

test_survives_mismatched_managed_markers() {
    GITSETU_DRY_RUN=0
    
    PROFILE_COUNT=1
    PROFILE_LABELS=("global")
    PROFILE_NAMES=("Test")
    PROFILE_EMAILS=("global@test.com")
    PROFILE_DIRS=("")

    # Create a gitconfig with a start marker but no end marker
    cat > "$HOME/.gitconfig" <<EOF
[alias]
    st = status
${GITSETU_MANAGED_START}
[user]
    name = Bad Block
EOF

    write_global_gitconfig 2>/dev/null
    
    assert_file_contains "$HOME/.gitconfig" "st = status" "preserves user block"
    assert_file_contains "$HOME/.gitconfig" "useConfigOnly = true" "replaces broken managed block with valid one"
    assert_file_contains "$HOME/.gitconfig" "${GITSETU_MANAGED_END}" "adds missing end marker"
    assert_file_not_contains "$HOME/.gitconfig" "Bad Block" "cleans up broken block contents"
}

printf '\n%btest_resilience.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "survives malformed syntax in ~/.gitconfig" test_survives_malformed_gitconfig
run_test "survives missing managed end marker" test_survives_mismatched_managed_markers
print_results "Resilience tests"
