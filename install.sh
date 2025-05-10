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
for i in "${!BROWSER_OPTIONS[@]}"; do
    echo "[$((i+1))] ${BROWSER_OPTIONS[$i]}"
done
echo "[0] Skip browser installation"

while true; do
    read -p "Enter number [0-${#BROWSER_OPTIONS[@]}]: " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [[ "$selection" -eq 0 ]]; then
            BROWSER=""
            echo "Browser installation will be skipped."
            break
        elif [[ "$selection" -le "${#BROWSER_OPTIONS[@]}" ]]; then
            BROWSER="${BROWSER_OPTIONS[$((selection-1))]}"

            # Check if the selected browser is firefox or zen-browser-bin
            if [[ "$BROWSER" == "firefox" || "$BROWSER" == "zen-browser-bin" ]]; then
                BROWSER="$BROWSER python-pywalfox"
            fi

            echo "Selected browser: $BROWSER"
            break
        fi
    fi
    
    echo "Invalid selection. Please enter a number between 0 and ${#BROWSER_OPTIONS[@]}."
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

if [[ -z "$LAPTOP" ]]; then
	sudo systemctl enable tlp
	sudo systemctl start tlp
	sudo tlp start
fi

./postinstall.sh