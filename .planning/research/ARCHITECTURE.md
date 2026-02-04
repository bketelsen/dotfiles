# Architecture Patterns

**Domain:** Dotfiles Management with chezmoi
**Researched:** 2026-02-04
**Confidence:** HIGH

## Recommended Architecture

A cross-platform chezmoi dotfiles repository should use a **layered component architecture** with clear separation between:

1. **Configuration Data Layer** - OS-specific variables and package definitions
2. **Template Layer** - Reusable template components and shared configurations
3. **Script Layer** - Installation, setup, and lifecycle automation
4. **Dotfile Layer** - Actual configuration files (managed via chezmoi prefixes)

```
~/.local/share/chezmoi/              # Source state (git repo)
├── .chezmoiroot                      # Optional: points to 'home/' subdirectory
├── home/                             # RECOMMENDED: Actual source files (if using .chezmoiroot)
│   ├── dot_config/
│   │   ├── atuin/
│   │   │   └── config.toml.tmpl
│   │   ├── starship/
│   │   │   └── starship.toml.tmpl
│   │   ├── direnv/
│   │   │   └── direnv.toml.tmpl
│   │   └── bat/
│   │       └── config.tmpl
│   ├── dot_zshrc.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_gitconfig.tmpl
│   └── private_dot_ssh/
│       ├── encrypted_private_id_ed25519.age
│       └── config.tmpl
├── .chezmoitemplates/               # Shared template components
│   ├── shell-functions.tmpl
│   ├── homebrew-path.tmpl
│   ├── os-detection.tmpl
│   └── bitwarden-helpers.tmpl
├── .chezmoidata/                     # Data files for templates
│   ├── packages.yaml
│   └── secrets.yaml
├── .chezmoiignore                    # Conditional file exclusion
├── .chezmoiexternal.yaml             # External file management
├── chezmoi.toml                      # Repository configuration
├── run_once_before_00-install-homebrew.sh.tmpl
├── run_once_before_01-install-age.sh.tmpl
├── run_once_before_02-unlock-bitwarden.sh.tmpl
├── run_onchange_after_10-install-packages.sh.tmpl
└── run_after_99-configure-shell.sh.tmpl
```

### Component Boundaries

| Component | Responsibility | Communicates With | Files/Directories |
|-----------|---------------|-------------------|-------------------|
| **Configuration Data** | Store OS/machine-specific variables, package lists | Template Layer | `.chezmoidata/`, `chezmoi.toml` |
| **Template Library** | Provide reusable template fragments | Dotfile Layer | `.chezmoitemplates/` |
| **Lifecycle Scripts** | Bootstrap, install, configure system | All layers | `run_*` scripts |
| **Dotfiles** | Actual configuration files to deploy | Template Layer, Configuration Data | `dot_*`, `private_*`, `encrypted_*` files |
| **Encryption** | Secure sensitive files | Dotfiles, Scripts | `encrypted_*` files, age keys |
| **Secrets Manager** | Retrieve secrets at runtime | Dotfiles (via templates) | Bitwarden CLI integration |

### Data Flow

```
Bootstrap (curl chezmoi install)
    ↓
Initialize Repository (chezmoi init)
    ↓
run_once_before_* scripts execute (in alphabetical order)
    ├── Install Homebrew
    ├── Install age for encryption
    └── Unlock Bitwarden vault
    ↓
Template Processing
    ├── Load .chezmoidata/* (OS detection, package lists)
    ├── Evaluate conditionals (.chezmoi.os, .chezmoi.hostname)
    ├── Include .chezmoitemplates/* fragments
    └── Decrypt encrypted_* files (using age)
    ↓
File Deployment (chezmoi apply)
    ├── Create directories (exact_, private_)
    ├── Deploy dotfiles to home directory
    └── Set permissions (executable_, private_, readonly_)
    ↓
run_onchange_* scripts execute
    └── Install/update packages from .chezmoidata/packages.yaml
    ↓
run_after_* scripts execute
    └── Final configuration (e.g., change default shell)
```

## Patterns to Follow

### Pattern 1: .chezmoiroot for Clean Repository Structure

**What:** Use `.chezmoiroot` file containing `home` to separate actual dotfiles from repository infrastructure.

**When:** Your repository has complex structure with tests, documentation, or installation scripts at the root.

**Benefits:**
- Root directory stays uncluttered
- Separate concerns: `home/` for dotfiles, `install/` for scripts, `tests/` for validation
- Makes public repository more approachable

**Example:**
```bash
# .chezmoiroot
home
```

```
~/.local/share/chezmoi/
├── .chezmoiroot           # Points to 'home/'
├── home/                  # Actual dotfiles source
│   └── dot_bashrc.tmpl
├── install/               # Bootstrap scripts
│   └── setup.sh
└── tests/                 # Validation tests
    └── test_bashrc.bats
```

**Source:** [Customize your source directory - chezmoi](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)

### Pattern 2: Conditional OS-Specific Configuration

**What:** Use template conditionals to deploy different configurations per OS while maintaining single source files.

**When:** Configuration differs between macOS and Linux (shell, paths, tools).

**Example:**
```bash
# dot_bashrc.tmpl
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific
eval "$(/opt/homebrew/bin/brew shellenv)"
{{- else if eq .chezmoi.os "linux" }}
# Linux-specific
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{- end }}

# Common configuration
{{ template "shell-functions.tmpl" . }}
```

**Source:** [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)

### Pattern 3: Declarative Package Management with run_onchange

**What:** Store package lists in `.chezmoidata/packages.yaml` and install via `run_onchange_` scripts that only execute when package lists change.

**When:** Managing multiple tools across multiple machines.

**Example:**
```yaml
# .chezmoidata/packages.yaml
packages:
  darwin:
    brews:
      - atuin
      - bat
      - direnv
      - starship
      - age
  linux:
    brews:
      - atuin
      - bat
      - direnv
      - starship
      - age
```

```bash
# run_onchange_after_10-install-packages.sh.tmpl
#!/bin/bash
set -euo pipefail

{{- if eq .chezmoi.os "darwin" }}
# macOS
{{- range .packages.darwin.brews }}
brew install {{ . | quote }}
{{- end }}
{{- else if eq .chezmoi.os "linux" }}
# Linux
{{- range .packages.linux.brews }}
brew install {{ . | quote }}
{{- end }}
{{- end }}
```

**Source:** [Install packages declaratively - chezmoi](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)

### Pattern 4: Modular Shell Functions with .chezmoitemplates

**What:** Extract shell functions to `.chezmoitemplates/` and include them in multiple shell RC files.

**When:** Sharing functions between bash and zsh, or organizing large shell configurations.

**Example:**
```bash
# .chezmoitemplates/shell-functions.tmpl
# Common shell functions for all machines

function mk() {
  mkdir -p "$1" && cd "$1"
}

function backup() {
  cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

{{- if eq .chezmoi.os "darwin" }}
function update-all() {
  brew update && brew upgrade && brew cleanup
}
{{- end }}
```

```bash
# dot_zshrc.tmpl
# ZSH-specific configuration
autoload -Uz compinit && compinit

# Load common functions
{{ template "shell-functions.tmpl" . }}

# dot_bashrc.tmpl
# Bash-specific configuration
shopt -s histappend

# Load common functions
{{ template "shell-functions.tmpl" . }}
```

**Source:** [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)

### Pattern 5: Layered Encryption (age + Bitwarden)

**What:** Use age for encrypting files in git (SSH keys, certificates), and Bitwarden template functions for runtime secrets (API tokens, passwords).

**When:** You need both stored secrets (files) and runtime secrets (credentials).

**Example:**
```bash
# chezmoi.toml
encryption = "age"
[age]
  identity = "~/.config/chezmoi/key.txt"
  recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"

[bitwarden]
  unlock = "auto"
```

```bash
# private_dot_ssh/encrypted_private_id_ed25519.age
# Binary age-encrypted SSH key (use: chezmoi add --encrypt ~/.ssh/id_ed25519)

# dot_gitconfig.tmpl
[user]
  name = "Your Name"
  email = "{{ (bitwarden "item" "github").login.username }}"

[github]
  token = "{{ (bitwardenFields "item" "github").token.value }}"
```

**Sources:**
- [age - chezmoi](https://www.chezmoi.io/user-guide/encryption/age/)
- [Bitwarden - chezmoi](https://www.chezmoi.io/user-guide/password-managers/bitwarden/)

### Pattern 6: Script Execution Order with Prefixes

**What:** Use script prefixes to control execution timing and frequency.

**When:** Coordinating installation dependencies and idempotent operations.

**Execution Order:**
1. `run_once_before_*` - Pre-flight (install Homebrew, age, unlock Bitwarden)
2. `run_before_*` - Before each apply
3. File deployment happens here
4. `run_onchange_*` - Only when script content changes (package installation)
5. `run_after_*` - Post-deployment (shell configuration)
6. `run_once_after_*` - One-time final setup

**Numbering Convention:** Use numeric prefixes for explicit ordering: `00-`, `01-`, `02-`, etc.

**Example:**
```bash
run_once_before_00-install-homebrew.sh.tmpl
run_once_before_01-install-age.sh.tmpl
run_once_before_02-unlock-bitwarden.sh.tmpl
run_onchange_after_10-install-packages.sh.tmpl
run_after_99-configure-shell.sh.tmpl
```

**Source:** [Use scripts to perform actions - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

### Pattern 7: One-Command Bootstrap

**What:** Single curl command that installs chezmoi and applies dotfiles in one operation.

**When:** Setting up new machines or after fresh OS installation.

**Example:**
```bash
# For public repository
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-username>

# For private repository with HTTPS
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/<username>/dotfiles.git

# With SSH
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:<username>/dotfiles.git
```

**Sources:**
- [Quick start - chezmoi](https://www.chezmoi.io/quick-start/)
- [macOS - chezmoi](https://www.chezmoi.io/user-guide/machines/macos/)

## Anti-Patterns to Avoid

### Anti-Pattern 1: Script Organization in Subdirectories

**What:** Creating subdirectories to organize scripts (like `scripts/install/`, `scripts/config/`).

**Why bad:** Chezmoi creates these directories in your home directory as empty folders. Scripts must be in the source root or create unwanted target directories.

**Instead:** Use flat structure with descriptive script names and numeric prefixes:
```bash
# BAD - creates ~/scripts/ directory
scripts/run_once_install.sh

# GOOD - stays in source directory only
run_once_before_10-install-homebrew.sh.tmpl
run_once_before_20-install-packages.sh.tmpl
```

**Workaround (if needed):** The `.chezmoiscripts` directory feature allows script organization without creating target directories, but verify your chezmoi version supports it.

**Source:** [Is it possible to put 'util/library' shell scripts in `.chezmoiscripts` dir?](https://github.com/twpayne/chezmoi/discussions/3506)

### Anti-Pattern 2: Hardcoded Absolute Paths

**What:** Using absolute paths like `/Users/username/` or `/home/username/` in templates.

**Why bad:** Breaks portability across machines and users.

**Instead:** Use chezmoi template variables:
```bash
# BAD
source /Users/bjk/.config/shell/functions.sh

# GOOD
source {{ .chezmoi.homeDir }}/.config/shell/functions.sh

# BETTER (for relative paths within config)
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/functions.sh"
```

**Source:** [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)

### Anti-Pattern 3: Secrets in Plain Text Templates

**What:** Storing API keys, passwords, or tokens directly in template files that get committed to git.

**Why bad:** Secrets leak to version control history even if later encrypted. Private repositories aren't sufficient protection.

**Instead:** Use one of these approaches:
- **Age encryption:** For files (SSH keys): `chezmoi add --encrypt ~/.ssh/id_ed25519`
- **Bitwarden templates:** For runtime secrets: `{{ (bitwarden "item").login.password }}`
- **Environment variables:** For build-time secrets: `{{ .Env.SECRET_TOKEN }}`

**Never commit:**
- Plain text passwords, API keys, tokens
- Unencrypted SSH keys
- Cloud provider credentials
- Database connection strings with passwords

**Source:** [How To Manage Dotfiles With Chezmoi](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/)

### Anti-Pattern 4: Monolithic RC Files

**What:** Single massive `.bashrc` or `.zshrc` file with all configuration.

**Why bad:** Hard to maintain, test, and share across shells. Changes require reloading entire file.

**Instead:** Split into modular components:
```bash
# dot_zshrc.tmpl
# Core zsh configuration
autoload -Uz compinit && compinit

# Load modular components
{{ template "homebrew-path.tmpl" . }}
{{ template "shell-functions.tmpl" . }}

# Source functions.d directory
for f in {{ .chezmoi.homeDir }}/.config/shell/functions.d/*.sh; do
  [ -r "$f" ] && source "$f"
done

# Tool initialization
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
```

Create separate function files:
```
dot_config/shell/
├── functions.d/
│   ├── git-helpers.sh
│   ├── docker-helpers.sh
│   └── development.sh
```

**Source:** [Managing dotfiles with Chezmoi](https://natelandau.com/managing-dotfiles-with-chezmoi/)

### Anti-Pattern 5: Non-Idempotent Scripts

**What:** Scripts that fail or duplicate work when run multiple times.

**Why bad:** `run_onchange_` scripts execute every time their content changes. Non-idempotent scripts cause errors or unexpected state.

**Instead:** Make all scripts idempotent:
```bash
# BAD - fails if already exists
git clone https://github.com/user/repo ~/projects/repo

# GOOD - checks first
if [ ! -d ~/projects/repo ]; then
  git clone https://github.com/user/repo ~/projects/repo
fi

# BAD - duplicates PATH entries
export PATH="$HOME/.local/bin:$PATH"

# GOOD - checks if already in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# BEST - use run_once_ for truly one-time operations
# run_once_before_clone-repos.sh.tmpl
```

**Source:** [Use scripts to perform actions - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

### Anti-Pattern 6: Ignoring OS Differences in Homebrew Paths

**What:** Hardcoding Homebrew path as `/opt/homebrew` or `/usr/local`.

**Why bad:** macOS Apple Silicon uses `/opt/homebrew`, Intel Macs and Linux use different paths.

**Instead:** Use dynamic detection:
```bash
# .chezmoitemplates/homebrew-path.tmpl
{{- if eq .chezmoi.os "darwin" }}
{{-   if eq .chezmoi.arch "arm64" }}
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"
{{-   else }}
# Intel Mac
eval "$(/usr/local/bin/brew shellenv)"
{{-   end }}
{{- else if eq .chezmoi.os "linux" }}
# Linux
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{- end }}
```

**Source:** [macOS - chezmoi](https://www.chezmoi.io/user-guide/machines/macos/)

### Anti-Pattern 7: Skipping .chezmoiignore for Machine-Specific Files

**What:** Including all files without considering machine context.

**Why bad:** Work-specific configs deploy to personal machines, Linux configs deploy to macOS.

**Instead:** Use `.chezmoiignore` with templates:
```bash
# .chezmoiignore
{{- if ne .chezmoi.hostname "work-laptop" }}
.config/work/
.aws/work-profile
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
.config/linux-only/
{{- end }}

{{- if eq .chezmoi.os "linux" }}
.config/macos-only/
Library/
{{- end }}
```

**Source:** [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)

## Implementation Build Order

Based on dependency analysis, implement components in this order:

### Phase 1: Foundation (Bootstrap & Core Structure)
**Goal:** Basic repository structure and bootstrap capability.

1. Initialize git repository at `~/.local/share/chezmoi`
2. Create `.chezmoiroot` containing `home`
3. Create `home/`, `.chezmoitemplates/`, `.chezmoidata/` directories
4. Create `chezmoi.toml` with basic configuration
5. Create `run_once_before_00-install-homebrew.sh.tmpl` (macOS + Linux support)

**Validation:** `sh -c "$(curl -fsLS get.chezmoi.io)" -- init <repo>` works

**Dependencies:** None
**Complexity:** Low

### Phase 2: Encryption & Secrets
**Goal:** Enable secure credential storage before adding sensitive configs.

1. Create `run_once_before_01-install-age.sh.tmpl`
2. Generate age key and configure in `chezmoi.toml`
3. Create `run_once_before_02-unlock-bitwarden.sh.tmpl`
4. Configure Bitwarden in `chezmoi.toml`
5. Test encryption: `chezmoi add --encrypt <test-file>`

**Validation:** Can encrypt/decrypt files and retrieve Bitwarden secrets
**Dependencies:** Phase 1 (Homebrew)
**Complexity:** Medium

### Phase 3: Template System & OS Detection
**Goal:** Build reusable template library.

1. Create `.chezmoitemplates/os-detection.tmpl`
2. Create `.chezmoitemplates/homebrew-path.tmpl`
3. Create `.chezmoiignore` with OS conditionals
4. Test cross-platform variable access

**Validation:** Templates correctly detect OS and architecture
**Dependencies:** Phase 1
**Complexity:** Low

### Phase 4: Package Management
**Goal:** Declarative tool installation.

1. Create `.chezmoidata/packages.yaml` (atuin, bat, direnv, starship)
2. Create `run_onchange_after_10-install-packages.sh.tmpl`
3. Test package installation on both OSes

**Validation:** Running `chezmoi apply` installs all packages
**Dependencies:** Phase 1 (Homebrew), Phase 3 (OS detection)
**Complexity:** Medium

### Phase 5: Shell Configuration
**Goal:** Deploy shell configs with modular functions.

1. Create `.chezmoitemplates/shell-functions.tmpl`
2. Create `home/dot_bashrc.tmpl` (Linux)
3. Create `home/dot_zshrc.tmpl` (macOS)
4. Create `home/dot_config/shell/functions.d/` structure
5. Configure tool initialization (atuin, direnv, starship)

**Validation:** Shell loads correctly on both systems with all tools working
**Dependencies:** Phase 3 (templates), Phase 4 (packages)
**Complexity:** Medium

### Phase 6: Tool Configurations
**Goal:** Deploy tool-specific configs.

1. `home/dot_config/atuin/config.toml.tmpl`
2. `home/dot_config/starship/starship.toml.tmpl`
3. `home/dot_config/direnv/direnv.toml.tmpl`
4. `home/dot_config/bat/config.tmpl`
5. Git configuration with Bitwarden integration

**Validation:** Each tool respects custom configuration
**Dependencies:** Phase 4 (tools installed), Phase 2 (Bitwarden for git)
**Complexity:** Low-Medium

### Phase 7: SSH & Secure Files
**Goal:** Deploy encrypted sensitive files.

1. Add SSH config template: `home/private_dot_ssh/config.tmpl`
2. Encrypt SSH keys: `chezmoi add --encrypt ~/.ssh/id_*`
3. Set proper permissions via `private_` prefix
4. Create `.chezmoiignore` rules for known_hosts (machine-specific)

**Validation:** SSH keys deploy with correct permissions and encryption
**Dependencies:** Phase 2 (age encryption)
**Complexity:** Medium

### Phase 8: Final Automation
**Goal:** Complete end-to-end automation.

1. Create `run_after_99-configure-shell.sh.tmpl` (set default shell if needed)
2. Test full bootstrap on fresh macOS VM
3. Test full bootstrap on fresh Linux VM
4. Document one-command bootstrap in README

**Validation:** Single curl command fully configures new machine
**Dependencies:** All previous phases
**Complexity:** Low (mostly validation)

## Dependency Graph

```
Phase 1 (Foundation)
    ├──→ Phase 2 (Encryption)
    │       └──→ Phase 7 (SSH & Secure Files)
    ├──→ Phase 3 (Templates)
    │       ├──→ Phase 4 (Packages)
    │       │       ├──→ Phase 5 (Shell Config)
    │       │       │       └──→ Phase 6 (Tool Configs)
    │       │       └──→ Phase 6 (Tool Configs)
    │       └──→ Phase 5 (Shell Config)
    └──→ Phase 8 (Final Automation)
```

**Critical Path:** Phase 1 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 8

**Parallel Opportunities:**
- Phase 2 and Phase 3 can be developed in parallel (both depend only on Phase 1)
- Phase 6 and Phase 7 can be developed in parallel (Phase 6 needs Phase 4, Phase 7 needs Phase 2)

## Scalability Considerations

| Concern | Initial Setup | 10+ Machines | 100+ Files |
|---------|--------------|--------------|------------|
| **Repository Size** | Single repo works fine | Consider separating by environment (personal/work) using branches or separate repos | Use `.chezmoiignore` extensively; consider `.chezmoiroot` subdirectories |
| **Secret Management** | Age encryption sufficient | Bitwarden for shared secrets, machine-specific age keys | Automate Bitwarden organization/collection structure |
| **Script Execution Time** | `run_once_` keeps scripts fast | Profile script execution; cache expensive operations | Convert to `run_onchange_` with fingerprinting |
| **Template Complexity** | Simple conditionals work | Extract to `.chezmoitemplates/`; use includes | Build template library; document with examples |
| **Cross-Platform Drift** | Manual testing | Automated testing with CI/CD (GitHub Actions + VMs) | Comprehensive test matrix per OS/version |

## Advanced Patterns for Future Consideration

### External File Management

For managing files not stored in git (large binaries, licensed software):

```yaml
# .chezmoiexternal.yaml
".local/bin/tool":
  type: "archive"
  url: "https://releases.example.com/tool/v1.0.0/tool-{{ .chezmoi.os }}-{{ .chezmoi.arch }}.tar.gz"
  executable: true
```

### Machine-Specific Configuration Files

For configurations that vary per machine (not per OS):

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
  email = "personal@example.com"
  machine_type = "personal"

# Different file per machine:
# ~/.config/chezmoi/chezmoi.toml on work machine:
[data]
  email = "work@company.com"
  machine_type = "work"
```

### Testing Infrastructure

Directory structure for validation:

```
tests/
├── bats/
│   ├── test_shell.bats
│   ├── test_packages.bats
│   └── test_encryption.bats
└── run_tests.sh
```

## Sources

**HIGH Confidence (Official Documentation):**
- [Use scripts to perform actions - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Customize your source directory - chezmoi](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/)
- [age - chezmoi](https://www.chezmoi.io/user-guide/encryption/age/)
- [Bitwarden - chezmoi](https://www.chezmoi.io/user-guide/password-managers/bitwarden/)
- [Install packages declaratively - chezmoi](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)
- [macOS - chezmoi](https://www.chezmoi.io/user-guide/machines/macos/)
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Quick start - chezmoi](https://www.chezmoi.io/quick-start/)

**MEDIUM Confidence (Community Best Practices):**
- [How To Manage Dotfiles With Chezmoi](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/)
- [Managing dotfiles with Chezmoi | Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/)
- [Taking Control of My Dotfiles with chezmoi](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/)
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew, and Devpod](https://medium.com/@alfor93/cross-platform-dotfiles-with-chezmoi-nix-brew-and-devpod-0fdb478e40ce)

**Community Examples:**
- [GitHub - HotThoughts/dotfiles](https://github.com/HotThoughts/dotfiles)
- [GitHub - gazorby/dotfiles](https://github.com/gazorby/dotfiles)
- [GitHub - nicholaschiang/dotfiles](https://github.com/nicholaschiang/dotfiles)
- [GitHub - shunk031/dotfiles](https://github.com/shunk031/dotfiles)
