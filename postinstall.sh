mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.cache/wal"

cp -r ./wallpapers "$HOME/"
cp -r .cache/* ~/.cache/
touch ~/.cache/wal/colors-kitty.conf
sudo mkdir -p "/etc/sddm.conf.d"


echo "[Theme]
Current=sddm-astronaut-theme" > /etc/sddm.conf
echo "[General]
InputMethod=qtvirtualkeyboard" > /etc/sddm.conf.d/virtualkbd.conf
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
echo " - Reboot!"