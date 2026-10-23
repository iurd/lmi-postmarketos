# Hardware

## Working

| Component | Notes |
|---|---|
| SoC | Qualcomm SM8250 (Snapdragon 865) |
| Display | Samsung AMS667UU01, 1080x2400, 60 Hz |
| Touch | FocalTech FT3518 (i2c13) |
| GPU | Adreno 650, Freedreno/Mesa |
| Wi-Fi | QCA6391, ath11k |
| Battery | PM8150B fuel gauge (`qcom_fg`) |
| Charger | PM8150B SMB5 charger; status exposed, private fast-charge/BQ2597x not supported |
| OSK | stevia (Phosh 0.58 default); the bring-up image used squeekboard |
| Desktop | Phosh 0.58 |

## Partial / unverified

- Bluetooth (present, not re-verified in the latest pass)
- Speaker / earpiece / microphone
- Brightness changes (known artifacts)
- Suspend / wake
- USB gadget network (USB enumerates, no adbd; network path not verified)

## Not working

- **Modem**: SDX55M is not supported by mainline; no SIM, calls, SMS, IMS/VoLTE, or mobile data
- Camera: OV13B10 raw/UVC experiments only; no full camera stack
- In-display fingerprint
- GPS
- Haptics
- NFC / sensors

## Boot

The device is A-only. `boot` is 128 MiB, `dtbo` 32 MiB, `userdata` ~226 GiB. The bootloader rejects the pmOS image on `boot` for AVB reasons; the working path is `recovery`.

## Recovery / rollback

Keep stock backups of the unique partitions (`persist`, `modemst*`, `fsg`, `fsc`, `mdm1m9kefs*`) and a matching HyperOS fastboot ROM. Do not write EDL/firehose or NV data unless you know exactly what you are doing.
