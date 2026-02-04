# Phase 2: Encryption & Secrets - Research

**Researched:** 2026-02-04
**Domain:** chezmoi with age encryption and Bitwarden CLI integration
**Confidence:** HIGH

## Summary

This research covers implementing age encryption and Bitwarden CLI integration within chezmoi for secure dotfile management. The standard approach uses age (v1.3.1+) for file encryption with X25519 keys stored outside the repository at `~/.config/chezmoi/key.txt`, and Bitwarden CLI for runtime secret retrieval via template functions.

Age encryption in chezmoi is well-established with built-in support and simple configuration. The workflow is transparent: files are encrypted during `chezmoi add --encrypt`, automatically decrypted during `chezmoi apply`, and can be edited in plaintext via `chezmoi edit` which handles encryption/decryption automatically. Bitwarden integration provides template functions (`bitwarden`, `bitwardenFields`, etc.) with session caching to avoid repeated authentication prompts.

Critical implementation decisions are locked: use age (not GPG), store keys at `~/.config/chezmoi/key.txt`, integrate Bitwarden CLI, use standard chezmoi commands for encrypted file management, and implement pre-commit safeguards. The key challenge is balancing security (encrypted files, safe key storage) with usability (one-time authentication, automatic key generation, no passphrase prompts during normal operations).

**Primary recommendation:** Use age-keygen via chezmoi wrapper (`chezmoi age-keygen`) for key generation, configure automatic Bitwarden unlock with `bitwarden.unlock = "auto"`, implement detect-secrets pre-commit hook for safety, and provide comprehensive recovery documentation with multiple backup strategies.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| age | v1.3.1+ | File encryption | Officially recommended by chezmoi; simpler than GPG with X25519 keys |
| chezmoi | latest | Dotfile manager | Built-in age support; automatic encryption/decryption workflow |
| bitwarden-cli (bw) | latest | Secret retrieval | Native chezmoi template functions; session caching |
| age-keygen | (included) | Key generation | Standard key generation for age; outputs identity + recipient |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| detect-secrets | v1.5.0+ | Pre-commit scanning | Prevent accidental plaintext commits of sensitive files |
| pre-commit | latest | Git hook framework | Manage pre-commit hooks declaratively |
| expect | system package | Automated password entry | Optional: headless key decryption on first setup |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| age | GPG | GPG is more complex; age explicitly recommended by chezmoi docs |
| age | SSH keys | age docs recommend against SSH keys; only X25519 supported |
| bw CLI | rbw | rbw is third-party; bw is official Bitwarden CLI |
| detect-secrets | git-secrets | git-secrets is AWS-specific; detect-secrets more general |

**Installation:**
```bash
# age (via Homebrew - already in Phase 1)
brew install age

# Bitwarden CLI
brew install bitwarden-cli

# Pre-commit framework (optional but recommended)
pip install pre-commit
# OR
brew install pre-commit

# detect-secrets
pip install detect-secrets
# OR
brew install detect-secrets
```

## Architecture Patterns

### Recommended Project Structure
```
~/.local/share/chezmoi/          # Source directory
├── .chezmoi.toml.tmpl           # Config with age + bw settings
├── .chezmoiignore               # Ignore key.txt.age if stored here
├── dot_config/
│   └── ...                      # Regular config files
├── encrypted_dot_netrc.tmpl     # Encrypted credential file with template
├── encrypted_private_dot_ssh/   # Encrypted SSH keys
│   └── private_key
├── .chezmoiscripts/
│   └── run_once_before_00-decrypt-age-key.sh.tmpl  # Optional: first-time key setup
└── docs/
    └── encryption.md            # Recovery procedures

~/.config/chezmoi/               # Outside repo (gitignored by default)
├── key.txt                      # Age private key (identity)
└── chezmoi.toml                 # Applied config (generated from template)
```

### Pattern 1: Age Key Generation and Storage
**What:** Generate age keypair on first setup, store private key outside repo, display public key for backup
**When to use:** Initial dotfile setup or new machine provisioning
**Example:**
```bash
# Source: https://www.chezmoi.io/user-guide/encryption/age/
# Generate key with chezmoi wrapper
chezmoi age-keygen --output=$HOME/.config/chezmoi/key.txt

# Outputs:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
# (save this for configuration and backup)
```

**Key considerations:**
- Identity (private key) goes in `~/.config/chezmoi/key.txt` (standard location)
- Recipient (public key) goes in chezmoi configuration
- Never commit private key to repository
- Public key needed for configuration and is safe to share

### Pattern 2: Chezmoi Configuration with Age
**What:** Configure chezmoi to use age encryption with identity and recipient
**When to use:** In chezmoi configuration file (typically `.chezmoi.toml.tmpl`)
**Example:**
```toml
# Source: https://www.chezmoi.io/user-guide/encryption/age/
# CRITICAL: encryption must be at top level BEFORE other sections
encryption = "age"

[age]
    identity = "{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"

# Other config sections follow...
```

**Multiple recipients (for team/multi-device):**
```toml
encryption = "age"

[age]
    identities = ["{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"]
    recipients = [
        "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p",  # Primary
        "age1yztv8tn9x2kx8k3w7l9j2mn4w8r5h6t3p9q2l4k7m6n8x5w2h3j4k5l6m7",  # Backup
    ]
```

### Pattern 3: Adding and Editing Encrypted Files
**What:** Transparent encryption workflow for sensitive files
**When to use:** Any file with credentials, secrets, or sensitive data
**Example:**
```bash
# Source: https://www.chezmoi.io/reference/commands/edit/
# Add encrypted file (encrypts automatically)
chezmoi add --encrypt ~/.netrc

# Edit encrypted file (decrypts to temp, opens editor, re-encrypts)
chezmoi edit ~/.netrc

# Edit and apply immediately
chezmoi edit --apply ~/.netrc

# Result in source directory:
# encrypted_dot_netrc (if not template)
# encrypted_dot_netrc.tmpl (if template)
```

**Important behaviors:**
- Files are decrypted to private temporary directory during edit
- On editor exit, file is re-encrypted and replaces source
- Templates can be encrypted: `encrypted_*.tmpl` files work correctly
- Encrypted files get `.age` extension in repository (internal detail)

### Pattern 4: Bitwarden CLI Integration
**What:** Retrieve secrets at runtime via template functions with automatic session management
**When to use:** For secrets that change frequently or are shared across machines
**Example:**
```toml
# Source: https://www.chezmoi.io/reference/templates/bitwarden-functions/
# In .chezmoi.toml.tmpl - configure auto-unlock
[bitwarden]
    unlock = "auto"  # Only unlock if BW_SESSION not set
```

```bash
# In template file (e.g., encrypted_dot_npmrc.tmpl)
# Source: https://www.chezmoi.io/reference/templates/bitwarden-functions/bitwarden/
//registry.npmjs.org/:_authToken={{ (bitwarden "item" "npm-token").login.password }}
```

```bash
# Access custom fields
# Source: https://www.chezmoi.io/reference/templates/bitwarden-functions/bitwardenFields/
[github]
    token = {{ (bitwardenFields "item" "github-api").token.value }}
```

**Session management:**
- `bitwarden.unlock = false`: Never unlock automatically (manual `export BW_SESSION`)
- `bitwarden.unlock = true`: Always run `bw unlock` before operations
- `bitwarden.unlock = "auto"`: Only unlock if `BW_SESSION` not already set (recommended)
- Results are cached per unique argument set (multiple calls with same args only invoke `bw` once)
- Chezmoi runs `bw lock` before exit when auto-unlock is enabled

### Pattern 5: Pre-commit Hook for Secret Detection
**What:** Prevent accidental commits of plaintext secrets
**When to use:** Always - safety net for human error
**Example:**
```yaml
# Source: https://github.com/Yelp/detect-secrets
# .pre-commit-config.yaml in repository root
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: |
          (?x)(
            package-lock.json|
            poetry.lock|
            encrypted_.*
          )
```

**Setup:**
```bash
# Install pre-commit framework
pip install pre-commit  # or brew install pre-commit

# Generate baseline of known secrets (first time)
detect-secrets scan > .secrets.baseline

# Install git hooks
pre-commit install

# Test
pre-commit run --all-files
```

**Exclusion patterns:**
- Exclude `encrypted_*` files (already protected)
- Exclude lock files (high false positives)
- Use inline allowlist for known false positives: `# pragma: allowlist secret`

### Pattern 6: First-Time Key Setup Script
**What:** Automated age key generation on first `chezmoi init`
**When to use:** Bootstrap new machines without manual key setup
**Example:**
```bash
# Source: https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/
# .chezmoiscripts/run_once_before_00-generate-age-key.sh.tmpl
#!/bin/sh
# Generate age key if it doesn't exist

KEY_FILE="{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"

if [ ! -f "$KEY_FILE" ]; then
    echo "Generating age encryption key..."
    mkdir -p "$(dirname "$KEY_FILE")"

    # Generate key and capture public key
    PUBLIC_KEY=$(chezmoi age-keygen --output="$KEY_FILE" 2>&1 | grep "Public key:" | cut -d' ' -f3)

    chmod 600 "$KEY_FILE"

    echo "Age key generated at: $KEY_FILE"
    echo "Public key: $PUBLIC_KEY"
    echo ""
    echo "IMPORTANT: Back up this public key and your private key file!"
    echo "Save to Bitwarden, 1Password, or another secure location."
else
    echo "Age key already exists at: $KEY_FILE"
fi
```

### Pattern 7: Recovery Documentation
**What:** Clear procedures for key loss and recovery scenarios
**When to use:** Documentation in `docs/encryption.md`
**Example structure:**
```markdown
# Encryption & Recovery

## Backup Procedures

1. **Age Private Key** (`~/.config/chezmoi/key.txt`)
   - Store in Bitwarden as secure note
   - Keep offline copy on encrypted USB drive
   - Print and store in safe (for disaster recovery)

2. **Age Public Key**
   - Record in this document: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
   - Safe to commit to repository (but good to have separately)

## Recovery Scenarios

### Scenario 1: New Machine Setup
1. Install chezmoi
2. Copy age private key to `~/.config/chezmoi/key.txt`
3. Run `chezmoi init --apply https://github.com/user/dotfiles.git`

### Scenario 2: Lost Private Key (Key Backed Up)
1. Retrieve key from backup location
2. Copy to `~/.config/chezmoi/key.txt` on all machines
3. Verify with `chezmoi apply --dry-run`

### Scenario 3: Lost Private Key (No Backup) - UNRECOVERABLE
- All encrypted files are permanently inaccessible
- Must re-encrypt all files with new key:
  1. On machine with decrypted files: `chezmoi apply` (apply current state)
  2. Generate new age key
  3. Update configuration with new recipient
  4. Re-add all encrypted files: `chezmoi forget <files> && chezmoi add --encrypt <files>`
```

### Anti-Patterns to Avoid
- **Committing private key to repository:** Never add `key.txt` to source directory; keep in `~/.config/chezmoi/`
- **Encryption directive in wrong location:** Must be top-level in config BEFORE all other sections
- **Using SSH keys as identities:** Age docs recommend against this; use X25519 keys only
- **Passphrase-based encryption for regular use:** Prompts become tiresome during `chezmoi diff`, `status`, etc.
- **Manual bw unlock in templates:** Use `bitwarden.unlock = "auto"` in config instead
- **Forgetting to backup public key:** Needed for configuration; make it accessible
- **Adding `--encrypt` to already-managed files:** Use `chezmoi edit` instead of `chezmoi add` for existing files

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Key generation | Custom keygen script | `chezmoi age-keygen` | Outputs correct format, integrated with chezmoi |
| File encryption/decryption | Manual `age` commands | `chezmoi add --encrypt` / `chezmoi edit` | Automatic workflow; handles templates correctly |
| Bitwarden session management | Custom `bw unlock` wrapper | `bitwarden.unlock` config | Built-in caching; automatic lock on exit |
| Secret detection | Regex patterns in custom hook | detect-secrets pre-commit | Comprehensive plugin system; baseline management |
| Encrypted file diffs | Git diff filters | `chezmoi diff` | Decrypts automatically; shows actual changes |
| Template secret retrieval | Shell command substitution | `bitwarden` template functions | Cached; error handling; consistent |
| Key backup automation | Custom backup script | Multiple manual backups + docs | Key loss is rare; automation adds complexity/risk |
| Multi-recipient encryption | Re-encrypt for each recipient | age `recipients = [...]` | Single encryption, multiple decryption keys |

**Key insight:** Chezmoi's age integration is designed to be transparent. The more you try to work around it with manual encryption commands or custom wrappers, the more likely you'll create inconsistencies between source state and target state. Use the built-in commands and let chezmoi handle the encryption lifecycle.

## Common Pitfalls

### Pitfall 1: Age Key Not Found During Apply
**What goes wrong:** `chezmoi apply` fails with "age: error: identity file not found"
**Why it happens:** Private key doesn't exist at configured identity path
**How to avoid:**
- Always use `~/.config/chezmoi/key.txt` as standard location
- Check file exists before `chezmoi apply`: `test -f ~/.config/chezmoi/key.txt`
- Use templating in config: `identity = "{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"`
**Warning signs:** First-time setup on new machine without key distribution

### Pitfall 2: Identity/Recipient Mismatch
**What goes wrong:** "age: error: no identity matched any of the recipients"
**Why it happens:** File was encrypted with different recipient than current identity's public key
**How to avoid:**
- Keep public key recorded (in docs or config comments)
- Don't change keys without re-encrypting files
- For key rotation: apply all files first, then forget and re-add with new key
**Warning signs:** After key regeneration or copying wrong key file to new machine

### Pitfall 3: Encryption Config Placement
**What goes wrong:** Age encryption not recognized; files not decrypted
**Why it happens:** `encryption = "age"` directive not at top level or placed after other sections
**How to avoid:** Always put encryption configuration at the very beginning of config file
**Warning signs:** Chezmoi treats encrypted files as regular files
**Correct:**
```toml
encryption = "age"
[age]
    identity = "..."
    recipient = "..."

[data]
    # other config...
```
**Wrong:**
```toml
[data]
    # other config...

encryption = "age"  # Too late!
[age]
    identity = "..."
```

### Pitfall 4: Bitwarden Session Expiry During Apply
**What goes wrong:** `chezmoi apply` hangs or prompts for password mid-execution
**Why it happens:** BW_SESSION expired or not set; auto-unlock not configured
**How to avoid:**
- Set `bitwarden.unlock = "auto"` in config
- Or manually: `export BW_SESSION="$(bw unlock --raw)"` before `chezmoi apply`
- Make Bitwarden integration optional: provide fallback values or conditionals in templates
**Warning signs:** Templates with Bitwarden functions but no session management config

### Pitfall 5: Editing Encrypted Files Directly
**What goes wrong:** Changes to source state in repository don't decrypt/apply correctly
**Why it happens:** Manually editing `encrypted_*` files instead of using `chezmoi edit`
**How to avoid:** Always use `chezmoi edit <file>` for encrypted files
**Warning signs:** Trying to open `encrypted_dot_file` directly in editor; seeing encrypted content

### Pitfall 6: Accidentally Committing Plaintext Secrets
**What goes wrong:** Secrets committed to repository in plaintext (e.g., wrong filename, forgot `--encrypt`)
**Why it happens:** Human error during `chezmoi add` or file creation
**How to avoid:**
- Install detect-secrets pre-commit hook
- Use `.chezmoiignore` for sensitive files that shouldn't be in repo at all
- Review `git diff` in source directory before commits
**Warning signs:** No pre-commit hook installed; rushed workflow

### Pitfall 7: Builtin Age vs External Age Confusion
**What goes wrong:** Passphrase/SSH key features don't work; unexpected behavior
**Why it happens:** Chezmoi uses builtin age when `age` binary not in PATH; builtin doesn't support all features
**How to avoid:**
- Install age explicitly via package manager (Homebrew in Phase 1)
- Verify age is in PATH: `which age`
- Don't use passphrase or SSH key features (use X25519 keys)
**Warning signs:** Age installed but passphrase prompts don't appear

### Pitfall 8: Lost Private Key Without Backup
**What goes wrong:** All encrypted files become permanently inaccessible
**Why it happens:** Hardware failure, accidental deletion, no backup strategy
**How to avoid:**
- Document public key in repository (safe to commit)
- Back up private key to password manager (Bitwarden secure note)
- Keep offline backup (encrypted USB drive or printout)
- Test recovery procedure on fresh machine
**Warning signs:** No documented backup procedure; only one copy of key

### Pitfall 9: Template Encryption Ordering
**What goes wrong:** Template processed before decryption; secrets appear as encrypted blobs
**Why it happens:** Misunderstanding of chezmoi processing order (decrypt → template → apply)
**How to avoid:**
- Understand: `encrypted_*.tmpl` decrypts FIRST, then processes template
- Templates can safely reference Bitwarden functions after decryption
- Don't try to decrypt within templates; encryption is transparent
**Warning signs:** Seeing age-encrypted content in applied files

### Pitfall 10: Bitwarden CLI Not Authenticated
**What goes wrong:** `bw unlock` or `bw login` prompts interrupt automation
**Why it happens:** Bitwarden requires authentication before first use
**How to avoid:**
- Separate concern: `bw login` is one-time setup per machine
- Auto-unlock only handles `bw unlock` (session unlock), not login
- Document pre-requisite: "Run `bw login` before first `chezmoi apply`"
- Make templates defensive: check if Bitwarden is available/authenticated
**Warning signs:** Fresh machine setup without Bitwarden login step

## Code Examples

Verified patterns from official sources:

### Complete Configuration Example
```toml
# Source: https://www.chezmoi.io/user-guide/encryption/age/
# ~/.local/share/chezmoi/.chezmoi.toml.tmpl

# CRITICAL: Encryption config MUST be first, top-level
encryption = "age"

[age]
    # Identity: private key location (outside repo)
    identity = "{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"

    # Recipient: public key (safe to hardcode)
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"

[bitwarden]
    # Auto-unlock if BW_SESSION not already set
    unlock = "auto"

[data]
    # Your custom data for templates
    email = "user@example.com"
```

### Encrypted Template with Bitwarden Integration
```bash
# Source: https://www.chezmoi.io/reference/templates/bitwarden-functions/
# ~/.local/share/chezmoi/encrypted_dot_netrc.tmpl

# This file is encrypted AND templated
# Processing order: decrypt → template → apply

{{- $npmItem := bitwarden "item" "npm-registry" -}}
{{- $githubItem := bitwarden "item" "github-packages" -}}

machine registry.npmjs.org
  login {{ $npmItem.login.username }}
  password {{ $npmItem.login.password }}

machine npm.pkg.github.com
  login {{ $githubItem.login.username }}
  password {{ (bitwardenFields "item" "github-packages").personal_token.value }}
```

### Defensive Bitwarden Template (Optional Fallback)
```bash
# Template that works even if Bitwarden unavailable
{{- $bwAvailable := and (lookPath "bw") (env "BW_SESSION") -}}

[github]
{{- if $bwAvailable }}
    token = {{ (bitwardenFields "item" "github").token.value }}
{{- else }}
    # Fallback: use placeholder or skip
    token = "BITWARDEN_NOT_AVAILABLE_REPLACE_ME"
{{- end }}
```

### Key Generation Script with Validation
```bash
# Source: Adapted from https://www.chezmoi.io/user-guide/encryption/age/
# .chezmoiscripts/run_once_before_00-setup-age-key.sh.tmpl
#!/bin/sh
set -e

KEY_FILE="{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"
CONFIG_FILE="{{ .chezmoi.homeDir }}/.config/chezmoi/chezmoi.toml"

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
    echo "Age key already exists: $KEY_FILE"
    exit 0
fi

# Ensure config directory exists
mkdir -p "$(dirname "$KEY_FILE")"

# Generate key
echo "Generating age encryption key..."
OUTPUT=$(chezmoi age-keygen --output="$KEY_FILE" 2>&1)

# Extract public key from output
PUBLIC_KEY=$(echo "$OUTPUT" | grep "Public key:" | awk '{print $3}')

# Secure permissions
chmod 600 "$KEY_FILE"

echo "✓ Age key generated successfully"
echo ""
echo "Private key: $KEY_FILE"
echo "Public key: $PUBLIC_KEY"
echo ""
echo "IMPORTANT - BACKUP YOUR KEYS:"
echo "  1. Save public key to password manager: $PUBLIC_KEY"
echo "  2. Backup private key file: $KEY_FILE"
echo "  3. Update chezmoi config with recipient: $PUBLIC_KEY"
echo ""
```

### Pre-commit Configuration with Chezmoi Exclusions
```yaml
# Source: https://github.com/Yelp/detect-secrets
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args:
          - '--baseline'
          - '.secrets.baseline'
          - '--exclude-files'
          - 'encrypted_.*'  # Already encrypted
        exclude: |
          (?x)(
            package-lock.json|
            poetry.lock|
            Brewfile.lock.json
          )

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: end-of-file-fixer
      - id: trailing-whitespace
```

### Verify Age Encryption Setup
```bash
# Verification script - run after setup
#!/bin/bash

echo "Verifying age encryption setup..."

# Check age binary
if ! command -v age >/dev/null 2>&1; then
    echo "✗ age binary not found in PATH"
    exit 1
fi
echo "✓ age binary found: $(which age)"

# Check age-keygen
if ! command -v age-keygen >/dev/null 2>&1; then
    echo "✗ age-keygen not found"
    exit 1
fi
echo "✓ age-keygen found"

# Check private key
KEY_FILE="$HOME/.config/chezmoi/key.txt"
if [ ! -f "$KEY_FILE" ]; then
    echo "✗ Private key not found: $KEY_FILE"
    exit 1
fi
echo "✓ Private key exists: $KEY_FILE"

# Check key permissions
PERMS=$(stat -f "%Lp" "$KEY_FILE" 2>/dev/null || stat -c "%a" "$KEY_FILE" 2>/dev/null)
if [ "$PERMS" != "600" ]; then
    echo "⚠ Warning: Key file permissions are $PERMS (should be 600)"
else
    echo "✓ Key file permissions correct: 600"
fi

# Check config
CONFIG_FILE="$HOME/.config/chezmoi/chezmoi.toml"
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "^encryption.*=.*\"age\"" "$CONFIG_FILE"; then
        echo "✓ Age encryption configured in chezmoi.toml"
    else
        echo "✗ Age encryption not configured in chezmoi.toml"
        exit 1
    fi
else
    echo "⚠ Warning: chezmoi.toml not found (will be generated on first apply)"
fi

echo ""
echo "Age encryption setup verified successfully!"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GPG encryption | age encryption | age v1.0.0 (2020) | Simpler keys, better UX, recommended by chezmoi |
| Manual bw unlock in templates | `bitwarden.unlock` config | chezmoi v2.x | Automatic session management, caching |
| Symmetric passphrase encryption | X25519 key pairs | age best practices | No prompts during normal operations |
| Git diff filters for encrypted files | `chezmoi diff` | chezmoi native | Transparent decryption for diffs |
| Custom pre-commit scripts | detect-secrets framework | ~2020 | Plugin system, baseline management, widely adopted |
| Post-quantum disabled | Post-quantum hybrid keys | age v1.3.0 (Dec 2025) | Use `-pq` flag for quantum-resistant encryption |

**Deprecated/outdated:**
- **GPG for chezmoi encryption**: Still supported but age is recommended (simpler, better docs)
- **Passphrase-based age encryption**: Works but impractical for frequent decryption operations
- **SSH keys as age identities**: age documentation explicitly recommends against; use X25519 only
- **Manual BW_SESSION export in templates**: Use `bitwarden.unlock` configuration instead
- **Builtin age with passphrase**: Builtin age doesn't support passphrases; must use external age binary

## Open Questions

Things that couldn't be fully resolved:

1. **Bitwarden CLI Session Timeout Duration**
   - What we know: `BW_SESSION` tokens don't have automatic timeout; valid until `bw lock` or terminal close
   - What's unclear: Exact server-side session validity duration; community discussions mention 1-hour timeouts but official docs don't specify
   - Recommendation: Assume sessions are short-lived; use `bitwarden.unlock = "auto"` to re-unlock as needed

2. **Key Rotation Best Practices**
   - What we know: Rotation requires decrypt-all → new-key → re-encrypt-all workflow
   - What's unclear: Frequency recommendation; whether multiple recipients mitigate rotation need
   - Recommendation: Marked as "Claude's Discretion" in CONTEXT.md; implement simple rotation docs but don't enforce periodic rotation unless user requests

3. **Pre-commit Hook vs Gitattributes**
   - What we know: detect-secrets pre-commit hook scans staged files; gitattributes can mark files as binary
   - What's unclear: Whether gitattributes adds meaningful protection beyond pre-commit hooks for chezmoi
   - Recommendation: Use detect-secrets pre-commit hook (marked as Claude's Discretion); gitattributes unnecessary as `encrypted_*` files already handled by chezmoi

4. **Headless Automation with Age Passphrase**
   - What we know: Install Doctor uses `expect` + `AGE_PASSWORD` env var for headless decryption
   - What's unclear: Whether this level of automation is needed for user's use case; adds complexity
   - Recommendation: Document but don't implement unless needed; standard key-based auth is simpler

## Sources

### Primary (HIGH confidence)
- [chezmoi age encryption documentation](https://www.chezmoi.io/user-guide/encryption/age/) - Official age setup guide
- [chezmoi age configuration reference](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/encryption/age.md) - Complete config examples
- [chezmoi Bitwarden functions reference](https://www.chezmoi.io/reference/templates/bitwarden-functions/) - Template function documentation
- [chezmoi bitwarden function](https://www.chezmoi.io/reference/templates/bitwarden-functions/bitwarden/) - Detailed function syntax
- [chezmoi bitwardenFields function](https://www.chezmoi.io/reference/templates/bitwarden-functions/bitwardenFields/) - Custom fields access
- [chezmoi encryption FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/) - Common issues and solutions
- [chezmoi edit command reference](https://www.chezmoi.io/reference/commands/edit/) - Edit command documentation
- [age GitHub repository](https://github.com/FiloSottile/age) - Latest version (v1.3.1), installation, key generation
- [detect-secrets GitHub repository](https://github.com/Yelp/detect-secrets) - Installation, configuration, examples
- [Bitwarden CLI documentation](https://bitwarden.com/help/cli/) - Session management, authentication

### Secondary (MEDIUM confidence)
- [Sync Claude Code with chezmoi and age blog](https://www.arun.blog/sync-claude-code-with-chezmoi-and-age/) - Real-world workflow example
- [Install Doctor age decryption script](https://install.doctor/docs/scripts/before/run_before_03-decrypt-age-key.sh.tmpl) - Headless automation pattern
- [Bitwarden CLI session discussion](https://community.bitwarden.com/t/cli-session-expiration/43611) - Session timeout behavior
- [Git hooks secret prevention guide](https://orca.security/resources/blog/git-hooks-prevent-secrets/) - Pre-commit best practices
- [detect-secrets best practices](https://medium.com/@mabhijit1998/pre-commit-and-detect-secrets-best-practises-6223877f39e4) - Configuration patterns

### Tertiary (LOW confidence)
- [chezmoi GitHub discussions on encryption](https://github.com/twpayne/chezmoi/discussions/3713) - Community patterns (marked for validation)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools verified from official sources; versions confirmed
- Architecture patterns: HIGH - Examples from official docs and verified real-world implementations
- Pitfalls: HIGH - Documented in official FAQs and verified through GitHub issues
- Bitwarden session timeout: MEDIUM - Community discussions but no official timeout specification
- Pre-commit implementation details: MEDIUM - Multiple valid approaches; detect-secrets is well-established

**Research date:** 2026-02-04
**Valid until:** 2026-03-04 (30 days - stable ecosystem; age and chezmoi are mature)
