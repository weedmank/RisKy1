asm(
"li      sp,8192\n"
"lui     x1, %hi(pass_fail)\n"
"addi    x1, x1, %lo(pass_fail)\n"
"li      x1, 20\n"
"j       main\n"
"pass_fail:\n"
"li      x1,-1\n"
"slli    x1,x1,4\n"     // x1 = FFFF_FFF0
"sw      x0, 0(x1)\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop\n"
"nop"
);
// NOTE: it appear that X1 should hold return address of code that calls main()

int main()
{
   int volatile *dp;
   int result;
   dp = (int *)0x3000000;
   *dp = 0xABADCAFE;
   result = *dp;
   
   return((result == 0xABADCAFE) ? 1 : 0);
}
