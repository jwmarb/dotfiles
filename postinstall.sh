#!/bin/bash
echo "This is for hyprlock."

read -p "Enter your github username (required): " github
read -p "Enter your LinkedIn name (required): " linkedin

echo " $github   $linkedin" > .config/hypr/hyprlock-media

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
cp -r ./wallpapers "$HOME/"

sudo chmod +x ./.setup-sddm
sudo chmod +x ./.setup-wal
sudo chmod +x ./.setup-gtk

sudo ./.setup-sddm
./.setup-wal
./.setup-gtk

# Check and add starship init if not already present
if ! grep -q "eval \$(starship init bash)" $HOME/.bashrc; then
  echo 'eval $(starship init bash)' >> $HOME/.bashrc
fi

# Check and add pokemon-colorscripts if not already present
if ! grep -q "pokemon-colorscripts -r" $HOME/.bashrc; then
  echo 'pokemon-colorscripts -r' >> $HOME/.bashrc
fi

for folder in .config/*; do
  folder=$(basename $folder)

	# Delete folder and its contents if it exists already
  if [[ -e "$HOME/.config/$folder" ]]; then
    rm -rf "$HOME/.config/$folder"
  fi
  ln -s "$(pwd)/.config/$folder" "$HOME/.config/$folder"
done

selected_wallpaper="$HOME/wallpapers/walls/mountains.jpg"

wal -i "$selected_wallpaper" -n && \
  swww img "$selected_wallpaper" && \
  cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf && \
	source ~/.cache/wal/colors.sh && \
	cp -r $wallpaper ~/wallpapers/pywallpaper.jpg

echo "jwmarb's Dotfiles successfully installed."

if [[ -z "$DISPLAY" ]]; then
	read -p "Would you like to restart your pc now? [Y/n]: " choice

	if [[ "$choice" =~ ^[Yy]$ ]]; then
	  sudo reboot
	fi
fi