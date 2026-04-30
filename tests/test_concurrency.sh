#!/usr/bin/env bash
# tests/test_concurrency.sh — Concurrency tests for GitSetu
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

source_gitsetu_libs

test_atomic_registry_writes() {
    GITSETU_DRY_RUN=0
    
    # Simulate setup
    PROFILE_COUNT=2
    PROFILE_LABELS=("global" "pro")
    PROFILE_NAMES=("Test Global" "Test Pro")
    PROFILE_EMAILS=("global@test.com" "pro@test.com")
    PROFILE_DIRS=("" "$HOME/dev/pro")
    PROFILE_PROVIDERS=("github.com" "github.com")
    PROFILE_SIGNS=("0" "0")
    PROFILE_KEYS=("$HOME/.ssh/id_ed25519_global" "$HOME/.ssh/id_ed25519_pro")
    
    # Spawn 20 parallel writes
    local i
    for i in {1..20}; do
        write_profiles_conf 2>/dev/null &
    done
    
    wait
    
    # Verify the file is not corrupted (should have exactly 2 lines)
    local line_count
    line_count=$(wc -l < "$GITSETU_PROFILES_CONF" | tr -d ' ')
    # Actually, the file has a 3-line header. 3 header + 2 profiles = 5 lines.
    assert_equals "5" "$line_count" "profiles.conf has exactly 5 lines (no data dropped or interleaved)" || return 1
    
    assert_file_contains "$GITSETU_PROFILES_CONF" "global:global@test.com::github.com:0:$HOME/.ssh/id_ed25519_global" "has global" || return 1
    assert_file_contains "$GITSETU_PROFILES_CONF" "pro:pro@test.com:$HOME/dev/pro:github.com:0:$HOME/.ssh/id_ed25519_pro" "has pro" || return 1
}

printf '\n%btest_concurrency.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "atomic writes survive parallel execution" test_atomic_registry_writes
print_results "Concurrency tests"
