#!/bin/sh
# Dotfiles Bootstrap Script
# This script installs Homebrew and chezmoi, then applies dotfiles configuration
# Can be run via: sh -c "$(curl -fsSL https://raw.githubusercontent.com/bjk/dotfiles/main/bootstrap.sh)"

set -e

# Configuration
GITHUB_USERNAME="bketelsen"
LOG_FILE="${HOME}/.dotfiles-bootstrap.log"

# Color codes (will be set by setup_colors)
BOLD=""
RED=""
GREEN=""
BLUE=""
RESET=""

# Setup color support based on terminal capabilities
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
    BOLD="${BOLD:-}"
    RED="${RED:-}"
    GREEN="${GREEN:-}"
    BLUE="${BLUE:-}"
    RESET="${RESET:-}"
}

# Log message to stdout and file
log() {
    message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    printf '%s\n' "$message"
    printf '%s\n' "$message" >> "$LOG_FILE"
}

# Print error and exit
abort() {
    printf '%sERROR: %s%s\n' "$RED" "$1" "$RESET" >&2
    printf 'Suggested fix: %s\n' "$2" >&2
    printf 'Check %s for details\n' "$LOG_FILE" >&2
    printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
    exit 1
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    if ! curl -fsS --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        abort "Cannot reach github.com" "Check your internet connection and try again"
    fi
    if ! curl -fsS --connect-timeout 5 --max-time 10 "https://brew.sh" >/dev/null 2>&1; then
        abort "Cannot reach brew.sh" "Check your internet connection and try again"
    fi
    log "Network connectivity OK"
}

# Detect operating system
detect_os() {
    log "Detecting operating system..."
    OS="$(uname -s)"
    case "$OS" in
        Darwin)
            OS="macos"
            log "Detected: macOS"
            ;;
        Linux)
            OS="linux"
            log "Detected: Linux"
            ;;
        *)
            abort "Unsupported operating system: $OS" "This script only supports macOS and Linux"
            ;;
    esac
}

# Install Homebrew if not present
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log "Homebrew already installed, skipping..."
        return 0
    fi

    log "Installing Homebrew..."
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1; then
        abort "Failed to install Homebrew" "Check $LOG_FILE for details or try running the command manually"
    fi
    log "Homebrew installed successfully"
}

# Configure Homebrew PATH for current session
configure_homebrew_path() {
    log "Configuring Homebrew environment..."

    # Check all possible Homebrew locations
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log "Homebrew configured (Apple Silicon path)"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        log "Homebrew configured (Linux path)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        log "Homebrew configured (Intel Mac path)"
    else
        abort "Homebrew installation not found" "Try running the Homebrew installer manually"
    fi
}

# Install chezmoi if not present
install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        log "chezmoi already installed, skipping..."
        return 0
    fi

    log "Installing chezmoi..."
    if ! brew install chezmoi >> "$LOG_FILE" 2>&1; then
        abort "Failed to install chezmoi" "Check $LOG_FILE for details or try 'brew install chezmoi' manually"
    fi
    log "chezmoi installed successfully"
}

# Apply dotfiles using chezmoi
apply_dotfiles() {
    log "Applying dotfiles configuration..."

    if ! chezmoi init --apply "$GITHUB_USERNAME" >> "$LOG_FILE" 2>&1; then
        abort "Failed to apply dotfiles" "Check $LOG_FILE for details or try 'chezmoi init --apply $GITHUB_USERNAME' manually"
    fi

    log "Dotfiles applied successfully"
}

# Show completion summary
show_summary() {
    printf '\n%s========================================%s\n' "$GREEN$BOLD" "$RESET"
    printf '%sBootstrap Complete!%s\n' "$GREEN$BOLD" "$RESET"
    printf '%s========================================%s\n\n' "$GREEN$BOLD" "$RESET"

    printf 'Your dotfiles have been installed and configured.\n\n'

    printf '%sNext steps:%s\n' "$BOLD" "$RESET"
    printf '  1. Restart your shell or run: exec %s\n' "$SHELL"
    printf '  2. Review installed configuration\n'
    printf '  3. Customize as needed with: chezmoi edit <file>\n\n'

    printf '%sUseful commands:%s\n' "$BOLD" "$RESET"
    printf '  chezmoi diff    - See what would change\n'
    printf '  chezmoi apply   - Apply dotfiles changes\n'
    printf '  chezmoi update  - Pull and apply latest changes\n\n'

    printf 'Log file: %s\n' "$LOG_FILE"
}

# Main execution
main() {
    printf '\n%sDotfiles Bootstrap%s\n' "$BLUE$BOLD" "$RESET"
    printf 'Starting bootstrap process...\n\n'

    # Initialize logging
    printf '=== Bootstrap started at %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"

    setup_colors
    check_network
    detect_os
    install_homebrew
    configure_homebrew_path
    install_chezmoi
    apply_dotfiles
    show_summary

    log "Bootstrap completed successfully"
}

# Run main function
main
