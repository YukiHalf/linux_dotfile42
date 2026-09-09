export PATH="$HOME/.local/bin:$PATH"

# mise-managed CLI tools
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

autoload -Uz compinit
compinit

# Vim-style command-line editing in zsh.
# Esc enters normal mode; i/a/etc. return to insert mode.
bindkey -v
export KEYTIMEOUT=10

# Keep familiar history search available in vi insert mode.
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Existing NVM install, if present
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Minimal aliases
alias s='git status --short --branch'
alias valgod='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'
alias zj='zellij'

croot() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "Not inside a Git repository."
        return 1
    }
    cd "$root" || return
}

check42() {
    echo "=== Git ==="
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git status --short --branch
    else
        echo "Not inside a Git repository."
    fi

    if command -v norminette >/dev/null 2>&1; then
        echo
        echo "=== Norminette ==="
        norminette
    fi
}

# Exit Yazi into the directory you navigated to.
y() {
    local tmp cwd
    tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
    command rm -f -- "$tmp"
}

[ -f "$HOME/.config/zsh/rice.zsh" ] && source "$HOME/.config/zsh/rice.zsh"

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
