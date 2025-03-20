#!/bin/bash
CONFIG_PATH="$HOME/.config/hypr/hyprland.conf"

FONTS="ttf-fira-code ttf-firacode-nerd ttf-font-awesome noto-fonts-emoji illogical-impulse-bibata-modern-classic-bin"
BROWSER="zen-browser"
DEV_TOOLS="cmake base-devel"
TERMINAL="kitty fastfetch starship btop fd"
HYPRLAND="hyprland swaync hypridle hyprpicker hyprshot hyprlock wlogout"
THEMING="python-pywal swww waybar nwg-look qogir-icon-theme materia-gtk-theme"
FILE_MANAGER="nemo"
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

hyprland & 

while [[ ! -f "$CONFIG_PATH"]]; do
  sleep 1
done
  
cp -r ./wallpapers "$HOME/"
cp -r .cache/* ~/.cache/
touch ~/.cache/wal/colors-kitty.conf
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.cache/wal"

echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
echo 'eval $(starship init bash)' >> $HOME/.bashrc
echo 'pokemon-colorscripts -r' >> $HOME/.bashrc

for folder in "$(pwd)/.config"/*; do
  folder=$(basename $folder)
  if [[ -e "$HOME/.config/$folder" ]]; then
    rm -rf "$HOME/.config/$folder"
  fi
  ln -s "$(pwd)/.config/$folder" "$HOME/.config/$folder"
done

sudo systemctl enable sddm

echo "POST-INSTALL INSTRUCTIONS:"
echo " - Press Alt + W and select the wallpaper to initialize the widgets and color theme"
echo " - Run \"nwg-look\" to configure the theme"