#!/bin/bash

echo "=== Dotfiles Installer ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCH=$(dpkg --print-architecture)

# Install apt packages
echo "[1/11] Installing apt packages..."
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

mkdir -p ~/.local/bin

# Create bat symlink (Debian/Ubuntu installs as batcat)
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi

# Install eza (not in all distro repos)
if ! command -v eza &> /dev/null; then
  echo "[2/11] Installing eza from GitHub..."
  if [ "$ARCH" = "amd64" ]; then
    EZA_ARCH="x86_64-unknown-linux-gnu"
  elif [ "$ARCH" = "arm64" ]; then
    EZA_ARCH="aarch64-unknown-linux-gnu"
  else
    EZA_ARCH="x86_64-unknown-linux-gnu"
  fi
  curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
  tar xf /tmp/eza.tar.gz -C /tmp && install -m 755 /tmp/eza ~/.local/bin/eza
else
  echo "[2/11] eza already installed, skipping."
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[3/11] Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[3/11] Oh My Zsh already installed, skipping."
fi

# Install custom zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
echo "[4/11] Installing zsh plugins..."
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# Install Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
  echo "[5/11] Installing Oh My Posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
else
  echo "[5/11] Oh My Posh already installed, skipping."
fi
echo "Downloading Oh My Posh themes..."
mkdir -p ~/.cache/oh-my-posh/themes
curl -sL "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -o /tmp/omp-themes.zip
unzip -oq /tmp/omp-themes.zip -d ~/.cache/oh-my-posh/themes

# Install nvm + Node LTS
echo "[6/11] Installing nvm + Node.js..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# Install pyenv + latest Python
echo "[7/11] Installing pyenv + Python..."
if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
fi
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install -s 3.13
pyenv global 3.13

# Install CLI tools to ~/.local/bin
echo "[8/11] Installing CLI tools..."

if [ "$ARCH" = "arm64" ]; then
  LG_ARCH="Linux_arm64"
  LD_ARCH="Linux_arm64"
  YQ_ARCH="yq_linux_arm64"
  FF_ARCH="linux-aarch64"
else
  LG_ARCH="Linux_x86_64"
  LD_ARCH="Linux_x86_64"
  YQ_ARCH="yq_linux_amd64"
  FF_ARCH="linux-amd64"
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

# Install fastfetch
if ! command -v fastfetch &> /dev/null; then
  echo "Installing fastfetch..."
  curl -Lo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-${FF_ARCH}.deb"
  if sudo -n true 2>/dev/null; then
    sudo dpkg -i /tmp/fastfetch.deb || sudo apt install -f -y
  else
    # Extract from .deb without sudo
    cd /tmp && ar x fastfetch.deb && tar xf data.tar.gz ./usr/bin/fastfetch
    install -m 755 /tmp/usr/bin/fastfetch ~/.local/bin/fastfetch
    cd -
  fi
fi

# Install latest Neovim + LazyVim
echo "[9/11] Installing Neovim + LazyVim..."
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

# Install bat Catppuccin Mocha theme
echo "[10/11] Installing bat Catppuccin theme..."
mkdir -p "$(batcat --config-dir 2>/dev/null || echo ~/.config/bat)/themes"
BAT_THEMES_DIR="$(batcat --config-dir 2>/dev/null || echo ~/.config/bat)/themes"
curl -Lo "$BAT_THEMES_DIR/Catppuccin Mocha.tmTheme" \
  "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
batcat cache --build 2>/dev/null || bat cache --build 2>/dev/null

# Install TPM and tmux plugins
echo "[11/11] Installing TPM + tmux plugins + symlinking configs..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
if [ ! -d "$HOME/.tmux/plugins/tmux" ]; then
  git clone https://github.com/catppuccin/tmux ~/.tmux/plugins/tmux
fi
if [ ! -d "$HOME/.tmux/plugins/tmux-sensible" ]; then
  git clone https://github.com/tmux-plugins/tmux-sensible ~/.tmux/plugins/tmux-sensible
fi

# Symlink configs
mkdir -p ~/.config/bat ~/.config/lazygit ~/.config/fastfetch

ln -sf "$SCRIPT_DIR/config/bat/config" ~/.config/bat/config
ln -sf "$SCRIPT_DIR/config/lazygit/config.yml" ~/.config/lazygit/config.yml
ln -sf "$SCRIPT_DIR/config/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
ln -sf "$SCRIPT_DIR/.tmux.conf" ~/.tmux.conf

# Symlink .zshrc
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
echo "Post-install steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Open tmux and press Ctrl+a then I to install tmux plugins"
echo "  3. Paste Catppuccin Mocha theme into Windows Terminal settings"
