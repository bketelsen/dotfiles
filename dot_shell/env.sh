# ~/.shell/env.sh
# Shared environment variables sourced by both bash and zsh
# Keep this POSIX-compatible — no [[ ]], no `source`, no arrays

# Default editor
export EDITOR="vim"

# mise-managed tools (also available to non-interactive shells)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo/rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Snowcat MCP token (minted on selfie:snowcat; see docs/design/queue-operations.md → Run workers)
[ -r "$HOME/.config/snowcat/mcp-token.env" ] && . "$HOME/.config/snowcat/mcp-token.env"
