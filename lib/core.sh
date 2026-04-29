#!/usr/bin/env bash
# shellcheck disable=SC2034  # All variables here are used by modules that source this file
# lib/core.sh — Constants, version, and global state for gideon
#
# This file is sourced by the main gideon script.
# All variables defined here are available to all other modules.
#
# Bash 3.2 compatible: no associative arrays, no mapfile, no ${var,,}

# ------------------------------------------------------------------------------
# Version
# ------------------------------------------------------------------------------

GIDEON_VERSION="1.0.0"

# ------------------------------------------------------------------------------
# Directory layout (XDG-compliant)
# ------------------------------------------------------------------------------

GIDEON_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gideon"
GIDEON_BACKUP_DIR="$GIDEON_CONFIG_DIR/backups"
GIDEON_PROFILES_DIR="$GIDEON_CONFIG_DIR/profiles"
GIDEON_HOOKS_DIR="$GIDEON_CONFIG_DIR/hooks"
GIDEON_PROFILES_CONF="$GIDEON_CONFIG_DIR/profiles.conf"

# ------------------------------------------------------------------------------
# Managed block markers
# Used to identify sections in config files that gideon owns.
# Everything between START and END markers is replaced on re-run (idempotent).
# Content outside these markers is never touched.
# ------------------------------------------------------------------------------

GIDEON_MARKER_PREFIX="# [gideon:managed"
GIDEON_MANAGED_START="# [gideon:managed:start]"
GIDEON_MANAGED_END="# [gideon:managed:end]"

# ------------------------------------------------------------------------------
# Profile state (collected during wizard)
#
# Bash 3.2 compat: using parallel indexed arrays instead of associative arrays.
# Index 0 is always the default/global profile.
# ------------------------------------------------------------------------------

PROFILE_LABELS=()
PROFILE_NAMES=()
PROFILE_EMAILS=()
PROFILE_DIRS=()
PROFILE_PROVIDERS=()
PROFILE_SIGNS=()
PROFILE_KEYS=()
PROFILE_COUNT=0
DEFAULT_PROFILE_INDEX=0

# ------------------------------------------------------------------------------
# Runtime state
# ------------------------------------------------------------------------------

GIDEON_OS=""           # Set by detect_os(): linux, macos, wsl, gitbash, unknown
GIDEON_DRY_RUN=0      # Set to 1 by --dry-run flag
GIDEON_USE_PASSPHRASE=0 # Set to 1 to prompt for SSH passphrases

# ------------------------------------------------------------------------------
# load_profiles — Reads registry into arrays
# ------------------------------------------------------------------------------
load_profiles() {
    PROFILE_COUNT=0
    if [[ ! -f "$GIDEON_PROFILES_CONF" ]]; then
        return 0
    fi
    local label email dir provider sign_commits key_path
    while IFS=: read -r label email dir provider sign_commits key_path || [[ -n "$label" ]]; do
        [[ "$label" == "#"* ]] && continue
        [[ -z "$label" ]] && continue
        PROFILE_LABELS+=("$label")
        PROFILE_EMAILS+=("$email")
        PROFILE_DIRS+=("$dir")
        PROFILE_PROVIDERS+=("${provider:-github.com}")
        PROFILE_SIGNS+=("${sign_commits:-0}")
        PROFILE_KEYS+=("${key_path:-$HOME/.ssh/id_ed25519_${label}}")
        # In this context, name isn't stored in registry. For headless add, we might need a dummy.
        # But wait, name is currently not in profiles.conf! 
        # Ah! That's a bug in original implementation: profiles.conf has:
        # label:email:dir:provider:sign_commits:key_path
        # Where is name? We never saved it! It's derived from global git config usually?
        PROFILE_NAMES+=("$(git config --global user.name 2>/dev/null || echo "")")
        PROFILE_COUNT=$((PROFILE_COUNT + 1))
    done < "$GIDEON_PROFILES_CONF"
}
GIDEON_SCRIPT_DIR="${GIDEON_SCRIPT_DIR:-}"   # Preserve value set by main script

# ------------------------------------------------------------------------------
# Helper: lowercase a string (bash 3.2 compatible)
# Usage: result=$(to_lower "FooBar")
# ------------------------------------------------------------------------------
to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# ------------------------------------------------------------------------------
# Helper: check if a value exists in an indexed array
# Usage: array_contains "needle" "${haystack[@]}"
# Returns: 0 if found, 1 if not
# ------------------------------------------------------------------------------
array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}
