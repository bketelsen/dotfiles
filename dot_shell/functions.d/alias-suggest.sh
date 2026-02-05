# Alias suggestion script
# Suggests existing aliases based on recent shell history
# Sourced by .zshrc / .bashrc

# Function to suggest aliases (called at shell startup)
suggest_aliases() {
    # Skip if not interactive terminal
    [[ ! -t 0 ]] && return

    # Skip if disabled by user
    [[ -n "$ALIAS_SUGGEST_DISABLE" ]] && return

    # Rate limiting: check timestamp file
    local cache_file="$HOME/.cache/alias-suggest-last-run"
    local force="${ALIAS_SUGGEST_FORCE:-}"

    if [[ -z "$force" && -f "$cache_file" ]]; then
        local last_run now elapsed
        # macOS uses -f %m, Linux uses -c %Y
        last_run=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        now=$(date +%s)
        elapsed=$((now - last_run))
        if [[ $elapsed -lt 3600 ]]; then  # 3600 seconds = 1 hour
            return
        fi
    fi

    # Define alias mappings: "long command" -> "short alias"
    # Using parallel arrays for POSIX compatibility
    local patterns=(
        # Git status and diff
        "git status"
        "git diff --staged"
        "git diff"
        # Git add
        "git add --all"
        "git add"
        # Git commit
        "git commit --amend"
        "git commit -m"
        "git commit -s -m"
        "git commit"
        # Git push/pull
        "git push --force-with-lease"
        "git push"
        "git pull"
        # Git branch
        "git checkout -b"
        "git checkout"
        "git switch -c"
        "git switch"
        "git branch"
        # Navigation
        "cd ../../.."
        "cd ../.."
        "cd .."
        # Utils
        "clear"
        "history"
    )

    local suggestions=(
        # Git status and diff
        "gs"
        "gds"
        "gd"
        # Git add
        "gaa"
        "ga"
        # Git commit
        "gca"
        "gcmsg"
        "gcs"
        "gc"
        # Git push/pull
        "gpf"
        "gp"
        "gl"
        # Git branch
        "gcb"
        "gco"
        "gswc"
        "gsw"
        "gb"
        # Navigation
        "...."
        "..."
        ".."
        # Utils
        "c"
        "h"
    )

    # Get recent history (last 100 commands)
    local history_content
    if [[ -n "$ZSH_VERSION" ]]; then
        # Zsh: use fc, strip leading whitespace and command numbers
        history_content=$(fc -ln -100 2>/dev/null | sed 's/^[[:space:]]*//')
    elif [[ -n "$BASH_VERSION" ]]; then
        # Bash: fc requires history to be loaded in interactive shell
        # Fall back to history file if fc fails
        history_content=$(fc -ln -100 2>/dev/null | sed 's/^[[:space:]]*//')
        if [[ -z "$history_content" && -f "$HOME/.bash_history" ]]; then
            history_content=$(tail -100 "$HOME/.bash_history" 2>/dev/null)
        fi
    else
        return
    fi

    [[ -z "$history_content" ]] && return

    # Find matches
    local found=()
    local found_count=0
    local max_suggestions=5
    local i

    for i in "${!patterns[@]}"; do
        [[ $found_count -ge $max_suggestions ]] && break

        local pattern="${patterns[$i]}"
        local suggestion="${suggestions[$i]}"

        # Check if pattern appears in history (as command start)
        if echo "$history_content" | grep -q "^${pattern}"; then
            # Skip if already suggested (dedup)
            local already_found=0
            for f in "${found[@]}"; do
                if [[ "$f" == "$suggestion" ]]; then
                    already_found=1
                    break
                fi
            done

            if [[ $already_found -eq 0 ]]; then
                found+=("$pattern|$suggestion")
                ((found_count++))
            fi
        fi
    done

    # Print suggestions if any found
    if [[ ${#found[@]} -gt 0 ]]; then
        echo ""
        printf '\033[1;33m💡 Alias suggestions based on recent history:\033[0m\n'
        for item in "${found[@]}"; do
            local cmd="${item%|*}"
            local alias="${item#*|}"
            printf '   \033[0;37m%s\033[0m → \033[1;32m%s\033[0m\n' "$cmd" "$alias"
        done
        echo ""
    fi

    # Update timestamp
    mkdir -p "$(dirname "$cache_file")"
    touch "$cache_file"
}

# Auto-run on source
suggest_aliases
