CFLAGS = -g -O0

libfoo.so: foo.c
	$(CC) $(CFLAGS) -o $@ -shared $^ '-Wl,--no-as-needed,--enable-new-dtags'

hello_world: hello_world.c
	$(CC) $(CFLAGS) -o $@ $^ -L. -lfoo '-Wl,--no-as-needed,--enable-new-dtags,-rpath,$$ORIGIN'

clean:
	rm -f hello_world libfoo.so