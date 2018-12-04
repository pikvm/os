-include config.mk

CARD ?= /dev/mmcblk0
CARD_BOOT ?= $(CARD)p1
CARD_ROOT ?= $(CARD)p2

BOARD ?= rpi2
PLATFORM ?= v1-vga
STAGES ?= __init__ os watchdog ro pikvm-common-init pikvm-$(PLATFORM) pikvm-common-final sshkeygen __cleanup__

BUILD_OPTS ?=

HOSTNAME ?= pikvm
LOCALE ?= en_US
TIMEZONE ?= Europe/Moscow
REPO_URL ?= http://mirror.yandex.ru/archlinux-arm

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin


# =====
_BUILD_DIR = ./.build

define fetch_version
$(shell curl --silent "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$(1)" \
	| grep "^pkgver=" \
	| grep -Po "\d+\.\d+[^\"']*")
endef


# =====
all:
	@ echo "Available commands:"
	@ echo "    make                # Print this help"
	@ echo "    make v1-vga-rpi2    # Build v1-vga-rpi2"
	@ echo "    make v1-hdmi-rpi2   # Build v1-hdmi-rpi2"
	@ echo "    make v1-vga-rpi3    # v1-vga-rpi3"
	@ echo "    make v1-hdmi-rpi3   # v1-hdmi-rpi3"
	@ echo "    make shell          # Run Arch-ARM shell"
	@ echo "    make install        # Install rootfs to partitions on $(CARD)"
	@ echo "    make scan           # Find all RPi devices in the local network"
	@ echo "    make clean          # Remove the generated rootfs"
	@ echo "    make clean-all      # Remove the generated rootfs and pi-builder toolchain"

v1-vga-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v1-vga
v1-hdmi-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v1-hdmi
v1-vga-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v1-vga
v1-hdmi-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v1-hdmi


shell:
	cd $(_BUILD_DIR) && make shell


_pikvm: $(_BUILD_DIR)
	rm -rf $(_BUILD_DIR)/stages/pikvm-*
	rm -rf $(_BUILD_DIR)/builder/scripts/pikvm
	cp -a platforms/common-init $(_BUILD_DIR)/stages/pikvm-common-init
	cp -a platforms/common-final $(_BUILD_DIR)/stages/pikvm-common-final
	cp -a platforms/$(PLATFORM) $(_BUILD_DIR)/stages/pikvm-$(PLATFORM)
	cd $(_BUILD_DIR) && make binfmt os \
		BUILD_OPTS=" $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PLATFORM) \
			--build-arg USTREAMER_VERSION=$(call fetch_version,ustreamer) \
			--build-arg KVMD_VERSION=$(call fetch_version,kvmd) \
			--build-arg KVMD_WEBTERM_VERSION=$(call fetch_version,kvmd-webterm) \
			--build-arg NEW_SSH_KEYGEN=$(shell uuidgen) \
			--build-arg ROOT_PASSWD='$(ROOT_PASSWD)' \
			--build-arg WEBUI_ADMIN_PASSWD='$(WEBUI_ADMIN_PASSWD)' \
			--build-arg NEW_HTTPS_CERT=$(shell uuidgen) \
		" \
		PROJECT=pikvm \
		BOARD=$(BOARD) \
		STAGES='$(STAGES)' \
		LOCALE=$(LOCALE) \
		TIMEZONE=$(TIMEZONE) \
		REPO_URL=$(REPO_URL)


$(_BUILD_DIR):
	git clone --depth=1 https://github.com/mdevaev/pi-builder $(_BUILD_DIR)


install: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make install \
		CARD=$(CARD) \
		CARD_BOOT=$(CARD_BOOT) \
		CARD_ROOT=$(CARD_ROOT) \
		HOSTNAME=$(HOSTNAME)


scan: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make scan


clean: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make clean


clean-all:
	- cd $(_BUILD_DIR) && make clean-all
	rm -rf $(_BUILD_DIR)
