#
# Makefile for musl (requires GNU make)
#
# This is how simple every makefile should be...
# No, I take that back - actually most should be less than half this size.
#
# Use config.mak to override any of the following variables.
# Do not make changes here.
#

SOURCE_DIR ?= .

exec_prefix = /usr/local
bindir = $(exec_prefix)/bin

prefix = /usr/local/musl
includedir = $(prefix)/include
libdir = $(prefix)/lib
syslibdir = /lib

SRCS = $(sort $(wildcard ${SOURCE_DIR}/src/*/*.c ${SOURCE_DIR}/arch/$(ARCH)/src/*.c))
OBJS = $(patsubst ${SOURCE_DIR}/%.c,%.o,$(SRCS))
LOBJS = $(OBJS:.o=.lo)
GENH = include/bits/alltypes.h
GENH_INT = src/internal/version.h
IMPH = ${SOURCE_DIR}/src/internal/stdio_impl.h ${SOURCE_DIR}/src/internal/pthread_impl.h ${SOURCE_DIR}/src/internal/libc.h

#LDFLAGS =
LIBCC = -lgcc
#CPPFLAGS =
CFLAGS += -Os -pipe
CFLAGS_C99FSE = -std=c99 -ffreestanding -nostdinc 

CFLAGS_ALL = $(CFLAGS_C99FSE)
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I${SOURCE_DIR}/arch/$(ARCH) -I${SOURCE_DIR}/src/internal -I${SOURCE_DIR}/include -I./include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS)
CFLAGS_ALL_STATIC = $(CFLAGS_ALL)
CFLAGS_ALL_SHARED = $(CFLAGS_ALL) -fPIC -DSHARED

AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib
INSTALL = ./tools/install.sh

ARCH_INCLUDES = $(wildcard ${SOURCE_DIR}/arch/$(ARCH)/bits/*.h)
NON_ARCH_INCLUDES = $(wildcard ${SOURCE_DIR}/include/*.h ${SOURCE_DIR}/include/*/*.h)
ALL_INCLUDES = $(sort $(NON_ARCH_INCLUDES:${SOURCE_DIR}/%=%) $(GENH) $(ARCH_INCLUDES:${SOURCE_DIR}/arch/$(ARCH)/%=include/%))

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=lib/lib%.a)
CRT_LIBS = lib/crt1.o lib/Scrt1.o lib/crti.o lib/crtn.o
STATIC_LIBS = lib/libc.a
SHARED_LIBS = lib/libc.so
TOOL_LIBS = lib/musl-gcc.specs
ALL_LIBS = $(CRT_LIBS) $(STATIC_LIBS) $(SHARED_LIBS) $(EMPTY_LIBS) $(TOOL_LIBS)
ALL_TOOLS = tools/musl-gcc

LDSO_PATHNAME = $(syslibdir)/ld-musl-$(ARCH)$(SUBARCH).so.1

-include ${SOURCE_DIR}/config.mak

all: $(ALL_LIBS) $(ALL_TOOLS)

install: install-libs install-headers install-tools

clean:
	rm -f crt/*.o
	rm -f $(OBJS)
	rm -f $(LOBJS)
	rm -f $(ALL_LIBS) lib/*.[ao] lib/*.so
	rm -f $(ALL_TOOLS)
	rm -f $(GENH) $(GENH_INT)
	rm -f include/bits

distclean: clean
	rm -f config.mak

include/bits:
	@test "$(ARCH)" || { echo "Please set ARCH in config.mak before running make." ; exit 1 ; }
	mkdir -p $(@D)
	ln -s ${SOURCE_DIR}/arch/$(ARCH)/bits $@

include/bits/alltypes.h.in: include/bits

include/bits/alltypes.h: tools/mkalltypes.sed include/bits/alltypes.h.in include/alltypes.h.in
	sed -f $+ > $@

src/internal/version.h: $(wildcard VERSION .git)
	printf '#define VERSION "%s"\n' "$$(sh tools/version.sh)" > $@

src/internal/version.lo: src/internal/version.h

src/ldso/dynlink.lo: arch/$(ARCH)/reloc.h

crt/crt1.o crt/Scrt1.o: $(wildcard ${SOURCE_DIR}/arch/$(ARCH)/crt_arch.h)

crt/Scrt1.o: CFLAGS += -fPIC

OPTIMIZE_SRCS = $(wildcard $(OPTIMIZE_GLOBS:%=src/%))
$(patsubst ${SOURCE_DIR}/%.c,%.o,$(OPTIMIZE_SRCS)) $(patsubst ${SOURCE_DIR}/%.c,%.lo,$(OPTIMIZE_SRCS)): CFLAGS += -O3

MEMOPS_SRCS = src/string/memcpy.c src/string/memmove.c src/string/memcmp.c src/string/memset.c
$(patsubst ${SOURCE_DIR}/%.c,%.o,$(MEMOPS_SRCS)) $(patsubst ${SOURCE_DIR}/%.c,%.lo,$(MEMOPS_SRCS)): CFLAGS += $(CFLAGS_MEMOPS)

# This incantation ensures that changes to any subarch asm files will
# force the corresponding object file to be rebuilt, even if the implicit
# rule below goes indirectly through a .sub file.
define mkasmdep
$(dir $(patsubst ${SOURCE_DIR}/%/,%,$(dir $(1))))$(notdir $(1:.s=.o)): $(1)
endef
$(foreach s,$(wildcard ${SOURCE_DIR}/src/*/$(ARCH)*/*.s),$(eval $(call mkasmdep,$(s))))

%.o: $(ARCH)$(ASMSUBARCH)/%.sub
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $(dir $<)$(shell cat $<)

%.o: $(ARCH)/%.s
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $<

%.o: %.c $(GENH) $(IMPH)
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $<

%.lo: $(ARCH)$(ASMSUBARCH)/%.sub
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $(dir $<)$(shell cat $<)

%.lo: $(ARCH)/%.s
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $<

%.lo: %.c $(GENH) $(IMPH)
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $<

lib/libc.so: $(LOBJS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS_ALL_SHARED) $(LDFLAGS) -nostdlib -shared \
	-Wl,-e,_dlstart -Wl,-Bsymbolic-functions \
	-o $@ $(LOBJS) $(LIBCC)

lib/libc.a: $(OBJS)
	mkdir -p $(@D)
	rm -f $@
	$(AR) rc $@ $(OBJS)
	$(RANLIB) $@

$(EMPTY_LIBS):
	mkdir -p $(@D)
	rm -f $@
	$(AR) rc $@

lib/%.o: crt/%.o
	mkdir -p $(@D)
	cp $< $@

lib/musl-gcc.specs: tools/musl-gcc.specs.sh config.mak
	sh $< "$(includedir)" "$(libdir)" "$(LDSO_PATHNAME)" > $@

tools/musl-gcc: config.mak
	mkdir -p $(@D)
	printf '#!/bin/sh\nexec "$${REALGCC:-gcc}" "$$@" -specs "%s/musl-gcc.specs"\n' "$(libdir)" > $@
	chmod +x $@

$(DESTDIR)$(bindir)/%: tools/%
	$(INSTALL) -D $< $@

$(DESTDIR)$(libdir)/%.so: lib/%.so
	$(INSTALL) -D -m 755 $< $@

$(DESTDIR)$(libdir)/%: lib/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: arch/$(ARCH)/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/%: include/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(LDSO_PATHNAME): $(DESTDIR)$(libdir)/libc.so
	$(INSTALL) -D -l $(libdir)/libc.so $@ || true

install-libs: $(ALL_LIBS:lib/%=$(DESTDIR)$(libdir)/%) $(if $(SHARED_LIBS),$(DESTDIR)$(LDSO_PATHNAME),)

install-headers: $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%)

install-tools: $(ALL_TOOLS:tools/%=$(DESTDIR)$(bindir)/%)

musl-git-%.tar.gz: .git
	 git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ $(patsubst musl-git-%.tar.gz,%,$@)

musl-%.tar.gz: .git
	 git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ v$(patsubst musl-%.tar.gz,%,$@)

.PRECIOUS: $(CRT_LIBS:lib/%=crt/%)

.PHONY: all clean install install-libs install-headers install-tools
