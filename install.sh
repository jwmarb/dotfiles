sudo pacman -Syu

if [[ ! -d "paru" ]]; then
  git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si
fi

paru -Sy \
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
  nm-connection-editor \
  network-manager-applet \
  illogical-impulse-bibata-modern-classic-bin \
  ttf-fira-code \
  
cp -r ./wallpapers "$HOME/"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.cache/wal"

for folder in "$(pwd)/.config"/*; do
  folder=$(basename $folder)
  if [[ -e "$HOME/.config/$folder" ]]; then
    rm -rf "$HOME/.config/$folder"
  fi
  ln -s "$(pwd)/.config/$folder" "$HOME/.config/$folder"
done