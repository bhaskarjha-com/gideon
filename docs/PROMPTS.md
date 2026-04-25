# gideon — Prompt Library

> **What this is**: Copy-paste prompts for a brand new AI session with ZERO conversation history.
> Each prompt is self-contained — it tells the AI where the code is, what files to read, what standards to follow, and exactly what to do.
>
> **How to use**: Copy the entire prompt block (between the `---` markers) and paste it as your first message in a new session.

---

## Table of Contents

1. [Full Codebase Audit](#1-full-codebase-audit)
2. [Add a New Feature](#2-add-a-new-feature)
3. [Fix a Bug](#3-fix-a-bug)
4. [Add Tests](#4-add-tests)
5. [Improve Documentation](#5-improve-documentation)
6. [Prepare a Release](#6-prepare-a-release)
7. [Security Audit](#7-security-audit)
8. [Add New Platform Support](#8-add-new-platform-support)
9. [Resume & Portfolio Update](#9-resume--portfolio-update)
10. [Competitive Analysis Refresh](#10-competitive-analysis-refresh)
11. [Live Setup Test](#11-live-setup-test)
12. [CI/CD Improvements](#12-cicd-improvements)
13. [Code Refactor / Cleanup](#13-code-refactor--cleanup)
14. [Onboard Yourself (General Context)](#14-onboard-yourself-general-context)

---

## 1. Full Codebase Audit

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Before doing anything, read these files to understand the project:
- /media/sf_dev/pro/gideon/README.md
- /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gideon/lib/core.sh (for constants and state)

Then perform a thorough technical audit:

1. Run all tests: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
2. Run ShellCheck (if available): `shellcheck /media/sf_dev/pro/gideon/gideon /media/sf_dev/pro/gideon/lib/*.sh`
3. Check for bash 4+ violations (this project MUST be bash 3.2 compatible):
   `grep -rn 'declare -A\|mapfile\|readarray\|\${.*,,\}\|\${.*\^\^\}' /media/sf_dev/pro/gideon/lib/ /media/sf_dev/pro/gideon/gideon`
4. Check for unquoted variables and security issues
5. Verify all functions have documentation comments
6. Cross-check README test count matches actual test count
7. Verify CHANGELOG version matches GIDEON_VERSION in lib/core.sh
8. Check the module dependency graph in ARCHITECTURE.md matches actual source imports

Standards:
- Bash 3.2 compatible (no associative arrays, no mapfile, no ${var,,})
- All variables must be quoted
- All output to stderr (>&2), stdout kept clean
- Managed block markers for idempotent config file updates

Create an audit report artifact with: findings, severity, and specific fix recommendations.
Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 2. Add a New Feature

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Before doing anything, read these files IN ORDER to understand the project:
1. /media/sf_dev/pro/gideon/README.md (what the tool does)
2. /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md (how it's built)
3. /media/sf_dev/pro/gideon/lib/core.sh (constants, state arrays)
4. /media/sf_dev/pro/gideon/gideon (main script — note the CRLF self-healing block and gideon_source pattern)

I want to add this feature: [DESCRIBE YOUR FEATURE HERE]

Rules you MUST follow:
- Bash 3.2 compatible: NO declare -A, NO mapfile, NO ${var,,}, NO |&
- All variables must be quoted — no word splitting bugs
- All user-facing output goes to stderr (>&2) using print_* functions from lib/ui.sh
- New functions MUST have a doc comment (purpose, usage, return value)
- If modifying user config files, use managed block markers (# [gideon:managed:start/end])
- Source new lib files via gideon_source() in the main gideon script (NOT direct source)

After implementing:
1. Write tests in tests/test_<module>.sh following the existing pattern (see tests/helpers.sh)
2. Run all tests: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
3. Update README.md (CLI reference table, project structure if new files)
4. Update docs/ARCHITECTURE.md if adding new modules
5. Update CHANGELOG.md

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 3. Fix a Bug

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read these files to understand the project:
- /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gideon/lib/core.sh

The bug is: [DESCRIBE THE BUG, HOW TO REPRODUCE, EXPECTED vs ACTUAL BEHAVIOR]

Follow this process:
1. First, understand the relevant module by reading the lib/*.sh file involved
2. Write a FAILING test that reproduces the bug in tests/test_<module>.sh
3. Fix the bug in the lib file
4. Run the test to confirm it passes
5. Run ALL tests to confirm no regressions: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
6. Update CHANGELOG.md with the fix

Rules:
- Bash 3.2 compatible (no declare -A, mapfile, ${var,,})
- All variables quoted
- Don't break existing tests

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 4. Add Tests

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read these files to understand the testing approach:
- /media/sf_dev/pro/gideon/tests/helpers.sh (test framework: assertions, isolated HOME)
- /media/sf_dev/pro/gideon/tests/test_validate.sh (example of well-written tests)
- /media/sf_dev/pro/gideon/tests/test_integration.sh (example of end-to-end tests)

Current coverage: 72 tests across 7 test files. I want to improve coverage.

Identify gaps by:
1. Reading each lib/*.sh file and listing functions without corresponding tests
2. Checking edge cases not covered (empty input, special characters, permission errors)
3. Looking for untested subcommands (status, verify, guard)

Then write new tests following these patterns:
- Use setup_test_home() for any test that touches files
- Test functions return 0 (pass) or 1 (fail)
- Register with: run_test "description" function_name
- Use assert_* helpers: assert_equals, assert_contains, assert_file_exists, assert_file_contains, assert_exit_code
- Tests MUST NOT touch real ~/.ssh or ~/.gitconfig

Run all tests after adding: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
Update README.md test count.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 5. Improve Documentation

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read ALL documentation files:
- /media/sf_dev/pro/gideon/README.md
- /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gideon/docs/TROUBLESHOOTING.md
- /media/sf_dev/pro/gideon/docs/VISION.md
- /media/sf_dev/pro/gideon/CONTRIBUTING.md
- /media/sf_dev/pro/gideon/CHANGELOG.md

Also read the actual code to verify accuracy:
- /media/sf_dev/pro/gideon/gideon (subcommands, help text)
- /media/sf_dev/pro/gideon/lib/core.sh (version, constants)

Cross-check and fix:
1. Test count in README matches actual (run tests to count)
2. CLI reference table matches actual subcommands in main()
3. Module diagram in ARCHITECTURE.md matches actual lib/*.sh files
4. CHANGELOG version matches GIDEON_VERSION in core.sh
5. Platform table matches detect_os() in platform.sh
6. Bash 3.2 compat table in CONTRIBUTING.md is complete
7. All file paths and cross-references between docs are valid
8. FAQ answers are technically accurate

Also assess quality:
- Is README compelling for a portfolio project?
- Are troubleshooting entries covering real user pain points?
- Is the architecture doc useful for a new contributor?

Create an artifact with all findings and fix everything in-place.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 6. Prepare a Release

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read these files first:
- /media/sf_dev/pro/gideon/lib/core.sh (current GIDEON_VERSION)
- /media/sf_dev/pro/gideon/CHANGELOG.md (current release notes)

I want to prepare release v[VERSION]. Execute this checklist:

1. Update GIDEON_VERSION in lib/core.sh to the new version
2. Update CHANGELOG.md with all changes since last release
3. Run full test suite: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
4. Run ShellCheck if available: `shellcheck /media/sf_dev/pro/gideon/gideon /media/sf_dev/pro/gideon/lib/*.sh`
5. Verify `bash /media/sf_dev/pro/gideon/gideon --version` shows new version
6. Update README.md test count if tests were added
7. Verify all docs are current (cross-check version references)
8. Show me the git commands to tag and push the release

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 7. Security Audit

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/
It generates SSH keys and modifies ~/.gitconfig and ~/.ssh/config.

Read the code:
- /media/sf_dev/pro/gideon/lib/ssh.sh (SSH key generation)
- /media/sf_dev/pro/gideon/lib/gitconfig.sh (config file writing)
- /media/sf_dev/pro/gideon/lib/guard.sh (pre-commit hook — runs on every commit)
- /media/sf_dev/pro/gideon/lib/backup.sh (backup management)

Audit for:
1. File permissions: Are SSH keys created with chmod 600? Is ~/.ssh/config 600?
2. eval/exec usage: Any eval with user-supplied input? (should be zero)
3. Input injection: Can profile labels/emails inject into config files?
4. Temp file safety: Are temp files created securely (mktemp)?
5. Backup exposure: Could backups leak sensitive data?
6. Guard hook: Does it make any network calls? (should not)
7. Path traversal: Can user input escape intended directories?
8. Race conditions: Any TOCTOU issues in file operations?

Also check:
- `grep -rn 'eval\|exec ' /media/sf_dev/pro/gideon/lib/ /media/sf_dev/pro/gideon/gideon`
- `grep -rn 'curl\|wget\|nc ' /media/sf_dev/pro/gideon/lib/`
- `grep -rn 'chmod' /media/sf_dev/pro/gideon/lib/`

Create a security audit report with severity ratings and remediation steps.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 8. Add New Platform Support

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read these files:
- /media/sf_dev/pro/gideon/lib/platform.sh (current OS detection and path normalization)
- /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md (platform design)

I want to add support for: [PLATFORM NAME — e.g., "FreeBSD", "Docker containers", "Codespaces"]

Steps:
1. Add detection logic to detect_os() in lib/platform.sh
2. Add prerequisite install guidance to get_install_guidance()
3. Update get_gitdir_keyword() if path matching differs on this platform
4. Update get_ssh_agent_advice() for platform-specific SSH agent setup
5. Test path normalization for this platform's path format
6. Add tests to tests/test_platform.sh
7. Update README.md platform support table
8. Add platform section to docs/TROUBLESHOOTING.md
9. Run all tests: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`

Rules: Bash 3.2 compatible, all variables quoted, test changes don't break other platforms.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 9. Resume & Portfolio Update

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read these files to understand current state:
- /media/sf_dev/pro/gideon/README.md (features, stats)
- /media/sf_dev/pro/gideon/CHANGELOG.md (what's been done)
- /media/sf_dev/pro/gideon/lib/core.sh (version)

Also check the existing resume artifact if it exists:
- /home/ag-deb/.gemini/antigravity/brain/16b65c7e-2531-45cf-8f76-4ec2b8f4e8f4/resume_brief.md

Run tests to get exact count: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
Count lines: `find /media/sf_dev/pro/gideon/lib /media/sf_dev/pro/gideon/gideon -name "*.sh" -o -name "gideon" | xargs wc -l`

Then update/create the resume_brief.md artifact with:
1. Short resume entry (3-4 bullet points, quantified)
2. Extended resume entry (for DevOps/Platform roles)
3. Technical interview Q&A (5 common questions with answers)
4. Portfolio stats table (LoC, tests, platforms, key innovations)
5. Skills matrix (what this project demonstrates)

Every claim must be backed by verifiable code — no exaggeration.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 10. Competitive Analysis Refresh

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/
It's a zero-dependency bash CLI for automated Git multi-identity and SSH setup.

Read the current analysis if it exists:
- /home/ag-deb/.gemini/antigravity/brain/16b65c7e-2531-45cf-8f76-4ec2b8f4e8f4/competitive_analysis.md

Do fresh web research on:
1. Git identity management tools (any new ones since last analysis?)
2. SSH key management automation tools
3. Dotfiles managers that handle git identity
4. GitHub/GitLab features for multi-account management

For each competitor found, document:
- Name, language, stars, last commit date
- Features: key gen, git config, SSH config, guard hook, cross-platform
- Dependencies required
- Gap vs gideon

Update the competitive analysis with new findings.
Also check if gideon's README comparison table needs updating.
```

---

## 11. Live Setup Test

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

I want to do a LIVE test of the setup wizard. Guide me through:

1. First, show me the dry run: `bash /media/sf_dev/pro/gideon/gideon setup --dry-run`
2. Then run the real setup: `bash /media/sf_dev/pro/gideon/gideon setup`
   - Profile 1 (default): label=global, name=Bhaskar Jha, email=hmmbhaskar@gmail.com
   - Profile 2: label=pro, name=Bhaskar Jha, email=bhaskarjha.com@gmail.com, dir=/media/sf_dev/pro
3. After setup, verify: `bash /media/sf_dev/pro/gideon/gideon verify`
4. Check status: `bash /media/sf_dev/pro/gideon/gideon status`
5. Show me the generated files:
   - cat ~/.gitconfig
   - cat ~/.ssh/config
   - cat ~/.config/gideon/profiles/pro.gitconfig
   - cat ~/.config/gideon/profiles.conf
6. Test SSH connectivity (after I add keys to GitHub)

Note: This is a Debian 13 VM with VirtualBox shared folder at /media/sf_dev/pro/.
The gideon script has CRLF self-healing so it works directly on vboxsf.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 12. CI/CD Improvements

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read the current CI config:
- /media/sf_dev/pro/gideon/.github/workflows/ci.yml

Also read:
- /media/sf_dev/pro/gideon/README.md (badges section)
- /media/sf_dev/pro/gideon/tests/helpers.sh (test framework)

I want to improve CI/CD. Consider adding:
1. Badge that dynamically shows test pass/fail from CI
2. Test output artifact upload in CI
3. Release automation (create GitHub release on tag push)
4. Dependabot or similar for Actions version pinning
5. Matrix expansion (specific macOS versions, specific bash versions)
6. ShellCheck with --severity=warning for strict linting
7. Code coverage approximation (% of lib functions with tests)

Implement what makes sense. Update the CI workflow and README badges.

Rules: Keep the CI simple — this is a bash project, not a monorepo.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 13. Code Refactor / Cleanup

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

Read all source files:
- /media/sf_dev/pro/gideon/gideon
- /media/sf_dev/pro/gideon/lib/*.sh

Look for:
1. Dead code (functions never called)
2. Duplicated logic across modules
3. Functions that are too long (>50 lines) and should be split
4. Inconsistent naming conventions
5. Missing error handling (functions that should return error codes but don't)
6. Hardcoded values that should be in lib/core.sh constants
7. Output going to stdout instead of stderr
8. Variables not declared local inside functions

Rules:
- Bash 3.2 compatible
- All variables quoted
- Don't change function signatures (tests depend on them)
- Run all tests after refactoring: `for f in /media/sf_dev/pro/gideon/tests/test_*.sh; do bash "$f" 2>/dev/null; done`

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 14. Onboard Yourself (General Context)

```
I have a bash CLI project called "gideon" at /media/sf_dev/pro/gideon/

This is a zero-dependency bash 3.2+ CLI tool that automates multi-identity Git and SSH setup across Linux, macOS, and Windows.

Please read these files to fully understand the project before I give you a task:

1. /media/sf_dev/pro/gideon/README.md — What the tool does, CLI reference
2. /media/sf_dev/pro/gideon/docs/ARCHITECTURE.md — How it's built (module diagram, CRLF self-healing, managed blocks, config formats)
3. /media/sf_dev/pro/gideon/docs/VISION.md — Why design decisions were made
4. /media/sf_dev/pro/gideon/lib/core.sh — Constants, state arrays, version
5. /media/sf_dev/pro/gideon/gideon — Main script (note: CRLF self-healing block at top, gideon_source pattern for loading libs)

Key things to know:
- Bash 3.2 compatible (NO declare -A, mapfile, ${var,,})
- All output to stderr, prompts from /dev/tty
- Managed block markers for idempotent config updates
- Tests use isolated $HOME in /tmp (never touch real config)
- VirtualBox shared folder causes CRLF — the script self-heals at runtime
- Use Cwd=/media/sf_dev/pro/niyantra for the run_command tool

After reading, summarize your understanding and I'll give you the task.
```

---

## Tips for Using These Prompts

1. **Always copy the FULL prompt** — the context setup at the beginning is critical
2. **Replace `[PLACEHOLDERS]`** with your specific details
3. **The Cwd workaround** (`/media/sf_dev/pro/niyantra`) is needed because the workspace validator may not recognize the gideon path
4. **If ShellCheck isn't installed**, the AI will skip that step — install with `sudo apt install shellcheck` when you can
5. **Each prompt is self-contained** — no need to reference previous conversations
