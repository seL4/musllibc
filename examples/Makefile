CC = ../build/bin/musl-gcc
CFLAGS = -g -O0

libfoo.so: foo.c
	$(CC) $(CFLAGS) -o $@ -shared $^ '-Wl,--no-as-needed,--enable-new-dtags'

hello_world: hello_world.c libfoo.so
	$(CC) $(CFLAGS) -o $@ $^ -L. -lfoo '-Wl,--no-as-needed,--enable-new-dtags,-rpath,$$ORIGIN'

read_relo_cache: read_relo_cache.cpp
	clang++ -std=c++17 $^ -o $@

clean:
	rm -f hello_world libfoo.so read_relo_cache