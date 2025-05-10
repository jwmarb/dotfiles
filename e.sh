#!/bin/bash

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Process each bind line
count=1
grep '^bind' "$HYPR_CONF" | while IFS= read -r line; do
    # Remove 'bind=' prefix
    content="$(echo "$line" | cut -d' ' -f3-)"
		
    
    # Extract modifiers (first part before comma)
    modifiers="${content%%,*}"
    content="${content#*,}"
    
    # Extract key (next part before comma)
    key="${content%%,*}"
    content="${content#*,}"
    
    # The rest is the command, check for comments
    if [[ "$content" == *"#"* ]]; then
        cmd="${content%%#*}"
        comment="${content#*#}"
        
        # Trim whitespace
        cmd="${cmd%"${cmd##*[![:space:]]}"}"
        comment="${comment#"${comment%%[![:space:]]*}"}"
    else
        cmd="$content"
        comment=""
    fi
    
    # Format display with line number prefix (for reliable selection)
    if [[ -n "$comment" ]]; then
        display="[$count] <b>$modifiers +$key</b>  <span color='gray'>$cmd</span> <i>$comment</i>"
    else
        display="[$count] <b>$modifiers +$key</b>  <span color='gray'>$cmd</span>"
    fi
    
    # Store in files
    echo "$display" >> "$TMP_DIR/display.txt"
    echo "$cmd" >> "$TMP_DIR/commands.txt"
    
    ((count++))
done

# If we have keybindings, show the menu
if [[ -s "$TMP_DIR/display.txt" ]]; then
    # Show wofi menu
    SELECTION=$(cat "$TMP_DIR/display.txt" | wofi -c $HOME/.config/wofi/keybinds -s $HOME/.config/wofi/style-keybinds.css -dmenu -i -p "Hyprland Keybinds:")
    
    if [[ -n "$SELECTION" ]]; then
        # Extract line number from selection
        line_num=$(echo "$SELECTION" | grep -o '^\[[0-9]*\]' | tr -d '[]')
        
        # Get the command for this line
        CMD=$(sed -n "${line_num}p" "$TMP_DIR/commands.txt")
        
        # Execute the command
        if [[ "$CMD" == exec* ]]; then
            EXEC_CMD="${CMD#exec }"
            eval "$EXEC_CMD" &
        else
            hyprctl dispatch "$CMD"
        fi
    fi
else
    echo "No keybindings found in $HYPR_CONF"
    exit 1
fi