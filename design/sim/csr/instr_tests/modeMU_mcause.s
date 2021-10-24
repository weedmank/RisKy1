asm(
"li      sp,8192\n"
"li      x1, -1\n"
"csrrw   x5,x1,12'h342\n"  // Rd = X5, Rs1 = X1, CSR = 0x342
"nop\n"
"nop\n"
"nop\n"
"li      x1,-1\n"          // X1 = 0xFFFF_FFFF
"slli    x1,x1,4\n"        // X1 = X1 << 4; X1 will become 0xFFFF_FFF0
"sw      x0, 0(x1)\n"      // cause sim_stop signal to occcur
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