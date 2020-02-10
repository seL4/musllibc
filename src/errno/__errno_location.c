#include "pthread_impl.h"

_Thread_local int errno;

int *__errno_location(void)
{
	return &errno;
}
