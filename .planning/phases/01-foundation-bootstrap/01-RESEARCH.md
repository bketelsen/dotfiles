# Phase 1: Foundation & Bootstrap - Research

**Researched:** 2026-02-04
**Domain:** Shell scripting, chezmoi bootstrap, Homebrew installation
**Confidence:** HIGH

## Summary

This phase implements a single-command bootstrap that installs Homebrew and chezmoi, then applies dotfiles to a fresh machine. The research confirms that chezmoi provides a well-documented one-liner pattern (`sh -c "$(curl ...)" -- init --apply user/repo`) that can be wrapped in a custom bootstrap script to add Homebrew installation and enhanced user feedback.

The standard approach is a POSIX-compatible shell script (using `/bin/sh` shebang for maximum portability) that:
1. Validates network connectivity
2. Installs Homebrew if not present (using official installer with `NONINTERACTIVE=1`)
3. Installs chezmoi via Homebrew or the official get.chezmoi.io script
4. Runs `chezmoi init --apply` to apply dotfiles

**Primary recommendation:** Write a POSIX sh bootstrap script that wraps Homebrew and chezmoi installation with proper error handling (`set -e`), terminal color detection, and file logging. Use chezmoi's official init pattern rather than custom cloning.

## Standard Stack

The established tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Homebrew | Latest | Package manager for macOS/Linux | Official installer handles all OS/arch detection |
| chezmoi | Latest | Dotfiles manager | Built-in init+apply pattern, official install script |
| curl | System | HTTP client for downloads | Available on macOS, most Linux; more reliable than wget |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| tput | Terminal color detection | When outputting colored status messages |
| tee | Dual output logging | Logging to file while showing progress |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| POSIX sh | Bash | Bash has better features but sh is more portable |
| curl | wget | wget more common on minimal Linux, but curl on both macOS/major distros |
| Homebrew chezmoi | get.chezmoi.io | Homebrew approach is simpler if Homebrew already installed |

**Installation commands:**
```bash
# Homebrew (official, non-interactive)
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# chezmoi via Homebrew
brew install chezmoi

# chezmoi via official script (alternative)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

## Architecture Patterns

### Recommended Script Structure
```
bootstrap.sh
    |
    +-- validate_prerequisites()    # Check curl, network
    +-- detect_os()                 # macOS vs Linux
    +-- install_homebrew()          # Idempotent Homebrew install
    +-- configure_homebrew_path()   # Add to PATH for session
    +-- install_chezmoi()           # Via brew or fallback
    +-- apply_dotfiles()            # chezmoi init --apply
    +-- show_summary()              # Next steps
```

### Pattern 1: Fail-Fast with set -e
**What:** Exit immediately on any command failure
**When to use:** Always for bootstrap scripts
**Example:**
```sh
#!/bin/sh
# Source: Homebrew installer pattern
set -e

abort() {
    printf "%s\n" "$@" >&2
    exit 1
}
```

### Pattern 2: Idempotent Installation Checks
**What:** Skip installation if tool already present
**When to use:** For Homebrew and chezmoi installation
**Example:**
```sh
# Source: Common dotfiles bootstrap pattern
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log "Homebrew already installed, skipping"
        return 0
    fi
    # ... installation code
}
```

### Pattern 3: Terminal Color Detection
**What:** Auto-detect color support, provide colorful output when available
**When to use:** For user-facing status messages
**Example:**
```sh
# Source: Homebrew installer
setup_colors() {
    if [ -t 1 ]; then
        tty_escape() { printf "\033[%sm" "$1"; }
    else
        tty_escape() { :; }
    fi
    tty_mkbold() { tty_escape "1;$1"; }
    tty_blue="$(tty_mkbold 34)"
    tty_red="$(tty_mkbold 31)"
    tty_green="$(tty_mkbold 32)"
    tty_reset="$(tty_escape 0)"
}
```

### Pattern 4: Dual Output Logging
**What:** Show output on terminal AND log to file
**When to use:** For debugging failed bootstraps
**Example:**
```sh
# Source: BashFAQ/106 pattern
LOG_FILE="$HOME/.dotfiles-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1
```
**Note:** Process substitution `>()` requires bash. For POSIX sh, use named pipes or simpler approach.

### Pattern 5: Network Connectivity Check
**What:** Verify internet access before attempting downloads
**When to use:** At script start, before any curl commands
**Example:**
```sh
# Source: Common bootstrap patterns
check_network() {
    if ! curl -fsS --connect-timeout 5 "https://github.com" >/dev/null 2>&1; then
        abort "No network connectivity. Please check your internet connection."
    fi
}
```

### Anti-Patterns to Avoid
- **Using `set -e` with arithmetic expansion:** `((counter++))` returns 1 when counter is 0, triggering exit
- **Relying on sudo credential caching with Homebrew:** Homebrew explicitly invalidates sudo timestamp
- **Using bash-specific features in /bin/sh scripts:** Arrays, `[[`, `{a,b}` expansion not POSIX
- **Hardcoding Homebrew paths:** Path differs between macOS Intel (`/usr/local`), Apple Silicon (`/opt/homebrew`), and Linux (`/home/linuxbrew/.linuxbrew`)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OS/arch detection | Custom uname parsing | Homebrew installer pattern | Handles edge cases (WSL, ARM, etc.) |
| Homebrew installation | Manual git clone | Official install.sh | Handles permissions, directories, XCode CLI tools |
| chezmoi installation | Manual binary download | `get.chezmoi.io` or `brew install` | Handles libc detection, architecture |
| Dotfiles application | Manual symlinks | `chezmoi init --apply` | Handles templates, encryption, scripts |
| Color output | Raw ANSI codes | tput-based detection | Handles non-TTY, TERM variations |

**Key insight:** The Homebrew and chezmoi install scripts have years of edge-case handling. Wrapping them is better than reimplementing their logic.

## Common Pitfalls

### Pitfall 1: Homebrew PATH Not Available in Same Session
**What goes wrong:** After installing Homebrew, `brew` command not found
**Why it happens:** Shell PATH not updated until shell restart
**How to avoid:** Explicitly eval brew shellenv after installation
**Warning signs:** "brew: command not found" immediately after install
```sh
# After Homebrew install, add to current session
if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
```

### Pitfall 2: POSIX sh vs Bash Compatibility
**What goes wrong:** Script fails on systems where /bin/sh is dash or other non-bash shell
**Why it happens:** Using bashisms in scripts with `#!/bin/sh` shebang
**How to avoid:** Use POSIX-only features: `[ ]` not `[[ ]]`, no arrays, `$(cmd)` not `$((cmd))` for subshells
**Warning signs:** "Syntax error" or "unexpected token" on Ubuntu/Debian

### Pitfall 3: sudo Credential Timeout
**What goes wrong:** User prompted for password multiple times during long bootstrap
**Why it happens:** sudo credentials expire after 5-15 minutes; Homebrew invalidates timestamp
**How to avoid:** Prompt for sudo once at start with `sudo -v`, accept that Homebrew may re-prompt
**Warning signs:** Password prompt appearing mid-installation

### Pitfall 4: curl vs wget Availability
**What goes wrong:** Script fails because curl not available
**Why it happens:** Minimal Linux installations may have wget but not curl
**How to avoid:** Check for curl, fall back to wget, or require curl as prerequisite
**Warning signs:** "curl: command not found"

### Pitfall 5: Network Check False Positives
**What goes wrong:** Network check passes but downloads fail
**Why it happens:** Checking wrong host, or corporate proxy/firewall issues
**How to avoid:** Check actual hosts that will be used (github.com, brew.sh)
**Warning signs:** Connection timeout during installation

### Pitfall 6: Process Substitution in POSIX sh
**What goes wrong:** `exec > >(tee file)` fails
**Why it happens:** Process substitution `>()` is a bash feature, not POSIX
**How to avoid:** Use simpler logging or require bash for the script
**Warning signs:** "Syntax error near unexpected token `>'"

## Code Examples

Verified patterns from official sources and best practices:

### Bootstrap Script Header (POSIX sh)
```sh
#!/bin/sh
# Source: Homebrew installer pattern + shell best practices
set -e

# Logging
LOG_FILE="${HOME}/.dotfiles-bootstrap.log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

abort() {
    printf 'ERROR: %s\n' "$1" >&2
    printf 'See %s for details\n' "$LOG_FILE" >&2
    exit 1
}
```

### OS Detection
```sh
# Source: Homebrew installer
detect_os() {
    OS="$(uname -s)"
    case "$OS" in
        Darwin) OS="macos" ;;
        Linux) OS="linux" ;;
        *) abort "Unsupported operating system: $OS" ;;
    esac
}
```

### Homebrew Installation (Idempotent)
```sh
# Source: Official Homebrew documentation
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log "Homebrew already installed"
        return 0
    fi

    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

configure_homebrew_path() {
    # Detect Homebrew location and add to PATH for this session
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        abort "Homebrew installation not found"
    fi
}
```

### chezmoi Installation and Init
```sh
# Source: chezmoi documentation
install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        log "chezmoi already installed"
        return 0
    fi

    log "Installing chezmoi..."
    brew install chezmoi
}

apply_dotfiles() {
    log "Applying dotfiles..."
    chezmoi init --apply "$GITHUB_USERNAME"
}
```

### Color Setup (POSIX-compatible)
```sh
# Source: Homebrew installer pattern
setup_colors() {
    if [ -t 1 ] && [ -n "${TERM-}" ] && command -v tput >/dev/null 2>&1; then
        if [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
            BOLD="$(tput bold)"
            RED="$(tput setaf 1)"
            GREEN="$(tput setaf 2)"
            BLUE="$(tput setaf 4)"
            RESET="$(tput sgr0)"
        fi
    fi
    # Defaults if tput unavailable
    BOLD="${BOLD:-}"
    RED="${RED:-}"
    GREEN="${GREEN:-}"
    BLUE="${BLUE:-}"
    RESET="${RESET:-}"
}
```

### Network Connectivity Check
```sh
# Source: Common bootstrap patterns
check_network() {
    log "Checking network connectivity..."
    if ! curl -fsS --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        abort "Cannot reach github.com. Please check your internet connection."
    fi
    if ! curl -fsS --connect-timeout 5 --max-time 10 "https://brew.sh" >/dev/null 2>&1; then
        abort "Cannot reach brew.sh. Please check your internet connection."
    fi
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GPG for secrets | age encryption | chezmoi 2.x | Simpler key management |
| Manual symlinks | chezmoi templates | Always | Templating, encryption, scripts |
| Profile-based installs | Single config | User decision | Simplicity for v1 |

**Deprecated/outdated:**
- Homebrew tapping homebrew-core: No longer needed since Homebrew API (2023+)
- Using `--depth=1` always: Not needed unless using `--one-shot`

## Open Questions

Things that couldn't be fully resolved:

1. **Linux build prerequisites**
   - What we know: Homebrew on Linux needs build-essential/development tools
   - What's unclear: Whether to auto-install these or just warn
   - Recommendation: Check and warn, let user install prerequisites

2. **Exact log file location**
   - What we know: User decided "log to file for debugging"
   - What's unclear: `~/.dotfiles-bootstrap.log` vs `~/.local/state/dotfiles/bootstrap.log`
   - Recommendation: Use simple `~/.dotfiles-bootstrap.log` per XDG convention relaxation

3. **Shell script shebang choice**
   - What we know: POSIX sh is more portable, bash has better features
   - Marked as: Claude's discretion
   - Recommendation: Use `#!/bin/sh` for maximum portability, avoid bashisms

4. **Script arguments (--dry-run, --verbose)**
   - What we know: User marked as Claude's discretion
   - Options: Full getopts parsing vs simple positional args vs none
   - Recommendation: Add `--verbose` for debug output, `--dry-run` to show what would run

## Sources

### Primary (HIGH confidence)
- [chezmoi Install Documentation](https://www.chezmoi.io/install/) - Installation methods, script flags
- [chezmoi init Reference](https://www.chezmoi.io/reference/commands/init/) - All init flags and options
- [chezmoi Setup Guide](https://www.chezmoi.io/user-guide/setup/) - Init workflow
- [Homebrew Installation Docs](https://docs.brew.sh/Installation) - Official install command
- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) - Linux-specific configuration
- [Homebrew install.sh source](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) - Actual implementation patterns
- [chezmoi get.chezmoi.io script](https://raw.githubusercontent.com/twpayne/chezmoi/master/assets/scripts/install.sh) - Script flags, OS detection

### Secondary (MEDIUM confidence)
- [Shell Error Handling Best Practices](https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425) - set -e, pipefail patterns
- [BashFAQ/106](https://mywiki.wooledge.org/BashFAQ/106) - Tee logging patterns
- [Testing Internet Connection](https://www.baeldung.com/linux/internet-connection-bash-test) - Network check methods
- [Terminal Color Detection](https://www.baeldung.com/linux/terminal-colors) - tput patterns

### Tertiary (LOW confidence)
- WebSearch results for bootstrap script patterns - Community practices, marked for validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official documentation for all tools
- Architecture: HIGH - Patterns derived from Homebrew installer source
- Pitfalls: MEDIUM - Some from community sources, verified where possible
- Code examples: HIGH - Adapted from official sources

**Research date:** 2026-02-04
**Valid until:** 60 days (tools are stable, patterns well-established)
