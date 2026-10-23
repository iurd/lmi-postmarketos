# Runtime

The device package installs these files; the current device has equivalent manual copies.

## Display scale

`/etc/phosh/phoc.ini`:

```ini
[output:DSI-1]
scale = 3
```

The tested setup uses 300% as the normal phone density (1080x2400 → 360x800 logical).

## Chinese UI

- Packages: `font-noto-cjk`, `musl-locales`, and the `-lang` packages
- `/etc/locale.conf`: `LANG=zh_CN.UTF-8`
- Session environment: `/etc/skel/.phoshdebug` (installed by the device package), sourced by the unmodified upstream `phosh-session`:

```sh
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_COLLATE=C
export G_RESOURCE_OVERLAYS=/mobi/phosh/gmobile/devices/display-panels/xiaomi,lmi.json=/usr/share/gmobile-lmi/xiaomi,lmi.json
```

For an existing user, place the same file at `~/.phoshdebug` and log in again.

There is no Chinese input method: Phosh's OSK (stevia/squeekboard) has no pinyin layout. The UI is translated, but typing Chinese needs a separate fcitx5/input-method integration.

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
