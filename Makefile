BOARD ?= rpi-2
PLATFORM ?= v1-vga

BUILD_OPTS ?=

HOSTNAME ?= pikvm
LOCALE ?= en_US.UTF-8
TIMEZONE ?= Europe/Moscow

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
	@ cat Makefile


v1-rpi2-vga:
	make _pikvm BOARD=rpi-2 PLATFORM=v1-vga
v1-rpi2-hdmi:
	make _pikvm BOARD=rpi-2 PLATFORM=v1-hdmi
v1-rpi3-vga:
	make _pikvm BOARD=rpi-3 PLATFORM=v1-vga
v1-rpi3-hdmi:
	make _pikvm BOARD=rpi-3 PLATFORM=v1-hdmi


shell:
	cd $(_BUILD_DIR) && make shell


_pikvm: $(_BUILD_DIR)
	rm -rf $(_BUILD_DIR)/stages/pikvm-*
	rm -rf $(_BUILD_DIR)/builder/scripts/pikvm
	cp -a platforms/common-init $(_BUILD_DIR)/stages/pikvm-common-init
	cp -a platforms/common-final $(_BUILD_DIR)/stages/pikvm-common-final
	cp -a platforms/$(PLATFORM) $(_BUILD_DIR)/stages/pikvm-$(PLATFORM)
	cd $(_BUILD_DIR) && make binfmt && make _rpi \
		BUILD_OPTS=" $(BUILD_OPTS) \
			--build-arg USTREAMER_VERSION=$(call fetch_version,ustreamer) \
			--build-arg KVMD_VERSION=$(call fetch_version,kvmd) \
			--build-arg NEW_SSH_KEYGEN=$(shell uuidgen) \
			--build-arg WEBUI_ADMIN_PASSWD='$(WEBUI_ADMIN_PASSWD)' \
			--build-arg NEW_HTTPS_CERT=$(shell uuidgen) \
		" \
		PROJECT=pikvm \
		BOARD=$(BOARD) \
		STAGES="__init__ os watchdog ro pikvm-common-init pikvm-$(PLATFORM) pikvm-common-final rootssh __cleanup__" \
		LOCALE=$(LOCALE) \
		TIMEZONE=$(TIMEZONE)


$(_BUILD_DIR):
	git clone --depth=1 https://github.com/mdevaev/pi-builder $(_BUILD_DIR)


install: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make install HOSTNAME=$(HOSTNAME)


scan: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make scan


clean: $(_BUILD_DIR)
	cd $(_BUILD_DIR) && make clean


clean-all:
	- cd $(_BUILD_DIR) && make clean-all
	rm -rf $(_BUILD_DIR)
