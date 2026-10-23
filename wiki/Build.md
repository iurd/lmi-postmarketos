# Build

## Environment used

- Host: WSL2 Ubuntu 26.04, 8 vCPU, ~10 GB RAM, ~860 GB free
- `pmbootstrap` 3.12.1
- pmaports fork: `yuweiyuan8/pmaports`, branch `nikroks/alioth`
- Kernel source: `yuweiyuan8/Linux-redmi-k30pro-6.19`, branch `v6.19` (actually 6.19.0-rc8)
- Alpine mirror: TUNA (`https://mirrors.tuna.tsinghua.edu.cn/alpine/`)

The exact environment and failures are in [`docs/04-build.md`](https://github.com/iurd/lmi-postmarketos/blob/main/docs/04-build.md).

## Packages in this repository

### Kernel package

`packages/linux-postmarketos-qcom-sm8250-lmi/` (`pkgrel=1`)

- `0001-power-supply-wire-qcom-fg.patch` wires the existing `drivers/power/supply/qcom_fg.c` into Kconfig/Makefile.
- `CONFIG_BATTERY_QCOM_FG=m` is added to the kernel config, so the package ships `qcom_fg.ko`.
- The running kernel has `CONFIG_MODVERSIONS` disabled, but a package rebuild is still preferable to manually copying a module.

### Device package

`packages/device-xiaomi-lmi/` (`pkgrel=4`)

Adds:

- `font-noto-cjk`, `musl-locales`, and the `-lang` packages used by the installed UI
- `nftables`
- panel data `xiaomi,lmi.json`, `phoc.ini` (scale 3), `locale.conf`
- `/etc/skel/.phoshdebug` (session language + gmobile resource overlay)
- `/etc/nftables.d/60_lmi.nft` (DHCP client replies + mDNS)

## Build steps

1. Clone the pmaports fork and check out `nikroks/alioth`.
2. Copy the two package directories into `device/testing/`.
3. Apply the build-side patches in `patches/` to the kernel APKBUILD/config as needed (they are already reflected in the packaged files).
4. Build:

```sh
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root build --arch aarch64 \
    linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

The kernel is the long step (~1 hour on 8 vCPU). Then build the image with `pmbootstrap install` and export `boot.img` / rootfs.

## Verify

```sh
apk info -L linux-postmarketos-qcom-sm8250-lmi | grep qcom_fg
apk info -L device-xiaomi-lmi | grep -E 'xiaomi,lmi.json|phoshdebug|60_lmi.nft'
modinfo qcom_fg | grep vermagic
```

`qcom_fg.ko` must match `uname -r` (`6.19.0-rc8-sm8250`).

## Verified build

The 2026-10-24 build produced:

- kernel `6.19.7-r1`, 28 MB, SHA256 `6a7bc96c…`
- device `1-r4`, 5.1 KB, SHA256 `3938571d…`
- `qcom_fg.ko` vermagic `6.19.0-rc8-sm8250 SMP preempt mod_unload aarch64`

Details and package contents: [`verification/build-2026-10-24.md`](https://github.com/iurd/lmi-postmarketos/blob/main/verification/build-2026-10-24.md).
