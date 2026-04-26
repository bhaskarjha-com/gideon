# The Gideon Manifesto

Gideon was born from a singular, profound frustration: managing multiple Git identities across diverse environments is a universally broken experience.

Modern software development requires engineers to constantly context-switch between enterprise monorepos, open-source contributions, and personal sandboxes. Yet, the infrastructure required to securely isolate these identities—generating keys, configuring SSH aliases, writing conditional Git includes, and mitigating virtualization quirks—is deeply tedious, highly error-prone, and entirely manual.

Gideon exists to solve this problem permanently.

## The Core Philosophy

### 1. The Magical Clone (Zero-Friction UX)
Competitors require developers to memorize custom SSH host aliases (`git clone git@github-work:...`). We fundamentally reject this design.

Gideon leverages the `includeIf` gitdir directive to dynamically inject `core.sshCommand` *mid-flight* during the clone process. This allows developers to clone repositories exactly as they normally would (`git clone git@github.com:...`). Gideon intercepts the request and silently applies the correct SSH key based entirely on the target directory. It is frictionless, intuitive, and indistinguishable from magic.

### 2. Absolute Zero Dependencies
A bootstrapping tool that requires a package manager to install is a contradiction in terms. 

Gideon is written in pure, POSIX-compliant Bash 3.2. It requires no Go runtimes, no Node modules, no Rust toolchains, and no Homebrew installations. It relies strictly on `bash`, `git`, and `ssh-keygen`—tools guaranteed to exist on every developer workstation on earth. This guarantees zero "binary rot" and absolute portability.

### 3. Strict Idempotency and Self-Healing
Configuration scripts that append data blindly are dangerous. 

Gideon implements a strict Managed Block Protocol. It surgically updates only the sections it owns, leaving custom user configurations perfectly intact. It is safe to execute ten times in a row. Furthermore, it natively self-heals against virtualization environments, automatically stripping CRLF injections from VirtualBox shared folders and injecting `safe.directory` rules to bypass Git's dubious ownership blocks.

### 4. Bootstrapping vs. Switching
Gideon is a bootstrapper, not a switcher. It does not exist to manage identities you have already painstakingly configured. It exists to obliterate the configuration process entirely. From a fresh OS install, Gideon provisions your entire Git identity infrastructure from scratch in under 60 seconds.

## Competitive Positioning

Extensive industry research evaluated 9 existing multi-identity tools (`gitego`, `gguser`, `git-profile`, `karn`, etc.). 

**None** generate SSH keys, formulate gitconfigs, and orchestrate SSH configurations in a single unified session. All require external compiled runtimes. 

Gideon is the definitive, zero-dependency solution to Git identity management.

## Non-Goals

To maintain its extreme focus and reliability, Gideon explicitly rejects the following features:
- **Credential Management:** It does not handle passwords, personal access tokens (PATs), or OAuth flows.
- **Git Wrapping:** It does not alias or intercept standard Git commands (beyond the native hooks).
- **Dotfiles Management:** It strictly isolates its scope to Git and SSH identity configuration.
- **Daemonization:** It is an execution script, not a background process.
