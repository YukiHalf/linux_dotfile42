# Minimal Ubuntu dotfiles

A no-sudo bootstrap for the terminal/desktop setup built on Ubuntu GNOME.

## What it restores

- Zsh configuration
- mise user-level tool manager
- Starship
- zoxide
- fzf
- ripgrep (`rg`)
- fd
- bat
- eza
- Zellij (optional; Yazi image previews are better directly in Ghostty)
- Yazi using the musl binary to avoid old-glibc problems
- Catppuccin Mocha + mauve rice
- Ghostty configuration and ergonomic clipboard bindings
- PaperWM
- PaperWM dconf settings once saved with `./save.sh`

Ghostty itself is not installed here because it was already provided by the Ubuntu environment and installing Ghostty without admin access is distro-specific.

## Fresh-machine restore

After creating/pushing this repository to GitHub:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
```

On a GNOME Wayland machine, a newly installed PaperWM extension may require one logout/login before GNOME loads it.

## First push to GitHub

Create an empty repository called `dotfiles`, then from this directory:

```bash
git init
git add .
git commit -m "initial dotfiles"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git push -u origin main
```

## Save current PaperWM changes

Whenever you change PaperWM settings or shortcuts:

```bash
cd ~/.dotfiles
./save.sh
git add .
git commit -m "update desktop config"
git push
```

The ordinary terminal configuration files are symlinked from this repo, so editing `~/.zshrc`, Ghostty, Starship, Zellij, etc. edits the tracked file directly.

## Check the installation

```bash
~/.dotfiles/doctor.sh
```

## Useful commands

- `s` — compact Git status
- `z <name>` — jump to frequently used directory
- `zi` — fuzzy directory selector
- `rg text` — recursive text search
- `fd name` — file search
- `bat file.c` — syntax-highlighted file view
- `ll` — detailed eza listing
- `lt` — two-level tree
- `y` — Yazi, returning the shell to the directory you exit from
- `zj` — Zellij
- `valgod ./program` — Valgrind with full leak/origin flags
- `croot` — jump to current Git repository root
- `check42` — Git + Norminette check

## Vim-style navigation

This setup intentionally uses Vim-like navigation wherever it fits naturally:

- **Zsh:** `Esc` enters vi normal mode; use `h/j/k/l`, `w/b`, `0/$`, etc. while editing commands.
- **PaperWM:** `Super+h/j/k/l` focuses windows; `Super+Shift+h/j/k/l` moves windows; `Super+Ctrl+j/k` changes workspace.
- **Yazi:** already uses native Vim-style `h/j/k/l` navigation.
- **fzf:** `Ctrl+j` / `Ctrl+k` move through results (fzf defaults).
- **VS Code:** VSCodeVim provides normal Vim motions; `jj` exits Insert mode. `Alt+h/j/k/l` focuses editor groups and `Alt+Shift+h/j/k/l` moves them.
- **Browser:** install the Vimium extension manually. Browser stores do not provide a clean portable dotfiles-style installation path. Vimium defaults include `h/j/k/l`, `gg`, `G`, `/`, `f`, `F`, etc.

### VS Code

The bootstrap installs these extensions when the `code` CLI exists:

- `vscodevim.vim`
- `Catppuccin.catppuccin-vsc`
- `Catppuccin.catppuccin-vsc-icons`

VS Code is configured for Catppuccin Mocha, mauve accent, minimal workbench styling, relative line numbers, no minimap, and Vim editing.
