from pathlib import Path

P = Path("~/pmaports-lmi/device/testing/device-xiaomi-lmi/APKBUILD")
s = P.read_text()

old_rel = "pkgver=1\npkgrel=0\n"
new_rel = "pkgver=1\npkgrel=1\n"
if old_rel in s:
    s = s.replace(old_rel, new_rel, 1)
    print("pkgrel -> 1")
elif "pkgver=1\npkgrel=1\n" in s:
    print("pkgrel already 1")
else:
    raise SystemExit("pkgrel block not found")

marker = "\tdevicepkg_package $startdir $pkgname\n"
addition = (
    "\n"
    "\t# Newer postmarketos-base triggers source this path\n"
    "\tinstall -Dm644 \"$srcdir/deviceinfo\" \\\n"
    "\t\t\"$pkgdir/usr/share/misc/source_deviceinfo\"\n"
)
if "usr/share/misc/source_deviceinfo" not in s:
    if marker not in s:
        raise SystemExit("devicepkg_package marker not found")
    s = s.replace(marker, marker + addition, 1)
    print("added source_deviceinfo install")
else:
    print("source_deviceinfo already present")

P.write_text(s)
print(P.read_text())
