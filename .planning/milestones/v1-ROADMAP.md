# Milestone v1: MVP

**Status:** ✅ SHIPPED 2026-02-04
**Phases:** 1-5
**Total Plans:** 10

## Overview

Transform a fresh machine into a fully configured development environment with a single curl command. Starting with foundational bootstrap infrastructure, we layer on encryption for secrets, cross-platform templating for macOS and Linux, declarative tool installation via Homebrew, and finally shell configuration with modular functions. Each phase delivers a complete, verifiable capability that enables the next.

## Phases

### Phase 1: Foundation & Bootstrap

**Goal**: User can bootstrap a fresh machine with a single curl command that installs Homebrew and chezmoi
**Depends on**: Nothing (first phase)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05
**Success Criteria**:
  1. User can execute a single curl command from README to bootstrap any fresh machine
  2. Bootstrap script installs Homebrew automatically if not present on macOS or Linux
  3. Bootstrap script installs chezmoi and runs init/apply without manual intervention
  4. Bootstrap scripts can be safely re-run multiple times without side effects
  5. Bootstrap failures display clear error messages indicating what went wrong

Plans:
- [x] 01-01-PLAN.md - Bootstrap infrastructure (bootstrap.sh, README, chezmoi config)

**Details:**
- POSIX shell script for maximum compatibility
- Idempotent operations (safe to re-run)
- Color-aware output with graceful degradation
- File logging to ~/.dotfiles-bootstrap.log

### Phase 2: Encryption & Secrets

**Goal**: Sensitive files are encrypted with age and secrets can be retrieved from Bitwarden at runtime
**Depends on**: Phase 1
**Requirements**: ENCR-01, ENCR-02, ENCR-03, ENCR-04
**Success Criteria**:
  1. Sensitive files are automatically encrypted with age before being committed to repository
  2. age encryption keys are generated during initial setup and stored securely
  3. Bitwarden CLI can retrieve secrets at runtime for template expansion
  4. Key backup and recovery procedures are documented and testable

Plans:
- [x] 02-01-PLAN.md - Age encryption and Bitwarden integration configuration
- [x] 02-02-PLAN.md - Pre-commit secret detection hooks
- [x] 02-03-PLAN.md - Encryption and recovery documentation

**Details:**
- chezmoi builtin age (not standalone binary)
- Bitwarden unlock = auto for session-aware auth
- run_once_before_00 pattern for first-time setup
- detect-secrets pre-commit hook

### Phase 3: Cross-Platform Support

**Goal**: Configuration templates detect OS and adapt automatically for macOS and Linux
**Depends on**: Phase 2
**Requirements**: PLAT-01, PLAT-02, PLAT-03, PLAT-04
**Success Criteria**:
  1. Templates automatically detect whether running on macOS or Linux
  2. Platform-specific files are included or ignored based on OS detection
  3. Homebrew paths are correctly configured for Apple Silicon, Intel Mac, and Linux
  4. Same dotfiles repository produces working configuration on Mac laptop, Linux desktop, and Linux servers

Plans:
- [x] 03-01-PLAN.md - Platform detection infrastructure (config templates, .chezmoiignore)

**Details:**
- Apple Silicon only (Intel Mac blocked by design)
- {{ .homebrew_prefix }} template variable
- Inverted .chezmoiignore logic for platform conditionals

### Phase 4: Tool Installation

**Goal**: CLI tools are installed declaratively via Homebrew with cross-platform package lists
**Depends on**: Phase 3
**Requirements**: TOOL-01, TOOL-02, TOOL-03, TOOL-04, TOOL-05
**Success Criteria**:
  1. starship prompt works identically in both zsh and bash with custom configuration
  2. atuin provides shell history sync and search functionality with optimal defaults
  3. bat replaces cat with syntax highlighting and configured theme
  4. direnv automatically loads per-directory environment variables
  5. Git uses custom configuration from dotfiles (.gitconfig, .gitignore_global)

Plans:
- [x] 04-01-PLAN.md - Declarative package installation and tool configuration

**Details:**
- Embedded Brewfile as heredoc in run_onchange script
- starship: symbol-only language modules
- atuin: local-only mode with fuzzy search
- bat: Nord theme
- git: rebase workflow, common aliases

### Phase 5: Shell Configuration

**Goal**: Both zsh (macOS) and bash (Linux) are fully configured with modular function directories
**Depends on**: Phase 4
**Requirements**: SHEL-01, SHEL-02, SHEL-03, SHEL-04, SHEL-05
**Success Criteria**:
  1. zsh on macOS has working prompt, aliases, environment variables, and tool integrations
  2. bash on Linux has working prompt, aliases, environment variables, and tool integrations
  3. Shell functions are organized in functions.d directories for easy maintenance
  4. Functions from functions.d are automatically sourced during shell startup
  5. Shared shell logic works on both zsh and bash without duplication

Plans:
- [x] 05-01-PLAN.md - Shell package installation and environment foundation
- [x] 05-02-PLAN.md - zsh configuration with tool integrations
- [x] 05-03-PLAN.md - bash configuration with tool integrations
- [x] 05-04-PLAN.md - functions.d modules (git, nav, utils)

**Details:**
- Cached HOMEBREW_PREFIX for fast startup
- fzf Ctrl-R disabled when atuin present
- zsh-syntax-highlighting loaded last
- POSIX-compatible function files shared between shells

---

## Milestone Summary

**Key Decisions:**

- POSIX sh for maximum compatibility (not bash)
- Homebrew on Linux for consistency with macOS
- age over GPG for simpler encryption
- Apple Silicon only (Intel Mac blocked)
- Embedded Brewfile heredoc pattern
- Identical zsh/bash function files for maintainability

**Issues Resolved:**

- Pre-commit hook detecting age public key as secret (added allowlist pragma)

**Issues Deferred:**

- None

**Technical Debt Incurred:**

- None

---

*Archived: 2026-02-04 as part of v1 milestone completion*
*For current project status, see .planning/ROADMAP.md*
