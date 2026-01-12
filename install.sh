#!/bin/bash
set -e

# Master installation script

echo "=========================================="
echo "Start Dotfiles Setup"
echo "=========================================="

echo "[1/3] Setting up symbolic links..."
sh ./setup_links.sh

echo "[2/3] Setting up Prezto (Zsh)..."
zsh ./setup_prezto.zsh

echo "[3/3] Installing Apps with Homebrew..."
sh ./homebrew_install.sh

if [ $? -eq 0 ]; then
  echo "Installation successful. Reloading shell..."
  exec zsh -l
else
  echo "Installation failed. Please check the logs."
fi