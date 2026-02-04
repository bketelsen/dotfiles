---
phase: 05-shell-configuration
plan: 01
subsystem: shell
tags: [zsh, bash, homebrew, fzf, eza, fd, path]

# Dependency graph
requires:
  - phase: 04-tool-installation
    provides: Homebrew package installation script, .homebrew_prefix data
provides:
  - Shell enhancement packages in Brewfile (fzf, eza, fd, zsh plugins)
  - .zshenv with PATH and HOMEBREW_PREFIX
  - .bash_profile that sources .bashrc
affects: [05-02-zsh-configuration, 05-03-bash-configuration]

# Tech tracking
tech-stack:
  added: [fzf, eza, fd, zsh-autosuggestions, zsh-syntax-highlighting]
  patterns: [typeset-U-path-deduplication, cached-homebrew-prefix]

key-files:
  created:
    - dot_zshenv.tmpl
    - dot_bash_profile
  modified:
    - .chezmoiscripts/run_onchange_before_install-packages.sh.tmpl

key-decisions:
  - "eza over exa: exa is unmaintained, eza is active fork"
  - "Cached HOMEBREW_PREFIX: Per-OS hardcoded values for fast startup"
  - "typeset -U path: Zsh-native PATH deduplication"

patterns-established:
  - "Cached environment variables: Compute once at template time, not shell startup"
  - "bash_profile sources bashrc: Standard pattern for consistent bash configuration"

# Metrics
duration: 2min
completed: 2026-02-04
---

# Phase 05 Plan 01: Shell Enhancement Packages Summary

**fzf/eza/fd tools plus zsh plugins in Brewfile, .zshenv with cached HOMEBREW_PREFIX and deduplicated PATH**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-04T00:00:00Z
- **Completed:** 2026-02-04T00:02:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added fzf, eza, fd to CLI tools in Brewfile
- Added zsh-autosuggestions and zsh-syntax-highlighting for macOS
- Created .zshenv with cached HOMEBREW_PREFIX and typeset -U PATH deduplication
- Created .bash_profile that sources .bashrc for consistent bash configuration

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Brewfile with shell enhancement packages** - `f35b5c6` (feat)
2. **Task 2: Create .zshenv for PATH and environment** - `cb66ac2` (feat)
3. **Task 3: Create .bash_profile that sources .bashrc** - `b84750b` (feat)

## Files Created/Modified

- `.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl` - Added fzf, eza, fd, zsh plugins
- `dot_zshenv.tmpl` - HOMEBREW_PREFIX and PATH setup for all zsh shells
- `dot_bash_profile` - Login shell sources .bashrc

## Decisions Made

- **eza over exa:** exa is unmaintained, eza is the active community fork with ongoing development
- **Cached HOMEBREW_PREFIX:** Hardcoded per-OS values (`/opt/homebrew` for Darwin, `/home/linuxbrew/.linuxbrew` for Linux) rather than `$(brew --prefix)` for fast shell startup
- **typeset -U path:** Zsh-native deduplication prevents PATH bloat from nested shells

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all tasks completed successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Shell enhancement packages ready for installation via `chezmoi apply`
- .zshenv provides foundation for .zshrc configuration (next plan)
- .bash_profile provides foundation for .bashrc configuration
- PATH and HOMEBREW_PREFIX available in all shell contexts

---
*Phase: 05-shell-configuration*
*Completed: 2026-02-04*
