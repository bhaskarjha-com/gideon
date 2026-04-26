#!/usr/bin/env bash
# lib/guard.sh — Pre-commit identity guard hook
#
# Installs a global pre-commit hook that warns when the current
# git user.email doesn't match the expected profile for the directory.
# Uses core.hooksPath to apply globally (no per-repo setup needed).
# Bash 3.2 compatible.

# ------------------------------------------------------------------------------
# install_guard — Install the pre-commit identity guard hook
#
# Creates hook script in $GIDEON_HOOKS_DIR/pre-commit
# Sets git config --global core.hooksPath to point to that directory.
#
# Usage: install_guard
# ------------------------------------------------------------------------------
install_guard() {
    local hook_path="$GIDEON_HOOKS_DIR/pre-commit"

    # Check if core.hooksPath is already set to something else
    local existing_hooks_path
    existing_hooks_path=$(git config --global core.hooksPath 2>/dev/null || true)

    if [[ -n "$existing_hooks_path" ]] && [[ "$existing_hooks_path" != "$GIDEON_HOOKS_DIR" ]]; then
        print_warning "core.hooksPath is already set to: $existing_hooks_path"
        if ! confirm "Override with gideon hooks directory?" "n"; then
            print_info "Guard hook installation skipped."
            return 0
        fi
    fi

    if [[ "$GIDEON_DRY_RUN" -eq 1 ]]; then
        print_info "[DRY RUN] Would install guard hook at: $hook_path"
        print_info "[DRY RUN] Would set core.hooksPath = $GIDEON_HOOKS_DIR"
        return 0
    fi

    ensure_dirs

    # Write the hook script
    cat > "$hook_path" <<'HOOK_SCRIPT'
#!/usr/bin/env bash
# [gideon:managed] Pre-commit identity guard
# Checks if current user.email matches expected profile for this directory.
# Installed by: gideon guard --install
# Remove with:  gideon guard --uninstall

set -euo pipefail

# Find the profiles.conf
GIDEON_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/gideon/profiles.conf"

if [[ ! -f "$GIDEON_CONF" ]]; then
    # No config found — allow commit (gideon not fully set up)
    exit 0
fi

# Get the current git directory (absolute path)
current_dir=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Get the configured email for this repo
actual_email=$(git config user.email 2>/dev/null || true)

if [[ -z "$actual_email" ]]; then
    # No email configured — git will error anyway
    exit 0
fi

# Search profiles.conf for a matching directory
expected_email=""
expected_label=""

while IFS=: read -r label email dir || [[ -n "$label" ]]; do
    # Skip comments and empty lines
    [[ "$label" == "#"* ]] && continue
    [[ -z "$label" ]] && continue
    
    # Skip manual mode profiles (no directory)
    [[ -z "$dir" ]] && continue

    # Normalize: ensure trailing slash for prefix matching
    dir_slash="${dir%/}/"

    # Check if current dir is under this profile's directory
    if [[ "${current_dir}/" == "${dir_slash}"* ]]; then
        expected_email="$email"
        expected_label="$label"
        # Don't break — last match wins (most specific path)
    fi
done < "$GIDEON_CONF"

# If no profile matched this directory, allow commit
if [[ -z "$expected_email" ]]; then
    exit 0
fi

# Compare
if [[ "$actual_email" != "$expected_email" ]]; then
    printf '\n'
    printf '  \033[0;33m⚠\033[0m  \033[1mgideon: Identity mismatch detected!\033[0m\n'
    printf '     Expected: \033[0;32m%s\033[0m (profile: %s)\n' "$expected_email" "$expected_label"
    printf '     Actual:   \033[0;31m%s\033[0m\n' "$actual_email"
    printf '\n'
    printf '     Run \033[1mgideon status\033[0m to investigate.\n'
    printf '     Use \033[2m--no-verify\033[0m to skip this check.\n'
    printf '\n'
    exit 1
fi

exit 0
HOOK_SCRIPT

    chmod +x "$hook_path"
    git config --global core.hooksPath "$GIDEON_HOOKS_DIR"

    print_success "Guard hook installed: $hook_path"
    print_info "All repos will now check identity before commits."
    print_info "Use 'gideon guard --uninstall' to remove."
}

# ------------------------------------------------------------------------------
# uninstall_guard — Remove the pre-commit identity guard hook
#
# Removes the hook file and unsets core.hooksPath (only if it was gideon's).
#
# Usage: uninstall_guard
# ------------------------------------------------------------------------------
uninstall_guard() {
    local hook_path="$GIDEON_HOOKS_DIR/pre-commit"

    if [[ "$GIDEON_DRY_RUN" -eq 1 ]]; then
        print_info "[DRY RUN] Would remove: $hook_path"
        print_info "[DRY RUN] Would unset core.hooksPath"
        return 0
    fi

    # Remove hook file
    if [[ -f "$hook_path" ]]; then
        rm -f "$hook_path"
        print_success "Removed guard hook: $hook_path"
    else
        print_info "No guard hook found at: $hook_path"
    fi

    # Unset core.hooksPath only if it points to our directory
    local current_hooks_path
    current_hooks_path=$(git config --global core.hooksPath 2>/dev/null || true)
    
    # Normalize slashes for Windows Git Bash paths (C:\ vs C:/ vs /c/)
    local normalized_current="${current_hooks_path//\\//}"
    local normalized_target="${GIDEON_HOOKS_DIR//\\//}"

    # Match exact path or suffix (to handle Windows C:/ vs /c/ drive letter differences)
    if [[ "$normalized_current" == "$normalized_target" ]] || [[ "$normalized_current" == *"/gideon/hooks" ]]; then
        git config --global --unset core.hooksPath
        print_success "Unset core.hooksPath"
    elif [[ -n "$current_hooks_path" ]]; then
        print_warning "core.hooksPath points to '$current_hooks_path' (not gideon). Leaving it."
    fi
}
