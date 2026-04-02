#!/bin/bash
# =============================================================================
# New Mac Bootstrap Script
#
# Usage:
#   1. Push your dotfiles to a GitHub repo
#   2. On a new Mac, open Terminal and run:
#      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap.sh)"
#
# This script is idempotent — safe to run multiple times.
# =============================================================================

set -euo pipefail

DOTFILES_REPO="https://github.com/YOUR_USERNAME/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

echo "╔══════════════════════════════════════════════╗"
echo "║         New Mac Bootstrap — Let's go!        ║"
echo "╚══════════════════════════════════════════════╝"

# ─── Xcode CLI Tools ────────────────────────────────────────────────────────
echo "▸ Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  echo "  Installing Xcode CLI tools (this may take a while)..."
  xcode-select --install
  echo "  Press any key after Xcode tools finish installing..."
  read -n 1 -s
fi
echo "  ✓ Xcode CLI tools ready"

# ─── Homebrew ────────────────────────────────────────────────────────────────
echo "▸ Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "  ✓ Homebrew ready ($(brew --version | head -1))"

# ─── Clone Dotfiles ─────────────────────────────────────────────────────────
echo "▸ Setting up dotfiles..."
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  echo "  Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull --rebase
fi

# ─── Symlink Dotfiles ───────────────────────────────────────────────────────
echo "▸ Symlinking dotfiles..."

symlink() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/$1"

  if [[ -L "$dst" ]]; then
    echo "  ↻ $1 (already linked)"
  elif [[ -f "$dst" ]]; then
    echo "  ⚠ $1 exists — backing up to $dst.backup"
    mv "$dst" "$dst.backup"
    ln -s "$src" "$dst"
    echo "  ✓ $1 linked"
  else
    ln -s "$src" "$dst"
    echo "  ✓ $1 linked"
  fi
}

symlink .zshrc
symlink .zprofile
symlink .gitconfig
symlink .gitignore_global
symlink .npmrc
# Add more dotfiles here as needed:
# symlink .zshrc.local
# symlink .ssh/config

git config --global core.excludesfile ~/.gitignore_global

# ─── Brewfile (install all tools at once) ────────────────────────────────────
echo "▸ Installing Homebrew packages from Brewfile..."
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
  brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
  echo "  ✓ Homebrew packages installed"
else
  echo "  ⚠ No Brewfile found — skipping. Create one with: brew bundle dump"
fi

# ─── Node.js ─────────────────────────────────────────────────────────────────
echo "▸ Setting up Node.js..."
if command -v fnm &>/dev/null; then
  fnm install --lts
  echo "  ✓ Node LTS installed via fnm"
else
  echo "  ⚠ fnm not found — install with: brew install fnm"
fi

# Enable corepack for pnpm/yarn
if command -v corepack &>/dev/null; then
  corepack enable
  echo "  ✓ Corepack enabled (pnpm/yarn ready)"
fi

# ─── Python ──────────────────────────────────────────────────────────────────
echo "▸ Setting up Python..."
echo "  Using Homebrew Python: $(python3 --version 2>/dev/null || echo 'not found')"

# Install useful global Python tools
if command -v pipx &>/dev/null; then
  pipx ensurepath
  for tool in black ruff httpie; do
    pipx install "$tool" 2>/dev/null || true
  done
  echo "  ✓ Python CLI tools installed via pipx"
fi

# ─── Ruby / CocoaPods ───────────────────────────────────────────────────────
echo "▸ Setting up Ruby..."
if command -v gem &>/dev/null; then
  gem install cocoapods bundler --no-document 2>/dev/null || true
  echo "  ✓ CocoaPods and Bundler installed"
fi

# ─── macOS Defaults (optional, uncomment what you want) ─────────────────────
echo "▸ Configuring macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable press-and-hold for accent characters (enables key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

echo "  ✓ macOS defaults configured"

# ─── SSH Setup ───────────────────────────────────────────────────────────────
echo "▸ Checking SSH key..."
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "  No SSH key found. Generating one..."
  ssh-keygen -t ed25519 -C "ngh.nhatminh0712@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""

  # Configure SSH to use Keychain
  mkdir -p "$HOME/.ssh"
  cat > "$HOME/.ssh/config" << 'SSHEOF'
Host *
  UseKeychain yes
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
SSHEOF

  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

  echo ""
  echo "  ✓ SSH key generated. Add this to GitHub:"
  echo "  ──────────────────────────────────────────"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "  ──────────────────────────────────────────"
  echo "  Or run: gh auth login"
else
  echo "  ✓ SSH key exists"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║              Setup Complete!                 ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Next steps:                                 ║"
echo "║  1. Restart your terminal (or run: exec zsh) ║"
echo "║  2. Run: gh auth login                       ║"
echo "║  3. Open Xcode → install iOS simulators      ║"
echo "║  4. Open Android Studio → install SDK        ║"
echo "╚══════════════════════════════════════════════╝"
