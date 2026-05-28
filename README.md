# HomeBox Scanner Kiosk

Turn an **NVIDIA Jetson Nano 2GB Developer Kit** into a dedicated HomeBox field/scanner kiosk appliance that boots straight into the HomeBox scanner UI.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Jetson%20Nano%202GB-green)
![OS](https://img.shields.io/badge/OS-L4T%20Ubuntu%2018.04-orange)

## 🎯 What It Does

- Boots directly to `https://homebox.home.arpa:30022/field/` — the HomeBox scanner interface
- Normal Chromium browser with tabs, address bar, and window management
- Right-click desktop menu with **Terminal**, **Chromium (new window)**, and **Display & Scaling** controls
- Auto-detects and reconnects WiFi if it drops
- Persists display scaling across reboots
- No login required — autologin to tty1 as `kiosk` user

## 📸 Screenshot

```
┌─────────────────────────────────────────────────┐
│  Chromium — https://homebox.home.arpa:30022/   │
│ ┌─────────────────────────────────────────────┐ │
│ │                                             │ │
│ │        HomeBox Scanner Interface            │ │
│ │                                             │ │
│ │  [Scan Item]  [Search]  [Recent Items]      │ │
│ │                                             │ │
│ │         Right-click → Display & Scaling     │ │
│ │                        ARandR GUI            │ │
│ │                        LXAppearance          │ │
│ │                        Scale 105%/110%/...   │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## ⚡ Quick Start

### 1. Flash the SD Card

**On your Linux host:**

```bash
# Download official JetPack 4.6.1 / L4T 32.7.1 image for Jetson Nano 2GB
wget https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/jp_4.6.1_b110_sd_card/jetson_nano_2gb/jetson-nano-2gb-jp461-sd-card-image.zip

# Insert microSD, identify target (e.g. /dev/sda)
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,RM,TYPE,MOUNTPOINTS

# Flash (adjust /dev/sdX to your target)
sudo umount /dev/sdX* 2>/dev/null || true
unzip -p jetson-nano-2gb-jp461-sd-card-image.zip sd-blob.img | sudo dd of=/dev/sdX bs=16M status=progress conv=fsync
sync
```

Or use the safe flash script:

```bash
chmod +x flash/flash-jetson-nano-2gb-to-sda.sh
sudo ./flash/flash-jetson-nano-2gb-to-sda.sh
```

> **Important:** The safe flash script validates the target is removable, refuses system disks, and requires you to type `FLASH` to confirm.

### 2. First Boot — Complete Ubuntu Setup

1. Insert the microSD into the Jetson Nano 2GB
2. Connect power, HDMI, and Ethernet (or WiFi)
3. Complete the first-boot Ubuntu setup (initial username/password)
4. Connect to WiFi if not using Ethernet
5. Grab the Jetson's IP: `ip -brief a`

### 3. SSH In and Run the Kiosk Setup

```bash
ssh <user>@<jetson-ip>
# Upload and run the setup script
scp scripts/setup-homebox-field-kiosk.sh <user>@<jetson-ip>:/home/<user>/
ssh -t <user>@<jetson-ip> 'chmod +x setup-homebox-field-kiosk.sh && sudo ./setup-homebox-field-kiosk.sh'

# After setup completes:
sudo reboot
```

### 4. Post-Setup (optional)

```bash
# Switch to browser mode (tabs, address bar — not fullscreen kiosk)
ssh -t <user>@<jetson-ip> 'sudo ./make-browser-mode.sh && sudo systemctl restart getty@tty1.service'

# Install GUI settings + display scaling presets
ssh -t <user>@<jetson-ip> 'sudo ./add-gui-settings.sh && sudo systemctl restart getty@tty1.service'

# Install WiFi stability watchdog
ssh -t <user>@<jetson-ip> 'sudo ./fix-jetson-stability.sh && sudo systemctl restart getty@tty1.service'
```

## 📁 Repository Structure

```
.
├── README.md                         # This file
├── LICENSE                           # MIT License
│
├── flash/
│   ├── flash-instructions.md         # Detailed SD card flashing guide
│   └── flash-jetson-nano-2gb-to-sda.sh  # Safe flash helper
│
├── scripts/
│   ├── setup-homebox-field-kiosk.sh  # Full kiosk provisioning (Phase 3)
│   ├── make-browser-mode.sh          # Switch from kiosk → browser mode
│   ├── add-gui-settings.sh           # GUI settings + Display & Scaling menu
│   ├── fix-jetson-stability.sh       # WiFi watchdog + right-click menu + xterm
│   └── rewrite-menu.sh               # Clean openbox menu rewrite
│
└── files/
    ├── start-homebox-kiosk.sh        # Kiosk Chromium launcher (browser mode)
    ├── menu.xml                      # Openbox right-click menu config
    ├── kiosk-scale                   # Display scaling helper script
    ├── wifi-watchdog.service         # Systemd oneshot service
    ├── wifi-watchdog.timer           # Systemd timer (every 5 minutes)
    └── autologin.conf                # systemd getty drop-in for tty1 autologin
```

## 🧰 How It Works

### Boot Sequence

1. Power on → U-Boot → Linux 4.9-tegra
2. `systemd` starts `getty@tty1.service` with autologin for `kiosk` user
3. `~/.bash_profile` detects tty1 and runs `startx`
4. `.xinitrc` starts Openbox window manager, then the Chromium launcher
5. Chromium opens `https://homebox.home.arpa:30022/field/`

### Display Scaling

Scaling uses `xrandr --scale`. The `kiosk-scale` helper auto-detects the connected HDMI output (`HDMI-0`, `HDMI-1`, etc.) and applies the scale factor. Previous scale is saved to `~/.config/kiosk-scale` for persistence.

Right-click → **Display & Scaling** → choose from 80% to 150% in 5% increments.

### WiFi Stability

The wifi-watchdog timer runs `/usr/local/bin/wifi-watchdog.sh` every 5 minutes. It checks:
1. Does `wlan0` have an IPv4 address? → if not, restarts networking
2. Is the gateway (192.168.1.1) reachable? → if not, restarts wpa_supplicant

### User Accounts

| User  | Role            | Password    |
|-------|-----------------|-------------|
| kiosk | Appliance user  | (autologin) |
| jetson | Admin (SSH)    | *set during first boot* |

Use `Ctrl+Alt+F2` to switch to tty2 for an admin shell as `jetson`.

## 🖱️ Right-Click Menu

| Menu Item               | Action                                      |
|-------------------------|---------------------------------------------|
| Terminal (xterm)        | Opens a terminal window                     |
| Chromium (new window)   | Opens another browser window                |
| ARandR                  | GUI for display layout / resolution / scale |
| LXAppearance            | Font, theme, and cursor size settings       |
| Scale presets (5% steps)| Immediate xrandr scaling (80%–150%)         |
| Reload Openbox          | Re-read openbox config at runtime           |
| Log Out Kiosk           | Exit X session, return to tty1 login prompt |

## 🔒 Certificate Trust

Chromium currently launches with `--ignore-certificate-errors` because the internal HomeBox certificate is not trusted. To remove that flag:

```bash
# Install your root CA
sudo cp your-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Remove --ignore-certificate-errors from the launcher
sudo sed -i 's/ --ignore-certificate-errors//' /home/kiosk/start-homebox-kiosk.sh
sudo systemctl restart getty@tty1.service
```

## 🐞 Troubleshooting

**Chromium won't start after boot:**
```bash
# Check tty1 autologin
systemctl status getty@tty1.service --no-pager -l

# Check auth file
ls -la /tmp/serverauth.*
# ps aux | grep -E 'Xorg|openbox|chromium'

# Check DNS resolution
getent hosts homebox.home.arpa

# Check launcher script
cat /home/kiosk/start-homebox-kiosk.sh
```

**WiFi keeps dropping:**
```bash
systemctl status wifi-watchdog.timer --no-pager -l
journalctl -u wifi-watchdog.service
```

**Need to reset scaling:**
```bash
kiosk-scale 1.00
```

**Display not detected correctly:**
```bash
# Launch ARandR from right-click menu
# Or use xrandr directly
xrandr
xrandr --output HDMI-0 --mode 1280x720
```

## 📋 Requirements

- **Hardware:** NVIDIA Jetson Nano 2GB Developer Kit (B01 or earlier)
- **Storage:** 32GB+ microSD (16GB minimum, 32GB recommended)
- **Display:** HDMI monitor with at least 1280x720 resolution
- **Networking:** Ethernet or WiFi
- **Base OS:** JetPack 4.6.1 / L4T 32.7.1 (Ubuntu 18.04)

## 🧪 Tested On

| Component               | Version / Model         |
|-------------------------|-------------------------|
| Jetson Nano 2GB         | L4T R32.7.6             |
| Kernel                  | 4.9.337-tegra           |
| Chromium                | 112.0.5615.49           |
| Openbox                 | 3.6.1                   |
| X.Org                   | 7.7 + 1.20              |
| HomeBox                 | v0.x (self-hosted)      |

## 📝 License

MIT — see [LICENSE](LICENSE)
