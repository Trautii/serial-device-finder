# Serial Device Finder

Small KDE/Linux helper for finding the `/dev/ttyUSB*` or `/dev/ttyACM*`
path assigned to a newly plugged USB serial adapter.

The desktop launcher opens a terminal, asks you to plug in the adapter, detects
the new serial device, copies the path to the clipboard, and keeps the result
visible so you can paste it into PuTTY.

## Install

Clone your private repo, then run:

```bash
cd serial-device-finder
chmod +x install.sh uninstall.sh
./install.sh
```

To publish this folder to a new private GitHub repo:

```bash
cd serial-device-finder
git init
git add .
git commit -m "Initial serial device finder"
git branch -M main
git remote add origin git@github.com:YOUR_USER/YOUR_PRIVATE_REPO.git
git push -u origin main
```

The installer creates:

```text
~/.local/bin/find-serial.sh
~/.local/bin/find-serial-copy.sh
~/.config/serial-device-finder/config
~/Desktop/Find Serial Device.desktop
~/.local/share/applications/find-serial-device.desktop
```

After installing, double-click `Find Serial Device` on the desktop. If KDE
Plasma asks whether to trust or execute the launcher, allow it once.

## Clipboard Support

The copy step tries these methods, in order:

```text
wl-copy
xclip
xsel
qdbus6 KDE Klipper
qdbus KDE Klipper
```

On KDE Plasma, `qdbus6` is often already available. If automatic copying fails
on a Wayland session, install `wl-clipboard`.

CachyOS/Arch:

```bash
sudo pacman -S wl-clipboard
```

Debian/Ubuntu:

```bash
sudo apt install wl-clipboard
```

## Usage From Terminal

Detect and print the new serial device:

```bash
find-serial.sh
```

Detect, copy, and show the result:

```bash
find-serial-copy.sh
```

Use the result in another command:

```bash
PORT="$(find-serial.sh)"
echo "$PORT"
```

## Config

Default config:

```bash
SERIAL_FINDER_TIMEOUT=60
```

Edit it here after install:

```text
~/.config/serial-device-finder/config
```

## Uninstall

Remove installed scripts and launchers:

```bash
./uninstall.sh
```

Also remove the config:

```bash
./uninstall.sh --remove-config
```
