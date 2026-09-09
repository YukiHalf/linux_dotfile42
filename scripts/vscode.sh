#!/usr/bin/env bash
set -Eeuo pipefail

VIMCODE_REPO="https://github.com/wojukasz/VimCode.git"
TMP_DIR="$(mktemp -d)"
CODE_DIR="$HOME/.config/Code/User"
STAMP="$(date +%Y%m%d-%H%M%S)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$CODE_DIR"

echo "==> Backing up current VS Code config"
[ -f "$CODE_DIR/settings.json" ] && cp "$CODE_DIR/settings.json" "$CODE_DIR/settings.json.bak.$STAMP"
[ -f "$CODE_DIR/keybindings.json" ] && cp "$CODE_DIR/keybindings.json" "$CODE_DIR/keybindings.json.bak.$STAMP"

echo "==> Fetching current VimCode/LazyVim config"
git clone --depth 1 "$VIMCODE_REPO" "$TMP_DIR/VimCode" >/dev/null

# Use VimCode's keybindings EXACTLY. No custom Alt+h/j/k/l layer.
cp "$TMP_DIR/VimCode/config/keybindings.json" "$CODE_DIR/keybindings.json"

echo "==> Merging VimCode settings with your Catppuccin rice"
python3 - "$TMP_DIR/VimCode/config/settings.json" "$CODE_DIR/settings.json" <<'PY'
import json
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

text = src.read_text()

# Strip // and /* */ comments while preserving strings.
out = []
i = 0
in_string = False
escape = False
while i < len(text):
    c = text[i]
    if in_string:
        out.append(c)
        if escape:
            escape = False
        elif c == "\\":
            escape = True
        elif c == '"':
            in_string = False
        i += 1
        continue

    if c == '"':
        in_string = True
        out.append(c)
        i += 1
        continue

    if c == "/" and i + 1 < len(text) and text[i + 1] == "/":
        i += 2
        while i < len(text) and text[i] not in "\r\n":
            i += 1
        continue

    if c == "/" and i + 1 < len(text) and text[i + 1] == "*":
        i += 2
        while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
            i += 1
        i += 2
        continue

    out.append(c)
    i += 1

clean = "".join(out)
# Remove trailing commas before } or ].
clean = re.sub(r",(\s*[}\]])", r"\1", clean)

cfg = json.loads(clean)

# -----------------------------------------------------------------
# Preserve YOUR visual rice / personal VS Code preferences.
# Navigation and Vim behavior remain upstream VimCode.
# -----------------------------------------------------------------
overlay = {
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "catppuccin.accentColor": "mauve",
    "catppuccin.workbenchMode": "minimal",
    "catppuccin.bracketMode": "dimmed",
    "catppuccin.italicKeywords": False,
    "catppuccin.boldKeywords": False,

    "editor.semanticHighlighting.enabled": True,
    "terminal.integrated.minimumContrastRatio": 1,
    "window.titleBarStyle": "custom",
    "window.commandCenter": False,
    "workbench.layoutControl.enabled": False,
    "window.menuBarVisibility": "compact",
    "workbench.startupEditor": "none",

    "editor.minimap.enabled": False,
    "breadcrumbs.enabled": False,
    "editor.lineNumbers": "relative",
    "editor.cursorBlinking": "solid",
    "editor.smoothScrolling": True,
    "editor.fontLigatures": True,
    "editor.renderWhitespace": "selection",
    "editor.guides.indentation": False,
    "editor.stickyScroll.enabled": False,
    "workbench.list.smoothScrolling": True,

    "files.autoSave": "onFocusChange",
    "chat.disableAIFeatures": True,

    # Keep your custom CSS animation hook.
    "vscode_custom_css.imports": [
        "file:///home/sdarius-/.vscode/extensions/brandonkirbyson.vscode-animations-2.0.8/dist/updateHandler.js"
    ],

    # Keep the rice Catppuccin rather than letting Vim mode recolor
    # the entire VS Code status bar.
    "vim.statusBarColorControl": False,
    "vim.searchHighlightColor": "rgba(203, 166, 247, 0.35)",
}

cfg.update(overlay)

# Preserve your 42 C formatter.
lang_c = cfg.get("[c]", {})
if not isinstance(lang_c, dict):
    lang_c = {}
lang_c["editor.defaultFormatter"] = "keyhr.42-c-format"
cfg["[c]"] = lang_c

dst.write_text(json.dumps(cfg, indent=2) + "\n")
PY

echo "==> Installing VimCode extensions"
if command -v code >/dev/null 2>&1; then
    code --install-extension vscodevim.vim
    code --install-extension VSpaceCode.whichkey
    code --install-extension eamodio.gitlens
    code --install-extension hoovercj.vscode-settings-cycler
else
    echo "WARNING: 'code' command not found; configs were installed but extensions were not."
fi

echo
echo "Done."
echo
echo "Navigation is now VimCode/LazyVim:"
echo "  Ctrl+h/j/k/l     focus splits"
echo "  Ctrl+Arrow        resize splits"
echo "  Alt+j/k           move lines"
echo "  Shift+H/L         previous/next buffer"
echo "  [d / ]d           diagnostics"
echo "  [h / ]h           git hunks"
echo "  Ctrl+/            toggle terminal"
echo "  Ctrl+;            editor <-> terminal"
echo
echo "Leader is Space:"
echo "  Space f f         find files"
echo "  Space /           search workspace"
echo "  Space c a         code action"
echo "  Space g g         git status"
echo
echo "Current upstream VimCode uses ~ to open the WhichKey popup."
echo
echo "Restart VS Code after running this."
