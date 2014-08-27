.global __syscall
.type __syscall,%function
__syscall:
    sub sp, sp, #4
    push {r5,r6}
    adr r5, 1f
    ldr r6, 1f
    ldr r5, [r5,r6]
    str r5, [sp, #8]
    pop {r5, r6}
    pop {pc}

.hidden __sysinfo
1:  .word __sysinfo-1b
