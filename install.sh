#!/bin/bash
CONFIG_PATH="$HOME/.config/hypr/hyprland.conf"

FONTS="ttf-fira-code ttf-firacode-nerd ttf-font-awesome noto-fonts-emoji illogical-impulse-bibata-modern-classic-bin"
BROWSER="zen-browser"
DEV_TOOLS="cmake base-devel"
TERMINAL="kitty fastfetch starship btop fd"
HYPRLAND="hyprland swaync hypridle hyprpicker hyprshot hyprlock wlogout"
THEMING="python-pywal swww waybar nwg-look qogir-icon-theme materia-gtk-theme"
FILE_MANAGER="nemo nemo-webp-git nemo-fileroller"
AUDIO="pipewire pipewire-pulse pipewire-alsa pipewire-jack pavucontrol"
NETWORK="nm-connection-editor network-manager-applet"
UTILITIES="wofi wdisplays pamixer"
DISPLAY_MANAGER="sddm sddm-astronaut-theme qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg"
MISC="pokemon-colorscripts-git"

sudo pacman -Syu

if [[ ! -d "paru" ]]; then
  git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si
fi

paru -Sy \
  $FONTS \
  $BROWSER \
  $DEV_TOOLS \
  $TERMINAL \
  $HYPRLAND \
  $THEMING \
  $FILE_MANAGER \
  $AUDIO \
  $NETWORK \
  $UTILITIES \
  $DISPLAY_MANAGER \
  $MISC

hyprland