

struct pthread global_tls;

#if ((__ARM_ARCH_6K__ || __ARM_ARCH_6ZK__) && !__thumb__) \
 || __ARM_ARCH_7A__ || __ARM_ARCH_7R__ || __ARM_ARCH >= 7

static inline pthread_t __pthread_self()
{
	return (void *)&global_tls;
}

#else

static inline pthread_t __pthread_self()
{
	return (void *)&global_tls;
}

#endif

#define TLS_ABOVE_TP
#define TP_ADJ(p) ((char *)(p) + sizeof(struct pthread) - 8)

#define CANCEL_REG_IP 18
