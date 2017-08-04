#
# Copyright 2017, Data61
# Commonwealth Scientific and Industrial Research Organisation (CSIRO)
# ABN 41 687 119 230.
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(DATA61_BSD)
#

# This is a bit of a hacky wrapper around the original muslc Makefile, which has
# been renamed Makefile.muslc. This wrapper allows for bashing muslc into the
# greater seL4 build system, but still preserving the original Makefile (albeit renamed)
# to allow for ease of merging changes

all: build_muslc

ifeq (${CONFIG_USER_DEBUG_BUILD},y)
    ENABLE_DEBUG = --enable-debug
else
	ENABLE_DEBUG =
endif

ifeq (${CONFIG_ARCH_IA32},y)
    TARGET = i386
endif

ifeq (${CONFIG_ARCH_AARCH32},y)
    TARGET = arm
endif

ifeq (${CONFIG_ARCH_X86_64},y)
    TARGET = x86_64
endif

ifeq (${CONFIG_ARCH_AARCH64},y)
    TARGET = aarch64
endif

ifeq (${CONFIG_LINK_TIME_OPTIMISATIONS},y)
    CFLAGS += -flto
endif


CC = ${TOOLPREFIX}gcc${TOOLSUFFIX}
CROSS_COMPILE = ${TOOLPREFIX}
CFLAGS += ${NK_CFLAGS}

export CC CROSS_COMPILE CFLAGS

build_muslc:
	# muslc does not support out of tree builds, so step 1 is to copy the source
	# into the build directory
	cp -a $(SOURCE_DIR)/* .
	# Configure muslc, using the non _sel4 arch. Send everything to /dev/null as it's a bit noisy
	./configure --prefix=${STAGE_DIR} ${ENABLE_DEBUG} \
    	--target=${TARGET} --enable-warnings --disable-shared --enable-static > /dev/null
	# Now that configuration is done and flags have been set change the ARCH to the _sel4 one
	sed -i 's/^ARCH = \(.*\)/ARCH = \1_sel4/' config.mak
	$(MAKE) CFLAGS="${CFLAGS}" CC="${CC}" CROSS_COMPILE="${CROSS_COMILE}" -f Makefile.muslc
	$(MAKE) CFLAGS="${CFLAGS}" CC="${CC}" CROSS_COMPILE="${CROSS_COMILE}" -f Makefile.muslc install-libs install-headers
