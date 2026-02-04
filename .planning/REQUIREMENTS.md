# Requirements: Dotfiles

**Defined:** 2026-02-04
**Core Value:** One command takes a fresh machine to a fully working environment

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Bootstrap

- [ ] **BOOT-01**: User can bootstrap a fresh machine with a single curl command from the README
- [ ] **BOOT-02**: Bootstrap installs Homebrew if not already present (macOS and Linux)
- [ ] **BOOT-03**: Bootstrap installs chezmoi and runs init/apply automatically
- [ ] **BOOT-04**: All bootstrap scripts are idempotent (safe to re-run without side effects)
- [ ] **BOOT-05**: Bootstrap scripts have error handling with clear failure messages

### Encryption

- [x] **ENCR-01**: Sensitive files are encrypted with age before committing to repository
- [x] **ENCR-02**: age encryption is configured and keys are generated during initial setup
- [x] **ENCR-03**: Bitwarden CLI is integrated for runtime secret retrieval
- [x] **ENCR-04**: Key backup procedure is documented (how to backup and restore age keys)

### Shell

- [ ] **SHEL-01**: zsh is fully configured for macOS with prompt, aliases, and environment
- [ ] **SHEL-02**: bash is fully configured for Linux with prompt, aliases, and environment
- [ ] **SHEL-03**: Shell functions are organized in modular functions.d directories
- [ ] **SHEL-04**: functions.d files are automatically sourced on shell startup
- [ ] **SHEL-05**: Shared shell logic works across both zsh and bash where possible

### Tools

- [x] **TOOL-01**: starship prompt is configured with sensible cross-shell defaults
- [x] **TOOL-02**: atuin is configured for shell history sync and search
- [x] **TOOL-03**: bat is configured as cat replacement with syntax highlighting
- [x] **TOOL-04**: direnv is configured for per-directory environment variables
- [x] **TOOL-05**: Git is configured with sensible defaults (.gitconfig)

### Cross-Platform

- [x] **PLAT-01**: Templates detect OS (macOS vs Linux) and adjust configuration accordingly
- [x] **PLAT-02**: Platform-specific files are handled via .chezmoiignore or separate templates
- [x] **PLAT-03**: Homebrew paths are correctly set for both platforms (Apple Silicon, Intel, Linux)
- [x] **PLAT-04**: Configuration works identically on Mac laptop, Linux desktop, and Linux servers

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced Features

- **ADV-01**: Work/personal profile separation (single repo, multiple identities)
- **ADV-02**: Container/DevPod environment detection
- **ADV-03**: macOS defaults automation (system preferences)
- **ADV-04**: External dependency management (vim plugins, themes)
- **ADV-05**: SSH agent integration with 1Password or other providers

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| GUI application configs | CLI-focused dotfiles, GUI apps have their own sync mechanisms |
| Non-Homebrew package managers | Consistency over platform-native package managers |
| Multiple setup profiles (minimal/full) | Simplicity for v1, single setup for all machines |
| GPG encryption | age is simpler and has better chezmoi integration |
| Fish shell | Not used on target machines (zsh on Mac, bash on Linux) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BOOT-01 | Phase 1 | Complete |
| BOOT-02 | Phase 1 | Complete |
| BOOT-03 | Phase 1 | Complete |
| BOOT-04 | Phase 1 | Complete |
| BOOT-05 | Phase 1 | Complete |
| ENCR-01 | Phase 2 | Complete |
| ENCR-02 | Phase 2 | Complete |
| ENCR-03 | Phase 2 | Complete |
| ENCR-04 | Phase 2 | Complete |
| PLAT-01 | Phase 3 | Complete |
| PLAT-02 | Phase 3 | Complete |
| PLAT-03 | Phase 3 | Complete |
| PLAT-04 | Phase 3 | Complete |
| TOOL-01 | Phase 4 | Complete |
| TOOL-02 | Phase 4 | Complete |
| TOOL-03 | Phase 4 | Complete |
| TOOL-04 | Phase 4 | Complete |
| TOOL-05 | Phase 4 | Complete |
| SHEL-01 | Phase 5 | Pending |
| SHEL-02 | Phase 5 | Pending |
| SHEL-03 | Phase 5 | Pending |
| SHEL-04 | Phase 5 | Pending |
| SHEL-05 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-04*
*Last updated: 2026-02-04 after roadmap creation*
