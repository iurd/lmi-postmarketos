# scripts/

Helper scripts used during the port. They are provided for reference; review paths and device names before running.

| Script | Purpose |
|---|---|
| `setup_pmbootstrap.py` | Prepare pmbootstrap / pmaports for the lmi build |
| `fix_config_and_mirror.py` | Merge the kernel config and switch to the TUNA Alpine mirror |
| `add_kernel_hash.py` | Add the kernel tarball hash to the APKBUILD |
| `pmbootstrap_lax_deps.py` | Local strict-mode workaround for pmbootstrap 3.12 |
| `mount_image.sh` | Mount the sparse rootfs image in WSL (loop offset) |
| `add_sshd_server.sh` | Offline-install `openssh-server` into an image |
| `collect_logs.sh` | Collect display/session/package logs from the device |
| `inspect_bootimg.py` | Inspect an Android boot image header/DTB |
| `make_debug_bootimg.py` | Build a debug boot image variant |
| `inspect_display.sh` | Read DRM/panel/backlight state |

Placeholders such as `<serial>`, `<ssid>`, `<wifi-password>` and `<device-ip>` must be filled locally. Do not commit real credentials.
