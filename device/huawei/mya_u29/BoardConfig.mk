DEVICE_PATH := device/huawei/mya_u29

# Architecture: MT6580 is a 32-bit Cortex-A7 platform.
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_SMP := true
ARCH_ARM_HAVE_NEON := true
ARCH_ARM_HAVE_VFP := true
ARCH_ARM_HAVE_TLS_REGISTER := true

# Android Go / low-RAM allocator profile.
MALLOC_SVELTE := true

# Platform and bootloader.
TARGET_BOARD_PLATFORM := mt6580
TARGET_IGNORES_FTP_PPTP_CONNTRACK_FAILURE := true
TARGET_BOOTLOADER_BOARD_NAME := mya_u29
TARGET_NO_BOOTLOADER := true

BOARD_HAS_MTK_HARDWARE := true
BOARD_USES_MTK_HARDWARE := true
MTK_HARDWARE := true

# HWC2 configuration.
TARGET_USES_HWC2 := true

# Kernel (prebuilt G81 zImage)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_KERNEL_IMAGE_NAME := zImage
# Use our local compiled kernel (need to make sure we point to it correctly later)
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04000000
BOARD_TAGS_OFFSET := 0x0e000000
BOARD_KERNEL_PAGESIZE := 2048
# The MTK bootloader boots with root=/dev/ram, so the boot ramdisk holds the
# first stage init.  androidboot.hardware tells fs_mgr which device fstab to
# use (/fstab.mt6580) before any partition is mounted.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32S1,32S1 androidboot.hardware=mt6580
BOARD_MKBOOTIMG_ARGS := \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_TAGS_OFFSET)

# Partition layout
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
# System p23 3GB = 3221225472
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
# Cust p24 400MB = 419430400
BOARD_VENDORIMAGE_PARTITION_SIZE := 419430400
# The vendor payload is a verified prebuilt image (Android 10 MTK compatibility
# image, Git LFS object).  It is flashed to the "cust" partition and mounted
# as /vendor, so the image is used as-is instead of being rebuilt from source.
BOARD_PREBUILT_VENDORIMAGE := $(DEVICE_PATH)/prebuilt/vendor.img
# Cache p25 200MB = 209715200
BOARD_CACHEIMAGE_PARTITION_SIZE := 209715200
# Userdata p26 11152896KB = 11420557312
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11420557312

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_COPY_OUT_VENDOR := vendor
BOARD_HAS_LARGE_FILESYSTEM := true

# Recovery.
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
BOARD_HAS_NO_SELECT_BUTTON := true
RECOVERY_SDCARD_ON_DATA := true
RECOVERY_GRAPHICS_USE_LINELENGTH := true

# Screen
TARGET_SCREEN_WIDTH := 480
TARGET_SCREEN_HEIGHT := 854
TARGET_SCREEN_DENSITY := 240
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 128

# TWRP minimal settings
TW_EXTRA_LANGUAGES := false
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_TZDATA := true
TW_USE_TOOLBOX := true
TW_INCLUDE_CRYPTO := true
TW_HAS_MTP := true
TW_MTP_DEVICE := /dev/mtp_usb
TW_NO_CPU_TEMP := true
TW_REBOOT_RECOVERY := true

ALLOW_MISSING_DEPENDENCIES := true

# WiFi
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true

TARGET_OTA_ASSERT_DEVICE := MYA-U29
# Lineage soong config (exports kernel vars to soong)
include vendor/lineage/config/BoardConfigSoong.mk
