# Dotfiles

## What This Is

A chezmoi-managed dotfiles repository for cross-platform use across macOS (zsh) and Linux (bash). A single curl command bootstraps a fresh machine from zero to fully configured with tools, shell settings, and decrypted secrets.

## Core Value

One command takes a fresh machine to a fully working environment — Homebrew, CLI tools, shell configs, and secrets all in place.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Bootstrap script installable via curl from GitHub README
- [ ] Bootstrap installs Homebrew if not present
- [ ] Bootstrap installs chezmoi and triggers init/apply
- [ ] Chezmoi configured with age encryption for secrets
- [ ] Bitwarden CLI integration for secret retrieval
- [ ] age setup/decryption handled during bootstrap
- [ ] atuin configured with sensible defaults
- [ ] bat configured with sensible defaults
- [ ] direnv configured with sensible defaults
- [ ] starship prompt configured with sensible defaults
- [ ] zsh configuration for macOS
- [ ] bash configuration for Linux
- [ ] Modular functions.d directories for both bash and zsh
- [ ] Works identically on Mac laptop, Linux desktop, and Linux servers

### Out of Scope

- Minimal vs full installation profiles — single setup for all machines for now
- GUI application configs — CLI tools only
- Non-Homebrew package managers — Homebrew on both platforms

## Context

**Target machines:**
- Mac laptop (zsh default)
- Linux desktop (bash default)
- Linux servers (bash default)

**Key tools to configure:**
- atuin — shell history sync/search
- bat — cat replacement with syntax highlighting
- direnv — directory-specific environment variables
- starship — cross-shell prompt

**Secrets to manage:**
- API keys
- SSH keys
- Authentication tokens

**Shell architecture:**
- Modular `.d` directories for functions (easy to add/extend)
- Shared logic where possible, shell-specific where needed

## Constraints

- **Package manager**: Homebrew on both Linux and macOS — consistency over native package managers
- **Encryption**: age for secrets — simpler than GPG, chezmoi has native support
- **Secret source**: Bitwarden CLI (`bw`) — user's existing password manager

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Homebrew on Linux | Consistency with macOS, single package manager to maintain | — Pending |
| age over GPG | Simpler setup, better chezmoi integration, no keyserver complexity | — Pending |
| Single setup (no profiles) | Simplicity for now, can add machine profiles later if needed | — Pending |
| Modular functions.d pattern | Easy to add/remove shell functions without touching main configs | — Pending |

---
*Last updated: 2026-02-04 after initialization*
