#!/bin/bash

# Kill previous instances of this script (prevents duplicate managers)
pgrep -f "launch_waybar.sh" | grep -v "^$$\$" | xargs -r kill 2>/dev/null && sleep 0.2

WAYBAR_DIR="$HOME/.config/waybar"
GENERATE="$WAYBAR_DIR/scripts/generate_config.sh"
CONFIG_FILES="$WAYBAR_DIR/config $WAYBAR_DIR/style.css $HOME/.cache/wal/colors-waybar.css"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

trap "killall waybar 2>/dev/null; kill 0" EXIT

restart_waybar() {
    killall waybar 2>/dev/null
    while pgrep -x waybar >/dev/null; do sleep 0.1; done
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
