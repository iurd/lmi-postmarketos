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

echo "=== install openssh-server ==="
chroot /mnt/lmi-root /bin/sh -c 'apk update; apk add openssh-server || apk add openssh; ssh-keygen -A; command -v sshd; ls -l /usr/sbin/sshd'

echo "=== local start script ==="
cat > /mnt/lmi-root/etc/local.d/10-sshd.start <<'EOF'
#!/bin/sh
[ -x /usr/sbin/sshd ] || exit 0
[ -f /etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -A
rc-service sshd restart 2>/dev/null || true
EOF
chmod +x /mnt/lmi-root/etc/local.d/10-sshd.start
ls -l /mnt/lmi-root/etc/local.d/10-sshd.start

sync
umount /mnt/lmi-root/proc 2>/dev/null || true
umount /mnt/lmi-root/dev 2>/dev/null || true
umount /mnt/lmi-root/sys 2>/dev/null || true
umount /mnt/lmi-root 2>/dev/null || true
losetup -d /dev/loop2 2>/dev/null || true

echo "=== repack fixed2 ==="
img2simg /tmp/xiaomi-lmi.raw ./out/xiaomi-lmi-fixed2.img
ls -lh ./out/xiaomi-lmi-fixed2.img
sha256sum ./out/xiaomi-lmi-fixed2.img
