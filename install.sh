#!/bin/bash
# install.sh — one-liner bootstrap for the jwmarb dotfiles.
#
#   $ curl -fsSL https://raw.githubusercontent.com/jwmarb/dotfiles/main/install.sh | bash
#   $ curl -fsSL https://raw.githubusercontent.com/jwmarb/dotfiles/main/install.sh | bash -s -- --yes
#
# Options:
#   -y, --yes      Accept the default answer for every prompt (non-interactive)
#   -n, --dry-run  Print system commands instead of running them
#
# The helper functions below are an inline copy of .setup-lib: this script
# must run before the dotfiles are fetched, so it cannot source .setup-lib.
# keep in sync with .setup-lib

set -uo pipefail

: "${DRY_RUN:=0}" "${ASSUME_YES:=0}"
export DRY_RUN ASSUME_YES

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/jwmarb/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_TARBALL="${DOTFILES_TARBALL:-https://codeload.github.com/jwmarb/dotfiles/tar.gz/refs/heads/$DOTFILES_BRANCH}"
ONE_LINER="curl -fsSL https://raw.githubusercontent.com/jwmarb/dotfiles/main/install.sh | bash"

BROWSER_PKGS=()
LAPTOP_PKGS=()
FETCH=1

# --- helpers (keep in sync with .setup-lib) ---------------------------------

info() {
  printf 'info: %s\n' "$*" >&2
}

warn() {
  printf 'warn: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# run CMD [ARGS...] — run CMD, or just print it when DRY_RUN=1.
# The [dry-run] notice goes to stderr like info/warn/die, so a caller's
# >/dev/null cannot hide it.
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    {
      printf '[dry-run]'
      printf ' %q' "$@"
      printf '\n'
    } >&2
    return 0
  fi
  "$@"
}

# ask_yn PROMPT DEFAULT [YES_ANSWER]
# Prints "PROMPT [Y/n]:" (or [y/N]) and returns 0 for a yes-like answer.
# Under ASSUME_YES=1 the answer is YES_ANSWER (defaulting to DEFAULT) and a
# "PROMPT -> ANSWER (--yes)" line is logged to stderr.
ask_yn() {
  local prompt=$1 default=${2:-y}
  local yes_answer=${3:-$default}
  local ans
  if [[ $ASSUME_YES -eq 1 ]]; then
    ans=$yes_answer
    printf '%s -> %s (--yes)\n' "$prompt" "$ans" >&2
  else
    local suffix
    if [[ $default =~ ^[Yy] ]]; then suffix='[Y/n]'; else suffix='[y/N]'; fi
    ans=''
    read -r -p "$prompt $suffix: " ans </dev/tty || ans=$default
    ans=${ans:-$default}
  fi
  [[ $ans =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ask_line PROMPT YES_VALUE
# Prints "PROMPT " and echoes the answer line. Under ASSUME_YES=1 the answer
# is YES_VALUE. Log lines go to stderr so $(ask_line ...) stays clean.
ask_line() {
  local prompt=$1 yes_value=${2-}
  local ans=''
  if [[ $ASSUME_YES -eq 1 ]]; then
    ans=$yes_value
    printf '%s -> %s (--yes)\n' "$prompt" "$ans" >&2
  else
    read -r -p "$prompt " ans </dev/tty || ans=''
  fi
  printf '%s\n' "$ans"
}

# parse_args [ARGS...] — -y/--yes -> ASSUME_YES=1, -n/--dry-run -> DRY_RUN=1,
# -h/--help -> usage + exit 0, anything else -> die "Unknown option".
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -y|--yes) ASSUME_YES=1 ;;
      -n|--dry-run) DRY_RUN=1 ;;
      -h|--help)
        cat <<EOF >&2
Usage: ${0##*/} [options]

  -y, --yes      Accept the default answer for every prompt (non-interactive)
  -n, --dry-run  Print system commands instead of running them
  -h, --help     Show this help

One-liner:        $ONE_LINER
Non-interactive:  $ONE_LINER -s -- --yes
EOF
        exit 0
        ;;
      *) die "Unknown option '$1' (see --help)" ;;
    esac
    shift
  done
  export ASSUME_YES DRY_RUN
}

require_tty_or_yes() {
  if [[ $ASSUME_YES -eq 1 ]]; then
    return 0
  fi
  if { : </dev/tty; } 2>/dev/null; then
    return 0
  fi
  die "No terminal for prompts. Re-run non-interactively with: curl -fsSL https://raw.githubusercontent.com/jwmarb/dotfiles/main/install.sh | bash -s -- --yes"
}
# DRY_RUN / ASSUME_YES may come from the environment (or from parse_args
# later). Accept only 0, 1 or empty — the :=0 defaults above already
# normalise empty. Die on anything else rather than coercing, so nobody
# ever runs for real believing it was a dry run.
for _v in DRY_RUN ASSUME_YES; do
  case ${!_v} in
    ''|0|1) ;;
    *) die "$_v must be 0 or 1 (got '${!_v}'); unset it and re-run" ;;
  esac
done

# --- fetch -------------------------------------------------------------------

check_guards() {
  [[ $EUID -ne 0 ]] || die "Do not run as root"
  command -v pacman >/dev/null 2>&1 || die "Arch Linux (pacman) required"
  require_tty_or_yes
}

resolve_dotfiles_dir() {
  local requested=${DOTFILES_DIR:-}
  local self=${BASH_SOURCE[0]:-}
  if [[ -n $self && -f $self ]]; then
    local dir
    dir=$(cd "$(dirname "$self")" && pwd -P)
    if [[ -f $dir/.config/hypr/hyprland.lua ]]; then
      if [[ -n $requested && $requested != "$dir" ]]; then
        warn "Running from inside a checkout; using $dir even though DOTFILES_DIR=$requested is set"
      fi
      DOTFILES_DIR=$dir
      FETCH=0
      return 0
    fi
  fi
  DOTFILES_DIR=${requested:-$HOME/dotfiles}
  FETCH=1
}

has_git() {
  command -v git >/dev/null 2>&1
}

is_our_clone() {
  local dir=$1 url
  [[ -d $dir/.git ]] || return 1
  has_git || return 1
  url=$(git -C "$dir" remote get-url origin 2>/dev/null) || return 1
  # Only github.com/jwmarb/dotfiles counts (https, ssh:// or scp-like git@);
  # look-alikes such as https://gitlab.com/someone/jwmarb/dotfiles.git or
  # https://evil.com/jwmarb/dotfiles.git are rejected. A test override in
  # DOTFILES_REPO (e.g. file://…) matches through the exact comparison.
  [[ $url == "$DOTFILES_REPO" || $url =~ ^(https://github\.com/|ssh://git@github\.com/|git@github\.com:)jwmarb/dotfiles(\.git)?/?$ ]]
}

# move_tree_backup DIR — move an existing dotfiles tree aside to
# DIR.old-<epoch> before re-fetching over it, so local edits are preserved
# and upstream-deleted files cannot linger. The new location is printed.
move_tree_backup() {
  local dir=$1 ts
  ts=$(date +%s)
  while [[ -e $dir.old-$ts ]]; do ts=$((ts + 1)); done
  mv "$dir" "$dir.old-$ts" || die "cannot move $dir aside (is its parent dir writable?); aborting — your tree is untouched"
  info "previous install moved to $dir.old-$ts (local edits preserved there)"
}

# ensure_git — make git available before fetching. Fresh Arch boxes ship no
# git, so a plain one-liner install would be stuck on the tarball forever;
# install it with pacman first. In a dry run the pacman call is only
# printed, so git stays absent and the caller falls back to the tarball.
# Returns 0 only when git is on PATH afterwards.
ensure_git() {
  has_git && return 0
  warn "git not found; installing it with pacman first"
  run sudo pacman -S --needed --noconfirm git
  has_git
}

# fetch_tarball DIR [refresh] — download and extract the tarball into DIR.
# Extraction happens in a sibling mktemp dir and is swapped into place only
# after success, so a failed or truncated download leaves DIR absent (fresh)
# or untouched (refresh) — never empty or half-populated.
fetch_tarball() {
  local dir=$1 refresh=${2-}
  command -v curl >/dev/null 2>&1 || die "curl is required to fetch the tarball"
  local parent tmp
  parent=$(dirname "$dir")
  mkdir -p "$parent" || die "cannot create $parent"
  tmp=$(mktemp -d "$parent/.dotfiles-tmp.XXXXXX") || die "cannot create a temp dir in $parent"
  if ! curl -fsSL "$DOTFILES_TARBALL" | tar -xz --strip-components=1 -C "$tmp"; then
    rm -rf "$tmp"
    die "tarball fetch failed ($DOTFILES_TARBALL); no partial tree was left in $dir"
  fi
  if [[ $refresh == refresh ]]; then
    # A refresh only ever happens over a previous tarball install: move the
    # old tree aside (preserving local edits) now that the new tree is
    # safely extracted.
    [[ -e $dir ]] || { rm -rf "$tmp"; die "refresh expected an existing tree at $dir"; }
    move_tree_backup "$dir"
  elif [[ -e $dir ]]; then
    # A fresh fetch may only replace an empty dir (non-empty dirs were
    # refused by fetch_dotfiles); rmdir succeeds only on empty dirs.
    rmdir "$dir" 2>/dev/null || { rm -rf "$tmp"; die "$dir exists and is not empty; move it or set DOTFILES_DIR=<other path>"; }
  fi
  mv "$tmp" "$dir" || { rm -rf "$tmp"; die "failed to move the extracted tree into $dir"; }
  printf 'tarball %s\n' "$DOTFILES_TARBALL" > "$dir/.dotfiles-source"
  info "fetched tarball ($DOTFILES_TARBALL) into $dir"
}

# clone_into_place DIR [replace] — git clone into a sibling mktemp dir and swap
# it into DIR only after the clone succeeds (same rule as fetch_tarball). With
# `replace`, the existing tree at DIR is moved aside only after a successful
# clone; without it, DIR must be absent or empty. Returns 1 (temp removed, DIR
# untouched) when the clone fails, so the caller decides how to recover.
clone_into_place() {
  local dir=$1 replace=${2-} parent tmp
  parent=$(dirname "$dir")
  mkdir -p "$parent" || die "cannot create $parent"
  tmp=$(mktemp -d "$parent/.dotfiles-clone.XXXXXX") || die "cannot create a temp dir in $parent"
  if ! git clone --depth 1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$tmp"; then
    rm -rf "$tmp"
    return 1
  fi
  if [[ $replace == replace ]]; then
    move_tree_backup "$dir"
  elif [[ -e $dir ]]; then
    rmdir "$dir" 2>/dev/null || { rm -rf "$tmp"; die "$dir exists and is not empty; move it or set DOTFILES_DIR=<other path>"; }
  fi
  mv "$tmp" "$dir" || { rm -rf "$tmp"; die "failed to move the clone into $dir"; }
}

# update_checkout DIR — pull the clone forward on our branch. On failure
# (the checkout is normally dirty — wal writes tracked files through
# ~/.config: hyprlock-media, current-theme.conf, mako config) warn with the
# exact stash/status commands and a porcelain excerpt, then continue with
# the existing checkout. Deliberately no --autostash: on a dirty checkout it
# can leave conflict markers behind.
update_checkout() {
  local dir=$1 excerpt
  if git -C "$dir" pull --ff-only origin "$DOTFILES_BRANCH"; then
    return 0
  fi
  warn "git pull --ff-only origin $DOTFILES_BRANCH failed in $dir; continuing with the existing checkout (it may be stale)."
  warn "The checkout is often dirty because wal writes tracked files through ~/.config: .config/hypr/hyprlock-media, .config/kitty/current-theme.conf, .config/mako/config."
  warn "Inspect:  git -C '$dir' status --porcelain"
  warn "If those edits are disposable (e.g. wal output), discard them, then pull:"
  warn "          git -C '$dir' checkout -- <file>   # or: git -C '$dir' checkout -- ."
  warn "          git -C '$dir' pull --ff-only origin '$DOTFILES_BRANCH'"
  warn "If you want to keep them: git -C '$dir' stash, pull as above, then git -C '$dir' stash pop and resolve any conflicts it reports."
  excerpt=$(git -C "$dir" status --porcelain 2>/dev/null | head -n 20)
  if [[ -n $excerpt ]]; then
    warn "Local changes (porcelain excerpt):"
    printf '%s\n' "$excerpt" | sed 's/^/    /' >&2
  fi
}

fetch_dotfiles() {
  [[ $FETCH -eq 1 ]] || return 0
  local t=$DOTFILES_DIR
  if is_our_clone "$t"; then
    update_checkout "$t"
  elif [[ -f $t/.dotfiles-source ]]; then
    # A previous tarball install (no .git). Prefer converting to a git clone
    # when git is available; otherwise refresh the tarball in place.
    if ensure_git; then
      info "converting tarball install to a git clone of $DOTFILES_REPO ($DOTFILES_BRANCH)"
      # Clone into a sibling temp dir FIRST; only once that succeeds is the old
      # tree moved aside and the clone swapped in. A failed clone must never
      # leave $t missing: every ~/.config/* symlink points into it.
      if ! clone_into_place "$t" replace; then
        warn "git clone failed; refreshing the tarball install instead"
        fetch_tarball "$t" refresh
      fi
    else
      warn "git unavailable; refreshing the tarball install in place"
      fetch_tarball "$t" refresh
    fi
  elif [[ -e $t && -n $(ls -A "$t" 2>/dev/null) ]]; then
    die "$t exists and is not a clone of jwmarb/dotfiles; refusing to overwrite. Move it or set DOTFILES_DIR=<other path>"
  else
    mkdir -p "$(dirname "$t")" || die "cannot create $(dirname "$t")"
    if ensure_git; then
      clone_into_place "$t" || die "git clone of $DOTFILES_REPO ($DOTFILES_BRANCH) failed; nothing was written to $t"
    else
      warn "git unavailable; using the tarball fallback"
      fetch_tarball "$t"
    fi
  fi
  # Completeness gate: the fetched tree must contain every file the rest of
  # the install depends on. .setup-lib is required — without it the scripts
  # die later with unbound variables (C1).
  local missing=()
  [[ -f $t/.config/hypr/hyprland.lua ]] || missing+=(.config/hypr/hyprland.lua)
  [[ -f $t/postinstall.sh ]] || missing+=(postinstall.sh)
  [[ -f $t/.setup-lib ]] || missing+=(.setup-lib)
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "fetched tree incomplete: missing ${missing[*]} in $t (repo: $DOTFILES_REPO, branch: $DOTFILES_BRANCH); re-run the one-liner"
  fi
  DOTFILES_DIR=$(cd "$t" && pwd -P)
}

# --- package selection ---------------------------------------------------------

choose_browser() {
  local BROWSER_OPTIONS=(firefox zen-browser-bin chromium google-chrome brave-bin opera)
  local selection
  echo "Please select a browser to install:"
  for i in "${!BROWSER_OPTIONS[@]}"; do
    echo "[$((i+1))] ${BROWSER_OPTIONS[$i]}"
  done
  echo "[0] Skip browser installation"
  selection=$(ask_line "Enter number [0-${#BROWSER_OPTIONS[@]}]: " 0)
  # Only 1..N (or 0 to skip) is accepted: reject leading zeros (09), negative
  # values and huge numbers. Force base 10 and bound the digit count so the
  # arithmetic can never overflow or go negative.
  if [[ $selection == 0 ]]; then
    info "Browser installation will be skipped."
  elif [[ $selection =~ ^[1-9][0-9]*$ ]] && (( ${#selection} <= 9 )) && (( 10#$selection <= ${#BROWSER_OPTIONS[@]} )); then
    local browser=${BROWSER_OPTIONS[$((10#$selection - 1))]}
    BROWSER_PKGS=("$browser")
    if [[ $browser == firefox || $browser == zen-browser-bin ]]; then
      BROWSER_PKGS+=(python-pywalfox)
    fi
    info "Selected browser: ${BROWSER_PKGS[*]}"
  else
    warn "Invalid browser selection '$selection'; skipping browser installation."
  fi
}

choose_laptop() {
  if ask_yn "Would you like to install packages for functionality on a laptop?" n n; then
    mapfile -t LAPTOP_PKGS < <(grep -Ev '^\s*(#|$)' "$DOTFILES_DIR/pkgs-laptop.list")
    if [[ ${#LAPTOP_PKGS[@]} -eq 0 ]]; then
      warn "you opted in to laptop packages, but pkgs-laptop.list has no entries; skipping"
    fi
  fi
}

# --- package installation --------------------------------------------------------

install_paru() {
  if command -v paru >/dev/null 2>&1; then
    info "paru is already installed, skipping..."
    return 0
  fi
  info "Installing paru..."
  run sudo pacman -S --needed --noconfirm git base-devel
  if [[ $DRY_RUN -eq 1 ]]; then
    # A dry run never builds: print the real commands with a literal
    # placeholder path (no mktemp) so the transcript is reproducible.
    local placeholder=/tmp/paru-build
    run git clone https://aur.archlinux.org/paru.git "$placeholder/paru"
    info "[dry-run] cd $placeholder/paru"
    run makepkg -si --noconfirm
    return 0
  fi
  local tmp rc
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  rc=$?
  if (( rc == 0 )); then
    (
      cd "$tmp/paru" || exit 1
      run makepkg -si --noconfirm
    )
    rc=$?
  fi
  rm -rf "$tmp"
  trap - EXIT
  (( rc == 0 )) || die "paru bootstrap failed"
}

install_packages() {
  local FONTS=(ttf-fira-code ttf-firacode-nerd ttf-font-awesome noto-fonts-emoji bibata-cursor-theme-bin ttf-koruri)
  local DEV_TOOLS=(cmake base-devel)
  local TERMINAL=(kitty fastfetch starship btop fd)
  local HYPRLAND=(hyprland uwsm mako hypridle hyprpicker hyprshot hyprlock wlogout wayfreeze xorg-xwayland xwaylandvideobridge swaync pyprland)
  local THEMING=(python-pywal awww waybar nwg-look qogir-icon-theme materia-gtk-theme)
  local FILE_MANAGER=(nemo nemo-webp-git nemo-fileroller)
  local AUDIO=(pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol)
  local NETWORK=(nm-connection-editor network-manager-applet)
  local UTILITIES=(wofi wdisplays pamixer inotify-tools playerctl jq python libnotify wl-clipboard)
  local DISPLAY_MANAGER=(sddm sddm-astronaut-theme qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg)
  local MISC=(pokemon-colorscripts)
  local PKGS=("${FONTS[@]}" "${BROWSER_PKGS[@]}" "${DEV_TOOLS[@]}" "${TERMINAL[@]}" "${HYPRLAND[@]}" "${THEMING[@]}" "${FILE_MANAGER[@]}" "${AUDIO[@]}" "${NETWORK[@]}" "${UTILITIES[@]}" "${DISPLAY_MANAGER[@]}" "${MISC[@]}" "${LAPTOP_PKGS[@]}")
  run paru -S --needed --noconfirm "${PKGS[@]}" || warn "paru -S failed; continuing, some packages may be missing (see output above)"
}

enable_tlp() {
  (( ${#LAPTOP_PKGS[@]} > 0 )) || return 0
  run sudo systemctl enable tlp
  run sudo systemctl start tlp
  run sudo tlp start
}

# --- main ---------------------------------------------------------------------------

main() {
  parse_args "$@"
  check_guards

  cat <<'EOF'
+-------------------------------------------------------------------------+
| jwmarb Dotfiles Installation Script                                     |
+=========================================================================+

You are about to install the jwmarb Dotfiles.

EOF
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "DRY RUN: system commands are printed, not run; files under $HOME ARE written"
  fi

  ask_yn "Would you like to proceed with the installation?" n y || exit 0

  resolve_dotfiles_dir
  fetch_dotfiles

  choose_browser
  choose_laptop

  run sudo -v || die "could not obtain sudo credentials; re-run in a terminal, or use --yes with sudo already cached"
  run sudo pacman -Syu --noconfirm || die "pacman -Syu failed"

  install_paru
  install_packages
  enable_tlp

  DOTFILES_DIR=$DOTFILES_DIR DRY_RUN=$DRY_RUN ASSUME_YES=$ASSUME_YES bash "$DOTFILES_DIR/postinstall.sh"
}
main "$@"
