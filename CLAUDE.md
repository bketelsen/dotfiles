# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository supporting macOS (Apple Silicon only) and Linux. Chezmoi manages dotfiles by maintaining source templates in this repository and applying them to target machines.

Linux support is intentionally distribution agnostic. All that matters is that we can install Homebrew or use an existing Homebrew install.

## Key Commands

```bash
chezmoi diff              # Preview changes before applying
chezmoi apply             # Apply dotfiles to home directory
chezmoi apply -v          # Apply with verbose output
chezmoi edit ~/.bashrc    # Edit source file and re-encrypt if needed
chezmoi status            # Show managed files status
chezmoi doctor            # Verify chezmoi and encryption setup
```

## Architecture

### Chezmoi File Naming Conventions

Files in this repo use chezmoi prefixes that control how they're processed:

- `dot_` → becomes `.` (e.g., `dot_bashrc` → `~/.bashrc`)
- `symlink_` → creates symlink to target
- `.tmpl` suffix → processed as Go template
- `encrypted_` prefix → decrypted during apply
- `run_once_before_` → script runs once before other files
- `run_onchange_before_` → script runs when its content changes

### Template System

Templates use Go template syntax with chezmoi context:

- `.chezmoi.os` - "darwin" or "linux"
- `.chezmoi.arch` - hardware architecture
- `.chezmoi.homeDir` - user's home directory
- `.homebrew_prefix` - computed: `/opt/homebrew` (macOS) or `/home/linuxbrew/.linuxbrew` (Linux)

Platform-specific blocks:

```go
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{- else if eq .chezmoi.os "linux" }}
# Linux-specific config
{{- end }}
```

### .chezmoiignore Logic

The ignore file uses **inverted logic**: patterns are IGNORED, so to include a file only on macOS, you ignore it when NOT darwin:

```go
{{- if ne .chezmoi.os "darwin" }}
Library/   # This INCLUDES Library/ on macOS by ignoring it elsewhere
{{- end }}
```

### Shell Configuration Structure

```
dot_shell/functions.d/     # Shared functions sourced by both bash and zsh
dot_bash/symlink_functions.d → ../dot_shell/functions.d
dot_zsh/symlink_functions.d  → ../dot_shell/functions.d
```

Both shells source `~/.shell/functions.d/*.sh` for common functions (git, nav, utils).

### Encryption

Uses age encryption with keys at `~/.config/chezmoi/key.txt`. Files prefixed with `encrypted_` are automatically decrypted during apply. The public key in `.chezmoi.toml.tmpl` is safe to commit (encrypts only).

### Automated Scripts

Located in `.chezmoiscripts/`:

- `run_once_before_00-setup-age-key.sh.tmpl` - generates age key on first run
- `run_onchange_before_install-packages.sh.tmpl` - runs `brew bundle` when Brewfile changes

## Platform Support

- **macOS**: Apple Silicon (arm64) only - Intel Macs explicitly fail
- **Linux**: x86_64 with Linuxbrew
- Platform validation happens in `.chezmoi.toml.tmpl` using `fail` directive
