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
PROFILE_COUNT=0
DEFAULT_PROFILE_INDEX=0

# ------------------------------------------------------------------------------
# Runtime state
# ------------------------------------------------------------------------------

GIDEON_OS=""           # Set by detect_os(): linux, macos, wsl, gitbash, unknown
GIDEON_DRY_RUN=0      # Set to 1 by --dry-run flag
GIDEON_USE_PASSPHRASE=0 # Set to 1 to prompt for SSH passphrases
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
