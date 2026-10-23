#!/bin/sh
echo "=== gtk ==="
ldd /usr/libexec/phosh 2>/dev/null | grep -E 'gtk|gdk'
echo "=== gresource ==="
gresource list /usr/libexec/phosh 2>/dev/null | head -30
gresource extract /usr/libexec/phosh /sm/puri/phosh/style.css 2>/dev/null > /tmp/phosh-style.css
wc -l /tmp/phosh-style.css 2>/dev/null
grep -nE 'top-panel|status-bar|panel|margin|padding' /tmp/phosh-style.css 2>/dev/null | head -60
echo "=== schemas ==="
gsettings list-recursively sm.puri.phosh 2>/dev/null | head -60
echo "=== user config ==="
ls -la /home/user/.config 2>/dev/null | head -20
ls -la /home/user/.config/gtk-3.0 /home/user/.config/gtk-4.0 2>/dev/null
echo "=== css files ==="
find /usr/share -name '*.css' 2>/dev/null | grep -i phosh | head
