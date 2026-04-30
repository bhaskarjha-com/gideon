<div align="center">

# GitSetu 
*(git · se · tu)* / Sanskrit: bridge

**The bridge between your identities and your repositories.**  
*Zero deps. No daemon. Pure bash.*

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](.github/workflows/ci.yml)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash 3.2+](https://img.shields.io/badge/Bash-3.2%2B-orange)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)]()

<br/>

</div>

---

## 01. The Problem

**Wrong author commits**
You push a freelance project and your work email shows up in the git log. Your client sees your employer's domain.

**SSH key collisions**
One SSH key for three GitHub accounts means GitHub can't tell who you are. Pushes fail, permissions break.

**Manual global config**
You edit `~/.gitconfig` before every context switch. Then you forget. Again.

**Heavy tooling**
Every solution requires Node, Python, or a background daemon watching your filesystem. Just to change a name.

---

## 02. How GitSetu Works

GitSetu automatically manages multiple Git identities and SSH keys on a single machine. It provisions distinct keys, injects directory-based conditional configs, and writes SSH host aliases — so you never accidentally commit as the wrong author ever again.

1. **You declare an identity:** Run `gitsetu add`. Name, email, directory scope.
2. **GitSetu provisions a dedicated SSH key:** Generates a unique ED25519 SSH keypair cleanly stored under `~/.ssh/gitsetu/`. No shared keys between accounts.
3. **Writes a scoped `~/.gitconfig` include:** Injects an `includeIf` block that activates your name and email — only inside that directory tree.
4. **Creates an SSH host alias:** Writes a `Host` block in `~/.ssh/config`. 

### The "Magical Clone" Workflow
Other tools require you to memorize custom SSH host aliases (`git clone git@github-work:repo.git`). We reject this. With GitSetu, you just clone normally. Git's native `includeIf` intercepts the clone mid-flight and injects the correct key.

```mermaid
graph TD
    A[cd ~/work] --> B[git clone git@github.com:repo]
    B --> C{Git creates local .git}
    C --> D[Trigger includeIf rule]
    D --> E[Inject work SSH Key]
    E --> F[Authenticate with GitHub]
    
    classDef highlight fill:#00c4cc,stroke:#fff,stroke-width:2px,color:#fff;
    class D,E highlight;
```

---

## 03. Quick Start

**1. Install GitSetu:**
```bash
curl -sL https://raw.githubusercontent.com/bhaskarjha-com/gitsetu/main/install.sh | bash
```

**2. Add your identities once:**
```bash
$ gitsetu add personal "Aditya Kumar" aditya@gmail.com ~/personal
$ gitsetu add work "Aditya Kumar" aditya@company.com ~/work
$ gitsetu add freelance "AK Dev" ak@freelance.io ~/clients
```
*(Prefer a guided setup? Just run `gitsetu setup` to launch the interactive TUI).*

**3. Verify your setup:**
```bash
$ gitsetu status
personal aditya@gmail.com ~/personal ✓ active
work aditya@company.com ~/work
freelance ak@freelance.io ~/clients
```

**4. From now on — just `cd` and work. GitSetu does the rest.**
```text
$ cd ~/work/my-api && git commit -m "fix: auth bug"
Author: Aditya Kumar <aditya@company.com> ← correct, automatically
```

---

## 04. What You Get

- **zero dependency:** Pure Bash. No Node. No Python. No package manager.
- **no daemon:** GitSetu writes config once and lets Git's native `includeIf` do the switching. Zero background processes. Zero memory footprint.
- **directory-scoped:** Identity follows your cursor. Enter `~/work` — you're your work self.
- **ssh isolated:** Each profile gets its own ED25519 keypair and SSH host alias.
- **non-destructive:** Your existing config is safe. GitSetu appends to `~/.gitconfig` and `~/.ssh/config` with clearly marked blocks. Uninstall removes exactly what it added.
- **open standard:** No lock-in. GitSetu generates standard Git config and standard SSH config. You can read, edit, or delete what it creates.

---

## 05. The "Identity Guard"

Ever accidentally pushed a commit to your company repository using your `anime_fan_99@gmail.com` email address? 

GitSetu includes a global pre-commit hook that actively monitors your `$PWD` and blocks commits if your active `user.email` doesn't match the expected profile for that folder.

```bash
# Install the global identity guard
gitsetu guard --install
```

```text
$ git commit -m "fix critical auth bug"

⚠ gitsetu: Identity mismatch detected!
  Expected: engineering@company.com (profile: work)
  Actual:   personal@gmail.com
```

---

## 06. Ecosystem Comparison

| Feature | `gitego` (Go) | `gguser` (Node) | `git-profile` (Rust/JS) | `karn` (Go) | **GitSetu (Bash)** |
|---------|:---:|:---:|:---:|:---:|:---:|
| **Identity Switching** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Directory-Based Auto Switch** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **SSH Key Generation** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **SSH Config Orchestration** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Pre-Commit Identity Guard** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Absolute Zero Dependencies** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Safe Idempotent Execution** | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 07. Philosophy

In Sanskrit, *Setu (सेतु)* is the bridge that connects two shores without disturbing either. It doesn't change the shore. It doesn't own the water. It simply makes crossing effortless and reliable.

GitSetu is built on the same principle. It does not replace Git, SSH, or your terminal workflow. It bridges the gap between the developer you are in one directory and the developer you are in another — invisibly, correctly, and without asking anything of you after the first setup.

**A tool that demands your attention has failed. GitSetu succeeds when you forget it exists.**

---

[MIT License](LICENSE) — Created by Bhaskar Jha
