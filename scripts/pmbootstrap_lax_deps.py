from pathlib import Path

P = Path("~/pmbootstrap/pmb/chroot/apk.py")
OLD = "pmb.build.packages(context, to_add, arch)"
NEW = "pmb.build.packages(context, to_add, arch, strict=False)"

s = P.read_text()
if NEW in s:
    print("already patched")
elif OLD in s:
    P.write_text(s.replace(OLD, NEW))
    print("patched apk.py dependency build to lax mode")
else:
    raise SystemExit("target line not found")
