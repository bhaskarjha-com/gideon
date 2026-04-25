<div align="center">

# gideon

**One command. All identities. Every machine.**

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](.github/workflows/ci.yml)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash 3.2+](https://img.shields.io/badge/Bash-3.2%2B-orange)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)]()

A zero-dependency CLI tool that automates Git multi-identity and SSH key setup.
Clone, run, done.

</div>

---

## The Problem

You work with multiple Git identities — personal, work, freelance, open-source. Every new machine, VM, or container means manually generating SSH keys, editing `~/.gitconfig`, configuring `~/.ssh/config`, adding keys to GitHub... and hoping you didn't make a typo that will haunt your commit history forever.

**gideon does all of this in 60 seconds.**

## Quick Start

```bash
git clone https://github.com/bhaskarjha-com/gideon.git
cd gideon
./gideon setup
```

That's it. Answer the prompts, copy the public keys to GitHub, and you're done.

## What It Does

In a single interactive session, `gideon`:

1. 🔍 **Detects** your OS and environment (Linux, macOS, Windows, WSL, VirtualBox)
2. 🎤 **Collects** your profile information (name, email, directory) via guided prompts
3. 🔑 **Generates** Ed25519 SSH keys for each identity
4. 📝 **Creates** `~/.gitconfig` with `includeIf` conditional includes
5. 📝 **Creates** per-profile gitconfig files with `core.sshCommand`
6. 🔗 **Updates** `~/.ssh/config` with host aliases for cloning
7. 🛡️ **Installs** a pre-commit guard hook (optional) to catch identity mismatches
8. ✅ **Verifies** your entire setup works

## Why gideon?

| Feature | gitego | gguser | git-profile | karn | **gideon** |
|---------|--------|--------|-------------|------|-----------|
| SSH key generation | ❌ | ❌ | ❌ | ❌ | ✅ |
| SSH config creation | ❌ | ❌ | ❌ | ❌ | ✅ |
| Git config with includeIf | ✅ | ❌ | ❌ | ❌ | ✅ |
| Pre-commit identity guard | ✅ | ❌ | ❌ | ❌ | ✅ |
| Zero dependencies | ❌ (Go) | ❌ (Node) | ❌ (Rust) | ❌ (Go) | ✅ (bash) |
| Cross-platform | ✅ | ✅ | ⚠️ | ✅ | ✅ |
| Idempotent re-run | ❌ | ❌ | ❌ | ❌ | ✅ |
| Dry-run mode | ❌ | ❌ | ❌ | ❌ | ✅ |

> **gideon is a bootstrapper, not a switcher.** Other tools manage identities you've already set up. gideon creates the entire infrastructure from scratch.

## CLI Reference

| Command | Description |
|---------|-------------|
| `./gideon setup` | Interactive setup wizard |
| `./gideon setup --dry-run` | Preview what setup would do (no writes) |
| `./gideon status` | Show current identity and all profiles |
| `./gideon verify` | Test SSH keys, git config, and connectivity |
| `./gideon teardown` | Remove all gideon configurations safely |
| `./gideon guard --install` | Install pre-commit identity mismatch guard |
| `./gideon guard --uninstall` | Remove the guard hook |
| `./gideon --help` | Full help text |
| `./gideon --version` | Version info |

## How It Works

### Files Created

```
~/.gitconfig                              # Global config with includeIf rules
~/.ssh/config                             # Host aliases for cloning
~/.ssh/id_ed25519_<label>                 # Private SSH key per profile
~/.ssh/id_ed25519_<label>.pub             # Public SSH key per profile
~/.config/gideon/profiles/<label>.gitconfig # Per-profile git config
~/.config/gideon/profiles.conf             # Profile registry
~/.config/gideon/hooks/pre-commit          # Identity guard hook (optional)
```

### The Dual SSH Strategy

gideon solves the **clone chicken-and-egg problem** that no other tool addresses:

- **Day-to-day** (push, pull, commit): `core.sshCommand` in profile gitconfigs automatically uses the right SSH key based on directory
- **First-time cloning**: SSH config host aliases let you specify the identity:
  ```bash
  git clone git@github-pro:username/repo.git ~/dev/pro/repo
  ```

### Managed Blocks (Idempotent Updates)

gideon marks its sections with `# [gideon:managed:start]` / `# [gideon:managed:end]` comments. On re-run, only managed blocks are replaced. Your custom configurations are **never touched**.

## Identity Guard Hook

Prevent wrong-identity commits with a global pre-commit hook:

```bash
./gideon guard --install
```

```
$ git commit -m "fix bug"
⚠ gideon: Identity mismatch detected!
  Expected: work@company.com (profile: work)
  Actual:   personal@gmail.com

  Run 'gideon status' to investigate.
  Use --no-verify to skip this check.
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | ✅ Full support | Tested on Debian, Ubuntu |
| macOS | ✅ Full support | Works with macOS's built-in bash 3.2 |
| Windows (Git Bash) | ✅ Full support | Uses case-insensitive `gitdir/i:` |
| WSL | ✅ Full support | Detected via `/proc/version` |
| VirtualBox shared folders | ⚠️ Supported | SSH keys must live on native filesystem |

## Requirements

- **bash** 3.2+ (pre-installed on macOS, Linux, Git Bash, WSL)
- **git** (any recent version)
- **ssh-keygen** (pre-installed with OpenSSH)

No Go. No Node. No Rust. No pip. No brew. Just bash.

## Testing

```bash
# Run all tests
for f in tests/test_*.sh; do bash "$f"; done

# Run a specific test file
bash tests/test_validate.sh
```

74 tests covering: platform detection, input validation, SSH key generation, git config generation, backup/restore, teardown logic, and full integration.

## FAQ

<details>
<summary><strong>Can I use this with GitLab or Bitbucket?</strong></summary>

Currently, the generated SSH config uses `github.com` as the hostname. You can manually edit the managed blocks to use `gitlab.com` or `bitbucket.org`. Multi-host support is planned for v2.
</details>

<details>
<summary><strong>What about SSH passphrases?</strong></summary>

By default, gideon generates keys without passphrases for convenience. You can add a passphrase to any key later with `ssh-keygen -p -f ~/.ssh/id_ed25519_<label>`.
</details>

<details>
<summary><strong>Is it safe to re-run?</strong></summary>

Yes. gideon is fully idempotent. It backs up existing configs before modifying them and uses managed block markers to replace only its own sections. Run it as many times as you want.
</details>

<details>
<summary><strong>What if I already have SSH keys?</strong></summary>

If a key with the same name exists, gideon will prompt you to: skip (keep current), rename the old key, or overwrite it.
</details>

<details>
<summary><strong>Why bash instead of Go/Rust/Python?</strong></summary>

Zero dependency is the killer feature. Bash, git, and ssh-keygen are available on every developer machine without installing anything. No version managers, no package managers, no binary downloads. This also means no "binary rot" — the tool works as long as bash exists.
</details>

## Project Structure

```
gideon/
├── gideon                # Main entry point (CRLF self-healing + wizard)
├── lib/
│   ├── core.sh          # Constants, version, state
│   ├── platform.sh      # OS detection, prerequisites
│   ├── ui.sh            # Colors, prompts, formatting
│   ├── validate.sh      # Input validation
│   ├── backup.sh        # Timestamped backups
│   ├── ssh.sh           # SSH key & config management
│   ├── gitconfig.sh     # Git config generation
│   ├── guard.sh         # Pre-commit identity hook
│   ├── verify.sh        # Post-setup verification
│   └── teardown.sh      # Safely remove all configurations
├── tests/               # 74 tests, zero dependencies
├── docs/                # Architecture & troubleshooting
└── .github/workflows/   # CI: ShellCheck + tests on 3 OSes
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

[MIT](LICENSE) — Bhaskar Jha
