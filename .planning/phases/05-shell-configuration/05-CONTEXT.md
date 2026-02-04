# Phase 5: Shell Configuration - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Configure zsh (macOS) and bash (Linux) with working prompt, aliases, environment variables, and tool integrations. Shell functions are organized in functions.d directories and automatically sourced. Shared logic works on both shells without duplication.

</domain>

<decisions>
## Implementation Decisions

### Shell startup flow
- Startup should be as fast as possible — minimize operations, defer or lazy-load where possible
- Silent by default, but show verbose status on first shell after login (login shell only)
- Warn once (on first login shell) if an expected tool is missing, then skip silently

### Aliases & functions
- Productivity set: navigation, git shortcuts, common commands with better defaults
- functions.d organized by purpose: git.sh, nav.sh, utils.sh — grouped by what they do
- Git shortcuts: gs=status, ga=add, gc=commit, gp=push, etc.
- Modern replacements: cat→bat, ls→eza/exa, find→fd (if installed)

### Tool integration
- Conditional init: only run `eval $(tool init)` if tool is installed
- direnv: manual `direnv allow` required — no auto-trust
- Add fzf for fuzzy finding

### zsh vs bash split
- Use chezmoi templates to generate shell-specific files from shared templates
- Equal parity: both shells get identical features where possible
- Use zsh-specific features where available: completions, syntax highlighting, autosuggestions

### Claude's Discretion
- Shell startup order (PATH/env vars vs tool detection)
- Alias naming strategy (shadow base commands safely, or new names)
- fzf keybindings (pick non-conflicting bindings, consider atuin overlap on Ctrl+R)
- zsh plugin approach (likely direct sourcing for speed, but Claude can decide)

</decisions>

<specifics>
## Specific Ideas

- Startup speed is a priority — user explicitly wants it "as fast as possible"
- First login shell should be informative (show what's loaded/missing), subsequent shells silent
- fzf added beyond the Phase 4 tools (starship, atuin, direnv)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-shell-configuration*
*Context gathered: 2026-02-04*
