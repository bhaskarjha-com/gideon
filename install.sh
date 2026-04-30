#!/usr/bin/env bash
# GitSetu Installer
#
# This script downloads the gitsetu executable, makes it executable,
# and places it in ~/.local/bin (which is added to PATH if missing).
#
# Usage: curl -sL https://raw.githubusercontent.com/bhaskarjha-com/gitsetu/main/install.sh | bash

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/bhaskarjha-com/gitsetu/main/gitsetu"
INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE="$INSTALL_DIR/gitsetu"

echo "Downloading GitSetu..."
mkdir -p "$INSTALL_DIR"
curl -sL "$REPO_URL" -o "$EXECUTABLE"
chmod +x "$EXECUTABLE"

echo "✓ GitSetu installed to $EXECUTABLE"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "Please add the following line to your ~/.bashrc or ~/.zshrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
echo "You can now run 'gitsetu setup' or use 'gitsetu add' to get started."
