# =============================================================================
#  .zshrc — Minh's Fullstack & Mobile Dev Setup
#  Clean, fast, organized. Grouped by concern.
# =============================================================================

# ─── Homebrew (must be first — everything else depends on it) ────────────────
# Apple Silicon path. Change to /usr/local for Intel Macs.
export HOMEBREW_PREFIX="/opt/homebrew"
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# ─── Oh My Zsh ──────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Keep plugins minimal. Each one adds startup time.
# git        — aliases (gst, gco, gp, etc.)
# z          — smart directory jumping (way better than cd)
# You can add 'vscode' if you use VS Code, or 'docker' if needed.
plugins=(git z)

source "$ZSH/oh-my-zsh.sh"

# ─── Shell Options ───────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export EDITOR="code"               # Change to: cursor, nvim, vim, etc.
export VISUAL="$EDITOR"
HIST_STAMPS="yyyy-mm-dd"

# ─── Node.js (fnm — fast, reads .nvmrc automatically) ───────────────────────
# Install:     brew install fnm
# Usage:       fnm install 20 && fnm default 20
# Per-project: just drop a .nvmrc file — fnm switches automatically on cd
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

# ─── Python ──────────────────────────────────────────────────────────────────
# Homebrew Python takes priority over Xcode's /usr/bin/python3.
# Xcode uses its own Python internally via absolute paths — this doesn't
# affect it. You just want YOUR terminal to use Homebrew's version.
#
# Golden rules:
#   - Never "pip install" globally — use pipx for CLI tools, venv for projects
#   - Never sudo pip install anything
#   - Xcode's Python will take care of itself; don't try to sync versions
#
# Homebrew Python is already in PATH via brew shellenv above.
# This adds the user-local bin for pipx and pip --user installs:
export PATH="$HOMEBREW_PREFIX/opt/python@3/libexec/bin:$PATH"

# ─── Java / Android (Mobile Dev) ────────────────────────────────────────────
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# ─── Go ──────────────────────────────────────────────────────────────────────
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOPRIVATE="bitbucket.org/dragontailcom/*"
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"

# Project-specific CGO flags (consider moving to direnv or project Makefile)
export CGO_CPPFLAGS="-I$HOMEBREW_PREFIX/opt/unixodbc/include/"
export CGO_LDFLAGS="-L$HOMEBREW_PREFIX/opt/unixodbc/lib"

# ─── Ruby (Homebrew) ────────────────────────────────────────────────────────
# Homebrew Ruby + its gem bin path so `pod`, `bundler`, `fastlane` etc. are found.
# Never use `sudo gem install` — Homebrew Ruby installs gems to user-writable paths.
export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
export PATH="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin:$PATH" 2>/dev/null
export GEM_HOME="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)" 2>/dev/null

# Pin your Ruby gems in iOS projects with a Gemfile:
#   source "https://rubygems.org"
#   gem "cocoapods", "~> 1.15"
#   gem "fastlane"
# Then: bundle install (uses Bundler, installs per-project)
#        bundle exec pod install (runs CocoaPods from the Gemfile version)

# ─── SSH (use macOS Keychain — no ssh-agent spawning) ────────────────────────
# macOS handles ssh-agent via Keychain automatically.
# Just make sure ~/.ssh/config has:
#   Host *
#     UseKeychain yes
#     AddKeysToAgent yes
#     IdentityFile ~/.ssh/id_ed25519

# ─── Local bin ───────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ─── Zsh Plugins (loaded last) ──────────────────────────────────────────────
# These must come after everything else, especially syntax-highlighting.
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null

# ─── Aliases ─────────────────────────────────────────────────────────────────
alias reload="source ~/.zshrc"
alias ll="ls -lahG"
alias ..="cd .."
alias ...="cd ../.."

# Git shortcuts (on top of OMZ git plugin)
alias gs="git status"
alias gc="git commit"
alias gd="git diff"
alias gl="git log --oneline -15"

# Mobile dev
alias adb-devices="adb devices"
alias ios-sim="open -a Simulator"
alias pod-clean="cd ios && pod deintegrate && pod install && cd .."

# ─── Project-specific overrides (optional) ───────────────────────────────────
# If you use direnv for per-project env vars (highly recommended):
# eval "$(direnv hook zsh)"

# Source local overrides that shouldn't be committed to your dotfiles repo
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
