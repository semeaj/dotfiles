#!/bin/bash

echo "=== Dotfiles Installer ==="

# Install apt packages
echo "[1/8] Installing apt packages..."
sudo apt update
sudo apt install -y \
  zsh git curl wget \
  fzf bat fd-find ripgrep \
  htop tmux jq \
  build-essential gcc make cmake \
  unzip zip tar \
  python3 python3-pip \
  libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev \
  zlib1g-dev libncurses-dev libxml2-dev libxmlsec1-dev liblzma-dev

# Install eza (not in all distro repos)
if ! command -v eza &> /dev/null; then
  echo "Installing eza from GitHub..."
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "amd64" ]; then
    EZA_ARCH="x86_64-unknown-linux-gnu"
  elif [ "$ARCH" = "arm64" ]; then
    EZA_ARCH="aarch64-unknown-linux-gnu"
  else
    EZA_ARCH="x86_64-unknown-linux-gnu"
  fi
  EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | jq -r '.tag_name')
  curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
  tar xf /tmp/eza.tar.gz -C /tmp && install -m 755 /tmp/eza ~/.local/bin/eza
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[2/8] Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[2/8] Oh My Zsh already installed, skipping."
fi

# Install custom zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
echo "[3/8] Installing zsh plugins..."
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# Install Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
  echo "[4/8] Installing Oh My Posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
else
  echo "[4/8] Oh My Posh already installed, skipping."
fi
echo "Downloading Oh My Posh themes..."
oh-my-posh get themes

# Install nvm + Node LTS
echo "[5/8] Installing nvm + Node.js..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# Install pyenv + latest Python
echo "[6/8] Installing pyenv + Python..."
if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
fi
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install -s 3.13
pyenv global 3.13

# Install CLI tools to ~/.local/bin
echo "[7/8] Installing CLI tools..."
mkdir -p ~/.local/bin

# Detect architecture
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "arm64" ]; then
  LG_ARCH="Linux_arm64"
  LD_ARCH="Linux_arm64"
  YQ_ARCH="yq_linux_arm64"
else
  LG_ARCH="Linux_x86_64"
  LD_ARCH="Linux_x86_64"
  YQ_ARCH="yq_linux_amd64"
fi

if ! command -v lazygit &> /dev/null; then
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | sed 's/v//')
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_${LG_ARCH}.tar.gz"
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && install -m 755 /tmp/lazygit ~/.local/bin/lazygit
fi

if ! command -v lazydocker &> /dev/null; then
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | jq -r '.tag_name' | sed 's/v//')
  curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_${LD_ARCH}.tar.gz"
  tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker && install -m 755 /tmp/lazydocker ~/.local/bin/lazydocker
fi

if ! command -v yq &> /dev/null; then
  curl -Lo /tmp/yq "https://github.com/mikefarah/yq/releases/latest/download/${YQ_ARCH}"
  install -m 755 /tmp/yq ~/.local/bin/yq
fi

# Install latest Neovim + LazyVim
echo "[8/9] Installing Neovim + LazyVim..."
if [ "$ARCH" = "arm64" ]; then
  NVIM_ARCH="nvim-linux-arm64"
else
  NVIM_ARCH="nvim-linux-x86_64"
fi
curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/${NVIM_ARCH}.tar.gz"
tar xf /tmp/nvim.tar.gz -C /tmp
cp -r /tmp/${NVIM_ARCH}/* ~/.local/

if [ ! -d "$HOME/.config/nvim" ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
fi

# Symlink .zshrc
echo "[9/9] Linking .zshrc..."
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
