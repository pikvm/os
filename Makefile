-include config.mk

PLATFORM ?= v2-hdmi
SUFFIX ?=
export BOARD ?= rpi4
export ARCH ?= arm
export PROJECT ?= pikvm-os.$(PLATFORM)$(SUFFIX)
export STAGES ?= __init__ os pikvm-repo pistat watchdog rootdelay ro pikvm restore-mirrorlist __cleanup__
export NC ?=

export HOSTNAME ?= pikvm
export LOCALE ?= en_US
export TIMEZONE ?= UTC
export ARCH_DIST_REPO_URL ?= http://de3.mirror.archlinuxarm.org
BUILD_OPTS ?=

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin
IPMI_ADMIN_PASSWD ?= admin

export DISK ?= $(shell pwd)/disk/$(word 1,$(subst -, ,$(PLATFORM))).conf
export CARD ?= /dev/null
export IMAGE_XZ ?=

UPLOAD_USER ?= root
UPLOAD_TARGET ?= files.pikvm.org:/var/www/files.pikvm.org/images

BUILD_DIR ?= ./.pi-builder


# =====
SHELL := bash
.SHELLFLAGS := -Eeuo pipefail -c

define optbool
$(filter $(shell echo $(1) | tr A-Z a-z),yes on 1)
endef

define fv
$(shell curl --silent "https://files.pikvm.org/repos/arch/$(BOARD)-$(ARCH)/latest/$(1)")
endef


# =====
all:
	@ echo "Available commands:"
	@ echo "    make                # Print this help"
	@ echo "    make os             # Build OS with your default config"
	@ echo "    make shell          # Run Arch-ARM shell"
	@ echo "    make install        # Install rootfs to partitions on $(CARD)"
	@ echo "    make image          # Create a binary image for burning outside of make install"
	@ echo "    make scan           # Find all RPi devices in the local network"
	@ echo "    make clean          # Remove the generated rootfs"
	@ echo "    make clean-all      # Remove the generated rootfs and pi-builder toolchain"


shell: $(BUILD_DIR)
	$(MAKE) -C $(BUILD_DIR) shell


os: $(BUILD_DIR)
	rm -rf $(BUILD_DIR)/stages/arch/{pikvm,pikvm-otg-console}
	cp -a stages/arch/{pikvm,pikvm-otg-console} $(BUILD_DIR)/stages/arch
	$(MAKE) -C $(BUILD_DIR) os \
		BUILD_OPTS=' $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PLATFORM) \
			--build-arg OLED=$(call optbool,$(OLED)) \
			--build-arg VERSIONS=$(call fv,ustreamer)/$(call fv,kvmd)/$(call fv,kvmd-webterm)/$(call fv,kvmd-fan) \
			--build-arg FAN=$(call optbool,$(FAN)) \
			--build-arg ROOT_PASSWD=$(ROOT_PASSWD) \
			--build-arg WEBUI_ADMIN_PASSWD=$(WEBUI_ADMIN_PASSWD) \
			--build-arg IPMI_ADMIN_PASSWD=$(IPMI_ADMIN_PASSWD) \
		'


$(BUILD_DIR):
	mkdir -p `dirname $(BUILD_DIR)`
	git clone --depth=1 https://github.com/mdevaev/pi-builder $(BUILD_DIR)


image: $(BUILD_DIR)
	$(eval _dir := images/$(PLATFORM)-$(BOARD)/$(ARCH))
	$(eval _dated := $(PLATFORM)-$(BOARD)-$(ARCH)$(SUFFIX)-$(shell date +%Y%m%d).img)
	$(eval _latest := $(PLATFORM)-$(BOARD)-$(ARCH)$(SUFFIX)-latest.img)
	$(eval _suffix = $(if $(call optbool,$(IMAGE_XZ)),.xz,))
	mkdir -p $(_dir)
	$(MAKE) -C $(BUILD_DIR) image IMAGE=$(shell pwd)/$(_dir)/$(_dated)
	cd $(_dir) && ln -sf $(_dated)$(_suffix) $(_latest)$(_suffix)
	cd $(_dir) && ln -sf $(_dated)$(_suffix).sha1 $(_latest)$(_suffix).sha1


upload:
	rsync -rl --progress images/ $(UPLOAD_USER)@$(UPLOAD_TARGET)
