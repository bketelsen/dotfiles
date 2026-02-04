# Git shortcuts and helper functions
# Sourced by .zshrc / .bashrc

# Status and diff
alias gs='git status'
alias gst='git status --short'
alias gd='git diff'
alias gds='git diff --staged'

# Adding and committing
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcmsg='git commit -m'
alias gca='git commit --amend'

# Pushing and pulling
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'

# Branching
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'

# Logging
alias glog='git log --oneline --graph --decorate -10'
alias gloga='git log --oneline --graph --decorate --all -20'

# Helpers
alias gundo='git reset --soft HEAD~1'
alias gunstage='git restore --staged'

# Functions
# Git add all and commit with message
gac() {
  git add --all && git commit -m "$*"
}

# Git add, commit, and push
gcp() {
  git add --all && git commit -m "$*" && git push
}

# Git checkout main/master (whichever exists)
gcom() {
  if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
  elif git show-ref --verify --quiet refs/heads/master; then
    git checkout master
  else
    echo "Neither main nor master branch exists"
    return 1
  fi
}
