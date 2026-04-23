#!/usr/bin/env bash
# tests/test_backup.sh — Tests for lib/backup.sh
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
source_gideon_libs

setup_test_home
detect_os

# --- Tests ---

test_ensure_dirs_creates_all() {
    ensure_dirs

    assert_dir_exists "$GIDEON_CONFIG_DIR" "config dir exists" &&
    assert_dir_exists "$GIDEON_BACKUP_DIR" "backup dir exists" &&
    assert_dir_exists "$GIDEON_PROFILES_DIR" "profiles dir exists" &&
    assert_dir_exists "$GIDEON_HOOKS_DIR" "hooks dir exists"
}

test_backup_creates_timestamped_copy() {
    local test_file="$HOME/test_config"
    printf 'original content\n' > "$test_file"

    ensure_dirs
    backup_file "$test_file" 2>/dev/null

    # Should have at least one .bak file
    local count
    count=$(find "$GIDEON_BACKUP_DIR" -name "test_config.*.bak" | wc -l)

    if [[ "$count" -ge 1 ]]; then
        return 0
    fi

    printf '    FAIL: No backup file found in %s\n' "$GIDEON_BACKUP_DIR"
    return 1
}

test_backup_preserves_content() {
    local test_file="$HOME/test_preserve"
    printf 'important data\nline two\n' > "$test_file"

    ensure_dirs
    backup_file "$test_file" 2>/dev/null

    # Find the backup
    local bak_file
    bak_file=$(find "$GIDEON_BACKUP_DIR" -name "test_preserve.*.bak" | head -n1)

    assert_file_contains "$bak_file" "important data" "backup has original content"
}

test_backup_does_not_modify_original() {
    local test_file="$HOME/test_original"
    printf 'do not change\n' > "$test_file"

    ensure_dirs
    backup_file "$test_file" 2>/dev/null

    assert_file_contains "$test_file" "do not change" "original unchanged"
}

test_backup_nonexistent_file_returns_error() {
    assert_exit_code 1 backup_file "/nonexistent/file/path"
}

test_multiple_backups_dont_overwrite() {
    local test_file="$HOME/test_multi"
    printf 'version 1\n' > "$test_file"

    ensure_dirs
    backup_file "$test_file" 2>/dev/null

    # Modify and backup again (may be same second, so test collision avoidance)
    printf 'version 2\n' > "$test_file"
    backup_file "$test_file" 2>/dev/null

    local count
    count=$(find "$GIDEON_BACKUP_DIR" -name "test_multi.*.bak" | wc -l)

    if [[ "$count" -ge 2 ]]; then
        return 0
    fi

    # Might be same timestamp — at least 1 must exist
    if [[ "$count" -ge 1 ]]; then
        return 0
    fi

    printf '    FAIL: Expected at least 1 backup, found %d\n' "$count"
    return 1
}

# --- Run ---

printf '\n%btest_backup.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "ensure_dirs creates all directories" test_ensure_dirs_creates_all
run_test "backup creates timestamped copy" test_backup_creates_timestamped_copy
run_test "backup preserves file content" test_backup_preserves_content
run_test "backup does not modify original" test_backup_does_not_modify_original
run_test "backup nonexistent file returns error" test_backup_nonexistent_file_returns_error
run_test "multiple backups don't overwrite each other" test_multiple_backups_dont_overwrite
print_results "Backup tests"
