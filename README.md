# LCD Backlight Auto-Control for Volumio or other similar embedded systems.

Automatic brightness control for 7" DPI LCD display using VEML7700 light sensor on Raspberry Pi 3B+ with Volumio.

![GitHub](https://img.shields.io/badge/license-GPL%20v2-blue.svg)
![Python](https://img.shields.io/badge/python-3.x-blue.svg)
![Raspberry Pi](https://img.shields.io/badge/platform-Raspberry%20Pi%203B%2B-red.svg)

> **⚠️ Using Volumio?** On Volumio the recommended way is the Volumio plugin **`lcd_backlight`**
> ([volumio-plugins-sources-bookworm](https://github.com/lubomirkarlik/volumio-plugins-sources-bookworm/tree/lcd_backlight/lcd_backlight)).
> It contains the same control script, adds a settings page in the Volumio web UI and a brightness boost during playback.
>
> **Do NOT install the standalone version from this repository and the Volumio plugin together.**
> Both use the same systemd service name (`lcd_backlight.service`), the same script
> (`/usr/local/bin/backlight_control.py`) and the same configuration directory (`/etc/lcd_backlight`).
> If you switch from the standalone version to the plugin, run `sudo ./uninstall.sh` first.

## 📋 Table of Contents

- [Features](#features)
- [Hardware Components](#hardware-components)
- [Software Requirements](#software-requirements)
- [Wiring Diagram](#wiring-diagram)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## ✨ Features

- 🌞 **Automatic brightness adjustment** based on ambient light
- 📈 **Logarithmic brightness curve** for natural perception
- 🎚️ **Smooth transitions** to prevent flickering
- ⚙️ **Configurable parameters** via external files, applied without restart
- 🔄 **Auto-start** at boot via systemd service, automatic restart on failure
- 💡 **Full brightness restored** when the service is stopped or disabled
- 📊 **Logging** to the systemd journal

## 🔧 Hardware Components

| Component | Model/Type | Description |
|-----------|------------|-------------|
| **Main Unit** | Raspberry Pi 3B+ | Control unit |
| **Display** | 7" LCD DPI (OFI009) | Touch display connected via DPI interface |
| **Encoder** | KY-040 | Rotary encoder for volume control |
| **Light Sensor** | VEML7700 (BH-014PA) | 16-bit I2C ambient light sensor |

## 💿 Software Requirements

- **OS**: Linux based system as is Raspberry Pi OS, Armbian, VolumioOS... (with systemd)
- **Display**: backlight device in `/sys/class/backlight/`
- **I2C**: enabled I2C bus 1
- **Python**: 3.7 or newer
- **Python Libraries**:
  - `smbus` (Debian package `python3-smbus`, installed by `install.sh`)

## 🔌 Wiring Diagram

### I2C Bus (VEML7700 Sensor)

```
Raspberry Pi 3B+          VEML7700 (WL7700)
─────────────────         ──────────────────
Pin 1  (3.3V)    ──────── Pin 5 (+3.3V)
Pin 3  (GPIO 2)  ──────── Pin 2 (SDA)
Pin 5  (GPIO 3)  ──────── Pin 1 (SCL)
Pin 6  (GND)     ──────── Pin 4 (GND)
```

### GPIO Pinout Reference

```
+-----+-----+---------+------+---+---Pi 3B+-+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
|     |     |    3.3v |      |   |  1 || 2  |   |      | 5v      |     |     |
|   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5v      |     |     |
|   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      |     |     |
|   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | IN   | TxD     |  15 |  14 |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
```

### Rotary Encoder (KY-040)

- **CLK**: GPIO pin (BCM numbering from `gpio readall`)
- **DT**: GPIO pin (BCM numbering)
- **SW**: GPIO pin (button)
- **+**: 3.3V
- **GND**: Ground

> **Note**: Configure encoder pins in Volumio's Rotary Encoder plugin using **BCM** pin numbers.

### Display Connection

- **Power**: +5V and GND from connector X1
- **DPI Signals**: Connected according to `/boot/config.txt` DPI configuration

## 📦 Installation

> On Volumio use the Volumio plugin `lcd_backlight` instead (see the note at the top).

### Step 1: Enable I2C

```bash
sudo nano /boot/config.txt
# Add or uncomment:
dtparam=i2c_arm=on
```

Reboot after changes.

### Step 2: Verify I2C Sensor

```bash
sudo apt install i2c-tools
i2cdetect -y 1
```

Expected output (sensor at address 0x10):

```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
```

### Step 3: Install

```bash
git clone https://github.com/lubomirkarlik/LCD-Backlight-Control-VEML7700.git
cd LCD-Backlight-Control-VEML7700
sudo ./install.sh
```

`install.sh` (must be run as root):

- installs `python3-smbus` via apt (if `smbus` is not available yet)
- copies `backlight_control.py` to `/usr/local/bin/backlight_control.py`
- creates `/etc/lcd_backlight` with default configuration files (existing files are kept)
- copies the systemd unit `lcd_backlight.service` (included in this repository) to `/etc/systemd/system/`
- enables the service for auto-start at boot and starts it

### Step 4: Verify Service Status

```bash
sudo systemctl status lcd_backlight.service
```

Monitor logs in real-time:

```bash
sudo journalctl -u lcd_backlight.service -f
```

### Uninstallation

```bash
sudo ./uninstall.sh
```

Stops and disables the service (the display is set back to full brightness) and removes the service file,
`/usr/local/bin/backlight_control.py` and `/etc/lcd_backlight`.

### Systemd Service

The unit file `lcd_backlight.service` is part of this repository:

```ini
[Unit]
Description=LCD Backlight Control Service
After=network.target

[Service]
Type=simple
User=root
# -u: unbuffered output, so messages appear in the journal immediately
ExecStart=/usr/bin/python3 -u /usr/local/bin/backlight_control.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

If the sensor or the backlight device is not available at start, the script exits with an error
and systemd restarts it every 5 seconds.

## ⚙️ Configuration

### Configuration Files Location

The configuration directory `/etc/lcd_backlight` with default values is created by `install.sh`.
Each parameter is a separate file containing a single value. A missing file (or directory) means the default value.

Changes are detected automatically (file modification time) and applied within one measurement interval,
**no restart is needed**.

### Available Configuration Parameters

#### Enable/Disable Automatic Control (1/0)

When disabled, the display is set to full brightness and the service waits for re-enabling.

```bash
echo "0" | sudo tee /etc/lcd_backlight/lcd_enabled
```

#### Minimum Brightness (0-255)

```bash
echo "12" | sudo tee /etc/lcd_backlight/lcd_min_backlight
```

#### Maximum Brightness (0-255)

Values above the device `max_brightness` are limited to it.

```bash
echo "255" | sudo tee /etc/lcd_backlight/lcd_max_backlight
```

#### Measurement Interval (seconds, minimum 0.1)

```bash
echo "1" | sudo tee /etc/lcd_backlight/lcd_int_time
```

#### Lux Multiplier (calibration)

```bash
echo "0.75" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier
```

#### Smoothing Factor (0.05-1.0)

Lower values = smoother (slower) transitions, 1.0 = no smoothing

```bash
echo "0.3" | sudo tee /etc/lcd_backlight/lcd_smoothing_factor
```

#### Playback Boost (0-255) and Boost Duration (seconds)

Additional brightness while music is playing, kept for `lcd_playback_boost_duration` seconds after playback stops.
The playback state is read from `/etc/lcd_backlight/lcd_playing` (`1` = playing), which is written by the Volumio plugin.
The standalone version does not write this file, so without it there is no boost (keep `lcd_playback_boost` at `0`).

```bash
echo "0" | sudo tee /etc/lcd_backlight/lcd_playback_boost
echo "30" | sudo tee /etc/lcd_backlight/lcd_playback_boost_duration
```

### Default Values

| File | Default | Description |
|------|---------|-------------|
| `lcd_enabled` | 1 | Automatic control enabled |
| `lcd_min_backlight` | 12 | Minimum brightness (dark) |
| `lcd_max_backlight` | 255 | Maximum brightness (bright) |
| `lcd_int_time` | 1 | Measurement interval (sec) |
| `lcd_lux_multiplier` | 0.75 | Lux calibration coefficient |
| `lcd_smoothing_factor` | 0.3 | Transition smoothing |
| `lcd_playback_boost` | 0 | Brightness boost during playback |
| `lcd_playback_boost_duration` | 30 | Boost duration after playback stops (sec) |

## 🎯 Usage

### Automatic Operation

The service starts automatically at boot and runs continuously.

### Manual Service Control

```bash
# Check status
sudo systemctl status lcd_backlight.service

# Stop service (display is set to full brightness)
sudo systemctl stop lcd_backlight.service

# Start service
sudo systemctl start lcd_backlight.service

# Restart service
sudo systemctl restart lcd_backlight.service

# Disable auto-start
sudo systemctl disable lcd_backlight.service

# Enable auto-start
sudo systemctl enable lcd_backlight.service
```

### View Logs

```bash
# Last 50 entries
sudo journalctl -u lcd_backlight.service -n 50

# Follow in real-time
sudo journalctl -u lcd_backlight.service -f

# Today's logs only
sudo journalctl -u lcd_backlight.service --since today
```

### Log Output Example

Per-measurement output is disabled by default. To enable it, uncomment the two debug lines
(`boost_indicator = ...` and `log(...)`) at the end of `_update_brightness()` in `/usr/local/bin/backlight_control.py` and restart the service:

```
[12:34:56] Lux:    245.3 | Brightness: 145/255
[12:34:57] Lux:    248.1 | Brightness: 147/255
[12:34:58] Lux:    251.7 | Brightness: 149/255
```

## 🔍 Troubleshooting

### Sensor Not Detected

**Check I2C bus:**

```bash
i2cdetect -y 1
```

**Enable I2C interface:**

```bash
sudo nano /boot/config.txt
# Add or uncomment:
dtparam=i2c_arm=on
```

Reboot after changes.

### Service Fails to Start

**Check service logs:**

```bash
sudo journalctl -u lcd_backlight.service -n 50 --no-pager
```

**Verify Python dependencies:**

```bash
python3 -c "import smbus; print('SMBus: OK')"
```

**Check script syntax:**

```bash
python3 -m py_compile /usr/local/bin/backlight_control.py
```

### Display Doesn't Change Brightness

**Verify backlight device exists:**

```bash
ls -la /sys/class/backlight/*/brightness
cat /sys/class/backlight/*/max_brightness
```

**Test manual brightness control:**

```bash
echo 128 | sudo tee /sys/class/backlight/*/brightness
echo 255 | sudo tee /sys/class/backlight/*/brightness
```

**Check that automatic control is enabled:**

```bash
cat /etc/lcd_backlight/lcd_enabled
# Should be: 1
```

### Brightness Changes Too Fast / Flickers

Decrease smoothing factor:

```bash
echo "0.1" | sudo tee /etc/lcd_backlight/lcd_smoothing_factor
```

### Display Too Dark/Bright

**Adjust minimum brightness:**

```bash
echo "5" | sudo tee /etc/lcd_backlight/lcd_min_backlight
```

**Adjust maximum brightness:**

```bash
echo "200" | sudo tee /etc/lcd_backlight/lcd_max_backlight
```

### Sensor Readings Seem Wrong

Calibrate lux multiplier:

```bash
# For higher sensitivity
echo "1.0" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier

# For lower sensitivity
echo "0.5" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier
```

## 📊 Monitoring

### Real-Time Monitoring

```bash
# Watch service messages
sudo journalctl -u lcd_backlight.service -f
```

### Performance Statistics

```bash
# Service uptime and status
sudo systemctl status lcd_backlight.service

# Recent logs with timestamps
sudo journalctl -u lcd_backlight.service -n 100 --no-pager
```

## 🛠️ Advanced Configuration

### Custom Brightness Curve

Edit `/usr/local/bin/backlight_control.py` and modify the `_lux_to_brightness()` method to implement custom brightness curves,
then restart the service.

### Multiple Sensors

The script can be extended to support multiple VEML7700 sensors for different zones.

## 📝 Files Structure

Repository:

```
backlight_control.py               # Main Python script
lcd_backlight.service              # Systemd service file
install.sh                         # Installation script (sudo ./install.sh)
uninstall.sh                       # Uninstallation script (sudo ./uninstall.sh)
```

Installed files:

```
/usr/local/bin/
└── backlight_control.py           # Main Python script

/etc/systemd/system/
└── lcd_backlight.service          # Systemd service file

/etc/lcd_backlight/
├── lcd_enabled                    # Automatic control enabled (1/0)
├── lcd_min_backlight              # Minimum brightness value
├── lcd_max_backlight              # Maximum brightness value
├── lcd_int_time                   # Measurement interval
├── lcd_lux_multiplier             # Lux calibration
├── lcd_smoothing_factor           # Smoothing factor
├── lcd_playback_boost             # Brightness boost during playback
└── lcd_playback_boost_duration    # Boost duration after playback stops
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open-source and available under the GPL-2.0 License.You may use and modify it freely.  You may use the program as is at your own risk, no updates or modifications to the code will be made, no planed, and no warranties or claims for damages will be made in connection with any use of this code.

## 👤 Author

**lubomirkarlik60@gmail.com**

## 📅 Changelog

### Version 1.2.0 (November 2026)
- Same control script as the Volumio plugin `lcd_backlight` 1.2.0
- Smoothing converges to the target brightness (float smoothing)
- Brightness is kept on sensor read errors
- Brightness limited to the device `max_brightness`
- Full brightness restored when the service is stopped or disabled
- Exit with error on initialization failure, so systemd restarts the service
- Unbuffered log output to the journal
- Optional playback boost (`lcd_playback_boost`, `lcd_playback_boost_duration`)
- Added `lcd_backlight.service` to the repository
- Fixed `install.sh` and `uninstall.sh` (no pip install, default configuration files, no Volumio plugin directory)

### Version 1.0.0 (November 2025)
- Initial release
- VEML7700 sensor support
- Logarithmic brightness curve
- Configurable parameters
- Systemd service integration

## 🔗 Related Projects

- [Volumio plugin lcd_backlight](https://github.com/lubomirkarlik/volumio-plugins-sources-bookworm/tree/lcd_backlight/lcd_backlight) - the same control as a Volumio plugin (recommended on Volumio)
- [Volumio](https://volumio.com/) - Audiophile music player
- [HiFiBerry](https://www.hifiberry.com/) - High-quality audio for Raspberry Pi

## 📧 Support

For questions, issues, or feature requests, please create an issue in this repository.

---

**Last Updated**: November 2026  
**Compatible with**: Raspberry Pi 3B+, Raspberry Pi OS / Debian (buster, bullseye, bookworm), Python 3.7+
