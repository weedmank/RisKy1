// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_wr_super.svh
// Description   :  Contains CSR Write logic for Supervisor mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // ================================================= Supervisor Mode =================================================
   `ifdef ext_S

   // ------------------------------ Supervisor Trap Setup
   // Supervisor status register.
   // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
   //                    31          22    21    20   19    18    17  16:15 14:13 12:11 9:10     8     7     6     5     4     3     2     1    0
   assign csr_sstatus = {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0,  spp, 1'b0, 1'b0, spie, upie, 1'b0, 1'b0,  sie, uie};

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
         spp <= 1'b0;                                             // spp = User?
      else if (exception.flag & (nxt_mode == 1))
         spp <= mode[1];                                          // spp = Supervisor Prevous Privileged mode
      else if (sret)                                              // Note: S mode implies there's a U-mode because S mode is not allowed unless U is supported
         spp <= 1'b0;                                             // "and xPP is set to U (or M if user-mode is not supported)." p. 20 riscv-privileged-v1.10

      if (reset_in)                                               // spie
         spie  <= 'd0;
      else if (exception.flag & (nxt_mode == 1))
         spie  <= sie;                                            // spie <= sie
      else if (sret)
         spie  <= TRUE;                                           // "xPIE is set to 1" p. 20 riscv-privileged-v1.10

      // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
      //       or cleared with a single CSR instruction.
      if (reset_in)
         sie  <= FALSE;
      else if (csr_wr && (csr_addr == 12'h100) && (nxt_mode >= 1))
         sie  <= csr_wr_data[1];
      else if (exception.flag & (nxt_mode == 1))
         sie  <= 'd0;
      else if (sret)                                              // "xIE is set to xPIE;"  p. 20 riscv-privileged-v1.10
         sie  <= spie;
   end

   // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
   // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged.pdf p 28

   //!!! NOTE: DOn't yet know how to implement all the logic for medeleg and mideleg!!!

   `ifdef ext_N
   // Supervisor exception delegation register.
   // 12'h102 = 12'b0001_0000_0010  sedeleg                             (read-write)
   csr_std_wr #(0,12'h102,RSZ) Sedeleg          (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_sedeleg);

   // Supervisor interrupt delegation register.
   // 12'h103 = 12'b0001_0000_0011  sideleg                             (read-write)
   csr_std_wr #(0,12'h103,RSZ) Sideleg          (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_sideleg);
   `endif

   // Supervisor interrupt-enable register.
   // 12'h104 = 12'b0001_0000_0100  sie                                 (read-write)
   csr_std_wr #(0,12'h104,RSZ,'hFFFF_FCCC) Sie  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_sie);         // Note: bits 2-3, 6-7, 10-31 are not writable and are "hardwired" to 0

   // Supervisor trap handler base address.
   // 12'h105 = 12'b0001_0000_0101  stvec                               (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
   csr_std_wr #(0,12'h105,RSZ,32'h0E) Stvec     (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_stvec);

   // Supervisor counter enable.
   // 12'h106 = 12'b0001_0000_0110  scounteren                          (read-write)
   csr_std_wr #(0,12'h106) Scounteren           (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_scounteren);

   // ------------------------------ Supervisor Trap Handling
   // Scratch register for supervisor trap handlers.
   // 12'h140 = 12'b0001_0100_0000  sscratch                            (read-write)
   csr_std_wr #(0,12'h140) Sscratch             (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_sscratch);

   // Supervisor Exception Program Counter.
   // 12'h141 = 12'b0001_0100_0001  sepc                                (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_sepc <=  '0;
//    "When a trap is taken into S-mode, sepc is written with the virtual address of the instruction that was interrupted or that encountered the exception." riscv-privileged p 61
      else if (exception.flag & (nxt_mode == 1))
         csr_sepc <= {exception.pc[RSZ-1:1], 1'b0};                     // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h141) & (mode >= 1))           // Machine & Supervisor modes can write to this CSR
         csr_sepc <= {csr_wr_data[RSZ-1:1], 1'b0};                      // Software settable - low bit is always 0
   end
   assign sepc  = {csr_sepc[PC_SZ-1:2], (ialign ? csr_sepc[1] : 1'b0), csr_sepc[0]}; // bit 1 is masked when read when ialign == 0 (32 bit alignment)

   // Supervisor Exception Cause.
   // 12'h142 = 12'b0001_0100_0010  scause                              (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_scause <=  'b0;
      else if (exception.flag & (nxt_mode == 1))
         csr_scause <= exception.cause;                                 // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h142) & (mode >= 1))
         csr_scause <= csr_wr_data;                                     // Sotware settable
   end

   // Supervisor Exception Trap Value.                                  see riscv-privileged p. 38-39
   // 12'h143 = 12'b0001_0100_0011  stval                               (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_stval <=  'b0;
      else if (exception.flag & (nxt_mode == 1))
         csr_stval <= exception.cause;                                  // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h143) & (mode >= 1))           // Modes higher than User can write to this CSR
         csr_stval <= csr_wr_data;                                      // Sotware settable
   end

   `ifdef ext_N
   // The UEIP field in mip provides user-mode external interrupts when the N extension for user-mode
   // interrupts is implemented. It is defined analogously to SEIP. riscv-privileged.pdf p 31
   // ---------------------- Supervisor Interrupt Pending bits ---------------------
   // 12'h144 = 12'b0001_0100_0100  sip                                 (read-write)
   // see mip register with writes to address 12'h144
   always_ff @(posedge clk_in)
   begin
      // Supervisor interrupt pending.
      // 12'h144 = 12'b0001_0100_0100  sip                              (read-write)  supervisor mode
      if (reset_in)
      begin
         seip <= FALSE;
         stip <= FALSE;
         ssip <= FALSE;
      end
      else if (csr_wr && (csr_addr == 12'h144) & (mode >=1))
      begin
         seip <= csr_wr_data[9];                                        // set or clear SEIP
         stip <= csr_wr_data[5];                                        // set or clear STIP
         ssip <= csr_wr_data[1];                                        // set or clear SSIP
      end
      else if (mode == 1)                                               // irq setting during supervisor mode
      begin
         seip <= ext_irq;
         stip <= time_irq;
         ssip <= sw_irq;
      end
   end
   `else    // no interrutps can occur
   assign ssip = FALSE;                                                 // SSIP - Supervisor mode Software Interrupt Pending
   assign stip = FALSE;                                                 // STIP - Supervisor mode Timer Interrupt Pending
   assign seip = FALSE;                                                 // SEIP - Supervisor mode External Interrupt Pending
   `endif   // ext_N

   assign csr_sip = {20'b0,1'b0,1'b0,{seip | ext_irq},ueip,1'b0,1'b0,stip,utip,1'b0,1'b0,ssip,usip};

   // ------------------------------ Supervisor Protection and Translation
   // Supervisor address translation and protection.
   // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
   csr_std_wr #(0,12'h180) Satp (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_satp);


   `else    // no interrutps can occur
   assign spp  = 0;
   assign spie = 0;
   assign sie  = 0;

   assign ssip = FALSE;                                                 // SSIP - Supervisor mode Software Interrupt Pending
   assign stip = FALSE;                                                 // STIP - Supervisor mode Timer Interrupt Pending
   assign seip = FALSE;                                                 // SEIP - Supervisor mode External Interrupt Pending
   `endif   // ext_S
