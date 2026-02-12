#!/bin/bash
set -e

echo "=== Dotfiles Installer ==="

# Install dependencies
echo "[1/6] Installing packages..."
sudo apt update
sudo apt install -y zsh fzf bat eza fd-find ripgrep curl git

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[2/6] Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[2/6] Oh My Zsh already installed, skipping."
fi

# Install custom plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "[3/6] Installing zsh plugins..."
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# Install Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
  echo "[4/6] Installing Oh My Posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
else
  echo "[4/6] Oh My Posh already installed, skipping."
fi

# Download Oh My Posh themes
echo "[5/6] Downloading Oh My Posh themes..."
oh-my-posh get themes

# Symlink .zshrc
echo "[6/6] Linking .zshrc..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
  echo "  Backed up existing .zshrc to .zshrc.backup"
fi
ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

echo ""
echo "=== Done! ==="
echo "Restart your terminal or run: exec zsh"
