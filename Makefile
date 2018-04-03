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

ifeq (${CONFIG_ARCH_RISCV},y)
    TARGET = riscv
endif

ifeq (${CONFIG_LINK_TIME_OPTIMISATIONS},y)
    CFLAGS += -flto
endif


CC = ${TOOLPREFIX}gcc${TOOLSUFFIX}
CROSS_COMPILE = ${TOOLPREFIX}
CFLAGS += ${NK_CFLAGS}

export CC CROSS_COMPILE CFLAGS

configure_line := --srcdir=${SOURCE_DIR} --prefix=${STAGE_DIR} ${ENABLE_DEBUG} \
        --target=${TARGET} --enable-warnings --disable-shared --enable-static

build_muslc:
    # If the configure line changed and we've done a build (i.e. we have a makefile) then we should
    # do a clean as muslc does not rebuild in the same directory correctly if you change the target
    # or other major things
	[ "`cat configure_line 2>&1`" != "${configure_line}" ] && [ -e Makefile.muslc ] && \
		$(MAKE) CFLAGS="${CFLAGS}" CC="${CC}" CROSS_COMPILE="${CROSS_COMPILE}" -f Makefile.muslc clean || true

	# If the configure line did change (or we don't have one yet) then we also need to (re)run configure
	# Send everything to /dev/null though as configure is quite noisy
	# Also need to update the ARCH in the config.mak file configure generates
	[ "`cat configure_line 2>&1`" != "${configure_line}" ] && \
		${SOURCE_DIR}/configure ${configure_line} && sed -i 's/^ARCH = \(.*\)/ARCH = \1_sel4/' config.mak || true
	# Store the current configuration
	echo "${configure_line}" > configure_line
	# Symlink in the correct Makefile as the configure script doesn't know that we renamed the muslc one
	[ -e Makefile.muslc ] || ln -s ${SOURCE_DIR}/Makefile.muslc Makefile.muslc
	$(MAKE) CFLAGS="${CFLAGS}" CC="${CC}" CROSS_COMPILE="${CROSS_COMILE}" -f Makefile.muslc
	$(MAKE) CFLAGS="${CFLAGS}" CC="${CC}" CROSS_COMPILE="${CROSS_COMILE}" -f Makefile.muslc install-libs install-headers
