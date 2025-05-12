#!/bin/bash
read -p "Would you like to add your github and linkedin to display on hyprlock? [y/N]: " add_info

if [[ "$add_info" == "y" || "$add_info" == "Y" ]]; then
    read -p "Enter your github username (required): " github
    read -p "Enter your LinkedIn name (required): " linkedin
    
    if [[ -z "$github" || -z "$linkedin" ]]; then
        echo "Both GitHub username and LinkedIn name are required. Skipping."
    else
        echo " $github   $linkedin" > $HOME/.config/hypr/hyprlock-media
        echo "Information added successfully."
    fi
else
    echo "Skipping GitHub and LinkedIn information."
fi

echo "Note: If you wish to change your information later, you can edit the contents of $HOME/.config/hypr/hyprlock-media"

sleep 1

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
cp -r ./wallpapers "$HOME/"

sudo chmod +x ./.setup-sddm
sudo chmod +x ./.setup-wal
sudo chmod +x ./.setup-gtk

./.setup-sddm
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
  ln -s "$PWD/.config/$folder" "$HOME/.config/$folder"
done

selected_wallpaper="$HOME/wallpapers/walls/mountains.jpg"

source .config/hypr/wallpaper.sh && \
  use_wallpaper $selected_wallpaper

echo "jwmarb's Dotfiles successfully installed."

if [[ -z "$DISPLAY" ]]; then
	read -p "Would you like to restart your pc now? [Y/n]: " choice

	if [[ "$choice" =~ ^[Yy]$ ]]; then
	  sudo reboot
	fi
elif [[ ! -z "$XDG_SESSION_TYPE" ]]; then 

  echo "Installation updated. Since you are already running on a graphical environment, some changes may not be fully reflected until reboot."

fi