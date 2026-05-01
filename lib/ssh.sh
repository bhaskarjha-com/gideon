#!/usr/bin/env bash
# lib/ssh.sh — SSH key generation and ~/.ssh/config management
#
# Generates Ed25519 keys per profile and creates host alias blocks
# in ~/.ssh/config for the clone workflow.
# Bash 3.2 compatible.

# ------------------------------------------------------------------------------
# generate_ssh_key — Generate an Ed25519 SSH key pair for a profile
#
# Creates: $HOME/.ssh/id_ed25519_<label> (private) and .pub (public)
# If key exists: prompts user to skip, rename old, or overwrite.
#
# Usage: generate_ssh_key "pro" "user@example.com"
# Returns: 0 on success/skip, 1 on failure
# ------------------------------------------------------------------------------
generate_ssh_key() {
    local label="$1"
    local email="$2"
    local key_path="${3:-$HOME/.ssh/id_ed25519_${label}}"

    # Warn if ~/.ssh is on a shared mount
    if is_shared_mount "$HOME/.ssh" 2>/dev/null; then
        # shellcheck disable=SC2088  # Tilde is in a display string, not a path
        print_warning "~/.ssh appears to be on a shared folder (VirtualBox/VMware)."
        print_warning "SSH keys require strict permissions (600) which shared folders cannot enforce."
        print_info "Consider storing keys on the native filesystem instead."
    fi

    # Create ~/.ssh if it doesn't exist
    if [[ ! -d "$HOME/.ssh" ]]; then
        mkdir -p "$HOME/.ssh"
        print_step "Created ~/.ssh directory"
    fi
    chmod 700 "$HOME/.ssh"

    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        print_warning "SSH key already exists: $key_path"

        if [[ "$GITSETU_DRY_RUN" -eq 1 ]]; then
            print_info "[DRY RUN] Would prompt for action on existing key"
            return 0
        fi

        ask_choice "What to do with existing key?" "skip (keep current)" "rename old key" "overwrite"

        case "$REPLY" in
            "skip (keep current)")
                print_info "Keeping existing key for '$label'"
                return 0
                ;;
            "rename old key")
                local timestamp
                timestamp=$(date +%Y%m%dT%H%M%S)
                mv "$key_path" "${key_path}.old.${timestamp}"
                mv "${key_path}.pub" "${key_path}.pub.old.${timestamp}" 2>/dev/null || true
                print_info "Renamed old key to ${key_path}.old.${timestamp}"
                ;;
            "overwrite")
                print_info "Overwriting existing key for '$label'"
                ;;
        esac
    fi

    # Dry run: just show what would happen
    if [[ "$GITSETU_DRY_RUN" -eq 1 ]]; then
        print_info "[DRY RUN] Would generate: $key_path"
        print_info "[DRY RUN] ssh-keygen -t ed25519 -C \"$email\" -f \"$key_path\" -N \"\""
        return 0
    fi

    # Generate the key
    print_step "Generating SSH key for '$label'..."

    # Check if FIDO2 hardware key was requested based on filename convention
    local key_type="ed25519"
    local extra_args=""
    if [[ "$key_path" == *"_sk_"* ]]; then
        key_type="ed25519-sk"
        extra_args="-O resident -O verify-required"
        print_info "Hardware Security Key detected. Please TOUCH YOUR YUBIKEY when prompted."
    fi

    if [[ "${GITSETU_USE_PASSPHRASE:-0}" -eq 1 ]] || [[ "$key_type" == "ed25519-sk" ]]; then
        # Prompt user for passphrase or FIDO2 touch interactively
        # shellcheck disable=SC2086
        ssh-keygen -t "$key_type" $extra_args -C "$email" -f "$key_path"
        local status=$?
        
        # FIDO2 Fallback Mechanism
        if [[ "$status" -ne 0 ]] && [[ "$key_type" == "ed25519-sk" ]]; then
            print_warning "Hardware Security Key enrollment failed (missing device or libfido2 unsupported)."
            print_info "Falling back to standard ed25519 software key generation..."
            
            key_type="ed25519"
            extra_args=""
            if [[ "${GITSETU_USE_PASSPHRASE:-0}" -eq 1 ]]; then
                ssh-keygen -t "$key_type" -C "$email" -f "$key_path"
                status=$?
            else
                ssh-keygen -t "$key_type" -C "$email" -f "$key_path" -N "" -q
                status=$?
            fi
        fi
    else
        # Password-less key (background with spinner)
        # shellcheck disable=SC2086
        ssh-keygen -t "$key_type" $extra_args -C "$email" -f "$key_path" -N "" -q >/dev/null 2>&1 &
        local pid=$!
        local spin='-\|/'
        local i=0
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) %4 ))
            printf "\r  ${BOLD}Generating...${RESET} %s " "${spin:$i:1}" >&2
            sleep 0.1
        done
        wait $pid
        local status=$?
        printf "\r\033[K" >&2 # Clear the spinner line
    fi

    if [[ "$status" -eq 0 ]]; then
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        print_success "Created: $key_path"
        return 0
    else
        print_error "Failed to generate SSH key for '$label'"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# build_ssh_host_block — Generate a single Host block for ~/.ssh/config
#
# Usage: block=$(build_ssh_host_block "pro" "github.com")
# Output: formatted Host block with managed markers
# ------------------------------------------------------------------------------
build_ssh_host_block() {
    local label="$1"
    local hostname="${2:-github.com}"
    local key_path="${3:-$HOME/.ssh/id_ed25519_${label}}"
    
    # Extract the main part of the domain (e.g., gitlab.com -> gitlab) for the alias prefix
    local prefix
    prefix=$(printf '%s' "$hostname" | cut -d'.' -f1)

    cat <<EOF
${GITSETU_MANAGED_START} ${label}
Host ${prefix}-${label}
    HostName ${hostname}
    User git
    IdentityFile ${key_path}
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "    UseKeychain yes"
    fi

    echo "${GITSETU_MANAGED_END} ${label}"
}

# ------------------------------------------------------------------------------
# write_ssh_config — Update ~/.ssh/config with gitsetu-managed host blocks
#
# Strategy:
#   1. Create ~/.ssh/config if it doesn't exist
#   2. Remove ALL existing gitsetu-managed blocks (between markers)
#   3. Append fresh managed blocks for all profiles
#   4. Preserve all non-managed content verbatim
#
# This makes the function fully idempotent.
# Usage: write_ssh_config
# ------------------------------------------------------------------------------
write_ssh_config() {
    local ssh_config="$HOME/.ssh/config"

    # Create ~/.ssh if needed
    if [[ ! -d "$HOME/.ssh" ]]; then
        mkdir -p "$HOME/.ssh"
    fi
    chmod 700 "$HOME/.ssh"

    # Dry run
    if [[ "$GITSETU_DRY_RUN" -eq 1 ]]; then
        print_info "[DRY RUN] Would update: $ssh_config"
        local i
        for (( i=0; i<PROFILE_COUNT; i++ )); do
            print_info "[DRY RUN] Would add Host github-${PROFILE_LABELS[$i]}"
        done
        return 0
    fi

    # Backup existing config
    if [[ -f "$ssh_config" ]]; then
        backup_file "$ssh_config"
    fi

    # Remove existing managed blocks
    if [[ -f "$ssh_config" ]]; then
        local tmp_file
        tmp_file=$(mktemp "${ssh_config}.tmp.XXXXXX")
        GITSETU_CLEANUP_FILES+=("$tmp_file")

        awk '
            BEGIN { in_block=0; buffer="" }
            /\[gitsetu:managed:start\]/ {
                in_block=1
                buffer = $0 "\n"
                next
            }
            in_block {
                buffer = buffer $0 "\n"
                if (/\[gitsetu:managed:end\]/) {
                    in_block=0
                    buffer=""
                }
                next
            }
            !in_block { print }
            END {
                if (in_block) {
                    printf "%s", buffer
                }
            }
        ' "$ssh_config" > "$tmp_file"

        mv "$tmp_file" "$ssh_config"
    fi

    # Append managed blocks for all profiles
    local i
    for (( i=0; i<PROFILE_COUNT; i++ )); do
        local label="${PROFILE_LABELS[$i]}"
        local provider="${PROFILE_PROVIDERS[$i]:-github.com}"
        local key_path="${PROFILE_KEYS[$i]:-$HOME/.ssh/id_ed25519_${label}}"
        printf '\n' >> "$ssh_config"
        build_ssh_host_block "$label" "$provider" "$key_path" >> "$ssh_config"
    done

    # Ensure correct permissions
    chmod 600 "$ssh_config"
    print_success "Updated: $ssh_config"
}

# ------------------------------------------------------------------------------
# display_public_keys — Show all public keys with copy instructions
#
# Displays each key in a formatted box with the GitHub settings URL.
# Usage: display_public_keys
# ------------------------------------------------------------------------------
display_public_keys() {
    print_section "Public Keys — Add These to GitHub/GitLab"

    local i
    for (( i=0; i<PROFILE_COUNT; i++ )); do
        local label="${PROFILE_LABELS[$i]}"
        local email="${PROFILE_EMAILS[$i]}"
        local pubkey="${PROFILE_KEYS[$i]:-$HOME/.ssh/id_ed25519_${label}}.pub"

        if [[ -f "$pubkey" ]]; then
            print_key_box "$label" "$email" "$pubkey"
        else
            print_warning "Key not found for '$label': $pubkey"
        fi
    done

    print_section "The Magical Clone"
    printf >&2 "  %bYou no longer need special host aliases to clone!%b\n\n" "$BOLD" "$RESET"
    printf >&2 "  Simply %bcd%b into your profile's directory and run:\n" "$CYAN" "$RESET"
    printf >&2 "    git clone git@github.com:username/repo.git\n\n"
    printf >&2 "  %bGitSetu will automatically intercept and use the correct SSH key!%b\n" "$BOLD" "$RESET"
}
