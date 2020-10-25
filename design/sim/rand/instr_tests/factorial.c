// Notes: 8192 - 16535 is l1 D$ space
//        0    - 8191  is L1 I$ space
// li & lui didn't work, so li x1,20 was used so thatwhen main does "return()",
// the PC will go to pass_fail location, create address FFFF_FFF0 in x1 which will
// cause the hardware to create signal sim_stop when sw x0, 0(x1) executes.
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
   int n, k;
   
   k = 1;
   for (n = 2; n <= 4; n++)   // 4!  Factorial = 1*2*3*4 = 24
      k = k * n;
   return((k == 24) ? 1 : 0);
}

