# Examples

This document outlines some of the manual steps you can go through to get this fork working.

The changes in this fork are mainly restricted to [dynlink.c](../ldso/dynlink.c) to support a new relocation format optimized for systems such as Nix & Spack.

## Prerequisites

Compile musl and install it

```console
./configure --prefix=$(realpath build) \
            --exec-prefix=$(realpath build) \
            --syslibdir=$(realpath build/lib/) \
            --host=x86_64-linux-gnu \
            --enable-debug \
            --disable-optimize

make && make install
```
