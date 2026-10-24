# Live audit — 2026-10-24

Read-only audit over SSH as the normal `user` account after Wi-Fi reconnection. No SSID, MAC,
serial or password is recorded in this file.

## Working / present

- Wi-Fi connected; NetworkManager reports `wlan0: connected`
- Phosh 0.58, `squeekboard` running; `org.gnome.desktop.a11y.applications screen-keyboard-enabled = true`
- Display: `/sys/class/drm/card0-DSI-1/modes` → `1080x2400`; backlight device present
- GPU/Freedreno, touch, UFS, battery (`qcom-battery`, 99%, discharging)
- Bluetooth controller: `hci0`, `btqca` loaded, rfkill soft/hard = 0/0
- IR: `rc0`, `/dev/lirc0`
- Camera flash LED: `white:flash`
- Venus video encoder/decoder: `video14` / `video15`
- Thermal zones reporting values
- USB gadget interface `usb0` with `172.16.42.1/16` (currently DOWN)
- Type-C `data_role=host`

## Not working in the current image

- **Audio**: ALSA card 0 `lmi` exists (TFA9872 + WCD938x bound, headset jack), but PulseAudio
  only exposes `auto_null`. Kernel log: `MultiMedia1: ASoC: no backend DAIs enabled for
  MultiMedia1, possibly missing ALSA mixer-based routing or UCM profile`.
- **Camera**: `ov13b10 21-0020: failed to find sensor: -5`; VFE nodes exist but there is no
  usable camera sensor.
- **Sensors**: `iio-sensor-proxy`/`libssc`/`hexagonrpcd` are present, but no IIO sensor
  devices; `monitor-sensor` reports `Sensor claim not allowed`.
- **NFC**: no `/dev/nfc` or `/sys/class/nfc`.
- **GPS**: no `/dev/gnss`.
- **Haptics**: only `white:flash` under `/sys/class/leds`; no vibrator/force-feedback.
- **Proximity**: no sensor device.
- **Modem**: unchanged (SDX55m not supported by mainline).

## Not tested

Bluetooth pairing/audio, IR transmission, flash brightness, USB networking with a host,
Venus encode/decode, suspend/wake (`s2idle` only), hotspot/tethering, 77 Hz display,
thermal stress.
