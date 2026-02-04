# Dotfiles

## What This Is

A chezmoi-managed dotfiles repository for cross-platform use across macOS (zsh) and Linux (bash). A single curl command bootstraps a fresh machine from zero to fully configured with tools, shell settings, and decrypted secrets.

## Core Value

One command takes a fresh machine to a fully working environment — Homebrew, CLI tools, shell configs, and secrets all in place.

## Current State

**Version:** v1 MVP (shipped 2026-02-04)

**Shipped:**
- Single curl command bootstraps fresh machine
- Age encryption with automatic key generation
- Bitwarden CLI integration for secrets
- Cross-platform support (macOS Apple Silicon, Linux)
- CLI tools: starship, atuin, bat, direnv, fzf, eza, fd
- Shell configs: zsh (macOS), bash (Linux) with modular functions.d

**Stats:**
- 856 lines of configuration
- 63 commits
- 23 requirements shipped

## Requirements

### Validated

- ✓ Bootstrap script installable via curl from GitHub README — v1
- ✓ Bootstrap installs Homebrew if not present — v1
- ✓ Bootstrap installs chezmoi and triggers init/apply — v1
- ✓ Bootstrap scripts are idempotent (safe to re-run) — v1
- ✓ Bootstrap has error handling with clear messages — v1
- ✓ Chezmoi configured with age encryption for secrets — v1
- ✓ Age keys generated automatically during first setup — v1
- ✓ Bitwarden CLI integration for secret retrieval — v1
- ✓ Key backup/recovery procedures documented — v1
- ✓ starship prompt configured with sensible defaults — v1
- ✓ atuin configured with sensible defaults — v1
- ✓ bat configured with sensible defaults — v1
- ✓ direnv configured with sensible defaults — v1
- ✓ Git configured with sensible defaults — v1
- ✓ zsh configuration for macOS — v1
- ✓ bash configuration for Linux — v1
- ✓ Modular functions.d directories for both shells — v1
- ✓ functions.d files automatically sourced on startup — v1
- ✓ Shared shell logic works across both shells — v1
- ✓ Templates detect OS and adjust configuration — v1
- ✓ Platform-specific files handled via .chezmoiignore — v1
- ✓ Homebrew paths correctly set for all platforms — v1
- ✓ Works identically on Mac, Linux desktop, Linux servers — v1

### Active

(None — ready for next milestone)

### Out of Scope

- Minimal vs full installation profiles — single setup for all machines for now
- GUI application configs — CLI tools only
- Non-Homebrew package managers — Homebrew on both platforms
- GPG encryption — age is simpler with better chezmoi integration
- Fish shell — not used on target machines
- Intel Mac support — Apple Silicon only

## Context

**Target machines:**
- Mac laptop (zsh default, Apple Silicon)
- Linux desktop (bash default)
- Linux servers (bash default)

**Key tools configured:**
- starship — cross-shell prompt with git status
- atuin — shell history sync/search (local-only mode)
- bat — cat replacement with syntax highlighting (Nord theme)
- direnv — directory-specific environment variables
- fzf — fuzzy finder
- eza — modern ls replacement
- fd — modern find replacement

**Shell architecture:**
- Modular `.d` directories for functions (git.sh, nav.sh, utils.sh)
- POSIX-compatible function files shared between zsh and bash
- Cached HOMEBREW_PREFIX for fast startup

## Constraints

- **Package manager**: Homebrew on both Linux and macOS — consistency over native package managers
- **Encryption**: age for secrets — simpler than GPG, chezmoi has native support
- **Secret source**: Bitwarden CLI (`bw`) — user's existing password manager
- **macOS architecture**: Apple Silicon only — Intel Mac explicitly blocked

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Homebrew on Linux | Consistency with macOS, single package manager to maintain | ✓ Good |
| age over GPG | Simpler setup, better chezmoi integration, no keyserver complexity | ✓ Good |
| Single setup (no profiles) | Simplicity for now, can add machine profiles later if needed | ✓ Good |
| Modular functions.d pattern | Easy to add/remove shell functions without touching main configs | ✓ Good |
| POSIX sh for bootstrap | Maximum compatibility across shells | ✓ Good |
| Apple Silicon only | Simplifies platform matrix, Intel Mac use declining | ✓ Good |
| Embedded Brewfile heredoc | Keeps package list with install script | ✓ Good |
| atuin local-only mode | No sync complexity, fuzzy search, sensitive filtering | ✓ Good |
| Identical zsh/bash function files | Maintainability over shell-specific optimizations | ✓ Good |
| fzf Ctrl-R disabled with atuin | Prevents keybinding conflict | ✓ Good |

---
*Last updated: 2026-02-04 after v1 milestone*
