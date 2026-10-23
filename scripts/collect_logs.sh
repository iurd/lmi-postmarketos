#!/bin/sh
echo "=== uname ==="
uname -a
echo "=== user home ==="
ls -la /home/user
echo "=== xsession-errors ==="
tail -120 /home/user/.xsession-errors 2>/dev/null
echo "=== user logs ==="
find /home/user -maxdepth 4 -type f \( -iname '*.log' -o -iname '*session*' -o -iname '*error*' \) 2>/dev/null | head -40
echo "=== gdm cache ==="
ls -la /home/user/.cache/gdm 2>/dev/null
tail -120 /home/user/.cache/gdm/session.log 2>/dev/null
echo "=== local state ==="
find /home/user/.local/state -maxdepth 3 -type f 2>/dev/null | head -30
echo "=== var log ==="
ls -la /var/log
tail -80 /var/log/messages 2>/dev/null
echo "=== greetd config ==="
cat /etc/greetd/config.toml 2>/dev/null
echo "=== sessions ==="
ls /usr/share/wayland-sessions /usr/share/xsessions 2>/dev/null
cat /usr/share/wayland-sessions/*.desktop 2>/dev/null
echo "=== packages ==="
apk info -v 2>/dev/null | grep -E '^(phosh|gnome|mutter|greetd|phoc|postmarketos-ui)' | sort
echo "=== dmesg errors ==="
dmesg | grep -iE 'drm|msm|freedreno|kgsl|gpu|panel|error|fail|phosh|gnome|segfault' | tail -100
