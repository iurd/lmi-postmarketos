# Flash

> Back up first. The repository does **not** contain firmware, partition backups or flashable images.

## Why recovery-only?

The bootloader writes the pmOS `boot.img` to `boot` but refuses to boot it (AVB). The same image is accepted in `recovery`, so the current workaround is:

- rootfs → `userdata`
- `boot.img` → `recovery`
- boot into recovery

Normal reboot currently returns to fastboot. This is the main integration blocker.

## Preconditions

- Unlocked bootloader
- Backups of `boot`, `dtbo`, `vbmeta*`, `recovery`, `persist`, `modem`, `dsp`, `bluetooth`, `misc`, and both GPTs
- A matching HyperOS fastboot ROM for recovery
- Backups kept off-device

The full partition/backup details are in [`docs/03-device-audit.md`](https://github.com/iurd/lmi-postmarketos/blob/main/docs/03-device-audit.md) and [`docs/05-flash-and-first-boot.md`](https://github.com/iurd/lmi-postmarketos/blob/main/docs/05-flash-and-first-boot.md).

## Flash

Generic boot image: [v0.1.0-lmi release](https://github.com/iurd/lmi-postmarketos/releases/tag/v0.1.0-lmi) (boot.img only; build the rootfs with pmbootstrap and keep boot/rootfs from the same build).

```sh
adb -s <serial> reboot bootloader
fastboot -s <serial> flash userdata <rootfs-image>
fastboot -s <serial> flash recovery <boot.img>
fastboot -s <serial> reboot recovery
```

Do not flash `dtbo`, `vbmeta`, `super`, `persist` or `modem` unless you know why.

## First boot

- Phosh starts at the lock screen (the installer creates the user).
- The lock screen cannot select a Wi-Fi SSID. Log in with the default account, then configure Wi-Fi in Settings. Generic images ship **without Wi-Fi credentials**.
- Root SSH is only available after you configure it. Generic images contain **no authorized keys**.
- Verify display, touch, battery, Chinese and the top bar.

## Rollback

From pmOS (no adbd):

```sh
ssh root@<device-ip> reboot bootloader
fastboot -s <serial> flash boot <stock-boot.img>
fastboot -s <serial> reboot
```

If TWRP is missing, re-flash it from your own backup. Restoring Android data requires your own backup or the HyperOS fastboot ROM.
