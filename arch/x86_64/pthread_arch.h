/* The tls in this file is a hack to provide a struct as proper tls wasn't working yet
*/
struct pthread global_tls;

static inline struct pthread *__pthread_self()
{
	return &global_tls;
}

#define TP_ADJ(p) (p)

#define CANCEL_REG_IP 16
