#include <string.h>
#include <elf.h>
#include <endian.h>

#define LDSO_ARCH "riscv"

#define TPOFF_K 0

static int remap_rel(int type)
{
  /* TODO */
	return 0;
}

#include "syscall.h"
void __reloc_self(int c, size_t *a, size_t *dynv)
{
  /* TODO */
}
