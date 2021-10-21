-include config.mk

BOARD ?= rpi4
PLATFORM ?= v2-hdmi
STAGES ?= __init__ os pikvm-repo watchdog ro no-audit pikvm __cleanup__

HOSTNAME ?= pikvm
LOCALE ?= en_US
TIMEZONE ?= Europe/Moscow
#REPO_URL ?= http://mirror.yandex.ru/archlinux-arm
REPO_URL ?= http://de3.mirror.archlinuxarm.org
BUILD_OPTS ?=

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin
IPMI_ADMIN_PASSWD ?= admin

CARD ?= /dev/mmcblk0

DEPLOY_USER ?= root


# =====
SHELL = /usr/bin/env bash
_BUILDER_DIR = ./.pi-builder

define fetch_version
$(shell curl --silent "https://files.pikvm.org/repos/arch/$(BOARD)/latest/$(1)")
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
	$(MAKE) -C $(_BUILDER_DIR) shell


os: $(_BUILDER_DIR)
	rm -rf $(_BUILDER_DIR)/stages/{pikvm,pikvm-otg-console}
	cp -a pikvm pikvm-otg-console $(_BUILDER_DIR)/stages
	$(MAKE) -C $(_BUILDER_DIR) os \
		NC=$(NC) \
		BUILD_OPTS=' $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PLATFORM) \
			--build-arg USTREAMER_VERSION=$(call fetch_version,ustreamer) \
			--build-arg KVMD_VERSION=$(call fetch_version,kvmd) \
			--build-arg KVMD_WEBTERM_VERSION=$(call fetch_version,kvmd-webterm) \
			--build-arg ROOT_PASSWD=$(ROOT_PASSWD) \
			--build-arg WEBUI_ADMIN_PASSWD=$(WEBUI_ADMIN_PASSWD) \
			--build-arg IPMI_ADMIN_PASSWD=$(IPMI_ADMIN_PASSWD) \
		' \
		PROJECT=pikvm-os-$(PLATFORM) \
		BOARD=$(BOARD) \
		STAGES='$(STAGES)' \
		HOSTNAME=$(HOSTNAME) \
		LOCALE=$(LOCALE) \
		TIMEZONE=$(TIMEZONE) \
		REPO_URL=$(REPO_URL)


$(_BUILDER_DIR):
	git clone --depth=1 https://github.com/mdevaev/pi-builder $(_BUILDER_DIR)


update: $(_BUILDER_DIR)
	cd $(_BUILDER_DIR) && git pull --rebase
	git pull --rebase


install: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) install \
		CARD=$(CARD) \
		CARD_DATA_FS_TYPE=$(if $(findstring v2,$(PLATFORM))$(findstring v3,$(PLATFORM)),ext4,) \
		CARD_DATA_FS_FLAGS=-m0 \
		CARD_DATA_BEGIN_AT=6400


scan: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) scan


clean: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) clean


clean-all:
	- $(MAKE) -C $(_BUILDER_DIR) clean-all
	rm -rf $(_BUILDER_DIR)


_IMAGE_DATED := $(PLATFORM)-$(BOARD)-$(shell date +%Y%m%d).img
_IMAGE_LATEST := $(PLATFORM)-$(BOARD)-latest.img
image:
	mkdir -p images
	sudo bash -x -c ' \
		truncate images/$(_IMAGE_DATED) -s 6G \
		&& device=`losetup --find --show images/$(_IMAGE_DATED)` \
		&& $(MAKE) install CARD=$$device \
		&& losetup -d $$device \
	'
	bzip2 -f images/$(_IMAGE_DATED)
	sha1sum images/$(_IMAGE_DATED).bz2 | awk '{print $$1}' > images/$(_IMAGE_DATED).bz2.sha1
	cd images && ln -sf $(_IMAGE_DATED).bz2 $(_IMAGE_LATEST).bz2
	cd images && ln -sf $(_IMAGE_DATED).bz2.sha1 $(_IMAGE_LATEST).bz2.sha1


upload:
	rsync -rl --progress images/ $(DEPLOY_USER)@files.pikvm.org:/var/www/files.pikvm.org/images
