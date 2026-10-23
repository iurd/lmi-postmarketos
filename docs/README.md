# Documentation

| File | Content |
|---|---|
| `00-project-conventions.md` | Project scope, safety rules and conventions |
| `01-evaluation.md` | Feasibility evaluation, routes and risks |
| `02-sources.md` | Upstream/community sources and original support matrix |
| `03-device-audit.md` | Android-side device audit and partition map |
| `04-build.md` | Build environment, patches and commands |
| `05-flash-and-first-boot.md` | Backup, recovery-only flash path, first boot and rollback |
| `06-runtime.md` | Chinese UI, corners, battery, nftables, cleanup and rollback |

The wiki under `../wiki/` is a guided version of these notes. The repository README has the short overview.

Raw `fastboot getvar all` output, partition backups, firmware and images are intentionally not included: they contain device-specific data or are too large. Use your own backups and replace the placeholders in the commands.
