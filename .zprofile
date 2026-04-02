# =============================================================================
#  .zprofile — Runs ONCE at login (before .zshrc)
#
#  Rule of thumb:
#  - .zprofile  → env vars that only need to be set once (login shells)
#  - .zshrc     → everything else (aliases, prompt, plugins, functions)
#
#  Keep this file minimal. Most config belongs in .zshrc.
# =============================================================================

# Nothing here by default. Homebrew and all PATH setup lives in .zshrc
# so it works in both login and non-login shells (e.g., VS Code terminal).
#
# If a tool's installer adds something here automatically (like rbenv, conda),
# move it to .zshrc instead — otherwise it won't work in VS Code/iTerm splits.
