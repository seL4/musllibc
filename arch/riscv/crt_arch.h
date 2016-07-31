__asm__("\
.global _start\n\
.align  4\n\
_start:\n\
  add a0, x0, sp\n\
/* Set gp for relaxation. See \n\
 * https://www.sifive.com/blog/2017/08/28/all-aboard-part-3-linker-relaxation-in-riscv-toolchain/ \n\
 */ \n\
.option push  \n\
.option norelax \n\
1:auipc gp, %pcrel_hi(__global_pointer$) \n\
  addi  gp, gp, %pcrel_lo(1b) \n\
.option pop \n\
  la   s0, _start_c\n\
  jalr s0\n\
");
