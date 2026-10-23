# Project conventions and scope

## Scope

- Device: Redmi K30 Pro / K30 Pro Zoom / POCO F2 Pro, codename `lmi`, Qualcomm SM8250
- Goal: bring up postmarketOS + Phosh and validate the core hardware; modem/camera are out of scope
- Route: reuse the existing community port
  - pmaports fork: `yuweiyuan8/pmaports`, branch `nikroks/alioth`
  - Device package: `device/testing/device-xiaomi-lmi`
  - Kernel package: `linux-postmarketos-qcom-sm8250-lmi` (metadata 6.19.7, actual 6.19.0-rc8)
  - Kernel source: `yuweiyuan8/Linux-redmi-k30pro-6.19`, branch `v6.19`
  - UI: Phosh

## Safety rules

- Back up the GPTs and `boot`/`dtbo`/`vbmeta*`/`recovery`/`persist`/`modem`/`dsp`/`bluetooth`/`misc` before writing anything.
- Keep a matching HyperOS fastboot ROM for recovery.
- Do not touch `super`, `persist`, `modem`, NV data or the bootloader state without a specific reason.
- The working boot path is recovery-only; `boot` is rejected by AVB.
- Debug over Wi-Fi + root SSH; there is no `adbd`.
- Never commit firmware, calibration data, MAC addresses, keys, serials or Wi-Fi credentials.
- A firewall change must have an armed rollback (`nft flush ruleset`) before it is applied over SSH.

## Development conventions

- One variable at a time; if the same failure happens twice, stop and write the analysis.
- Every boot-path change gets a cold-boot check; failures keep pstore/logs/image hashes.
- Record package commit, kernel version, image hash and evidence location.
- Temporary workarounds are listed as debt with an exit condition in `06-runtime.md`.
- Prefer upstream or community code; keep local patches minimal and documented.

## Current status (2026-10-24)

- pmOS edge + Phosh boots from `recovery`; display/touch/Wi-Fi/GPU/battery work
- Chinese UI, corner compensation and nftables are working; runtime verified
- Package-level fixes: kernel `pkgrel=1`, device `pkgrel=6`
- Remaining: AVB-accepted boot image, cold-boot validation, suspend/brightness, Chinese input method, screenshot automation

## Documentation

- [Evaluation](01-evaluation.md)
- [Sources](02-sources.md)
- [Device audit](03-device-audit.md)
- [Build](04-build.md)
- [Flash and first boot](05-flash-and-first-boot.md)
- [Runtime](06-runtime.md)
