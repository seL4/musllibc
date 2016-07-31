.global __setjmp
.global _setjmp
.global setjmp
.type __setjmp,@function
.type _setjmp,@function
.type setjmp,@function

#define SW sw

__setjmp:
_setjmp:

setjmp:
  SW x1, 1*4(a0)
  SW x2, 2*4(a0)
  SW x3, 3*4(a0)
  SW x4, 4*4(a0)
  SW x5, 5*4(a0)
  SW x6, 6*4(a0)
  SW x7, 7*4(a0)
  SW x8, 8*4(a0)
  SW x9, 9*4(a0)
  SW x10, 10*4(a0)
  SW x11, 11*4(a0)
  SW x12, 12*4(a0)
  SW x13, 13*4(a0)
  SW x14, 14*4(a0)
  SW x15, 15*4(a0)
  SW x16, 16*4(a0)
  SW x17, 17*4(a0)
  SW x18, 18*4(a0)
  SW x19, 19*4(a0)
  SW x20, 20*4(a0)
  SW x21, 21*4(a0)
  SW x22, 22*4(a0)
  SW x23, 23*4(a0)
  SW x24, 24*4(a0)
  SW x25, 25*4(a0)
  SW x26, 26*4(a0)
  SW x27, 27*4(a0)
  SW x28, 28*4(a0)
  SW x29, 29*4(a0)
  SW x30, 30*4(a0)
  SW x31, 31*4(a0)

  ret
