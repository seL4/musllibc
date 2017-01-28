.global __syscall
.type __syscall,%function
__syscall:
    adr x9, 1f
    ldr x10, 1f
    ldr x9, [x9,x10]
    br  x9

.hidden __sysinfo
1:  .word __sysinfo-1b
