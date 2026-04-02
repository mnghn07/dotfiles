# Dotfiles — Fullstack & Mobile Dev

## Quick Start (New Mac)

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles

# 2. Run the bootstrap script
chmod +x ~/.dotfiles/bootstrap.sh
~/.dotfiles/bootstrap.sh

# 3. Restart terminal
exec zsh
```

## What's Included

| File | Purpose |
|---|---|
| `.zshrc` | Shell config — Homebrew, fnm, Python, Android, Go, Ruby, aliases |
| `.zprofile` | Login shell config (intentionally minimal) |
| `.npmrc` | npm defaults — exact versions, no fund/audit noise |
| `.gitconfig` | Git config — aliases, rebase on pull, credential helper |
| `.gitignore_global` | Ignore .DS_Store, .env, node_modules everywhere |
| `Brewfile` | All CLI tools and apps — one command install |
| `bootstrap.sh` | Full new-Mac setup automation |
| `audit.sh` | Diagnose issues with your current setup |

## Sync Strategy

The bootstrap script uses **symlinks**: your dotfiles live in `~/.dotfiles/` and are symlinked to `$HOME`. This means:

- Edit `~/.zshrc` → you're editing the repo file
- `cd ~/.dotfiles && git add -A && git commit -m "update" && git push`
- On another Mac: `cd ~/.dotfiles && git pull`

For machine-specific settings (work email, proprietary env vars), use `~/.zshrc.local` which is sourced at the end of `.zshrc` but not committed.

## Key Decisions

**fnm over nvm** — Same workflow, reads `.nvmrc`, auto-switches on `cd`. 40x faster shell startup.

**Homebrew Ruby over rbenv** — Simpler for CocoaPods/Bundler. Use `bundle exec pod install` in projects.

**Homebrew Python over pyenv** — Xcode's Python is separate and untouched. Use `pipx` for global tools, `venv` for projects.

**Symlinks over GNU Stow** — Simpler. The bootstrap script handles backup of existing files automatically.

**Brewfile** — One command (`brew bundle`) installs everything. Run `brew bundle dump --force` to update.
