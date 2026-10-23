#!/bin/bash
set -e
umount /mnt/lmi-root 2>/dev/null || true
losetup -d /dev/loop1 2>/dev/null || true
losetup -d /dev/loop2 2>/dev/null || true
losetup -o 511705088 /dev/loop2 /tmp/xiaomi-lmi.raw
mount /dev/loop2 /mnt/lmi-root

mount --bind /proc /mnt/lmi-root/proc
mount --bind /dev /mnt/lmi-root/dev
mount --bind /sys /mnt/lmi-root/sys
cp /etc/resolv.conf /mnt/lmi-root/etc/resolv.conf

echo "=== chroot test ==="
chroot /mnt/lmi-root /bin/sh -c 'uname -m; apk --version'

echo "=== apk update ==="
chroot /mnt/lmi-root /bin/sh -c 'apk update'

echo "=== install android-tools ==="
chroot /mnt/lmi-root /bin/sh -c 'apk add android-tools' || true

echo "=== adbd presence ==="
chroot /mnt/lmi-root /bin/sh -c 'command -v adbd || true; apk info -L android-tools 2>/dev/null | grep -E "adbd|/adb$" || true'
