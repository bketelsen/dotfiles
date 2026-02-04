# Phase 4: Tool Installation - Research

**Researched:** 2026-02-04
**Domain:** CLI tools via Homebrew with chezmoi templating (starship, atuin, bat, direnv, git)
**Confidence:** HIGH

## Summary

Researched declarative CLI tool installation via Homebrew using chezmoi's run_onchange script pattern, plus configuration for starship prompt, atuin shell history, bat syntax highlighter, direnv environment loader, and git. The user's decisions lock in specific approaches: single Brewfile with chezmoi templating for platform conditionals, `--no-lock` flag (no Brewfile.lock), and specific tool configurations.

The core pattern uses a `run_onchange_` script that embeds the Brewfile as a heredoc and pipes it to `brew bundle --file=/dev/stdin --no-lock`. This triggers re-installation only when the package list changes. Platform-specific packages (casks on macOS, Linux-only brews) are handled via chezmoi template conditionals within the Brewfile content.

Tool configurations follow XDG conventions where supported: starship uses `~/.config/starship.toml`, atuin uses `~/.config/atuin/config.toml`, bat uses `~/.config/bat/config`. Git configuration uses traditional `~/.gitconfig` and `~/.gitignore_global`. The direnv hook must be added to shell rc files (Phase 5 integration point).

**Primary recommendation:** Create a single `run_onchange_before_install-packages.sh.tmpl` that embeds a Brewfile heredoc with platform conditionals, then create individual config files for each tool as chezmoi-managed templates.

## Standard Stack

The established tools for CLI tool installation in this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Homebrew | latest | Package manager | Works on both macOS and Linux, declared project-wide decision |
| brew bundle | built-in | Declarative package management | Native Homebrew subcommand, Brewfile support |
| chezmoi | v2.69.3+ | Dotfile/config management | Already established in project, templating for platform conditionals |

### CLI Tools Being Installed
| Tool | Homebrew Package | Purpose | Config Location |
|------|------------------|---------|-----------------|
| starship | `starship` | Cross-shell prompt | `~/.config/starship.toml` |
| atuin | `atuin` | Shell history sync/search | `~/.config/atuin/config.toml` |
| bat | `bat` | cat replacement with syntax highlighting | `~/.config/bat/config` |
| direnv | `direnv` | Per-directory env vars | `~/.config/direnv/direnvrc` (optional) |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `brew bundle` | Process Brewfile | run_onchange script execution |
| `--no-lock` flag | Skip Brewfile.lock | User decision: no lock file |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single Brewfile | Separate files per tool | More files, harder to see full picture |
| brew bundle | Individual brew install commands | No declarative state, harder to maintain |
| Embedded heredoc | Separate Brewfile | Extra file to manage, chezmoi can't template it directly |

**Installation:**
```bash
# All tools installed via Brewfile, no manual installation needed
# The run_onchange script handles everything declaratively
```

## Architecture Patterns

### Recommended Project Structure
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl                           # Already exists, platform detection
├── .chezmoiignore                               # Already exists, platform filtering
├── .chezmoiscripts/
│   ├── run_once_before_00-setup-age-key.sh.tmpl # Already exists
│   └── run_onchange_before_install-packages.sh.tmpl  # NEW: Brewfile + brew bundle
├── dot_config/
│   ├── starship.toml                            # NEW: starship prompt config
│   ├── atuin/
│   │   └── config.toml                          # NEW: atuin settings
│   └── bat/
│       └── config                               # NEW: bat settings
├── dot_gitconfig.tmpl                           # NEW: git configuration
└── dot_gitignore_global                         # NEW: global git ignores
```

### Pattern 1: Brewfile Embedded in run_onchange Script
**What:** Embed the Brewfile content directly in the script as a heredoc, piped to brew bundle
**When to use:** Always - this is the user-decided pattern
**Example:**
```bash
# run_onchange_before_install-packages.sh.tmpl
# Source: https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/
#!/bin/sh
set -e

# Brewfile hash: {{ include "dot_config/private_Brewfile.tmpl" | sha256sum }}
# The above comment triggers re-run when Brewfile content changes

{{ .homebrew_prefix }}/bin/brew bundle --file=/dev/stdin --no-lock <<EOF
# Taps
tap "homebrew/bundle"

# Core CLI tools
brew "starship"
brew "atuin"
brew "bat"
brew "direnv"

{{- if eq .chezmoi.os "darwin" }}
# macOS-only casks
cask "font-meslo-lg-nerd-font"
{{- end }}
EOF
```

### Pattern 2: run_onchange with External Hash
**What:** Include hash of external file in comment to trigger on that file's changes
**When to use:** When Brewfile content is managed separately or templated
**Example:**
```bash
# run_onchange_before_install-packages.sh.tmpl
# Source: https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/
#!/bin/sh
# Brewfile hash: {{ include ".Brewfile.tmpl" | sha256sum }}
# Script re-runs whenever .Brewfile.tmpl content changes

brew bundle --file="{{ .chezmoi.sourceDir }}/.Brewfile" --no-lock
```

### Pattern 3: Platform Conditionals in Brewfile
**What:** Use chezmoi template conditionals to include platform-specific packages
**When to use:** For casks (macOS only) or Linux-specific tools
**Example:**
```bash
# Inside the heredoc or template
{{- if eq .chezmoi.os "darwin" }}
# macOS GUI applications
cask "iterm2"
cask "rectangle"
{{- end }}

{{- if eq .chezmoi.os "linux" }}
# Linux-specific tools (if any)
brew "linux-specific-tool"
{{- end }}
```

### Pattern 4: XDG Config Files as chezmoi Targets
**What:** Place tool configs in `dot_config/` directory to install to `~/.config/`
**When to use:** For all tools that support XDG (starship, atuin, bat)
**Example:**
```
# Source: dot_config/starship.toml
# Target: ~/.config/starship.toml

# Source: dot_config/atuin/config.toml
# Target: ~/.config/atuin/config.toml
```

### Anti-Patterns to Avoid
- **Separate brew install commands:** Use Brewfile for declarative state, not imperative installs
- **Committing Brewfile.lock:** User decision is `--no-lock` - Homebrew is rolling release
- **Shell hooks in this phase:** Direnv/starship shell hooks belong in Phase 5 (shell integration)
- **run_once for package installation:** Use `run_onchange` so adding packages triggers reinstall
- **Hardcoded Homebrew paths:** Use `{{ .homebrew_prefix }}` from .chezmoi.toml.tmpl

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package installation tracking | Custom state file | `brew bundle --no-lock` | Homebrew handles idempotency |
| Change detection | Manual checksums | `run_onchange_` script naming | chezmoi tracks content hash automatically |
| Platform package lists | Separate script files | Template conditionals in single file | Cleaner, single source of truth |
| Git aliases | Shell aliases | `[alias]` in .gitconfig | Proper git integration, works with git commands |
| Syntax highlighting | Manual escape codes | bat with configured theme | Maintained, hundreds of languages |
| Shell history search | grep + history | atuin | Fuzzy search, sqlite-backed, context-aware |

**Key insight:** Homebrew's `brew bundle` is designed for declarative package management. The `--no-lock` flag is appropriate because Homebrew is a rolling release manager - pinning versions isn't the Homebrew way.

## Common Pitfalls

### Pitfall 1: Script Runs Every Time (Missing run_onchange)
**What goes wrong:** Script named `run_before_install.sh` runs on every `chezmoi apply`
**Why it happens:** Missing `onchange` in script name means no content-change tracking
**How to avoid:** Always use `run_onchange_` prefix for package installation scripts
**Warning signs:** Slow `chezmoi apply`, redundant brew operations in output

### Pitfall 2: Brewfile Changes Don't Trigger Script
**What goes wrong:** Adding packages to Brewfile doesn't reinstall
**Why it happens:** If Brewfile is separate from script, script content doesn't change
**How to avoid:** Either embed Brewfile in script, or include `{{ include "Brewfile" | sha256sum }}` in comment
**Warning signs:** New packages in Brewfile not installed after `chezmoi apply`

### Pitfall 3: Wrong Homebrew Prefix in Script
**What goes wrong:** `brew: command not found` errors
**Why it happens:** Hardcoded `/usr/local/bin/brew` path doesn't work on Apple Silicon or Linux
**How to avoid:** Use `{{ .homebrew_prefix }}/bin/brew` from chezmoi data
**Warning signs:** Works on one platform, fails on another

### Pitfall 4: bat Theme Not Found
**What goes wrong:** bat reports "Theme 'Nord' not found"
**Why it happens:** Theme name is case-sensitive, or custom theme not in cache
**How to avoid:** Use exact theme name from `bat --list-themes` output (Nord is built-in)
**Warning signs:** bat falls back to default theme silently

### Pitfall 5: atuin Sync Enabled Accidentally
**What goes wrong:** atuin prompts for account creation or sync errors
**Why it happens:** Default `auto_sync = true` tries to sync
**How to avoid:** Explicitly set `auto_sync = false` in config.toml (user decision: local only)
**Warning signs:** Network errors, account prompts during shell startup

### Pitfall 6: direnv Hook in Wrong Location
**What goes wrong:** direnv doesn't load .envrc files
**Why it happens:** Hook must be at END of shell rc file, after other prompt manipulators
**How to avoid:** Document that Phase 5 shell integration must place hook correctly
**Warning signs:** "direnv: PS1 cannot be exported" or .envrc not loading

### Pitfall 7: starship Slowing Down Prompt
**What goes wrong:** Prompt takes seconds to render
**Why it happens:** Too many modules enabled, especially git status on large repos
**How to avoid:** Use minimal format (user decision), set appropriate timeouts
**Warning signs:** Visible delay after pressing Enter, especially in git repos

### Pitfall 8: Git Config Platform Differences
**What goes wrong:** Git helpers (credential, diff tool) fail on one platform
**Why it happens:** macOS and Linux have different credential helpers, diff tools
**How to avoid:** Use conditional includes in .gitconfig or template with platform checks
**Warning signs:** "credential helper not found" errors, diff tools not opening

## Code Examples

Verified patterns from official sources:

### Brewfile with Platform Conditionals (Embedded in Script)
```bash
# run_onchange_before_install-packages.sh.tmpl
# Source: https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/
# Source: https://docs.brew.sh/Brew-Bundle-and-Brewfile
#!/bin/sh
set -e

echo "[brew-bundle] Installing packages..."

{{ .homebrew_prefix }}/bin/brew bundle --file=/dev/stdin --no-lock <<'EOF'
# =============================================================================
# Homebrew Bundle - Declarative Package Management
# =============================================================================
# This Brewfile is embedded in a chezmoi run_onchange script
# It re-runs automatically when this content changes

# Taps (custom formula repositories)
tap "homebrew/bundle"

# Core CLI Tools
brew "starship"          # Cross-shell prompt
brew "atuin"             # Shell history search
brew "bat"               # cat with syntax highlighting
brew "direnv"            # Per-directory environment

{{- if eq .chezmoi.os "darwin" }}

# =============================================================================
# macOS-only packages
# =============================================================================
# GUI Applications (casks)
cask "font-meslo-lg-nerd-font"  # Nerd font for starship icons
{{- end }}
EOF

echo "[brew-bundle] Package installation complete"
```

### Starship Minimal Configuration
```toml
# dot_config/starship.toml
# Source: https://starship.rs/config/
# User decision: minimal prompt - directory + git + prompt character

# Don't add blank line between prompts (cleaner)
add_newline = false

# Minimal format: directory, git, character
format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$branch]($style) "
style = "purple"

[git_status]
# User decision: show branch + staged/modified/untracked counts
format = '([$all_status$ahead_behind]($style) )'
staged = '[+$count](green)'
modified = '[~$count](yellow)'
untracked = '[?$count](blue)'
ahead = '[⇡$count](cyan)'
behind = '[⇣$count](cyan)'

[cmd_duration]
# User decision: only show for slow commands (>2 seconds)
min_time = 2000
format = "[$duration]($style) "
style = "yellow"

[character]
success_symbol = "[>](green)"
error_symbol = "[>](red)"

# Disable all language version modules by default
# User decision: show only when relevant (in directories with those files)
# These modules auto-detect, so they'll show when files exist
[python]
format = 'via [$symbol]($style)'

[nodejs]
format = 'via [$symbol]($style)'

[rust]
format = 'via [$symbol]($style)'

[golang]
format = 'via [$symbol]($style)'
```

### Atuin Local-Only Configuration
```toml
# dot_config/atuin/config.toml
# Source: https://docs.atuin.sh/cli/configuration/config/
# User decisions: local only, fuzzy search, global dedup, Ctrl+R binding

# =============================================================================
# Sync Settings
# =============================================================================
# User decision: local only mode (no cloud sync, no account needed)
auto_sync = false

# =============================================================================
# Search Settings
# =============================================================================
# User decision: fuzzy search mode
search_mode = "fuzzy"

# User decision: global deduplication (each unique command once)
filter_mode = "global"

# Ctrl+R behavior (user decision: replaces default reverse search)
filter_mode_shell_up_key_binding = "global"

# =============================================================================
# History Settings
# =============================================================================
# Exclude sensitive commands from history
history_filter = [
  "^export .*=",      # Don't record export with values
  "^set .*=",         # Don't record set with values
  ".*secret.*",       # Skip commands with "secret"
  ".*password.*",     # Skip commands with "password"
  ".*token.*",        # Skip commands with "token"
]

# =============================================================================
# UI Settings
# =============================================================================
# Show command preview
show_preview = true

# Inline height for search UI
inline_height = 20
```

### bat Configuration
```bash
# dot_config/bat/config
# Source: https://github.com/sharkdp/bat#configuration
# User decisions: Nord theme, line numbers only in pager mode

# Theme (user decision: Nord)
--theme="Nord"

# Paging behavior
# When output fits terminal, no pager
# When piped, disable paging
--paging=auto

# Style: line numbers only in pager mode (user decision)
# "numbers" shows line numbers, "plain" is minimal
--style=numbers

# Disable decorations when piping
--decorations=auto
```

### Git Configuration
```toml
# dot_gitconfig.tmpl
# Source: https://git-scm.com/docs/git-config
# User decisions: push.default=current, pull.rebase=true, common aliases

[user]
    # These will be overridden by includeIf or local config
    name = PLACEHOLDER
    email = PLACEHOLDER

[init]
    defaultBranch = main

[push]
    # User decision: push current branch to same-named remote branch
    default = current
    # Automatically set up tracking
    autoSetupRemote = true

[pull]
    # User decision: rebase instead of merge on pull
    rebase = true

[fetch]
    # Clean up deleted remote branches
    prune = true

[rebase]
    # Stash changes before rebase, restore after
    autoStash = true

[diff]
    # Show moved lines in different color
    colorMoved = zebra

[merge]
    # Show original in conflict markers
    conflictStyle = diff3

[core]
    # Global gitignore
    excludesFile = ~/.gitignore_global
{{- if eq .chezmoi.os "darwin" }}
    # macOS: use Keychain for credentials
    # (credential helper handled by git-credential-osxkeychain)
{{- end }}

[alias]
    # Status shortcuts
    s = status -s
    st = status

    # Diff shortcuts
    d = diff
    dc = diff --cached
    ds = diff --stat

    # Branch shortcuts
    br = branch
    co = checkout
    cob = checkout -b

    # Commit shortcuts
    ci = commit
    ca = commit --amend

    # Log shortcuts
    l = log --oneline -20
    lg = log --oneline --graph --decorate -20
    last = log -1 HEAD --stat

    # Useful operations
    undo = reset HEAD~1 --mixed
    unstage = reset HEAD --

    # Show branches with last commit
    branches = branch -vv
```

### Global Gitignore
```gitignore
# dot_gitignore_global
# Source: https://www.atlassian.com/git/tutorials/saving-changes/gitignore
# Global ignores for OS and editor files (not project-specific)

# =============================================================================
# macOS
# =============================================================================
.DS_Store
**/.DS_Store
.AppleDouble
.LSOverride
._*

# =============================================================================
# Linux
# =============================================================================
*~
.directory

# =============================================================================
# Editors
# =============================================================================
# Vim
*.swp
*.swo
*.swn
*~

# VS Code (user-specific, not workspace settings)
.vscode/settings.json
.vscode/launch.json

# JetBrains
.idea/

# =============================================================================
# Temporary files
# =============================================================================
*.tmp
*.temp
*.log
*.bak
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `run_once_` for packages | `run_onchange_` with hash | chezmoi v2.x | Re-runs when content changes, not just first time |
| Separate Brewfile | Embedded heredoc | Best practice | Single file, direct templating support |
| Brewfile.lock | `--no-lock` flag | Homebrew design | Homebrew is rolling release, locks don't work well |
| Manual brew installs | `brew bundle` declarative | brew-bundle stable | Idempotent, declarative, single command |
| zsh-specific prompts | starship cross-shell | ~2020 | Same prompt in bash, zsh, fish |
| Custom history scripts | atuin | ~2022 | sqlite-backed, fuzzy search, context-aware |

**Deprecated/outdated:**
- **oh-my-zsh themes for prompt:** starship provides cross-shell alternative with better performance
- **Manual history management:** atuin replaces with better search and optional sync
- **Brewfile.lock:** Don't use - Homebrew is intentionally rolling release

## Open Questions

Things that couldn't be fully resolved:

1. **Nerd Font installation method**
   - What we know: starship can use Nerd Font symbols, installable via `cask "font-meslo-lg-nerd-font"`
   - What's unclear: Should we use a Nerd Font preset or plain text symbols?
   - Recommendation: Install Nerd Font as cask (macOS), user can choose symbol style. Plain text fallback works without font.

2. **bat theme verification**
   - What we know: Nord is a built-in theme (verified in `bat --list-themes`)
   - What's unclear: Exact case sensitivity of theme name
   - Recommendation: Use `--theme="Nord"` (capital N confirmed in documentation)

3. **starship language version display**
   - What we know: User wants versions "only when relevant (in directories with those files)"
   - What's unclear: Default behavior already does this - should we explicitly configure or rely on defaults?
   - Recommendation: Explicitly configure with `format = 'via [$symbol]($style)'` to hide version but show symbol

4. **direnv shell hook placement**
   - What we know: Hook must be at end of rc file, after prompt manipulators
   - What's unclear: Phase 5 implementation details
   - Recommendation: Document hook placement requirement; Phase 5 handles actual integration

## Sources

### Primary (HIGH confidence)
- [chezmoi.io/user-guide/advanced/install-packages-declaratively/](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/) - Brewfile integration pattern
- [chezmoi.io/user-guide/use-scripts-to-perform-actions/](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) - run_onchange behavior
- [docs.brew.sh/Brew-Bundle-and-Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile) - Brewfile syntax, --no-lock flag
- [starship.rs/config/](https://starship.rs/config/) - Starship configuration options
- [docs.atuin.sh/cli/configuration/config/](https://docs.atuin.sh/cli/configuration/config/) - Atuin configuration
- [github.com/sharkdp/bat](https://github.com/sharkdp/bat) - bat README and configuration
- [direnv.net/docs/hook.html](https://direnv.net/docs/hook.html) - direnv shell hook setup
- [git-scm.com/docs/git-config](https://git-scm.com/docs/git-config) - Git configuration reference

### Secondary (MEDIUM confidence)
- [starship.rs/presets/no-runtimes.html](https://starship.rs/presets/no-runtimes.html) - No runtime versions preset pattern
- [jvns.ca/blog/2024/02/16/popular-git-config-options/](https://jvns.ca/blog/2024/02/16/popular-git-config-options/) - Git config best practices
- [gist.github.com/mwhite/6887990](https://gist.github.com/mwhite/6887990) - Git alias patterns
- [sebastiandedeyne.com/setting-up-a-global-gitignore-file/](https://sebastiandedeyne.com/setting-up-a-global-gitignore-file/) - Global gitignore patterns

### Tertiary (LOW confidence)
- None - all findings verified with primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official docs for all tools, verified Homebrew patterns
- Architecture: HIGH - chezmoi patterns verified against official docs and existing project structure
- Pitfalls: HIGH - Documented in official troubleshooting, common community issues
- Tool configs: HIGH - All configuration options verified against official documentation
- Git config: HIGH - Official git-scm.com documentation

**Research date:** 2026-02-04
**Valid until:** 2026-03-04 (30 days - stable domain, tools update infrequently)

**Phase 5 Integration Notes:**
- Shell hooks for direnv (`eval "$(direnv hook bash)"` / `eval "$(direnv hook zsh)"`) must be added in Phase 5
- Starship initialization (`eval "$(starship init bash)"` / `eval "$(starship init zsh)"`) must be added in Phase 5
- Atuin initialization (`eval "$(atuin init bash)"` / `eval "$(atuin init zsh)"`) must be added in Phase 5
- These belong in shell rc files, not in this phase's tool installation
