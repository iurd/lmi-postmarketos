# packages/

pmaports sources used for the lmi port.

## device-xiaomi-lmi (`pkgrel=12`)

Copy this directory to `device/testing/device-xiaomi-lmi` in the pmaports fork.

It adds:

- `font-noto-cjk`, `musl-locales`, and the `-lang` packages used by the UI
- `nftables`
- `fcitx5`, `fcitx5-chinese-addons`, `fcitx5-gtk`
- `/usr/share/gmobile-lmi/xiaomi,lmi.json` (panel data, corner radius 150)
- `/etc/phosh/phoc.ini` (`scale = 3`)
- `/etc/locale.conf` (`LANG=zh_CN.UTF-8`)
- `/etc/skel/.phoshdebug` (session language + `G_RESOURCE_OVERLAYS` + IM env)
- `/etc/nftables.d/60_lmi.nft` (DHCP client replies + mDNS)
- `/usr/share/alsa/ucm2/Xiaomi/lmi/{lmi,HiFi}.conf` plus `conf.d/sm8250`,
  `conf.d/snd-sm8250` and `conf.virt.d` symlinks (speaker + Mic1 UCM routes)
- `/usr/bin/fcitx5-session-start`, `/etc/xdg/autostart/fcitx5.desktop`,
  `/etc/skel/.config/fcitx5/profile` (pinyin input)

`deviceinfo` sets `deviceinfo_zram_swap_algo="lzo-rle"` because the kernel only
ships the LZO zram backend.

## linux-postmarketos-qcom-sm8250-lmi (`pkgrel=3`)

Copy to `device/testing/linux-postmarketos-qcom-sm8250-lmi`.

- `0001-power-supply-wire-qcom-fg.patch` wires `qcom_fg.c` into Kconfig/Makefile.
- `0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch` changes
  `&sound { model = "Xiaomi lmi"; }` to `"lmi"`; names with spaces/hyphens
  cannot be opened by `snd_use_case_mgr_open()`, so PulseAudio/ALSA find no UCM.
- The config has `CONFIG_BATTERY_QCOM_FG=m`.
- The package therefore ships `qcom_fg.ko` for the 6.19.0-rc8-sm8250 kernel.

## Build

```sh
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root build --arch aarch64 \
    linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

Kernel rebuild is the long step on a cold cache (~1 h on 8 vCPU); with ccache
warm it is about 2 minutes. Check `patches/README.md` for the fork-side
APKBUILD fixes.
