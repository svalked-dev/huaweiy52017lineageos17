#!/bin/bash
# Prepare an Android 10 / LineageOS 17.1 checkout for the MYA-U29 port.
#
#   ./setup.sh /path/to/los17.1 [--build]
#
# The script
#   1. copies the device tree from this repository into the checkout,
#   2. applies the AOSP patches from patches/,
#   3. patches the fstab inside the prebuilt vendor image (cust -> /vendor),
#   4. optionally starts the build.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE="${1:?usage: setup.sh <path-to-checkout> [--build]}"
DO_BUILD=0
[ "${2:-}" = "--build" ] && DO_BUILD=1

[ -d "$TREE/build/make" ] || { echo "not an Android checkout: $TREE"; exit 1; }

echo "== 1/4 device tree =="
mkdir -p "$TREE/device/huawei"
rm -rf "$TREE/device/huawei/mya_u29"
cp -a "$HERE/device/huawei/mya_u29" "$TREE/device/huawei/"
echo "   -> $TREE/device/huawei/mya_u29"

echo "== 2/4 patches =="
for patch in "$HERE"/patches/*.patch; do
    [ -e "$patch" ] || continue
    name="$(basename "$patch")"
    # Skip patches that are already applied.
    if git -C "$TREE" apply --check "$patch" 2>/dev/null; then
        git -C "$TREE" apply "$patch" && echo "   applied $name"
    else
        echo "   skipped  $name (already applied or conflicting)"
    fi
done

echo "== 3/4 vendor image =="
VENDOR="$TREE/vendor/alps/g81/proprietary/vendor.img"
if [ -f "$VENDOR" ]; then
    if command -v debugfs >/dev/null 2>&1; then
        python3 "$HERE/device/huawei/mya_u29/tools/patch-vendor-fstab.py" \
            "$VENDOR" "$HERE/device/huawei/mya_u29/rootdir/fstab.mt6580" \
            || echo "   !! vendor patch failed (continuing)"
    else
        echo "   debugfs not found - install e2fsprogs to patch the vendor image"
    fi
else
    echo "   vendor image missing (run 'repo sync' with git-lfs enabled)"
fi

if [ "$DO_BUILD" = "1" ]; then
    echo "== 4/4 build =="
    cd "$TREE"
    export TOP="$TREE"
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch evolution_mya_u29-userdebug
    m -j"$(nproc)" bacon
else
    echo "== 4/4 build: skipped (use --build) =="
fi
