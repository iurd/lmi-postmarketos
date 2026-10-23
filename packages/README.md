# packages/

pmaports sources used for the lmi port.

## device-xiaomi-lmi (`pkgrel=6`)

Copy this directory to `device/testing/device-xiaomi-lmi` in the pmaports fork.

It adds:

- `font-noto-cjk`, `musl-locales`, and the `-lang` packages used by the UI
- `nftables`
- `/usr/share/gmobile-lmi/xiaomi,lmi.json` (panel data, corner radius 150)
- `/etc/phosh/phoc.ini` (`scale = 3`)
- `/etc/locale.conf` (`LANG=zh_CN.UTF-8`)
- `/etc/skel/.phoshdebug` (session language + `G_RESOURCE_OVERLAYS`)
- `/etc/nftables.d/60_lmi.nft` (DHCP client replies + mDNS)

## linux-postmarketos-qcom-sm8250-lmi (`pkgrel=1`)

Copy to `device/testing/linux-postmarketos-qcom-sm8250-lmi`.

- `0001-power-supply-wire-qcom-fg.patch` wires `qcom_fg.c` into Kconfig/Makefile.
- The config has `CONFIG_BATTERY_QCOM_FG=m`.
- The package therefore ships `qcom_fg.ko` for the 6.19.0-rc8-sm8250 kernel.

## Build

```sh
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root build --arch aarch64 \
    linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

The kernel rebuild is the long step. Check `patches/README.md` for the fork-side APKBUILD fixes.
