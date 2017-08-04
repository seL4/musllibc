.hidden __sysinfo

# We do some gymnastics here to pretend that a call to __syscall
# Is actually a call into the __sysinfo function. As they have
# the same type we really just want to do a jmp, but need to
# do the lookup in a way that supports PIC and not clobber
# any registers

.global __syscall
.hidden __syscall
.type __syscall,@function
__syscall:
    subl $4, %esp           # Reserve space for tail call
    push %eax               # Save EAX
    call 1f                 # Determine our IP
1:	mov (%esp),%eax
	add $[__sysinfo-1b],%eax
	mov (%eax),%eax
	test %eax,%eax
	jz 2f
	movl %eax, 8(%esp)      # Put this in space we reserved
	addl $4, %esp           # Junk our IP
	popl %eax               # Restore eax
	ret                     # Tail call
2:	addl $4, %esp
    popl %eax
    addl $4, %esp
	int $128
	ret
