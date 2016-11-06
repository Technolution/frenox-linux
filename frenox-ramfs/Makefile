###############################################################################
##
## (C) COPYRIGHT 2006-2016 TECHNOLUTION BV, GOUDA NL
## | =======          I                   ==          I    =
## |    I             I                    I          I
## |    I   ===   === I ===  I ===   ===   I  I    I ====  I   ===  I ===
## |    I  /   \ I    I/   I I/   I I   I  I  I    I  I    I  I   I I/   I
## |    I  ===== I    I    I I    I I   I  I  I    I  I    I  I   I I    I
## |    I  \     I    I    I I    I I   I  I  I   /I  \    I  I   I I    I
## |    I   ===   === I    I I    I  ===  ===  === I   ==  I   ===  I    I
## |                 +---------------------------------------------------+
## +----+            |  +++++++++++++++++++++++++++++++++++++++++++++++++|
##      |            |             ++++++++++++++++++++++++++++++++++++++|
##      +------------+                          +++++++++++++++++++++++++|
##                                                         ++++++++++++++|
##              A U T O M A T I O N     T E C H N O L O G Y         +++++|
##
###############################################################################
## make file to build basic root image
###############################################################################

ENVIRONMENTS	:= riscv-tools
TL_ENV			?= true

BUSYBOX_DISTRO	:= busybox-1.21.1.tar.bz2
CACHE_DIR 		:= /var/cache/
BUSYBOX_FILE	:= $(abspath $(strip $(CACHE_DIR))/$(BUSYBOX_DISTRO))
BUSYBOX_URL		:= http://busybox.net/downloads/$(BUSYBOX_DISTRO)

ROOT_IMG		:= frenox-initramfs.cpio

###############################################################################
## phony rules
###############################################################################
.PHONY: all clean 

all: ramfs

clean:
	rm -rf build/

###############################################################################
## rules to build initramfs
###############################################################################
## by calling
##    make ramfs
## the initramfs is build or updated
###############################################################################
DEFAULT_DIRS = bin dev etc lib mnt proc root sbin sys tmp usr
DEFAULT_DEVS = dev/console
RAMFS_ITEMS = $(shell find initramfs/ ! -type l)

RAMFS_DIRS = $(DEFAULT_DIRS:%=initramfs/%)
RAMFS_DEVS = $(DEFAULT_DEVS:%=initramfs/%)

build/:
	mkdir -p $@

ramfs: build/$(ROOT_IMG)
itest::
	@echo $(RAMFS_ITEMS)


build/$(ROOT_IMG):  $(RAMFS_ITEMS) $(RAMFS_DIRS) $(RAMFS_DEVS) busybox | build/
	cd initramfs && fakeroot sh -c 'find . -print0 | cpio --null -ov --format=newc' > ../$@

$(RAMFS_DIRS):
	mkdir -p $@

initramfs/dev/console:
	mknod $@ c 5 1

	
###############################################################################
## busybox
###############################################################################
## by calling
##    make busybox
## the busybox is build or updated
###############################################################################
busybox: initramfs/bin/busybox

initramfs/bin/busybox: busybox/busybox
	cp $< $@

busybox/busybox: busybox/Makefile
	$(TL_ENV) $(ENVIRONMENTS) && $(MAKE) -C busybox

busybox/Makefile: 
	cd busybox && (cat $(BUSYBOX_FILE) || /usr/bin/curl -L $(BUSYBOX_URL)) | tar -xj --strip-components=1
	mv busybox/.gitignore busybox/.gitignore-old
	touch $@

	