#!/usr/bin/env bash
# lib/backup.sh — Timestamped backup and restore of configuration files
#
# Ensures no data is ever lost during gideon setup.
# Bash 3.2 compatible.

# ------------------------------------------------------------------------------
# ensure_dirs — Create all required gideon directories
#
# Called at the start of setup. Idempotent.
# ------------------------------------------------------------------------------
ensure_dirs() {
    mkdir -p "$GIDEON_CONFIG_DIR" 2>/dev/null || true
    mkdir -p "$GIDEON_BACKUP_DIR" 2>/dev/null || true
    mkdir -p "$GIDEON_PROFILES_DIR" 2>/dev/null || true
    mkdir -p "$GIDEON_HOOKS_DIR" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# backup_file — Create a timestamped backup of a file
#
# Copies the file to $GIDEON_BACKUP_DIR/<basename>.<ISO-timestamp>.bak
# Preserves permissions with cp -p.
#
# Usage: backup_file "$HOME/.gitconfig"
# Returns: 0 on success, 1 if source doesn't exist
# ------------------------------------------------------------------------------
backup_file() {
    local source_path="$1"

    if [[ ! -f "$source_path" ]]; then
        return 1
    fi

    ensure_dirs

    local basename
    basename=$(basename "$source_path")

    local timestamp
    timestamp=$(date +%Y%m%dT%H%M%S)

    local backup_path="$GIDEON_BACKUP_DIR/${basename}.${timestamp}.bak"

    # Avoid overwriting if backup from same second exists (unlikely but safe)
    local counter=1
    while [[ -f "$backup_path" ]]; do
        backup_path="$GIDEON_BACKUP_DIR/${basename}.${timestamp}.${counter}.bak"
        counter=$((counter + 1))
    done

    if cp -p "$source_path" "$backup_path" 2>/dev/null; then
        print_info "Backed up: $source_path → $backup_path"
        return 0
    else
        print_error "Failed to backup: $source_path"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# list_backups — List all backups sorted by date
#
# Usage: list_backups
# ------------------------------------------------------------------------------
list_backups() {
    if [[ ! -d "$GIDEON_BACKUP_DIR" ]]; then
        print_info "No backups found."
        return 0
    fi

    local count
    count=$(find "$GIDEON_BACKUP_DIR" -name "*.bak" 2>/dev/null | wc -l)

    if [[ "$count" -eq 0 ]]; then
        print_info "No backups found."
        return 0
    fi

    print_section "Backups"
    # List files sorted by modification time, newest first
    ls -lt "$GIDEON_BACKUP_DIR"/*.bak 2>/dev/null | while IFS= read -r line; do
        printf >&2 '    %s\n' "$line"
    done
}
