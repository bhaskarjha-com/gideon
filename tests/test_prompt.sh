#!/usr/bin/env bash
# tests/test_prompt.sh — Tests for the sub-millisecond PS1 prompt integration
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

GITSETU_EXE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/gitsetu"
GITSETU_EXE="${GITSETU_EXE%$'\r'}"

test_prompt_empty_registry() {
    # Ensure it doesn't crash when no registry exists
    local output
    output=$(bash "$GITSETU_EXE" prompt)
    assert_equals "" "$output" "returns empty string when no registry exists" || return 1
}

test_prompt_matching() {
    mkdir -p "$HOME/.config/gitsetu"
    
    # Create a registry with overlapping paths
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
global::/invalid:github.com:0:
work::$HOME/work:github.com:0:
freelance::$HOME/work/freelance:github.com:0:
EOF

    # Test work dir
    mkdir -p "$HOME/work/api"
    cd "$HOME/work/api"
    local out1
    out1=$(bash "$GITSETU_EXE" prompt)
    assert_equals "work" "$out1" "matches work profile" || return 1

    # Test freelance dir (longest match wins)
    mkdir -p "$HOME/work/freelance/ui"
    cd "$HOME/work/freelance/ui"
    local out2
    out2=$(bash "$GITSETU_EXE" prompt)
    assert_equals "freelance" "$out2" "longest match wins for freelance profile" || return 1

    # Test unmapped dir
    mkdir -p "$HOME/personal"
    cd "$HOME/personal"
    local out3
    out3=$(bash "$GITSETU_EXE" prompt)
    assert_equals "" "$out3" "returns empty string for unmapped directory" || return 1
}

printf '\n%btest_prompt.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "prompt empty registry safely" test_prompt_empty_registry
run_test "prompt dynamic path matching" test_prompt_matching
print_results "Prompt tests"
