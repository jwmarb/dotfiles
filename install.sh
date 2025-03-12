sudo pacman -Syu

git clone https://aur.archlinux.org/paru.git && \
  cd paru && \
  makepkg -si

paru -Sy pavucontrol \
  pulseaudio \
  kitty \
  base-devel \
  fastfetch \
  python-pywal \
  swww \
  waybar \
  hyprland \
  swaync \
  starship \
  hypridle \
  hyprpicker \
  hyprshot \
  hyprlock \
  wlogout \
  fd \
  nwg-look \
  qogir-icon-theme \
  materia-gtk-theme \
  nemo \
  btop \
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  pipewire-jack \
  pavucontrol \
  pulsemixer \
  nm-connection-editor \
  network-manager-applet

mkdir -p "$HOME/wallpapers/walls"
mkdir -p "$HOME/.config"

for folder in "$(pwd)/.config"/*; do
  folder=$(basename $folder)
  if [[ -e "$HOME/.config/$folder" ]]; then
    rm -rf "$HOME/.config/$folder"
  fi
  ln -s "$(pwd)/.config/$folder" "$HOME/.config/$folder"
done