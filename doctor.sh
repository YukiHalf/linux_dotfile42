#!/usr/bin/env bash
set -u

printf '%-12s %s\n' 'tool' 'status'
printf '%-12s %s\n' '------------' '------------------------------'
for cmd in ghostty zsh starship zoxide fzf rg fd bat eza zellij yazi ya valgrind git; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ver="$($cmd --version 2>/dev/null | head -n1)"
        printf '%-12s %s\n' "$cmd" "${ver:-installed}"
    else
        printf '%-12s %s\n' "$cmd" 'MISSING'
    fi
done

if command -v gnome-shell >/dev/null 2>&1; then
    echo
    gnome-shell --version
fi

if command -v gnome-extensions >/dev/null 2>&1; then
    echo
    gnome-extensions info paperwm@paperwm.github.com 2>/dev/null || echo 'PaperWM not visible to GNOME yet'
fi
