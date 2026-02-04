# Phase 2: Encryption & Secrets - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Set up age encryption for sensitive files and Bitwarden CLI integration for runtime secret retrieval. Encrypted files are decrypted during chezmoi apply. Keys are generated during initial setup and stored outside the repo. Recovery procedures are documented.

</domain>

<decisions>
## Implementation Decisions

### Key management
- Store age private key at `~/.config/chezmoi/key.txt` (standard chezmoi location, outside repo)
- Auto-generate key silently on first-time setup if none exists
- Display public key after generation so user can immediately back it up
- Never overwrite an existing key — preserve what's there

### Bitwarden workflow
- Prompt for Bitwarden login only when a secret is actually needed (lazy authentication)
- Bitwarden integration is optional — bootstrap works without it, secrets use defaults or stay blank
- One unlock per chezmoi apply — authenticate once at start, use session throughout
- Flexible secret types — design for API tokens, SSH keys, and config files

### Encrypted file handling
- Use standard `chezmoi add --encrypt` workflow for adding encrypted files
- Edit encrypted files with `chezmoi edit` (decrypt to temp, open editor, re-encrypt)
- Encrypt credential files (.netrc, .npmrc), full config files with embedded secrets, and SSH private keys
- Add pre-commit safeguard to prevent accidental plaintext commits of sensitive files

### Recovery & backup
- Back up age key to multiple locations (Bitwarden secure note AND physical/offline)
- Display public key after generation for easy copying to backup
- Create dedicated `docs/encryption.md` with full recovery procedures

### Claude's Discretion
- Key rotation design — implement if it makes sense, otherwise one key forever is fine
- Specific BW session handling implementation details
- Pre-commit hook implementation approach (hook vs gitattributes vs other)
- Recovery documentation specifics for key loss scenario

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-encryption-secrets*
*Context gathered: 2026-02-04*
