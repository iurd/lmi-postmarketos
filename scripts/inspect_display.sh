#!/bin/sh
echo "=== processes ==="
ps aux | grep -E 'phosh|phoc|gnome-session|squeekboard' | grep -v grep
echo "=== phoc config ==="
ls -l /etc/phosh /usr/share/phosh 2>/dev/null
echo "--- /usr/share/phosh/phoc.ini ---"
cat /usr/share/phosh/phoc.ini 2>/dev/null
echo "--- /etc/phosh/phoc.ini ---"
cat /etc/phosh/phoc.ini 2>/dev/null
echo "=== phoc env ==="
pid=$(pgrep -x phoc | head -1)
echo "pid=$pid"
tr '\0' '\n' < /proc/$pid/environ 2>/dev/null | grep -E 'WAYLAND|XDG_RUNTIME|DISPLAY|GDK|SCALE'
echo "=== wlr-randr ==="
uid=$(id -u user)
export XDG_RUNTIME_DIR=/run/user/$uid
export WAYLAND_DISPLAY=wayland-0
wlr-randr 2>&1 || true
echo "=== gsettings ==="
su - user -c 'export XDG_RUNTIME_DIR=/run/user/$(id -u); export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus; gsettings get org.gnome.desktop.interface text-scaling-factor 2>&1; gsettings get org.gnome.desktop.interface scaling-factor 2>&1' 2>&1
echo "=== packages ==="
apk info -e phosh-mobile-settings wlr-randr 2>&1
echo "=== display drm ==="
cat /sys/class/drm/card0-DSI-1/status 2>/dev/null
cat /sys/class/drm/card0-DSI-1/modes 2>/dev/null | head -3
