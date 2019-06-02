-include config.mk

BOARD ?= rpi2
PLATFORM ?= v1-vga
STAGES ?= __init__ os watchdog ro pikvm-common-init pikvm-$(PLATFORM) pikvm-common-final sshkeygen __cleanup__

HOSTNAME ?= pikvm
LOCALE ?= en_US
TIMEZONE ?= Europe/Moscow
REPO_URL ?= http://mirror.yandex.ru/archlinux-arm
BUILD_OPTS ?=

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin

CARD ?= /dev/mmcblk0


# =====
_BUILDER_DIR = ./.pi-builder

define fetch_version
$(shell curl --silent "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$(1)" \
	| grep "^pkgver=" \
	| grep -Po "\d+\.\d+[^\"']*")
endef


# =====
all:
	@ echo "Available commands:"
	@ echo "    make                # Print this help"
	@ echo
	@ echo "    make v0-vga-rpi2    # Build v0-vga-rpi2"
	@ echo "    make v0-hdmi-rpi2   # Build v0-hdmi-rpi2"
	@ echo "    make v0-vga-rpi3    # Build v0-vga-rpi3"
	@ echo "    make v0-hdmi-rpi3   # Build v0-hdmi-rpi3"
	@ echo
	@ echo "    make v1-vga-rpi2    # Build v1-vga-rpi2"
	@ echo "    make v1-hdmi-rpi2   # Build v1-hdmi-rpi2"
	@ echo "    make v1-vga-rpi3    # Build v1-vga-rpi3"
	@ echo "    make v1-hdmi-rpi3   # Build v1-hdmi-rpi3"
	@ echo
	@ echo "    make shell          # Run Arch-ARM shell"
	@ echo "    make install        # Install rootfs to partitions on $(CARD)"
	@ echo "    make scan           # Find all RPi devices in the local network"
	@ echo "    make clean          # Remove the generated rootfs"
	@ echo "    make clean-all      # Remove the generated rootfs and pi-builder toolchain"

v0-vga-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v0-vga
v0-hdmi-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v0-hdmi
v0-vga-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v0-vga
v0-hdmi-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v0-hdmi

v1-vga-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v1-vga
v1-hdmi-rpi2:
	make _pikvm BOARD=rpi2 PLATFORM=v1-hdmi
v1-vga-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v1-vga
v1-hdmi-rpi3:
	make _pikvm BOARD=rpi3 PLATFORM=v1-hdmi


shell: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) shell


_pikvm: $(_BUILDER_DIR)
	rm -rf $(_BUILDER_DIR)/stages/pikvm-*
	rm -rf $(_BUILDER_DIR)/builder/scripts/pikvm
	cp -a platforms/common-init $(_BUILDER_DIR)/stages/pikvm-common-init
	cp -a platforms/common-final $(_BUILDER_DIR)/stages/pikvm-common-final
	cp -a platforms/$(PLATFORM) $(_BUILDER_DIR)/stages/pikvm-$(PLATFORM)
	make -C $(_BUILDER_DIR) os \
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
	make -C $(_BUILDER_DIR) install CARD=$(CARD)


scan: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) scan


clean: $(_BUILDER_DIR)
	make -C $(_BUILDER_DIR) clean


clean-all:
	- make -C $(_BUILDER_DIR) clean-all
	rm -rf $(_BUILDER_DIR)
