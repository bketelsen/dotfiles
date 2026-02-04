---
phase: 04-tool-installation
plan: 01
subsystem: infra
tags: [homebrew, starship, atuin, bat, direnv, git, chezmoi]

# Dependency graph
requires:
  - phase: 03-cross-platform-support
    provides: homebrew_prefix template variable for platform-aware paths
provides:
  - Declarative Brewfile with run_onchange trigger for CLI tool installation
  - starship prompt configuration with git status and minimal style
  - atuin shell history with local-only mode and fuzzy search
  - bat syntax highlighting with Nord theme
  - git configuration with sensible defaults and aliases
affects: [05-shell-configuration]

# Tech tracking
tech-stack:
  added: [starship, atuin, bat, direnv]
  patterns: [run_onchange_before for declarative package management, embedded heredoc Brewfile]

key-files:
  created:
    - .chezmoiscripts/run_onchange_before_install-packages.sh.tmpl
    - dot_config/starship.toml
    - dot_config/atuin/config.toml
    - dot_config/bat/config
    - dot_gitconfig.tmpl
    - dot_gitignore_global

key-decisions:
  - "Embedded Brewfile as heredoc, not separate file"
  - "starship: symbol-only language modules (no versions)"
  - "atuin: local-only mode with sensitive command filtering"
  - "git: push.default=current, pull.rebase=true, common aliases"

patterns-established:
  - "run_onchange_before_: re-runs when content hash changes"
  - "dot_config/ prefix: maps to ~/.config/ via chezmoi"
  - ".tmpl suffix: enables future platform conditionals"

# Metrics
duration: 1min
completed: 2026-02-04
---

# Phase 4 Plan 1: CLI Tools and Configuration Summary

**Declarative Brewfile installs starship, atuin, bat, direnv via Homebrew; configs set minimal prompt, local-only history, Nord theme, and git aliases**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-04T18:30:00Z
- **Completed:** 2026-02-04T18:31:24Z
- **Tasks:** 3
- **Files created:** 6

## Accomplishments

- run_onchange script with embedded Brewfile installs 4 CLI tools declaratively
- starship.toml with minimal prompt: directory + git branch/status + cmd duration
- atuin config with local-only sync, fuzzy search, and sensitive command filtering
- bat config with Nord theme and line numbers
- gitconfig with rebase workflow, auto-setup remote, and common aliases
- Global gitignore for macOS, Linux, and editor patterns

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Brewfile with run_onchange script** - `4242072` (feat)
2. **Task 2: Create CLI tool configurations** - `e848374` (feat)
3. **Task 3: Create Git configuration** - `4359fc3` (feat)

## Files Created

- `.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl` - Declarative package installation via Homebrew
- `dot_config/starship.toml` - Minimal prompt with git status, purple branch, 2s cmd duration
- `dot_config/atuin/config.toml` - Local-only history with fuzzy search, sensitive filtering
- `dot_config/bat/config` - Nord theme, line numbers, auto paging
- `dot_gitconfig.tmpl` - Git configuration with aliases and sensible defaults
- `dot_gitignore_global` - Global gitignore for OS and editor patterns

## Decisions Made

- **Embedded Brewfile heredoc:** Keeps Brewfile content inline with script for atomic updates
- **starship symbol-only modules:** Language modules show symbol without version for cleaner prompt
- **atuin sensitive filtering:** Regex patterns filter export, secret, password, token from history
- **git aliases:** Common shortcuts (s, st, d, dc, br, co, cob, ci, ca, l, lg, undo, unstage)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All CLI tool configs ready for Phase 5 shell integration
- Phase 5 needs to add shell hooks: `eval "$(starship init zsh)"`, `eval "$(atuin init zsh)"`, `eval "$(direnv hook zsh)"`
- Tools will be installed on next `chezmoi apply` via run_onchange script

---
*Phase: 04-tool-installation*
*Completed: 2026-02-04*
