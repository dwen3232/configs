# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## MUST FOLLOW

- Never read files directly from `~/` or any absolute path under `/Users/`. All dotfiles are managed here via Stow. Use the repo path instead:
  - `~/.config/foo` → `dot-config/foo`
  - `~/.claude/foo` → `dot-claude/foo`
  - `~/.pi/foo` → `dot-pi/foo`
  - `~/foo` → `dot-foo` (if it exists)
- If a file isn't in the repo, ask the user rather than reading it from the home directory.

## Overview

Personal dotfiles repository for macOS. Uses GNU Stow to symlink `dot-*` directories to `~/.*`.

## Key Commands

```bash
# Setup
just bootstrap         # Install Brewfile deps, sync submodules, stow configs
just check-deps        # Check whether Brewfile deps are installed
just stow-configs      # Create symlinks to home directory

# Development
just sync-submodules   # Sync git submodules (tmux plugins)
just upgrade           # Upgrade Brewfile dependencies
```

## Architecture

- **Stow**: `dot-config/` → `~/.config/`, `dot-claude/` → `~/.claude/`, `dot-pi/` → `~/.pi/`
- **Justfile**: All installation and setup automation
- **Submodules**: tmux plugins in `dot-config/tmux/plugins/`
- **Shell**: zsh with Oh My Zsh, sources `.zshrc.*` files (gitignored)

## Subdirectory Documentation

When working with specific tools, read their documentation:
- Neovim: See `dot-config/nvim/README.md`
- Tmux: See `dot-config/tmux/README.md`
- Pi: See `dot-pi/agent/`

**Note**: Keep all README files concise (< 100 lines). Focus on essential architecture and commands only.
