#!/bin/bash
# =============================================================================
# Dotfiles Audit Script for macOS
# Run: chmod +x audit.sh && ./audit.sh
# This will analyze your current shell, Node, Python, and tooling setup
# and output a report with recommendations.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

issues=0
warnings=0

header() { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}\n"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; ((warnings++)); }
fail()   { echo -e "  ${RED}✗${NC} $1"; ((issues++)); }
info()   { echo -e "  ${BLUE}ℹ${NC} $1"; }

echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Dotfiles Audit — Fullstack Dev (macOS)   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"

# ─── Shell ───────────────────────────────────────────────────────────────────
header "Shell Environment"

CURRENT_SHELL=$(basename "$SHELL")
info "Current shell: $CURRENT_SHELL"

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
  ok "Using zsh (macOS default since Catalina)"
else
  warn "Not using zsh — consider switching: chsh -s /bin/zsh"
fi

if [[ -f ~/.zshrc ]]; then
  ZSHRC_LINES=$(wc -l < ~/.zshrc)
  info ".zshrc has $ZSHRC_LINES lines"
  if (( ZSHRC_LINES > 200 )); then
    warn ".zshrc is very long ($ZSHRC_LINES lines) — consider splitting into modular files"
  fi
else
  fail "No .zshrc found"
fi

# Check for conflicting shell configs
for f in ~/.bash_profile ~/.bashrc ~/.bash_login; do
  if [[ -f "$f" ]]; then
    warn "Found $f — this is ignored by zsh and may cause confusion. Consider removing or migrating."
  fi
done

if [[ -f ~/.zprofile ]] && [[ -f ~/.zshrc ]]; then
  ZPROFILE_PATHS=$(grep -c 'PATH' ~/.zprofile 2>/dev/null || echo 0)
  ZSHRC_PATHS=$(grep -c 'PATH' ~/.zshrc 2>/dev/null || echo 0)
  if (( ZPROFILE_PATHS > 0 && ZSHRC_PATHS > 0 )); then
    warn "PATH is modified in both .zprofile and .zshrc — this can cause duplicates"
  fi
fi

# Check PATH for duplicates
IFS=':' read -rA path_entries <<< "$PATH"
declare -A seen_paths
dupes=0
for p in "${path_entries[@]}"; do
  if [[ -n "${seen_paths[$p]+x}" ]]; then
    ((dupes++))
  fi
  seen_paths[$p]=1
done
if (( dupes > 0 )); then
  warn "PATH has $dupes duplicate entries — slows down shell startup"
else
  ok "No duplicate PATH entries"
fi

# Shell startup time
if command -v zsh &>/dev/null; then
  STARTUP_TIME=$( { time zsh -i -c exit; } 2>&1 | grep real | awk '{print $2}')
  info "Shell startup time: $STARTUP_TIME"
  SECONDS_PART=$(echo "$STARTUP_TIME" | sed 's/[^0-9.]//g' | tail -1)
  if (( $(echo "$SECONDS_PART > 1.0" | bc -l 2>/dev/null || echo 0) )); then
    warn "Shell startup is slow (>1s) — check for heavy init scripts (nvm, conda, etc.)"
  fi
fi

# ─── Oh My Zsh / Frameworks ─────────────────────────────────────────────────
header "Zsh Framework"

if [[ -d ~/.oh-my-zsh ]]; then
  info "Oh My Zsh is installed"
  if [[ -f ~/.zshrc ]]; then
    PLUGINS=$(grep '^plugins=' ~/.zshrc 2>/dev/null || echo "")
    if [[ -n "$PLUGINS" ]]; then
      PLUGIN_COUNT=$(echo "$PLUGINS" | tr '(' '\n' | tr ')' '\n' | tr ' ' '\n' | grep -c '[a-z]' || echo 0)
      info "Active plugins: $PLUGINS"
      if (( PLUGIN_COUNT > 15 )); then
        warn "Too many OMZ plugins ($PLUGIN_COUNT) — each adds startup time. Keep it under 10."
      fi
    fi
  fi
elif command -v starship &>/dev/null; then
  ok "Using Starship prompt (lightweight, fast)"
else
  info "No zsh framework detected — consider Starship for a fast, minimal prompt"
fi

# ─── Homebrew ────────────────────────────────────────────────────────────────
header "Homebrew"

if command -v brew &>/dev/null; then
  ok "Homebrew installed: $(brew --version | head -1)"
  BREW_PREFIX=$(brew --prefix)

  if [[ -f "$BREW_PREFIX/bin/brew" ]]; then
    if ! grep -q 'brew shellenv\|HOMEBREW' ~/.zshrc 2>/dev/null && \
       ! grep -q 'brew shellenv\|HOMEBREW' ~/.zprofile 2>/dev/null; then
      warn "Homebrew shellenv not sourced in .zshrc or .zprofile"
    fi
  fi

  if [[ -f ~/Brewfile ]] || [[ -f ~/.Brewfile ]]; then
    ok "Brewfile found — good for reproducibility"
  else
    warn "No Brewfile found — run 'brew bundle dump' to create one for syncing"
  fi
else
  fail "Homebrew not installed — essential for macOS dev setup"
fi

# ─── Node.js / npm ──────────────────────────────────────────────────────────
header "Node.js & npm"

NODE_MANAGERS=()
if [[ -d ~/.nvm ]] || command -v nvm &>/dev/null 2>&1; then NODE_MANAGERS+=("nvm"); fi
if command -v fnm &>/dev/null; then NODE_MANAGERS+=("fnm"); fi
if command -v volta &>/dev/null; then NODE_MANAGERS+=("volta"); fi
if command -v n &>/dev/null; then NODE_MANAGERS+=("n"); fi
if command -v asdf &>/dev/null && asdf plugin list 2>/dev/null | grep -q nodejs; then NODE_MANAGERS+=("asdf"); fi
if command -v mise &>/dev/null; then NODE_MANAGERS+=("mise"); fi

if (( ${#NODE_MANAGERS[@]} == 0 )); then
  fail "No Node version manager found — install fnm or volta"
elif (( ${#NODE_MANAGERS[@]} > 1 )); then
  warn "Multiple Node version managers detected: ${NODE_MANAGERS[*]} — pick ONE to avoid conflicts"
  if [[ " ${NODE_MANAGERS[*]} " =~ " nvm " ]]; then
    warn "nvm is the slowest option — consider migrating to fnm (drop-in replacement) or volta"
  fi
else
  MANAGER="${NODE_MANAGERS[0]}"
  if [[ "$MANAGER" == "nvm" ]]; then
    warn "Using nvm — it adds 200-500ms to shell startup. Consider fnm (compatible, 40x faster) or volta"
  else
    ok "Using $MANAGER for Node version management"
  fi
fi

if command -v node &>/dev/null; then
  info "Node: $(node --version)"
fi

if [[ -f ~/.npmrc ]]; then
  info ".npmrc found"
  if grep -qi '//registry.*:_authToken' ~/.npmrc 2>/dev/null; then
    warn ".npmrc contains auth tokens — make sure this is NOT committed to git"
  fi
else
  info "No global .npmrc — consider creating one with sensible defaults"
fi

# ─── Python ──────────────────────────────────────────────────────────────────
header "Python"

PY_MANAGERS=()
if command -v pyenv &>/dev/null; then PY_MANAGERS+=("pyenv"); fi
if command -v conda &>/dev/null; then PY_MANAGERS+=("conda"); fi
if command -v mise &>/dev/null && mise plugins list 2>/dev/null | grep -q python; then PY_MANAGERS+=("mise"); fi
if command -v asdf &>/dev/null && asdf plugin list 2>/dev/null | grep -q python; then PY_MANAGERS+=("asdf"); fi

if (( ${#PY_MANAGERS[@]} == 0 )); then
  info "No Python version manager — fine if you only need system Python or use Docker"
elif (( ${#PY_MANAGERS[@]} > 1 )); then
  warn "Multiple Python managers: ${PY_MANAGERS[*]} — pick one to avoid PATH conflicts"
else
  ok "Using ${PY_MANAGERS[0]} for Python management"
fi

if command -v python3 &>/dev/null; then
  info "Python3: $(python3 --version)"
  info "python3 location: $(which python3)"
fi

if command -v pipx &>/dev/null; then
  ok "pipx available — good for global CLI tools"
else
  info "Consider installing pipx for global Python CLI tools (avoids polluting system Python)"
fi

# ─── Mobile Development ─────────────────────────────────────────────────────
header "Mobile Development"

if [[ -n "${ANDROID_HOME:-}" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  ok "ANDROID_HOME/ANDROID_SDK_ROOT is set"
else
  if [[ -d ~/Library/Android/sdk ]]; then
    warn "Android SDK exists at ~/Library/Android/sdk but ANDROID_HOME is not set"
  else
    info "No Android SDK detected"
  fi
fi

if command -v java &>/dev/null; then
  info "Java: $(java -version 2>&1 | head -1)"
  if [[ -n "${JAVA_HOME:-}" ]]; then
    ok "JAVA_HOME is set: $JAVA_HOME"
  else
    warn "JAVA_HOME is not set — React Native and Android builds may fail"
  fi
else
  info "No Java installed"
fi

if command -v xcodebuild &>/dev/null; then
  ok "Xcode CLI tools installed"
  info "Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo 'unknown')"
else
  warn "Xcode CLI tools not installed — run: xcode-select --install"
fi

if command -v pod &>/dev/null; then
  ok "CocoaPods installed: $(pod --version)"
else
  info "CocoaPods not installed"
fi

if command -v flutter &>/dev/null; then
  info "Flutter: $(flutter --version 2>/dev/null | head -1)"
fi

# ─── Git ─────────────────────────────────────────────────────────────────────
header "Git"

if command -v git &>/dev/null; then
  ok "Git: $(git --version)"

  GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -n "$GIT_NAME" ]]; then
    info "Git user: $GIT_NAME <$GIT_EMAIL>"
  else
    warn "Git user.name not configured globally"
  fi

  if git config --global init.defaultBranch &>/dev/null; then
    ok "Default branch: $(git config --global init.defaultBranch)"
  else
    warn "Default branch not set — add: git config --global init.defaultBranch main"
  fi

  if [[ -f ~/.gitignore_global ]] || [[ -f ~/.config/git/ignore ]]; then
    ok "Global .gitignore found"
  else
    warn "No global .gitignore — create one to exclude .DS_Store, .env, node_modules, etc."
  fi
else
  fail "Git not installed"
fi

# ─── Misc Tools ──────────────────────────────────────────────────────────────
header "Useful Tools Check"

for tool in gh fzf ripgrep fd jq bat eza delta lazygit; do
  cmd=$tool
  [[ "$tool" == "ripgrep" ]] && cmd="rg"
  [[ "$tool" == "fd" ]] && cmd="fd"
  if command -v "$cmd" &>/dev/null; then
    ok "$tool installed"
  else
    info "$tool not installed (recommended)"
  fi
done

# ─── Docker ──────────────────────────────────────────────────────────────────
header "Containers"

if command -v docker &>/dev/null; then
  ok "Docker available"
elif command -v orbstack &>/dev/null || [[ -d /Applications/OrbStack.app ]]; then
  ok "OrbStack available (lighter Docker alternative)"
else
  info "No Docker/OrbStack found"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
header "Summary"

echo -e "  ${RED}Issues:   $issues${NC}"
echo -e "  ${YELLOW}Warnings: $warnings${NC}"
echo ""

if (( issues + warnings == 0 )); then
  echo -e "  ${GREEN}${BOLD}Your setup looks clean!${NC}"
elif (( issues > 5 || warnings > 10 )); then
  echo -e "  ${RED}${BOLD}Your setup needs attention. Consider using the dotfiles kit to start fresh.${NC}"
else
  echo -e "  ${YELLOW}${BOLD}A few things to tidy up — check the warnings above.${NC}"
fi

echo ""
echo -e "${BOLD}Tip:${NC} Run this script after making changes to verify improvements."
