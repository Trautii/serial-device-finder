#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
install_dir="$HOME/.local/bin"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/serial-device-finder"
config_file="$config_dir/config"
app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
desktop_name="Find Serial Device.desktop"

desktop_dir_from_system() {
  local dir=""

  if command -v xdg-user-dir >/dev/null 2>&1; then
    dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
  fi

  if [[ -z "$dir" || "$dir" == "$HOME" ]]; then
    dir="$HOME/Desktop"
  fi

  printf '%s\n' "$dir"
}

choose_exec_line() {
  local copy_script="$1"

  if command -v konsole >/dev/null 2>&1; then
    printf 'konsole -e %s\n' "$copy_script"
  else
    printf '%s\n' "$copy_script"
  fi
}

choose_terminal_flag() {
  if command -v konsole >/dev/null 2>&1; then
    printf 'false\n'
  else
    printf 'true\n'
  fi
}

warn_if_clipboard_helper_missing() {
  if command -v wl-copy >/dev/null 2>&1 ||
    command -v xclip >/dev/null 2>&1 ||
    command -v xsel >/dev/null 2>&1 ||
    command -v qdbus6 >/dev/null 2>&1 ||
    command -v qdbus >/dev/null 2>&1; then
    return 0
  fi

  cat <<'EOF'

Warning: no supported clipboard helper was found.
On KDE Plasma this may still work if qdbus is installed with KDE tools.
For Wayland systems, install wl-clipboard if automatic copying fails:

  CachyOS/Arch:  sudo pacman -S wl-clipboard
  Debian/Ubuntu: sudo apt install wl-clipboard
EOF
}

desktop_dir="$(desktop_dir_from_system)"
copy_script="$install_dir/find-serial-copy.sh"
exec_line="$(choose_exec_line "$copy_script")"
terminal_flag="$(choose_terminal_flag)"

install -d "$install_dir" "$config_dir" "$app_dir" "$desktop_dir"
install -m 0755 "$script_dir/bin/find-serial.sh" "$install_dir/find-serial.sh"
install -m 0755 "$script_dir/bin/find-serial-copy.sh" "$copy_script"

if [[ ! -e "$config_file" ]]; then
  install -m 0644 "$script_dir/config/default.conf" "$config_file"
fi

desktop_tmp="$(mktemp)"
sed \
  -e "s|@EXEC@|$exec_line|g" \
  -e "s|@TERMINAL@|$terminal_flag|g" \
  "$script_dir/desktop/$desktop_name.in" > "$desktop_tmp"

install -m 0755 "$desktop_tmp" "$desktop_dir/$desktop_name"
install -m 0644 "$desktop_tmp" "$app_dir/find-serial-device.desktop"
rm -f "$desktop_tmp"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_dir/$desktop_name"
  desktop-file-validate "$app_dir/find-serial-device.desktop"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$app_dir" >/dev/null 2>&1 || true
fi

warn_if_clipboard_helper_missing

cat <<EOF

Installed Serial Device Finder.

Scripts:
  $install_dir/find-serial.sh
  $copy_script

Config:
  $config_file

Launchers:
  $desktop_dir/$desktop_name
  $app_dir/find-serial-device.desktop

Double-click "Find Serial Device" on your desktop.
If Plasma asks whether to trust or execute it, allow it once.
EOF
