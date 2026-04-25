# gideon — Vision & Design Rationale

> **One command. All identities. Every machine.**

## Why gideon Exists

Developers with multiple Git identities face a painful, repetitive setup on every new machine:
1. Generate SSH keys per identity
2. Configure `~/.ssh/config` with host aliases (for connectivity testing)
3. Write `~/.gitconfig` with `includeIf` conditional includes
4. Create per-profile gitconfig files
5. Register public keys on GitHub/GitLab
6. Verify everything works

One mistake → commits under the wrong email → permanent embarrassment in git history.

**gideon does all of this in 60 seconds.**

## Core Principles

1. **Zero dependencies** — Only bash 3.2+, git, and ssh-keygen
2. **Bootstrapper, not switcher** — Creates infrastructure from scratch (competitors only manage existing setups)
3. **Idempotent** — Safe to re-run via managed block markers
4. **Non-destructive** — Timestamped backups before any modification
5. **Cross-platform** — Linux, macOS (bash 3.2), Windows (Git Bash), WSL
6. **Transparent** — Dry-run mode shows exactly what will change

## Key Design Decision: The Magical Clone

Gideon provides a completely frictionless, alias-free clone experience.

The `includeIf gitdir:` dynamically injects `core.sshCommand` *during* the clone process, intercepting the fetch and applying the correct SSH key mid-flight.

- **Magical clone**: standard `git clone` works seamlessly (e.g. `git clone git@github.com...`)
- **Day-to-day**: `core.sshCommand` via `includeIf`

No other tool natively embraces this capability.

## Key Design Decision: Bash 3.2

macOS ships bash 3.2 (GPLv2) and legally cannot ship 4+ (GPLv3). Requiring bash 4+ would mean requiring Homebrew, breaking the zero-dependency promise. All modern bash features (associative arrays, mapfile, etc.) are replaced with portable alternatives.

## Competitive Positioning

9 existing tools were researched. **None generate SSH keys + create gitconfig + create SSH config in one session.** All require external runtimes (Go, Node, Rust). gideon is the only zero-dependency bootstrapper.

## Non-Goals

- Not a credential manager (no tokens/passwords)
- Not a Git wrapper (no command interception)
- Not a dotfiles manager (only git+SSH identity)
- Not a daemon (runs once, exits)
- Not a package (clone and run)

For complete competitive analysis and risk matrix, see the project artifacts.
