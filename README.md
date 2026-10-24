# Redmi K30 Pro (lmi) — postmarketOS port

Unofficial bring-up notes, kernel/device packaging and patches for running **postmarketOS + Phosh** on the **Redmi K30 Pro / K30 Pro Zoom / POCO F2 Pro** (Qualcomm SM8250, codename `lmi`).

> **Status: experimental.** This is a bring-up, not a daily-driver phone port. Speaker/mic, Chinese pinyin input, display, Wi-Fi and battery work; modem/calls/SMS/data, camera, fingerprint, GPS, sensors and haptics do not. Booting currently requires the `recovery` partition workaround described below. Flashing can brick or erase your data — back up first.

> **中文摘要：** 本仓库记录 Redmi K30 Pro（lmi，SM8250）运行 postmarketOS + Phosh 的移植、内核/设备包补丁和运行期配置。当前显示/触控/Wi-Fi/GPU/电池/扬声器/麦克风/fcitx5 中文拼音/R 角补偿可用；modem、相机、指纹、GPS、传感器和振动不可用；只能从 `recovery` 启动。详细中文文档见 [`docs/`](docs/README.md)，操作步骤见 [wiki](https://github.com/iurd/lmi-postmarketos/wiki)。**另一个 AI/维护者请先读 [`HANDOFF.md`](HANDOFF.md)。**

## Current state (2026-10-24)

| Area | State |
|---|---|
| Boot | pmOS boots from `recovery`; the stock bootloader rejects the same image on `boot` (AVB). Normal reboot returns to fastboot until an AVB-accepted image exists. |
| Display / touch | Working: AMS667UU01 panel, FT3518 touch, Phosh 0.58, 300% scale |
| UI language | Chinese UI works (`zh_CN.UTF-8`, Noto CJK, translations) |
| Chinese input | Working via fcitx5 native Wayland + pinyin (`fcitx5-remote -n` = `pinyin`); Qt IM env still needs cleanup |
| Audio | Working: PulseAudio `HiFi` profile, TFA9872 speaker, WCD938x Mic1 source; `parecord` works; ADC1 gain 12 (18 dB) |
| Top bar / rounded corners | Working; panel data included for gmobile, icons inset from the physical R corners |
| Battery | Working: PM8150B fuel gauge via `qcom_fg`, exposed to UPower as `qcom-battery`; charging reported |
| Wi-Fi / Bluetooth | Wi-Fi working; Bluetooth scan works; pairing/audio not fully tested |
| GPU | Freedreno / Mesa working |
| Firewall | nftables enabled in `default` runlevel with DHCP/mDNS allowances; runtime verified, cold boot pending |
| Screenshots | `grim` works on the current Phoc |
| Modem | Not working (SDX55M stays in SBL/MHI; mainline unsupported) |
| Sensors | Not working: no IIO samples; `ssccli` only sees registry traffic |
| Camera / fingerprint / GPS / haptics | Not working |
| Suspend / brightness | Suspend not fully validated; only `s2idle`; brightness-change artifacts are a known community issue |

Kernel: `6.19.0-rc8-sm8250` (package `6.19.7-r3`). Device package: `1-r12`. Userland: postmarketOS edge + Phosh 0.58. Boot path: recovery-only due to AVB.

## Repository layout

```
docs/        Porting notes: evaluation, sources, device audit, build, flash, runtime
patches/     Build patches, kernel patch, running kernel config
packages/    pmaports sources for device-xiaomi-lmi and the kernel package
runtime/     Runtime defaults: gmobile panel JSON, phoc.ini, .phoshdebug, fcitx5, nftables drop-in
reference/   Key out-of-tree kernel sources (DTS, qcom_fg, panel, touch, audio)
scripts/     Build/offline-image/debug helpers
verification/ Build and runtime verification records
archive/     Failed or superseded approaches, kept for history
wiki/        Source for the GitHub wiki pages
HANDOFF.md   Current state, runtime knobs, next steps for the next AI/maintainer
```

Start with [`HANDOFF.md`](HANDOFF.md) for the current state and next steps, then the [wiki](https://github.com/iurd/lmi-postmarketos/wiki) for the guided version, or read the documents in `docs/` directly.

## What was fixed for this port

- **Audio / mic**: DTS sound-card name changed to `lmi`; UCM installed under the real ALSA lookup paths; `cdev`/raw control fixes; Mic1 route with `TX SMIC MUX0=ADC0`, `ADC1_MIXER Switch`, `ADC1 Switch`, `ADC1 Volume=12`. Speaker and microphone both work through PulseAudio.
- **DSP routing**: a clean reboot (not just card unbind/bind) is required to reset q6routing/WCD938x; the old `q6adm error 0x2` disappeared and capture started working.
- **Chinese pinyin input**: fcitx5 native Wayland with pinyin profile and retrying autostart; GTK/QT IM env is unset in `.phoshdebug` (Qt residual env is still tracked in HANDOFF).
- **zram**: deviceinfo forces `lzo-rle` because the kernel only has the LZO zram backend; the default zstd failed.
- **Battery**: `drivers/power/supply/qcom_fg.c` existed in the kernel tree but was not wired into Kconfig/Makefile. The kernel package now carries `0001-power-supply-wire-qcom-fg.patch` and `CONFIG_BATTERY_QCOM_FG=m`.
- **Chinese UI**: device package depends on `font-noto-cjk`, `musl-locales` and the `-lang` packages used by the installed applications; `LANG=zh_CN.UTF-8`, `LANGUAGE=zh_CN:zh`.
- **Rounded corners**: Phosh 0.58 only applies its corner-shift logic when gmobile has panel data for the device. `runtime/xiaomi,lmi.json` supplies 1080x2400 and corner radius 150 (tuned for 300% scale); `G_RESOURCE_OVERLAYS` injects it without rebuilding gmobile.
- **Session environment**: injected through the upstream `$HOME/.phoshdebug` hook, so `phosh-session` stays unpatched. The image version is installed as `/etc/skel/.phoshdebug`.
- **Firewall**: pmOS base enables nftables; `runtime/60_lmi.nft` allows DHCP client replies and mDNS on top of the default rules (SSH is already allowed by the base ruleset).

## Build

Prerequisites: Linux (WSL2 is fine), `pmbootstrap` 3.12.x, the `yuweiyuan8/pmaports` fork (`nikroks/alioth`) and the matching kernel source. See [docs/04-build.md](docs/04-build.md) for the exact environment.

The packaged fix is in `packages/`:

- `packages/device-xiaomi-lmi` — device package (`pkgrel=12`): CJK/language/nftables dependencies, UCM speaker/Mic1 routes, ADC1 gain 12, `deviceinfo_zram_swap_algo="lzo-rle"`, panel JSON, `phoc.ini`, `locale.conf`, `.phoshdebug`, fcitx5 pinyin autostart, nftables drop-in.
- `packages/linux-postmarketos-qcom-sm8250-lmi` — kernel package (`pkgrel=3`): `qcom_fg` Kconfig/Makefile patch, `0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch` (sound model `Xiaomi lmi` → `lmi`), `CONFIG_BATTERY_QCOM_FG=m`.

Copy them into a pmaports checkout under `device/testing/`, then:

```sh
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root build --arch aarch64 \
    linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

The full kernel rebuild is the long step on a cold cache; with a warm ccache it is about 2 minutes on this WSL2 setup. Build patches for the fork itself are in `patches/`.

Generic image: `scripts/build-generic-image.sh` builds an image with no Wi-Fi profile, no SSH keys and no personal files. Pass the test account password with `GENERIC_PASSWORD`; the account name is `user`. Change the password after first login. Generic images do not auto-connect to any Wi-Fi.

## Verification

- [AI/maintainer handoff](HANDOFF.md) — current state, boot/DSP caveats, runtime knobs, next steps
- [Package build result](verification/build-2026-10-24.md) — hashes, `qcom_fg.ko` vermagic, device package contents
- [Runtime checks](verification/runtime-2026-10-24.md) — Chinese UI, corners, battery, nftables on the device
- [Audio/mic/IME runtime](verification/runtime-2026-10-24-audio-mic-ime.md) — UCM, ADC1 gain, PA source, fcitx5 pinyin
- [q6routing/DSP reload](verification/q6routing-reload-2026-10-24.md) — why a full reboot (not card rebind) is required; capture results
- [Live audit](verification/live-audit-2026-10-24.md) — postmarketOS-category findings; still-broken areas
- [Support matrix](docs/07-support-matrix.md) — postmarketOS categories, community vs this port, what still does not work
- [v0.2.0-lmi release](https://github.com/iurd/lmi-postmarketos/releases/tag/v0.2.0-lmi) — boot image, r3 kernel APK, r12 device APK; no rootfs/firmware/credentials

## Flash (read this first)

This port currently **cannot boot from `boot`**: the bootloader rejects the pmOS image there for AVB reasons. The working path is:

1. Back up `boot`, `dtbo`, `vbmeta*`, `recovery`, `persist`, `modem`, `dsp`, `bluetooth`, `misc` and the GPTs. Backups are **not** included in this repository.
2. Flash the rootfs image to `userdata` and the same `boot.img` to **`recovery`**.
3. Boot recovery; pmOS starts.

```sh
adb -s <serial> reboot bootloader
fastboot -s <serial> flash userdata <rootfs-image>
fastboot -s <serial> flash recovery <boot.img>
fastboot -s <serial> reboot recovery
```

Rollback: flash your stock `boot.img` back; re-flash TWRP from your backup if needed. Full details and warnings are in [docs/05-flash-and-first-boot.md](docs/05-flash-and-first-boot.md).

## Debugging

- Root SSH over Wi-Fi is the working debug channel. The lock screen cannot select an SSID: log in with your account first, then configure Wi-Fi in Settings. Generic images ship **without Wi-Fi credentials and without authorized SSH keys**.
- USB enumerates as `POSTMARKETOS` but there is no `adbd`; Alpine `android-tools` does not ship it.
- `grim` screenshots work on the current Phoc; older notes that said screencopy was unsupported are stale.

## Security / sanitization

This repository contains no device serial, account password, Wi-Fi credentials, SSH private keys, firmware, partition backups or rootfs/boot images. Commands use placeholders:

`<serial>`, `<password>`, `<ssid>`, `<wifi-password>`, `<device-ip>`, `<key>`.

Replace them locally. Do not commit your own secrets.

## Credits

- [yuweiyuan8](https://github.com/yuweiyuan8) and Nikroks for the pmOS fork, device package and kernel tree
- [ccc007ccc](https://github.com/ccc007ccc) and [electropica](https://github.com/electropica) for the mainline/Debian lmi work and validation notes
- The Phosh, gmobile, postmarketOS and Linux kernel communities

## License

GPL-2.0-only. See [LICENSE](LICENSE). Package metadata retains its original licenses (for example, the device package is MIT); kernel-derived patches remain GPL-2.0.
