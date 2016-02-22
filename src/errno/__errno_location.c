#include "pthread_impl.h"

int err;

int *__errno_location(void)
{
	return &err;
}
