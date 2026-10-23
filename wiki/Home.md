# Redmi K30 Pro (lmi) — postmarketOS

Unofficial port notes for **postmarketOS + Phosh** on the Redmi K30 Pro / K30 Pro Zoom / POCO F2 Pro (Qualcomm SM8250, `lmi`).

> **Experimental.** Not a phone replacement. Modem/calls/SMS/data, camera, fingerprint, GPS and haptics do not work. Booting currently needs the `recovery` partition workaround. Flashing can erase data or brick the device.
>
> 中文详细文档在仓库的 [`docs/`](https://github.com/iurd/lmi-postmarketos/tree/main/docs) 目录；本 Wiki 是英文操作版。

## Status (2026-10-24)

- pmOS edge + Phosh 0.58, kernel `6.19.0-rc8-sm8250`
- Display/touch, Wi-Fi, GPU, battery, Chinese UI, rounded-corner compensation: working
- nftables enabled with DHCP/mDNS allowances; runtime verified, cold boot pending
- Boot: recovery-only because `boot` is rejected by AVB
- Modem, camera, fingerprint, GPS, haptics: not working
- Suspend and brightness behavior: not fully validated

## Navigate

- [Device](Device) — postmarketOS-style device page and status
- [Build](Build) — environment, package patches, build commands
- [Flash](Flash) — backups, recovery-only boot, rollback
- [Runtime](Runtime) — Chinese, corners, battery, nftables
- [Hardware](Hardware) — support matrix and limits
- [Troubleshooting](Troubleshooting) — common failures
- [FAQ](FAQ)

Repository: <https://github.com/iurd/lmi-postmarketos>

## Quick start

1. Back up the stock partitions and keep a HyperOS fastboot ROM.
2. Build the kernel and device packages from this repository (see [Build](Build)).
3. Flash the rootfs to `userdata` and the same `boot.img` to `recovery`; boot recovery.
4. Log in and verify display, touch, Wi-Fi, battery, Chinese and corners.

Always use placeholders (`<serial>`, `<password>`, `<ssid>`, `<wifi-password>`) in commands; the repository contains no device secrets.
