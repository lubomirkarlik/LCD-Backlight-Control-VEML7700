#!/bin/bash
# LCD Backlight Control (VEML7700) - standalone installation
# Run as root: sudo ./install.sh

set -e

SERVICE_NAME="lcd_backlight.service"
SCRIPT_DEST="/usr/local/bin/backlight_control.py"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"
CONFIG_DIR="/etc/lcd_backlight"

# Resolve paths relative to this script, so it can be run from any directory
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root: sudo $0" >&2
    exit 1
fi

for f in backlight_control.py "$SERVICE_NAME"; do
    if [ ! -f "$SRC_DIR/$f" ]; then
        echo "Missing file: $SRC_DIR/$f" >&2
        exit 1
    fi
done

echo "Installing LCD Backlight Control..."

# Python dependencies (python3-smbus from apt; pip install fails on bookworm, PEP 668)
if command -v python3 >/dev/null 2>&1 && python3 -c "import smbus" 2>/dev/null; then
    echo "Dependencies already installed (python3, smbus)"
else
    echo "Installing dependencies..."
    apt-get update || echo "Warning: apt-get update failed, trying to install anyway"
    apt-get install -y python3 python3-smbus i2c-tools
fi

# Python script
echo "Installing Python script to $SCRIPT_DEST..."
install -m 755 "$SRC_DIR/backlight_control.py" "$SCRIPT_DEST"

# Configuration directory with default values (existing files are kept)
echo "Creating default configuration in $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
chmod 755 "$CONFIG_DIR"

write_default() {
    local file="$CONFIG_DIR/$1"
    if [ ! -f "$file" ]; then
        echo "$2" > "$file"
        chmod 644 "$file"
        echo "  $1 = $2"
    else
        echo "  $1 kept ($(cat "$file"))"
    fi
}

write_default lcd_enabled 1
write_default lcd_int_time 1
write_default lcd_min_backlight 12
write_default lcd_max_backlight 255
write_default lcd_lux_multiplier 0.75
write_default lcd_smoothing_factor 0.3
write_default lcd_playback_boost 0
write_default lcd_playback_boost_duration 30

# systemd service (copied, not symlinked)
echo "Installing systemd service to $SERVICE_DEST..."
install -m 644 "$SRC_DIR/$SERVICE_NAME" "$SERVICE_DEST"

echo "Reloading systemd daemon..."
systemctl daemon-reload

# Standalone version: start automatically at boot
echo "Enabling and starting service..."
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "Installation complete!"
echo "Status: systemctl status $SERVICE_NAME"
echo "Logs:   journalctl -u $SERVICE_NAME -f"

exit 0
