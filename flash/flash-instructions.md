# Flashing the Jetson Nano 2GB SD Card

This guide covers downloading the official NVIDIA JetPack 4.6.1 (L4T 32.7.1) SD card image and flashing it to a microSD card from a Linux host.

## Prerequisites

- **Linux host** with at least 14 GB free disk space
- **microSD card reader** (USB or built-in)
- **microSD card** (32 GB or larger recommended, 16 GB minimum)
- `wget`, `unzip`, `dd`, `sync` — standard packages

## Step 1: Identify Your Target Device

```bash
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,RM,TYPE,MOUNTPOINTS
```

Look for your microSD card — it should have `RM=1` (removable) and `TRAN=usb`. **Never flash your system disk** (look for mounts at `/`, `/home`, `/boot`).

## Step 2: Download the Image

```bash
mkdir -p ~/Downloads/jetson-nano-2gb
cd ~/Downloads/jetson-nano-2gb

# ~6.2 GB download
wget https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/jp_4.6.1_b110_sd_card/jetson_nano_2gb/jetson-nano-2gb-jp461-sd-card-image.zip
```

The zip contains a single file, `sd-blob.img` (~12.8 GB uncompressed).

## Step 3: Unmount Partitions

Replace `/dev/sdX` with your actual target device:

```bash
sudo umount /dev/sdX* 2>/dev/null || true
```

## Step 4: Flash the Image

```bash
cd ~/Downloads/jetson-nano-2gb
unzip -p jetson-nano-2gb-jp461-sd-card-image.zip sd-blob.img | sudo dd of=/dev/sdX bs=16M status=progress conv=fsync
sync
```

This takes **5–10 minutes** depending on write speed. The first boot will expand the root partition automatically.

## Step 5: Eject

```bash
sudo eject /dev/sdX
```

Remove the microSD and insert it into the Jetson Nano 2GB.

## Safe Flash Script

An automated version is included at `flash-jetson-nano-2gb-to-sda.sh`. It validates:
- The target is a removable block device
- The target does not have system/root/home mounts
- You type `FLASH` to confirm before writing

```bash
sudo ./flash-jetson-nano-2gb-to-sda.sh
```

## First Boot

1. Connect HDMI, Ethernet (optional), and power to the Jetson
2. Insert the microSD and boot
3. Complete the initial Ubuntu setup wizard:
   - Accept the EULA
   - Create an admin user (`jetson` recommended)
   - Set a password
   - Connect to WiFi if not using Ethernet
4. The Jetson will reboot — grab its IP:
   ```bash
   ip -brief a
   ```
5. You're ready for the [kiosk setup](../)!

## Troubleshooting

| Problem | Likely Fix |
|---------|------------|
| `dd` fails with "No space left" | Image is ~12.8 GB — your SD card may be too small (need 16 GB+) |
| `dd` hangs | Card reader may be slow. Try a USB 3.0 reader |
| Jetson boots to black screen | HDMI cable not seated; try reboot with HDMI already connected |
| "No boot device" | The image wasn't written correctly. Re-flash from scratch |
