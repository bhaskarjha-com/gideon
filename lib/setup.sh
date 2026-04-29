#!/usr/bin/env bash
# lib/setup.sh — Interactive Blueprint Dashboard for Gideon
#
# Replaces the linear wizard with a fast "Review & Apply" TUI menu.

# ------------------------------------------------------------------------------
# render_blueprint_dashboard
# ------------------------------------------------------------------------------
render_blueprint_dashboard() {
    clear || printf '\033c'
    
    printf >&2 '\n  %b╔══════════════════════════════════════╗%b\n' "$BOLD" "$RESET"
    printf >&2 '  %b║  Gideon Setup Blueprint              ║%b\n' "$BOLD" "$RESET"
    printf >&2 '  %b╚══════════════════════════════════════╝%b\n\n' "$BOLD" "$RESET"

    if [[ "$PROFILE_COUNT" -eq 0 ]]; then
        printf >&2 '  No profiles configured.\n\n'
    fi

    local i
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        local label="${PROFILE_LABELS[i]}"
        local name="${PROFILE_NAMES[i]}"
        local email="${PROFILE_EMAILS[i]}"
        local dir="${PROFILE_DIRS[i]}"
        local key="${PROFILE_KEYS[i]}"
        
        local key_status="(Will Generate)"
        if [[ -f "$key" ]]; then
            key_status="${GREEN}(Found Existing!)${RESET}"
        elif [[ "$key" == *"_sk_"* ]]; then
            key_status="(Will Generate FIDO2)"
        fi
        
        local display_name="${name:-(Not Configured)}"
        local display_email="${email:-(Not Configured)}"
        local display_dir="${dir:-[Global Fallback]}"
        
        printf >&2 '  %b%s) [%s]%b %s <%s>\n' "$BOLD" "$((i+1))" "$label" "$RESET" "$display_name" "$display_email"
        printf >&2 '     Key: %s %b\n' "$key" "$key_status"
        printf >&2 '     Dir: %s\n\n' "$display_dir"
    done

    printf >&2 '  ──────────────────────────────────────────────────────────\n'
    printf >&2 '  [A]dd Profile | [E]dit Profile | [R]emove | [S]ecurity \n'
    printf >&2 '  [H]elp        | [Q]uit         | [ENTER] Apply\n\n'
}

# ------------------------------------------------------------------------------
# prompt_edit_profile
# ------------------------------------------------------------------------------
prompt_edit_profile() {
    local i="$1"
    local label="${PROFILE_LABELS[i]}"
    
    printf >&2 '\n  ─── Editing Profile: %b%s%b ───\n' "$BOLD" "$label" "$RESET"
    
    # Name
    ask "Full Name" "${PROFILE_NAMES[i]}"
    if [[ -n "$REPLY" ]]; then PROFILE_NAMES[i]="$REPLY"; fi
    
    # Email
    ask "Email Address" "${PROFILE_EMAILS[i]}"
    if [[ -n "$REPLY" ]]; then PROFILE_EMAILS[i]="$REPLY"; fi
    
    # Directory (skip for global)
    if [[ "$i" -ne 0 ]]; then
        ask "Directory (e.g. ~/work)" "${PROFILE_DIRS[i]}"
        if [[ -n "$REPLY" ]]; then PROFILE_DIRS[i]=$(normalize_path "$REPLY"); fi
    fi
    
    # Key
    ask "SSH Key Path" "${PROFILE_KEYS[i]}"
    if [[ -n "$REPLY" ]]; then PROFILE_KEYS[i]=$(normalize_path "$REPLY"); fi
}

# ------------------------------------------------------------------------------
# prompt_add_profile
# ------------------------------------------------------------------------------
prompt_add_profile() {
    printf >&2 '\n  ─── Adding New Profile ───\n'
    
    ask_required "Profile Label (e.g. oss, client)"
    local label
    label=$(to_lower \"$REPLY\")
    
    while ! validate_label "$label" || array_contains "$label" "${PROFILE_LABELS[@]+"${PROFILE_LABELS[@]}"}"; do
        print_warning "Invalid or duplicate label."
        ask_required "Profile Label"
        label=$(to_lower "$REPLY")
    done
    
    PROFILE_LABELS[PROFILE_COUNT]="$label"
    
    # Default name to global
    local def_name="${PROFILE_NAMES[0]}"
    ask "Full Name" "$def_name"
    PROFILE_NAMES[PROFILE_COUNT]="$REPLY"
    
    ask "Email Address" ""
    PROFILE_EMAILS[PROFILE_COUNT]="$REPLY"
    
    local def_dir="$HOME/$label"
    ask "Directory" "$def_dir"
    PROFILE_DIRS[PROFILE_COUNT]=$(normalize_path "$REPLY")
    
    local def_key="$HOME/.ssh/id_ed25519_${label}"
    ask "SSH Key Path" "$def_key"
    PROFILE_KEYS[PROFILE_COUNT]=$(normalize_path "$REPLY")
    
    PROFILE_PROVIDERS[PROFILE_COUNT]="github.com"
    PROFILE_SIGNS[PROFILE_COUNT]="${GIDEON_DEFAULT_SIGN:-0}"
    
    PROFILE_COUNT=$((PROFILE_COUNT + 1))
}

# ------------------------------------------------------------------------------
# prompt_security
# ------------------------------------------------------------------------------
prompt_security() {
    printf >&2 '\n  ─── Global Security Settings ───\n'
    
    if confirm "Enable Native SSH Commit Signing for all generated profiles?" "n"; then
        export GIDEON_DEFAULT_SIGN=1
        local i
        for i in $(seq 0 $((PROFILE_COUNT - 1))); do
            PROFILE_SIGNS[i]=1
        done
    else
        export GIDEON_DEFAULT_SIGN=0
        local i
        for i in $(seq 0 $((PROFILE_COUNT - 1))); do
            PROFILE_SIGNS[i]=0
        done
    fi
    
    if confirm "Protect newly generated keys with a Passphrase?" "n"; then
        export GIDEON_USE_PASSPHRASE=1
    else
        export GIDEON_USE_PASSPHRASE=0
    fi
}

# ------------------------------------------------------------------------------
# execute_blueprint
# ------------------------------------------------------------------------------
execute_blueprint() {
    clear || printf '\033c'
    print_section "Executing Setup Blueprint"
    
    ensure_dirs

    # 1. Generate SSH keys
    print_section "Generating SSH Keys"
    local i
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        local key_path="${PROFILE_KEYS[i]}"
        
        if [[ -f "$key_path" ]]; then
            print_info "Using existing key: $key_path"
            continue
        fi
        
        generate_ssh_key "${PROFILE_LABELS[i]}" "${PROFILE_EMAILS[i]}" "$key_path"
        # shellcheck disable=SC2181
        if [[ $? -ne 0 ]] && [[ "$key_path" == *"_sk_"* ]]; then
            print_warning "FIDO2 Hardware Key generation failed."
            if confirm "Fallback to standard software SSH key for '${PROFILE_LABELS[i]}'?" "y"; then
                key_path="$HOME/.ssh/id_ed25519_${PROFILE_LABELS[i]}"
                PROFILE_KEYS[i]="$key_path"
                generate_ssh_key "${PROFILE_LABELS[i]}" "${PROFILE_EMAILS[i]}" "$key_path"
            else
                print_error "Setup aborted due to FIDO2 key generation failure."
                exit 1
            fi
        fi
    done

    # 2. Write profile gitconfigs (for non-default profiles)
    print_section "Writing Git Configuration"
    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        if [[ "$i" -ne "$DEFAULT_PROFILE_INDEX" ]]; then
            write_profile_gitconfig "${PROFILE_LABELS[i]}" "${PROFILE_NAMES[i]}" "${PROFILE_EMAILS[i]}" "${PROFILE_SIGNS[i]}" "${PROFILE_KEYS[i]}"
        fi
    done

    # 3. Write global gitconfig
    write_global_gitconfig

    # 4. Write SSH config
    print_section "Updating SSH Configuration"
    write_ssh_config

    # 5. Write profiles registry
    write_profiles_conf

    # 6. Display public keys
    display_public_keys
    
    # SSH agent advice
    print_section "SSH Agent Setup"
    get_ssh_agent_advice
    printf >&2 '\n'

    print_success "Setup complete! You're ready to go."
    printf >&2 '\n'
}

# ------------------------------------------------------------------------------
# interactive_setup_wizard
# ------------------------------------------------------------------------------
interactive_setup_wizard() {
    # Bootstrap initial state if empty
    generate_initial_blueprint

    while true; do
        render_blueprint_dashboard
        
        read -r -p "[?] Select an option, or press ENTER to Apply: " choice
        choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
        
        case "$choice" in
            "")
                # Validate before applying
                local valid=1
                local i
                for i in $(seq 0 $((PROFILE_COUNT - 1))); do
                    if [[ -z "${PROFILE_NAMES[i]}" ]] || [[ -z "${PROFILE_EMAILS[i]}" ]]; then
                        print_error "Profile '${PROFILE_LABELS[i]}' is missing a name or email!"
                        valid=0
                        sleep 2
                        break
                    fi
                done
                if [[ "$valid" -eq 1 ]]; then
                    execute_blueprint
                    break
                fi
                ;;
            "A")
                prompt_add_profile
                ;;
            "E")
                read -r -p "Enter profile number to edit (1-$PROFILE_COUNT): " idx
                if [[ "$idx" =~ ^[0-9]+$ ]] && [[ "$idx" -ge 1 ]] && [[ "$idx" -le "$PROFILE_COUNT" ]]; then
                    prompt_edit_profile $((idx - 1))
                fi
                ;;
            "R")
                read -r -p "Enter profile number to remove: " idx
                if [[ "$idx" =~ ^[0-9]+$ ]] && [[ "$idx" -ge 2 ]] && [[ "$idx" -le "$PROFILE_COUNT" ]]; then
                    # Bash 3.2 array removal hack
                    local rem_idx=$((idx - 1))
                    PROFILE_LABELS=("${PROFILE_LABELS[@]:0:$rem_idx}" "${PROFILE_LABELS[@]:$((rem_idx + 1))}")
                    PROFILE_NAMES=("${PROFILE_NAMES[@]:0:$rem_idx}" "${PROFILE_NAMES[@]:$((rem_idx + 1))}")
                    PROFILE_EMAILS=("${PROFILE_EMAILS[@]:0:$rem_idx}" "${PROFILE_EMAILS[@]:$((rem_idx + 1))}")
                    PROFILE_DIRS=("${PROFILE_DIRS[@]:0:$rem_idx}" "${PROFILE_DIRS[@]:$((rem_idx + 1))}")
                    PROFILE_KEYS=("${PROFILE_KEYS[@]:0:$rem_idx}" "${PROFILE_KEYS[@]:$((rem_idx + 1))}")
                    PROFILE_PROVIDERS=("${PROFILE_PROVIDERS[@]:0:$rem_idx}" "${PROFILE_PROVIDERS[@]:$((rem_idx + 1))}")
                    PROFILE_SIGNS=("${PROFILE_SIGNS[@]:0:$rem_idx}" "${PROFILE_SIGNS[@]:$((rem_idx + 1))}")
                    PROFILE_COUNT=$((PROFILE_COUNT - 1))
                else
                    print_warning "Cannot remove default profile or invalid index."
                    sleep 1
                fi
                ;;
            "S")
                prompt_security
                ;;
            "Q"|"QUIT"|"EXIT")
                print_info "Setup aborted."
                exit 0
                ;;
            "H"|"HELP")
                clear || printf '\033c'
                printf >&2 '\n  %b─── Gideon Setup Help ───%b\n\n' "$BOLD" "$RESET"
                printf >&2 '  Gideon auto-discovers your SSH keys and Git configurations.\n'
                printf >&2 '  If the proposed Blueprint looks correct, simply press %bENTER%b to apply.\n\n' "$BOLD" "$RESET"
                printf >&2 '  %b[A]dd%b       : Manually add a new profile (e.g. client, oss).\n' "$BOLD" "$RESET"
                printf >&2 '  %b[E]dit%b      : Modify a profile. Select its number to change Name, Email, or Key.\n' "$BOLD" "$RESET"
                printf >&2 '  %b[R]emove%b    : Delete a profile from the Blueprint.\n' "$BOLD" "$RESET"
                printf >&2 '  %b[S]ecurity%b  : Configure advanced options like FIDO2 Hardware keys, Commit Signing,\n' "$BOLD" "$RESET"
                printf >&2 '                and SSH Passphrases.\n\n'
                printf >&2 '  Press ENTER to return to the Dashboard.\n'
                read -r
                ;;
            *)
                # If they typed a number, edit that profile
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$PROFILE_COUNT" ]]; then
                    prompt_edit_profile $((choice - 1))
                fi
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# cmd_profile — Headless router for adding/removing profiles
# Usage: gideon profile add <label> --email="..."
# ------------------------------------------------------------------------------
cmd_profile() {
    local action="$1"
    shift
    local label="$1"
    shift

    if [[ -z "$action" ]] || [[ -z "$label" ]]; then
        print_error "Usage: gideon profile add|remove <label> [flags...]"
        exit 1
    fi

    load_profiles
    if [[ "$PROFILE_COUNT" -eq 0 ]]; then
        generate_initial_blueprint
    fi

    case "$action" in
        add|edit)
            # Find if it exists
            local idx=-1
            local i
            for i in $(seq 0 $((PROFILE_COUNT - 1))); do
                if [[ "${PROFILE_LABELS[i]}" == "$label" ]]; then
                    idx=$i
                    break
                fi
            done

            if [[ "$idx" -eq -1 ]] && [[ "$action" == "edit" ]]; then
                print_error "Profile '$label' not found."
                exit 1
            fi

            if [[ "$idx" -eq -1 ]]; then
                idx=$PROFILE_COUNT
                PROFILE_COUNT=$((PROFILE_COUNT + 1))
                PROFILE_LABELS[idx]="$label"
                PROFILE_NAMES[idx]="${PROFILE_NAMES[0]}" # default to global name
                PROFILE_EMAILS[idx]=""
                PROFILE_DIRS[idx]="$HOME/$label"
                PROFILE_PROVIDERS[idx]="github.com"
                PROFILE_SIGNS[idx]="${GIDEON_DEFAULT_SIGN:-0}"
                PROFILE_KEYS[idx]="$HOME/.ssh/id_ed25519_${label}"
            fi

            # Parse flags
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name=*) PROFILE_NAMES[idx]="${1#*=}" ;;
                    --email=*) PROFILE_EMAILS[idx]="${1#*=}" ;;
                    --dir=*) PROFILE_DIRS[idx]=$(normalize_path "${1#*=}") ;;
                    --provider=*) PROFILE_PROVIDERS[idx]="${1#*=}" ;;
                    --key=*) PROFILE_KEYS[idx]=$(normalize_path "${1#*=}") ;;
                    --fido2) PROFILE_KEYS[idx]="$HOME/.ssh/id_ed25519_sk_${label}" ;;
                    --sign) PROFILE_SIGNS[idx]="1" ;;
                    --no-sign) PROFILE_SIGNS[idx]="0" ;;
                    *)
                        print_error "Unknown flag: $1"
                        exit 1
                        ;;
                esac
                shift
            done

            # Validation
            if [[ -z "${PROFILE_EMAILS[idx]}" ]]; then
                if [[ -t 1 ]]; then
                    ask_required "Email Address for $label"
                    PROFILE_EMAILS[idx]="$REPLY"
                else
                    print_error "--email is required in headless mode."
                    exit 1
                fi
            fi

            execute_blueprint
            ;;
        remove)
            local idx=-1
            local i
            for i in $(seq 0 $((PROFILE_COUNT - 1))); do
                if [[ "${PROFILE_LABELS[i]}" == "$label" ]]; then
                    idx=$i
                    break
                fi
            done
            if [[ "$idx" -eq -1 ]]; then
                print_error "Profile '$label' not found."
                exit 1
            fi
            if [[ "$idx" -eq 0 ]]; then
                print_error "Cannot remove the global/default profile."
                exit 1
            fi

            # Bash 3.2 array removal hack
            PROFILE_LABELS=("${PROFILE_LABELS[@]:0:$idx}" "${PROFILE_LABELS[@]:$((idx + 1))}")
            PROFILE_NAMES=("${PROFILE_NAMES[@]:0:$idx}" "${PROFILE_NAMES[@]:$((idx + 1))}")
            PROFILE_EMAILS=("${PROFILE_EMAILS[@]:0:$idx}" "${PROFILE_EMAILS[@]:$((idx + 1))}")
            PROFILE_DIRS=("${PROFILE_DIRS[@]:0:$idx}" "${PROFILE_DIRS[@]:$((idx + 1))}")
            PROFILE_KEYS=("${PROFILE_KEYS[@]:0:$idx}" "${PROFILE_KEYS[@]:$((idx + 1))}")
            PROFILE_PROVIDERS=("${PROFILE_PROVIDERS[@]:0:$idx}" "${PROFILE_PROVIDERS[@]:$((idx + 1))}")
            PROFILE_SIGNS=("${PROFILE_SIGNS[@]:0:$idx}" "${PROFILE_SIGNS[@]:$((idx + 1))}")
            PROFILE_COUNT=$((PROFILE_COUNT - 1))

            execute_blueprint
            ;;
        *)
            print_error "Unknown profile action: $action"
            exit 1
            ;;
    esac
}
