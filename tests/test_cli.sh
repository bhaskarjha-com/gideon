#!/usr/bin/env bash
# tests/test_cli.sh — CLI argument parsing tests for gitsetu entrypoint
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

# We need the path to the actual executable
GITSETU_EXE="$(dirname "${BASH_SOURCE[0]}")/../gitsetu"
GITSETU_EXE="${GITSETU_EXE%$'\r'}"

test_cli_no_args_shows_help() {
    local output
    output=$("$GITSETU_EXE" 2>&1 || true)
    assert_contains "$output" "Usage:" "no args prints usage"
}

test_cli_invalid_command() {
    local output
    output=$("$GITSETU_EXE" fakecmd 2>&1 || true)
    assert_contains "$output" "Unknown command" "catches invalid command"
    assert_exit_code 1 "$GITSETU_EXE" fakecmd
}

test_cli_add_missing_args() {
    local output
    output=$("$GITSETU_EXE" add 2>&1 || true)
    assert_contains "$output" "Missing arguments for add" "catches missing args"
    assert_exit_code 1 "$GITSETU_EXE" add
}

test_cli_add_invalid_label() {
    local output
    output=$("$GITSETU_EXE" add "bad label" "Name" "email@test.com" "$HOME/dir" 2>&1 || true)
    assert_contains "$output" "Invalid label" "catches invalid label format"
    assert_exit_code 1 "$GITSETU_EXE" add "bad label" "Name" "email@test.com" "$HOME/dir"
}

test_cli_remove_invalid_arg() {
    local output
    output=$("$GITSETU_EXE" remove 2>&1 || true)
    assert_contains "$output" "Usage: gitsetu remove" "catches missing arg for remove"
    assert_exit_code 1 "$GITSETU_EXE" remove
}

test_cli_help_flag() {
    local output
    output=$("$GITSETU_EXE" --help 2>&1 || true)
    assert_contains "$output" "USAGE" "prints help"
    assert_exit_code 0 "$GITSETU_EXE" --help
}

printf '\n%btest_cli.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "no arguments shows help" test_cli_no_args_shows_help
run_test "invalid command caught" test_cli_invalid_command
run_test "add with missing args caught" test_cli_add_missing_args
run_test "add with invalid label caught" test_cli_add_invalid_label
run_test "remove with missing args caught" test_cli_remove_invalid_arg
run_test "--help prints menu and exits 0" test_cli_help_flag
print_results "CLI tests"
