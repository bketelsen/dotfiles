# Navigation shortcuts
# Sourced by .zshrc / .bashrc

# Directory traversal
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Common directories
alias ~='cd ~'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias dev='cd ~/dev'
alias dots='cd ~/.local/share/chezmoi'

# Directory stack (pushd/popd shortcuts)
alias d='dirs -v'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'

# Make directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Quick find in current directory
f() {
  find . -name "*$1*" 2>/dev/null
}
