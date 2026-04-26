<div align="center">

![Gideon Logo](docs/assets/logo.png)

# gideon

**One command. All identities. Every machine.**

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](.github/workflows/ci.yml)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash 3.2+](https://img.shields.io/badge/Bash-3.2%2B-orange)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)]()

A zero-dependency CLI tool that automates Git multi-identity and SSH key setup.  
**Stop fighting with SSH keys. Clone, run, done.**

</div>

---

## The Problem

You work with multiple Git identities — personal, work, freelance, open-source. Every new machine, VM, or container means manually generating SSH keys, editing `~/.gitconfig`, configuring `~/.ssh/config`, adding keys to GitHub... and hoping you didn't make a typo that will haunt your commit history forever.

**gideon does all of this in 60 seconds.**

## 🚀 Quick Start

```bash
git clone https://github.com/bhaskarjha-com/gideon.git
cd gideon
./gideon setup
```

That's it. Answer the interactive prompts, copy the generated public keys to GitHub, and you're done.

---

## ✨ The Magical Workflow

Gideon provides a completely frictionless, alias-free experience. 

Other tools require you to memorize custom SSH host aliases (like `git clone git@github-work:username/repo.git`). With gideon, you don't.

1. **`cd` into your profile directory** (e.g., `cd ~/dev/work`)
2. **Clone normally**: `git clone git@github.com:company/repo.git`

> **How is this possible?**
> Git's `includeIf` conditional rules instantly activate the moment a new `.git` directory is created. During the clone process, Git initializes the folder locally, immediately triggers gideon's `includeIf` rule, reads the `core.sshCommand` for that profile, and dynamically injects the correct SSH key mid-flight before the connection to GitHub is ever made!

---

## ⚡ Why Gideon?

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

### Key Benefits
- **Zero Dependencies:** Written in pure Bash 3.2. No Go, Node, Rust, or Homebrew required.
- **Idempotent:** Safe to run multiple times. Gideon marks its config sections with managed blocks and never touches your custom configurations.
- **Self-Healing:** Natively detects and fixes VirtualBox/WSL CRLF line-ending bugs and automatically injects Git `safe.directory` rules to resolve "dubious ownership" errors on shared mounts.
- **Identity Guard:** Includes a pre-commit hook that actively prevents you from committing to a repository with the wrong email address.

> **gideon is a bootstrapper, not a switcher.** Other tools manage identities you've already set up. gideon creates the entire infrastructure from scratch.

---

## 🛡️ Identity Guard Hook

Prevent wrong-identity commits with a global pre-commit hook:

```bash
./gideon guard --install
```

If you accidentally try to commit with the wrong email, Gideon intercepts it:

```text
$ git commit -m "fix bug"

⚠ gideon: Identity mismatch detected!
  Expected: work@company.com (profile: work)
  Actual:   personal@gmail.com

  Run 'gideon status' to investigate.
  Use --no-verify to skip this check.
```

---

## 🛠️ CLI Reference

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

---

## 💻 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | ✅ Full support | Tested on Debian, Ubuntu |
| macOS | ✅ Full support | Works with macOS's built-in bash 3.2 |
| Windows (Git Bash) | ✅ Full support | Uses case-insensitive `gitdir/i:` |
| WSL | ✅ Full support | Detected via `/proc/version` |
| VirtualBox | ✅ Full support | Handles CRLF injection and `dubious ownership` natively |

---

## 📖 Documentation & Architecture

Gideon's internals are heavily documented. See the following guides for deep dives:
- **[Architecture & Design](docs/ARCHITECTURE.md)**: Visual diagrams of the configuration flow and clone intercept.
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)**: Quick diagnostics for SSH and Git issues.
- **[The Vision](docs/VISION.md)**: The engineering manifesto behind Gideon.

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

To run the test suite (74 tests covering all edge cases):
```bash
# Run all tests
for f in tests/test_*.sh; do bash "$f"; done
```

## License

[MIT](LICENSE) — Bhaskar Jha
