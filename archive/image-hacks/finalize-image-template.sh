#!/bin/bash
# HISTORICAL TEMPLATE: the nftables removal below is obsolete. The current fix enables
# nftables and adds /etc/nftables.d/60_lmi.nft; see runtime/60_lmi.nft.
set -e
UUID=$(python3 -c 'import uuid; print(uuid.uuid4())')
CONF=/mnt/lmi-root/etc/NetworkManager/system-connections/<ssid>.nmconnection
mkdir -p /mnt/lmi-root/etc/NetworkManager/system-connections
cat > "$CONF" <<EOF
[connection]
id=<ssid>
uuid=$UUID
type=wifi
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=<ssid>

[wifi-security]
key-mgmt=wpa-psk
psk=<wifi-password>

[ipv4]
method=auto

[ipv6]
method=auto
EOF
chmod 600 "$CONF"

# Debug image: do not let nftables block SSH
rm -f /mnt/lmi-root/etc/runlevels/default/nftables

echo "=== profile ==="
cat "$CONF"
echo "=== sshd default ==="
ls -l /mnt/lmi-root/etc/runlevels/default/sshd 2>&1 || true

sync
umount /mnt/lmi-root/proc 2>/dev/null || true
umount /mnt/lmi-root/dev 2>/dev/null || true
umount /mnt/lmi-root/sys 2>/dev/null || true
umount /mnt/lmi-root 2>/dev/null || true
losetup -d /dev/loop2 2>/dev/null || true

echo "=== repack sparse ==="
img2simg /tmp/xiaomi-lmi.raw ./out/xiaomi-lmi-fixed.img
ls -lh ./out/xiaomi-lmi-fixed.img
file ./out/xiaomi-lmi-fixed.img
sha256sum ./out/xiaomi-lmi-fixed.img
