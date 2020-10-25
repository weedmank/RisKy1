// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_wr_user.svh
// Description   :  Contains CSR Write logic for User mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // ==================================================== User Mode ====================================================
   `ifdef ext_U

   `ifdef ext_N
   // When the N extension is present, and the outer execution environment has delegated designated
   // interrupts and exceptions to user-level, then hardware can transfer control directly to a user-level
   // trap handler without invoking the outer execution environment. see p. 123 riscv_spec.pdf

   // ------------------------------ User Trap Setup
   // User Status Register
   // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
   //                    31          22    21    20   19    18    17  16:15 14:13 12:11 9:10     8     7     6     5     4     3     2     1    0
   assign csr_ustatus = {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};

   // Writes can only modify upie, uie bits - see upie, uie (bits 4,0) of mstatus logic
   always_ff @(posedge clk_in)
   begin // see riscv-privileged.pdf
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
         upie  <= 1'b0;
      else if (exception.flag & (nxt_mode == 0))
         upie  <= uie;
      else if (uret)
         upie  <= 1'b1;

      // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
      //       or cleared with a single CSR instruction.
      if (reset_in)
         uie  <= FALSE;
      else if (csr_wr && (csr_addr == 12'h300) && (mode == 3))
         uie  <= csr_wr_data[0];
      `ifdef ext_S
      else if (csr_wr && (csr_addr == 12'h100) && (mode == 1))
         uie  <= csr_wr_data[0];
      `endif // ext_S
      else if (csr_wr && (csr_addr == 12'h000))
         uie  <= csr_wr_data[0];
      else if (exception.flag & (nxt_mode == 0))
         uie  <= 'd0;
      else if (uret)
         uie  <= upie;                                                  // "xIE is set to xPIE;"  p. 21 riscv-privileged.pdf
   end

   // User Interrupt-Enable Register
   // 12'h004 = 12'b0000_0000_0100  uie                                 (read-write)  user mode
   csr_std_wr #(0,12'h004) Uie                  (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_uie);

   // User Trap Handler Base address.
   // 12'h005 = 12'b0000_0000_0101  utvec                               (read-write)  user mode
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
   csr_std_wr #(0,12'h005,RSZ,32'h0E) Utvec     (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_utvec);

   // ------------------------------ User Trap Handling
   // Scratch register for user trap handlers.
   // 12'h040 = 12'b0000_0100_0000  uscratch                            (read-write)
   csr_std_wr #(0,12'h040) Uscratch             (clk_in,reset_in, mode, csr_wr, csr_wr_data, csr_uscratch);

   // User Exception Program Counter
   // 12'h041 = 12'b0000_0100_0001  uepc                                (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_uepc <=  '0;
      else if (exception.flag & (nxt_mode == 0))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         csr_uepc <= {exception.pc[RSZ-1:1], 1'b0};                     // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h041))                         // All modes can write to this CSR
         csr_uepc <= {csr_wr_data[RSZ-1:1], 1'b0};                      // Software settable - low bit is always 0
   end
   assign uepc  = {csr_uepc[PC_SZ-1:2], (ialign ? csr_uepc[1] : 1'b0), csr_uepc[0]}; // bit 1 is masked when read when ialign == 0 (32 bit alignment)

   // User Exception Cause.
   // 12'h042 = 12'b0000_0100_0010  ucause                              (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_ucause <=  'b0;
      else if (exception.flag & (nxt_mode == 0))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         csr_ucause <= exception.cause;                                 // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h042))
         csr_ucause <= csr_wr_data;                                     // Sotware settable
   end

   // User Exception Trap Value.                                        see riscv-privileged p. 38-39
   // 12'h043 = 12'b0000_0100_0011  utval                               (read-write)
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr_utval <=  'b0;
      else if (exception.flag & (nxt_mode == 0))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         csr_utval <= exception.cause;                                  // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h043))                         // all modes can write to this CSR
         csr_utval <= csr_wr_data;                                      // Sotware settable
   end

   // The UEIP field in mip provides user-mode external interrupts when the N extension for user-mode
   // interrupts is implemented. It is defined analogously to SEIP. riscv-privileged.pdf p 31
   // ---------------------- User Interrupt Pending bits ---------------------------
   // 12'h044 = 12'b0000_0100_0100  uip                                 (read-write)
   // see mip register with writes to address 12'h044
   always_ff @(posedge clk_in)
   begin
      // User interrupt pending.
      // 12'h044 = 12'b0000_0100_0100  uip                              (read-write)  user mode
      if (reset_in)
      begin
         ueip <= FALSE;
         utip <= FALSE;
         usip <= FALSE;
      end
      else if (csr_wr && (csr_addr == 12'h044))
      begin
         ueip <= csr_wr_data[8];                                        // set or clear UEIP
         utip <= csr_wr_data[4];                                        // set or clear UTIP
         usip <= csr_wr_data[0];                                        // set or clear USIP
      end
      else if (mode == 0)                                               // irq setting during user mode
      begin
         ueip <= ext_irq;
         utip <= time_irq;
         usip <= sw_irq;
      end
   end
   assign csr_uip = {20'b0,1'b0,1'b0,1'b0,ueip,1'b0,1'b0,1'b0,utip,1'b0,1'b0,1'b0,usip};

   `else  // no ext_N - no interrutps can occur
   assign upie = 1'b0;
   assign uie  = 1'b0;
   assign usip = FALSE;
   assign utip = FALSE;
   assign ueip = FALSE;                                                 // If the N extension for user-level interrupts is not implemented, UEIP and UEIE are hardwired to zero. see riscv-privileged p 59
   `endif   // ext_N

   `ifdef ext_F
   // ------------------------------ User Floating-Point CSRs
   // 12'h001 - 12'h003

   // !!!!!!!!!!!!!!!!!!!!!!!!! NEED TO ADD THESE !!!!!!!!!!!!!!!!!!!!!!!!!
   `endif   // ext_F

   // NOTE:  The following User Counter/Timers are located in file csr_rd_cntr_tmr.svh. These can be accessed by other modes (Machine, Supervisor)
   // 0xC00    URO       cycle         Cycle counter for RDCYCLE instruction
   // 0xC01    URO       time          Timer for RDTIME instruction
   // 0xC02    URO       instret       Instructions-retired counter for RDINSTRET instruction
   // 0xC03    URO       hpmcounter3   Performance-monitoring counter
   // 0xC04    URO       hpmcounter4   Performance-monitoring counter
   // ...
   // 0xC1F    URO       hpmcounter31  Performance-monitoring counter
   // 0xC80    URO       cycleh        Upper 32 bits of cycle, RV32I only
   // 0xC81    URO       timeh         Upper 32 bits of time, RV32I only
   // 0xC82    URO       instreth      Upper 32 bits of instret, RV32I only
   // 0xC83    URO       hpmcounter3h  Upper 32 bits of hpmcounter3, RV32I only
   // 0xC84    URO       hpmcounter4h  Upper 32 bits of hpmcounter4, RV32I only
   // ...
   // 0xC9F    URO       hpmcounter31h Upper 32 bits of hpmcounter31, RV32I only

   `else    // no ext_U - no user interrutps can occur
   assign upie = 1'b0;
   assign uie  = 1'b0;
   assign usip = FALSE;                                                 // USIP - User mode Software Interrupt Pending
   assign utip = FALSE;                                                 // UTIP - User mode Timer Interrupt Pending
   assign ueip = FALSE;                                                 // UEIP - User mode External Interrupt Pending

   `endif   // ext_U

