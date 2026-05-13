#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: find-serial.sh [-t seconds]

Snapshots existing /dev/ttyUSB* and /dev/ttyACM* devices, waits for a new
serial device to be plugged in, then prints the new device path on stdout.

Options:
  -t, --timeout SECONDS   Stop waiting after SECONDS. Default: 60.
  -h, --help              Show this help.
EOF
}

timeout=60
use_color=0

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  use_color=1
fi

if ((use_color)); then
  bold=$'\033[1m'
  dim=$'\033[2m'
  green=$'\033[32m'
  yellow=$'\033[33m'
  red=$'\033[31m'
  reset=$'\033[0m'
else
  bold=
  dim=
  green=
  yellow=
  red=
  reset=
fi

status_line_active=0

cleanup_status_line() {
  if ((status_line_active)); then
    printf '\n' >&2
  fi
}

trap cleanup_status_line EXIT

while (($#)); do
  case "$1" in
    -t|--timeout)
      if [[ $# -lt 2 || ! "$2" =~ ^[0-9]+$ || "$2" -lt 1 ]]; then
        echo "error: --timeout requires a positive number of seconds" >&2
        exit 2
      fi
      timeout="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

list_serial_devices() {
  local devices=()

  shopt -s nullglob
  devices=(/dev/ttyUSB* /dev/ttyACM*)
  shopt -u nullglob

  if ((${#devices[@]})); then
    printf '%s\n' "${devices[@]}" | sort -V
  fi
}

declare -A existing=()
while IFS= read -r device; do
  existing["$device"]=1
done < <(list_serial_devices)

printf '%sFind Serial Device%s\n' "$bold" "$reset" >&2

if ((${#existing[@]})); then
  printf '%sAlready connected:%s\n' "$dim" "$reset" >&2
  while IFS= read -r device; do
    printf '  %s\n' "$device" >&2
  done < <(list_serial_devices)
else
  printf '%sAlready connected:%s none\n' "$dim" "$reset" >&2
fi

printf '\n%sPlug in the device now.%s\n' "$yellow" "$reset" >&2

start=$SECONDS
spinner='-\|/'
tick=0

while :; do
  new_devices=()

  while IFS= read -r device; do
    if [[ -z "${existing[$device]+seen}" ]]; then
      new_devices+=("$device")
    fi
  done < <(list_serial_devices)

  if ((${#new_devices[@]})); then
    if command -v udevadm >/dev/null 2>&1; then
      udevadm settle >/dev/null 2>&1 || true
    fi

    if ((status_line_active)); then
      printf '\r%*s\r' 80 '' >&2
      status_line_active=0
    fi

    printf '%sFound new device:%s\n' "$green" "$reset" >&2
    printf '%s\n' "${new_devices[@]}" | sort -V
    exit 0
  fi

  if ((SECONDS - start >= timeout)); then
    if ((status_line_active)); then
      printf '\r%*s\r' 80 '' >&2
      status_line_active=0
    fi

    printf '%sTimed out after %ss without seeing a new serial device.%s\n' "$red" "$timeout" "$reset" >&2
    exit 1
  fi

  if [[ -t 2 ]]; then
    frame="${spinner:tick % ${#spinner}:1}"
    tick=$((tick + 1))
    printf '\r%s Waiting... %ss/%ss  Ctrl+C to cancel' "$frame" "$((SECONDS - start))" "$timeout" >&2
    status_line_active=1
  fi

  sleep 0.2
done
