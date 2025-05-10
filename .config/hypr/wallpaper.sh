#!/bin/bash
WALLPAPER_DIR="$HOME/wallpapers/walls"
#I dont know what the fuck I am doing
menu() {
    find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

use_wallpaper() {
	selected_wallpaper=$1
  wal -i "$selected_wallpaper" -n
	pywalfox update
  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
  swaync-client --reload-css
  cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf
  pkill -USR2 cava 2>/dev/null
  killall waybar
  waybar &
  source ~/.cache/wal/colors.sh && cp -r $wallpaper ~/wallpapers/pywallpaper.jpg
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
