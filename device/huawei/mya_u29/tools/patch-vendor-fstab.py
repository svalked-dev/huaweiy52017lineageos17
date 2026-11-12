#!/usr/bin/env python3
"""Install the MYA-U29 device fstab into the prebuilt vendor image.

The G81 vendor image ships an fstab that mounts a "vendor" partition and
carries a malformed "encryptable=<path>," flag.  On the MYA-U29 the vendor
payload lives in the MTK "cust" partition and vold needs the real metadata
device, so the fstab inside the vendor image is replaced with the device fstab
from rootdir/fstab.mt6580.

Usage: patch-vendor-fstab.py <vendor.img> <fstab.mt6580>
"""
import subprocess
import sys
from pathlib import Path

image = Path(sys.argv[1])
fstab = Path(sys.argv[2])
target = "/etc/fstab.mt6580"

if not image.is_file():
    sys.exit(f"missing vendor image: {image}")
if not fstab.is_file():
    sys.exit(f"missing fstab: {fstab}")


def debugfs(command: str) -> None:
    result = subprocess.run(
        ["debugfs", "-w", "-R", command, str(image)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(f"debugfs failed ({command}): {result.stderr.strip()}")


# Replace the file in place: remove the old entry first so that the new inode
# does not inherit the old (larger) block allocation.
debugfs(f"rm {target}")
debugfs(f"write {fstab} {target}")
debugfs(f"set_inode_field {target.lstrip('/')} mode 33188")

# Verify the result.
dump = subprocess.run(
    ["debugfs", "-R", f"cat {target}", str(image)],
    capture_output=True,
    text=True,
)
if dump.stdout.strip() != fstab.read_text().strip():
    sys.exit("fstab verification failed")
print(f"patched {image} ({target})")
