#!/bin/bash
WALLPAPER_DIR="$HOME/wallpapers/walls"
#I dont know what the fuck I am doing
menu() {
    find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}
main() {
    cat $HOME/.cache/wal/colors-kitty.conf > /tmp/prev_wallpaper
    choice=$(menu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n)
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
    wal -i "$selected_wallpaper" -n
    cat $HOME/.cache/wal/colors-kitty.conf > /tmp/current_wallpaper
    DIFF=$(diff /tmp/current_wallpaper /tmp/prev_wallpaper)
    if [[ "$DIFF" != "" ]]; then
      swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
      swaync-client --reload-css
      cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf
      pkill -USR2 cava 2>/dev/null
      killall waybar
      waybar &
      source ~/.cache/wal/colors.sh && cp -r $wallpaper ~/wallpapers/pywallpaper.jpg 
    fi
}
main

