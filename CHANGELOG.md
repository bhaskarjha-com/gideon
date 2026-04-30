# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-23

### Added

- Interactive setup wizard with smart defaults and guided prompts
- Ed25519 SSH key generation per profile
- Global `~/.gitconfig` with `includeIf` conditional includes for directory-based identity switching
- Per-profile gitconfig files with `core.sshCommand` for automatic SSH key selection
- `~/.ssh/config` host alias generation for the clone workflow
- Pre-commit identity guard hook (`gitsetu guard --install`) to prevent wrong-identity commits
- `gitsetu status` command showing current identity and all configured profiles
- `gitsetu verify` command testing SSH keys, permissions, git config, and connectivity
- Dry-run mode (`gitsetu setup --dry-run`) to preview changes without writing
- Timestamped backups of all modified configuration files
- Managed block markers for idempotent re-runs (safe to run multiple times)
- Cross-platform support: Linux, macOS (bash 3.2), Windows (Git Bash), WSL
- VirtualBox shared folder detection with permission warnings
- CRLF self-healing: auto-detects and strips `\r` at runtime on VirtualBox shared folders
- 67 automated tests with zero external dependencies
- Comprehensive documentation: README, ARCHITECTURE, TROUBLESHOOTING, CONTRIBUTING
- Prompt library (`docs/PROMPTS.md`) with 14 copy-paste templates for AI-assisted development

### Fixed

- `is_shared_mount` broken pipe chain — `grep -qE` swallowed output before path matching
- Color detection checked stdout (`-t 1`) instead of stderr (`-t 2`), disabling colors when stdout was piped
- `get_ssh_agent_advice` wrote to stdout instead of stderr, breaking the clean-stdout convention
- Replaced here-strings (`<<<`) with process substitution for stricter bash 3.2 compatibility

