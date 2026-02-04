# Phase 3: Cross-Platform Support - Research

**Researched:** 2026-02-04
**Domain:** chezmoi cross-platform templating
**Confidence:** HIGH

## Summary

Researched chezmoi's cross-platform capabilities for managing dotfiles across macOS and Linux. The core approach uses chezmoi's built-in template variables (`.chezmoi.os`, `.chezmoi.arch`) combined with Go's `text/template` conditionals to create adaptive configurations. Platform-specific file handling is achieved through templated `.chezmoiignore` files, not filename suffixes.

Key findings: chezmoi does NOT have built-in platform-specific file suffixes like `_darwin` or `_linux`. The standard approach uses three strategies: (1) single `.tmpl` files with `{{ if eq .chezmoi.os "..." }}` conditionals for mostly-similar files, (2) completely separate files managed via `.chezmoiignore` for wholly-different files, and (3) `.chezmoidata.yaml` for storing computed values like Homebrew prefix as reusable variables.

Homebrew paths vary by platform: `/opt/homebrew` on Apple Silicon, `/usr/local` on Intel Mac, and `/home/linuxbrew/.linuxbrew` on Linux. These should be detected at config-generation time and stored in `.chezmoidata.yaml`, not computed in every template.

**Primary recommendation:** Use `.chezmoi.toml.tmpl` to compute platform-specific values once (Homebrew prefix, OS ID), store them in the `[data]` section, then reference them in all other templates via simple variable lookups.

## Standard Stack

The established tools for cross-platform chezmoi configuration:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | v2.69.3+ | Dotfile manager with templating | Built-in cross-platform variables, mature templating system |
| Go text/template | stdlib | Template engine | Native to chezmoi, no external dependencies |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| .chezmoidata.yaml | n/a | Static platform data | Store computed values (Homebrew prefix, etc.) |
| .chezmoiignore | n/a | Platform-specific file exclusion | Completely different files per platform |
| chezmoi.toml.tmpl | n/a | Dynamic config generation | Compute platform values once at init |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| .chezmoiignore | Separate template files with no ignore | More file duplication, less clear intent |
| .chezmoidata.yaml | Compute in every template | Slower, repeated logic, harder to maintain |
| Template conditionals | External shell scripts | Harder to debug, breaks chezmoi's atomic model |

**Installation:**
```bash
# chezmoi already installed via Homebrew (Phase 1)
# No additional packages needed
```

## Architecture Patterns

### Recommended Project Structure
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Dynamic config with platform detection
├── .chezmoidata.yaml           # Static platform data (Homebrew prefix)
├── .chezmoiignore              # Platform-specific file exclusion
├── dot_bashrc.tmpl             # Template with platform conditionals
├── dot_zshrc.tmpl              # Template with platform conditionals
├── private_dot_ssh/
│   └── config.tmpl             # SSH config with platform paths
└── run_once_install-packages.sh.tmpl  # Platform-specific package installs
```

### Pattern 1: Platform Detection in Config Template
**What:** Use `.chezmoi.toml.tmpl` to compute platform-specific values once and store in `[data]` section
**When to use:** For any platform-specific value needed by multiple templates (Homebrew prefix, OS ID)
**Example:**
```toml
# .chezmoi.toml.tmpl
# Source: https://www.chezmoi.io/reference/templates/variables/

{{- $homebrewPrefix := "" -}}
{{- if eq .chezmoi.os "darwin" -}}
  {{- if eq .chezmoi.arch "arm64" -}}
    {{- $homebrewPrefix = "/opt/homebrew" -}}
  {{- else -}}
    {{- $homebrewPrefix = "/usr/local" -}}
  {{- end -}}
{{- else if eq .chezmoi.os "linux" -}}
  {{- $homebrewPrefix = "/home/linuxbrew/.linuxbrew" -}}
{{- end -}}

encryption = "age"

[age]
    identity = "{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"
    recipient = "PLACEHOLDER_PUBLIC_KEY"

[data]
    homebrew_prefix = "{{ $homebrewPrefix }}"
```

### Pattern 2: Inline Conditionals for Minor Differences
**What:** Single `.tmpl` file with `{{ if eq .chezmoi.os "..." }}` blocks for platform-specific lines
**When to use:** Files mostly the same across platforms with a few different lines
**Example:**
```bash
# dot_bashrc.tmpl
# Source: https://www.chezmoi.io/user-guide/templating/

# Homebrew setup
{{ if ne .homebrew_prefix "" -}}
eval "$({{ .homebrew_prefix }}/bin/brew shellenv)"
{{ end -}}

# Platform-specific aliases
{{ if eq .chezmoi.os "darwin" -}}
alias ls='ls -G'
{{ else if eq .chezmoi.os "linux" -}}
alias ls='ls --color=auto'
{{ end -}}
```

### Pattern 3: Platform-Specific File Exclusion
**What:** Use `.chezmoiignore` with template logic to exclude files on wrong platforms
**When to use:** Completely different files per platform (macOS-only plist, Linux-only systemd)
**Example:**
```
# .chezmoiignore
# Source: https://www.chezmoi.io/reference/special-files/chezmoiignore/

# Ignore macOS-specific files on Linux
{{- if ne .chezmoi.os "darwin" }}
Library/
.yabairc
.skhdrc
{{ end -}}

# Ignore Linux-specific files on macOS
{{- if ne .chezmoi.os "linux" }}
.xinitrc
.Xresources
{{ end -}}
```

### Pattern 4: Static Data in .chezmoidata.yaml
**What:** Store computed platform values in `.chezmoidata.yaml` for template reuse
**When to use:** Values computed in `.chezmoi.toml.tmpl` that templates need to reference
**Example:**
```yaml
# .chezmoidata.yaml
# Source: https://www.chezmoi.io/reference/special-files/chezmoidata-format/

# Computed by .chezmoi.toml.tmpl, consumed by templates
homebrew_prefix: /opt/homebrew
os_id: darwin
arch: arm64
```

### Anti-Patterns to Avoid
- **External shell scripts for platform detection:** chezmoi already provides `.chezmoi.os` and `.chezmoi.arch` - don't shell out to `uname`
- **Filename suffixes like `file_darwin.tmpl`:** Not a chezmoi feature, use `.chezmoiignore` instead
- **Computing Homebrew prefix in every template:** Compute once in `.chezmoi.toml.tmpl`, reference via variable
- **Silently skipping on unsupported platforms:** Templates should fail loudly with `{{ fail "..." }}` for unsupported configurations

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Platform detection | `uname` scripts, `/etc/os-release` parsing | `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.osRelease` | Already parsed, cached, reliable across all platforms |
| Homebrew path detection | `which brew`, `command -v brew` | Compute in `.chezmoi.toml.tmpl` once | Evaluated at config generation, not every template |
| Distro-specific logic | Nested conditionals per distro | Combine OS+distro: `{{ $osid := printf "%s-%s" .chezmoi.os .chezmoi.osRelease.id }}` | Flattens conditionals, recommended in official docs |
| File exclusion | Conditional template wrapper scripts | `.chezmoiignore` templating | Native chezmoi feature, clearer intent |

**Key insight:** chezmoi templates are computed during `chezmoi apply`, not at shell runtime. This means you can safely compute expensive operations (path detection, command existence checks) in templates without runtime performance cost. Don't optimize for runtime performance by using shell variables - optimize for maintainability by using chezmoi's template features.

## Common Pitfalls

### Pitfall 1: Assuming Filename Suffixes Work
**What goes wrong:** Creating files named `dot_bashrc_darwin.tmpl` expecting chezmoi to auto-select by platform
**Why it happens:** Confusion from other tools (Ansible, Salt) that support platform suffixes
**How to avoid:** Use `.chezmoiignore` for platform-specific file selection, not filename suffixes
**Warning signs:** Files with `_darwin`, `_linux` in their names that aren't being processed

### Pitfall 2: .chezmoiignore Logic Inversion
**What goes wrong:** Using `{{ if eq .chezmoi.os "darwin" }}` to include files (seems intuitive but wrong)
**Why it happens:** chezmoi installs everything by default, so you must negate: "ignore unless platform matches"
**How to avoid:** Always use `{{ if ne .chezmoi.os "..." }}` (not equal) in `.chezmoiignore`
**Warning signs:** Files appearing on wrong platforms, or expected files missing

### Pitfall 3: Templates in .chezmoidata Files
**What goes wrong:** Creating `.chezmoidata.yaml.tmpl` and expecting template evaluation
**Why it happens:** Most chezmoi files support `.tmpl` suffix, so assumption seems reasonable
**How to avoid:** Use `.chezmoi.toml.tmpl` for dynamic data, `.chezmoidata.yaml` for static data only
**Warning signs:** Error "template syntax" in `.chezmoidata` files, variables not defined

### Pitfall 4: Intel Mac Homebrew Prefix Assumption
**What goes wrong:** Hardcoding `/usr/local` as Homebrew prefix breaks on Apple Silicon
**Why it happens:** Legacy assumption from Intel Mac era (pre-2020)
**How to avoid:** Detect architecture with `.chezmoi.arch` and use correct prefix
**Warning signs:** Command not found errors on Apple Silicon, wrong PATH on Linux

### Pitfall 5: macOS Name Confusion
**What goes wrong:** Using `{{ if eq .chezmoi.os "macos" }}` which never matches
**Why it happens:** macOS is the marketing name, but runtime.GOOS returns "darwin"
**How to avoid:** Always use `darwin` in templates, never `macos` or `osx`
**Warning signs:** macOS-specific blocks never executing, conditions always falling through

### Pitfall 6: Template Whitespace Handling
**What goes wrong:** Extra blank lines appear in generated files from template conditionals
**Why it happens:** Template blocks leave newlines even when content is empty
**How to avoid:** Use `{{-` (trim left) and `-}}` (trim right) to remove surrounding whitespace
**Warning signs:** Extra blank lines in diffs, file line numbers don't match

## Code Examples

Verified patterns from official sources:

### Detecting Current Platform
```bash
# Check what chezmoi sees on current system
# Source: https://www.chezmoi.io/reference/commands/data/
chezmoi data --format=yaml

# Test a template expression
# Source: https://www.chezmoi.io/reference/commands/execute-template/
chezmoi execute-template "{{ .chezmoi.os }}/{{ .chezmoi.arch }}"
```

### Platform-Specific Aliases with Whitespace Trimming
```bash
# dot_aliases.tmpl
# Source: https://www.chezmoi.io/user-guide/templating/

{{- if eq .chezmoi.os "darwin" }}
# macOS-specific aliases
alias ls='ls -G'
alias finder='open -a Finder'
{{- else if eq .chezmoi.os "linux" }}
# Linux-specific aliases
alias ls='ls --color=auto'
alias open='xdg-open'
{{- end }}
```

### Failing on Unsupported Platforms
```toml
# .chezmoi.toml.tmpl
# Source: https://github.com/twpayne/chezmoi/discussions/1670

{{- if and (ne .chezmoi.os "darwin") (ne .chezmoi.os "linux") }}
{{-   fail "Unsupported OS: only darwin and linux are supported" }}
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
{{-   if and (ne .chezmoi.arch "arm64") (ne .chezmoi.arch "amd64") }}
{{-     fail "Unsupported architecture: only arm64 (Apple Silicon) and amd64 (Intel) supported on macOS" }}
{{-   end }}
{{- end }}
```

### Homebrew Prefix Detection
```toml
# .chezmoi.toml.tmpl
# Source: https://docs.brew.sh/Installation

{{- $homebrewPrefix := "" }}
{{- if eq .chezmoi.os "darwin" }}
{{-   if eq .chezmoi.arch "arm64" }}
{{-     $homebrewPrefix = "/opt/homebrew" }}
{{-   else }}
{{-     $homebrewPrefix = "/usr/local" }}
{{-   end }}
{{- else if eq .chezmoi.os "linux" }}
{{-   $homebrewPrefix = "/home/linuxbrew/.linuxbrew" }}
{{- end }}

[data]
    homebrew_prefix = "{{ $homebrewPrefix }}"
```

### Using Homebrew Prefix in Templates
```bash
# dot_bashrc.tmpl

# Homebrew environment setup
{{- if ne .homebrew_prefix "" }}
eval "$({{ .homebrew_prefix }}/bin/brew shellenv)"
{{- end }}

# Add Homebrew binaries to PATH
export PATH="{{ .homebrew_prefix }}/bin:{{ .homebrew_prefix }}/sbin:$PATH"
```

### Platform-Specific Package Installation Script
```bash
# run_once_install-packages.sh.tmpl
# Source: https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/

#!/bin/sh
set -e

{{- if eq .chezmoi.os "darwin" }}
# macOS packages via Homebrew
brew install \
    git \
    tmux \
    neovim
{{- else if eq .chezmoi.os "linux" }}
# Linux packages via Homebrew
brew install \
    git \
    tmux \
    neovim
{{- end }}
```

### XDG Directory Handling
```bash
# dot_config/shell/env.tmpl
# Source: https://specifications.freedesktop.org/basedir/latest/

# XDG Base Directory Specification
{{- if eq .chezmoi.os "linux" }}
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
{{- else if eq .chezmoi.os "darwin" }}
# macOS doesn't follow XDG by default, but we can set it
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
{{- end }}
```

### Combining OS and Distribution for Flatter Conditionals
```toml
# .chezmoi.toml.tmpl
# Source: https://www.chezmoi.io/user-guide/machines/linux/

{{- $osid := .chezmoi.os -}}
{{- if hasKey .chezmoi.osRelease "id" -}}
{{-   $osid = printf "%s-%s" .chezmoi.os .chezmoi.osRelease.id -}}
{{- end -}}

[data]
    os_id = "{{ $osid }}"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcode `/usr/local` for Homebrew | Detect arch, use `/opt/homebrew` on Apple Silicon | ~2020 (M1 Macs) | Must check `.chezmoi.arch` to get correct prefix |
| Sprig template functions | Moving away from sprig | v2.68+ | Some sprig functions deprecated, prefer Go stdlib or chezmoi-specific |
| Nested OS/distro conditionals | Combined `$osid` variable | v2.x | Flatter templates, easier to read |
| `missingkey=invalid` default | `missingkey=error` default | v2.x | Templates fail on typos instead of silently using wrong values |

**Deprecated/outdated:**
- **Sprig's `fail` function:** Still works but sprig library is unmaintained, prefer native error handling
- **`writeToStdout` in regular templates:** Only works during `chezmoi init`, use in init scripts only
- **Hardcoded `/usr/local`:** Breaks on Apple Silicon and Linux, always detect dynamically

## Open Questions

Things that couldn't be fully resolved:

1. **Should we support Intel Macs?**
   - What we know: User decided "Apple Silicon only (arm64)" in CONTEXT.md
   - What's unclear: If Intel Mac support was explicitly excluded or just not considered
   - Recommendation: Follow user decision - fail loudly on Intel Mac with clear error message

2. **WSL-specific handling needed?**
   - What we know: User said "WSL treated as regular Linux - no special handling"
   - What's unclear: Are there any WSL-specific gotchas that should be documented?
   - Recommendation: Treat as Linux, test on WSL during validation phase

3. **Which XDG directories need platform handling?**
   - What we know: XDG spec defines HOME, CONFIG, DATA, CACHE, STATE directories
   - What's unclear: Which ones should we explicitly set vs let default?
   - Recommendation: Set all five (CONFIG, DATA, CACHE, STATE, RUNTIME) explicitly on both platforms for consistency

4. **Error message verbosity for unsupported platforms?**
   - What we know: User wants "fail loudly on unsupported platforms"
   - What's unclear: How verbose? Just "unsupported" or include links to supported platforms?
   - Recommendation: Include OS/arch detected, list of supported combinations, and link to docs

## Sources

### Primary (HIGH confidence)
- [chezmoi.io/user-guide/templating/](https://www.chezmoi.io/user-guide/templating/) - Template variables documentation
- [chezmoi.io/reference/templates/variables/](https://www.chezmoi.io/reference/templates/variables/) - Complete variable reference
- [chezmoi.io/user-guide/machines/macos/](https://www.chezmoi.io/user-guide/machines/macos/) - macOS-specific patterns
- [chezmoi.io/user-guide/machines/linux/](https://www.chezmoi.io/user-guide/machines/linux/) - Linux-specific patterns
- [chezmoi.io/reference/special-files/chezmoiignore/](https://www.chezmoi.io/reference/special-files/chezmoiignore/) - Platform exclusion patterns
- [chezmoi.io/reference/special-files/chezmoidata-format/](https://www.chezmoi.io/reference/special-files/chezmoidata-format/) - Static data files
- [chezmoi.io/reference/commands/data/](https://www.chezmoi.io/reference/commands/data/) - Viewing template data
- [docs.brew.sh/Installation](https://docs.brew.sh/Installation) - Homebrew prefix documentation

### Secondary (MEDIUM confidence)
- [abrauner/dotfiles](https://github.com/abrauner/dotfiles) - Real-world cross-platform example with work/personal separation
- [alfonsofortunato.com/posts/dotfile/](https://alfonsofortunato.com/posts/dotfile/) - Cross-platform patterns with Nix and Brew
- [natelandau.com/managing-dotfiles-with-chezmoi/](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Comprehensive chezmoi guide
- [github.com/twpayne/chezmoi/discussions/1670](https://github.com/twpayne/chezmoi/discussions/1670) - Template fail function discussion

### Tertiary (LOW confidence)
- [specifications.freedesktop.org/basedir/](https://specifications.freedesktop.org/basedir/latest/) - XDG Base Directory Specification (external, not chezmoi-specific)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official docs confirm all capabilities, current chezmoi v2.69.3 installed
- Architecture: HIGH - Patterns verified against official docs and real-world repos
- Pitfalls: HIGH - Documented in official troubleshooting and GitHub discussions
- Homebrew paths: HIGH - Verified against official Homebrew installation docs
- Platform suffixes: HIGH - Confirmed absence in official docs, alternative approach documented

**Research date:** 2026-02-04
**Valid until:** 2026-03-04 (30 days - stable domain, chezmoi updates infrequently)

**Critical finding:** User's CONTEXT.md mentioned "chezmoi's native suffix conventions (_darwin, _linux)" but this is NOT a chezmoi feature. Research found these suffixes don't exist in official documentation. The correct approach uses `.chezmoiignore` templating instead. Planning phase should clarify this with the user.
