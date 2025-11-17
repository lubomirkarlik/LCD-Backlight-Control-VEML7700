# LCD Backlight Auto-Control for Volumio or other similar embedded systems.

Automatic brightness control for 7" DPI LCD display using VEML7700 light sensor on Raspberry Pi 3B+ with Volumio.

![GitHub](https://img.shields.io/badge/license-GPL%20v2-blue.svg)
![Python](https://img.shields.io/badge/python-3.x-blue.svg)
![Raspberry Pi](https://img.shields.io/badge/platform-Raspberry%20Pi%203B%2B-red.svg)

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
- ⚙️ **Configurable parameters** via external files
- 🔄 **Auto-start** at boot via systemd service
- 📊 **Real-time monitoring** with detailed logging

## 🔧 Hardware Components

| Component | Model/Type | Description |
|-----------|------------|-------------|
| **Main Unit** | Raspberry Pi 3B+ | Control unit |
| **Display** | 7" LCD DPI (OFI009) | Touch display connected via DPI interface |
| **Audio** | HiFiBerry AMP2 | Amplifier for speakers |
| **Enclosure** | Gainta G17083UBK | Protective case |
| **24V Power Supply** | ZDR1231 | Power supply for amplifier |
| **5.1V Power Supply** | ZDR577 (adjustable) | Main power supply for RPi |
| **Encoder** | KY-040 | Rotary encoder for volume control |
| **Light Sensor** | VEML7700 (BH-014PA) | 16-bit I2C ambient light sensor |
| **Speaker Connector** | VG09103 | Output connector |
| **Power Connector** | KAB2423 | With switch and fuse |

## 💿 Software Requirements

- **OS**: Linux based system as is Raspi, Armbian, VolumioOS...
- **Python**: 3.x
- **Python Libraries**:
  - `RPi.GPIO`
  - `smbus`
  - `schedule`

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

### Step 1: Prepare SD Card

Use **Balena Etcher** to flash Volumio image:

```bash
Volumio-3.832-2025-07-26-pi.zip
```

### Step 2: Configure APT Repository

After first boot, edit APT sources:

```bash
sudo nano /etc/apt/sources.list
```

Replace content with:

```
deb http://archive.raspbian.org/raspbian/ buster main contrib non-free rpi
```

### Step 3: Basic Volumio Setup

1. Complete Volumio web interface setup
2. Install plugins:
   - **Touch Display** (disable Sleep Mode)
   - **Now Playing**
   - **Rotary Encoder** (configure with BCM pin numbers)
3. Enable SSH: `http://volumio.local/dev`

### Step 4: Install System Dependencies

```bash
sudo apt update
sudo apt upgrade
sudo apt install python3-pip i2c-tools
```

### Step 5: Install Python Libraries

```bash
sudo pip3 install adafruit-circuitpython-veml7700
sudo pip3 install RPi.GPIO
sudo pip3 install smbus
sudo pip3 install schedule
```

### Step 6: Verify I2C Sensor

```bash
i2cdetect -y 1
```

Expected output (sensor at address 0x10):

```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
```

### Step 7: Create Python Script

Create `/home/volumio/backlight_control.py`:

```bash
nano /home/volumio/backlight_control.py
```

Paste the script content (see `backlight_control.py` in this repository).

Set permissions:

```bash
chmod +x /home/volumio/backlight_control.py
```

### Step 8: Create Systemd Service

```bash
sudo nano /etc/systemd/system/backlight.service
```

Content:

```ini
[Unit]
Description=Backlight Control Service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/volumio/backlight_control.py
WorkingDirectory=/home/volumio
User=volumio
Group=volumio
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Step 9: Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable backlight.service
sudo systemctl start backlight.service
```

### Step 10: Verify Service Status

```bash
sudo systemctl status backlight.service
```

Monitor logs in real-time:

```bash
sudo journalctl -u backlight.service -f
```

## ⚙️ Configuration

### Configuration Files Location

Create configuration directory:

```bash
sudo mkdir -p /etc/lcd_backlight
```

### Available Configuration Parameters

#### Minimum Brightness (0-255)

```bash
echo "12" | sudo tee /etc/lcd_backlight/lcd_min_backlight
```

#### Maximum Brightness (0-255)

```bash
echo "255" | sudo tee /etc/lcd_backlight/lcd_max_backlight
```

#### Measurement Interval (seconds)

```bash
echo "1" | sudo tee /etc/lcd_backlight/lcd_int_time
```

#### Lux Multiplier (calibration)

```bash
echo "0.75" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier
```

#### Smoothing Factor (0.0-1.0)

Lower values = smoother transitions

```bash
echo "0.3" | sudo tee /etc/lcd_backlight/lcd_smoothing_factor
```

### Apply Configuration Changes

```bash
sudo systemctl restart backlight.service
```

### Default Values

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MIN_BACKLIGHT` | 12 | Minimum brightness (dark) |
| `MAX_BACKLIGHT` | 255 | Maximum brightness (bright) |
| `INT_TIME` | 1 | Measurement interval (sec) |
| `LUX_MULTIPLIER` | 0.75 | Lux calibration coefficient |
| `SMOOTHING_FACTOR` | 0.3 | Transition smoothing |

## 🎯 Usage

### Automatic Operation

The service starts automatically at boot and runs continuously.

### Manual Service Control

```bash
# Check status
sudo systemctl status backlight.service

# Stop service
sudo systemctl stop backlight.service

# Start service
sudo systemctl start backlight.service

# Restart service
sudo systemctl restart backlight.service

# Disable auto-start
sudo systemctl disable backlight.service

# Enable auto-start
sudo systemctl enable backlight.service
```

### View Logs

```bash
# Last 50 entries
sudo journalctl -u backlight.service -n 50

# Follow in real-time
sudo journalctl -u backlight.service -f

# Today's logs only
sudo journalctl -u backlight.service --since today
```

### Log Output Example

```
[12:34:56] Lux:  245.3 | Brightness: 145/255
[12:34:57] Lux:  248.1 | Brightness: 147/255
[12:34:58] Lux:  251.7 | Brightness: 149/255
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
sudo journalctl -u backlight.service -n 50 --no-pager
```

**Verify Python dependencies:**

```bash
python3 -c "import adafruit_veml7700; print('VEML7700: OK')"
python3 -c "import RPi.GPIO; print('GPIO: OK')"
python3 -c "import smbus; print('SMBus: OK')"
```

**Check script syntax:**

```bash
python3 -m py_compile /home/volumio/backlight_control.py
```

### Display Doesn't Change Brightness

**Verify backlight device exists:**

```bash
ls -la /sys/class/backlight/*/brightness
```

**Test manual brightness control:**

```bash
echo 128 | sudo tee /sys/class/backlight/*/brightness
echo 255 | sudo tee /sys/class/backlight/*/brightness
```

**Check file permissions:**

```bash
ls -la /home/volumio/backlight_control.py
# Should be: -rwxr-xr-x (executable)
```

### Brightness Too Sensitive

Increase smoothing factor:

```bash
echo "0.5" | sudo tee /etc/lcd_backlight/lcd_smoothing_factor
sudo systemctl restart backlight.service
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

**Apply changes:**

```bash
sudo systemctl restart backlight.service
```

### Sensor Readings Seem Wrong

Calibrate lux multiplier:

```bash
# For higher sensitivity
echo "1.0" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier

# For lower sensitivity
echo "0.5" | sudo tee /etc/lcd_backlight/lcd_lux_multiplier

sudo systemctl restart backlight.service
```

## 📊 Monitoring

### Real-Time Monitoring

```bash
# Watch brightness changes
sudo journalctl -u backlight.service -f
```

### Performance Statistics

```bash
# Service uptime and status
sudo systemctl status backlight.service

# Recent logs with timestamps
sudo journalctl -u backlight.service -n 100 --no-pager
```

## 🛠️ Advanced Configuration

### Custom Brightness Curve

Edit `/home/volumio/backlight_control.py` and modify the `_lux_to_brightness()` method to implement custom brightness curves.

### Multiple Sensors

The script can be extended to support multiple VEML7700 sensors for different zones.

## 📝 Files Structure

```
/home/volumio/
└── backlight_control.py          # Main Python script

/etc/systemd/system/
└── backlight.service              # Systemd service file

/etc/lcd_backlight/
├── lcd_min_backlight              # Minimum brightness value
├── lcd_max_backlight              # Maximum brightness value
├── lcd_int_time                   # Measurement interval
├── lcd_lux_multiplier             # Lux calibration
└── lcd_smoothing_factor           # Smoothing factor
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open-source and available under the GPL-2.0 License.

## 👤 Author

**lubomirkarlik60@gmail.com**

## 📅 Changelog

### Version 1.0.0 (November 2025)
- Initial release
- VEML7700 sensor support
- Logarithmic brightness curve
- Configurable parameters
- Systemd service integration

## 🔗 Related Projects

- [Volumio](https://volumio.com/) - Audiophile music player
- [HiFiBerry](https://www.hifiberry.com/) - High-quality audio for Raspberry Pi

## 📧 Support

For questions, issues, or feature requests, please create an issue in this repository.

---

**Last Updated**: November 2025  
**Compatible with**: Volumio 3.x, Raspberry Pi 3B+, Python 3.x