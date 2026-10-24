# Support matrix — postmarketOS categories

Status legend:

- ✅ verified working on this port
- 🟡 partial / limited
- ❌ not working
- ❓ not re-verified on this port (community may claim it works)
- 🧱 hard blocker

The “community” column is the pmOS/Nura wiki status for lmi. The device is currently offline
(personal Wi-Fi and SSH keys were removed), so items marked ❓ cannot be live-checked until a
network is configured again.

| Category | Community (pmOS/Nura wiki) | This port | Notes |
|---|---|---|---|
| Flashing | Works | ✅ | `fastboot flash recovery` + rootfs to `userdata` |
| Boot from `boot` | — | ❌ / 🧱 | Bootloader rejects pmOS on `boot` (AVB); recovery-only workaround |
| USB Net | Works | ❓ | USB enumerates as `POSTMARKETOS`; no `adbd`; gadget network not verified |
| Storage / UFS | Works | ✅ | UFS rootfs, nested image in `userdata` |
| Battery | Works | ✅ | PM8150B FG via `qcom_fg`; UPower `qcom-battery` |
| Screen | Works | ✅ / 🟡 | AMS667UU01 1080x2400 @60 Hz; brightness-change artifacts; 77 Hz not re-verified |
| Touch | Works | ✅ | FocalTech FT3518 |
| 3D / GPU | Works | ✅ | Adreno 650, Freedreno/Mesa |
| Audio | Works | ❓ | UCM/TFA9872 present; debug unit speaker physically damaged; headphone/mic not re-verified |
| Camera | Partial | 🟡 | OV13B10 raw + UVC/software ISP only; no full ISP/YUV; main/front/tele unusable |
| Camera flash | Works | ❓ | Not re-verified |
| IR | Works | ❓ | Not re-verified |
| Wi-Fi | Works | ✅ | QCA6391/ath11k |
| Bluetooth | Works | ❓ | Present, not re-verified in the latest pass |
| GPS | Broken | ❌ | Not supported |
| NFC | Works | ❓ / ❌ | Community claims NQ-NCI works; this port does not enable it |
| Modem (calls/SMS/data) | Broken | 🧱 | SDX55m mainline unsupported; diagnosis only (SBL/Sahara/MHI) |
| Fingerprint | Broken | ❌ | In-display fingerprint unsupported |
| Sensors (accel/mag/light) | Works | ❓ | Needs hexagonrpcd + signed SDSP firmware; not live-verified here |
| Proximity | Broken | ❌ | — |
| Haptics / vibration | Broken | ❌ | AW8697 not integrated |
| Charging | Works (basic) | 🟡 | PM8150B basic charging/battery; 33W private fast-charge/BQ2597x ❌ |
| USB OTG / roles | Partial | ❓ | Gadget/ACM/PD sink; host/role switching partial |
| Suspend / wake | — | ❓ | Not validated |
| Video | — | 🟡 | Venus H.264 encode bring-up; hardware decode not verified |
| Desktop / UI | — | ✅ | Phosh 0.58, Chinese UI, rounded-corner compensation |
| Chinese input | — | ❌ | No pinyin OSK (stevia/squeekboard) |
| Screenshots | — | ❌ | Phoc has no `wlr-screencopy` |
| Firewall (nftables) | — | ✅ / ❓ | Runtime verified; cold boot with nftables pending |
| Thermal | — | ❓ | Not validated |
| Hotspot / tethering | — | ❓ | nftables rules exist; not verified |
| Wi-Fi Display / Miracast | — | ❓ | Not implemented/verified |
| Battery health / cycles | — | ❌ | `charge-cycles: N/A` with the current driver |

## Still not working (short list)

- Mobile network: calls, SMS, mobile data, IMS/VoLTE (mainline SDX55m blocker)
- Camera as a phone camera (raw/UVC only; no ISP/YUV, front/tele not enabled)
- In-display fingerprint
- GPS
- Proximity sensor; haptics/vibration
- NFC (not enabled in this port; community claims it works)
- Booting from the `boot` partition (AVB)
- 33W private fast charging (BQ2597x)
- Chinese text input; screenshots
- Battery health/cycle count

## Needs a live re-check (device currently offline)

Bluetooth, audio (speaker/earphone/mic), USB gadget network, NFC, sensors (accel/mag/light),
IR, camera flash, hotspot/tethering, USB host/role switching, suspend/wake, thermal,
brightness stability, 77 Hz display, battery health.

To re-enable verification, configure Wi-Fi on the device and add an SSH key (or use the UI);
the repository contains no keys or credentials.