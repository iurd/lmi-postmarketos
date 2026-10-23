# FAQ

## Is this an official postmarketOS port?

No. It reuses the community fork by yuweiyuan8/Nikroks. lmi is not in official pmaports or upstream mainline DTS.

## Can I use it as a daily phone?

No. The modem is unsupported (no calls/SMS/data), the camera stack is missing, and boot is recovery-only. It works as a Linux handheld/server with Wi-Fi.

## Why 300% scale?

At 1080x2400, 300% gives a normal phone-sized UI (360x800 logical). The panel JSON radius is tuned for that scale.

## Why is the battery fix a kernel module?

`qcom_fg.c` existed in the kernel tree but was not wired into Kconfig/Makefile. The package now applies the patch and enables `CONFIG_BATTERY_QCOM_FG=m`; the module is built by the kernel package.

## Will the fixes survive a reflash?

They are in the kernel/device packages in this repository. Rebuild the image from these packages; reflashing an **old** image will not contain them.

## Why not patch gnome-shell/mutter?

lmi uses Phosh/phoc, not GNOME Shell/Mutter. The corner issue is in Phosh's layout manager and gmobile panel data.

## Why recovery-only boot?

The bootloader rejects the pmOS image on `boot` (AVB). The same image is accepted on `recovery`. An AVB-accepted boot image/bootshim is future work.

## Does the repository include firmware, backups or images?

No. Only text, patches and package sources. Keep your own firmware and backups private.

## Where do I report issues?

Open an issue in this repository with device model, `uname -r`, package versions and logs. Do not paste serials, passwords, Wi-Fi credentials or private keys.
