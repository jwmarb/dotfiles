#!/bin/bash
WALLPAPER_DIR="$HOME/wallpapers/walls"
#I dont know what the fuck I am doing
menu() {
    find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}
backgroundAlpha() {
  source ~/.cache/wal/colors.sh
  local hex="${background#\#}"
  local alpha="$1"
  local r g b

  if [[ ${#hex} -eq 6 ]]; then
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
  elif [[ ${#hex} -eq 3 ]]; then
    r=$((16#${hex:0:1}${hex:0:1}))
    g=$((16#${hex:1:1}${hex:1:1}))
    b=$((16#${hex:2:1}${hex:2:1}))
  else
    echo "Invalid hex color."
    return 1
  fi

  echo "rgba($r, $g, $b, $alpha)"
}
use_wallpaper() {
  swww query
  if [[ $? -eq 1 ]]; then
    swww init
  fi
  selected_wallpaper=$1
  wal -i "$selected_wallpaper" -n
  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
  pywalfox update
  swaync-client --reload-css
  cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf
  pkill -USR2 cava 2>/dev/null
  source ~/.cache/wal/colors.sh && cp -r $wallpaper ~/wallpapers/pywallpaper.jpg && cp -r $wallpaper /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/pywallpaper.jpg
  
  # source color file to set vars. loop over the template, eval each env, then write out to deployed version
  source ~/.cache/wal/colors.sh
  read WIDTH HEIGHT < <(hyprctl monitors | awk 'NR==2 {split($1,a,"x"); split(a[2],b,"@"); print a[1], b[1]}')
  while IFS= read -r line; do
    eval "echo \"$line\""
  done < /usr/share/sddm/themes/sddm-astronaut-theme/Themes/hyprlock.template.conf  > /usr/share/sddm/themes/sddm-astronaut-theme/Themes/hyprlock.conf
}
main() {
    cat $HOME/.cache/wal/colors-kitty.conf > /tmp/prev_wallpaper
    choice=$(menu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Search for a wallpaper..." -n)
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
    use_wallpaper "$selected_wallpaper"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    main
fi