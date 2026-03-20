#!/usr/bin/env bash
# Claude Hangar — One-liner installer
# Usage: curl -fsSL https://raw.githubusercontent.com/claude-hangar/claude-hangar/main/install.sh | bash

set -euo pipefail

INSTALL_DIR="${HOME}/.claude-hangar"

echo ""
echo "  Installing Claude Hangar..."
echo "  ───────────────────────────"
echo ""

# Check prerequisites
command -v git &>/dev/null || { echo "Error: git is required"; exit 1; }
command -v node &>/dev/null || { echo "Error: node is required"; exit 1; }

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Cloning claude-hangar..."
  git clone https://github.com/claude-hangar/claude-hangar.git "$INSTALL_DIR"
fi

# Run setup
cd "$INSTALL_DIR"
bash setup.sh

echo ""
echo "Done! Open Claude Code in any project to start."
