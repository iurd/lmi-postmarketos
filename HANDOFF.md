# AI / maintainer handoff — lmi postmarketOS (2026-10-24)

**Read this first.** This file is the restart point for another agent or maintainer. The detailed
porting notes remain in [`docs/`](docs/README.md); this file records the state of the current build,
the exact runtime knobs that matter, and what is still broken.

## Snapshot

| Item | Value |
|---|---|
| Device | Redmi K30 Pro / K30 Pro Zoom / POCO F2 Pro (`lmi`, SM8250) |
| OS | postmarketOS / Nura edge, OpenRC + Phosh 0.58 |
| Kernel | `linux-postmarketos-qcom-sm8250-lmi` **6.19.7-r3**, running `#4-postmarketos-qcom-sm8250-lmi` |
| Device package | `device-xiaomi-lmi` **1-r12** |
| Sound card | ALSA card `lmi`, DTS `sound.model = "lmi"` (no spaces) |
| Boot | Bootloader boots **recovery** (`misc=boot-recovery`, `/dev/sda28`); `boot` is not the active path |
| Release assets | [v0.2.0-lmi](https://github.com/iurd/lmi-postmarketos/releases/tag/v0.2.0-lmi) |

Build hashes (SHA-256):

```text
c4d7a261eb813d4f502072608bc13c3327280f3ef0d4adcfc6a15a32e3db9092  boot-lmi-r3-r12.img
766eac1e382e97c1a778fee74938070bcc52055934c68e95324c3ae105baad47  device-xiaomi-lmi-1-r12.apk
0e1b7e5c13c59dc234e0abaaecbc3826fc716902da21b5df854ef580f2e8c418  linux-postmarketos-qcom-sm8250-lmi-6.19.7-r3.apk
```

## What works now

- Display/touch/GPU, Wi-Fi, Bluetooth scanning, battery gauge/charging, zram swap.
- Speaker playback through PulseAudio UCM (`HiFi` profile, TFA9872).
- Microphone capture through PulseAudio UCM (`alsa_input.platform-sound.HiFi__Mic1__source`).
- Chinese pinyin input through fcitx5 native Wayland; `fcitx5-remote -n` should be `pinyin`.
- `grim` screenshots work on the current Phoc, despite older notes saying otherwise.

## What is still broken / blocked

- **Modem / calls / SMS / mobile data**: external SDX55 stays in SBL; MHI probe times out. Not a
  userspace fix.
- **Sensors**: `iio-sensor-proxy`, `libssc`, `hexagonrpcd-sdsp` run, but no IIO sensor samples;
  `ssccli` only gets registry traffic. Registry/SLPI compatibility needs investigation.
- **Camera**: only `ov13b10` is enabled; probe fails with `-EIO`. Main camera drivers/DT are missing.
- **Haptics/vibrator**: no DT node/driver; only `white:flash`.
- **Suspend**: only `s2idle` exists; not validated.
- **USB gadget**: `usb0` DOWN; gadget networking is unconfigured.
- **Qt IM env**: phosh still has `QT_IM_MODULE=ibus` in its environment even though GTK apps use
  fcitx5 native. GTK works; Qt input may not. `.phoshdebug` unsets it for the next login.
- **Mic gain**: UCM sets `ADC1 Volume=12` (18 dB). PulseAudio source volume 50% maps the hardware
  gain lower again. Voice can still be adjusted in software; acoustic voice QA is pending.

## Important runtime knobs

### Audio / UCM

- UCM source: `packages/device-xiaomi-lmi/alsa-ucm-conf/HiFi.conf`
- Installed: `/usr/share/alsa/ucm2/Xiaomi/lmi/HiFi.conf`
- ALSA lookup paths installed by the package:
  - `/usr/share/alsa/ucm2/conf.d/sm8250/{lmi,Xiaomi-lmi,sm8250,snd-sm8250}.conf`
  - `/usr/share/alsa/ucm2/conf.d/snd-sm8250/{lmi,Xiaomi-lmi,sm8250,snd-sm8250}.conf`
  - `/usr/share/alsa/ucm2/conf.virt.d/{lmi,Xiaomi-lmi}.conf`
- Mic route: `MultiMedia3 Mixer TX_CODEC_DMA_TX_3=1`, `TX DEC0 MUX=SWR_MIC`,
  `TX SMIC MUX0=ADC0` (enum index 1), `TX_AIF1_CAP Mixer DEC0=1`,
  `ADC1_MIXER Switch=1`, `ADC1 Switch=1`, `ADC1 Volume=12`.
- Mic gain was reduced from 20 (+30 dB) to 12 (+18 dB) because max gain clipped at 32768.
- PulseAudio uses `CaptureMixerElem ADC1`; source volume overrides the hardware gain. 50% is a good
  starting point for voice tests.
- **Do not remove `/usr/share/wireplumber/wireplumber.conf.d/51-pulseaudio.conf`**. It keeps
  WirePlumber's `hardware.audio` disabled so PulseAudio owns the card. If it is missing, restore it
  and restart PipeWire/WirePlumber; otherwise PA sinks stay suspended with "another application is
  blocking the access to the device".

### Chinese input

- Packages: `fcitx5`, `fcitx5-chinese-addons`, `fcitx5-gtk` (device package depends on them since r12).
- Profile: `/etc/skel/.config/fcitx5/profile` (`DefaultIM=pinyin`, keyboard-us + pinyin group).
- Autostart: `/etc/phrog/autostart/fcitx5.desktop`, `/etc/xdg/autostart/fcitx5.desktop`,
  `Exec=/usr/bin/fcitx5-session-start`.
- Start script retries `fcitx5-remote -s pinyin` for up to 10 s.
- Session env: `/etc/skel/.phoshdebug` (and `$HOME/.phoshdebug`) contains
  `unset GTK_IM_MODULE QT_IM_MODULE` and `export XMODIFIERS=@im=fcitx`.
- IBus is not used; its autostart should stay disabled. IBus packages may remain installed but idle.

### Boot / DSP

- Device boots from **recovery**, not `boot` (AVB/stock bootloader behavior). The install path is:
  rootfs to `userdata`, `boot.img` to `recovery`.
- After a kernel update, `boot-deploy` only flashes `boot`; flash `/boot/boot.img` to
  `/dev/disk/by-partlabel/recovery` manually, then reboot.
- A full reboot is required after sound/codec/DSP changes. A mere card `unbind/bind` can leave the
  WCD938x ADC controls missing (`ADC1 Switch` etc.) and capture open fails with EINVAL.
- `q6asm-dai ... CMD 10bcd timeout` (ASM_STREAM_CMD_CLOSE) may appear after capture; it did not stop
  capture in the verified build. `q6adm ... 0x10325 error 0x2` disappeared after the clean reboot.
- After a clean reboot, `q6routing` sessions reset and the UCM route above captures successfully.

## Build

Prerequisites are in [`docs/04-build.md`](docs/04-build.md). Short version (WSL2):

```sh
cd ~/pmaports-lmi   # device/testing/{device-xiaomi-lmi,linux-postmarketos-qcom-sm8250-lmi}
# copy packages/ from this repo into device/testing/ if starting fresh
cd ~/pmbootstrap
python3 pmbootstrap.py -c ~/.config/pmbootstrap_v3.cfg --as-root -y \
    build linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

Warm ccache kernel rebuild is about 2 minutes; a cold build is much longer. The kernel package
carries `0001-power-supply-wire-qcom-fg.patch` and
`0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch` (sound model `Xiaomi lmi` → `lmi`).
The device package carries the UCM, zram algo, fcitx5 runtime and phoshdebug env.

## Verify a device (no secrets in repo)

Use placeholders for IP/user/password. SSH access is owner-provided.

```sh
# speaker
pactl list cards
speaker-test -D pulse -c 1 -t sine -l 1

# mic source + capture
pactl list sources
alsaucm -c lmi dump text
parecord --channels=1 --rate=48000 --format=s16le --file-format=wav /tmp/mic.wav
# analyze peak / play back

# IME
fcitx5-remote -n          # expect pinyin
fcitx5-remote -s pinyin

# DSP errors
dmesg | grep -iE 'q6adm|q6routing|q6asm'
```

If PA reports the sink suspended because another application holds the card, check the WirePlumber
`51-pulseaudio.conf` above.

## Next steps (priority)

1. **Modem**: investigate SDX55 SBL/MHI/EDL firmware path; no mainline support today.
2. **Sensors**: compare Android `sensors/registry` with `slpi.mbn`; inspect libssc QMI logs.
3. **Camera**: identify actual sensor variants, add drivers/DT (IMX686 etc.).
4. **Haptics**: add AW8695/AW8697 DT node + driver.
5. **Suspend**: validate s2idle resume and wake sources.
6. **Qt IM env**: remove the residual `QT_IM_MODULE=ibus` at session start.
7. **Mic QA**: record voice at source volume 50–70%; adjust `ADC1 Volume` if clipping/quiet.

## Release assets

`v0.2.0-lmi` contains only `boot-lmi-r3-r12.img`, the r3 kernel APK and the r12 device APK.
No rootfs, firmware, partition backup, Wi-Fi credentials, SSH keys, serial or account password is
included. Build the rootfs with `scripts/build-generic-image.sh` and pmbootstrap.

## Do not commit

Device serial, account passwords, Wi-Fi SSID/password, SSH private keys, `userdata`/rootfs images,
partition backups, firmware blobs or personal files. Use `<device-ip>`, `<user>`, `<password>`,
`<serial>`, `<ssid>` placeholders.
