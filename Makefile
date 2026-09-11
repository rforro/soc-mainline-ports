BOARD ?= r36s
SHOW_SIZES ?= 1
COMPILE_ATF := 0
SD_BIN_FILE := sd_bootloader.img

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR ?= $(ROOT_DIR)/build

UBOOT_DIR ?= $(ROOT_DIR)/../u-boot
TFA_DIR   ?= $(ROOT_DIR)/../trusted-firmware-a

TOOLCHAIN_PATH ?= /opt/toolchain/arm-gnu-toolchain-15.3.rel1-x86_64-aarch64-none-linux-gnu/bin
CROSS_COMPILE ?= $(TOOLCHAIN_PATH)/aarch64-none-linux-gnu-

# include platform specific configuration values
PLATFORM_DIR := $(ROOT_DIR)/platforms/$(BOARD)
include $(PLATFORM_DIR)/platform.mk

UBOOT_BUILD := $(BUILD_DIR)/$(BOARD)/u-boot
TFA_BUILD   := $(BUILD_DIR)/$(BOARD)/tf-a

# use prebuilt ATF if specified, otherwise build TF-A from source
# older platform don't requiere ArmTrustedFirmware
ifneq ($(strip $(ATF)),)

BL31 := BL31=$(ATF)

else ifneq ($(strip $(TFA_PLAT)),)
ifneq ($(strip $(TFA_TARGET)),)

COMPILE_ATF := 1
BL31 := BL31=$(TFA_BUILD)/$(TFA_PLAT)/release/$(TFA_TARGET)/$(TFA_TARGET).elf

endif
endif
# end TF-A

.PHONY: all u-boot u-boot-menuconfig tfa rebuild clean distclean

all: tfa uboot

uboot: $(UBOOT_BUILD)/.config
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD) CROSS_COMPILE=$(CROSS_COMPILE) $(BL31) -j$(shell nproc)
ifeq ($(SHOW_SIZES),1)
	@for img in u-boot tpl/u-boot-tpl spl/u-boot-spl; do \
		if [ -f "$(UBOOT_BUILD)/$$img" ]; then \
			echo "== $$img =="; \
			"$(CROSS_COMPILE)size" "$(UBOOT_BUILD)/$$img"; \
			echo; \
		fi; \
	done
endif

uboot-menuconfig:
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD) CROSS_COMPILE=$(CROSS_COMPILE) savedefconfig

$(UBOOT_BUILD)/.config:
	mkdir -p $(UBOOT_BUILD)
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD) CROSS_COMPILE=$(CROSS_COMPILE) $(UBOOT_DEFCONFIG)

tfa:
ifeq ($(COMPILE_ATF),1)
	$(MAKE) -C $(TFA_DIR) BUILD_BASE=$(TFA_BUILD) CROSS_COMPILE=$(CROSS_COMPILE) PLAT=$(TFA_PLAT) $(TFA_TARGET)
endif

sdcard: tfa u-boot
	@echo "Creating SD card image: $(SD_BIN_FILE)"
	dd if=$(UBOOT_BUILD)/$(UBOOT_IMAGE) \
		of=$(BUILD_DIR)/$(BOARD)/$(SD_BIN_FILE) \
		bs=512 \
		seek=64 \
		conv=fsync

rebuild: clean all

clean:
	rm -rf $(BUILD_DIR)/$(BOARD)

distclean:
	rm -rf $(BUILD_DIR)
