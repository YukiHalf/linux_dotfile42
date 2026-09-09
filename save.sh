#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PaperWM stores its settings and shortcuts in dconf.
if command -v dconf >/dev/null 2>&1; then
    mkdir -p "$ROOT/gnome"
    dconf dump /org/gnome/shell/extensions/paperwm/ > "$ROOT/gnome/paperwm.dconf"
    echo "Saved PaperWM settings -> gnome/paperwm.dconf"
else
    echo "dconf not available; PaperWM settings were not saved." >&2
fi

echo
echo "Tracked dotfile configs are symlinked into this repo, so edits are already here."
echo "Review with: git status"
