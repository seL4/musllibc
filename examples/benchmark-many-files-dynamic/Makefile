SRCS := $(wildcard *.c)
OBJS := $(filter-out benchmark.so,$(SRCS:.c=.so))

all: benchmark

benchmark: $(OBJS)
	$(CC) -o $@ benchmark.c $(OBJS)

%.so: %.c
	$(CC) -fPIC -shared -o $@ $<

generate_sources:
	./generate_sources.sh

clean:
	rm -f *.o benchmark *.c *.so