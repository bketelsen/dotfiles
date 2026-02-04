# Roadmap: Dotfiles

## Overview

Transform a fresh machine into a fully configured development environment with a single curl command. Starting with foundational bootstrap infrastructure, we layer on encryption for secrets, cross-platform templating for macOS and Linux, declarative tool installation via Homebrew, and finally shell configuration with modular functions. Each phase delivers a complete, verifiable capability that enables the next.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation & Bootstrap** - One-command setup with Homebrew installation
- [ ] **Phase 2: Encryption & Secrets** - age encryption and Bitwarden integration
- [ ] **Phase 3: Cross-Platform Support** - OS detection and platform-specific handling
- [ ] **Phase 4: Tool Installation** - Declarative package management for CLI tools
- [ ] **Phase 5: Shell Configuration** - zsh/bash configs with modular functions

## Phase Details

### Phase 1: Foundation & Bootstrap
**Goal**: User can bootstrap a fresh machine with a single curl command that installs Homebrew and chezmoi
**Depends on**: Nothing (first phase)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05
**Success Criteria** (what must be TRUE):
  1. User can execute a single curl command from README to bootstrap any fresh machine
  2. Bootstrap script installs Homebrew automatically if not present on macOS or Linux
  3. Bootstrap script installs chezmoi and runs init/apply without manual intervention
  4. Bootstrap scripts can be safely re-run multiple times without side effects
  5. Bootstrap failures display clear error messages indicating what went wrong
**Plans**: TBD

Plans:
- [ ] TBD after planning

### Phase 2: Encryption & Secrets
**Goal**: Sensitive files are encrypted with age and secrets can be retrieved from Bitwarden at runtime
**Depends on**: Phase 1
**Requirements**: ENCR-01, ENCR-02, ENCR-03, ENCR-04
**Success Criteria** (what must be TRUE):
  1. Sensitive files are automatically encrypted with age before being committed to repository
  2. age encryption keys are generated during initial setup and stored securely
  3. Bitwarden CLI can retrieve secrets at runtime for template expansion
  4. Key backup and recovery procedures are documented and testable
**Plans**: TBD

Plans:
- [ ] TBD after planning

### Phase 3: Cross-Platform Support
**Goal**: Configuration templates detect OS and adapt automatically for macOS and Linux
**Depends on**: Phase 2
**Requirements**: PLAT-01, PLAT-02, PLAT-03, PLAT-04
**Success Criteria** (what must be TRUE):
  1. Templates automatically detect whether running on macOS or Linux
  2. Platform-specific files are included or ignored based on OS detection
  3. Homebrew paths are correctly configured for Apple Silicon, Intel Mac, and Linux
  4. Same dotfiles repository produces working configuration on Mac laptop, Linux desktop, and Linux servers
**Plans**: TBD

Plans:
- [ ] TBD after planning

### Phase 4: Tool Installation
**Goal**: CLI tools are installed declaratively via Homebrew with cross-platform package lists
**Depends on**: Phase 3
**Requirements**: TOOL-01, TOOL-02, TOOL-03, TOOL-04, TOOL-05
**Success Criteria** (what must be TRUE):
  1. starship prompt works identically in both zsh and bash with custom configuration
  2. atuin provides shell history sync and search functionality with optimal defaults
  3. bat replaces cat with syntax highlighting and configured theme
  4. direnv automatically loads per-directory environment variables
  5. Git uses custom configuration from dotfiles (.gitconfig, .gitignore_global)
**Plans**: TBD

Plans:
- [ ] TBD after planning

### Phase 5: Shell Configuration
**Goal**: Both zsh (macOS) and bash (Linux) are fully configured with modular function directories
**Depends on**: Phase 4
**Requirements**: SHEL-01, SHEL-02, SHEL-03, SHEL-04, SHEL-05
**Success Criteria** (what must be TRUE):
  1. zsh on macOS has working prompt, aliases, environment variables, and tool integrations
  2. bash on Linux has working prompt, aliases, environment variables, and tool integrations
  3. Shell functions are organized in functions.d directories for easy maintenance
  4. Functions from functions.d are automatically sourced during shell startup
  5. Shared shell logic works on both zsh and bash without duplication
**Plans**: TBD

Plans:
- [ ] TBD after planning

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Bootstrap | 0/TBD | Not started | - |
| 2. Encryption & Secrets | 0/TBD | Not started | - |
| 3. Cross-Platform Support | 0/TBD | Not started | - |
| 4. Tool Installation | 0/TBD | Not started | - |
| 5. Shell Configuration | 0/TBD | Not started | - |
