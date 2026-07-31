#!/usr/bin/make -f

-include config.mk


# =====
all:

.all_targets.mk: print_targets.py build_all.mk
	./print_targets.py > .all_targets.mk.tmp
	mv .all_targets.mk.tmp .all_targets.mk

include .all_targets.mk

all: $(ALL_TARGETS)
.NOTPARALLEL: all $(ALL_TARGETS)

.SECONDEXPANSION:
$(ALL_TARGETS):
	@ tput -Txterm bold
	@ tput -Txterm setab 5
	@ tput -Txterm setaf 15
	@ echo -n "========== `dirname $@` =========="
	@ tput -Txterm sgr0
	@ echo
	$(MAKE) os BUILD_DIR=`dirname $@`
	$(MAKE) image IMAGE_XZ=1 BUILD_DIR=`dirname $@`
	touch $@
