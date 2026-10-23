# archive/

Failed or superseded approaches, kept so they are not retried blindly.

| Item | Why it is archived |
|---|---|
| `phosh-gtk.css`, `inspect_phosh_css.sh` | Phosh 0.58 does not apply the CSS padding; corners need gmobile panel data |
| `session-env` | Replaced by the upstream `$HOME/.phoshdebug` hook |
| `patch_rootfs_adbd*.sh` | Alpine `android-tools` has no adbd; Wi-Fi SSH is the real debug channel |
| `device-source_deviceinfo/` | `source_deviceinfo` is provided by `devicepkg-utils`; the patch was reverted |

These files are historical. Do not apply them to a current image without re-validating.
