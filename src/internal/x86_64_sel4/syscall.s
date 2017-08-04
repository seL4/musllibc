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
    subq $8, %rsp           # Reserve space for tail call
    pushq %rax              # Save RAX
    call 1f                 # Determine our IP
1:  movq (%rsp),%rax
    addq $[__sysinfo-1b],%rax
    mov (%eax),%rax
    test %rax,%rax
    jz 2f
    movq %rax, 16(%rsp)     # Put this in space we reserved
    addq $8, %rsp           # Junk our IP
    popq %rax               # Restore eax
    ret                     # Tail call
2:  addq $8, %rsp
    popq %rax
    addq $8, %rsp
    int $128
    ret
