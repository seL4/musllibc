#
# Copyright 2014, NICTA
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(NICTA_BSD)
#

prefix = ${STAGE_DIR}
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
includedir = $(prefix)/include
syslibdir = /lib
CC = ${TOOLPREFIX}gcc${TOOLSUFFIX}
CFLAGS += ${NK_CFLAGS} -Os -pipe -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables -Wa,--noexecstack -Werror=implicit-function-declaration -Werror=implicit-int -Werror=pointer-sign -Werror=pointer-arith -fno-stack-protector
CFLAGS_C99FSE = -std=c99 -nostdinc -ffreestanding -fexcess-precision=standard -frounding-math
CFLAGS_MEMOPS = -fno-tree-loop-distribute-patterns
CPPFLAGS +=
LDFLAGS += ${NK_LDFLAGS} -Wl,--hash-style=both 
CROSS_COMPILE = ${TOOLPREFIX}
LIBCC = -lgcc -lgcc_eh
OPTIMIZE_GLOBS = internal/*.c malloc/*.c string/*.c
SHARED_LIBS =
VPATH = ${SOURCE_DIR}
INSTALL = ${SOURCE_DIR}/tools/install.sh

ifeq (${CONFIG_ARCH_IA32},y)
	ARCH = i386_sel4
	SUBARCH =
	ASMSUBARCH =
endif

ifeq (${CONFIG_ARCH_ARM},y)
	ARCH = arm_sel4
	SUBARCH =
	ASMSUBARCH =
endif

ifeq (${CONFIG_ARCH_X86_64},y)
    ARCH = x86_64_sel4
    SUBARCH =
    ASMSUBARCH =
endif

ifeq (${CONFIG_LINK_TIME_OPTIMISATIONS},y)
	CFLAGS += -flto
endif

default: install-libs install-headers
