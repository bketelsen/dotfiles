# Phase 4: Tool Installation - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

CLI tools installed declaratively via Homebrew with cross-platform package lists. Includes starship prompt, atuin history, bat, direnv, and git configuration. Shell integration (rc files, aliases) is Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Package management
- Single Brewfile with chezmoi templating for platform conditionals
- run_onchange script triggers brew bundle when Brewfile changes
- Use --no-lock flag (no Brewfile.lock committed)
- Include casks in same Brewfile for macOS GUI apps

### Starship config
- Minimal prompt style: directory + git + prompt character
- Show language versions only when relevant (in directories with those files)
- Git status shows branch + staged/modified/untracked counts
- Command duration shown only for slow commands (>2 seconds)

### Atuin settings
- Local only mode (no cloud sync, no account needed)
- Fuzzy search mode
- Global deduplication (each unique command once)
- Ctrl+R keybinding replaces default reverse search

### Tool defaults
- bat: Nord theme, line numbers only in pager mode
- direnv: Standard behavior, warn and require `direnv allow` for untrusted files
- git: Sensible defaults (push.default=current, pull.rebase=true, common aliases)

### Claude's Discretion
- Specific git aliases to include
- Starship color scheme within minimal style
- bat pager configuration details
- Exact threshold for "slow command" duration

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-tool-installation*
*Context gathered: 2026-02-04*
