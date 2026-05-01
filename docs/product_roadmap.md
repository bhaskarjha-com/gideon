# GitSetu Product Roadmap (v1.1 - v2.0)

*Last Updated: Following a rigorous zero-bias architectural audit, deep web research, and evaluation against our absolute "Pure Bash 3.2 / Zero-Dependency" constraint.*

*(Note: Features implemented in v1.0.0, such as Custom Provider Hostnames and SSH Passphrase Support, have been cleared from this backlog).*

---

## ✅ Completed in v1.1.0 (Zero-Trust Security & Trust Baseline)

The following critical features and architectural fixes have been successfully implemented and verified:
- **Zero-Trust Identity Guard**: Enforces a strict fail-closed boundary on pre-commit; hard blocks commits if configuration is missing or tampered with.
- **Single Source of Truth (SSOT)**: Identity synchronization is guaranteed by dynamically querying isolated `.gitconfig` files, stripping dual-state variables from `profiles.conf`.
- **Unified Global Lifecycle (Filesystem Safe)**: Safe trapping of signals (`EXIT/SIGINT/SIGTERM`) to purge transient arrays, temporary files (via `mktemp` registration), and orphaned locks under all catastrophic termination scenarios.
- **POSIX Concurrency Hardening (Stale Lock Reaping)**: Atomic `mv` operations completely eliminate Time-of-Check to Time-of-Use race conditions, guaranteeing perfectly concurrent headless execution without deadlocks.
- **Bash 3.2 Array Panic Prevention**: Native C-style loops completely replace subshells, preventing catastrophic failures during empty registry states.
- **Path Injection Prevention**: Strict newline sanitization on `[includeIf]` paths prevents multi-line INI corruption of the global git configuration.
- **POSIX Subshell Optimization**: Fractured GNU `sed` extensions have been entirely replaced with native Bash regex or POSIX-compliant `sed` patterns.
- **Teardown DoS Prevention**: Bounded directory traversal safeguards the filesystem against accidental root or `$HOME` deep-cleans.
- **Masked Email Validation (GitHub No-Reply Guard)**: Strict regex validation intercepts public emails during setup.
- **Privacy Guard-Rails (`useConfigOnly`)**: Global Git identity removed; `useConfigOnly=true` forces fatal errors in unmapped directories to stop leaks.
- **Temporary Execution Override (`gitsetu run`)**: Enables instant, one-off identity hijacking for isolated commands (e.g., `gitsetu run pro -- git fetch`).
- **Global `core.hooksPath` Virtualization**: Global pre-commit hook acts as a native pass-through, preserving local developer ecosystems (Husky/Lefthook).
- **Native SSH Commit Signing**: Automates "Verified" commit badges using GitSetu-generated keys via `commit.gpgsign=true`, bypassing GPG completely.
- **Native `ssh-agent` Auto-Reloading**: Injects `AddKeysToAgent yes` (and `UseKeychain yes` on Macs) to natively force the OS SSH daemon to cache passphrases on first use.
- **Single Profile Teardown (`gitsetu remove`)**: Surgically extracts and deletes specific profiles while cleanly regenerating all global configurations.

---

## 🔴 Must Have (Target: v1.1 Core Release)

All Must Have features for the Core Release have been completed! Proceeding to high-value integrations.



---

## 🟡 Should Have (High-Value Integrations)

### 1. FIDO2 / YubiKey Hardware Key Bootstrapping
**Problem:** Enterprise security mandates hardware-backed SSH keys. Standard keys are vulnerable to exfiltration.
**Solution:** Automate `ssh-keygen -t ed25519-sk -O resident` for FIDO2 tokens, explicitly prompting users to touch their hardware keys during setup.
**Constraint Note:** OpenSSH natively supports this, but the host OS must have `libfido2` installed. GitSetu must handle graceful degradation/warnings if the library is missing on older Macs.
**Difficulty:** Medium.

### 2. Profile-Aware Scaffolder & Retrofitter (`gitsetu init`)
**Problem:** Native `git init` does not place `.gitignore` files in the working directory. Third-party scaffolders (Cookiecutter) require Python. Existing repositories lack an easy way to opt-into GitSetu without moving directories.
**Solution:** A unified wrapper. When a user runs `gitsetu init` in an empty directory, it runs Git init and copies template files (e.g., `LICENSE`, `.gitignore`) from `~/.config/gitsetu/templates/<profile>/`. If run in an *existing* repository, it safely injects local `.git/config` overrides (retrofitting it).
**Constraint Note:** Zero dependencies. Relies on standard `cp` and basic `sed` for templating.
**Difficulty:** Medium.

### 3. Shell Prompt Integration (`gitsetu prompt`)
**Problem:** Users lack visual confirmation of their active Git identity in their terminal.
**Solution:** A sub-millisecond command that outputs the active profile based on `$PWD` for injection into `PS1` or Starship prompts.
**Constraint Note:** Must avoid subshells to maintain zero-latency execution.
**Difficulty:** Low.

### 4. Custom SSH Key Naming & Paths
**Problem:** Keys are forced into `~/.ssh/id_ed25519_<label>`.
**Solution:** Allow linking existing arbitrary keys.
**Constraint Note:** Because Bash 3.2 lacks associative arrays (`declare -A`), we cannot store profile-to-key mappings in memory. We will strictly use the global `~/.gitconfig` as our state-engine to retrieve custom paths.
**Difficulty:** Low.

### 5. Git Credential Helper (PAT Management)
**Problem:** Corporate firewalls block SSH, forcing HTTPS cloning via Personal Access Tokens.
**Solution:** Extend GitSetu to act as a lightweight, Bash-based credential helper using the OS keychain.
**Difficulty:** High (Complex macOS Keychain / Windows Credential Manager integration).

---

## 🟢 Might Have (v2.0 Horizon & Experimental)

*Features pushed to the horizon due to extreme Bash 3.2 complexity or reliance on external tools.*

### 1. Scoped Repository Auto-Discovery
**Problem:** Users want GitSetu to automatically find their misplaced `.git` repositories.
**Constraint Note:** **Heavily Modified.** Bash 3.2 lacks `globstar` (`**`). Using `find ~ -name ".git"` on macOS will crawl network mounts and Library caches, freezing the system. This feature *must* be scoped to a single user-provided path (e.g., `gitsetu scan ~/dev`).
**Difficulty:** High.

### 2. Historical Commit Sanitizer (`gitsetu sanitize`)
**Problem:** Users want to rewrite Git history to remove leaked personal emails.
**Constraint Note:** **Demoted.** The official tool `git-filter-repo` requires Python. Rewriting history in pure Bash 3.2 is wildly dangerous and risks repository corruption. 
**Difficulty:** Extremely High (Too dangerous for pure Bash).

### 3. Automated SSH-Key Rotation Engine
**Solution:** Warn users of expiring keys by checking the filesystem modification time.
**Constraint Note:** macOS (BSD) and Linux (GNU) handle the `stat` command completely differently. Requires robust fallback logic.
**Difficulty:** Medium.

### 4. Configuration Drift Detection (`gitsetu drift`)
**Solution:** A background check that diffs the current Git config against GitSetu's expected state.
**Difficulty:** Medium.

### 5. Bash Event Plugin System
**Solution:** Allow users to drop `.sh` scripts into a plugins folder that execute on `on_profile_switch`.
**Difficulty:** Medium.

### 6. Encrypted State Export / Backup
**Solution:** Tar and encrypt the GitSetu config and SSH keys using `openssl enc` for migration to new laptops.
**Difficulty:** Low.

### 7. 1Password SSH & Git Integration
**Solution:** Detect the 1Password CLI (`op`) and automatically configure Git's `core.sshCommand` to route through their agent socket instead of generating local keys.
**Difficulty:** Very High.

### 8. Strict SSH Agent Sandboxing
**Solution:** Dynamically enforce `IdentitiesOnly = yes` and carefully unmount/mount specific keys to the active agent socket context to prevent "Too many authentication failures".
**Difficulty:** High.


