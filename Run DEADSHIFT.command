#!/bin/zsh
set -eu
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
for engine in /Applications/Godot.app/Contents/MacOS/Godot /private/tmp/deadshift-engine/Godot.app/Contents/MacOS/Godot; do
    if [[ -x "$engine" ]]; then
        exec "$engine" --path "$project_dir"
    fi
done
if command -v godot >/dev/null 2>&1; then
    exec godot --path "$project_dir"
fi
printf '%s\n' 'Godot 4 was not found. Install Godot, import project.godot, and press F5.'
read -r '?Press Enter to close.'
