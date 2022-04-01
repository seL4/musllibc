#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include "libc.h"

/* This function should work with most dlmalloc-like chunk bookkeeping
 * systems, but it's only guaranteed to work with the native implementation
 * used in this library. */

void *__memalign(size_t align, size_t len)
{
	unsigned char *mem, *new, *end;
	size_t header, footer;

	if ((align & -align) != align) {
		errno = EINVAL;
		return NULL;
	}

	if (len > SIZE_MAX - align) {
		errno = ENOMEM;
		return NULL;
	}
	else if (len < 4*sizeof(size_t))
		/* Ensure the length of the final aligned chunk meets the minimum limit. */
		len = 4*sizeof(size_t);

	if (align <= 4*sizeof(size_t)) {
		if (!(mem = malloc(len)))
			return NULL;
		return mem;
	}

	if (!(mem = malloc(len + align-1)))
		return NULL;

	new = (void *)((uintptr_t)mem + align-1 & -align);
	if (new == mem) return mem;

	header = ((size_t *)mem)[-1];

	if (!(header & 7)) {
		((size_t *)new)[-2] = ((size_t *)mem)[-2] + (new-mem);
		((size_t *)new)[-1] = ((size_t *)mem)[-1] - (new-mem);
		return new;
	}

	end = mem + (header & -8);
	footer = ((size_t *)end)[-2];

	((size_t *)mem)[-1] = header&7 | new-mem;
	((size_t *)new)[-2] = footer&7 | new-mem;
	((size_t *)new)[-1] = header&7 | end-new;
	((size_t *)end)[-2] = footer&7 | end-new;

	if (new-mem >= 4*sizeof(size_t))
		free(mem);
	else {
		/* The size of the region before 'new' is too small to be handled as a chunk
		 * so we cannot call 'free' on it. Instead we either discard the memory or
		 * transfer ownership of it to the previous chunk */
		if (!(((size_t *)mem)[-2] & -8)) {
			/* mem->psize has no length, i.e. 'mem' is the first chunk in this mapped
			 * region. In this case we simply discard the memory prior to 'new' by
			 * making 'new' the first chunk of the mapped region. To do this we set
			 * the length of new->psize to 0 with the 'in use' flag set, which equates
			 * to simply setting its value to 1. */
			((size_t *)new)[-2] = 1;
		}
		else {
			/* There is a previous chunk, assign ownership of the region before 'new'
			 * to this previous chunk by increasing it's length. */
			unsigned char *pre = mem - (((size_t *)mem)[-2] & -8);
			((size_t *)pre)[-1] += new-mem;
			((size_t *)new)[-2] = ((size_t *)pre)[-1];
		}
	}

	return new;
}

weak_alias(__memalign, memalign);
