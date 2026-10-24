# Support matrix — postmarketOS categories

Status legend:

- ✅ verified working on this port
- 🟡 partial / present but not fully usable
- ❌ not working
- ❓ not verified
- 🧱 hard blocker

The “community” column is the pmOS/Nura wiki status for lmi. The “this port” column includes the
read-only live audit from 2026-10-24 (device online via Wi-Fi; no SSID/MAC/serial recorded).

| Category | Community (pmOS/Nura wiki) | This port | Notes |
|---|---|---|---|
| Flashing | Works | ✅ | `fastboot flash recovery` + rootfs to `userdata` |
| Boot from `boot` | — | ❌ / 🧱 | Bootloader rejects pmOS on `boot` (AVB); recovery-only workaround |
| USB Net | Works | 🟡 | `usb0` exists with `172.16.42.1/16` but is DOWN; not verified with a host |
| Storage / UFS | Works | ✅ | UFS rootfs, nested image in `userdata` |
| Battery | Works | ✅ | PM8150B FG via `qcom_fg`; UPower `qcom-battery` |
| Screen | Works | 🟡 | AMS667UU01 1080x2400; `modes` exposes 1080x2400 only; 60 Hz; brightness-change artifacts |
| Touch | Works | ✅ | FocalTech FT3518 |
| 3D / GPU | Works | ✅ | Adreno 650, Freedreno/Mesa |
| Audio | Works | ❌ | ALSA card 0 `lmi` exists (TFA9872/WCD938x bound), but PulseAudio exposes only `auto_null`; kernel logs “no backend DAIs enabled … missing ALSA mixer routing or UCM profile” |
| Camera | Partial | ❌ | `ov13b10` probe fails with `-5`; VFE/venus nodes exist but no usable camera sensor |
| Camera flash | Works | 🟡 | `white:flash` LED exists; not tested |
| IR | Works | 🟡 | `rc0` / `/dev/lirc0` exist; not tested |
| Wi-Fi | Works | ✅ | QCA6391/ath11k; currently connected |
| Bluetooth | Works | 🟡 | `hci0`, `btqca`, rfkill unblocked; pairing/audio not tested |
| GPS | Broken | ❌ | No `/dev/gnss` |
| NFC | Works | ❌ | No `/dev/nfc` or NFC sysfs in this port |
| Modem (calls/SMS/data) | Broken | 🧱 | SDX55m mainline unsupported; diagnosis only (SBL/Sahara/MHI) |
| Fingerprint | Broken | ❌ | In-display fingerprint unsupported |
| Sensors (accel/mag/light) | Works | ❌ / 🟡 | `iio-sensor-proxy`, `libssc`, `hexagonrpcd` present, but no IIO sensor devices and `monitor-sensor` gets “Sensor claim not allowed” |
| Proximity | Broken | ❌ | No sensor device |
| Haptics / vibration | Broken | ❌ | Only `white:flash` LED; no vibrator/force-feedback device |
| Charging | Works (basic) | 🟡 | PM8150B basic charging/battery; 33W private fast-charge/BQ2597x ❌ |
| USB OTG / roles | Partial | 🟡 | Type-C `data_role=host`; `usb0` down; host/role switching not fully tested |
| Suspend / wake | — | ❓ | `/sys/power/state=freeze mem`, `s2idle` only; not tested |
| Video | — | 🟡 | Venus encoder/decoder nodes (`video14`/`video15`) exist; not tested |
| Desktop / UI | — | ✅ | Phosh 0.58, Chinese UI, rounded-corner compensation |
| OSK | — | ✅ | `squeekboard` running, `screen-keyboard-enabled=true`; the long delay was the Wi-Fi dialog startup |
| Chinese input | — | ❌ | No pinyin OSK (squeekboard/stevia) |
| Screenshots | — | ❌ | Phoc has no `wlr-screencopy` |
| Firewall (nftables) | — | ✅ / ❓ | Runtime verified; cold boot with nftables pending |
| Thermal | — | ✅ | Thermal zones report values |
| Hotspot / tethering | — | ❓ | nftables rules exist; not verified |
| Wi-Fi Display / Miracast | — | ❓ | Not implemented/verified |
| Battery health / cycles | — | ❌ | Not exposed (`charge-cycles` unavailable) |

## Still not working (live-confirmed or hard blocker)

- Audio: no usable PulseAudio sink/source; ALSA card exists but UCM routing is missing
- Camera: OV13B10 probe failure; raw nodes alone are not a camera
- NFC, GPS: no device nodes in this port
- Sensors: proxy/libssc present but no sensor data; proximity missing
- Haptics/vibration
- Modem: calls/SMS/data/IMS (mainline SDX55m blocker)
- Boot from `boot` (AVB); recovery-only
- 33W private fast charging (BQ2597x)
- Chinese text input; screenshots
- Battery health/cycle count

## Present but not fully tested

Bluetooth pairing/audio, camera flash, IR blaster, USB gadget networking/host role,
Venus video encode/decode, suspend/wake, hotspot/tethering, 77 Hz display, thermal behavior.

## Current verified positives

Wi-Fi (connected), Phosh, display/touch, GPU, battery/fuel gauge, Chinese UI, corner compensation,
OSK service, nftables runtime.