#!/bin/bash

WAYBAR_DIR="$HOME/.config/waybar"
GENERATE="$WAYBAR_DIR/scripts/generate_config.sh"
CONFIG_FILES="$WAYBAR_DIR/config $WAYBAR_DIR/style.css $HOME/.cache/wal/colors-waybar.css"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

trap "killall waybar; kill 0" EXIT

restart_waybar() {
    killall waybar 2>/dev/null
    bash "$GENERATE"
    waybar &
}

restart_waybar

socat -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*)
            sleep 1
            restart_waybar
            ;;
    esac
done &

while true; do
    inotifywait -e create,modify $CONFIG_FILES
    restart_waybar
done
