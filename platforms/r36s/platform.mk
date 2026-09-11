UBOOT_DEFCONFIG := r36s_defconfig
UBOOT_IMAGE := u-boot-rockchip.bin

# build TF-A from source
TFA_PLAT := px30
TFA_TARGET := bl31

# use TF-A Rockchip blob
# ATF ?= $(ROOT_DIR)/prebuilt/rk3326_bl31_v1.33.elf