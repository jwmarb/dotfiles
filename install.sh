#!/bin/bash


cat << EOF
+-------------------------------------------------------------------------+
| jwmarb Dotfiles Installation Script                                     |
+=========================================================================+

You are about to install the jwmarb Dotfiles.

EOF

read -p "Would you like to proceed with the installation? [y/N]: " choice

choice=${choice:-N}

if [[ "$choice" =~ ^[nN]$ ]]; then
	echo "Exiting installation script."
	exit 0
fi


CONFIG_PATH="$HOME/.config/hypr/hyprland.conf"

FONTS="ttf-fira-code ttf-firacode-nerd ttf-font-awesome noto-fonts-emoji illogical-impulse-bibata-modern-classic-bin ttf-koruri"
DEV_TOOLS="cmake base-devel"
TERMINAL="kitty fastfetch starship btop fd"
HYPRLAND="hyprland swaync hypridle hyprpicker hyprshot hyprlock wlogout wayfreeze-git xorg-xwayland xwaylandvideobridge"
THEMING="python-pywal swww waybar nwg-look qogir-icon-theme materia-gtk-theme"
FILE_MANAGER="nemo nemo-webp-git nemo-fileroller"
AUDIO="pipewire pipewire-pulse pipewire-alsa pipewire-jack pavucontrol"
NETWORK="nm-connection-editor network-manager-applet"
UTILITIES="wofi wdisplays pamixer"
DISPLAY_MANAGER="sddm sddm-astronaut-theme qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg"
MISC="pokemon-colorscripts-git"

BROWSER_OPTIONS=("firefox" "zen-browser-bin" "chromium" "google-chrome" "brave-bin" "opera")

echo "Please select a browser to install:"
select choice in "${BROWSER_OPTIONS[@]}" "Skip browser installation"; do
    if [[ -z "$choice" ]]; then
        echo "Invalid selection. Please try again."
    elif [[ "$choice" == "Skip browser installation" ]]; then
        BROWSER=""
        echo "Browser installation will be skipped."
        break
    else
        BROWSER="$choice"
        break
    fi
done

read -p "Would you like to install packages for functionality on a laptop? [y/N]: " choice

choice=${choice:-N}

if [[ "$choice" =~ ^[yY]$ ]]; then
	LAPTOP=$(cat pkgs-laptop.list)
else
	LAPTOP=""
fi

echo "Updating system..."

sudo pacman -Syu --noconfirm

if ! command -v paru &> /dev/null; then
  echo "Installing paru..."
  git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si
else
  echo "paru is already installed, skipping..."
fi

echo "Performing package installation..."

paru -S --noconfirm \
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
  $MISC \
	$LAPTOP

./postinstall.sh