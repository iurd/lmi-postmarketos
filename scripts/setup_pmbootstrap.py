from pathlib import Path
import shutil
import time

APK = Path("~/pmaports-lmi/device/testing/linux-postmarketos-qcom-sm8250-lmi/APKBUILD")
OLD = 'builddir="$srcdir/linux-v6.19"'
NEW = 'builddir="$srcdir/Linux-redmi-k30pro-6.19-6.19"'

s = APK.read_text()
if OLD in s:
    APK.write_text(s.replace(OLD, NEW))
    print("patched builddir")
elif NEW in s:
    print("builddir already patched")
else:
    raise SystemExit("ERROR: builddir line not found")

cfg = Path("~/.config/pmbootstrap_v3.cfg")
cfg.parent.mkdir(parents=True, exist_ok=True)
if cfg.exists():
    backup = cfg.with_name(cfg.name + ".bak." + str(int(time.time())))
    shutil.copy2(cfg, backup)
    print("backup:", backup)

cfg.write_text("""[pmbootstrap]
aports = ~/pmaports-lmi
build_default_device_arch = True
ccache_size = 10G
device = xiaomi-lmi
extra_packages = none
hostname = lmi
is_default_channel = False
jobs = 6
locale = C.UTF-8
service_manager = openrc
ssh_keys = False
sudo_timer = False
timezone = Asia/Shanghai
ui = phosh
user = user
work = /root/.local/var/pmbootstrap

[providers]

[mirrors]
""")
print(cfg.read_text())
