-include config.mk

BOARD ?= rpi4
ARCH ?= arm
PLATFORM ?= v2-hdmi
UBOOT ?=
STAGES ?= __init__ os pikvm-repo watchdog ro no-audit pikvm pikvm-image __cleanup__

HOSTNAME ?= pikvm
LOCALE ?= en_US
TIMEZONE ?= Europe/Moscow
#REPO_URL ?= http://mirror.yandex.ru/archlinux-arm
REPO_URL ?= http://de3.mirror.archlinuxarm.org
BUILD_OPTS ?=
BUILDER_URL ?= https://github.com/mdevaev/pi-builder
PIKVM_REPO_URL ?= https://pikvm.org/repos
PIKVM_REPO_KEY ?= 912C773ABBD1B584

WIFI_ESSID ?=
WIFI_PASSWD ?=
WIFI_IFACE ?= wlan0

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin
IPMI_ADMIN_PASSWD ?= admin

CARD ?= /dev/mmcblk0
IMAGE_FILE ?= images/$(PLATFORM)-$(BOARD)-$(ARCH)$(if $(UBOOT),-$(UBOOT),).img


# =====
SHELL = /usr/bin/env bash
_BUILDER_DIR = ./.pi-builder

define fetch_version
$(shell curl --silent "$(PIKVM_REPO_URL)/$(BOARD)-$(ARCH)/latest/$(1)")
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


shell: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) shell


os: $(_BUILDER_DIR)
	rm -rf $(_BUILDER_DIR)/stages/{pikvm,pikvm-image,pikvm-otg-console}
	cp -a pikvm pikvm-image pikvm-otg-console $(_BUILDER_DIR)/stages
	make -C $(_BUILDER_DIR) os \
		NC=$(NC) \
		BUILD_OPTS=" $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PLATFORM) \
			--build-arg USTREAMER_VERSION=$(call fetch_version,ustreamer) \
			--build-arg KVMD_VERSION=$(call fetch_version,kvmd) \
			--build-arg KVMD_WEBTERM_VERSION=$(call fetch_version,kvmd-webterm) \
			--build-arg WIFI_ESSID='$(WIFI_ESSID)' \
			--build-arg WIFI_PASSWD='$(WIFI_PASSWD)' \
			--build-arg WIFI_IFACE='$(WIFI_IFACE)' \
			--build-arg ROOT_PASSWD='$(ROOT_PASSWD)' \
			--build-arg WEBUI_ADMIN_PASSWD='$(WEBUI_ADMIN_PASSWD)' \
			--build-arg IPMI_ADMIN_PASSWD='$(IPMI_ADMIN_PASSWD)' \
			--build-arg NEW_HTTPS_CERT=$(shell uuidgen) \
		" \
		PROJECT=pikvm-os-$(PLATFORM) \
		BOARD=$(BOARD) \
		ARCH=$(ARCH) \
		UBOOT=$(UBOOT) \
		STAGES='$(STAGES)' \
		HOSTNAME=$(HOSTNAME) \
		LOCALE=$(LOCALE) \
		TIMEZONE=$(TIMEZONE) \
		REPO_URL=$(REPO_URL) \
		PIKVM_REPO_URL=$(PIKVM_REPO_URL) \
		PIKVM_REPO_KEY=$(PIKVM_REPO_KEY)


$(_BUILDER_DIR):
	git clone --depth=1 $(BUILDER_URL) $(_BUILDER_DIR)


update: $(_BUILDER_DIR)
	cd $(_BUILDER_DIR) && git pull --rebase
	git pull --rebase


install: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) install \
		CARD=$(CARD) \
		BOARD=$(BOARD) \
		ARCH=$(ARCH) \
		UBOOT=$(UBOOT) \
		CARD_DATA_FS_TYPE=$(if $(findstring v2-hdmi,$(PLATFORM)),ext4,) \
		CARD_DATA_FS_FLAGS=-m0


scan: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) scan


clean: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) clean


clean-all:
	- make -C $(_BUILDER_DIR) clean-all
	rm -rf $(_BUILDER_DIR)


image:
	mkdir -p images
	sudo bash -x -c ' \
		dd if=/dev/zero of=$(IMAGE_FILE) bs=512 count=12582912 \
		&& device=`losetup --find --show $(IMAGE_FILE)` \
		&& make install CARD=$$device BOARD=$(BOARD) ARCH=$(ARCH) UBOOT=$(UBOOT)\
		&& losetup -d $$device \
	'
	bzip2 -f $(IMAGE_FILE)
	sha1sum $(IMAGE_FILE).bz2 | awk '{print $$1}' > $(IMAGE_FILE).bz2.sha1


upload:
	rsync -rl --progress --delete images root@pikvm.org:/var/www/images2
	ssh root@pikvm.org "bash -c 'mv /var/www/images2/* /var/www/images/; rmdir /var/www/images2'"
