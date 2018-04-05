#if defined(_POSIX_SOURCE) || defined(_POSIX_C_SOURCE) \
 || defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#define PAGE_SIZE 4096 
#define LONG_BIT __riscv_xlen
#endif

#if __riscv_xlen == 32
#define LONG_MAX  0x7fffffffL
#else
#define LONG_MAX  0x7fffffffffffffffL
#endif
#define LLONG_MAX  0x7fffffffffffffffLL
