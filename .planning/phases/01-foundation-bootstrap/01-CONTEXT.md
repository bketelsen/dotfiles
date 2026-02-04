# Phase 1: Foundation & Bootstrap - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Bootstrap a fresh machine with a single command that installs Homebrew and chezmoi, then applies dotfiles. This phase delivers the invocation mechanism and bootstrap logic only — encryption, platform-specific templates, tool installation, and shell configuration are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Invocation method
- Use chezmoi's built-in init approach: `sh -c "$(curl ...)" -- init --apply user/repo`
- Script hosted at GitHub raw URL from the repository
- Always bootstrap from main branch
- Single-purpose script — no profiles or modes

### Output & feedback
- Moderate verbosity: show major milestones but hide underlying tool output
- Auto-detect terminal color support — use colors when available
- Show summary with next steps on completion (restart shell, etc.)
- Always log to file (~/.dotfiles-bootstrap.log or similar) for debugging

### Error handling
- Fail fast on any error — don't leave system in partial state
- Error messages include what failed plus suggested resolution
- Skip silently if Homebrew or chezmoi already installed (idempotent)
- Validate network connectivity before attempting downloads

### Environment assumptions
- Support both macOS and Linux from the start
- Prompt for sudo once upfront if needed, cache credentials for session
- No system requirement checks (disk, RAM) — assume capable system

### Claude's Discretion
- Script arguments (e.g., --dry-run, --verbose flags)
- Shell compatibility level (bash vs POSIX sh)
- Exact log file location and format
- Specific network connectivity check implementation

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

*Phase: 01-foundation-bootstrap*
*Context gathered: 2026-02-04*
