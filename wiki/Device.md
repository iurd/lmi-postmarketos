# Xiaomi Redmi K30 Pro (lmi)

> This page follows the postmarketOS device-page structure. It is an unofficial, experimental port.

| | |
|---|---|
| Manufacturer | Xiaomi |
| Name | Redmi K30 Pro / K30 Pro Zoom / POCO F2 Pro |
| Codename | `lmi` |
| Released | 2020 |
| Category | testing |
| Chipset | Qualcomm Snapdragon 865 (SM8250) |
| CPU | Octa-core (1×2.84 GHz + 3×2.42 GHz + 4×1.80 GHz) |
| GPU | Adreno 650 |
| Display | 6.67" 1080×2400 AMOLED (AMS667UU01) |
| Touch | FocalTech FT3518 |
| Storage | 128 / 256 GB UFS |
| Memory | 6 / 8 / 12 GB |
| Original OS | Android 10 (upgraded to HyperOS 3 by the owner) |
| pmOS status | booting |
| Mainline kernel | 6.19.0-rc8 (community fork) |
| Bootloader | unlocked; A-only; recovery-only workaround |
| Last verified | 2026-10-24 |

## Status

Working: display, touch, Phosh, Wi-Fi, GPU, battery (PM8150B FG), Chinese UI, rounded-corner compensation, nftables, OSK.

Not working: audio (no usable PulseAudio sink/UCM routing in the current image), camera (OV13B10 probe fails), modem (SDX55m), in-display fingerprint, GPS, haptics, NFC, sensors/proximity. Suspend and brightness behavior are not fully validated. See the [support matrix](https://github.com/iurd/lmi-postmarketos/blob/main/docs/07-support-matrix.md).

## Installation

This device is not in official pmaports; use the community fork and packages in this repository.

- Kernel package: `linux-postmarketos-qcom-sm8250-lmi` (`pkgrel=1`)
- Device package: `device-xiaomi-lmi` (`pkgrel=6`)
- Rootfs: build with `pmbootstrap` (or use a generic image built from these packages)

The current bring-up boots from **`recovery`** because the bootloader rejects the pmOS image on `boot` (AVB). See [Flash](Flash) for the exact path and rollback.

## Generic images

Generic images built from this repository:

- prebuilt **boot.img**: [v0.1.0-lmi release](https://github.com/iurd/lmi-postmarketos/releases/tag/v0.1.0-lmi) (boot only; SHA256 `2d1f2a28…`)
- contain **no Wi-Fi credentials**
- contain **no authorized SSH keys**
- boot to Phosh with user `user` / password `147147` (change it after first login)
- log in first, then configure Wi-Fi in Settings

The prebuilt boot image is paired with the generic rootfs from the same pmbootstrap run. If you build your own rootfs, generate both images with pmbootstrap; do not mix boot/rootfs from different builds.

Use [`scripts/build-generic-image.sh`](https://github.com/iurd/lmi-postmarketos/blob/main/scripts/build-generic-image.sh) and review the image before publishing.

## Hardware

See [Hardware](Hardware) for the support matrix, [`docs/07-support-matrix.md`](https://github.com/iurd/lmi-postmarketos/blob/main/docs/07-support-matrix.md) for the postmarketOS-style community-vs-port table, and [Runtime](Runtime) for the display scale, Chinese UI, battery and firewall details.

## Known issues

- Recovery-only boot due to AVB
- No modem/calls/SMS/data
- No full camera stack
- No Chinese input method (Phosh OSK stevia/squeekboard has no pinyin)
- No screenshot path in Phoc (no wlr-screencopy)
- Suspend/brightness unvalidated

## See also

- [Repository](https://github.com/iurd/lmi-postmarketos)
- [Build](Build)
- [Flash](Flash)
- [Troubleshooting](Troubleshooting)
