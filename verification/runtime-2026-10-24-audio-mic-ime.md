# Runtime verification — audio, microphone, Chinese input

Date: 2026-10-24 (collected 13:44–13:47 local, device time)
Device: Redmi K30 Pro Zoom (`lmi`), postmarketOS edge + Phosh 0.58
Kernel: `6.19.0-rc8-sm8250` (package `linux-postmarketos-qcom-sm8250-lmi-6.19.7-r3`)
Device package: `device-xiaomi-lmi-1-r12`
Boot path: recovery partition; session started at 12:53, uptime 51 min at check time

No device serial, SSID, IP, MAC or user password is recorded here.

## Package state

```text
$ apk info -v | grep -E '^(device-xiaomi-lmi|linux-postmarketos-qcom-sm8250-lmi|fcitx5)-'
device-xiaomi-lmi-1-r12
device-xiaomi-lmi-nonfree-firmware-1-r2
device-xiaomi-lmi-nonfree-firmware-openrc-1-r2
fcitx5-5.1.23-r0
fcitx5-chinese-addons-5.1.15-r0
fcitx5-gtk-5.1.7-r0
fcitx5-gtk3-5.1.7-r0
fcitx5-gtk4-5.1.7-r0
fcitx5-qt-5.1.16-r0
linux-postmarketos-qcom-sm8250-lmi-6.19.7-r3
```

## ALSA card and UCM

```text
$ cat /proc/asound/cards
 0 [lmi            ]: sm8250 - lmi
                      lmi

$ aplay -l
card 0: lmi [lmi], device 0: MultiMedia1 (*) []
card 0: lmi [lmi], device 1: MultiMedia2 (*) []
card 0: lmi [lmi], device 2: MultiMedia3 (*) []
```

The card is named `lmi` (DTS `&sound { model = "lmi"; }`, kernel patch `0002`). With the
original `"Xiaomi lmi"` the name contains a space and PulseAudio/ALSA could not open a UCM.

```text
$ ls -l /usr/share/alsa/ucm2/conf.d/sm8250/
Xiaomi-lmi.conf -> ../../Xiaomi/lmi/lmi.conf
lmi.conf        -> ../../Xiaomi/lmi/lmi.conf
sm8250.conf     -> ../../Xiaomi/lmi/lmi.conf
snd-sm8250.conf -> ../../Xiaomi/lmi/lmi.conf
```

Symlinks also exist under `conf.d/snd-sm8250/` and `conf.virt.d/` (`lmi`, `Xiaomi-lmi`).

## PulseAudio

```text
$ pactl list short sinks
0  alsa_output.platform-sound.HiFi__Speaker__sink  module-alsa-card.c  s16le 1ch 44100Hz  IDLE

$ pactl list short sources
0  alsa_output.platform-sound.HiFi__Speaker__sink.monitor  ...  RUNNING
1  alsa_input.platform-sound.HiFi__Mic1__source            ...  SUSPENDED

$ pactl list cards
  alsa.card_name = "lmi"
  Active Profile: HiFi

$ pactl list sources   # Mic1
  Mute: no
  Volume: front-left: 32768 / 50% / -18.06 dB, front-right: 32768 / 50% / -18.06 dB
```

Speaker playback was confirmed by ear with a 1 kHz tone; the sink reached RUNNING.

## Microphone capture

UCM Mic1 route (`HiFi.conf`):

```text
MultiMedia3 Mixer TX_CODEC_DMA_TX_3 = 1
TX DEC0 MUX     = SWR_MIC
TX SMIC MUX0    = 1          # enum index 1 = ADC0 -> TX SWR_ADC0 -> codec ADC1
TX_AIF1_CAP Mixer DEC0 = 1
ADC1_MIXER Switch = 1        # raw name; plain "ADC1_MIXER" does not exist
ADC1 Switch       = 1
ADC1 Volume       = 12       # +18 dB
CapturePCM        = hw:0,2
```

Fresh 4 s capture, quiet room, no music playing:

```text
$ parecord --device=alsa_input.platform-sound.HiFi__Mic1__source \
      --format=s16le --rate=48000 --channels=2 --file-format=raw /tmp/verify-mic.raw
capture_rc=0
-rw-r--r-- 756476 /tmp/verify-mic.raw
samples 378238  peak 2291  rms 82
```

Earlier loopback test (1 kHz from the phone speaker, same gain) measured peak 8069, i.e. the
route carries real audio and is not stuck at a constant value. Gain history:

| `ADC1 Volume` | Approx. gain | Result |
|---|---|---|
| 20 | +30 dB | peak 32768, hard clipping |
| 12 | +18 dB | loopback peak ~8 k, quiet room ~2.3 k, no clipping |

PulseAudio maps 50% source volume to about 7/10 of the hardware `ADC1 Volume` range.

DSP state: `dmesg | grep -cE 'q6adm|q6routing|q6asm'` was 2 before and 2 after the fresh
capture; the two lines are stale `ASM_STREAM_CMD_CLOSE` timeouts from earlier mid-session
experiments (1408 s / 1619 s uptime). A new capture adds no `q6adm`/`q6routing` errors.
See [`q6routing-reload-2026-10-24.md`](q6routing-reload-2026-10-24.md) for why only a full
reboot restores this state.

## Chinese input (fcitx5)

Session bus is private to phoc (`dbus-run-session`), so the bus address must be read from the
phoc environment when checking over SSH:

```sh
export XDG_RUNTIME_DIR=/run/user/10000
export WAYLAND_DISPLAY=wayland-0
export DBUS_SESSION_BUS_ADDRESS=$(tr '\0' '\n' < /proc/$(pgrep -x phoc | head -1)/environ \
    | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')

$ fcitx5-remote -n
pinyin
$ fcitx5-remote
2
```

Installed runtime files:

```text
-rwxr-xr-x /usr/bin/fcitx5-session-start
-rw-r--r-- /etc/xdg/autostart/fcitx5.desktop
```

`/etc/skel/.config/fcitx5/profile` has `DefaultIM=pinyin`. `/etc/skel/.phoshdebug` unsets
`GTK_IM_MODULE`/`QT_IM_MODULE` and sets `XMODIFIERS=@im=fcitx`. Pinyin preedit was observed in
the Phosh search field after login. The current session still inherits `QT_IM_MODULE=ibus`;
that is tracked in `HANDOFF.md` and does not affect GTK apps.

## Screenshot

```text
$ grim /tmp/verify-shot.png
-rw-r--r-- 103440 /tmp/verify-shot.png
```

PNG is 1080x2400. Artifact: [`desktop-r12-2026-10-24.png`](desktop-r12-2026-10-24.png) (Settings in Chinese,
300% scale, icons inset from the rounded corners).

## Caveats

- Bluetooth audio routing was not retested here.
- Microphone quality/level was checked with peak/RMS and a loopback tone, not with a speech
  intelligibility test.
- Playback and capture were tested while the session was unlocked; the lock screen does not
  change the ALSA state.
