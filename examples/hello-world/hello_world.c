#include <stdio.h>
#include <dlfcn.h>

extern void foo();

extern int global_variable;

int local_copy;

void my_function() {
    printf("This is my_function.\n");
}

int main() {
    local_copy = global_variable;
    printf("Hello, World: %d!\n", local_copy);
    foo();

    Dl_info info;

    // Getting information about the address of my_function
    if (dladdr((void *)my_function, &info)) {
        printf("Filename: %s\n", info.dli_fname);
        printf("Base address of shared object: %p\n", info.dli_fbase);
        printf("Name of nearest symbol: %s\n", info.dli_sname);
        printf("Address of nearest symbol: %p\n", info.dli_saddr);
    } else {
        printf("Error occurred while retrieving information.\n");
    }

    return 0;
}
