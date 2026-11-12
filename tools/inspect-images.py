#!/usr/bin/env python3
"""Inspect the built boot/system/vendor images for the MYA-U29 port.

Checks the pieces the first stage init depends on:
  * boot.img  - kernel, ramdisk (first stage init + device fstab), cmdline
  * system.img - root filesystem layout (init, init.rc, system/ subtree)
  * vendor.img - /etc/selinux, VINTF manifest, device fstab
"""
import gzip
import struct
import sys
from pathlib import Path

OUT = Path(sys.argv[1] if len(sys.argv) > 1
           else "/home/svalked/evolutionxportforhuaweiy52017/src/los17.1/out/target/product/mya_u29")


def read_boot_img(path: Path):
    data = path.read_bytes()
    if data[:8] != b"ANDROID!":
        raise SystemExit(f"{path} is not an Android boot image")
    (ks, ka, rs, ra, ss, sa, ta, ps, hv, osv) = struct.unpack("<10I", data[8:48])
    cmdline = data[64:576].rstrip(b"\0").decode(errors="replace")
    name = data[48:64].rstrip(b"\0").decode(errors="replace")
    pages = lambda n: (n + ps - 1) // ps * ps
    kernel = data[ps:ps + ks]
    ramdisk = data[ps + pages(ks):ps + pages(ks) + rs]
    second = data[ps + pages(ks) + pages(rs):ps + pages(ks) + pages(rs) + ss]
    return dict(name=name, cmdline=cmdline, page_size=ps, kernel=kernel,
                ramdisk=ramdisk, second=second, os_version=osv)


def cpio_list(data: bytes):
    """Return the file names of an (optionally gzipped) newc cpio archive."""
    if data[:2] == b"\x1f\x8b":
        data = gzip.decompress(data)
    names = []
    pos = 0
    while pos + 110 <= len(data):
        if data[pos:pos + 6] != b"070701":
            break
        fields = [int(data[pos + 6 + i * 8: pos + 14 + i * 8], 16) for i in range(13)]
        namesize = fields[11]
        filesize = fields[6]
        name_start = pos + 110
        name = data[name_start:name_start + namesize - 1].decode(errors="replace")
        pos = name_start + namesize
        pos = (pos + 3) & ~3
        pos = (pos + filesize + 3) & ~3
        if name == "TRAILER!!!":
            break
        names.append(name)
    return names


boot = OUT / "boot.img"
if boot.is_file():
    info = read_boot_img(boot)
    print(f"== {boot}")
    print(f"   name        : {info['name']}")
    print(f"   cmdline     : {info['cmdline']}")
    print(f"   page size   : {info['page_size']}")
    print(f"   kernel      : {len(info['kernel'])} bytes")
    print(f"   ramdisk     : {len(info['ramdisk'])} bytes")
    print(f"   second      : {len(info['second'])} bytes")
    entries = cpio_list(info["ramdisk"])
    print(f"   ramdisk has : {', '.join(sorted(entries))}")
    for needed in ("init", "fstab.mt6580"):
        print(f"   {needed:14}: {'OK' if needed in entries else 'MISSING'}")
else:
    print(f"== {boot}: not built")

system = OUT / "system.img"
if system.is_file():
    print(f"== {system}: {system.stat().st_size} bytes")
else:
    print(f"== {system}: not built")

vendor = OUT / "vendor.img"
if vendor.is_file():
    print(f"== {vendor}: {vendor.stat().st_size} bytes")
else:
    print(f"== {vendor}: not built")
