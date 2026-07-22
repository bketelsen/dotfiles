# Chezmoi drift detection
# Sourced by .zshrc / .bashrc
#
# Three layers of defense against editing dotfiles outside chezmoi:
#   1. Shell startup: warn when applied dotfiles differ from chezmoi source
#   2. Flag file (~/.cache/chezmoi-drift) drives the starship custom.chezmoi
#      prompt segment without running `chezmoi status` on every prompt
#   3. vim/vi wrappers redirect chezmoi-managed files to `chezmoi edit --apply`

_chezmoi_drift_flag="${XDG_CACHE_HOME:-$HOME/.cache}/chezmoi-drift"

# Refresh the flag file. Returns 0 and sets _cz_drift when drift exists.
_chezmoi_drift_refresh() {
  command -v chezmoi >/dev/null 2>&1 || return 1
  _cz_drift=$(command chezmoi status 2>/dev/null)
  if [ -n "$_cz_drift" ]; then
    mkdir -p "${_chezmoi_drift_flag%/*}" 2>/dev/null
    printf '%s\n' "$_cz_drift" > "$_chezmoi_drift_flag"
  else
    rm -f "$_chezmoi_drift_flag"
    unset _cz_drift
    return 1
  fi
}

_chezmoi_drift_warn() {
  if _chezmoi_drift_refresh; then
    printf '\033[33m! chezmoi drift detected:\033[0m\n'
    printf '%s\n' "$_cz_drift" | while IFS= read -r _cz_line; do
      printf '    %s\n' "$_cz_line"
    done
    printf '\033[2m    chezmoi diff           show what changed\n'
    printf '    chezmoi re-add <file>  keep local edits\n'
    printf '    chezmoi apply <file>   restore from source\033[0m\n'
  fi
  unset _cz_drift
}

# Keep the prompt flag accurate within this shell after state-changing commands
chezmoi() {
  command chezmoi "$@"
  _cz_ret=$?
  case "${1:-}" in
    apply|add|re-add|edit|update|init|forget|destroy|unmanage|purge)
      _chezmoi_drift_refresh
      unset _cz_drift
      ;;
  esac
  return $_cz_ret
}

# If the first file argument is chezmoi-managed, edit the source instead.
# --apply writes the change back to the real file on save, so no drift.
_chezmoi_edit_guard() {
  _cz_editor="$1"
  shift
  if command -v chezmoi >/dev/null 2>&1; then
    for _cz_f in "$@"; do
      case "$_cz_f" in -*) continue ;; esac
      if command chezmoi source-path "$_cz_f" >/dev/null 2>&1; then
        printf '\033[36m%s is chezmoi-managed - editing source (applies on save)\033[0m\n' "$_cz_f"
        chezmoi edit --apply "$_cz_f"
        return $?
      fi
    done
  fi
  command "$_cz_editor" "$@"
}

vim() { _chezmoi_edit_guard vim "$@"; }
vi()  { _chezmoi_edit_guard vi "$@"; }

_chezmoi_drift_warn
