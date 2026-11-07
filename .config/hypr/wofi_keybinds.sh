#!/bin/bash
# SUPER+H: searchable list of Hyprland keybinds; selecting one runs it.
# Hyprland 0.57+ (Lua config): binds are read from the KEYBIND_MENU table that
# hyprland.lua builds, via `hyprctl repl`, and run by index through the same
# dispatcher the key itself uses. Nothing here parses the config file.

# One tab-separated line per bind: index, keys, label
LIST=$(hyprctl repl 'local out = {}
for i, b in ipairs(KEYBIND_MENU or {}) do
    local label = tostring(b.label):gsub("[\t\n]", " ")
    out[#out + 1] = i .. "\t" .. b.keys .. "\t" .. label
end
return table.concat(out, "\n")' 2>/dev/null)

if [[ -z "$LIST" || "$LIST" == error* ]]; then
    notify-send "Keybinds" "Could not read keybinds from Hyprland (is KEYBIND_MENU defined in hyprland.lua?)" 2>/dev/null
    echo "Could not read keybinds from Hyprland: $LIST" >&2
    exit 1
fi

escape_markup() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

DISPLAY_LINES=""
while IFS=$'\t' read -r idx keys label; do
    [[ -z "$idx" ]] && continue
    DISPLAY_LINES+="[$idx] <b>$(escape_markup "$keys")</b>  <span color='gray'>$(escape_markup "$label")</span>"$'\n'
done <<< "$LIST"

SELECTION=$(printf '%s' "$DISPLAY_LINES" | wofi -c "$HOME/.config/wofi/keybinds" -s "$HOME/.config/wofi/style-keybinds.css" -dmenu -i -p "Hyprland Keybinds:")
[[ -z "$SELECTION" ]] && exit 0

IDX=$(grep -o '^\[[0-9]*\]' <<< "$SELECTION" | tr -d '[]')
[[ "$IDX" =~ ^[0-9]+$ ]] || exit 1

# Run the bind's own dispatcher (or Lua function) in the live session
hyprctl repl "local b = KEYBIND_MENU[$IDX]; if not b then return 'no such bind' end; return hl.dispatch(b.action).ok" >/dev/null
