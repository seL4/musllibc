#include "pthread_impl.h"

int __set_thread_area(void *p)
{
#ifdef SYS_set_thread_area
	return __syscall(SYS_set_thread_area, p);
#else
    /* The __init_tls routine requires that __set_thread_area work.
     * This function should be overriden by an arch __set_thread_area
     * function but for reasons unknown this is not happening,
     * consider this a temporary hack */
    return 0;
#endif
}
