# Runtime

The device package installs these files; the current device runs `device-xiaomi-lmi-1-r12` directly.

## Display scale

`/etc/phosh/phoc.ini`:

```ini
[output:DSI-1]
scale = 3
```

The tested setup uses 300% as the normal phone density (1080x2400 → 360x800 logical).

The bring-up device's personal Wi-Fi profile and debug SSH keys were removed after verification. Generic builds contain no Wi-Fi credentials or authorized keys.

## Chinese UI

- Packages: `font-noto-cjk`, `musl-locales`, and the `-lang` packages
- `/etc/locale.conf`: `LANG=zh_CN.UTF-8`
- Session environment: `/etc/skel/.phoshdebug` (installed by the device package), sourced by the unmodified upstream `phosh-session`:

```sh
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_COLLATE=C
export G_RESOURCE_OVERLAYS=/mobi/phosh/gmobile/devices/display-panels/xiaomi,lmi.json=/usr/share/gmobile-lmi/xiaomi,lmi.json
unset GTK_IM_MODULE QT_IM_MODULE
export XMODIFIERS=@im=fcitx
```

For an existing user, place the same file at `~/.phoshdebug` and log in again.

## Chinese input (fcitx5)

Chinese pinyin input uses fcitx5's native Wayland input method (`zwp_input_method_v2`), not IBus.

- Packages: `fcitx5`, `fcitx5-chinese-addons`, `fcitx5-gtk`
- `/etc/skel/.config/fcitx5/profile` sets `DefaultIM=pinyin` with a `keyboard-us` + `pinyin` group
- `/usr/bin/fcitx5-session-start` runs `fcitx5 -d --replace`, then retries `fcitx5-remote -s pinyin` for up to 10 s
- `/etc/xdg/autostart/fcitx5.desktop` (also copied to `/etc/phrog/autostart/`) starts it at login
- `.phoshdebug` unsets `GTK_IM_MODULE`/`QT_IM_MODULE` and sets `XMODIFIERS=@im=fcitx`

Verify from SSH; phoc runs under a private `dbus-run-session` bus, so take the address from the phoc process:

```sh
export XDG_RUNTIME_DIR=/run/user/10000 WAYLAND_DISPLAY=wayland-0
export DBUS_SESSION_BUS_ADDRESS=$(tr '\0' '\n' < /proc/$(pgrep -x phoc | head -1)/environ \
    | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
fcitx5-remote -n     # expect: pinyin
```

Order matters when changing the profile: stop fcitx5, write the profile, then start it. Writing while it runs gets overwritten with `keyboard-us`.

Qt apps may still inherit `QT_IM_MODULE=ibus` from the distro session environment; GTK input works.

## Audio

ALSA card is `lmi` (DTS `sound.model = "lmi"`); the UCM lives in `/usr/share/alsa/ucm2/Xiaomi/lmi/` and is symlinked into `conf.d/sm8250`, `conf.d/snd-sm8250` and `conf.virt.d`.

- Speaker: PulseAudio `HiFi` profile → `alsa_output.platform-sound.HiFi__Speaker__sink`
- Mic: `alsa_input.platform-sound.HiFi__Mic1__source`; route `TX_CODEC_DMA_TX_3` → `TX SMIC MUX0=ADC0` → `ADC1`; gain `ADC1 Volume=12`
- Raw control names matter: `ADC1_MIXER Switch`, `ADC1 Switch`, `ADC1 Volume`
- `ADC1 Volume=20` clips; 12 is +18 dB

Do not remove `/usr/share/wireplumber/wireplumber.conf.d/51-pulseaudio.conf`; without it WirePlumber takes the card and PulseAudio sinks stay suspended.

After changing UCM or codec routing, reboot. Unbinding/rebinding the card leaves WCD938x ADC controls missing and keeps ADM errors (`q6adm ... 0x10325 error 0x2`). See [`verification/q6routing-reload-2026-10-24.md`](https://github.com/iurd/lmi-postmarketos/blob/main/verification/q6routing-reload-2026-10-24.md).

```sh
pactl list cards            # Active Profile: HiFi
pactl list short sources    # Mic1 source
parecord --device=alsa_input.platform-sound.HiFi__Mic1__source \
    --format=s16le --rate=48000 --channels=2 --file-format=wav /tmp/mic.wav
```

## Rounded corners

Phosh 0.58 only runs corner compensation when gmobile has panel data for the device. lmi had no entry, so `panel == NULL` and the corner-shift code never ran. `runtime/xiaomi,lmi.json` supplies:

```json
{
  "name": "Xiaomi Redmi K30 Pro Zoom",
  "x-res": 1080,
  "y-res": 2400,
  "corner-radii": [150, 150, 150, 150],
  "cutouts": []
}
```

It is installed at `/usr/share/gmobile-lmi/xiaomi,lmi.json` and injected with `G_RESOURCE_OVERLAYS` from `.phoshdebug`. 150 is tuned for scale 3; it is not a measured hardware radius.

The older CSS-padding and `LD_PRELOAD` attempts never took effect and were removed; see `archive/`.

## Battery

The kernel tree already contained `drivers/power/supply/qcom_fg.c` (PM8150B fuel gauge), but it was not wired into Kconfig/Makefile. The kernel package applies the Kconfig/Makefile patch with `CONFIG_BATTERY_QCOM_FG=m` and installs `qcom_fg.ko`; udev autoloads it from the `of:N*T*Cqcom,pm8150b-fg` modalias. The current device also has `qcom_fg` in `/etc/modules` as a fallback.

Verify:

```sh
lsmod | grep qcom_fg
upower -i /org/freedesktop/UPower/devices/battery_qcom_battery
```

## Screenshots

`grim` works on the current Phoc despite older notes claiming there is no `wlr-screencopy`:

```sh
export XDG_RUNTIME_DIR=/run/user/10000 WAYLAND_DISPLAY=wayland-0
grim /tmp/shot.png      # 1080x2400 PNG
```

## nftables

The pmOS base ruleset already allows SSH via `50_sshd.nft`. `60_lmi.nft` adds:

```nft
table inet filter {
	chain input {
		udp sport 67 udp dport 68 accept comment "DHCP client replies"
		udp dport 5353 accept comment "mDNS"
	}
}
```

The service is enabled in `default` (`rc-update add nftables default`) and passes `nft -c -f /etc/nftables.nft`. Runtime start/restart, SSH, ping and DNS were verified; cold boot is pending.

If a rule change risks locking out SSH, arm a rollback first:

```sh
nohup sh -c 'sleep 60; [ -f /tmp/nft.cancel ] || nft flush ruleset' &
```
