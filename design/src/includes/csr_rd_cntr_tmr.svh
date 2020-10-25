// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_rd_cntr_tmr.svh
// Description   :  Contains CSR Read logic for counters and timers for all modes.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // Note: p 3 table 1.2 riscv-privileged.pdf  Notice that if U mode does not exist then the only valid mode is M.
   // If only M mode then mcounteren is never used and can be eliminated if desired
   // Number of levels Supported Modes Intended Usage
   // 1 M Simple embedded systems
   // 2 M, U Secure embedded systems
   // 3 M, S, U Systems running Unix-like operating systems
   //

   // see p 34 riscv-privileged.pdf
   av = FALSE;
   `ifdef M_MODE_ONLY
      av = TRUE;
   `else
      if (mode == 3)                   // Machine mode
         av = TRUE;
      else if (mode == 1)              // Supervisor mode
         av = csr_mcounteren[ndx];
      else if (mode == 0)              // User mode
      `ifdef ext_S
         av = csr_scounteren[ndx];
      `else
         av = csr_mcounteren[ndx];
      `endif
   `endif

   // csr_avail = CSR register exists in this design
   // ------------------------------ Counter/Timers (12'hCxx = Read Only - readable by Machine, Supervisor and User modes)

   // Cycle counter for RDCYCLE instruction
   // 12'hC00 = 12'b1100_0000_0000  cycle          (read-only)
   if (csr_addr == 12'hC00)
   begin
      csr_avail = av;
      if (csr_avail) csr_rdata = csr_mcycle_lo;
   end

   // 12'hC01 = 12'b1100_0000_0001  time           (read-only)
   if (csr_addr == 12'hC01)
   begin
      csr_avail = av;
      if (csr_avail) csr_rdata = mtime[RSZ-1:0];
   end

   // Number of Instructions Retired
   // 12'hC02 = 12'b1100_0000_0010  instret        (read-only)
   if (csr_addr == 12'hC02)
   begin
      csr_avail = av;
      if (csr_avail) csr_rdata = csr_minstret_lo;
   end


   // 12'hC03 = 12'b1100_0000_0011  hpmcounter3 lo (read-only)  user mode
   if (csr_addr inside {[12'hC03 : 12'hC1F]})
      csr_avail = av;
   `ifndef use_MHPM
      csr_rdata = 0;
   `else
   if (NUM_MHPM >  0) if (csr_addr == 12'hC03) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 0] : 0;   // hpmcounter3 lo
   if (NUM_MHPM >  1) if (csr_addr == 12'hC04) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 1] : 0;
   if (NUM_MHPM >  2) if (csr_addr == 12'hC05) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 2] : 0;
   if (NUM_MHPM >  3) if (csr_addr == 12'hC06) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 3] : 0;
   if (NUM_MHPM >  4) if (csr_addr == 12'hC07) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 4] : 0;
   if (NUM_MHPM >  5) if (csr_addr == 12'hC08) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 5] : 0;
   if (NUM_MHPM >  6) if (csr_addr == 12'hC09) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 6] : 0;
   if (NUM_MHPM >  7) if (csr_addr == 12'hC0A) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 7] : 0;
   if (NUM_MHPM >  8) if (csr_addr == 12'hC0B) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 8] : 0;
   if (NUM_MHPM >  9) if (csr_addr == 12'hC0C) csr_rdata = csr_avail ? csr_mhpmcounter_lo[ 9] : 0;
   if (NUM_MHPM > 10) if (csr_addr == 12'hC0D) csr_rdata = csr_avail ? csr_mhpmcounter_lo[10] : 0;
   if (NUM_MHPM > 11) if (csr_addr == 12'hC0E) csr_rdata = csr_avail ? csr_mhpmcounter_lo[11] : 0;
   if (NUM_MHPM > 12) if (csr_addr == 12'hC0F) csr_rdata = csr_avail ? csr_mhpmcounter_lo[12] : 0;
   if (NUM_MHPM > 13) if (csr_addr == 12'hC10) csr_rdata = csr_avail ? csr_mhpmcounter_lo[13] : 0;
   if (NUM_MHPM > 14) if (csr_addr == 12'hC11) csr_rdata = csr_avail ? csr_mhpmcounter_lo[14] : 0;
   if (NUM_MHPM > 15) if (csr_addr == 12'hC12) csr_rdata = csr_avail ? csr_mhpmcounter_lo[15] : 0;
   if (NUM_MHPM > 16) if (csr_addr == 12'hC13) csr_rdata = csr_avail ? csr_mhpmcounter_lo[16] : 0;
   if (NUM_MHPM > 17) if (csr_addr == 12'hC14) csr_rdata = csr_avail ? csr_mhpmcounter_lo[17] : 0;
   if (NUM_MHPM > 18) if (csr_addr == 12'hC15) csr_rdata = csr_avail ? csr_mhpmcounter_lo[18] : 0;
   if (NUM_MHPM > 19) if (csr_addr == 12'hC16) csr_rdata = csr_avail ? csr_mhpmcounter_lo[19] : 0;
   if (NUM_MHPM > 20) if (csr_addr == 12'hC17) csr_rdata = csr_avail ? csr_mhpmcounter_lo[20] : 0;
   if (NUM_MHPM > 21) if (csr_addr == 12'hC18) csr_rdata = csr_avail ? csr_mhpmcounter_lo[21] : 0;
   if (NUM_MHPM > 22) if (csr_addr == 12'hC19) csr_rdata = csr_avail ? csr_mhpmcounter_lo[22] : 0;
   if (NUM_MHPM > 23) if (csr_addr == 12'hC1A) csr_rdata = csr_avail ? csr_mhpmcounter_lo[23] : 0;
   if (NUM_MHPM > 24) if (csr_addr == 12'hC1B) csr_rdata = csr_avail ? csr_mhpmcounter_lo[24] : 0;
   if (NUM_MHPM > 25) if (csr_addr == 12'hC1C) csr_rdata = csr_avail ? csr_mhpmcounter_lo[25] : 0;
   if (NUM_MHPM > 26) if (csr_addr == 12'hC1D) csr_rdata = csr_avail ? csr_mhpmcounter_lo[26] : 0;
   if (NUM_MHPM > 27) if (csr_addr == 12'hC1E) csr_rdata = csr_avail ? csr_mhpmcounter_lo[27] : 0;
   if (NUM_MHPM > 28) if (csr_addr == 12'hC1F) csr_rdata = csr_avail ? csr_mhpmcounter_lo[28] : 0;  // hpmcounter31 lo
   `endif

   // Upper 32 bits of cycle, RV32I only.
   // 12'hC80 = 12'b1100_1000_0000  mcycle hi      (read-only)
   if (csr_addr == 12'hC80)
   begin
      csr_avail = av;
      csr_rdata = csr_mcycle_hi;
   end

   // Upper 32 bits of time, RV32I only.  see p 30 and CLINT.sv
   // 12'hC81 = 12'b1100_1000_0001  time hi        (read-only)
   if (csr_addr == 12'hC81)
   begin
      csr_avail = av;
      csr_rdata = mtime[RSZ*2-1:RSZ];
   end

   // Upper 32 bits of instret, RV32I only.
   // 12'hC82 = 12'b1100_1000_0010  uinstret hi    (read-only)
   if (csr_addr == 12'hC82)
   begin
      csr_avail = av;
      csr_rdata = csr_minstret_hi;
   end

   // 12'hC83 = 12'b1100_1000_0011  hpmcounter3 hi (read-only)  user mode
   if (csr_addr inside {[12'hC83 : 12'hC9F]})
      csr_avail = av;
   `ifndef use_MHPM
      csr_rdata = 0;
   `else
   if (NUM_MHPM >  0) if (csr_addr == 12'hC83) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 0] : 0;  // hpmcounter3 hi
   if (NUM_MHPM >  1) if (csr_addr == 12'hC84) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 1] : 0;
   if (NUM_MHPM >  2) if (csr_addr == 12'hC85) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 2] : 0;
   if (NUM_MHPM >  3) if (csr_addr == 12'hC86) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 3] : 0;
   if (NUM_MHPM >  4) if (csr_addr == 12'hC87) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 4] : 0;
   if (NUM_MHPM >  5) if (csr_addr == 12'hC88) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 5] : 0;
   if (NUM_MHPM >  6) if (csr_addr == 12'hC89) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 6] : 0;
   if (NUM_MHPM >  7) if (csr_addr == 12'hC8A) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 7] : 0;
   if (NUM_MHPM >  8) if (csr_addr == 12'hC8B) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 8] : 0;
   if (NUM_MHPM >  9) if (csr_addr == 12'hC8C) csr_rdata = csr_avail ? csr_mhpmcounter_hi[ 9] : 0;
   if (NUM_MHPM > 10) if (csr_addr == 12'hC8D) csr_rdata = csr_avail ? csr_mhpmcounter_hi[10] : 0;
   if (NUM_MHPM > 11) if (csr_addr == 12'hC8E) csr_rdata = csr_avail ? csr_mhpmcounter_hi[11] : 0;
   if (NUM_MHPM > 12) if (csr_addr == 12'hC8F) csr_rdata = csr_avail ? csr_mhpmcounter_hi[12] : 0;
   if (NUM_MHPM > 13) if (csr_addr == 12'hC90) csr_rdata = csr_avail ? csr_mhpmcounter_hi[13] : 0;
   if (NUM_MHPM > 14) if (csr_addr == 12'hC91) csr_rdata = csr_avail ? csr_mhpmcounter_hi[14] : 0;
   if (NUM_MHPM > 15) if (csr_addr == 12'hC92) csr_rdata = csr_avail ? csr_mhpmcounter_hi[15] : 0;
   if (NUM_MHPM > 16) if (csr_addr == 12'hC93) csr_rdata = csr_avail ? csr_mhpmcounter_hi[16] : 0;
   if (NUM_MHPM > 17) if (csr_addr == 12'hC94) csr_rdata = csr_avail ? csr_mhpmcounter_hi[17] : 0;
   if (NUM_MHPM > 18) if (csr_addr == 12'hC95) csr_rdata = csr_avail ? csr_mhpmcounter_hi[18] : 0;
   if (NUM_MHPM > 19) if (csr_addr == 12'hC96) csr_rdata = csr_avail ? csr_mhpmcounter_hi[19] : 0;
   if (NUM_MHPM > 20) if (csr_addr == 12'hC97) csr_rdata = csr_avail ? csr_mhpmcounter_hi[20] : 0;
   if (NUM_MHPM > 21) if (csr_addr == 12'hC98) csr_rdata = csr_avail ? csr_mhpmcounter_hi[21] : 0;
   if (NUM_MHPM > 22) if (csr_addr == 12'hC99) csr_rdata = csr_avail ? csr_mhpmcounter_hi[22] : 0;
   if (NUM_MHPM > 23) if (csr_addr == 12'hC9A) csr_rdata = csr_avail ? csr_mhpmcounter_hi[23] : 0;
   if (NUM_MHPM > 24) if (csr_addr == 12'hC9B) csr_rdata = csr_avail ? csr_mhpmcounter_hi[24] : 0;
   if (NUM_MHPM > 25) if (csr_addr == 12'hC9C) csr_rdata = csr_avail ? csr_mhpmcounter_hi[25] : 0;
   if (NUM_MHPM > 26) if (csr_addr == 12'hC9D) csr_rdata = csr_avail ? csr_mhpmcounter_hi[26] : 0;
   if (NUM_MHPM > 27) if (csr_addr == 12'hC9E) csr_rdata = csr_avail ? csr_mhpmcounter_hi[27] : 0;
   if (NUM_MHPM > 28) if (csr_addr == 12'hC9F) csr_rdata = csr_avail ? csr_mhpmcounter_hi[28] : 0;  // hpmcounter31 hi
   `endif
