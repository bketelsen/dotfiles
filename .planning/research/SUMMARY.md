# Project Research Summary

**Project:** chezmoi dotfiles management
**Domain:** Developer infrastructure - cross-platform dotfiles management
**Researched:** 2026-02-04
**Confidence:** HIGH

## Executive Summary

Dotfiles management with chezmoi represents a mature, well-documented approach to maintaining consistent development environments across macOS and Linux systems. The recommended approach centers on chezmoi as the single statically-linked binary that handles templating, encryption, and cross-platform differences natively. Combined with Homebrew for unified package management, age for modern encryption, and Bitwarden for runtime secrets, this stack provides a robust foundation with minimal dependencies.

The critical success factors are: (1) establishing encryption before adding any sensitive files, (2) implementing idempotent bootstrap scripts with explicit dependency ordering, and (3) keeping template logic simple by using platform-specific files rather than complex conditionals. The architecture follows a layered approach with clear separation between configuration data, templates, scripts, and dotfiles themselves.

Key risks center on security (committing secrets, losing encryption keys) and workflow friction (editing wrong files, bootstrap failures). These are well-documented pitfalls with established prevention patterns. Testing on fresh systems is essential - what works on a configured machine often fails on clean installations due to missing prerequisites or implicit dependencies.

## Key Findings

### Recommended Stack

Modern dotfiles management uses a minimal, battle-tested stack with zero runtime dependencies. Chezmoi provides templating and encryption natively, eliminating the need for additional tools in many cases. The stack prioritizes simplicity, security, and cross-platform consistency.

**Core technologies:**
- **chezmoi 2.69.3**: Dotfiles manager - single binary with native templating, encryption support, zero dependencies, works identically on macOS/Linux
- **age 1.3.1**: File encryption - modern alternative to GPG with post-quantum cryptography support, built into chezmoi
- **Homebrew 5.0.0**: Cross-platform package manager - unified package management across macOS and Linux (officially supports Linux ARM64 as of 2025)
- **Bitwarden CLI**: Password manager integration - official CLI provides template functions for secure secret retrieval
- **Shell tools**: atuin (history sync), bat (cat replacement), direnv (per-directory environments), starship (cross-shell prompt)

**Key insight:** Homebrew on Linux has matured significantly. As of 2025, it's officially supported, works identically to macOS, and enables true "install once, run anywhere" package definitions.

**Stack confidence:** HIGH - all tools verified from official documentation and recent releases.

### Expected Features

Dotfiles repositories have clear expectations. Users expect cross-platform support, secret management, and one-command bootstrap as table stakes. Missing these makes the setup feel incomplete or unprofessional.

**Must have (table stakes):**
- Cross-platform file management - core chezmoi purpose, handle macOS/Linux differences with templates
- Template-based configuration - essential for OS differences without file duplication
- Bootstrap script (one-liner) - new machine setup in single curl command
- Secret management integration - never commit secrets to git (use age encryption and/or Bitwarden)
- Declarative package installation - reproducible environments require automated package setup
- Shell configuration - primary use case (.zshrc, .bashrc) with functions, aliases, environment
- Git configuration - universal need (.gitconfig, .gitignore_global)
- SSH key management - secure authentication setup with encryption

**Should have (competitive differentiators):**
- Modular shell configuration - organize functions vs monolithic configs for maintainability
- Reusable template snippets - DRY principle via .chezmoitemplates/ directory
- Multi-environment detection - smart defaults for work/personal/container environments
- Age encryption for secrets - modern, simple alternative to GPG
- Bitwarden CLI integration - centralized secret management across systems
- Run-once setup scripts - idempotent system configuration
- Work/personal profile separation - single repo, multiple identities
- Modern CLI tool integration - enhanced shell experience with optimal settings

**Defer (v2+):**
- External dependency management - add when needed for vim plugins/themes
- Container/DevPod support - add when using Codespaces regularly
- macOS defaults automation - add when OS-level settings become annoying to configure manually
- Advanced Bitwarden integration - start with age encryption, migrate when managing 10+ secrets

### Architecture Approach

The recommended architecture uses a layered component structure with clear separation of concerns. Configuration data lives in .chezmoidata/, reusable templates in .chezmoitemplates/, lifecycle scripts use run_* prefixes with numeric ordering, and actual dotfiles use chezmoi's special prefixes (dot_, private_, encrypted_). This separation makes the system maintainable and testable.

**Major components:**
1. **Configuration Data Layer** - OS-specific variables and package definitions in .chezmoidata/ files, consumed by templates
2. **Template Library** - Reusable fragments in .chezmoitemplates/ for DRY principle and complex logic extraction
3. **Script Layer** - Bootstrap, installation, and configuration with explicit ordering via numeric prefixes (run_once_before_10-*, run_onchange_20-*)
4. **Dotfile Layer** - Actual configuration files managed via chezmoi prefixes, with encryption for sensitive files
5. **Encryption** - Layered approach: age for files in git (SSH keys), Bitwarden for runtime secrets (API tokens)

**Key patterns:**
- Use .chezmoiroot for clean repository structure
- Conditional OS-specific configuration via templates
- Declarative package management with run_onchange scripts
- Modular shell functions via .chezmoitemplates
- Script execution order with numbered prefixes (00, 01, 02...)

**Build order:** Foundation (bootstrap) → Encryption & Secrets → Template System → Package Management → Shell Configuration → Tool Configurations → SSH & Secure Files → Final Automation

### Critical Pitfalls

1. **Editing files in wrong location** - Users modify ~/.zshrc instead of source file in ~/.local/share/chezmoi, changes get overwritten. Prevention: Use `chezmoi edit` exclusively, add warning comments to managed files, establish workflow in Phase 1.

2. **Committing secrets to repository** - API keys, SSH keys committed in plain text even to private repos. Prevention: Set up age encryption BEFORE adding sensitive files, use pre-commit hooks, template placeholders for secrets.

3. **Age key loss or no backup strategy** - Encryption key lost, all secrets permanently unrecoverable. Prevention: Document backup strategy immediately, store key backup in password manager, test recovery on second machine.

4. **Bootstrap script fails silently** - One-curl bootstrap fails partway through, leaving inconsistent state. Prevention: Make scripts idempotent, use explicit dependency ordering with numeric prefixes, add error handling with `set -e`.

5. **Cross-platform template logic explosion** - Template files become unreadable mess of nested conditionals. Prevention: Use separate platform-specific files with .chezmoiignore, minimize conditionals, extract complex logic to scripts.

6. **Homebrew not installed before packages** - Scripts try `brew install` before Homebrew exists. Prevention: Use numbered prefixes (run_once_before_10-install-homebrew.sh runs first), check for Homebrew existence before use.

7. **Bitwarden CLI not unlocked during bootstrap** - Templates using bitwarden() fail if vault locked. Prevention: Set bitwarden.unlock = "auto" in config, document manual unlock procedure, provide fallback for initial setup.

## Implications for Roadmap

Based on research, suggested 8-phase structure following dependency chain:

### Phase 1: Foundation (Bootstrap & Core Structure)
**Rationale:** Must establish repository structure and basic bootstrap capability before anything else. All other phases depend on this foundation.

**Delivers:** Basic repository structure, chezmoi configuration, Homebrew installation script, working one-command bootstrap.

**Addresses:** Table stakes - bootstrap script (one-liner), cross-platform file management setup.

**Avoids:** Pitfall 4 (bootstrap failures) via idempotent scripts with error handling, Pitfall 8 (script ordering) via numeric prefix convention.

**Complexity:** Low. Well-documented patterns.

### Phase 2: Encryption & Secrets
**Rationale:** MUST happen before adding any sensitive files. Once secrets are in git history, they're there forever. This phase prevents the most critical security pitfall.

**Delivers:** age encryption setup, Bitwarden CLI integration, encryption key generation and backup documentation.

**Addresses:** Table stakes - secret management integration. Prevents public sharing blockers.

**Avoids:** Pitfall 2 (committing secrets), Pitfall 3 (key loss), Pitfall 5 (age config position).

**Complexity:** Medium. Requires understanding of age and key management.

### Phase 3: Template System & OS Detection
**Rationale:** Enables cross-platform support for all subsequent configuration. Establishes DRY patterns via .chezmoitemplates/.

**Delivers:** Reusable template library, OS detection patterns, .chezmoiignore with platform conditionals.

**Addresses:** Table stakes - template-based configuration, cross-platform support. Differentiator - reusable template snippets.

**Avoids:** Pitfall 7 (template logic explosion) by establishing modular patterns early.

**Complexity:** Low. Core chezmoi feature with good documentation.

### Phase 4: Package Management
**Rationale:** Declarative tool installation unlocks ability to configure those tools. Depends on Homebrew (Phase 1) and templates (Phase 3).

**Delivers:** .chezmoidata/packages.yaml, run_onchange package installer, cross-platform package lists.

**Addresses:** Table stakes - declarative package installation. Enables all modern CLI tools.

**Avoids:** Pitfall 9 (Homebrew not installed) via dependency on Phase 1, Pitfall 8 (script ordering) via numeric prefixes.

**Complexity:** Medium. Requires understanding run_onchange behavior.

### Phase 5: Shell Configuration
**Rationale:** Primary dotfiles use case. Depends on tools being installed (Phase 4) and templates (Phase 3).

**Delivers:** .zshrc/.bashrc templates, modular functions.d structure, tool initialization (atuin, direnv, starship).

**Addresses:** Table stakes - shell configuration. Differentiator - modular shell configuration.

**Avoids:** Pitfall 17 (functions.d ordering), Pitfall 18 (tool init order).

**Complexity:** Medium. Requires understanding shell startup sequence and tool interactions.

### Phase 6: Tool Configurations
**Rationale:** Configure the tools installed in Phase 4. Can happen in parallel with Phase 7 since they have different dependencies.

**Delivers:** Configuration files for atuin, starship, direnv, bat, git with Bitwarden integration.

**Addresses:** Table stakes - git configuration. Differentiator - modern CLI tool integration.

**Avoids:** Pitfall 13 (template syntax confusion) via clear examples, Pitfall 14 (missing .tmpl extension).

**Complexity:** Low-Medium. Mostly straightforward config files with some template usage.

### Phase 7: SSH & Secure Files
**Rationale:** Deploy encrypted sensitive files. Depends on encryption setup (Phase 2). Can happen in parallel with Phase 6.

**Delivers:** SSH config template, encrypted SSH keys, proper permissions via private_ prefix.

**Addresses:** Table stakes - SSH key management.

**Avoids:** Pitfall 2 (committing secrets) via encryption from Phase 2.

**Complexity:** Medium. Encryption and permissions must be correct.

### Phase 8: Final Automation & Testing
**Rationale:** Validate end-to-end automation and document the complete system.

**Delivers:** Final configuration scripts, fresh system testing, bootstrap documentation, recovery procedures.

**Addresses:** All features complete and tested.

**Avoids:** Pitfall 16 (no fresh system testing), Pitfall 1 (wrong location edits) via clear documentation.

**Complexity:** Low (mostly validation). Critical for reliability.

### Phase Ordering Rationale

- **Foundation first (Phase 1):** Everything depends on basic structure and Homebrew.
- **Encryption before files (Phase 2):** Security is not retroactive - secrets in git history stay there forever.
- **Templates before content (Phase 3):** Cross-platform patterns enable all subsequent configuration.
- **Packages before configs (Phase 4):** Cannot configure tools that aren't installed.
- **Shells depend on tools (Phase 5):** Shell init needs tools from Phase 4.
- **Parallel opportunity (Phases 6 & 7):** Tool configs and SSH have different dependency chains, can be built simultaneously.
- **Validation last (Phase 8):** Test complete system on fresh machine to catch integration issues.

**Critical path:** 1 → 2 → 3 → 4 → 5 → 6 → 8 (7 can happen in parallel with 6)

**Parallelization opportunities:**
- Phase 2 and Phase 3 can start together (both only depend on Phase 1)
- Phase 6 and Phase 7 can build in parallel (different dependency chains)

### Research Flags

**Phases with standard patterns (low research need):**
- **Phase 1:** Bootstrap patterns are well-documented, established conventions
- **Phase 3:** Template system is core chezmoi feature with excellent docs
- **Phase 6:** Tool configurations are mostly straightforward with official examples

**Phases needing validation during implementation:**
- **Phase 2:** Key management and backup procedures should be tested immediately
- **Phase 5:** Shell tool initialization order needs empirical testing to avoid conflicts
- **Phase 8:** Fresh system testing will reveal gaps not visible on configured machine

**No phases require additional research** - all patterns are well-documented in official sources and community examples. Implementation can proceed directly.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified from official releases, mature tools with active development |
| Features | HIGH | Clear community consensus on table stakes vs differentiators, validated against multiple real-world examples |
| Architecture | HIGH | Official documentation provides detailed patterns, multiple community repositories confirm approaches |
| Pitfalls | HIGH | Verified from official troubleshooting docs, GitHub issues, and community post-mortems |

**Overall confidence:** HIGH

The dotfiles domain is mature and well-documented. Chezmoi has comprehensive official documentation, active community, and established best practices. All recommendations are based on official sources or verified community consensus.

### Gaps to Address

**No significant gaps identified.** All critical areas have high-quality documentation and established patterns.

**Minor areas for validation during implementation:**
- Tool initialization order (Phase 5) - documentation exists but empirical testing on both macOS and Linux will confirm no conflicts
- Fresh system testing (Phase 8) - implicit dependencies often only surface when testing on truly clean machines
- Bitwarden unlock automation - official docs cover this but specific workflow may need adjustment based on authentication method

**Mitigation strategy:** Test each phase on fresh VM/container immediately after implementation. What works on a configured development machine may fail on clean systems.

## Sources

### Primary (HIGH confidence)
- [chezmoi.io](https://www.chezmoi.io/) - Official documentation (templating, scripts, encryption, cross-platform)
- [chezmoi GitHub releases](https://github.com/twpayne/chezmoi/releases) - Version 2.69.3
- [age GitHub releases](https://github.com/FiloSottile/age/releases) - Version 1.3.1 with post-quantum crypto
- [Homebrew 5.0.0 announcement](https://brew.sh/2025/11/12/homebrew-5.0.0/) - Linux ARM64 support
- Official tool releases (atuin, bat, direnv, starship, Bitwarden CLI) - All current versions verified

### Secondary (MEDIUM confidence)
- [Managing dotfiles with Chezmoi - Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Community best practices
- [How To Manage Dotfiles With Chezmoi - Jerry Ng](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/) - Workflow patterns
- [Cross-Platform Dotfiles with Chezmoi - Alfonso Fortunato](https://alfonsofortunato.com/posts/dotfile/) - Multi-platform approach
- Real-world examples: abrauner/dotfiles, HotThoughts/dotfiles, gazorby/dotfiles - Pattern validation

### Tertiary (verification only)
- GitHub Issues and Discussions - Confirmed pitfalls and edge cases
- Community blog posts (2025-2026) - Recent experiences validate approaches

---
*Research completed: 2026-02-04*
*Ready for roadmap: yes*
