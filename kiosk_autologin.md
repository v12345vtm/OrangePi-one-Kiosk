# Armbian HDMI Kiosk Setup (Orange Pi + Chromium + Auto Login)

This guide documents a complete working HDMI kiosk setup for a CLI-only Armbian installation using:

- Xorg
- Openbox
- Chromium
- xdotool
- systemd

The kiosk:
- boots automatically into Chromium fullscreen
- opens a Node-RED / Home Assistant dashboard
- automatically enters login credentials
- works without keyboard or mouse attached

Tested on:
- Orange Pi One
- Armbian (Debian Trixie)
- HDMI display

---

# Features

- Lightweight
- No desktop environment required
- Auto starts after boot
- Auto login support
- Chromium kiosk mode
- Hidden mouse cursor
- Automatic recovery after reboot

---

# 1. Install Required Packages

Update repositories and install required software:

```bash
sudo apt update

sudo apt install -y --no-install-recommends \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    openbox \
    chromium \
    unclutter \
    xdotool
```

---

# 2. Create Openbox Autostart Configuration

Create the Openbox configuration directory:

```bash
mkdir -p /root/.config/openbox
```

Create the autostart file:

```bash
nano /root/.config/openbox/autostart
```

Paste:

```bash
# Disable screen blanking and power saving
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor
unclutter -idle 1 -root &

# Start Chromium in kiosk mode
chromium \
  --no-sandbox \
  --disable-gpu \
  --disable-infobars \
  --kiosk \
  --app=https://pal.be &

# Auto login script
/root/autologin.sh &
```

Save:
- CTRL + O
- ENTER
- CTRL + X

---

# 3. Create Automatic Login Script

Create the script:

```bash
nano /root/autologin.sh
```

Paste:

```bash
#!/bin/bash

# Wait for Chromium to fully load
sleep 15

# Type username
xdotool type "homeassistant"

# Move to password field
xdotool key Tab

# Type password
xdotool type "homeassistant"

# Press ENTER
xdotool key Return
```

Save:
- CTRL + O
- ENTER
- CTRL + X

Make executable:

```bash
chmod +x /root/autologin.sh
```

---

# 4. Create systemd Kiosk Service

Create service file:

```bash
nano /etc/systemd/system/kiosk.service
```

Paste:

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

Save:
- CTRL + O
- ENTER
- CTRL + X

---

# 5. Enable And Start Kiosk

Reload systemd:

```bash
systemctl daemon-reload
```

Enable kiosk on boot:

```bash
systemctl enable kiosk.service
```

Start kiosk:

```bash
systemctl start kiosk.service
```

The display should now:
1. boot into Chromium
2. open the dashboard
3. automatically enter login credentials
4. open the dashboard fullscreen

---

# 6. Useful Commands

## Stop kiosk

```bash
systemctl stop kiosk.service
```

---

## Restart kiosk

```bash
systemctl restart kiosk.service
```

---

## View logs

```bash
journalctl -u kiosk.service -n 50 --no-pager
```

---

# 7. Full Automatic Installer Script

Save this as:

```text
kiosk_with_weblogin.sh
```

```bash
#!/bin/bash

set -e

KIOSK_URL="https://pal.be"
USERNAME="homeassistant"
PASSWORD="homeassistant"

echo "======================================"
echo " Armbian HDMI Kiosk Installer"
echo "======================================"

echo ""
echo "Updating packages..."
apt update

echo ""
echo "Installing packages..."

apt install -y --no-install-recommends \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    openbox \
    chromium \
    unclutter \
    xdotool

echo ""
echo "Creating Openbox configuration..."

mkdir -p /root/.config/openbox

cat > /root/.config/openbox/autostart <<EOF
# Disable screen blanking and power saving
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor
unclutter -idle 1 -root &

# Start Chromium
chromium \\
  --no-sandbox \\
  --disable-gpu \\
  --disable-infobars \\
  --kiosk \\
  --app=$KIOSK_URL &

# Auto login script
/root/autologin.sh &
EOF

echo ""
echo "Creating autologin script..."

cat > /root/autologin.sh <<EOF
#!/bin/bash

sleep 15

xdotool type "$USERNAME"
xdotool key Tab
xdotool type "$PASSWORD"
xdotool key Return
EOF

chmod +x /root/autologin.sh

echo ""
echo "Creating systemd service..."

cat > /etc/systemd/system/kiosk.service <<EOF
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
EOF

echo ""
echo "Enabling kiosk service..."

systemctl daemon-reload
systemctl enable kiosk.service
systemctl restart kiosk.service

echo ""
echo "======================================"
echo " INSTALLATION COMPLETE"
echo "======================================"
echo ""
echo "Kiosk URL: $KIOSK_URL"
echo ""
echo "Useful commands:"
echo "  systemctl stop kiosk.service"
echo "  systemctl restart kiosk.service"
echo "  journalctl -u kiosk.service -n 50 --no-pager"
echo ""
```

---

# 8. GitHub One-Line Installer

After uploading `kiosk_with_weblogin.sh` to GitHub:

```bash
bash <(curl -s https://raw.githubusercontent.com/v12345vtm/OrangePi-one-Kiosk/main/kiosk_with_weblogin.sh)
```

---

# Security Notice

The credentials are stored in plaintext inside:

```text
/root/kiosk_with_weblogin.sh
```

Only use this on:
- trusted local networks
- private dashboards
- isolated kiosk devices

Do NOT expose this kiosk publicly to the internet.

---
