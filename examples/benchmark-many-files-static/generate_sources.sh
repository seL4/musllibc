#!/bin/bash

for i in {1..10000}; do
    echo "int func_$i() { return $i; }" > "func_$i.c"
done

# Generate benchmark.c file
cat << EOF > benchmark.c
#include <stdio.h>
EOF

	for i in {1..10000}; do \
	    echo "extern int func_$i();" >> benchmark.c; \
	done

cat << EOF >> benchmark.c
int main() {
    int result = 0;
EOF

	for i in {1..10000}; do \
	    echo "    result += func_${i}();" >> benchmark.c; \
	done

	cat << EOF >> benchmark.c
    printf("Result: %d\\n", result);
    return 0;
}
EOF