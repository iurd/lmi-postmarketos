# Troubleshooting

## Boot returns to fastboot

Expected with the current workaround: `boot` contains a pmOS image the bootloader rejects. Boot `recovery` (key combo) instead. Do not assume the flash failed.

## No SSH

- There is no `adbd`; use the UI or configure SSH yourself.
- The lock screen cannot join an SSID. Log in first, then configure Wi-Fi in Settings. Generic images contain no Wi-Fi credentials.
- Check nftables: `nft list ruleset`; TCP 22 must be accepted.
- Keep a local console/TWRP path before changing firewall rules.

## Black screen but services are up

- Check the panel driver, backlight enable and DSI errors.
- “connector connected” or `/dev/fb0` alone does not mean the panel is lit.
- Read `docs/01-evaluation.md` and the display notes before changing DSC/panel parameters.

## UI is English

- Check `~/.phoshdebug` exists and is sourced at login.
- Check `/etc/locale.conf` and the installed `-lang` packages.
- Log out/in after changing session environment.

## Icons still touch the corners

- Confirm `G_RESOURCE_OVERLAYS` points at the panel JSON.
- Confirm `gsettings get sm.puri.phosh shell-layout` is `device`.
- The radius 150 is tuned for scale 3; changing scale or resolution may require retuning.
- Do not use CSS padding or `LD_PRELOAD` hacks; they do not work with Phosh 0.58.

## No battery

- `lsmod | grep qcom_fg`; module must match `uname -r`.
- `upower -i /org/freedesktop/UPower/devices/battery_qcom_battery`.
- Kernel package must include `CONFIG_BATTERY_QCOM_FG=m`.

## Wi-Fi password field has no keyboard

The lock screen cannot join an SSID, so log in first. In a Phosh session the OSK can be hidden even when a text field is focused:

1. **Long-press the bottom home bar** (~0.5 s) to unfold the on-screen keyboard, then tap the password field.
2. Check **Settings → Accessibility → Screen Keyboard** is enabled.
3. If the OSK service crashed, **log out and back in** (the login screen uses the OSK too) to restart squeekboard/stevia.
4. Make sure the Wi-Fi password dialog is actually open; tap the network name and wait for the dialog before tapping the entry.
5. As a temporary workaround, a USB-C or Bluetooth keyboard may work if OTG/Bluetooth is available.

Bring-up images use `squeekboard`; the generic images use Phosh's default `stevia`.

## Firewall locked me out

Arm a flush before applying rules:

```sh
nohup sh -c 'sleep 60; [ -f /tmp/nft.cancel ] || nft flush ruleset' &
# apply rules, verify SSH, then:
touch /tmp/nft.cancel
```

## Screenshots do not work

Phoc lacks `wlr-screencopy`; grim and similar tools fail. UI checks are visual.

## Modem/camera/fingerprint

Not supported. Do not spend time on userspace configuration; the mainline kernel lacks the required drivers.
