# Utility aliases and modern CLI replacements
# Sourced by .zshrc / .bashrc

# Modern replacements (only if installed)
# Use \command or command command to access originals

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias catp='bat --plain'  # No line numbers, no paging
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
  alias lta='eza --tree --level=2 -a'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

# Safer defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Quick shortcuts
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Quick edit
alias ez='${EDITOR:-vim} ~/.zshrc'
alias eb='${EDITOR:-vim} ~/.bashrc'
alias sz='source ~/.zshrc'
alias sb='source ~/.bashrc'

# Get public IP
myip() {
  curl -s https://api.ipify.org && echo
}

# Manage dotfiles with Claude Code
cdots() {
  claude "$(chezmoi source-path)"
}

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
