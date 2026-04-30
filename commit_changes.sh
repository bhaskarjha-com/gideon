#!/bin/bash
set -e
set -x

export GIT_AUTHOR_NAME="Bhaskar Jha"
export GIT_AUTHOR_EMAIL="bhaskarjha.com@gmail.com"
export GIT_COMMITTER_NAME="Bhaskar Jha"
export GIT_COMMITTER_EMAIL="bhaskarjha.com@gmail.com"

# Ensure no locks are lingering
rm -f .git/index.lock || true

# Reset the last commit, leaving changes in the working directory
git reset HEAD~1 || true
rm -f .git/index.lock || true

# Ensure the staging area is completely clean
git reset || true
rm -f .git/index.lock || true

# --- Commit 1: Security & Concurrency ---
git add lib/gitconfig.sh lib/setup.sh lib/verify.sh tests/test_gitconfig.sh tests/test_integration.sh
git commit -m "fix(security): enforce useConfigOnly guardrail and resolve registry race condition"

# --- Commit 2: Docs ---
git add README.md
git commit -m "docs: document opt-in global fallback configuration via home directory"

# --- Commit 3: Enterprise Tests ---
git add tests/test_cli.sh tests/test_concurrency.sh tests/test_discovery.sh tests/test_doctor.sh tests/test_guard.sh tests/test_resilience.sh
git commit -m "test: expand enterprise test coverage for guard, concurrency, and diagnostics"

# --- Run Tests ---
echo "Running full test suite for verification..."
for f in tests/test_*.sh; do bash "$f"; done
