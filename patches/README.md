# patches/

Build-side and kernel patches for the port.

## Current

| File | Purpose |
|---|---|
| `0001-lmi-kernel-builddir.patch` | Fix the kernel APKBUILD `builddir` (GitHub archive top-level directory was renamed) |
| `0002-lmi-kernel-config-hash.patch` | Add the kernel tarball hash and switch to the merged 6.19 config |
| `0003-pmbootstrap-lax-deps.patch` | Work around the pmbootstrap 3.12 strict-mode self-lock |
| `0001-power-supply-wire-qcom-fg.patch` | Wire `qcom_fg.c` into Kconfig/Makefile; also included in the kernel package |
| `packages/linux-postmarketos-qcom-sm8250-lmi/0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch` | DTS `sound.model` `Xiaomi lmi` → `lmi`; required for UCM lookup. Included in the kernel package |
| `config-6.19.0-rc8-sm8250-running` | Actual running kernel config, useful for rebuilding the module |

The kernel package in `packages/` already contains the qcom_fg patch and the config option, so it is the recommended path. These files document how the fork's APKBUILD was adapted.

## Historical / superseded

`archive/device-source_deviceinfo/` contains the `source_deviceinfo` experiment and its revert. The file is provided by `devicepkg-utils`; the patch is not needed.

Failed runtime approaches are in `archive/`:

- GTK CSS padding and `LD_PRELOAD` for rounded corners (never took effect with Phosh 0.58)
- ADB/`adbd` image patches (Alpine android-tools has no adbd)
- `session-env` (replaced by the `.phoshdebug` hook)
