#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/bin"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/serial-device-finder"
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

desktop_dir="$(desktop_dir_from_system)"

rm -f "$install_dir/find-serial.sh"
rm -f "$install_dir/find-serial-copy.sh"
rm -f "$desktop_dir/$desktop_name"
rm -f "$app_dir/find-serial-device.desktop"

if [[ "${1:-}" == "--remove-config" ]]; then
  rm -rf "$config_dir"
else
  echo "Leaving config in place: $config_dir"
  echo "Run ./uninstall.sh --remove-config to remove it too."
fi

echo "Uninstalled Serial Device Finder."
