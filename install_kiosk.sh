#!/bin/bash

set -e

echo "======================================"
echo " Armbian Chromium Kiosk Installer"
echo "======================================"

# Website to open
KIOSK_URL="https://pal.be"

echo ""
echo "Updating packages..."
apt update

echo ""
echo "Installing required packages..."
apt install -y --no-install-recommends \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    openbox \
    chromium \
    unclutter

echo ""
echo "Creating Openbox configuration..."

mkdir -p /root/.config/openbox

cat > /root/.config/openbox/autostart <<EOF
# Disable screen saver and power management blanking
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor after 1 second
unclutter -idle 1 -root &

# Launch Chromium in fullscreen kiosk mode
chromium --no-sandbox --noerrdialogs --disable-infobars --incognito --kiosk --disable-gpu "$KIOSK_URL" &
EOF

echo ""
echo "Creating systemd kiosk service..."

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
echo "Reloading systemd..."
systemctl daemon-reload

echo ""
echo "Enabling kiosk service..."
systemctl enable kiosk.service

echo ""
echo "Starting kiosk service..."
systemctl restart kiosk.service

echo ""
echo "======================================"
echo " Installation Complete"
echo "======================================"
echo ""
echo "Kiosk URL:"
echo "$KIOSK_URL"
echo ""
echo "Useful commands:"
echo "  Stop kiosk:    systemctl stop kiosk.service"
echo "  Restart kiosk: systemctl restart kiosk.service"
echo "  Logs:          journalctl -u kiosk.service -n 50 --no-pager"
echo ""
