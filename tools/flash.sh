#!/bin/bash
# Flash the Evolution X 4.5 (LineageOS 17.1) images onto the MYA-U29.
#
# Works from TWRP (adb in "recovery" state) or from a running system with adbd
# running as root.  The images are pushed to /data/local/tmp and written to
# the block devices with dd; /data needs roughly as much free space as the
# largest image.
#
# Usage: flash.sh [out-dir] [skip-system] [skip-vendor] [skip-boot]
set -euo pipefail

PROJECT="/home/svalked/evolutionxportforhuaweiy52017"
OUT="${1:-$PROJECT/src/los17.1/out/target/product/mya_u29}"
SKIP_SYSTEM="${2:-0}"
SKIP_VENDOR="${3:-0}"
SKIP_BOOT="${4:-0}"
BLK=/dev/block/mmcblk0

# "adb wait-for-device" never returns while the device reports the "recovery"
# state (TWRP), so poll the device list instead.
SERIAL=""
for _ in $(seq 1 60); do
    SERIAL="$(adb devices | awk 'NR>1 && $2 != "unauthorized" && $2 != "offline" {print $1; exit}')"
    [ -n "$SERIAL" ] && break
    sleep 2
done
[ -n "$SERIAL" ] || { echo "no device"; exit 1; }
echo "== device ${SERIAL} =="
adb -s "$SERIAL" root >/dev/null 2>&1 || true
sleep 2
adb -s "$SERIAL" shell id || { echo "no root shell"; exit 1; }

flash() {
    local img="$1" dst="$2"
    local src="${OUT}/${img}"
    local tmp="/data/local/tmp/${img}"
    [ -f "$src" ] || { echo "!! missing ${src}"; return 1; }
    # The build produces a sparse system image; partitions need a raw ext4.
    if [ "$(head -c4 "$src" | od -A n -t x1 | tr -d ' ')" = "ed26ff3a" ]; then
        echo "   (sparse image -> raw)"
        local raw="${OUT}/$(basename "$src" .img).raw.img"
        "${SIMG2IMG:-simg2img}" "$src" "$raw"
        src="$raw"
        tmp="/data/local/tmp/$(basename "$src")"
    fi
    echo "== ${img} ($(stat -c%s "$src") bytes) -> ${dst} =="
    adb -s "$SERIAL" push "$src" "$tmp"
    adb -s "$SERIAL" shell "dd if=${tmp} of=${dst} bs=4194304 conv=fsync 2>&1 | tail -2"
    adb -s "$SERIAL" shell "sync; rm -f ${tmp}"
}

# The running system may live on the very partitions we are about to overwrite.
adb -s "$SERIAL" shell "umount /system 2>/dev/null; umount -l /system 2>/dev/null; umount /vendor 2>/dev/null; umount -l /vendor 2>/dev/null; sync" || true

[ "$SKIP_SYSTEM" = "1" ] || flash system.img "${BLK}p23"
[ "$SKIP_VENDOR" = "1" ] || flash vendor.img "${BLK}p24"
[ "$SKIP_BOOT"  = "1" ] || flash boot.img   "${BLK}p8"

adb -s "$SERIAL" shell "sync"
echo "== done =="
