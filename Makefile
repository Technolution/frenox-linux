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

ENVIRONMENTS	:= riscv-tools
TL_ENV			?= true

CACHE_DIR 		:= /var/cache/

LINUX_DISTRO	:= linux-4.6.2.tar.xz
LINUX_FILE		:= $(abspath $(strip $(CACHE_DIR))/$(LINUX_DISTRO))
LINUX_URL		:= https://cdn.kernel.org/pub/linux/kernel/v4.x/$(LINUX_DISTRO)

BR2_DISTRO		:= buildroot-2016.11.tar.bz2
BR2_FILE		:= $(abspath $(strip $(CACHE_DIR))/$(BR2_DISTRO))
BR2_URL			:= https://buildroot.org/downloads/$(BR2_DISTRO)


###############################################################################
## phony rules
###############################################################################
.PHONY: all sub-update init-kernel bbl vmlinux defconfig menuconfig clean spike buildroot

all: bbl

sub-update: build/sub-update
init-kernel: riscv-linux/Makefile
bbl: build/riscv-pk/bbl

vmlinux: riscv-linux/Makefile buildroot
	$(TL_ENV) $(ENVIRONMENTS) && $(MAKE) -C riscv-linux ARCH=riscv vmlinux

defconfig: riscv-linux/Makefile
	$(TL_ENV) $(ENVIRONMENTS) && $(MAKE) -C riscv-linux ARCH=riscv defconfig

menuconfig: riscv-linux/Makefile
	$(TL_ENV) $(ENVIRONMENTS) && $(MAKE) -C riscv-linux ARCH=riscv menuconfig

buildroot: frenox-buildroot/Makefile
	$(TL_ENV) $(ENVIRONMENTS) && $(MAKE) -C frenox-buildroot

spike: build/riscv-pk/bbl
	$(TL_ENV) $(ENVIRONMENTS) && spike $<

clean:
	rm -rf build

###############################################################################
## build rules linux and bbl
###############################################################################
.PRECIOUS: build/sub-update riscv-linux/Makefile build/riscv-pk/Makefile frenox-buildroot/Makefile

build/sub-update: | build/
	git submodule update --init --recursive
	touch $@

build/:
	mkdir $@

riscv-linux/Makefile: build/sub-update
	cd riscv-linux && (cat $(LINUX_FILE) || /usr/bin/curl -L $(LINUX_URL)) | tar -xJ --strip-components=1
	cd riscv-linux && git checkout .
	touch $@

frenox-buildroot/Makefile: build/sub-update
	cd frenox-buildroot && (cat $(BR2_FILE) || /usr/bin/curl -L $(BR2_URL)) | tar -xj --strip-components=1
	cd frenox-buildroot && git checkout .
	touch $@

build/riscv-pk/Makefile: build/sub-update
	mkdir -p $(@D)
	cd $(@D) && $(TL_ENV) $(ENVIRONMENTS) && ../../riscv-pk/configure --prefix=$(PREFIX) --host=riscv32-unknown-elf \
		--enable-32bit --with-payload=../../riscv-linux/vmlinux

build/riscv-pk/bbl: build/riscv-pk/Makefile vmlinux
	$(TL_ENV) $(ENVIRONMENTS) && make -C $(@D) bbl

###############################################################################
## rules used to export repos
###############################################################################
## by calling 
##    make repo-export
## an build/export directory is created containing all git archive used by this
## archive and its submodules. This can be used to 'archive' this repos and
## its dependencies easiely
###############################################################################
REPO_URLS = $(shell git submodule foreach --recursive 'git config --get remote.origin.url' | grep http)
REPO_URLS += $(shell git config --get remote.origin.url)

show-repos: build/sub-update
	@echo $(REPOS)

build/export/: | build/
	mkdir -p $@

define repo_export_template
build/export/$(1).git: build/export/
	cd build/export && git clone --bare $(2)

REPOS += build/export/$(1).git
endef

$(foreach url, $(REPO_URLS), $(eval $(call repo_export_template,$(strip $(basename $(notdir $(url)))), $(url))))

repo-export: $(REPOS) build/sub-update

