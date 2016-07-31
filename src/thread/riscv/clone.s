/* int clone(fn, stack, flags, arg, ptid, tls, ctid)
 *           r3  r4     r5     r6   sp+0  sp+4 sp+8
 * sys_clone(flags, stack, ptid, ctid, tls)
 */
.global __clone
.type   __clone,@function
__clone:
	nop
