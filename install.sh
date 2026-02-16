#!/bin/bash
DESKTOP_ENTRY_PATH="$HOME/.local/share/applications"
START_SCRIPT="$(pwd)/start.sh"
CB_SCRIPT="$(pwd)/get-last-cb-item.sh"

success() { echo "$(printf '\033[1;32m%s\033[0m' "$*")"; }
err() { echo "$(printf '\033[1;31m%s\033[0m' "$*")"; }

[ -z "$1" ] || [ -z "$2" ] && { err "Usage: $0 <desktop_entry_name> <minecraft_filename (without '.desktop')>"; exit 1; }

SHORTCUT_EXISTS=$(dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ | grep "name='get-last-cb-item'")
if [ -z "$SHORTCUT_EXISTS" ]; then
  echo "Shortcut not found. Installing..."
  CURRENT_LIST=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
  NEXT_INDEX=$(echo $CURRENT_LIST | grep -o 'custom[0-9]\+' | sed 's/custom//' | sort -n | tail -1)
  NEW_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$((NEXT_INDEX + 1))/"

  NEW_LIST=$(echo $CURRENT_LIST | sed "s|]|, '$NEW_PATH']|" | sed "s|' '|', '|g")
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH name get-last-cb-item
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH command "$CB_SCRIPT"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH binding 'Insert'
fi

echo "Setting up start script..."
sed -i "\$ s/\s*[^[:space:]]\+\$/ $2/" "$START_SCRIPT"

echo "Updating desktop entry..."
cat > "$DESKTOP_ENTRY_PATH/$1.desktop" <<EOF
[Desktop Entry]
Name=$1
Exec=/bin/bash -lc "$START_SCRIPT"
Type=Application
Terminal=false
Icon=$(sed -n 's/^Icon=//p' "$DESKTOP_ENTRY_PATH/$2.desktop")
Categories=Application;
EOF
update-desktop-database "$DESKTOP_ENTRY_PATH"

success "All done"
