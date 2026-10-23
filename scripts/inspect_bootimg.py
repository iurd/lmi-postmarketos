import struct
import sys
from pathlib import Path


def inspect(path: str) -> None:
    p = Path(path)
    data = p.read_bytes()
    print(f"== {p} ==")
    print("size:", len(data))
    if data[:8] != b"ANDROID!":
        print("not an Android boot image")
        return
    fields = struct.unpack_from("<10I", data, 8)
    (kernel_size, kernel_addr, ramdisk_size, ramdisk_addr,
     second_size, second_addr, tags_addr, page_size,
     header_version, os_version) = fields
    name = data[48:64].split(b"\0")[0]
    cmdline = data[64:576].split(b"\0")[0]
    print("header_version:", header_version)
    print("page_size:", page_size)
    print("kernel:", kernel_size, hex(kernel_addr))
    print("ramdisk:", ramdisk_size, hex(ramdisk_addr))
    print("second:", second_size, hex(second_addr))
    print("tags:", hex(tags_addr))
    print("name:", name)
    print("cmdline:", cmdline[:200])
    if header_version >= 2 and len(data) >= 1660:
        dtb_size, dtb_addr = struct.unpack_from("<2I", data, 1648)
        print("dtb:", dtb_size, hex(dtb_addr))
    # AVB footer
    idx = data.rfind(b"AVBf")
    print("AVBf offset:", idx if idx >= 0 else "none")
    # FDT magic occurrences
    fdt = []
    start = 0
    while True:
        i = data.find(b"\xd0\x0d\xfe\xed", start)
        if i < 0:
            break
        fdt.append(i)
        start = i + 1
        if len(fdt) > 10:
            break
    print("FDT offsets:", fdt)
    print("tail:", data[-64:].hex())


for arg in sys.argv[1:]:
    inspect(arg)
    print()
