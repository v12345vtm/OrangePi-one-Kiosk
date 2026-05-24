#!/bin/bash

set -e

KIOSK_URL="http://192.168.1.64:1880/endpoint/ui"
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

sleep 60

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
