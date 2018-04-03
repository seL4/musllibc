#define LDSO_ARCH "riscv"

#define TPOFF_K 0

// Relocation is not currently supported for riscv
#define CRTJMP(pc,sp) __asm__ __volatile__( \
	".word 0x00000000": : "r"(pc), "r"(sp) : "memory" )
