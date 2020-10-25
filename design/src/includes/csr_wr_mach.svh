// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_wr_mach.svh
// Description   :  Contains CSR Write logic for Machine mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // ================================================= Machine Mode =================================================

   // ------------------------------ Machine Trap Setup
   // Machine status register.
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
   //                    31          22    21    20   19    18    17  16:15 14:13 12:11 9:10    8     7     6     5     4     3     2     1    0
   assign csr_mstatus = {sd, 8'b0,  tsr,   tw,  tvm, mxr,  sum, mprv,   xs,   fs,  mpp, 2'b0,  spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};

   `ifdef ext_S
   csr_std_wr #(0,12'h300,1) CC_tsr (clk_in, reset_in, mode, csr_wr, csr_wr_data[22], tsr);
   csr_std_wr #(0,12'h300,1) CC_tw  (clk_in, reset_in, mode, csr_wr, csr_wr_data[21], tw);
   csr_std_wr #(0,12'h300,1) CC_tvm (clk_in, reset_in, mode, csr_wr, csr_wr_data[20], tvm);
   csr_std_wr #(0,12'h300,1) CC_mxr (clk_in, reset_in, mode, csr_wr, csr_wr_data[19], mxr);
   csr_std_wr #(0,12'h300,1) CC_sum (clk_in, reset_in, mode, csr_wr, csr_wr_data[18], sum);
   `else
   assign tvm  = 0;                                               // p. 22-23. TVM, TW, TSR is hardwired to 0 if S-mode is not supported.
   assign tw   = 0;
   assign tsr  = 0;
   assign mxr  = 0;                                               // MXR is hardwired to 0 if S-mode is not supported.
   assign sum  = 0;                                               // SUM is hardwired to 0 if S-mode is not supported
   `endif // ext_S

   `ifdef ext_U
   csr_std_wr #(0,12'h300,1) CC_mprv (clk_in,reset_in, mode, csr_wr, csr_wr_data[17], mprv);
   `else
   assign mprv = 0;                                               // p. 22. MPRV is hardwired to 0 if U-mode is not supported
   `endif // ext_U

   assign xs = 0;                                                 // xs = 2'b00 - user mode Extension Status = OFF. p 23  Read-Only

   `ifdef ext_F
   csr_std_wr #(0,12'h300,2) CC_fs (clk_in,reset_in, mode, csr_wr, csr_wr_data[14:13], fs);
   `else
   assign fs = 0;                                                 // fs = 2'b00 - Floating Point Status = OFF. p 23  R/W    see p 23
   `endif

   assign sd   = (xs == 2'b11) || (fs == 2'b11);                  // used in csr_mstatus, sstatus and ustatus. see CSRs 0x300, 0x100, 0x000

   always_ff @(posedge clk_in)
   begin
      // p. 21. To support nested traps, each privilege mode x has a two-level stack of interrupt-enable
      //        bits and privilege modes. xPIE holds the value of the interrupt-enable bit active
      //        prior to the trap, and xPP holds the previous privilege mode.

      // p. 21  When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE;
      //        xIE is set to 0; and xPP is set to y.

      // p. 21  The MRET, SRET, or URET instructions are used to return from traps in M-mode, S-mode, or
      //        U-mode respectively. When executing an xRET instruction, supposing xPP holds the value y, xIE
      //        is set to xPIE; the privilege mode is changed to y; xPIE is set to 1; and xPP is set to U (or M if
      //        user-mode is not supported).
      if (reset_in)
         mpp <= 2'b11;                                            // mpp = Machine Prevous Privileged mode
      else if ((exception.flag) & (nxt_mode == 3))                // holds the previous privilege mode
         mpp <= mode;                                             // mpp = Machine Prevous Privileged mode
      else if (mret)
         `ifdef ext_U
         mpp <= 2'b00;                                            // "and xPP is set to U (or M if user-mode is not supported)." p. 21 riscv-privileged.pdf
         `else
         mpp <= 2'b11;
         `endif

      if (reset_in)
         mpie  <= 1'b0;
      else if ((exception.flag) & (nxt_mode == 3))
         mpie  <= mie;
      else if (mret)
         mpie  <= 1'b1;                                           // "xPIE is set to 1" p. 20 riscv-privileged-v1.10

      // p. 20 The xIE bits are located in the low-order bits of csr_mstatus, allowing them to be atomically set
      //       or cleared with a single CSR instruction.
      if (reset_in)
         mie  <= FALSE;
      else if (csr_wr && (csr_addr == 12'h300) && (mode == 3))    // modes lower than 3 cannot modify mie bit
         mie  <= csr_wr_data[3];
      else if ((exception.flag) & (nxt_mode == 3))
         mie  <= 'd0;
      else if (mret)
         mie  <= mpie;                                            // "xIE is set to xPIE;"  p. 21 riscv-privileged.pdf
   end

   // -------------------------------------- MISA -------------------------------------

                  //   MXL     ZY XWVU TSRQ PONM LKJI HGFE DCBA
   parameter MISA = 32'b0100_0000_0000_0000_0000_0001_0000_0000   /* MXLEN bits = 2'b01 = RV32, and I bit -----> RV32I */
   `ifdef ext_A
                  | 32'b0000_0000_0000_0000_0000_0000_0000_0001   /* A bit - Atomic Instruction support */
   `endif
   `ifdef ext_C
                  | 32'b0000_0000_0000_0000_0000_0000_0000_0100   /* C bit - Compressed Instruction support */
   `endif
   `ifdef ext_F
                  | 32'b0000_0000_0000_0000_0000_0000_0010_0000   /* F bit - Single Precision Floating Point support */
   `endif
   `ifdef ext_M
                  | 32'b0000_0000_0000_0000_0001_0000_0000_0000   /* M bit - integer Multiply, Divide, Remainder support */
   `endif
   `ifdef ext_N
                  | 32'b0000_0000_0000_0000_0010_0000_0000_0000   /* N bit - Interrupt support */
   `endif
   `ifdef ext_S
                  | 32'b0000_0000_0000_0100_0000_0000_0000_0000   /* S bit - Supervisor mode support */
   `endif
   `ifdef ext_U
                  | 32'b0000_0000_0001_0000_0000_0000_0000_0000   /* U bit - User mode support */
   `endif
   ;//                         ZY XWVU TSRQ PONM LKJI HGFE DCBA
   // ISA and extensions
   // 12'h301 = 12'b0011_0000_0001  misa                          (read-write but currently Read Only)
   // NOTE: if made to be writable, don't allow bit  2 to change to 1 if ext_C not defined
   // NOTE: if made to be writable, don't allow bit  5 to change to 1 if ext_F not defined
   // NOTE: if made to be writable, don't allow bit 12 to change to 1 if ext_M not defined
   // NOTE: if made to be writable, don't allow bit 13 to change to 1 if ext_N not defined
   // NOTE: if made to be writable, don't allow bit 18 to change to 1 if ext_S not defined
   // NOTE: if made to be writable, don't allow bit 20 to change to 1 if ext_U not defined
   // etc...
   assign csr_misa = MISA;

   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

   //!!! NOTE: DOn't yet know how to implement all the logic for medeleg and mideleg!!!

   `ifdef ext_S // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // Machine exception delegation register.
      // 12'h302 = 12'b0011_0000_0010  medeleg                       (read-write)
      csr_std_wr #(0,12'h302,RSZ) Medeleg       (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_medeleg);

      // Machine interrupt delegation register.
      // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
      csr_std_wr #(0,12'h303,RSZ) Mideleg       (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mideleg);
   `else // !ext_S
      `ifdef ext_U
         `ifdef ext_N
         // Machine exception delegation register.
         // 12'h302 = 12'b0011_0000_0010  medeleg                       (read-write)
         csr_std_wr #(0,12'h302,RSZ) Medeleg    (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_medeleg);

         // Machine interrupt delegation register.
         // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
         csr_std_wr #(0,12'h303,RSZ) Mideleg    (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mideleg);
         `endif
      `endif
   `endif

   // Machine interrupt-enable register.
   // 12'h304 = 12'b0011_0000_0100  mie                           (read-write)
   csr_std_wr #(0,12'h304,RSZ,'hFFFF_F444) Mie  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mie);   // Note: bits 2,6,10,12-31 are not changeable and are "hardwired" to 0

   // Machine trap-handler base address.
   // 12'h305 = 12'b0011_0000_0101  mtvec                         (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
   csr_std_wr #(0,12'h305,RSZ,32'h0E) Mtvec     (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mtvec);

   // Machine counter enable.
   // 12'h306 = 12'b0011_0000_0110  mcounteren                    (read-write)
   csr_std_wr #(0,12'h306) Mcounteren           (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mcounteren);

   // ------------------------------ Machine Counter Setup
   // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
   // 12'h320 = 12'b0011_0010_00000  mcountinhibit                (read-write)
   generate
      if (SET_MCOUNTINHIBIT == 1)
      begin : CNT_INHIBIT1
         assign csr_mcountinhibit = SET_MCOUNTINHIBIT_BITS;       // bit 1 (TIME) is never used
      end
      else
      begin : CNT_INHIBITx
         csr_std_wr #(0,12'h320,RSZ,2) Mcountinhibit (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mcountinhibit);  // NOTE: bit 1 always "hardwired" to 0
      end
   endgenerate

   `ifdef use_MHPM
   genvar mpmes;
   generate
      // Machine hardware performance-monitoring event selectors mhpmevent3 - mhpmevent31
      // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                 (read-write)
      for (mpmes = 0; mpmes < NUM_MHPM; mpmes++)
      begin
         // Note: width of csr_mhpmevent[] is define as 5 bits - up to 32 different event selections
         csr_std_wr #(0,12'h323+mpmes,EV_SEL_SZ) Mhpmevent (clk_in,reset_in, mode, csr_wr, csr_wr_data[3:0], csr_mhpmevent[mpmes]); // only 4 bit wide registers
      end
   endgenerate
   `endif

   // ------------------------------ Machine Trap Handling
   // Scratch register for machine trap handlers.
   // 12'h340 = 12'b0011_0100_0000  mscratch                      (read-write)
   csr_std_wr #(0,12'h340) Mscratch             (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_mscratch);

   // Machine Exception Program Counter. Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  mepc                          (read-write)   see riscv-privileged p 36
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_mepc <=  '0;
      else if ((exception.flag) & (nxt_mode == 3))
         csr_mepc <= {exception.pc[RSZ-1:1], 1'b0};               // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h341) & (mode == 3))     // Only Machine mode can write to this CSR
         csr_mepc <= {csr_wr_data[RSZ-1:1], 1'b0};                // Software settable - low bit is always 0
   end
   assign mepc  = {csr_mepc[PC_SZ-1:2], (ialign ? csr_mepc[1] : 1'b0), csr_mepc[0]}; // bit 1 is masked when read when ialign == 0 (32 bit alignment)

   // Machine Exception Cause.
   // 12'h342 = 12'b0011_0100_0010  mcause                        (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_mcause <= 'b0;
      else if (exception.flag & (nxt_mode == 3))
         csr_mcause <= exception.cause;                           // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h342) & (mode == 3))
         csr_mcause <= csr_wr_data;                               // Sotware settable
   end

   // The mbadaddr register has been subsumed by a more general mtval register that can now capture bad instruction bits on an illegal instruction fault to speed instruction emulation. see riscv-privileged-20190608-1.pdf p. iii, 38
   // Machine Exception Trap Value.                               see riscv-privileged p. 38-39
   // 12'h343 = 12'b0011_0100_0011  mtval                         (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_mtval <= 'b0;
      else if (exception.flag & (nxt_mode == 3))
         csr_mtval <= exception.tval;                             // save trap value for exception
      else if (csr_wr && (csr_addr == 12'h343) & (mode == 3))     // Only Machine mode can write to this CSR
         csr_mtval <= csr_wr_data;                                // Sotware settable
   end

   // ---------------------- Machine Interrupt Pending bits ----------------------
   // 12'h344 = 12'b0011_0100_0100  mip                           (read-write)  machine mode
   `ifdef ext_N
   assign meip = ext_irq;                                         // MEIP - Machine    mode External Interrupt Pending
   assign mtip = time_irq;                                        // MTIP - Machine    mode Timer Interrupt Pending
   assign msip = sw_irq;                                          // MSIP - Machine    mode Software Interrupt Pending
   `else
   assign meip = FALSE;                                           // For all the various interrupt types (software, timer, and external), if a privilege level is not supported,
   assign mtip = FALSE;                                           // or if U-mode is supported but the N extension is not supported, then the associated pending
   assign msip = FALSE;                                           // and interrupt-enable bits are hardwired to zero in the mip and mie registers respectively. see riscv-privileged.pdf p 31
   `endif
   assign csr_mip =  {20'b0,meip,1'b0,seip,ueip,mtip,1'b0,stip,utip,msip,1'b0,ssip,usip};

   // ------------------------------ Machine Protection and Translation

   // 12'h3A0 - 12'h3A3
   `ifdef USE_PMPCFG
      // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                    (read-write)
      csr_std_wr #(0,12'h3A0) Mpmpcfg0 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpcfg0);
      // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                    (read-write)
      csr_std_wr #(0,12'h3A1) Mpmpcfg1 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpcfg1);
      // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                    (read-write)
      csr_std_wr #(0,12'h3A2) Mpmpcfg2 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpcfg2);
      // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                    (read-write)
      csr_std_wr #(0,12'h3A3) Mpmpcfg3 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpcfg3);
   `endif

   // 12'h3B0 - 12'h3BF
   // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
   `ifdef PMP_ADDR0  csr_std_wr #(0,12'h3B0) Mpmpaddr0   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr0);    `endif
   `ifdef PMP_ADDR1  csr_std_wr #(0,12'h3B1) Mpmpaddr1   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr1);    `endif
   `ifdef PMP_ADDR2  csr_std_wr #(0,12'h3B2) Mpmpaddr2   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr2);    `endif
   `ifdef PMP_ADDR3  csr_std_wr #(0,12'h3B3) Mpmpaddr3   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr3);    `endif
   `ifdef PMP_ADDR4  csr_std_wr #(0,12'h3B4) Mpmpaddr4   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr4);    `endif
   `ifdef PMP_ADDR5  csr_std_wr #(0,12'h3B5) Mpmpaddr5   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr5);    `endif
   `ifdef PMP_ADDR6  csr_std_wr #(0,12'h3B6) Mpmpaddr6   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr6);    `endif
   `ifdef PMP_ADDR7  csr_std_wr #(0,12'h3B7) Mpmpaddr7   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr7);    `endif
   `ifdef PMP_ADDR8  csr_std_wr #(0,12'h3B8) Mpmpaddr8   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr8);    `endif
   `ifdef PMP_ADDR9  csr_std_wr #(0,12'h3B9) Mpmpaddr9   (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr9);    `endif
   `ifdef PMP_ADDR10 csr_std_wr #(0,12'h3BA) Mpmpaddr10  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr10);   `endif
   `ifdef PMP_ADDR11 csr_std_wr #(0,12'h3BB) Mpmpaddr11  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr11);   `endif
   `ifdef PMP_ADDR12 csr_std_wr #(0,12'h3BC) Mpmpaddr12  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr12);   `endif
   `ifdef PMP_ADDR13 csr_std_wr #(0,12'h3BD) Mpmpaddr13  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr13);   `endif
   `ifdef PMP_ADDR14 csr_std_wr #(0,12'h3BE) Mpmpaddr14  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr14);   `endif
   `ifdef PMP_ADDR15 csr_std_wr #(0,12'h3BF) Mpmpaddr15  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_pmpaddr15);   `endif

   `ifdef add_DM
   // Debug Write registers - INCOMPLETE!!!!!!!!!!!
   // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
   csr_std_wr #(0,12'h7A0) Mtsel (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_tselect);     // Trigger Select Register
   csr_std_wr #(0,12'h7A1) Mtdr1 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_tdata1);      // Trigger Data Register 1
   csr_std_wr #(0,12'h7A2) Mtdr2 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_tdata2);      // Trigger Data Register 2
   csr_std_wr #(0,12'h7A3) Mtdr3 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_tdata3);      // Trigger Data Register 3

   // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
   // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
   csr_std_wr #(0,12'h7B0) Mdcsr (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_dcsr);        // Debug Control and Status Register
   csr_std_wr #(0,12'h7B1) Mdpc  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_dpc);         // Debug PC Register
   csr_std_wr #(0,12'h7B2) Mdsr0 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_dscratch0);   // Debug Scratch Register 0
   csr_std_wr #(0,12'h7B3) Mdsr1 (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_dscratch1);   // Debug Scratch Register 1
   `endif // add_DM

   // ------------------------------ Machine Counter/Timers
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // mhpmcountern, respectively. p 34 risvcv-privileged.pdf

   // Machine cycle counter.        p 136 "Cycle counter for RDCYCLE instruction"
   always_ff @(posedge clk_in)
   begin
      // Lower 32 bits of mcycle, RV32I only.
      // 12'hB00 = 12'b1011_0000_0000  mcycle_lo (read-write)
      if (reset_in)
         csr_mcycle_lo      <= 'd0;
      else if (csr_wr && (csr_addr == 12'hB00) && (mode == 3))
         csr_mcycle_lo      <= csr_wr_data;
      else if (!csr_mcountinhibit[0])
         csr_mcycle_lo      <= csr_mcycle_lo + 'd1;                        // increment lower 32 bits

      // Upper 32 bits of mcycle, RV32I only.
      // 12'hB80 = 12'b1011_1000_0000  mcycle_hi (read-write)
      if (reset_in)
         csr_mcycle_hi  <= 'd0;
      else if (csr_wr && (csr_addr == 12'hB80) && (mode == 3))
         csr_mcycle_hi  <= csr_wr_data;
      else if (!csr_mcountinhibit[0] & (csr_mcycle_lo == {RSZ{1'b1}}))     // increment upper 32 bits when all lower 32 bits are 1
         csr_mcycle_hi  <= csr_mcycle_hi + 'd1;
   end

   // Machine time counter.        riscv-spec.pdf p 57  RDTIME instruction
   // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
   // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf


   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
   logic             tot_retired;      // In this design, at most, 1 instruction can retire per clock cycle

   // At most, for this design, only 1 instruction can retire per clock so just OR the retire bits (instead of adding)
   assign tot_retired      = current_events.ret_cnt[LD_RET]  | current_events.ret_cnt[ST_RET]   | current_events.ret_cnt[CSR_RET]  | current_events.ret_cnt[SYS_RET]  |
                             current_events.ret_cnt[ALU_RET] | current_events.ret_cnt[BXX_RET]  | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET] |
                             current_events.ret_cnt[IM_RET]  | current_events.ret_cnt[ID_RET]   | current_events.ret_cnt[IR_RET]   | current_events.ret_cnt[HINT_RET] |
               `ifdef ext_F  current_events.ret_cnt[FLD_RET] | current_events.ret_cnt[FST_RET]  | current_events.ret_cnt[FP_RET]   | `endif
                             current_events.ret_cnt[UNK_RET] ;

   always_ff @(posedge clk_in)
   begin
      // Lower 32 bits of minstret, RV32I only.
      // 12'hB02 = 12'b1011_0000_0010  minstret_lo             (read-write)
      if (reset_in)
         csr_minstret_lo <= 'd0;
      else if (csr_wr && (csr_addr == 12'hB02) && (mode == 3))
         csr_minstret_lo <= csr_wr_data;
      else if (!csr_mcountinhibit[2])
         csr_minstret_lo <= csr_minstret_lo + tot_retired;

      // Upper 32 bits of minstret, RV32I only.
      // 12'hB82 = 12'b1011_1000_0010  minstret_hi             (read-write)
      if (reset_in)
         csr_minstret_hi   <= 'd0;
      else if (csr_wr && (csr_addr == 12'hB82) && (mode == 3))
         csr_minstret_hi   <= csr_wr_data;
      else if (!csr_mcountinhibit[2] & (csr_minstret_lo == {RSZ{1'b1}})) // increment upper 32 bits when all lower 32 bits are 1
         csr_minstret_hi   <= csr_minstret_hi + 'd1;
   end

   `ifdef use_MHPM
   // Machine instructions-retired counter.
   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
   logic             br_cnt;
   logic             misaligned_cnt;

   assign br_cnt           = current_events.ret_cnt[BXX_RET] | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET];
   assign misaligned_cnt   = (current_events.e_flag ? current_events.e_cause[0] : 0) |  /* 0 = Instruction Address Misaligned */
                             (current_events.e_flag ? current_events.e_cause[4] : 0) |  /* 4 = Load Address Misaligned */
                             (current_events.e_flag ? current_events.e_cause[4] : 0);   /* 6 = Store Address Misaligned */

   genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
   generate
//      logic     [E-1:0] events[0:N];  // N different event counts (counts for this clock cycle) that can be used. E bits needed per event for this design (2^E instructions max per clock cycle)
      logic               events[0:23];  // 24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
      logic [NUM_MHPM-1:0] [2*RSZ-1:0] nxt_mhpmcounter;
      logic [NUM_MHPM-1:0] [2*RSZ-1:0] mhpmcounter;

      // Machine hardware performance-monitoring counters
      for (n = 0; n < NUM_MHPM; n++)
      begin : MHPM_CNTR
         // increment mhpmcounter[] if the Event Selector is not 0 and the corresponding csr_mcountinhibit bit is not set.
         // currently there are 16 possible events[], where event[0] = 0
         assign mhpmcounter[n]      = {csr_mhpmcounter_hi[n], csr_mhpmcounter_lo[n]};
         assign nxt_mhpmcounter[n]  = csr_mcountinhibit[n+3] ? mhpmcounter[n] : mhpmcounter[n] + events[csr_mhpmevent[n]];

         always_ff @(posedge clk_in)
         begin
            // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
            if (reset_in)
               csr_mhpmcounter_lo[n] <= 'd0;
            else if (csr_wr && (csr_addr == (12'hB03+n)) && (mode == 3)) // Andrew Waterman says these are writable in an Apr 8, 2019 post
               csr_mhpmcounter_lo[n] <= csr_wr_data;
            else
               csr_mhpmcounter_lo[n] <= nxt_mhpmcounter[n] [RSZ-1:0];

            // p. 31 riscv-privledged-v1.10
            // All counters should be implemented, but a legal implementation is to
            // hard-wire both the counter and its corresponding event selector to 0.
            // Counters not created here get read as a value of 0 in always_comb block further below

            // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
            if (reset_in)
               csr_mhpmcounter_hi[n] <= 'd0;
            else if (csr_wr && (csr_addr == (12'hB83+n)) && (mode == 3))
               csr_mhpmcounter_hi[n] <= csr_wr_data;
            else
               csr_mhpmcounter_hi[n] <= nxt_mhpmcounter[n] [2*RSZ-1:RSZ];
         end
      end

      assign events[0 ]  = 0;                                        // no change to mhpm counter when this even selected
      // The following events return a count value which is used by a csr_mhpmcounter[]. csr_mhpmcounter[n] can use whichever event[x] it wants by setting csr_mphmevent[n]
      // The count sources (i.e. current_events.ret_cnt[LD_RET]) may be changed by the user to reflect what information they want to use for a given counter.
      // Any of the logic on the RH side of the assignment can be used for any events[x] - even new logic can be created for a new event source.
      assign events[1 ]  = current_events.ret_cnt[LD_RET];           // Load Instruction retirement count. See ret_cnt[] in cpu_structs_pkg.sv. One ret_cnt for each instruction type.
      assign events[2 ]  = current_events.ret_cnt[ST_RET];           // Store Instruction retirement count.
      assign events[3 ]  = current_events.ret_cnt[CSR_RET];          // CSR
      assign events[4 ]  = current_events.ret_cnt[SYS_RET];          // System
      assign events[5 ]  = current_events.ret_cnt[ALU_RET];          // ALU
      assign events[6 ]  = current_events.ret_cnt[BXX_RET];          // BXX
      assign events[7 ]  = current_events.ret_cnt[JAL_RET];          // JAL
      assign events[8 ]  = current_events.ret_cnt[JALR_RET];         // JALR
      assign events[9 ]  = current_events.ret_cnt[IM_RET];           // Integer Multiply
      assign events[10]  = current_events.ret_cnt[ID_RET];           // Integer Divide
      assign events[11]  = current_events.ret_cnt[IR_RET];           // Integer Remainder
      assign events[12]  = current_events.ret_cnt[HINT_RET];         // Hint Instructions
      assign events[13]  = current_events.ret_cnt[UNK_RET];          // Unknown Instructions
      assign events[14]  = current_events.e_flag ? e_cause[0] : 0;   // e_cause[0] = Instruction Address Misaligned
      assign events[15]  = current_events.e_flag ? e_cause[1] : 0;   // e_cause[1] = Instruction Access Fault
      assign events[16]  = current_events.mispredict;                // branch mispredictions
      assign events[17]  = br_cnt;                                   // all bxx, jal, jalr instructions
      assign ecents[18]  = misaligned_cnt;                           // all misaligned instructions
      assign events[19]  = tot_retired;                              // total of all instructions retired this clock cycle
      `ifdef ext_F
      assign events[20]  = current_events.ret_cnt[FLD_RET];          // single precision Floating Point Load retired
      assign events[21]  = current_events.ret_cnt[FST_RET];          // single precision Floating Point Store retired
      assign events[22]  = current_events.ret_cnt[FP_RET];           // single precision Floating Point operation retired
      assign events[23]  = current_events.ext_irq;                   // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
      `endif
      // Note: currently there are NUM_EVENTS events as specified at the beginning of this generate block. The number can be changed if more or less event types are needed
   endgenerate
   `endif

   // ------------------------------ Machine Information Registers
   // Vendor ID
   // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
   assign csr_mvendorid = M_VENDOR_ID;

   // Architecture ID
   // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
   assign csr_marchid   = M_ARCH_ID;

   // Implementation ID
   // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
   assign csr_mimpid    = M_IMP_ID;

   // Hardware Thread ID
   // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
   assign csr_mhartid   = M_HART_ID;


   // ===================================================================================================================
