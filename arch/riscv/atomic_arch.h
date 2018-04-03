#ifndef _INTERNAL_ATOMIC_H
#define _INTERNAL_ATOMIC_H


#define a_cas a_cas
static inline int a_cas(volatile int *p, int t, int s)
{
  /* FIXME: Temporary cas emulation */
  if(*p == t)
  {
    *p = s;
    return t;
  }

  return *p;

}

#define a_cas_p a_cas_p
static inline void *a_cas_p(volatile void *p, void *t, void *s)
{
  /* FIXME: Temporary cas emulation */
  if(*((unsigned long *) p) == (unsigned long) t)
  {
    *((unsigned long *) p) = (unsigned long) s;
    return t;
  }

  return (void *) *((unsigned long *) p);
}

#define a_barrier a_barrier
static inline void a_barrier()
{
    __asm__ __volatile__( "" : : : "memory" );
}
#endif
