# Technology Stack

**Project:** chezmoi dotfiles management
**Researched:** 2026-02-04
**Overall Confidence:** HIGH

## Recommended Stack

### Core Dotfiles Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| chezmoi | 2.69.3 (2026-01) | Dotfiles manager | Industry standard with native templating, encryption support, cross-platform compatibility, and zero dependencies. Single statically-linked binary works on macOS/Linux without runtime requirements. |
| age | 1.3.1 (2025-12) | File encryption | Modern, simple encryption with post-quantum cryptography support (ML-KEM-768). Built into chezmoi since recent versions, eliminating external dependency. Recommended over GPG for simplicity. |
| Bitwarden CLI (bw) | 2025.12.1 | Password manager integration | Official Bitwarden CLI provides `bitwarden()` template functions in chezmoi for secure secret retrieval. Widely adopted, actively maintained, supports both cloud and self-hosted vaults. |

**Confidence:** HIGH - All tools verified from official documentation and release pages.

### Package Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Homebrew | 5.0.0 (2025-11) | Cross-platform package manager | Unified package management across macOS and Linux. As of 2025, officially supports Linux ARM64/AArch64 (Tier 1), has 9% Linux user base, works identically on both platforms. Eliminates need for platform-specific package managers. |

**Confidence:** HIGH - Verified from official Homebrew 5.0.0 release notes.

**Why Homebrew on Linux:** Linuxbrew was merged into Homebrew in 2019. In 2025, Homebrew on Linux is mature, officially supported, and provides identical experience to macOS. This enables true "install once, run anywhere" package definitions in dotfiles.

### Shell Environment Tools

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| atuin | Latest (2025-12) | Shell history sync | SQLite-based history with encrypted cloud sync, cross-shell support (bash/zsh/fish), context-aware search. Replaces traditional shell history with superior search and sync capabilities. |
| bat | 0.26.1 (2025-12) | cat replacement | Syntax highlighting, git integration, automatic paging. Written in Rust for performance. Drop-in `cat` replacement that enhances CLI experience. |
| direnv | 2.37.0 (2025-07) | Per-directory environments | Automatic environment variable management based on directory. Essential for project-specific configurations. 2025 version adds ARM64 Windows support. |
| starship | 1.24.2 (2025-12) | Cross-shell prompt | Fast, customizable prompt that works on any shell/OS. Single TOML config. Built in Rust for performance. Shows git status, tool versions, job status at a glance. |

**Confidence:** HIGH - All versions verified from official releases or documentation.

### Shell Configuration

| Component | Purpose | Why |
|-----------|---------|-----|
| Bash | Linux default shell | Pre-installed on all Linux distributions. Conservative choice for maximum compatibility. |
| Zsh | macOS default shell | Default since macOS Catalina. Superior interactive features, compatibility with bash scripts. |
| functions.d pattern | Modular function organization | Split shell functions into individual files sourced at startup. Enables clean organization, easy testing, conditional loading per platform. |

**Confidence:** HIGH - Standard practice verified across multiple dotfiles repositories.

## Architecture: chezmoi-Specific Features to Leverage

### 1. Templates (Primary Integration Method)

**Use for:** Platform-specific configuration, secret injection, dynamic content generation.

**Built-in variables:**
- `{{ .chezmoi.os }}` - Detects darwin, linux, windows
- `{{ .chezmoi.arch }}` - Processor architecture
- `{{ .chezmoi.hostname }}` - Machine hostname
- `{{ .chezmoi.osRelease }}` - Linux distribution info

**Example:**
```go
{{- if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX="/opt/homebrew"
{{- else if eq .chezmoi.os "linux" }}
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{- end }}
```

**Confidence:** HIGH - Official documentation, core chezmoi feature.

### 2. Scripts (Package Installation & Setup)

**Script naming conventions:**

| Prefix | Behavior | Use Case |
|--------|----------|----------|
| `run_once_` | Runs once, tracked in state | Initial package installation |
| `run_onchange_` | Runs when script content changes | Package list updates |
| `run_before_` | Runs before applying files | Pre-requisite setup |
| `run_after_` | Runs after applying files | Post-configuration tasks |

**Recommended structure:**
```
.chezmoiscripts/
├── run_once_before_install-homebrew.sh.tmpl
├── run_onchange_install-packages.sh.tmpl
└── run_after_configure-shell.sh.tmpl
```

**Confidence:** HIGH - Official documentation, widely used pattern.

### 3. External Files (.chezmoiexternal.yaml)

**Use for:** Downloading external tools, fetching remote configurations, including third-party files.

**Features:**
- Template support (even without .tmpl extension)
- `refreshPeriod` for periodic updates
- Conditional inclusion based on platform
- Checksum verification

**Example:**
```yaml
".local/bin/some-tool":
  type: file
  url: "https://github.com/org/repo/releases/download/v1.0.0/tool-{{ .chezmoi.os }}-{{ .chezmoi.arch }}"
  refreshPeriod: "168h"
```

**Confidence:** HIGH - Official documentation.

### 4. Encryption Integration

**age + chezmoi integration:**

1. Generate age key: `chezmoi age-keygen --output=$HOME/key.txt`
2. Configure in `~/.config/chezmoi/chezmoi.toml`:
```toml
encryption = "age"
[age]
identity = "/home/user/key.txt"
recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```
3. Add encrypted files: `chezmoi add --encrypt ~/.ssh/id_rsa`

**Built-in age support:** chezmoi has built-in age encryption if the `age` command is not installed, though it lacks passphrase support.

**Confidence:** HIGH - Official documentation.

### 5. Bitwarden Integration

**Template functions available:**

- `{{ bitwarden "item-id" }}` - Retrieve entire item
- `{{ bitwardenFields "item-id" }}` - Retrieve custom fields
- `{{ bitwardenAttachment "filename" "item-id" }}` - Retrieve attachments

**Authentication:** Supports email, API key, SSO. Use `BW_SESSION` environment variable for session management.

**Workflow:**
1. Login: `bw login`
2. Unlock: `bw unlock` (sets BW_SESSION)
3. Reference in templates: `{{ (bitwarden "item-id").login.password }}`

**Confidence:** HIGH - Official chezmoi documentation.

## Bootstrap Strategy

### One-Command Setup

**Standard bootstrap (public repo):**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

**Private repository:**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:$GITHUB_USERNAME/dotfiles.git
```

**How it works:**
1. Downloads and installs chezmoi binary
2. Clones dotfiles repository to `~/.local/share/chezmoi`
3. Runs `chezmoi apply` (executes scripts, generates files)
4. Results in fully configured environment from single command

**Alternative install location (.local/bin):**
```bash
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply $GITHUB_USERNAME
```

**Confidence:** HIGH - Official installation method.

### Recommended Bootstrap Order

Based on dependency analysis:

1. **Install Homebrew** - `run_once_before_install-homebrew.sh.tmpl`
   - Detects OS, installs appropriate Homebrew
   - Required before any brew package installation

2. **Install packages** - `run_onchange_install-packages.sh.tmpl`
   - Uses Homebrew to install atuin, bat, direnv, starship
   - Re-runs when package list changes

3. **Configure Bitwarden** - `run_once_before_configure-bitwarden.sh.tmpl`
   - Installs Bitwarden CLI via Homebrew
   - Prompts for login/unlock if needed
   - Required before templates using bitwarden() functions

4. **Apply dotfiles** - (automatic via chezmoi apply)
   - Templates rendered with secrets from Bitwarden
   - age-encrypted files decrypted
   - Shell configs generated per-platform

5. **Post-configuration** - `run_after_configure-shell.sh.tmpl`
   - Set shell to zsh on macOS (if needed)
   - Initialize atuin sync
   - Any final setup steps

**Confidence:** MEDIUM - Synthesized from best practices, not single authoritative source.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Dotfiles Manager | chezmoi | GNU Stow | No native templating, encryption, or cross-platform support. Requires manual scripting for everything chezmoi handles natively. |
| Dotfiles Manager | chezmoi | yadm | Less active development, weaker cross-platform story. chezmoi has better templating and encryption integration. |
| Dotfiles Manager | chezmoi | Home Manager (Nix) | Requires learning Nix language, heavy dependency chain. Overkill for dotfiles-only use case. chezmoi is single binary with zero dependencies. |
| Encryption | age | GPG | age is simpler (no key servers, no web of trust complexity), modern crypto (Curve25519), and has post-quantum support in 1.3+. GPG is over-engineered for this use case. |
| Encryption | age | git-crypt | git-crypt encrypts in-repo (visible to git history), age encrypts before git sees content. age provides better secret rotation story. |
| Package Manager (Linux) | Homebrew | Nix | Nix requires learning functional language, managing generations, dealing with non-standard paths. Homebrew "just works" like on macOS. |
| Package Manager (cross-platform) | Homebrew | mise/asdf | Tool version managers, not package managers. Different use case (runtime versions vs system tools). Could complement Homebrew but not replace it. |
| Shell History | atuin | mcfly | atuin has better sync story, more active development, supports more shells. mcfly is single-machine only. |
| Shell History | atuin | fzf history search | fzf is file finder first, history second. atuin is purpose-built for history with superior filtering, sync, and context awareness. |
| Password Manager | Bitwarden | 1Password | 1Password CLI requires paid subscription, Bitwarden has free tier and self-host option. Both integrate well with chezmoi. |
| Password Manager | Bitwarden | pass (Unix password manager) | pass requires GPG (complexity), git (manual sync), less cross-platform support. Bitwarden has better UX and official apps. |
| Prompt | starship | oh-my-zsh/powerlevel10k | starship is shell-agnostic (works with bash/zsh/fish), single binary, no plugin system to manage. p10k is zsh-only. |

**Confidence:** MEDIUM - Comparison based on ecosystem knowledge, some alternatives not deeply investigated.

## Installation Commands

### Initial Bootstrap
```bash
# From scratch (public repo)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME

# From scratch (private repo)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:YOUR_GITHUB_USERNAME/dotfiles.git
```

### Manual Setup (if needed)
```bash
# Install chezmoi
brew install chezmoi

# Initialize from GitHub
chezmoi init YOUR_GITHUB_USERNAME

# Preview changes
chezmoi diff

# Apply dotfiles
chezmoi apply
```

### Package Installation (via scripts)
```bash
# In .chezmoiscripts/run_onchange_install-packages.sh.tmpl
brew install \
  age \
  atuin \
  bat \
  bitwarden-cli \
  direnv \
  starship
```

**Note:** Homebrew will be auto-installed by `run_once_before_install-homebrew.sh.tmpl` if not present.

## Version Verification

All versions current as of 2026-02-04:

| Tool | Current Version | Release Date | Source |
|------|----------------|--------------|--------|
| chezmoi | 2.69.3 | 2026-01-16 | [GitHub Releases](https://github.com/twpayne/chezmoi/releases) |
| age | 1.3.1 | 2025-12-29 | [GitHub Releases](https://github.com/FiloSottile/age/releases) |
| Bitwarden CLI | 2025.12.1 | 2025-12 | [npm](https://www.npmjs.com/package/@bitwarden/cli) |
| Homebrew | 5.0.0 | 2025-11-12 | [Homebrew Blog](https://brew.sh/2025/11/12/homebrew-5.0.0/) |
| atuin | Latest | 2025-12-13 | [Documentation](https://docs.atuin.sh/) |
| bat | 0.26.1 | 2025-12-02 | [GitHub Releases](https://github.com/sharkdp/bat/releases) |
| direnv | 2.37.0 | 2025-07-02 | [GitHub Releases](https://github.com/direnv/direnv/releases) |
| starship | 1.24.2 | 2025-12-30 | [GitHub Releases](https://github.com/starship/starship/releases) |

## What NOT to Use

### Anti-Patterns

1. **Don't use multiple dotfiles managers**
   - Mixing chezmoi with Stow, yadm, etc. creates confusion about source of truth
   - Pick one and commit to it

2. **Don't encrypt age keys with passphrases**
   - chezmoi needs frequent decryption (every `chezmoi diff`/`status`)
   - Passphrase prompts break automation
   - Instead: Store age key outside repo, encrypted at rest by OS

3. **Don't commit secrets in plain text**
   - Use age encryption for static secrets (SSH keys, certs)
   - Use Bitwarden integration for dynamic secrets (API keys)
   - Never rely on private repo for secret security

4. **Don't use run_ scripts without prefixes**
   - Plain `run_` executes every `chezmoi apply` (dangerous for installs)
   - Always use `run_once_`, `run_onchange_`, or `run_after_`/`run_before_`

5. **Don't hard-code absolute paths**
   - Use `{{ .chezmoi.homeDir }}` instead of `/home/username`
   - Enables portability across machines with different usernames

6. **Don't install platform-specific package managers**
   - Don't use apt/yum/pacman in scripts
   - Use Homebrew on both macOS and Linux for consistency
   - Exception: Homebrew itself needs platform-specific install

7. **Don't put everything in one giant .zshrc/.bashrc**
   - Use functions.d pattern with auto-sourcing
   - Enables conditional loading per platform
   - Easier to test individual components

### Deprecated Approaches

1. **Linuxbrew as separate project** - Merged into Homebrew in 2019, use `brew` everywhere
2. **GPG encryption in chezmoi** - age is simpler and now has post-quantum support
3. **SSH keys as age identities** - Not officially supported by age project, use X25519 keys
4. **git-crypt for dotfiles** - Visible in git history, rotation is painful, use age instead

## Sources

### Official Documentation
- [chezmoi.io](https://www.chezmoi.io/) - Official chezmoi documentation
- [chezmoi Templates Reference](https://www.chezmoi.io/reference/templates/) - Template functions
- [chezmoi age Encryption](https://www.chezmoi.io/user-guide/encryption/age/) - age integration
- [chezmoi Bitwarden Integration](https://www.chezmoi.io/user-guide/password-managers/bitwarden/) - Bitwarden functions
- [chezmoi Machine Differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) - Cross-platform handling
- [chezmoi Scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) - Script execution
- [chezmoi External Files](https://www.chezmoi.io/reference/special-files/chezmoiexternal-format/) - External file management

### Release Information
- [chezmoi Releases](https://github.com/twpayne/chezmoi/releases) - Version 2.69.3
- [age Releases](https://github.com/FiloSottile/age/releases) - Version 1.3.1 with post-quantum crypto
- [Homebrew 5.0.0](https://brew.sh/2025/11/12/homebrew-5.0.0/) - ARM64 Linux support
- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) - Linux-specific documentation
- [bat Releases](https://github.com/sharkdp/bat/releases) - Version 0.26.1
- [direnv Releases](https://github.com/direnv/direnv/releases) - Version 2.37.0
- [starship Releases](https://github.com/starship/starship/releases) - Version 1.24.2
- [Bitwarden CLI npm](https://www.npmjs.com/package/@bitwarden/cli) - Version 2025.12.1

### Best Practices & Community
- [Managing dotfiles with Chezmoi](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Community best practices
- [Frictionless Dotfile Management With Chezmoi](https://marcusb.org/posts/2025/01/frictionless-dotfile-management-with-chezmoi/) - Low-friction workflow
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew, and Devpod](https://alfonsofortunato.com/posts/dotfile/) - Multi-platform approach
- [Testable Dotfiles Management With Chezmoi](https://shunk031.me/post/testable-dotfiles-management-with-chezmoi/) - Testing strategies
- [Homebrew on Linux Discussion](https://github.com/orgs/Homebrew/discussions/5964) - 2025 Linux status
- [Atuin Documentation](https://docs.atuin.sh/) - Shell history sync

### Tool Ecosystem
- [Atuin](https://atuin.sh/) - Magical shell history
- [Starship](https://starship.rs/) - Cross-shell prompt
- [age](https://github.com/FiloSottile/age) - Simple encryption tool
- [Bitwarden CLI](https://bitwarden.com/help/cli/) - Password manager CLI
