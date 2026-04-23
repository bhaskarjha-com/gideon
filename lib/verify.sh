#!/usr/bin/env bash
# lib/verify.sh — Post-setup verification and connectivity tests
#
# Checks SSH keys, git config, and SSH connectivity for all profiles.
# Bash 3.2 compatible.

# ------------------------------------------------------------------------------
# verify_ssh_keys — Check that expected SSH key files exist with correct perms
#
# Returns: 0 if all OK, 1 if any issues found
# ------------------------------------------------------------------------------
verify_ssh_keys() {
    local issues=0
    local i

    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        local label="${PROFILE_LABELS[$i]}"
        local key_path="$HOME/.ssh/id_ed25519_${label}"
        local pub_path="${key_path}.pub"

        # Private key exists?
        if [[ ! -f "$key_path" ]]; then
            print_error "Missing private key: $key_path"
            issues=$((issues + 1))
            continue
        fi

        # Public key exists?
        if [[ ! -f "$pub_path" ]]; then
            print_error "Missing public key: $pub_path"
            issues=$((issues + 1))
            continue
        fi

        # Check private key permissions (should be 600)
        local perms
        perms=$(stat -c '%a' "$key_path" 2>/dev/null || stat -f '%Lp' "$key_path" 2>/dev/null || echo "???")
        if [[ "$perms" != "600" ]]; then
            print_warning "Incorrect permissions on $key_path: $perms (should be 600)"
            issues=$((issues + 1))
        fi
    done

    return "$issues"
}

# ------------------------------------------------------------------------------
# verify_git_config — Check that git config returns expected values
#
# For each profile directory (if it exists and contains git repos),
# verifies that git config user.email returns the expected value.
#
# Returns: 0 if all OK, 1 if any issues found
# ------------------------------------------------------------------------------
verify_git_config() {
    local issues=0
    local i

    # Check global config exists
    if [[ ! -f "$HOME/.gitconfig" ]]; then
        print_error "Global gitconfig not found: ~/.gitconfig"
        return 1
    fi

    # Check profile configs exist
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        if [[ "$i" -eq "$DEFAULT_PROFILE_INDEX" ]]; then
            continue  # Default profile is in global config, not a separate file
        fi

        local label="${PROFILE_LABELS[$i]}"
        local profile_path="$GIDEON_PROFILES_DIR/${label}.gitconfig"

        if [[ ! -f "$profile_path" ]]; then
            print_error "Missing profile config: $profile_path"
            issues=$((issues + 1))
        fi
    done

    # Verify includeIf works in actual git repos (if any exist)
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        if [[ "$i" -eq "$DEFAULT_PROFILE_INDEX" ]]; then
            continue
        fi

        local label="${PROFILE_LABELS[$i]}"
        local email="${PROFILE_EMAILS[$i]}"
        local dir="${PROFILE_DIRS[$i]}"

        # Find first git repo in the profile directory
        if [[ -d "$dir" ]]; then
            local repo_dir
            repo_dir=$(find "$dir" -maxdepth 2 -name ".git" -type d 2>/dev/null | head -n1)
            if [[ -n "$repo_dir" ]]; then
                repo_dir=$(dirname "$repo_dir")
                local actual_email
                actual_email=$(git -C "$repo_dir" config user.email 2>/dev/null || echo "")

                if [[ "$actual_email" == "$email" ]]; then
                    print_success "Profile '$label': git config correct in $repo_dir"
                elif [[ -z "$actual_email" ]]; then
                    print_warning "Profile '$label': no email configured in $repo_dir"
                    issues=$((issues + 1))
                else
                    print_error "Profile '$label': expected '$email', got '$actual_email' in $repo_dir"
                    issues=$((issues + 1))
                fi
            fi
        fi
    done

    return "$issues"
}

# ------------------------------------------------------------------------------
# verify_ssh_connectivity — Test SSH connection to GitHub for each profile
#
# Runs ssh -T with a timeout to test authentication.
# Parses output to distinguish: authenticated, key not added, timeout, error.
#
# Returns: 0 if all OK, 1 if any issues
# ------------------------------------------------------------------------------
verify_ssh_connectivity() {
    local issues=0
    local i

    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        local label="${PROFILE_LABELS[$i]}"
        local host="github-${label}"

        printf >&2 '  Testing SSH: %s ... ' "$host"

        local output
        output=$(ssh -T -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "git@${host}" 2>&1 || true)

        if printf '%s' "$output" | grep -qi "successfully authenticated"; then
            printf >&2 '%b%s authenticated%b\n' "$GREEN" "$SYM_CHECK" "$RESET"
        elif printf '%s' "$output" | grep -qi "permission denied"; then
            printf >&2 '%b%s key not added to GitHub%b\n' "$YELLOW" "$SYM_WARN" "$RESET"
            issues=$((issues + 1))
        elif printf '%s' "$output" | grep -qi "could not resolve\|connection refused\|timed out"; then
            printf >&2 '%b%s connection failed%b\n' "$RED" "$SYM_CROSS" "$RESET"
            issues=$((issues + 1))
        else
            printf >&2 '%b%s unknown response%b\n' "$DIM" "$SYM_INFO" "$RESET"
            issues=$((issues + 1))
        fi
    done

    return "$issues"
}

# ------------------------------------------------------------------------------
# verify_all — Run all verification checks and print a summary table
#
# Usage: verify_all
# Returns: 0 if all checks pass, 1 if any fail
# ------------------------------------------------------------------------------
verify_all() {
    print_section "Verification Results"

    local total_issues=0

    # Header
    printf >&2 '  %-12s %-30s %-10s %-10s %-12s\n' \
        "Profile" "Email" "SSH Key" "Perms" "Config"
    printf >&2 '  %-12s %-30s %-10s %-10s %-12s\n' \
        "-------" "-----" "-------" "-----" "------"

    local i
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        local label="${PROFILE_LABELS[$i]}"
        local email="${PROFILE_EMAILS[$i]}"
        local key_path="$HOME/.ssh/id_ed25519_${label}"

        # Key status
        local key_status="${GREEN}${SYM_CHECK}${RESET}"
        if [[ ! -f "$key_path" ]]; then
            key_status="${RED}${SYM_CROSS}${RESET}"
            total_issues=$((total_issues + 1))
        fi

        # Permissions status
        local perm_status="${GREEN}${SYM_CHECK}${RESET}"
        if [[ -f "$key_path" ]]; then
            local perms
            perms=$(stat -c '%a' "$key_path" 2>/dev/null || stat -f '%Lp' "$key_path" 2>/dev/null || echo "???")
            if [[ "$perms" != "600" ]]; then
                perm_status="${YELLOW}${SYM_WARN} ${perms}${RESET}"
                total_issues=$((total_issues + 1))
            fi
        else
            perm_status="${DIM}-${RESET}"
        fi

        # Config status
        local config_status="${GREEN}${SYM_CHECK}${RESET}"
        if [[ "$i" -eq "$DEFAULT_PROFILE_INDEX" ]]; then
            # Default is in global config
            if [[ ! -f "$HOME/.gitconfig" ]]; then
                config_status="${RED}${SYM_CROSS}${RESET}"
                total_issues=$((total_issues + 1))
            fi
        else
            local profile_path="$GIDEON_PROFILES_DIR/${label}.gitconfig"
            if [[ ! -f "$profile_path" ]]; then
                config_status="${RED}${SYM_CROSS}${RESET}"
                total_issues=$((total_issues + 1))
            fi
        fi

        printf >&2 "  %-12s %-30s %b     %b     %b\n" \
            "$label" "$email" "$key_status" "$perm_status" "$config_status"
    done

    printf >&2 '\n'

    # SSH connectivity
    print_section "SSH Connectivity"
    verify_ssh_connectivity || total_issues=$((total_issues + 1))

    # Summary
    printf >&2 '\n'
    if [[ "$total_issues" -eq 0 ]]; then
        print_success "All checks passed!"
    else
        print_warning "$total_issues issue(s) found. See above for details."
    fi

    return "$total_issues"
}
