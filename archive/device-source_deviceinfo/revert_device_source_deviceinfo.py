from pathlib import Path

P = Path("~/pmaports-lmi/device/testing/device-xiaomi-lmi/APKBUILD")
s = P.read_text()

block = (
    "\n"
    "\t# Newer postmarketos-base triggers source this path\n"
    "\tinstall -Dm644 \"$srcdir/deviceinfo\" \\\n"
    "\t\t\"$pkgdir/usr/share/misc/source_deviceinfo\"\n"
)
if block in s:
    s = s.replace(block, "", 1)
    print("removed source_deviceinfo install")
else:
    print("source_deviceinfo block not present")

if "pkgver=1\npkgrel=2\n" in s:
    print("pkgrel already 2")
elif "pkgver=1\npkgrel=1\n" in s:
    s = s.replace("pkgver=1\npkgrel=1\n", "pkgver=1\npkgrel=2\n", 1)
    print("pkgrel -> 2")
else:
    raise SystemExit("pkgrel block not found")

P.write_text(s)
print("package() block:")
start = s.index("package()")
print(s[start:start + 500])
