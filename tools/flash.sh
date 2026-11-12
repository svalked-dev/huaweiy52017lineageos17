#!/bin/bash
# Flash the Evolution X 4.5 (LineageOS 17.1) images onto the MYA-U29.
#
# The phone is connected over ADB with adbd running as root (it does not have
# to boot into TWRP - the block devices are reachable from the running system).
# Images are streamed over the ADB stdin channel, so no free space on the
# phone is required.
#
# Usage: flash.sh [out-dir] [skip-system] [skip-vendor] [skip-boot]
set -euo pipefail

PROJECT="/home/svalked/evolutionxportforhuaweiy52017"
OUT="${1:-$PROJECT/src/los17.1/out/target/product/mya_u29}"
SKIP_SYSTEM="${2:-0}"
SKIP_VENDOR="${3:-0}"
SKIP_BOOT="${4:-0}"
BLK=/dev/block/mmcblk0

flash() {
    local img="$1" dst="$2"
    local src="${OUT}/${img}"
    [ -f "$src" ] || { echo "!! missing ${src}"; return 1; }
    echo "== ${img} ($(stat -c%s "$src") bytes) -> ${dst} =="
    # Feed the image straight into dd on the device (dd reads stdin when no
    # if= is given; Android's toybox has no /dev/stdin).
    adb shell "dd of=${dst} bs=4194304 conv=fsync 2>&1 | tail -2" < "$src"
}

echo "== waiting for adb =="
adb wait-for-device
adb root >/dev/null 2>&1 || true
sleep 2
adb shell id || { echo "no root shell"; exit 1; }

# The running system lives on the very partition we are about to overwrite.
adb shell "umount /system 2>/dev/null; umount -l /system 2>/dev/null; sync" || true
adb shell "umount /vendor 2>/dev/null; umount -l /vendor 2>/dev/null; sync" || true

[ "$SKIP_SYSTEM" = "1" ] || flash system.img "${BLK}p23"
[ "$SKIP_VENDOR" = "1" ] || flash vendor.img "${BLK}p24"
[ "$SKIP_BOOT"  = "1" ] || flash boot.img   "${BLK}p8"

adb shell "sync"
echo "== done =="
