#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
finder="${SERIAL_FINDER_BIN:-$script_dir/find-serial.sh}"
config_file="${SERIAL_FINDER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/serial-device-finder/config}"
timeout="${SERIAL_FINDER_TIMEOUT:-60}"

if [[ -r "$config_file" ]]; then
  # shellcheck source=/dev/null
  source "$config_file"
  timeout="${SERIAL_FINDER_TIMEOUT:-$timeout}"
fi

pause_before_close() {
  if [[ -t 0 ]]; then
    echo
    read -r -p "Press Enter to close..."
  fi
}

copy_to_clipboard() {
  local text="$1"

  if command -v wl-copy >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if printf '%s' "$text" | wl-copy; then
      return 0
    fi
  fi

  if command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    if printf '%s' "$text" | xclip -selection clipboard; then
      return 0
    fi
  fi

  if command -v xsel >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    if printf '%s' "$text" | xsel --clipboard --input; then
      return 0
    fi
  fi

  if command -v qdbus6 >/dev/null 2>&1; then
    if qdbus6 org.kde.klipper /klipper setClipboardContents "$text" >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v qdbus >/dev/null 2>&1; then
    if qdbus org.kde.klipper /klipper setClipboardContents "$text" >/dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
}

if [[ ! -x "$finder" ]]; then
  echo "Could not run $finder" >&2
  echo "Make sure it exists and is executable." >&2
  pause_before_close
  exit 1
fi

if [[ ! "$timeout" =~ ^[0-9]+$ || "$timeout" -lt 1 ]]; then
  echo "Invalid SERIAL_FINDER_TIMEOUT in $config_file: $timeout" >&2
  pause_before_close
  exit 1
fi

if ! devices="$("$finder" --timeout "$timeout")"; then
  pause_before_close
  exit 1
fi

device="$(printf '%s\n' "$devices" | sed -n '1p')"

if [[ -z "$device" ]]; then
  echo "No device was detected." >&2
  pause_before_close
  exit 1
fi

echo
echo "Detected serial device:"
echo "$device"
echo

if copy_to_clipboard "$device"; then
  echo "Copied to clipboard. Paste it into PuTTY's Serial line field."
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Serial device copied" "$device" >/dev/null 2>&1 || true
  fi
else
  echo "Could not copy automatically."
  echo "Install wl-clipboard on Wayland, or copy this manually:"
  echo "$device"
fi

pause_before_close
