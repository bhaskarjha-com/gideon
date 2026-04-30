#!/usr/bin/env bash
# tests/test_discovery.sh — Tests for auto-discovery engine
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

source_gitsetu_libs

test_discover_global_git_identity_from_ssh() {
    # Mock missing git config but existing ssh key
    mkdir -p "$HOME/.ssh"
    echo "ssh-ed25519 AAAAC3... user@testdomain.com" > "$HOME/.ssh/id_ed25519_global.pub"
    
    # Run discovery
    discover_global_git_identity
    
    assert_equals "user@testdomain.com" "$DISCOVERED_GLOBAL_EMAIL" "extracted email from ssh pub key"
}

test_discover_global_git_identity_from_gitconfig() {
    # Create gitconfig
    cat > "$HOME/.gitconfig" <<EOF
[user]
    name = John Doe
    email = john@example.com
EOF

    discover_global_git_identity
    
    assert_equals "John Doe" "$DISCOVERED_GLOBAL_NAME" "extracted name from gitconfig"
    assert_equals "john@example.com" "$DISCOVERED_GLOBAL_EMAIL" "extracted email from gitconfig"
}

test_discover_ssh_key() {
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/id_rsa_work"
    
    local result
    result=$(discover_ssh_key_for_label "work")
    assert_equals "$HOME/.ssh/id_rsa_work" "$result" "found rsa key"
    
    # Touch ed25519, it should be preferred over rsa
    touch "$HOME/.ssh/id_ed25519_work"
    result=$(discover_ssh_key_for_label "work")
    assert_equals "$HOME/.ssh/id_ed25519_work" "$result" "prefers ed25519 over rsa"
}

test_discover_workspace_dir_fallback() {
    # Should find ~/work if it exists
    mkdir -p "$HOME/work"
    
    local result
    result=$(discover_workspace_dir "work")
    assert_equals "$HOME/work" "$result" "found workspace dir"
}

test_discover_workspace_dir_includeif() {
    # Should parse from includeIf
    mkdir -p "$HOME/random_folder"
    cat > "$HOME/.gitconfig" <<EOF
[includeIf "gitdir:~/random_folder/"]
    path = ~/.config/gitsetu/profiles/work.gitconfig
EOF

    local result
    result=$(discover_workspace_dir "work")
    assert_equals "$HOME/random_folder" "$result" "extracted from includeIf"
}

test_discover_workspace_dir_ignores_global() {
    # Should return empty for "global"
    mkdir -p "$HOME/global"
    
    local result
    result=$(discover_workspace_dir "global")
    assert_equals "" "$result" "ignores global label"
}

printf '\n%btest_discovery.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "extracts email from ssh public key" test_discover_global_git_identity_from_ssh
run_test "extracts identity from gitconfig" test_discover_global_git_identity_from_gitconfig
run_test "discovers ssh keys with priority" test_discover_ssh_key
run_test "discovers workspace fallback dirs" test_discover_workspace_dir_fallback
run_test "discovers workspace from includeIf" test_discover_workspace_dir_includeif
run_test "ignores global/default labels" test_discover_workspace_dir_ignores_global
print_results "Discovery tests"
