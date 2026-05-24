# Armbian Minimal Web Kiosk Setup (Orange Pi / Debian Trixie)

This guide documents the exact working steps used to configure a lightweight web kiosk on a CLI-only Armbian installation (tested on Orange Pi One).

The system boots directly into a fullscreen Chromium browser displaying:

https://pal.be

This setup uses:
- Xorg
- Openbox
- Chromium
- systemd

No full desktop environment is required.

---

# 1. Install Required Packages

Update package repositories and install the minimal graphical stack.

```bash
sudo apt update
sudo apt install --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox chromium unclutter
```

---

# 2. Configure Openbox Autostart

Create the Openbox configuration directory for the `root` user:

```bash
mkdir -p /root/.config/openbox
```

Open the autostart configuration file:

```bash
nano /root/.config/openbox/autostart
```

Paste the following configuration:

```bash
# Disable screen saver and power management blanking
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor after 1 second
unclutter -idle 1 -root &

# Launch Chromium in fullscreen kiosk mode
# --no-sandbox is required when running as root
# --disable-gpu prevents crashes on embedded SoCs
chromium --no-sandbox --noerrdialogs --disable-infobars --incognito --kiosk --disable-gpu "https://pal.be" &
```

Save and exit:

- `CTRL + O`
- `ENTER`
- `CTRL + X`

---

# 3. Create the systemd Kiosk Service

Create the kiosk service file:

```bash
nano /etc/systemd/system/kiosk.service
```

Paste the following configuration:

```ini
[Unit]
Description=Armbian Web Kiosk
After=network.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
PAMName=login
TTYPath=/dev/tty7
ExecStart=/usr/bin/startx /usr/bin/openbox-session
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Save and exit:

- `CTRL + O`
- `ENTER`
- `CTRL + X`

---

# 4. Enable and Start the Kiosk

Reload systemd:

```bash
systemctl daemon-reload
```

Enable the kiosk service on boot:

```bash
systemctl enable kiosk.service
```

Start the kiosk immediately:

```bash
systemctl start kiosk.service
```

If everything works correctly, the HDMI display should switch to Chromium running in fullscreen kiosk mode.

---

# 5. Kiosk Management Commands

## Stop the kiosk

```bash
systemctl stop kiosk.service
```

---

## Restart the kiosk

```bash
systemctl restart kiosk.service
```

---

## View logs / troubleshoot black screen

```bash
journalctl -u kiosk.service -n 50 --no-pager
```

---

# Notes

## Why `chromium` instead of `chromium-browser`

On newer Armbian / Debian Trixie systems, the package is named:

```bash
chromium
```

not:

```bash
chromium-browser
```

---

## Why `--no-sandbox`

Chromium will fail silently when launched as the `root` user unless:

```bash
--no-sandbox
```

is added.

Without it, the screen may remain black.

---

## Why `--disable-gpu`

Many embedded ARM boards have unstable GPU acceleration support.

Using:

```bash
--disable-gpu
```

prevents Chromium crashes and black screens.

---

## Why `startx` instead of `xinit`

Using:

```bash
startx
```

worked more reliably on Orange Pi hardware and properly initialized the HDMI display.

---

# Tested On

- Orange Pi One
- Armbian CLI
- Debian Trixie
- HDMI output
- Chromium 148+

---
