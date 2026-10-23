from pathlib import Path

APK = Path("~/pmaports-lmi/device/testing/linux-postmarketos-qcom-sm8250-lmi/APKBUILD")
FILENAME = "linux-postmarketos-qcom-sm8250-lmi-lmi.tar.gz"
SHA = "b762763f6ebd75770da8e28decce39ad9840b0ea252d2798463834d67844acae0e3380e2ac2f2f92a8c1d8b27efab6f5d5246bd10eacfcdf3cad5ae99c9cbfe4"

s = APK.read_text()
if FILENAME in s and SHA in s:
    print("kernel source hash already present")
else:
    marker = 'sha512sums="\n'
    if marker not in s:
        raise SystemExit("sha512sums header not found")
    s = s.replace(marker, marker + f"{SHA}  {FILENAME}\n", 1)
    APK.write_text(s)
    print("added kernel source hash")

for line in APK.read_text().splitlines():
    if line.startswith("builddir=") or FILENAME in line or line.startswith("sha512sums="):
        print(line)
