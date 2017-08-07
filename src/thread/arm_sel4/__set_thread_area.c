#include <stdint.h>
#include "pthread_impl.h"
#include "libc.h"

/* Implementation here a simplification of the arm/__set_thread_area.c */

extern uintptr_t __attribute__((__visibility__("hidden")))
	__a_gettp_ptr;

#if !__ARM_ARCH_7A__ && !__ARM_ARCH_7R__ && __ARM_ARCH < 7
static uintptr_t get_tp(void) {
    /* There's no good way to defer this bit of policy to elsewhere in the system,
     * instead we just read the word out of the seL4 globals page that represents the
     * TLS value */
    return *(uintptr_t*)0xffffc004;
}
#endif

int __set_thread_area(void *p)
{
#if !__ARM_ARCH_7A__ && !__ARM_ARCH_7R__ && __ARM_ARCH < 7
    __a_gettp_ptr = (uintptr_t)get_tp;
#endif
	return __syscall(__ARM_NR_set_tls, p);
}
