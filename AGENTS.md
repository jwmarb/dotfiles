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
install.sh        # Package installation (paru/pacman)
postinstall.sh    # Symlinks, PAM, SDDM, wal, GTK setup
.setup-*          # Setup scripts (SDDM, wal, GTK)
```

## Commands
- **Install**: `./install.sh` (interactive, installs packages via paru)
- **Post-install**: `./postinstall.sh` (symlinks configs, sets up PAM/SDDM/wal)
- **No build/lint/test** - configs validated by reloading components:
  - Hyprland: `hyprctl reload`
  - Waybar: `killall waybar && waybar` (or ALT+a to refresh)
  - Mako: `makoctl reload`
  - Wal colors: `wal -i <image>`

## Config File Formats
| Component | Format | Location |
|-----------|--------|----------|
| Hyprland | `.conf` (key-value, sections) | `.config/hypr/hyprland.conf` |
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
- Error handling: `set -e` not used; explicit checks preferred
- Source wal colors: `source ~/.cache/wal/colors.sh` before using color vars

### Hyprland Config
- Variables: `$varName = value` (prefix with `$`)
- Sections: `sectionName { key = value }`
- Keybinds: `bind = $mainMod, KEY, exec, command`
- Source external: `source = ~/.cache/wal/colors-hyprland`
- Main modifier: `$mainMod = SUPER`

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

## Key Patterns
- **Config symlinking**: `postinstall.sh` removes existing configs and symlinks `.config/*` to `~/.config/`
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
- **Add keybind**: Edit `.config/hypr/hyprland.conf` in KEYBINDINGS section
- **Change wallpaper**: `ALT+w` or run `.config/hypr/wallpaper.sh`
- **Add autostart**: `exec-once = command` in hyprland.conf AUTOSTART section
- **Modify waybar modules**: Edit `config` JSON and `style.css`
- **Change colors**: Run `wal -i <image>` or edit `.setup-wal` defaults
