int __set_thread_area(void *p)
{
    /* no support for TLS on seL4 at the moment */
    return 0;
}
