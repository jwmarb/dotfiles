#!/bin/bash
# Usage: generate_config.sh [source_config] [output_config]
# Detects monitors via hyprctl, assigns workspace ranges (1-10, 11-20, ...),
# and injects them into the waybar config's persistent-workspaces block.

WAYBAR_DIR="$HOME/.config/waybar"
SOURCE="${1:-$WAYBAR_DIR/config}"
OUTPUT="${2:-$WAYBAR_DIR/config}"

mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')

if [[ ${#MONITORS[@]} -eq 0 ]]; then
    exit 0
fi

build_workspaces_block() {
    local i=0
    for monitor in "${MONITORS[@]}"; do
        local start=$(( i * 10 + 1 ))
        local end=$(( start + 9 ))
        [[ $i -gt 0 ]] && printf ","
        printf '\n      "%s": [' "$monitor"
        for ws in $(seq $start $end); do
            [[ $ws -gt $start ]] && printf ","
            printf '\n        %d' "$ws"
        done
        printf '\n      ]'
        ((i++))
    done
}

WS_BLOCK=$(build_workspaces_block)

python3 -c "
import re

with open('$SOURCE', 'r') as f:
    content = f.read()

content = re.sub(r'\n\s*\"output\":\s*\"[^\"]*\",?\s*\n', '\n', content)

def replace_ws(match):
    indent = match.group(1)
    return indent + '\"persistent-workspaces\": {' + '''$WS_BLOCK''' + '\n    }'

content = re.sub(
    r'(\s*)\"persistent-workspaces\":\s*\{[^}]*(?://[^\n]*\n[^}]*)*\}',
    replace_ws,
    content,
    flags=re.DOTALL
)

with open('$OUTPUT', 'w') as f:
    f.write(content)
"
