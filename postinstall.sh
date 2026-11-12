#!/bin/bash
# postinstall.sh — re-runnable config setup for the jwmarb dotfiles.
#
# Options:
#   -y, --yes      Accept the default answer for every prompt (non-interactive)
#   -n, --dry-run  Print system commands instead of running them
#
# System-mutating commands go through run(); files under $HOME are written
# even in a dry run. Existing configs are backed up to $BACKUP_DIR before
# being replaced.

set -uo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)}"
DOTFILES_DIR=$(cd "$DOTFILES_DIR" && pwd -P)
[[ -f $DOTFILES_DIR/.config/hypr/hyprland.lua ]] || { echo "not a dotfiles dir: $DOTFILES_DIR" >&2; exit 1; }
# shellcheck source=.setup-lib
# .setup-lib is required: without it this script dies on unbound variables
# half-way through. A failed source must be fatal (no set -e, so a bare
# source would be silently ignored).
source "$DOTFILES_DIR/.setup-lib" || {
  echo "error: missing $DOTFILES_DIR/.setup-lib (incomplete dotfiles tree; re-run install.sh to re-fetch it)" >&2
  exit 1
}
export DOTFILES_DIR

# Optional: pi coding agent config (extensions, agents, skills) — jwmarb/dotpi
setup_pi_config() {
  if ask_yn "Would you like to install the pi config (jwmarb/dotpi)?" n n; then
    if command -v pi &> /dev/null; then
      if [[ -d "$HOME/.pi/.git" ]]; then
        info "Updating existing pi config..."
        run git -C "$HOME/.pi" pull --ff-only
      elif [[ -e "$HOME/.pi" ]]; then
        warn "Refusing to touch existing $HOME/.pi (not a git repo)."
      else
        info "Cloning pi config into ~/.pi..."
        run git clone --depth 1 https://github.com/jwmarb/dotpi.git "$HOME/.pi"
      fi
      if [[ -f "$HOME/.pi/agent/.env.example" && ! -f "$HOME/.pi/agent/.env" ]]; then
        cp "$HOME/.pi/agent/.env.example" "$HOME/.pi/agent/.env"
        info "Edit $HOME/.pi/agent/.env and add your LITELLM keys."
      fi
    else
      warn "pi not found on PATH — skipping pi config."
    fi
  else
    info "Skipping pi config."
  fi
}

# Fix hyprlock PAM config so password auth works out of the box.
# The default config includes system-auth which uses pam_faillock,
# causing password rejection after a few failed attempts.
setup_pam() {
  if [[ ! -f /etc/pam.d/hyprlock ]] || grep -q "include.*login" /etc/pam.d/hyprlock; then
    info "Configuring PAM for hyprlock..."
    run sudo tee /etc/pam.d/hyprlock >/dev/null <<'EOF'
#%PAM-1.0

auth      required  pam_unix.so try_first_pass nullok
auth      optional  pam_permit.so
auth      required  pam_env.so

account   required  pam_unix.so
account   optional  pam_permit.so

password  required  pam_unix.so try_first_pass nullok shadow

session   required  pam_unix.so
session   optional  pam_permit.so
EOF
  fi
}

# Reset any existing faillock lockout for the current user
reset_faillock() {
  if command -v faillock &>/dev/null; then
    if [[ $DRY_RUN -eq 1 ]]; then
      # Dry run: nothing executes, so there is nothing to silence — the
      # [dry-run] notice (stderr) must stay visible.
      run sudo faillock --user "${USER:-$(id -un)}" --reset
    else
      # Real run: silence faillock's own stderr (e.g. "no entries"); the
      # redirect only covers the command, not run's notice.
      run sudo faillock --user "${USER:-$(id -un)}" --reset 2>/dev/null
    fi
  fi
}

copy_wallpapers() {
  mkdir -p "$HOME/.config" "$HOME/wallpapers"
  cp -r --update=none "$DOTFILES_DIR/wallpapers/." "$HOME/wallpapers/"
}

run_setup_scripts() {
  bash "$DOTFILES_DIR/.setup-sddm"
  bash "$DOTFILES_DIR/.setup-wal"
  bash "$DOTFILES_DIR/.setup-gtk"
}

setup_bashrc() {
  touch "$HOME/.bashrc"
  if ! grep -qF 'eval $(starship init bash)' "$HOME/.bashrc"; then
    echo 'eval $(starship init bash)' >> "$HOME/.bashrc"
  fi
  if ! grep -qF 'pokemon-colorscripts -r' "$HOME/.bashrc"; then
    echo 'pokemon-colorscripts -r' >> "$HOME/.bashrc"
  fi
}

link_configs() {
  local src dest
  for src in "$DOTFILES_DIR"/.config/*; do
    dest="$HOME/.config/${src##*/}"
    if [[ -L $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      continue
    fi
    # If the backup fails (e.g. $BACKUP_DIR is not writable), skip this entry
    # instead of linking over the existing file/dir.
    backup_path "$dest" || { warn "skipping $dest (could not back it up first)"; continue; }
    # -n: if $dest is a symlink to a directory, replace the link itself
    # instead of creating the link inside it.
    if ! ln -sn "$src" "$dest"; then
      warn "could not link $dest -> $src; if a previous copy existed it is in $BACKUP_DIR"
    fi
  done
}

setup_hyprlock_media() {
  if ask_yn "Would you like to add your github and linkedin to display on hyprlock?" n n; then
    local github linkedin
    github=$(ask_line "Enter your github username (required): " "")
    linkedin=$(ask_line "Enter your LinkedIn name (required): " "")
    if [[ -z $github || -z $linkedin ]]; then
      warn "Both GitHub username and LinkedIn name are required. Skipping."
    else
      # ~/.config/hypr is a symlink, so this writes the tracked file
      # $DOTFILES_DIR/.config/hypr/hyprlock-media
      echo " $github   $linkedin" > "$HOME/.config/hypr/hyprlock-media"
      info "Information added successfully."
    fi
  else
    info "Skipping GitHub and LinkedIn information."
  fi
  echo "Note: If you wish to change your information later, you can edit the contents of $HOME/.config/hypr/hyprlock-media"
}

apply_initial_wallpaper() {
  local selected_wallpaper="$HOME/wallpapers/walls/mountains.jpg"
  if [[ $DRY_RUN -eq 1 ]]; then
    info "[dry-run] would source $DOTFILES_DIR/.config/hypr/wallpaper.sh and run use_wallpaper $selected_wallpaper (wal, awww, hyprctl, pywalfox, writes to /usr/share/sddm)"
  else
    # wallpaper.sh evals its color template and sources colors.sh, which
    # need set +u; run it isolated in a subshell.
    ( set +u; source "$DOTFILES_DIR/.config/hypr/wallpaper.sh" && use_wallpaper "$selected_wallpaper" ) || warn "initial wallpaper failed; run ALT+w after login"
  fi
}

finish() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Dry run complete: system commands were printed, not run; files under $HOME were written."
  else
    echo "jwmarb's Dotfiles successfully installed."
  fi
  if [[ -d $BACKUP_DIR ]]; then
    echo "Previous configs were backed up to $BACKUP_DIR"
  fi
  if [[ -z ${DISPLAY:-} ]]; then
    if ask_yn "Would you like to restart your pc now?" y n; then
      run sudo reboot
    fi
  elif [[ -n ${XDG_SESSION_TYPE:-} ]]; then
    echo "Installation updated. Since you are already running on a graphical environment, some changes may not be fully reflected until reboot."
  fi
}

main() {
  parse_args "$@"
  [[ $EUID -eq 0 ]] && die "Do not run as root"
  require_tty_or_yes
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: system commands are printed, not run; files under $HOME ARE written" >&2
  fi
  setup_pi_config
  setup_pam
  reset_faillock
  copy_wallpapers
  run_setup_scripts
  setup_bashrc
  link_configs
  setup_hyprlock_media
  apply_initial_wallpaper
  finish
}
main "$@"
