# MYA-U29 device tree — Evolution X 4.5 (LineageOS 17.1)

Device tree for the **Huawei MYA-U29** (MT6580, ARMv7 / cortex-a7, 1 GiB RAM,
480×854, legacy 3.18.79 kernel). The port is a **port of Evolution X 4.5**
(Evolution X is built on top of LineageOS 17.1 / Android 10), product
`evolution_mya_u29`, base branch `lineage-17.1`.

Nothing of this kind existed for this phone before: there was no working
LineageOS 17.1 / Evolution X 4.5 build for the MYA-U29, so the tree was created
from scratch on top of the public G81 (same SoC) sources.

## Layout

| Partition | Block | Content |
|---|---|---|
| `system` | `mmcblk0p23` | LineageOS 17.1 system image (3 GiB) |
| `cust` | `mmcblk0p24` | **vendor image** (400 MiB) — mounted as `/vendor` |
| `boot` | `mmcblk0p8` | G81 prebuilt kernel + ramdisk with first-stage init |

There is **no `vendor` partition** on this device: the vendor payload lives in
the MTK `cust` partition. `recovery.fstab`, `rootdir/fstab.mt6580` and the
patched fstab inside the vendor image all reflect that.

`data`, `nvram` and `oeminfo` are not touched by the port.

## Boot flow

* The MTK bootloader starts the kernel with `root=/dev/ram`, so the boot image
  keeps a ramdisk with the first-stage `init`.
* `androidboot.hardware=mt6580` is part of `BOARD_KERNEL_CMDLINE` so that
  `fs_mgr` can find `/fstab.mt6580` before any partition is mounted.
* The first stage mounts `/system` and `/vendor` (`first_stage_mount` entries)
  and pivots into `/system`.
* The generic AOSP 10 `init.rc` does not call `mount_all`, so the device
  `rootdir/init.mt6580.rc` mounts the remaining partitions explicitly.
* `ro.hardware` is set through `PRODUCT_SYSTEM_DEFAULT_PROPERTIES`, because in
  Lineage 17.1 the `PRODUCT_DEFAULT_PROPERTY_OVERRIDES` bucket does not reach
  `default.prop`.

## Files

| Path | Purpose |
|---|---|
| `BoardConfig.mk` | architecture, partition sizes, kernel, recovery fstab, screen |
| `device.mk` | product configuration, proprietary copies, device packages |
| `evolution_mya_u29.mk` | product definition and Evolution X 4.5 branding |
| `rootdir/fstab.mt6580` | device fstab: `system → /system`, `cust → /vendor` |
| `rootdir/init.mt6580.rc` | device init: `mount_all`, MTK Wi-Fi/GPS/PQ fixes |
| `rootdir/vendor_file_contexts` | labels used before the vendor partition is up |
| `sepolicy/` | device policy fragments (`hal_health_default`, `mtk_hal_audio`) |
| `tools/patch-vendor-fstab.py` | replaces the G81 fstab inside the vendor image |

The vendor payload itself is a pinned prebuilt image
(`vendor/alps/g81/proprietary/vendor.img`, Git LFS) that carries the legacy MTK
HALs, the vendor `nonplat_sepolicy.cil` and the VINTF manifest. It must not be
replaced with arbitrary stock or GSI vendor input.

The kernel is the prebuilt G81 `zImage` from
`vendor/alps/g81/device-prebuilts/kernel`; no kernel source tree is part of
this repository.

## Building

See the repository root `README.md` — the port is built as
`lunch evolution_mya_u29-userdebug && m bacon`.
