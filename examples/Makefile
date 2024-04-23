CC = ../build/bin/musl-gcc
CFLAGS = -g

libfoo.so: foo.c
	$(CC) $(CFLAGS) -o $@ -shared $^

hello_world: hello_world.c libfoo.so
	$(CC) $(CFLAGS) -o $@ $^ -L. -lfoo '-Wl,--no-as-needed,--enable-new-dtags,-rpath,$$ORIGIN'

clean:
	rm -f hello_world libfoo.so