#!/usr/bin/env bash
# Gideon CLI Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/bhaskarjha-com/gideon/main/install.sh | bash

set -euo pipefail

# Define colors
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

GIDEON_REPO="https://github.com/bhaskarjha-com/gideon.git"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gideon"
BIN_DIR="${HOME}/.local/bin"

echo -e "${BLUE}${BOLD}Installing Gideon CLI...${RESET}"

# Check prerequisites
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: Git is required to install Gideon.${RESET}" >&2
    exit 1
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo -e "Updating existing installation at ${INSTALL_DIR}..."
    git -C "$INSTALL_DIR" fetch --quiet
    git -C "$INSTALL_DIR" reset --hard origin/main --quiet
else
    echo -e "Cloning repository to ${INSTALL_DIR}..."
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}"
    git clone --quiet "$GIDEON_REPO" "$INSTALL_DIR"
fi

# Create symlink
echo -e "Creating executable symlink in ${BIN_DIR}..."
mkdir -p "$BIN_DIR"
ln -sf "${INSTALL_DIR}/gideon" "${BIN_DIR}/gideon"
chmod +x "${INSTALL_DIR}/gideon"

# Verify PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "\n${BOLD}Warning:${RESET} ${BIN_DIR} is not in your PATH."
    echo -e "You may need to add the following line to your ~/.bashrc or ~/.zshrc:"
    echo -e "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo -e "\n${GREEN}${BOLD}Gideon installed successfully!${RESET}"
echo -e "Run ${BOLD}gideon setup${RESET} to configure your Git identities."
