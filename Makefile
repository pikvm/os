-include config.mk

BOARD ?= rpi4
PLATFORM ?= v2-hdmi
STAGES ?= __init__ os pikvm-repo watchdog ro no-audit pikvm ssh-keygen __cleanup__

HOSTNAME ?= pikvm
LOCALE ?= en_US
TIMEZONE ?= Europe/Moscow
REPO_URL ?= http://mirror.yandex.ru/archlinux-arm
BUILD_OPTS ?=

WIFI_ESSID ?=
WIFI_PASSWD ?=
WIFI_IFACE ?= wlan0

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin
IPMI_ADMIN_PASSWD ?= admin

CARD ?= /dev/mmcblk0


# =====
SHELL = /bin/bash
_BUILDER_DIR = ./.pi-builder

define fetch_version
$(shell curl --silent "https://pikvm.org/repos/$(BOARD)/latest/$(1)")
endef


# =====
all:
	@ echo "Available commands:"
	@ echo "    make                # Print this help"
	@ echo "    make os             # Build OS with your default config"
	@ echo "    make shell          # Run Arch-ARM shell"
	@ echo "    make install        # Install rootfs to partitions on $(CARD)"
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
	make -C $(_BUILDER_DIR) install \
		CARD=$(CARD) \
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
	sudo bash -x -c ' \
		dd if=/dev/zero of=$(PLATFORM)-$(BOARD).img bs=512 count=12582912 \
		&& device=`losetup --find --show $(PLATFORM)-$(BOARD).img` \
		&& make install CARD=$$device \
		&& losetup -d $$device \
	'
	#bzip2 $(PLATFORM)-$(BOARD).img
	#sha1sum $(PLATFORM)-$(BOARD).img.bz2
