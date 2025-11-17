# \# LCD Backlight Auto-Control for Volumio3 or other embedded system .

# 

# Automatic brightness control for 7" DSI LCD display using VEML7700 light sensor on Raspberry Pi 3B+ .

# 

# \## 📋 Table of Contents

# 

# \- \[Hardware Components](#hardware-components)

# \- \[Software](#software)

# \- \[Wiring Diagram](#wiring-diagram)

# \- \[Installation](#installation)

# \- \[Configuration](#configuration)

# \- \[Usage](#usage)

# \- \[Troubleshooting](#troubleshooting)

# 

# \## 🔧 Hardware Components

# 

# | Component | Model/Type | Description |

# |-----------|------------|-------------|

# | \*\*Main Unit\*\* | Raspberry Pi 3B+ | Control unit |

# | \*\*Display\*\* | 7" LCD DPI (OFI009) | Touch display connected via DPI interface |

# | \*\*Audio\*\* | HiFiBerry AMP2 | Amplifier for speakers |

# | \*\*Enclosure\*\* | Gainta G17083UBK | Protective case |

# | \*\*24V Power Supply\*\* | ZDR1231 | Power supply for amplifier |

# | \*\*5.1V Power Supply\*\* | ZDR577 (adjustable) | Main power supply for RPi |

# | \*\*Encoder\*\* | KY-040 | Rotary encoder for volume control |

# | \*\*Light Sensor\*\* | VEML7700 (BH-014PA) | 16-bit I2C ambient light sensor |

# | \*\*Speaker Connector\*\* | VG09103 | Output connector |

# | \*\*Power Connector\*\* | KAB2423 | With switch and fuse |

# 

# \## 💿 Software

# 

# \- \*\*OS\*\*: Linux type OS as is Raspbian, Volumio OS ...

# \- \*\*Programming Language\*\*: Python 3

# \- \*\*Libraries\*\*:

# &nbsp; - `RPi.GPIO`

# &nbsp; - `smbus`

# &nbsp; - `schedule`

# 

# \## 🔌 Wiring Diagram

# 

# \### Component Connections to Raspberry Pi 3B+

# 

# \#### I2C Bus (VEML7700 sensor):

# \- \*\*SDA\*\*: GPIO 2 (Physical pin 3, BCM 2) → WL7700 pin 2

# \- \*\*SCL\*\*: GPIO 3 (Physical pin 5, BCM 3) → WL7700 pin 1

# \- \*\*3.3V\*\*: Pin 1 → WL7700 pin 5

# \- \*\*GND\*\*: Pin 6 → WL7700 pin 4

# 

# \#### 7" Display:

# \- \*\*Power\*\*: +5V and GND from X1 connector

# \- \*\*DPI Signals\*\*: Connected according to DPI configuration in `/boot/config.txt`

# 

# > \*\*Note\*\*: Pin numbers in Rotary Encoder plugin use \*\*BCM\*\* numbering from the `gpio readall` table.

# 

# \### GPIO Pinout Reference

# 

# ```

# +-----+-----+---------+------+---+---Pi 3B+-+---+------+---------+-----+-----+

# | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |

# +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+

# |     |     |    3.3v |      |   |  1 || 2  |   |      | 5v      |     |     |

# |   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5v      |     |     |

# |   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      |     |     |

# |   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | IN   | TxD     |  15 |  14 |

# ```

# 

# \## 📦 Installation

# 

# \### 1. SD Card Preparation

# 

# Use \*\*Balena Etcher\*\* to install the OS image (in my case Volumio OS) to SD card:

# 

# ```bash

# \# Downloaded image

# Volumio-3.832-2025-07-26-pi.zip

# ```

# 

# \### 2. First Boot and APT Repository Configuration

# 

# After first boot, edit `/etc/apt/sources.list`:

# 

# ```bash

# sudo nano /etc/apt/sources.list

# ```

# 

# Change content to:

# 

# ```

# deb http://archive.raspbian.org/raspbian/ buster main contrib non-free rpi

# ```

# 

# \### 3. Basic Volumio Configuration

# 

# 1\. Complete basic Volumio setup via web interface

# 2\. Install \*\*Touch Display\*\* plugin

# 3\. Install \*\*Now Playing\*\* plugin

# 4\. Enable SSH access via `http://volumio.local/dev`

# 

# \### 4. Plugin Configuration

# 

# \#### Touch Display plugin:

# \- \*\*Disable Sleep Mode\*\* (to prevent automatic screen dimming)

# 

# \#### Rotary Encoder plugin:

# \- Enter pin numbers in \*\*BCM format\*\* (from `gpio readall` table)

# \- Configure GPIO pins according to your encoder wiring

# 

# \### 5. Dependencies Installation

# 

# Connect via SSH and install required packages:

# 

# ```bash

# sudo apt update

# sudo apt upgrade

# sudo apt install python3-pip i2c-tools

# 

# sudo pip3 install adafruit-circuitpython-veml7700

# sudo pip3 install RPi.GPIO

# sudo pip3 install smbus

# sudo pip3 install schedule

# ```

# 

# \### 6. I2C Sensor Verification

# 

# Check if VEML7700 sensor is detected:

# 

# ```bash

# i2cdetect -y 1

# ```

# 

# Output should display address `10` (0x10):

# 

# ```

# &nbsp;    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f

# 00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 

# 10: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

# ...

# ```

# 

# \### 7. Python Script Creation

# 

# Create file `/home/volumio/backlight\_control.py`:

# 

# ```bash

# nano /home/volumio/backlight\_control.py

# ```

# 

# Copy the content of the provided Python script and set permissions:

# 

# ```bash

# chmod +x /home/volumio/backlight\_control.py

# ```

# 

# \### 8. Systemd Service Creation

# 

# Create service file:

# 

# ```bash

# sudo nano /etc/systemd/system/backlight.service

# ```

# 

# Insert the following content:

# 

# ```ini

# \[Unit]

# Description=Backlight Control Service

# After=multi-user.target

# 

# \[Service]

# Type=simple

# ExecStart=/usr/bin/python3 /home/volumio/backlight\_control.py

# WorkingDirectory=/home/volumio

# User=volumio

# Group=volumio

# Restart=always

# RestartSec=5

# 

# \[Install]

# WantedBy=multi-user.target

# ```

# 

# \### 9. Service Activation

# 

# ```bash

# sudo systemctl daemon-reload

# sudo systemctl enable backlight.service

# sudo systemctl start backlight.service

# ```

# 

# \### 10. Service Status Check

# 

# ```bash

# sudo systemctl status backlight.service

# ```

# 

# For real-time log monitoring:

# 

# ```bash

# sudo journalctl -u backlight.service -f

# ```

# 

# \## ⚙️ Configuration

# 

# \### Configuration Files

# 

# The script loads configuration from `/etc/lcd\_backlight/` directory:

# 

# ```bash

# sudo mkdir -p /etc/lcd\_backlight

# ```

# 

# Create the following configuration files:

# 

# \#### Minimum display brightness (0-255):

# ```bash

# echo "12" | sudo tee /etc/lcd\_backlight/lcd\_min\_backlight

# ```

# 

# \#### Maximum display brightness (0-255):

# ```bash

# echo "255" | sudo tee /etc/lcd\_backlight/lcd\_max\_backlight

# ```

# 

# \#### Measurement interval (seconds):

# ```bash

# echo "1" | sudo tee /etc/lcd\_backlight/lcd\_int\_time

# ```

# 

# \#### Lux conversion multiplier:

# ```bash

# echo "0.75" | sudo tee /etc/lcd\_backlight/lcd\_lux\_multiplier

# ```

# 

# \#### Brightness change smoothing factor (0.0-1.0):

# ```bash

# echo "0.3" | sudo tee /etc/lcd\_backlight/lcd\_smoothing\_factor

# ```

# 

# > \*\*Note\*\*: After configuration changes, restart the service: `sudo systemctl restart backlight.service`

# 

# \### Script Parameters

# 

# | Parameter | Value | Description |

# |-----------|-------|-------------|

# | `MIN\_BACKLIGHT` | 12 | Minimum brightness (dark environment) |

# | `MAX\_BACKLIGHT` | 255 | Maximum brightness (bright environment) |

# | `SMOOTHING\_FACTOR` | 0.3 | Transition smoothing (lower = smoother) |

# | `INT\_TIME` | 1 | Measurement interval in seconds |

# | `LUX\_MULTIPLIER` | 0.75 | Calibration coefficient for lux conversion |

# 

# \## 🎯 Usage

# 

# After successful installation, the service starts automatically at boot.

# 

# \### Features

# 

# \- \*\*Automatic brightness control\*\*: Display adapts to ambient lighting

# \- \*\*Logarithmic curve\*\*: Natural perception of brightness changes

# \- \*\*Transition smoothing\*\*: Prevents flickering during light changes

# \- \*\*Persistent configuration\*\*: Settings remain after restart

# 

# \### Manual Service Control

# 

# ```bash

# \# Stop service

# sudo systemctl stop backlight.service

# 

# \# Start service

# sudo systemctl start backlight.service

# 

# \# Restart service

# sudo systemctl restart backlight.service

# 

# \# Disable automatic startup

# sudo systemctl disable backlight.service

# ```

# 

# \## 🔍 Troubleshooting

# 

# \### Sensor Not Detected

# 

# ```bash

# \# Check I2C bus

# i2cdetect -y 1

# 

# \# Check I2C interface in config.txt

# sudo nano /boot/config.txt

# \# Should contain: dtparam=i2c\_arm=on

# ```

# 

# \### Service Won't Start

# 

# ```bash

# \# Check logs

# sudo journalctl -u backlight.service -n 50

# 

# \# Check Python dependencies

# python3 -c "import adafruit\_veml7700; import RPi.GPIO; import smbus"

# ```

# 

# \### Display Doesn't Change Brightness

# 

# ```bash

# \# Check if backlight device exists

# ls -la /sys/class/backlight/\*/brightness

# 

# \# Manual brightness change test

# echo 128 | sudo tee /sys/class/backlight/\*/brightness

# ```

# 

# \### Brightness Changes Too Sensitive

# 

# Increase `SMOOTHING\_FACTOR` value in `/etc/lcd\_backlight/lcd\_smoothing\_factor`:

# 

# ```bash

# echo "0.5" | sudo tee /etc/lcd\_backlight/lcd\_smoothing\_factor

# sudo systemctl restart backlight.service

# ```

# 

# \### Display Too Dark/Bright

# 

# Adjust brightness range:

# 

# ```bash

# \# For darker minimum brightness

# echo "5" | sudo tee /etc/lcd\_backlight/lcd\_min\_backlight

# 

# \# For lower maximum brightness

# echo "200" | sudo tee /etc/lcd\_backlight/lcd\_max\_backlight

# 

# sudo systemctl restart backlight.service

# ```

# 

# \## 📊 Monitoring

# 

# \### Real-time Brightness Monitoring

# 

# ```bash

# \# Monitor logs showing Lux and Brightness values

# sudo journalctl -u backlight.service -f

# ```

# 

# Output displays:        

# '# Uncomment for debug'

# '# if success:'

# '#     print(f"\[{time.strftime('%H:%M:%S')}] Lux: {lux:6.1f} | Brightness: {self.current\_brightness:3d}/{self.max\_backlight}") '





# ```

# \[12:34:56] Lux:  245.3 | Brightness: 145/255

# \[12:34:57] Lux:  248.1 | Brightness: 147/255

# ```

# 

# \## 📝 License

# 

# This project is open-source and freely available for personal and commercial use.

# 

# \## 🤝 Support

# 

# For questions and issues, please create an issue in this repository.

# 

# ---

# 

# \*\*Created by\*\*: lubomirkarlik60@gmail.com  

# \*\*Last Updated\*\*: November 2025

