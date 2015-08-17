#define __SYSCALL_LL_E(x) (x)
#define __SYSCALL_LL_O(x) (x)

extern unsigned long __sysinfo;

#define CALL_SYSINFO(n, ...) ((long(*)(long,...))__sysinfo)(n, ##__VA_ARGS__)

static inline long __syscall0(long n)
{
    return CALL_SYSINFO(n);
}

static inline long __syscall1(long n, long a1)
{
    return CALL_SYSINFO(n, a1);
}

static inline long __syscall2(long n, long a1, long a2)
{
    return CALL_SYSINFO(n, a1, a2);
}

static inline long __syscall3(long n, long a1, long a2, long a3)
{
    return CALL_SYSINFO(n, a1, a2, a3);
}

static inline long __syscall4(long n, long a1, long a2, long a3, long a4)
{
    return CALL_SYSINFO(n, a1, a2, a3, a4);
}

static inline long __syscall5(long n, long a1, long a2, long a3, long a4, long a5)
{
    return CALL_SYSINFO(n, a1, a2, a3, a4, a5);
}

static inline long __syscall6(long n, long a1, long a2, long a3, long a4, long a5, long a6)
{
    return CALL_SYSINFO(n, a1, a2, a3, a4, a5, a6);
}
