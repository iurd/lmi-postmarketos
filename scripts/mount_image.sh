#!/bin/bash
set -e
IMG=${IMG:-./out/xiaomi-lmi.img}
RAW=/tmp/xiaomi-lmi.raw
rm -f "$RAW"
simg2img "$IMG" "$RAW"
ls -lh "$RAW"
LOOP=$(losetup -fP --show "$RAW")
echo "loop=$LOOP"
lsblk "$LOOP"
mkdir -p /mnt/lmi-root
mount "${LOOP}p2" /mnt/lmi-root
echo "mounted ${LOOP}p2 -> /mnt/lmi-root"
ls /mnt/lmi-root | head -20
cat /mnt/lmi-root/etc/os-release | head -3
