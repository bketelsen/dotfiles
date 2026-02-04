# Phase 3: Cross-Platform Support - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Configuration templates detect OS and adapt automatically for macOS and Linux. Same dotfiles repository produces working configuration on Mac laptop, Linux desktop, and Linux servers. This phase establishes the templating infrastructure — actual platform-specific configs are applied in later phases.

</domain>

<decisions>
## Implementation Decisions

### Platform detection strategy
- Use chezmoi's built-in variables (.chezmoi.os, .chezmoi.arch) — no external scripts
- No Linux distro detection needed — just macOS vs Linux is sufficient
- Architecture detection via .chezmoi.arch (arm64 for Apple Silicon, amd64 for Intel)
- Templates should fail loudly on unsupported platforms rather than skip gracefully

### File organization
- Use chezmoi's native suffix conventions (_darwin, _linux) for platform-specific files
- Files mostly the same across platforms: single .tmpl with {{ if eq .chezmoi.os "..." }} conditionals
- Files completely different per platform: separate file_darwin.tmpl and file_linux.tmpl
- No additional documentation needed — chezmoi conventions make it clear

### Path handling
- Detect Homebrew prefix dynamically using chezmoi.os + chezmoi.arch
- Store Homebrew prefix as reusable variable in .chezmoidata.yaml ({{ .homebrew_prefix }})
- Assume Homebrew is installed when templates run (bootstrap installs it first)

### Platform scope
- macOS: Apple Silicon only (arm64) — no Intel Mac support needed
- Linux: Any distro with Homebrew — no distro-specific handling
- Support both headless servers and desktop environments
- WSL treated as regular Linux — no special handling

### Claude's Discretion
- Which additional paths (XDG directories, etc.) need platform handling
- Exact error messages for unsupported platforms
- Template helper structure if needed

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches using chezmoi best practices.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-cross-platform-support*
*Context gathered: 2026-02-04*
