# Feature Landscape

**Domain:** chezmoi dotfiles management
**Researched:** 2026-02-04
**Confidence:** HIGH

## Table Stakes

Features users expect in a mature chezmoi dotfiles repository. Missing these = setup feels incomplete or non-functional.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Cross-platform file management | Core chezmoi purpose - manage dotfiles across macOS/Linux | Low | Use `{{ if eq .chezmoi.os "darwin" }}` conditionals in templates |
| Template-based configuration | Essential for handling OS differences without file duplication | Medium | Files with `.tmpl` extension; supports Go templating + Sprig functions |
| Bootstrap script (one-liner) | Standard expectation - new machine setup in one command | Low | `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME` |
| Secret management integration | Never commit secrets to git - required for public repos | Medium | Choose one: age encryption, Bitwarden CLI, or other password manager |
| Declarative package installation | Reproducible environments require automated package setup | Medium | Use `run_onchange_` scripts with `.chezmoidata/packages.yaml` for Homebrew/apt |
| Shell configuration (zsh/bash) | Primary use case - shell dotfiles like `.zshrc`, `.bashrc` | Low | Core dotfiles with functions, aliases, environment variables |
| Git configuration | Universal developer need - `.gitconfig`, `.gitignore_global` | Low | Often with work/personal separation via templates |
| SSH key management | Secure authentication setup | Low | Use `private_dot_ssh/` with age encryption for keys |

## Differentiators

Features that elevate the quality and maintainability of a dotfiles setup. Not expected, but highly valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Modular shell configuration | Maintainability - organized functions vs monolithic configs | Low | Create `dot_config/shell/functions.d/` with sourced modules |
| Reusable template snippets | DRY principle - share common configs via `.chezmoitemplates/` | Medium | Include with `{{ template "snippet" . }}` - pass context explicitly |
| Multi-environment detection | Smart defaults for work/personal/container environments | Medium | Detect via hostname, env vars (`CODESPACES`, `REMOTE_CONTAINERS`) |
| Age encryption for secrets | Modern, simple encryption without GPG complexity | Medium | Use `chezmoi age-keygen` + `encryption = "age"` in config |
| Bitwarden CLI integration | Centralized secret management across all systems | High | Template functions: `{{ bitwarden "item" "name" }}` - cached per run |
| Run-once setup scripts | Idempotent system setup (install tools, configure OS) | Medium | `run_once_before_` and `run_once_after_` scripts with `.tmpl` for conditionals |
| External dependency management | Fetch plugins/themes from external repos | Medium | `.chezmoiexternal.toml` for managed external resources |
| Work/personal profile separation | Single repo, multiple identities (git config, SSH keys) | Medium | Use `promptBoolOnce` or hostname detection to set profile |
| Modern CLI tool integration | Enhanced shell experience (starship, atuin, direnv, bat, fzf) | Medium | Pre-configured with optimal settings, installed via Brewfile |
| Container/DevPod support | Transitory environment setup with `--one-shot` | Low | Detect container env and skip heavy installations |
| Brewfile management | Declarative package management on macOS and Linux (via Linuxbrew) | Low | Template-based `Brewfile.tmpl` with `run_onchange_` installer |
| Automated macOS defaults | Set system preferences programmatically | Medium | `run_once_after_macos-defaults.sh` for `defaults write` commands |

## Anti-Features

Features to explicitly NOT include. Common mistakes in dotfiles management.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Commit secrets in plaintext | Security vulnerability - leaked credentials | Always use age encryption or password manager integration |
| Overly complex templating | Maintenance nightmare - hard to debug | Keep templates simple; use `.chezmoitemplates/` for complex logic |
| Managing system files directly | Requires sudo, breaks on updates, not portable | Use `run_once_` scripts to configure, don't manage `/etc/*` files |
| Version-locking every tool | Brittle across systems with different package repos | Let package managers handle versions; only lock if compatibility issue |
| Monolithic shell configs | Hard to debug, slow shell startup | Split into modular `functions.d/` with lazy loading |
| Storing large binaries | Bloats git repo, slow clones | Use `.chezmoiexternal.toml` to fetch at apply-time |
| Run scripts on every apply | Slow, non-idempotent | Use `run_onchange_` or `run_once_` instead of bare `run_` |
| Managing IDE configs globally | IDEs have sync, conflicts with project-local configs | Exclude IDE directories in `.chezmoiignore` unless truly universal |
| Copying entire HOME | Overwhelming, manages cache/temp files | Be selective; use `.chezmoiignore` to exclude non-config directories |
| Complex multi-stage bootstrap | Fragile, hard to debug when it fails | Single curl command should work; scripts handle prerequisites |

## Feature Dependencies

```
Core Dependencies:
Bootstrap → Git repository (hosted on GitHub/GitLab)
Templates → chezmoi configuration (chezmoi.toml)
Secrets → age encryption OR Bitwarden CLI
Cross-platform → Template conditionals (.chezmoi.os, .chezmoi.hostname)

Package Installation:
Brewfile → Homebrew installed (via run_once_before script)
Declarative packages → .chezmoidata/packages.yaml + run_onchange_ script
Tool configs → Tools installed first (via packages)

Advanced Features:
Bitwarden → Bitwarden CLI installed + authenticated
External deps → .chezmoiexternal.toml format
Reusable templates → .chezmoitemplates/ directory structure
Work/personal → Prompt functions OR hostname detection
```

## MVP Recommendation

For MVP (minimal viable personal dotfiles), prioritize:

1. **Bootstrap capability** - Single curl command that works
2. **Shell configuration** - `.zshrc`/`.bashrc` with basic aliases and environment
3. **Cross-platform templates** - macOS and Linux detection with conditional blocks
4. **Basic secret management** - age encryption for SSH keys and sensitive configs
5. **Declarative packages** - Brewfile with `run_onchange_` installer for core tools
6. **One differentiator** - Choose one: Bitwarden integration OR modular shell structure

This covers "can I use this repo on a new machine?" without complexity debt.

## Defer to Post-MVP

- **External dependencies**: Add when you need vim plugins or themes from external repos
- **Multi-environment detection**: Add when you have work laptop to manage
- **macOS defaults automation**: Add when OS-level settings become annoying to configure manually
- **Container detection**: Add when using DevPods/Codespaces regularly
- **Advanced Bitwarden**: Start with age encryption, migrate to Bitwarden when managing 10+ secrets

## Feature Complexity Guide

**Low Complexity** (< 1 hour to implement):
- Basic templates with OS conditionals
- `.chezmoiignore` patterns
- Bootstrap one-liner setup
- Brewfile management
- Simple `run_once_` scripts

**Medium Complexity** (2-4 hours to implement):
- Age encryption setup with multiple machines
- Modular shell configuration structure
- `.chezmoitemplates/` reusable snippets
- Work/personal profile separation
- `run_onchange_` declarative package installation
- Modern tool integration (starship, atuin, direnv)

**High Complexity** (4+ hours to implement):
- Bitwarden CLI integration with templates
- Complex multi-environment detection logic
- External dependency orchestration
- macOS system preferences automation
- Advanced template composition patterns

## Sources

### Official Documentation (HIGH confidence)
- [chezmoi User Guide - Setup](https://www.chezmoi.io/user-guide/setup/)
- [chezmoi User Guide - Templating](https://www.chezmoi.io/user-guide/templating/)
- [chezmoi User Guide - Scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [chezmoi - Install Packages Declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)
- [chezmoi - Age Encryption](https://www.chezmoi.io/user-guide/encryption/age/)
- [chezmoi - Bitwarden Functions](https://www.chezmoi.io/reference/templates/bitwarden-functions/)
- [chezmoi - .chezmoiignore](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
- [chezmoi - .chezmoitemplates](https://www.chezmoi.io/reference/special-directories/chezmoitemplates/)
- [chezmoi - macOS Guide](https://www.chezmoi.io/user-guide/machines/macos/)

### Real-World Examples (MEDIUM confidence)
- [abrauner/dotfiles - Cross-platform with 1Password](https://github.com/abrauner/dotfiles)
- [MovieMaker93/devpod-dotfiles-chezmoi](https://github.com/MovieMaker93/devpod-dotfiles-chezmoi)
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew](https://alfonsofortunato.com/posts/dotfile/)

### Community Resources (MEDIUM confidence)
- [Managing dotfiles with Chezmoi - Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/)
- [Taking Control of My Dotfiles with chezmoi (Jan 2026)](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/)
- [Protecting Secrets in Dotfiles with Chezmoi](https://kidoni.dev/chezmoi-templates-and-secrets)

### Tool Integration Examples (MEDIUM confidence)
- [HotThoughts/dotfiles - Starship, Atuin, Fish](https://github.com/HotThoughts/dotfiles)
- [gazorby/dotfiles - Comprehensive tool integration](https://github.com/gazorby/dotfiles)
