# Domain Pitfalls: Chezmoi Dotfiles Management

**Domain:** Dotfiles management with chezmoi, age encryption, cross-platform support
**Researched:** 2026-02-04
**Confidence:** HIGH (verified with official documentation and multiple authoritative sources)

## Critical Pitfalls

Mistakes that cause data loss, security breaches, or require complete rewrites.

### Pitfall 1: Editing Files in Wrong Location
**What goes wrong:** Users modify the actual dotfile (e.g., `~/.zshrc`) instead of the source file in chezmoi's source directory (`~/.local/share/chezmoi/dot_zshrc`). Changes get overwritten on next `chezmoi apply`, causing loss of work.

**Why it happens:** Natural muscle memory - users forget they're managing files through chezmoi.

**Consequences:**
- Hours of configuration work lost
- Confusion about why changes disappear
- Users abandon chezmoi thinking it's broken

**Prevention:**
- Create an onboarding phase that establishes the workflow: `chezmoi edit <file>` NOT `vim ~/.zshrc`
- Add warning comments at the top of managed files: `# MANAGED BY CHEZMOI - Edit with: chezmoi edit ~/.zshrc`
- Use `chezmoi edit` exclusively in documentation and scripts
- Consider pre-commit hooks to detect manual edits

**Detection:**
- Run `chezmoi status` regularly to see divergence
- `chezmoi diff` shows uncommitted changes
- File timestamps differ between source and target

**Phase mapping:** Core Setup phase must establish this workflow before any other configuration.

---

### Pitfall 2: Committing Secrets to Repository
**What goes wrong:** Users commit secrets (API keys, AWS credentials, SSH keys) in plain text to the git repository, even private repos.

**Why it happens:**
- Forgetting to encrypt before adding files
- Not understanding that "private repository" doesn't mean "secure"
- Testing secrets in config files and forgetting to remove them
- Copy-pasting config with embedded secrets

**Consequences:**
- Security breach - secrets exposed in git history forever
- Cannot share dotfiles publicly
- Compliance violations in corporate environments
- Requires repository rewrite to remove secrets (complex and error-prone)

**Prevention:**
- Set up age encryption BEFORE adding any sensitive files
- Use `.chezmoiignore` for files that should never be committed
- Create encrypted file naming convention: `.age` suffix for encrypted files
- Add pre-commit hooks to scan for common secret patterns
- Use template placeholders for secrets: `{{ (bitwarden "item-id").password }}`
- Document the encryption workflow in Phase 1
- Use Bitwarden CLI integration for runtime secret injection

**Detection:**
- Review `git log --all --full-history --source -- '*password*' '*secret*' '*key*'`
- Use tools like `git-secrets` or `gitleaks` in pre-commit hooks
- Manual review before first push

**Phase mapping:** Encryption setup must happen in Phase 1 before adding any configuration files.

---

### Pitfall 3: Age Key Loss or No Backup Strategy
**What goes wrong:** The age encryption private key (`key.txt`) is lost, making all encrypted secrets permanently unrecoverable.

**Why it happens:**
- Key stored only on one machine that dies
- No backup strategy documented
- Key stored in dotfiles repo (ironic but dangerous)
- Accidental deletion without realizing importance

**Consequences:**
- Permanent loss of all encrypted secrets
- Cannot bootstrap on new machines
- Must regenerate all credentials and re-encrypt
- Downtime while recreating access

**Prevention:**
- Document key backup strategy in setup phase
- Store key backup in password manager (1Password, Bitwarden vault)
- Print key to paper and store in safe (extreme but valid)
- Never commit raw key to repository
- Use multiple recipient keys for team scenarios
- Document recovery procedure before it's needed
- Test recovery on a fresh machine

**Detection:**
- Test decryption on second machine during setup
- Schedule quarterly key backup verification
- Document key location in team runbook

**Phase mapping:**
- Phase 1: Key generation and initial backup
- Phase 2: Recovery procedure documentation and testing

---

### Pitfall 4: Bootstrap Script Fails Silently
**What goes wrong:** One-curl bootstrap command fails partway through, leaving system in inconsistent state with partial installation. User doesn't notice until trying to use missing tools.

**Why it happens:**
- Network interruption during curl
- Missing dependencies (XCode on macOS, sudo on Linux)
- Homebrew installation requires manual interaction
- Script doesn't check for previous successful run
- Non-zero exit codes not handled properly
- Scripts run in alphabetical order, dependencies not met

**Consequences:**
- Incomplete environment setup
- Tools fail with cryptic errors
- Manual intervention required to fix
- Loss of trust in automation
- Time wasted debugging partial state

**Prevention:**
- Make all scripts idempotent (safe to run multiple times)
- Check for prerequisites before installation
- Use `run_onchange_` scripts for conditional execution
- Add explicit dependency ordering with numbered prefixes: `run_onchange_before_10-install-homebrew.sh`
- Log all operations with clear success/failure messages
- Use `set -e` to fail fast on errors
- Provide manual recovery instructions in comments
- Test bootstrap on fresh VM/container regularly

**Detection:**
- Script exits with non-zero status
- `chezmoi status` shows errors
- Manual test of installed tools (`which brew`, `starship --version`)
- Check log files for incomplete operations

**Phase mapping:**
- Phase 1: Basic bootstrap with error handling
- Phase 3: Advanced error recovery and rollback

---

### Pitfall 5: Age Encryption Configuration Not At Top of Config
**What goes wrong:** Age encryption settings placed anywhere except the top-level section at the beginning of `chezmoi.toml`. Encryption silently doesn't work, files stored in plain text.

**Why it happens:** Users add encryption configuration after other settings, not realizing position matters.

**Consequences:**
- Files appear to be encrypted but aren't
- Secrets committed in plain text
- False sense of security
- Discovery only happens after security audit or breach

**Prevention:**
- Document required config structure in setup guide
- Provide working template that enforces correct order
- Add validation script that checks config structure
- Use `chezmoi doctor` to verify encryption setup

**Example correct structure:**
```toml
encryption = "age"
[age]
    identity = "~/.config/age/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"

# Other configuration sections below
[data]
    email = "user@example.com"
```

**Detection:**
- Run `chezmoi doctor` to check encryption setup
- Verify encrypted files have `.age` extension in source directory
- Test decryption: `chezmoi cat ~/.ssh/config` should require age key

**Phase mapping:** Phase 1 setup must validate configuration structure.

---

## Moderate Pitfalls

Mistakes that cause delays, technical debt, or require significant rework.

### Pitfall 6: Bitwarden CLI Not Unlocked During Bootstrap
**What goes wrong:** Bootstrap script templates try to use `{{ bitwarden "item-id" }}` but Bitwarden vault is locked or `BW_SESSION` not set. Templates fail to render, bootstrap stops.

**Why it happens:**
- Bitwarden requires explicit unlock step
- API key and SSO logins always require manual unlock
- `BW_SESSION` environment variable not persisted across shell sessions
- Users forget to `bw unlock` before running `chezmoi apply`

**Consequences:**
- Bootstrap fails with cryptic template errors
- Manual intervention required
- Chicken-and-egg: need secrets to configure tools, but tools needed to access secrets
- Friction in new machine setup

**Prevention:**
- Set `bitwarden.unlock = "auto"` in chezmoi config for automatic unlocking
- Document manual unlock procedure in bootstrap README
- Provide fallback for initial setup without Bitwarden
- Use conditional templates: `{{ if lookPath "bw" }}{{ bitwarden "id" }}{{ end }}`
- Create separate bootstrap phase that prompts for secrets
- Consider storing Bitwarden master password in secure enclave (macOS Keychain, Linux keyring)
- Test bootstrap sequence on fresh machine regularly

**Detection:**
- Template rendering errors mentioning `bitwarden`
- `echo $BW_SESSION` is empty
- `bw status` shows "locked"

**Phase mapping:**
- Phase 1: Manual secret prompts
- Phase 2: Bitwarden integration with documented unlock procedure
- Phase 3: Automatic unlock with secure credential storage

---

### Pitfall 7: Cross-Platform Template Logic Explosion
**What goes wrong:** Template files become unreadable mess of nested conditionals for different OS, architectures, and hostnames.

**Why it happens:**
- Different package names on macOS vs Linux
- Different file paths (`/usr/local/bin` vs `/home/linuxbrew/.linuxbrew/bin`)
- Shell differences (zsh default on macOS, bash on Linux)
- Feature availability differences
- Edge cases accumulate over time

**Consequences:**
- Templates become unmaintainable
- Hard to test all code paths
- Bugs hide in rarely-executed branches
- New contributors can't understand logic
- Fear of changing anything

**Prevention:**
- Use separate files with `.chezmoiignore` for platform-specific configs
- Extract complex logic to external scripts
- Use `.chezmoidata` files for platform-specific variables
- Minimize conditional logic in templates
- Document platform differences in README
- Use consistent patterns for OS detection
- Prefer feature detection over OS detection where possible

**Example structure:**
```
dot_zshrc.tmpl              # Common config
dot_zshrc_macos.tmpl        # macOS-specific, ignored on Linux
dot_zshrc_linux.tmpl        # Linux-specific, ignored on macOS
.chezmoiignore              # Platform ignore rules
```

**Example `.chezmoiignore`:**
```
{{ if eq .chezmoi.os "darwin" }}
*_linux.tmpl
{{ else if eq .chezmoi.os "linux" }}
*_macos.tmpl
{{ end }}
```

**Detection:**
- Template file exceeds 100 lines
- More than 3 levels of nested conditionals
- Copy-paste between OS branches
- Difficulty explaining template logic

**Phase mapping:**
- Phase 1: Simple templates with basic OS detection
- Phase 2: Refactor into modular platform-specific files
- Phase 4: Feature detection patterns

---

### Pitfall 8: Script Execution Order Dependencies
**What goes wrong:** Scripts run in alphabetical order by default. Script B depends on Script A, but "B" comes before "A" alphabetically, causing failures.

**Why it happens:**
- Not understanding chezmoi's alphabetical execution order
- Implicit dependencies not documented
- Natural naming doesn't match required order
- No dependency management system

**Consequences:**
- Bootstrap fails mysteriously
- Works on some machines but not others (race conditions)
- Manual intervention required
- Scripts must be run in specific order manually

**Prevention:**
- Use numeric prefixes to control order: `run_onchange_10-install-homebrew.sh`, `run_onchange_20-install-packages.sh`
- Use `run_before_` and `run_after_` prefixes for explicit ordering
- Document dependencies in script comments
- Make scripts check for prerequisites and fail early with clear message
- Minimize inter-script dependencies
- Consider single bootstrap script that calls functions in order

**Example naming scheme:**
```
run_onchange_before_10-install-homebrew.sh.tmpl
run_onchange_before_20-install-packages.sh.tmpl
run_onchange_30-configure-shell.sh.tmpl
run_onchange_40-setup-tools.sh.tmpl
run_after_90-verify-installation.sh.tmpl
```

**Detection:**
- Script failures referencing missing commands/paths
- Different behavior on repeated runs
- Errors about missing dependencies

**Phase mapping:**
- Phase 1: Establish naming convention for all scripts
- Document execution order in README

---

### Pitfall 9: Homebrew Not Installed Before Package Scripts Run
**What goes wrong:** Bootstrap scripts try to run `brew install` before Homebrew itself is installed, causing "command not found" errors.

**Why it happens:**
- Homebrew requires manual installation step on fresh systems
- Installation script requires user interaction (password prompt)
- PATH not updated until new shell session
- Script doesn't check if Homebrew exists before using it

**Consequences:**
- Bootstrap fails immediately
- User must manually install Homebrew then rerun
- Poor first-time user experience
- Documentation needed for workaround

**Prevention:**
- Use numbered script prefix to ensure Homebrew installs first: `run_onchange_before_10-install-homebrew.sh`
- Check for Homebrew before attempting to use it:
  ```bash
  if ! command -v brew &> /dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  ```
- Update PATH in same script after Homebrew installation
- Use `run_once_` for Homebrew installation to avoid repeated installations
- Make script idempotent with existence checks

**Example script structure:**
```bash
#!/bin/bash
set -e

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    echo "Homebrew already installed"
    exit 0
fi

# Install Homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update PATH for current script
{{ if eq .chezmoi.os "linux" }}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{ else if eq .chezmoi.os "darwin" }}
eval "$(/opt/homebrew/bin/brew shellenv)"
{{ end }}

brew --version
```

**Detection:**
- "brew: command not found" errors
- Scripts fail before any packages installed
- Bootstrap stops at first `brew install` command

**Phase mapping:**
- Phase 1: Homebrew installation must be first script
- Phase 2: Package installation scripts run after Homebrew confirmed

---

### Pitfall 10: Manual Commit Workflow Not Understood
**What goes wrong:** Users run `chezmoi edit` and make changes, but changes never persist to git repository. On new machine, old config appears because git wasn't updated.

**Why it happens:**
- Chezmoi doesn't auto-commit by default
- Users expect dotfile changes to auto-sync like cloud storage
- Coming from tools that auto-commit (some Nix setups)
- Forgetting the git step in workflow

**Consequences:**
- Work lost when bootstrapping new machine
- Confusion about which version is "real"
- Conflicting changes across machines
- Manual conflict resolution required

**Prevention:**
- Document three-step workflow prominently: Edit, Commit, Push
- Create shell aliases for common workflows:
  ```bash
  alias dotfiles-sync='chezmoi cd && git add . && git commit -m "Update dotfiles" && git push && cd -'
  ```
- Enable auto-commit in chezmoi config (with caution):
  ```toml
  [git]
      autoCommit = true
      autoPush = false  # Manual push for safety
  ```
- Create wrapper script that handles git operations
- Add reminders in shell prompt when chezmoi has uncommitted changes
- Consider `run_after_` script to check for uncommitted changes and warn

**Warning about auto-push:** If auto-push is enabled, sensitive files could accidentally be uploaded to remote repository. Only auto-commit, not auto-push.

**Detection:**
- `chezmoi cd && git status` shows uncommitted changes
- New machine has stale configuration
- `git log` shows no recent commits despite known changes

**Phase mapping:**
- Phase 1: Document manual workflow
- Phase 3: Optional auto-commit setup with clear warnings

---

### Pitfall 11: Cannot Add chezmoi.toml to Chezmoi
**What goes wrong:** Users try to run `chezmoi add ~/.config/chezmoi/chezmoi.toml` but it fails. Chezmoi explicitly disallows managing its own config file.

**Why it happens:**
- Intuition says "manage all dotfiles"
- Want to version control chezmoi configuration
- Need different config on different machines
- Circular dependency: config file defines how to process templates, but config file itself might be a template

**Consequences:**
- Manual chezmoi config setup on each machine
- Configuration drift across machines
- Frustration with tool limitations

**Prevention:**
- Use `.chezmoi.toml.tmpl` in source directory (template generates actual config)
- Create separate repository for machine-specific chezmoi configs
- Document manual config setup in bootstrap README
- Use `.chezmoidata` files for machine-specific variables instead of templated config
- Run `chezmoi execute-template --init` to regenerate config from template

**Example `.chezmoi.toml.tmpl`:**
```toml
{{ if eq .chezmoi.os "darwin" -}}
[data]
    packager = "homebrew"
    shell = "zsh"
{{ else if eq .chezmoi.os "linux" -}}
[data]
    packager = "apt"
    shell = "bash"
{{ end -}}
```

**Detection:**
- Error message: "chezmoi.toml is not allowed in source state"
- Config changes don't propagate to new machines
- Manual editing of config required on each machine

**Phase mapping:**
- Phase 1: Document config template approach
- Phase 2: Create reusable config template for different machine types

---

### Pitfall 12: Shell PATH Not Updated After Tool Installation
**What goes wrong:** Scripts install tools (atuin, starship, direnv) but PATH isn't updated until new shell session. Subsequent scripts fail trying to use newly-installed tools.

**Why it happens:**
- Tool installers modify `~/.zshrc` or `~/.bashrc` (shell init files)
- Changes only take effect on new shell
- Bootstrap script runs in single shell session
- Scripts assume tool availability immediately after installation

**Consequences:**
- Bootstrap scripts fail partway through
- Manual shell reload required mid-bootstrap
- Errors about missing commands for just-installed tools
- Inconsistent behavior between runs

**Prevention:**
- Source shell initialization in scripts after installing tools:
  ```bash
  # Install tool
  brew install starship

  # Update PATH for current script
  eval "$(starship init bash)"
  ```
- Use absolute paths to installed tools instead of assuming PATH
- Check for tool existence before use: `command -v starship || brew install starship`
- Split bootstrap into stages with shell reload between them
- Use `run_before_` and `run_after_` to separate installation from configuration

**Example with explicit PATH:**
```bash
#!/bin/bash
{{ if eq .chezmoi.os "darwin" }}
BREW_PREFIX="/opt/homebrew"
{{ else }}
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{ end }}

# Use absolute path
"${BREW_PREFIX}/bin/starship" --version
```

**Detection:**
- "command not found" errors for just-installed tools
- `which <tool>` returns nothing despite successful installation
- Scripts work on second run but not first run

**Phase mapping:**
- Phase 1: Document PATH update requirements
- Phase 2: Implement PATH updates in installation scripts

---

## Minor Pitfalls

Mistakes that cause annoyance but are easily fixable.

### Pitfall 13: Template Syntax Confusion
**What goes wrong:** Users confuse Go template syntax with shell variable syntax. Write `$HOME` in template expecting shell expansion, but chezmoi treats it as literal string.

**Why it happens:**
- Templates use `{{ }}` for Go templates
- Shell scripts use `$VAR` for variables
- Both can exist in same file (template + script)
- Not clear when template renders vs when script executes

**Consequences:**
- Variables not expanded as expected
- Debugging confusion
- Working locally but breaking on other machines

**Prevention:**
- Document template vs shell variable distinction clearly
- Use `{{ .chezmoi.homeDir }}` for chezmoi variables
- Use `$HOME` for runtime shell variables
- Add comments explaining when each renders
- Use `chezmoi execute-template` to test template rendering

**Example:**
```bash
# Template-time variable (rendered when chezmoi apply runs)
export CONFIG_DIR="{{ .chezmoi.homeDir }}/.config"

# Runtime shell variable (expanded when script executes)
export CURRENT_USER="$USER"

# Escape template delimiters if you need literal {{ }}
# {{ `{{ literal curly braces }}` }}
```

**Detection:**
- Unexpected literal strings in rendered files
- Variables not expanding
- Different behavior across machines despite same template

**Phase mapping:** Phase 1 documentation should explain template syntax clearly.

---

### Pitfall 14: Forgetting .tmpl Extension
**What goes wrong:** User creates file with template syntax but forgets `.tmpl` extension. Chezmoi copies file literally without processing templates. Variables appear as `{{ .var }}` in final file.

**Why it happens:**
- Template processing only happens for files ending in `.tmpl`
- Easy to forget extension when creating new files
- No warning when template syntax exists in non-template file

**Consequences:**
- Configuration contains literal template syntax instead of values
- Applications fail to parse config
- Debugging confusion about why templates aren't working

**Prevention:**
- Use `chezmoi add --template <file>` to automatically add `.tmpl` extension
- Create files directly in source directory with `.tmpl` extension
- Add verification script to check for `{{` in non-template files
- Document template creation workflow

**Detection:**
- Literal `{{` characters appear in target files
- `cat ~/.config/app/config` shows unrendered templates
- Configuration parsing errors

**Phase mapping:** Phase 1 should document template file creation workflow.

---

### Pitfall 15: Excessive Use of run_ Scripts
**What goes wrong:** Users create `run_` scripts for everything, even purely declarative configurations. Scripts break idempotency, make debugging harder, and violate chezmoi's declarative philosophy.

**Why it happens:**
- Scripts seem more flexible than declarative configs
- Coming from imperative shell script background
- Not understanding chezmoi's declarative model
- Copying examples that overuse scripts

**Consequences:**
- Hard to predict what will happen on `chezmoi apply`
- State tracking becomes complex
- Difficult to understand current system state
- Scripts may fail unpredictably

**Prevention:**
- Use declarative file management for configs (preferred)
- Reserve scripts for truly imperative operations (package installation, system config)
- Make all scripts idempotent (safe to run multiple times)
- Document why each script exists and what state it manages
- Prefer `.chezmoiexternal` for fetching external files over custom scripts

**Decision matrix:**
- Copying a config file → Use regular dotfile, not script
- Installing packages → Use `run_onchange_` script with Brewfile
- Setting system preferences → Use `run_once_` script
- Generating dynamic config → Use template, not script

**Detection:**
- `run_` scripts that only copy files (should be regular dotfiles)
- Scripts that fail on second run (not idempotent)
- Growing collection of scripts with unclear purpose

**Phase mapping:** Phase 1 should establish patterns for when to use scripts vs declarative files.

---

### Pitfall 16: Not Testing Bootstrap on Fresh System
**What goes wrong:** Bootstrap works perfectly on developer's machine (which already has tools installed) but fails completely on fresh system due to missing prerequisites.

**Why it happens:**
- Testing on already-configured machine
- Implicit dependencies not documented
- Tools installed globally via other methods
- Assuming system state that doesn't exist on fresh install

**Consequences:**
- New team members cannot onboard
- Personal machine recovery fails
- Emergency setup takes hours instead of minutes
- Bootstrap reputation damage

**Prevention:**
- Test bootstrap in Docker container regularly
- Use GitHub Actions to test bootstrap on clean Ubuntu/macOS runners
- Create VM snapshots for testing
- Document prerequisites explicitly
- Add prerequisite checks at start of bootstrap
- Get fresh eyes: have teammate test bootstrap

**Testing script example:**
```bash
#!/bin/bash
# run_onchange_before_00-check-prerequisites.sh

# Check for required tools
REQUIRED_TOOLS=(curl git)
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "ERROR: Required tool not found: $tool"
        exit 1
    fi
done
```

**Detection:**
- Bootstrap fails on colleague's machine
- Works on old machine but not new machine
- Different errors each time bootstrap runs

**Phase mapping:**
- Phase 1: Manual testing on fresh VM
- Phase 3: Automated CI testing of bootstrap

---

### Pitfall 17: Modular functions.d Not Sourced in Order
**What goes wrong:** Shell functions split into separate files in `functions.d/` directory, but sourcing happens alphabetically. Function B calls Function A, but B loads before A, causing "command not found" errors.

**Why it happens:**
- Natural naming doesn't match dependency order
- Glob expansion processes files alphabetically
- No explicit dependency declaration
- Functions spread across many files for organization

**Consequences:**
- Functions fail with "command not found"
- Order-dependent bugs that are hard to debug
- Different behavior across shells/systems
- Fragile configuration that breaks on edits

**Prevention:**
- Use numeric prefixes for functions with dependencies: `10-core.sh`, `20-helpers.sh`, `30-git.sh`
- Make functions independent where possible
- Put all dependency-heavy functions in single file
- Use lazy loading (define function that loads dependency on first call)
- Document function dependencies in comments

**Example sourcing pattern in `.zshrc`:**
```bash
# Source all functions in order
for func_file in ~/.config/shell/functions.d/*.sh; do
    [ -r "$func_file" ] && source "$func_file"
done
```

**Example with numeric prefixes:**
```
functions.d/
├── 10-core.sh           # Core utilities, no dependencies
├── 20-git-helpers.sh    # Depends on core
├── 30-project-tools.sh  # Depends on git helpers
└── README.md            # Document loading order
```

**Detection:**
- Functions fail with "command not found" for other functions
- Different behavior when files renamed
- Works on some machines but not others

**Phase mapping:** Phase 2 should establish modular configuration patterns with clear sourcing order.

---

### Pitfall 18: Shell Integration Tools Init Order Matters
**What goes wrong:** Tools like atuin, direnv, and starship need to be initialized in shell config in specific order. Wrong order causes conflicts or features not working.

**Why it happens:**
- Each tool modifies shell behavior (prompt, history, environment)
- Some tools override others' settings
- Documentation doesn't mention interaction
- Copy-paste configs without understanding

**Consequences:**
- Prompt looks broken
- History search doesn't work
- Environment variables not loaded
- Keybindings conflict

**Prevention:**
- Document recommended initialization order
- Test different orders to find working combination
- Use consistent pattern across machines
- Comment why order matters

**Recommended order for common tools:**
```bash
# 1. direnv - Must be early to modify environment before other tools
eval "$(direnv hook zsh)"

# 2. Starship prompt - Sets up prompt before history tools
eval "$(starship init zsh)"

# 3. atuin - History tool comes after prompt setup
eval "$(atuin init zsh)"

# 4. Other tools that don't modify core shell behavior
eval "$(zoxide init zsh)"
```

**Reasoning:**
- direnv first because it modifies environment variables that other tools might read
- Starship before atuin because atuin modifies history behavior that affects prompt
- zoxide last because it's purely additive (adds `z` command)

**Detection:**
- Prompt displays incorrectly
- History search keybindings don't work (Ctrl-R)
- Environment variables not loading per directory
- Error messages about conflicting configurations

**Phase mapping:** Phase 2 should document and implement correct tool initialization order.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: Initial Setup | Pitfall 2 (Secrets in repo), Pitfall 5 (Age config position) | Set up encryption before adding any files; provide config template |
| Phase 1: Bootstrap Script | Pitfall 4 (Silent failures), Pitfall 9 (Homebrew not installed) | Use numbered script prefixes; make scripts idempotent; add error handling |
| Phase 2: Secret Management | Pitfall 3 (Key loss), Pitfall 6 (Bitwarden not unlocked) | Document backup strategy; test key recovery; auto-unlock config |
| Phase 2: Cross-Platform | Pitfall 7 (Template logic explosion), Pitfall 12 (PATH not updated) | Use platform-specific files; minimize conditionals; explicit PATH management |
| Phase 3: Shell Config | Pitfall 17 (functions.d order), Pitfall 18 (Tool init order) | Numeric prefixes for files; document loading order; test on fresh shell |
| Phase 4: Tool Integration | Pitfall 8 (Script dependencies), Pitfall 15 (Script overuse) | Explicit script ordering; prefer declarative configs over scripts |
| All Phases | Pitfall 1 (Wrong location edits), Pitfall 10 (No git commits) | Establish workflow in Phase 1; create helper aliases; add reminders |
| Testing | Pitfall 16 (No fresh system testing) | Regular testing in Docker/VM; document prerequisites; CI automation |

## Common Anti-Patterns Summary

**Security Anti-Patterns:**
- Committing secrets in plain text (even to private repos)
- Age config not at top of config file
- No backup strategy for encryption keys
- Auto-push enabled (risk of accidental secret exposure)

**Workflow Anti-Patterns:**
- Editing target files instead of source files
- Not committing changes to git
- No testing on fresh systems
- Assuming tools are installed without checking

**Template Anti-Patterns:**
- Complex nested conditionals (use platform-specific files instead)
- Forgetting `.tmpl` extension
- Confusing template-time vs runtime variables
- Template logic that should be in scripts

**Script Anti-Patterns:**
- Scripts that aren't idempotent
- No dependency ordering (alphabetical accidents)
- Using scripts for purely declarative configs
- Scripts that fail silently without error handling

**Cross-Platform Anti-Patterns:**
- Hardcoded paths that differ across OS
- Assuming shell features (zsh arrays on bash)
- Not updating PATH after tool installation
- Testing only on one platform

## Sources

**Official Documentation (HIGH confidence):**
- [Troubleshooting - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/)
- [age encryption - chezmoi](https://www.chezmoi.io/user-guide/encryption/age/)
- [Use scripts - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [Bitwarden integration - chezmoi](https://www.chezmoi.io/user-guide/password-managers/bitwarden/)
- [macOS - chezmoi](https://www.chezmoi.io/user-guide/machines/macos/)
- [Manage machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Install packages declaratively - chezmoi](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)

**Community Resources (MEDIUM confidence):**
- [How To Manage Dotfiles With Chezmoi](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/)
- [Managing dotfiles with Chezmoi](https://natelandau.com/managing-dotfiles-with-chezmoi/)
- [Cross-Platform Dotfiles with Chezmoi](https://alfonsofortunato.com/posts/dotfile/)
- [Bootstrap repositories - dotfiles.github.io](https://dotfiles.github.io/bootstrap/)
- [Talm v0.17: Built-in Age Encryption](https://cozystack.io/blog/2025/12/talm-v0-17-built-in-age-encryption-for-secrets/)

**GitHub Issues and Discussions (MEDIUM confidence - verified patterns):**
- [Issue #830: Script run before templates](https://github.com/twpayne/chezmoi/issues/830)
- [Issue #3285: Adding chezmoi.toml](https://github.com/twpayne/chezmoi/discussions/3285)
- [Issue #3980: Builtin age doesn't work](https://github.com/twpayne/chezmoi/issues/3980)
- [Discussion #1538: age encryption multiple computers](https://github.com/twpayne/chezmoi/discussions/1538)

**Additional Community Guides:**
- [Using chezmoi Templates](https://kidoni.dev/using-templates-with-chezmoi)
- [Shell startup sequence](https://rickcogley.github.io/dotfiles/explanations/shell-startup.html)
- [Bash vs Zsh in 2025](https://medium.com/@awaleedpk/bash-vs-zsh-choosing-your-shell-in-2025-d6b9ed9d4354)
