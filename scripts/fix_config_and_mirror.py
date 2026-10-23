import configparser
import hashlib
import shutil
from pathlib import Path

CFG = Path("~/.config/pmbootstrap_v3.cfg")
APK = Path("~/pmaports-lmi/device/testing/linux-postmarketos-qcom-sm8250-lmi/APKBUILD")
KCFG = Path("~/pmaports-lmi/device/testing/linux-postmarketos-qcom-sm8250-lmi/config-postmarketos-qcom-sm8250-lmi.aarch64")
SRC_CFG = Path("~/Linux-redmi-k30pro-6.19-6.19/.output/.config")
TARBALL = Path("~/linux-lmi.tar.gz")
TARBALL_NAME = "linux-postmarketos-qcom-sm8250-lmi-lmi.tar.gz"
CONFIG_NAME = KCFG.name

c = configparser.ConfigParser()
c.read(CFG)
if "mirrors" not in c:
    c["mirrors"] = {}
c["mirrors"]["alpine"] = "https://mirrors.tuna.tsinghua.edu.cn/alpine/"
c["mirrors"]["pmaports"] = "https://mirror.postmarketos.org/postmarketos/"
with CFG.open("w") as f:
    c.write(f)
print("mirrors:", dict(c["mirrors"]))

shutil.copyfile(SRC_CFG, KCFG)
print("kernel config copied, lines:", len(KCFG.read_text().splitlines()))

def sha512(p: Path) -> str:
    h = hashlib.sha512()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

kernel_hash = sha512(TARBALL)
config_hash = sha512(KCFG)
print("kernel hash:", kernel_hash)
print("config hash:", config_hash)

lines = APK.read_text().splitlines()
out = []
for line in lines:
    if line.endswith("  " + TARBALL_NAME):
        line = f"{kernel_hash}  {TARBALL_NAME}"
    elif line.endswith("  " + CONFIG_NAME):
        line = f"{config_hash}  {CONFIG_NAME}"
    out.append(line)
APK.write_text("\n".join(out) + "\n")
print("APKBUILD hashes updated")
for line in APK.read_text().splitlines():
    if line.endswith(TARBALL_NAME) or line.endswith(CONFIG_NAME) or line.startswith("builddir="):
        print(line)
