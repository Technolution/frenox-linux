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
## This is a meta makefile to initialize the build environment for linux.
###############################################################################

ENVIRONMENTS	:= risc-v
TL_ENV			?= true

LINUX_DISTRO	:= linux-4.6.2.tar.xz
CACHE_DIR 		:= /var/cache/
LINUX_FILE		:= $(abspath $(strip $(CACHE_DIR))/$(LINUX_DISTRO))
LINUX_URL		:= https://cdn.kernel.org/pub/linux/kernel/v4.x/$(LINUX_DISTRO)



###############################################################################
## phony rules
###############################################################################
.PHONY: all sub-update init-kernel bbl vmlinux defconfig menuconfig clean

all: bbl

sub-update: build/sub-update
init-kernel: riscv-linux/Makefile
bbl: build/riscv-pk/bbl

vmlinux: riscv-linux/Makefile
	$(TL_ENV) {$(ENVIRONMENTS)} && $(MAKE) -C riscv-linux ARCH=riscv vmlinux

defconfig: riscv-linux/Makefile
	$(TL_ENV) {$(ENVIRONMENTS)} && $(MAKE) -C riscv-linux ARCH=riscv defconfig

menuconfig: riscv-linux/Makefile
	$(TL_ENV) {$(ENVIRONMENTS)} && $(MAKE) -C riscv-linux ARCH=riscv menuconfig

clean:
	rm -rf build

###############################################################################
## build rules
###############################################################################
build/sub-update: build/
	git submodule update --init --recursive
	touch $@

build/:
	mkdir $@

riscv-linux/Makefile: build/sub-update
	cd riscv-linux && (cat $(LINUX_FILE) || /usr/bin/curl -L $(LINUX_URL)) | tar -xJ --strip-components=1
	cd riscv-linux && git checkout .
	touch $@

build/riscv-pk/Makefile: build/sub-update
	mkdir -p $(@D)
	cd $(@D) && $(TL_ENV) {$(ENVIRONMENTS)} && ../../riscv-pk/configure --prefix=$(PREFIX) --host=riscv32-unknown-elf \
		--enable-32bit --with-payload=../../riscv-linux/vmlinux

build/riscv-pk/bbl: build/riscv-pk/Makefile vmlinux
	make -C $(@D) bbl
	

