# ~/.shell/env.sh
# Shared environment variables sourced by both bash and zsh
# Keep this POSIX-compatible — no [[ ]], no `source`, no arrays

# Default editor
export EDITOR="vim"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo/rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
