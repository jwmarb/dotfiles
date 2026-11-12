# AGENTS.md - jwmarb Dotfiles

## Overview
Arch Linux dotfiles with Hyprland WM. Config lives in `.config/` and is symlinked to `~/.config/` during installation. Uses Wal (pywal) for dynamic theming across all components.

## Repository Structure
```
.config/          # All config files (symlinked to ~/.config/)
  hypr/           # Hyprland WM, Hyprlock, wallpaper scripts
  waybar/         # Status bar (config, CSS, themes, scripts)
  kitty/          # Terminal emulator
  wofi/           # Application launcher (config + CSS styles)
  mako/           # Notification daemon
  swaync/         # Notification center
  sddm/           # Display manager theme configs
  gtk-{3,4}/      # GTK theming
  starship.toml   # Shell prompt
install.sh        # One-liner bootstrap: guards, fetch, packages (paru), then runs postinstall.sh
postinstall.sh    # Re-runnable config setup: backups+symlinks, PAM, SDDM, wal, GTK
.setup-lib        # Required shared helpers (run/ask/backup); sourced by postinstall.sh, .setup-sddm, .setup-gtk
.setup-sddm       # SDDM config + theme install (sources .setup-lib)
.setup-wal        # Static wal color fallbacks (standalone; does NOT source .setup-lib)
.setup-gtk        # GTK2 theme + dark portal color-scheme (sources .setup-lib)
```

## Commands
- **Install**: `curl -fsSL https://raw.githubusercontent.com/jwmarb/dotfiles/main/install.sh | bash`. Non-interactive: `… | bash -s -- --yes`. From a checkout: `./install.sh [--yes] [--dry-run]`.
- **Target dir**: `DOTFILES_DIR` (default `~/dotfiles`). A clone of jwmarb/dotfiles is updated with `git pull --ff-only origin <DOTFILES_BRANCH>`; a dir that isn't ours is refused. The tarball fallback (no git) writes a `.dotfiles-source` marker file into the dir; a re-run over a marked dir converts it to a git clone when git is available, or re-extracts the tarball. Either way the new tree is built in a sibling temp dir first, and only after that succeeds is the old tree moved to `$DOTFILES_DIR.old-<epoch>` (location printed), so a failed fetch never leaves `DOTFILES_DIR` missing, local edits survive, and upstream-deleted files disappear.
- **Re-run config only**: `~/dotfiles/postinstall.sh [--yes] [--dry-run]`.
- **Backups**: existing entries in `~/.config` and `~/.gtkrc-2.0` are backed up to `~/.config-backup-<YYYYmmdd-HHMMSS>/` before replacement; a failed backup aborts that replacement, and name collisions get a numeric suffix (`.1`, `.2`, …). System files are NOT backed up: `.setup-sddm` replaces `/etc/sddm.conf`, `/etc/sddm.conf.d/virtualkbd.conf` and theme files, and `postinstall.sh` rewrites `/etc/pam.d/hyprlock`. A tarball-install tree refresh is a separate thing: the whole old `DOTFILES_DIR` becomes `DOTFILES_DIR.old-<epoch>`.
- **Dry run**: `--dry-run` / `DRY_RUN=1` prints the system commands instead of running them. Files under `$HOME` are still written, and the fetch really runs: it can clone into `DOTFILES_DIR`, or move an existing install aside to `.old-<epoch>`.
- **Testing the installer**: run only `--dry-run` with `HOME=$(mktemp -d)` and `DOTFILES_DIR` inside it. To test unpushed changes, override **both** `DOTFILES_REPO=file://…` and `DOTFILES_TARBALL=file://…` (with git on PATH the installer clones `DOTFILES_REPO`, even if only the tarball is overridden), or run with a git-less `PATH` to force the tarball path.
- **No build/lint/test** - configs validated by reloading components:
  - Hyprland: `hyprctl reload`
  - Waybar: `killall waybar && waybar` (or ALT+a to refresh)
  - Mako: `makoctl reload`
  - Wal colors: `wal -i <image>`

## Config File Formats
| Component | Format | Location |
|-----------|--------|----------|
| Hyprland | Lua (`hl.*` API, Hyprland ≥ 0.57) | `.config/hypr/hyprland.lua` |
| Hyprlock | `.conf` | `.config/hypr/hyprlock.conf` |
| Waybar | JSON + CSS | `.config/waybar/config` + `style.css` |
| Wofi | INI + CSS | `.config/wofi/config` + `style.css` |
| Kitty | `.conf` | `.config/kitty/kitty.conf` |
| Mako | INI-like | `.config/mako/config` |
| SwayNC | JSON + CSS | `.config/swaync/config.json` + `style.css` |
| Starship | TOML | `.config/starship.toml` |

## Code Style Guidelines

### Shell Scripts
- Shebang: `#!/bin/bash`
- Variables: UPPER_CASE for config paths, lowercase for locals
- Prefer `[[ ]]` over `[ ]` for conditionals
- Quote all variable expansions: `"$var"`
- Use `local` for function-scoped variables
- Trap cleanup: `trap 'rm -rf "$TMP_DIR"' EXIT`
- Error handling: `set -uo pipefail` plus explicit checks; no `set -e`; every system-mutating command goes through `run`
- Source wal colors: `source ~/.cache/wal/colors.sh` before using color vars

### Hyprland Config
- Hyprland config is Lua (`hyprland.lua`), not `$var` / `bind =`.
- Main modifier: `local mainMod = "SUPER"`.
- Keybinds use the `bind(...)` / `exec(...)` helpers (`hyprland.lua:211–217`), e.g. `bind("ALT + Tab", hl.dsp.focus({ workspace = "previous" }))` or `bind("XF86AudioNext", exec("playerctl next"), { locked = true })`.
- Autostart goes inside `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)`.
- Wal colors are read by `load_wal_colors` from `~/.cache/wal/colors-hyprland`, whose `$name = value` lines `hyprlock.conf` still `source`s.
- The legacy `hyprland.conf` is unused.

### CSS (Waybar, Wofi, Wlogout)
- Import wal colors: `@import url('../../.cache/wal/colors-waybar.css')`
- Wal color vars: `@background`, `@foreground`, `@color1`-`@color15`
- Font: `"FiraCode Nerd Font Mono"` (Nerd icons required for status bar)
- Use `alpha(@color, 0.X)` for transparency
- Reset with `all: unset` before styling

### JSON (Waybar, SwayNC)
- 2-space indentation
- Trailing commas not used
- Icons use Nerd Font glyphs (e.g., ``, `󰂯`, ``)

## Wal (Pywal) Color System
Colors generated to `~/.cache/wal/`:
- `colors.sh` - Shell variables (`$color0`-`$color15`, `$background`, `$foreground`)
- `colors-hyprland` - Hyprland format (`$color0 = 0xffXXXXXX`)
- `colors-waybar.css` - CSS variables (`@color0`-`@color15`)
- `colors-kitty.conf` - Kitty terminal colors
- Scripts source colors before using them; wallpaper changes trigger full theme update
- **Brand**: the jwmarb brand kit lives in `~/jwmarb` (read its `AGENTS.md` first). It does **not** replace Wal here: desktop colours stay generated per wallpaper, and the brand's only fixed element on the desktop is the accent `#23ce6b`. Do not pin this palette to the brand tokens.

## Key Patterns
- **Config symlinking**: `postinstall.sh` backs up existing configs to `~/.config-backup-*`, then symlinks; it skips links that are already correct
- **Laptop detection**: `pkgs-laptop.list` for optional laptop packages (tlp, blueman)
- **Browser selection**: Interactive menu in `install.sh` (firefox, zen, chromium, etc.)
- **Wallpaper flow**: `wallpaper.sh` -> wal -> awww -> pywalfox -> mako -> kitty -> sddm
- **Hyprlock PAM**: `postinstall.sh` creates `/etc/pam.d/hyprlock` to avoid faillock issues

## Git Conventions
- **Conventional Commits**: `type(scope): description`
- Types: `feat`, `fix`, `style`, `chore`, `refactor`
- Scopes: `hypr`, `waybar`, `hyprlock`, `swaync`, `kitty`, or empty for cross-cutting
- Examples: `fix(hypr): prevent duplicate waybar instances`, `feat(waybar): add dynamic multi-monitor workspace detection`

## Common Modifications
- **Add keybind**: Edit the KEYBINDINGS section (`bind(...)`) in `.config/hypr/hyprland.lua`
- **Change wallpaper**: `ALT+w` or run `.config/hypr/wallpaper.sh`
- **Add autostart**: `hl.exec_cmd("command")` inside the `hl.on("hyprland.start", …)` block in the AUTOSTART section of `hyprland.lua`
- **Modify waybar modules**: Edit `config` JSON and `style.css`
- **Change colors**: Run `wal -i <image>` or edit `.setup-wal` defaults
