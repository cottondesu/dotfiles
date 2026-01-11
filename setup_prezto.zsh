#!/bin/zsh

if [ -z "$ZSH_VERSION" ]; then
  echo "Error: This script must be run with zsh. Please run: zsh setup_prezto.zsh"
  exit 1
fi


# Prezto Installation Script
# Reference: https://qiita.com/rocca0504/items/2457c9d44988645e04a7

# 1. Clone Prezto
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  echo "Cloning Prezto..."
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
else
  echo "Prezto already cloned."
fi

# 2. Create Symlinks for Prezto runcoms
# Note: This will only link files that do not already exist in $HOME.
# If you manage .zshrc in your dotfiles repo, that will take precedence if linked first.
echo "Setting up Prezto configuration links..."

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  target="${ZDOTDIR:-$HOME}/.${rcfile:t}"
  if [ ! -e "$target" ]; then
    echo "Linking $rcfile to $target"
    ln -s "$rcfile" "$target"
  else
    echo "Skipping $target (already exists)"
  fi
done

# 3. Install Powerlevel10k
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/external/powerlevel10k" ]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/external/powerlevel10k"
  ln -s "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/external/powerlevel10k/powerlevel10k.zsh-theme" "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/functions/prompt_powerlevel10k_setup"
fi

# Source Prezto to enable 'prompt' command
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

prompt -s powerlevel10k

echo "Prezto setup complete."
