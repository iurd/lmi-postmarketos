# reference/kernel/

Key out-of-tree sources copied from the kernel fork used by this port:

- Source: `yuweiyuan8/Linux-redmi-k30pro-6.19`, tag/branch `v6.19` (the tree reports 6.19.0-rc8)
- License: GPL-2.0 (headers preserved in each file)

| File | Original path | Why it is here |
|---|---|---|
| `sm8250-xiaomi-lmi.dts` | `arch/arm64/boot/dts/qcom/` | Device tree: panel, touch, charger, fuel gauge, USB, audio |
| `qcom_fg.c` | `drivers/power/supply/` | PM8150B fuel gauge; the kernel package patch wires it into Kconfig/Makefile |
| `panel-samsung-ams667uu01.c` | `drivers/gpu/drm/panel/` | lmi display panel |
| `focaltech_fts.c` | `drivers/input/touchscreen/` | FT3518 touch |
| `tfa9872.c` | `sound/soc/codecs/` | Speaker amplifier |

These copies are for reference and reproducibility; the build uses the kernel tarball referenced by the kernel APKBUILD. If you update the fork, re-check the DTS and driver state instead of assuming these copies are current.

Not included: proprietary firmware, calibration/NV data, vendor blobs, BQ2597x fast-charge driver (not supported in this port).
