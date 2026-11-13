#!/usr/bin/env python3
"""Build a boot image from the stock MYA-U29 kernel and the port's ramdisk.

The prebuilt G81 kernel carries the G81 device tree (384x854 panel, G81
hardware), which does not match the MYA-U29.  The stock Huawei kernel that
came with the phone has the correct device tree, so it is used together with
the ramdisk produced by the port build (first stage init + device fstab).

Usage: build-boot-stock-kernel.py <stock-boot.img> <port-boot.img> <out.img>
"""
import struct
import sys
from pathlib import Path

BOOT_MAGIC = b"ANDROID!"
PAGE_SIZE = 2048


def read_boot(path: Path):
    data = path.read_bytes()
    if data[:8] != BOOT_MAGIC:
        raise SystemExit(f"{path}: not an Android boot image")
    fields = struct.unpack("<10I", data[8:48])
    ks, ka, rs, ra, ss, sa, ta, ps, hv, osv = fields
    name = data[48:64]
    cmdline = data[64:576]
    pages = lambda n: (n + ps - 1) // ps * ps
    off = ps
    kernel = data[off:off + ks]
    off += pages(ks)
    ramdisk = data[off:off + rs]
    return dict(kernel=kernel, ramdisk=ramdisk, kernel_addr=ka,
                ramdisk_addr=ra, tags_addr=ta, page_size=ps, name=name,
                cmdline=cmdline, os_version=osv)


def build(kernel, ramdisk, kernel_addr, ramdisk_addr, tags_addr, page_size,
          name, cmdline, os_version):
    def pad(data):
        return data + b"\0" * ((page_size - len(data) % page_size) % page_size)

    header = bytearray(1632)
    header[0:8] = BOOT_MAGIC
    struct.pack_into("<10I", header, 8,
                     len(kernel), kernel_addr, len(ramdisk), ramdisk_addr,
                     0, 0, tags_addr, page_size, 0, os_version)
    header[48:64] = name[:16]
    header[64:576] = cmdline[:511]
    return bytes(header) + pad(kernel) + pad(ramdisk)


def main():
    stock = read_boot(Path(sys.argv[1]))
    port = read_boot(Path(sys.argv[2]))
    out = Path(sys.argv[3])

    cmdline = (b"bootopt=64S3,32S1,32S1 androidboot.hardware=mt6580 "
               b"androidboot.selinux=permissive buildvariant=userdebug")
    image = build(stock["kernel"], port["ramdisk"], stock["kernel_addr"],
                  stock["ramdisk_addr"], stock["tags_addr"], stock["page_size"],
                  stock["name"], cmdline, stock["os_version"])
    out.write_bytes(image)
    print(f"kernel   : {len(stock['kernel'])} bytes (stock MYA-U29)")
    print(f"ramdisk  : {len(port['ramdisk'])} bytes (port)")
    print(f"cmdline  : {cmdline.decode()}")
    print(f"written  : {out} ({len(image)} bytes)")


if __name__ == "__main__":
    main()
