#!/bin/bash
# LCD Backlight Control (VEML7700) - standalone uninstallation
# Run as root: sudo ./uninstall.sh

SERVICE_NAME="lcd_backlight.service"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root: sudo $0" >&2
    exit 1
fi

echo "Uninstalling LCD Backlight Control..."

# Stop the service (the script restores full brightness on stop) and disable autostart
echo "Stopping and disabling service..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

echo "Removing systemd service..."
rm -f "/etc/systemd/system/$SERVICE_NAME"

echo "Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed "$SERVICE_NAME" 2>/dev/null || true

echo "Removing Python script..."
rm -f /usr/local/bin/backlight_control.py

echo "Removing configuration directory /etc/lcd_backlight..."
rm -rf /etc/lcd_backlight

echo "Uninstallation complete!"

exit 0
