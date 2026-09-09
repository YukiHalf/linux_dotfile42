#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

need() {
    command -v "$1" >/dev/null 2>&1 || {
        warn "Missing required command: $1"
        return 1
    }
}

backup_path() {
    local path="$1"
    if [[ -e "$path" || -L "$path" ]]; then
        if [[ -L "$path" && "$(readlink -f "$path" 2>/dev/null || true)" == "$(readlink -f "$2" 2>/dev/null || true)" ]]; then
            return 0
        fi
        mv "$path" "$path.backup.$TS"
        info "Backed up $path"
    fi
}

link_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" && "$(readlink -f "$dst" 2>/dev/null || true)" == "$(readlink -f "$src" 2>/dev/null || true)" ]]; then
        return 0
    fi

    backup_path "$dst" "$src"
    ln -s "$src" "$dst"
}

for cmd in curl git zsh python3; do
    need "$cmd" || exit 1
done

mkdir -p "$HOME/.local/bin" "$HOME/.local/src" "$HOME/.config"
export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# mise + CLI tools (all user-local, no sudo)
# -----------------------------------------------------------------------------
info "Installing/updating mise"
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
    curl -fsSL https://mise.run | sh
fi
MISE="$HOME/.local/bin/mise"

info "Installing terminal tools"
"$MISE" use --global \
    starship@latest \
    zoxide@latest \
    fzf@latest \
    ripgrep@latest \
    fd@latest \
    bat@latest \
    eza@latest \
    zellij@latest

# Avoid the glibc-linked Yazi package that failed on this Ubuntu machine.
"$MISE" unuse --global yazi >/dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Yazi musl build — avoids requiring a newer system glibc
# -----------------------------------------------------------------------------
install_yazi_musl() {
    local machine asset_dir tmp zip
    machine="$(uname -m)"

    case "$machine" in
        x86_64|amd64)
            asset_dir="yazi-x86_64-unknown-linux-musl"
            ;;
        aarch64|arm64)
            asset_dir="yazi-aarch64-unknown-linux-musl"
            ;;
        *)
            warn "Unsupported architecture for automatic Yazi musl install: $machine"
            return 0
            ;;
    esac

    tmp="$(mktemp -d)"
    zip="$tmp/yazi.zip"
    info "Installing Yazi musl build"
    curl -fL "https://github.com/sxyazi/yazi/releases/latest/download/${asset_dir}.zip" -o "$zip"
    python3 -m zipfile -e "$zip" "$tmp"

    cp "$tmp/$asset_dir/yazi" "$HOME/.local/bin/yazi"
    cp "$tmp/$asset_dir/ya" "$HOME/.local/bin/ya"
    chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"
    rm -rf "$tmp"
}
install_yazi_musl

# -----------------------------------------------------------------------------
# Tracked dotfiles
# -----------------------------------------------------------------------------
info "Linking tracked configuration"
link_file "$ROOT/zshrc" "$HOME/.zshrc"
link_file "$ROOT/config/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$ROOT/config/starship.toml" "$HOME/.config/starship.toml"
link_file "$ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
link_file "$ROOT/config/zsh/rice.zsh" "$HOME/.config/zsh/rice.zsh"
link_file "$ROOT/config/bat/config" "$HOME/.config/bat/config"

# -----------------------------------------------------------------------------
# Catppuccin theme assets
# These are deterministic upstream files; fetch them during bootstrap rather
# than duplicating thousands of lines in this repo.
# -----------------------------------------------------------------------------
info "Installing Catppuccin theme assets"
mkdir -p "$HOME/.config/yazi" "$HOME/.config/eza" "$HOME/.config/bat/themes"

curl -fsSL \
  'https://raw.githubusercontent.com/catppuccin/yazi/main/themes/mocha/catppuccin-mocha-mauve.toml' \
  -o "$HOME/.config/yazi/theme.toml"

curl -fsSL \
  'https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme' \
  -o "$HOME/.config/yazi/Catppuccin-mocha.tmTheme"

curl -fsSL \
  'https://raw.githubusercontent.com/catppuccin/eza/main/themes/mocha/catppuccin-mocha-mauve.yml' \
  -o "$HOME/.config/eza/theme.yml"

curl -fsSL \
  'https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme' \
  -o "$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme"

if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 || true
fi

# -----------------------------------------------------------------------------
# PaperWM
# GNOME 42-44 use the legacy gnome-44 branch; newer GNOME uses release.
# -----------------------------------------------------------------------------
install_paperwm() {
    if ! command -v gnome-shell >/dev/null 2>&1; then
        warn "GNOME Shell not detected; skipping PaperWM"
        return 0
    fi

    local major branch dir
    major="$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)"

    if [[ -z "$major" ]]; then
        warn "Could not determine GNOME Shell version; skipping PaperWM"
        return 0
    elif (( major >= 42 && major <= 44 )); then
        branch="gnome-44"
    elif (( major >= 45 )); then
        branch="release"
    else
        warn "GNOME $major is older than this bootstrap supports for PaperWM"
        return 0
    fi

    dir="$HOME/.local/src/PaperWM"
    info "Installing PaperWM for GNOME $major ($branch branch)"

    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" fetch --depth 1 origin "$branch"
        git -C "$dir" checkout -q "$branch"
        git -C "$dir" reset --hard "origin/$branch"
    else
        rm -rf "$dir"
        git clone --depth 1 --branch "$branch" https://github.com/paperwm/PaperWM.git "$dir"
    fi

    # Avoid window-management conflicts from our previous Tiling Shell setup.
    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions disable tilingshell@ferrarodomenico.com >/dev/null 2>&1 || true
    fi

    "$dir/install.sh"

    if [[ -s "$ROOT/gnome/paperwm.dconf" ]]; then
        info "Restoring saved PaperWM settings"
        dconf load /org/gnome/shell/extensions/paperwm/ < "$ROOT/gnome/paperwm.dconf" || true
    fi

    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions enable paperwm@paperwm.github.com >/dev/null 2>&1 || true
    fi
}
install_paperwm

info "Done"
printf '\nReload the shell with:\n  exec zsh\n\n'
printf 'If PaperWM was newly installed on Wayland, log out/in once, then run:\n'
printf '  gnome-extensions enable paperwm@paperwm.github.com\n\n'
printf 'Ghostty is configured but not installed by this script; on this machine it was already provided.\n'
