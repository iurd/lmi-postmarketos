# Hardware

Full postmarketOS-style status table (community vs this port): [docs/07-support-matrix.md](https://github.com/iurd/lmi-postmarketos/blob/main/docs/07-support-matrix.md).

## Working

| Component | Notes |
|---|---|
| SoC | Qualcomm SM8250 (Snapdragon 865) |
| Display | Samsung AMS667UU01, 1080x2400, 60 Hz (brightness artifacts) |
| Touch | FocalTech FT3518 (i2c13) |
| GPU | Adreno 650, Freedreno/Mesa |
| Wi-Fi | QCA6391, ath11k |
| Battery | PM8150B fuel gauge (`qcom_fg`) |
| Charger | PM8150B SMB5 basic charging; private fast-charge/BQ2597x not supported |
| Desktop / OSK | Phosh 0.58, `stevia` in generic images (`squeekboard` in the bring-up image) |
| Audio | PulseAudio `HiFi` profile on card `lmi`; TFA9872 speaker, WCD938x Mic1 capture; ADC1 gain 12 |
| Chinese input | fcitx5 native Wayland + pinyin (GTK apps; Qt may still use IBus) |
| Screenshots | `grim` works on the current Phoc |
| Thermal | Thermal zones report values |

## Partial / present but not fully usable

- Bluetooth: `hci0`, `btqca`, rfkill unblocked; pairing/audio not tested
- IR: `rc0`/`/dev/lirc0` present; not tested
- Camera flash: `white:flash` present; not tested
- USB: Type-C `data_role=host`; `usb0` gadget network exists but is DOWN/untested
- Suspend/wake: only `s2idle`; not tested
- Video: Venus encoder/decoder nodes present; not tested
- 77 Hz display: only 1080x2400 mode exposed in the current image

## Not working (live audit 2026-10-24)

- **Camera**: `ov13b10` probe fails (`-5`); VFE nodes exist but no usable sensor
- **Sensors**: `iio-sensor-proxy`/`libssc`/`hexagonrpcd` present, but no sensor data and `monitor-sensor` gets “Sensor claim not allowed”; proximity missing
- **NFC**: no `/dev/nfc` or NFC sysfs
- **GPS**: no `/dev/gnss`
- **Haptics/vibration**: no vibrator/force-feedback device
- **Modem**: SDX55M unsupported; no SIM/calls/SMS/data/IMS
- In-display fingerprint

See [`docs/07-support-matrix.md`](https://github.com/iurd/lmi-postmarketos/blob/main/docs/07-support-matrix.md) and [`verification/live-audit-2026-10-24.md`](https://github.com/iurd/lmi-postmarketos/blob/main/verification/live-audit-2026-10-24.md).

## Boot

The device is A-only. `boot` is 128 MiB, `dtbo` 32 MiB, `userdata` ~226 GiB. The bootloader rejects the pmOS image on `boot` for AVB reasons; the working path is `recovery`.

## Recovery / rollback

Keep stock backups of the unique partitions (`persist`, `modemst*`, `fsg`, `fsc`, `mdm1m9kefs*`) and a matching HyperOS fastboot ROM. Do not write EDL/firehose or NV data unless you know exactly what you are doing.
