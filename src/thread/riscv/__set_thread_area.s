.global __set_thread_area
.type   __set_thread_area,@function
__set_thread_area:
	or	t1, a0, x0
	ret
