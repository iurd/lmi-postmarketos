# verification/

Build and runtime verification records for the packages and the device.

- `build-2026-10-24.md` — package build result, hashes and contents
- `runtime-2026-10-24.md` — device-side runtime checks (UI, corners, battery, nftables)
- `runtime-2026-10-24-audio-mic-ime.md` — UCM speaker/Mic1, ADC1 gain, PulseAudio, fcitx5, grim
- `q6routing-reload-2026-10-24.md` — ADM/q6routing failure modes; full reboot requirement
- `live-audit-2026-10-24.md` — read-only postmarketOS-category audit after Wi-Fi reconnection
- `desktop-r12-2026-10-24.png` — grim screenshot of the Chinese desktop at 300% scale
- The running kernel config is in `patches/config-6.19.0-rc8-sm8250-running`

This directory should contain logs and hashes, not firmware, backups or secrets.
