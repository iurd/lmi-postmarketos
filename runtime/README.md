# runtime/

Runtime defaults installed by the device package (or copied manually to the device).

| File | Device path | Purpose |
|---|---|---|
| `xiaomi,lmi.json` | `/usr/share/gmobile-lmi/xiaomi,lmi.json` | gmobile panel data: 1080x2400, corner radius 150 |
| `phoshdebug` | `~/.phoshdebug` / `/etc/skel/.phoshdebug` | session language, `G_RESOURCE_OVERLAYS`, IM env (`GTK_IM_MODULE`/`QT_IM_MODULE` unset, `XMODIFIERS=@im=fcitx`) |
| `phoc.ini` | `/etc/phosh/phoc.ini` | `scale = 3` |
| `60_lmi.nft` | `/etc/nftables.d/60_lmi.nft` | DHCP client replies + mDNS |
| `fcitx5-session-start` | `/usr/bin/fcitx5-session-start` | start fcitx5 and retry `fcitx5-remote -s pinyin` |
| `fcitx5.desktop` | `/etc/xdg/autostart/fcitx5.desktop` (also `/etc/phrog/autostart/`) | autostart entry |
| `fcitx5-profile` | `~/.config/fcitx5/profile` / `/etc/skel/.config/fcitx5/profile` | `DefaultIM=pinyin` |

`phoshdebug` is sourced by the upstream `phosh-session` script; `phosh-session` itself is unmodified.

After copying, log out and back in so the session environment is applied. The panel JSON is loaded by Phosh at startup; restart the session after changing it.

Audio UCM files live in the package (`packages/device-xiaomi-lmi/alsa-ucm-conf/`), not here: `lmi.conf` and `HiFi.conf` define the speaker and Mic1 routes and are symlinked into the ALSA lookup directories by the APKBUILD.

Checking fcitx5 over SSH requires the desktop bus address, because phoc runs under `dbus-run-session`:

```sh
eval "$(tr '\0' '\n' < /proc/$(pgrep -x phoc | head -1)/environ | grep -E '^(DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR)=' | sed 's/^/export /')"
fcitx5-remote -n    # -> pinyin
```
