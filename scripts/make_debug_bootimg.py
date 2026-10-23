import hashlib
from pathlib import Path

SRC = Path("./out/boot.img")
DST = Path("./out/boot-debug.img")

UUID_BOOT = "1bcf534c-2c4d-456f-a2ca-4498e06137cd"
UUID_ROOT = "87a30662-0133-4f46-92ba-b53a2ef0821f"
cmd = (
    "loglevel=7 pmos.debug-shell "
    f"pmos_boot_uuid={UUID_BOOT} pmos_root_uuid={UUID_ROOT} "
    "pmos_rootfsopts=defaults"
).encode()

data = bytearray(SRC.read_bytes())
assert data[:8] == b"ANDROID!"
assert len(cmd) < 512, len(cmd)
data[64:64 + 512] = cmd.ljust(512, b"\0")
DST.write_bytes(data)

print("cmdline:", cmd.decode())
print("size:", len(data))
print("sha256:", hashlib.sha256(data).hexdigest())
