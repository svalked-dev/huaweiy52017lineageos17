# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Inherit from our custom product
$(call inherit-product, device/huawei/mya_u29/device.mk)

# Device identifier. Must come after all inheritance specs
PRODUCT_BRAND := Evolution
PRODUCT_DEVICE := mya_u29
PRODUCT_NAME := evolution_mya_u29
PRODUCT_MODEL := MYA-U29
PRODUCT_MANUFACTURER := Huawei

# Evolution X branding
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.modversion=EvolutionX-4.5-mya_u29-20261112-OFFICIAL \
    ro.evolution.version=4.5 \
    ro.evolution.releasetype=OFFICIAL

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=MYA-U29 \
    PRODUCT_NAME=evolution_mya_u29 \
    BUILD_FINGERPRINT="evolution/mya_u29/mya_u29:10/QQ3A.200805.001/eng.svalked.20261112:userdebug/dev-keys"
