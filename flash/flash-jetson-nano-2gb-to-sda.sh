#!/usr/bin/env bash
set -euo pipefail
TARGET=/dev/sda
IMAGE_ZIP=/home/corey/Downloads/jetson-nano-2gb/jetson-nano-2gb-jp461-sd-card-image.zip
IMAGE_IN_ZIP=sd-blob.img

echo "==> Final safety check for ${TARGET}"
[ -b "$TARGET" ] || { echo "ERROR: $TARGET is not a block device" >&2; exit 1; }
rm=$(lsblk -dn -o RM "$TARGET" | tr -d ' ')
type=$(lsblk -dn -o TYPE "$TARGET" | tr -d ' ')
tran=$(lsblk -dn -o TRAN "$TARGET" | tr -d ' ')
if [ "$rm" != "1" ] || [ "$type" != "disk" ]; then
  echo "ERROR: refusing: $TARGET is not a removable disk (RM=$rm TYPE=$type TRAN=$tran)" >&2
  exit 1
fi
if lsblk -nr -o MOUNTPOINTS "$TARGET" | grep -Eq '^/$|^/home$|^/boot|^/var|^\[SWAP\]'; then
  echo "ERROR: refusing: $TARGET has system/root/home/swap mountpoints" >&2
  lsblk -o NAME,PATH,SIZE,MODEL,TRAN,RM,TYPE,MOUNTPOINTS "$TARGET"
  exit 1
fi
[ -s "$IMAGE_ZIP" ] || { echo "ERROR: missing image zip: $IMAGE_ZIP" >&2; exit 1; }

lsblk -o NAME,PATH,SIZE,MODEL,TRAN,RM,TYPE,MOUNTPOINTS "$TARGET"
echo
echo "About to overwrite ${TARGET} from the beginning with NVIDIA Jetson Nano 2GB JetPack 4.6.1 / L4T 32.7.1 image."
read -r -p "Type FLASH to continue: " answer
[ "$answer" = FLASH ] || { echo "Aborted."; exit 1; }

echo "==> Unmounting ${TARGET} partitions"
sudo umount /dev/sda* 2>/dev/null || true
sync

echo "==> Flashing ${IMAGE_ZIP}:${IMAGE_IN_ZIP} to ${TARGET}"
unzip -p "$IMAGE_ZIP" "$IMAGE_IN_ZIP" | sudo dd of="$TARGET" bs=16M status=progress conv=fsync
sync

echo "==> Ejecting ${TARGET}"
sudo eject "$TARGET" || true

echo "FLASH_COMPLETE: remove the microSD and insert it into the Jetson Nano 2GB."
