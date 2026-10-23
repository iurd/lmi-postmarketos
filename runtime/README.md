# runtime/

Runtime defaults installed by the device package (or copied manually to the device).

| File | Device path | Purpose |
|---|---|---|
| `xiaomi,lmi.json` | `/usr/share/gmobile-lmi/xiaomi,lmi.json` | gmobile panel data: 1080x2400, corner radius 150 |
| `phoshdebug` | `~/.phoshdebug` / `/etc/skel/.phoshdebug` | session language + `G_RESOURCE_OVERLAYS` |
| `phoc.ini` | `/etc/phosh/phoc.ini` | `scale = 3` |
| `60_lmi.nft` | `/etc/nftables.d/60_lmi.nft` | DHCP client replies + mDNS |

`phoshdebug` is sourced by the upstream `phosh-session` script; `phosh-session` itself is unmodified.

After copying, log out and back in so the session environment is applied. The panel JSON is loaded by Phosh at startup; restart the session after changing it.
