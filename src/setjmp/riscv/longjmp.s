.global _longjmp
.global longjmp
.type   _longjmp,@function
.type   longjmp,@function

#define LW lw
#define REGSIZE (4)

_longjmp:
longjmp:
  LW x1, (1 *4)(a0)
  LW x2, (2*4)(a0)
  LW x3, 3*4(a0)
  LW x4, 4*4(a0)
  LW x5, 5*4(a0)
  LW x6, 6*4(a0)
  LW x7, 7*4(a0)
  LW x8, 8*4(a0)
  LW x9, 9*4(a0)
  LW x10, 10*4(a0)
  LW x11, 11*4(a0)
  LW x12, 12*4(a0)
  LW x13, 13*4(a0)
  LW x14, 14*4(a0)
  LW x15, 15*4(a0)
  LW x16, 16*4(a0)
  LW x17, 17*4(a0)
  LW x18, 18*4(a0)
  LW x19, 19*4(a0)
  LW x20, 20*4(a0)
  LW x21, 21*4(a0)
  LW x22, 22*4(a0)
  LW x23, 23*4(a0)
  LW x24, 24*4(a0)
  LW x25, 25*4(a0)
  LW x26, 26*4(a0)
  LW x27, 27*4(a0)
  LW x28, 28*4(a0)
  LW x29, 29*4(a0)
  LW x30, 30*4(a0)
  LW x31, 31*4(a0)

  ret
