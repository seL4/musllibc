SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=.o)

all: benchmark

benchmark: $(OBJS)
	$(CC) -o $@ $^

%.o: %.c
	@$(CC) -c $< -o $@

generate_sources:
	./generate_sources.sh

clean:
	rm -f *.o benchmark *.c