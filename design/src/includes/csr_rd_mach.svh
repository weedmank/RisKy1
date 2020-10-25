// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_rd_mach.svh
// Description   :  Contains CSR Read logic for Machine mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // see riscv-privileged.pdf p. 10-11
   // csr_avail = CSR register exists in this design
   // ================================================= Machine Mode =================================================
   // See p. 11 riscv-priviledged-v1.10

   // ------------------------------ Machine Trap Setup
   // Machine status register.
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
   if (csr_addr == 12'h300) begin csr_rdata = csr_mstatus;    csr_avail = TRUE; end

   // ISA and extensions
   // 12'h301 = 12'b0011_0000_0001  misa        (read-write)
   if (csr_addr == 12'h301) begin csr_rdata = csr_misa;       csr_avail = TRUE; end
   //  12'h301: csr_rdata = MISA;             // ISA and extensions

   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

   `ifdef ext_S // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // Machine exception delegation register.
      // 12'h302 = 12'b0011_0000_0010  medeleg     (read-write)
      if (csr_addr == 12'h302) begin csr_rdata = csr_medeleg;     csr_avail = TRUE; end

      // Machine interrupt delegation register.
      // 12'h303 = 12'b0011_0000_0011  mideleg     (read-write)
      if (csr_addr == 12'h303) begin csr_rdata = csr_mideleg;     csr_avail = TRUE; end
   `else // !ext_S
      `ifdef ext_U
         `ifdef ext_N
         // Machine exception delegation register.
         // 12'h302 = 12'b0011_0000_0010  medeleg     (read-write)
         if (csr_addr == 12'h302) begin csr_rdata = csr_medeleg;     csr_avail = TRUE; end

         // Machine interrupt delegation register.
         // 12'h303 = 12'b0011_0000_0011  mideleg     (read-write)
         if (csr_addr == 12'h303) begin csr_rdata = csr_mideleg;     csr_avail = TRUE; end
         `endif
      `endif
   `endif

   // Machine interrupt-enable register.
   // 12'h304 = 12'b0011_0000_0100  mie         (read-write)
   if (csr_addr == 12'h304) begin csr_rdata = csr_mie;        csr_avail = TRUE; end

   // Machine trap-handler base address.
   // 12'h305 = 12'b0011_0000_0101  mtvec       (read-write)
   if (csr_addr == 12'h305) begin csr_rdata = csr_mtvec;      csr_avail = TRUE; end

   // Note: p 3 table 1.2 riscv-privileged.pdf  Notice that if U mode does not exist then the only valid mode is M.
   // If only M mode then mcounteren is never used and can be eliminated since it's not used by any other logic. See csr_rd_cntr_tmr.svh
   // Number of levels Supported Modes Intended Usage
   // 1 M Simple embedded systems
   // 2 M, U Secure embedded systems
   // 3 M, S, U Systems running Unix-like operating systems
   //
   // The following ifdef & endif lines can be removed if you want to keep this register when only an M-mode machine
   `ifdef ext_U
   // Machine counter enable.
   // 12'h306 = 12'b0011_0000_0110  mcounteren  (read-write)
   if (csr_addr == 12'h306) begin csr_rdata = csr_mcounteren; csr_avail = TRUE; end      // see csr_rd_cntr_tmr.svh
   `endif

   // ------------------------------ Machine Counter Setup
   // 12'h320 = 12'b0011_0010_0000  machine counter inhibit    (read-write)
   if (csr_addr == 12'h320) begin csr_rdata = csr_mcountinhibit; csr_avail = TRUE; end

   // NUM_MHPM is user definable in cpu_params.  This allows the user to decide how many of these they want.
   // Machine performance-monitoring event selectors mhpmevent3 - mhpmevent31
   // "All counters should be implemented, but a legal implementation is to hard-wire both the counter and its corresponding event selector to 0." riscv-privileged p 33
   // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31        (read-write)
   if (csr_addr inside {[12'h323 : 12'h33F]}) csr_avail = TRUE;
   `ifndef use_MHPM
      csr_rdata = 0;
   `else
   if (NUM_MHPM >  0) csr_rdata = (csr_addr == 12'h323) ? csr_mhpmevent[ 0] : 0;  // mhpmevent3
   if (NUM_MHPM >  1) csr_rdata = (csr_addr == 12'h324) ? csr_mhpmevent[ 1] : 0;
   if (NUM_MHPM >  2) csr_rdata = (csr_addr == 12'h325) ? csr_mhpmevent[ 2] : 0;
   if (NUM_MHPM >  3) csr_rdata = (csr_addr == 12'h326) ? csr_mhpmevent[ 3] : 0;
   if (NUM_MHPM >  4) csr_rdata = (csr_addr == 12'h327) ? csr_mhpmevent[ 4] : 0;
   if (NUM_MHPM >  5) csr_rdata = (csr_addr == 12'h328) ? csr_mhpmevent[ 5] : 0;
   if (NUM_MHPM >  6) csr_rdata = (csr_addr == 12'h329) ? csr_mhpmevent[ 6] : 0;
   if (NUM_MHPM >  7) csr_rdata = (csr_addr == 12'h32A) ? csr_mhpmevent[ 7] : 0;
   if (NUM_MHPM >  8) csr_rdata = (csr_addr == 12'h32B) ? csr_mhpmevent[ 8] : 0;
   if (NUM_MHPM >  9) csr_rdata = (csr_addr == 12'h32C) ? csr_mhpmevent[ 9] : 0;
   if (NUM_MHPM > 10) csr_rdata = (csr_addr == 12'h32D) ? csr_mhpmevent[10] : 0;
   if (NUM_MHPM > 11) csr_rdata = (csr_addr == 12'h32E) ? csr_mhpmevent[11] : 0;
   if (NUM_MHPM > 12) csr_rdata = (csr_addr == 12'h32F) ? csr_mhpmevent[12] : 0;
   if (NUM_MHPM > 13) csr_rdata = (csr_addr == 12'h330) ? csr_mhpmevent[13] : 0;
   if (NUM_MHPM > 14) csr_rdata = (csr_addr == 12'h331) ? csr_mhpmevent[14] : 0;
   if (NUM_MHPM > 15) csr_rdata = (csr_addr == 12'h332) ? csr_mhpmevent[15] : 0;
   if (NUM_MHPM > 16) csr_rdata = (csr_addr == 12'h333) ? csr_mhpmevent[16] : 0;
   if (NUM_MHPM > 17) csr_rdata = (csr_addr == 12'h334) ? csr_mhpmevent[17] : 0;
   if (NUM_MHPM > 18) csr_rdata = (csr_addr == 12'h335) ? csr_mhpmevent[18] : 0;
   if (NUM_MHPM > 19) csr_rdata = (csr_addr == 12'h336) ? csr_mhpmevent[19] : 0;
   if (NUM_MHPM > 20) csr_rdata = (csr_addr == 12'h337) ? csr_mhpmevent[20] : 0;
   if (NUM_MHPM > 21) csr_rdata = (csr_addr == 12'h338) ? csr_mhpmevent[21] : 0;
   if (NUM_MHPM > 22) csr_rdata = (csr_addr == 12'h339) ? csr_mhpmevent[22] : 0;
   if (NUM_MHPM > 23) csr_rdata = (csr_addr == 12'h33A) ? csr_mhpmevent[23] : 0;
   if (NUM_MHPM > 24) csr_rdata = (csr_addr == 12'h33B) ? csr_mhpmevent[24] : 0;
   if (NUM_MHPM > 25) csr_rdata = (csr_addr == 12'h33C) ? csr_mhpmevent[25] : 0;
   if (NUM_MHPM > 26) csr_rdata = (csr_addr == 12'h33D) ? csr_mhpmevent[26] : 0;
   if (NUM_MHPM > 27) csr_rdata = (csr_addr == 12'h33E) ? csr_mhpmevent[27] : 0;
   if (NUM_MHPM > 28) csr_rdata = (csr_addr == 12'h33F) ? csr_mhpmevent[28] : 0;  // mhpmevent31
   `endif
   
   // ------------------------------ Machine Trap Handling
   // Scratch register for machine trap handlers.
   // 12'h340 = 12'b0011_0100_0000  mscratch    (read-write)
   if (csr_addr == 12'h340) begin csr_rdata = csr_mscratch;   csr_avail = TRUE; end

   // Machine exception program counter.
   // 12'h341 = 12'b0011_0100_0001  mepc        (read-write)
   if (csr_addr == 12'h341) begin csr_rdata = csr_mepc;       csr_avail = TRUE; end

   // Machine trap cause.
   // 12'h342 = 12'b0011_0100_0010  mcause      (read-write)
   if (csr_addr == 12'h342) begin csr_rdata = csr_mcause;     csr_avail = TRUE; end

   // Machine bad address or instruction.
   // 12'h343 = 12'b0011_0100_0011  mtval       (read-write)
   if (csr_addr == 12'h343) begin csr_rdata = csr_mtval;      csr_avail = TRUE; end

   // Machine interrupt pending.
   // bits (USIP-0, SSIP-1, UTIP-4, STIP-5, UEIP-8, SEIP-9 are writable - all others read only. p.29
   // 12'h344 = 12'b0011_0100_0100  mip         (read-write)  machine mode
   if (csr_addr == 12'h344) begin csr_rdata = csr_mip;        csr_avail = TRUE; end

   // ------------------------------ Machine Protection and Translation
   `ifdef USE_PMPCFG
      if (csr_addr == 12'h3A0) begin csr_rdata = csr_pmpcfg0; csr_avail = TRUE; end   // pmpcfg0
      if (csr_addr == 12'h3A1) begin csr_rdata = csr_pmpcfg1; csr_avail = TRUE; end   // pmpcfg1
      if (csr_addr == 12'h3A2) begin csr_rdata = csr_pmpcfg2; csr_avail = TRUE; end   // pmpcfg2
      if (csr_addr == 12'h3A3) begin csr_rdata = csr_pmpcfg3; csr_avail = TRUE; end   // pmpcfg3
   `endif

   `ifdef PMP_ADDR0  if (csr_addr == 12'h3B0) begin csr_rdata = csr_pmpaddr0;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR1  if (csr_addr == 12'h3B1) begin csr_rdata = csr_pmpaddr1;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR2  if (csr_addr == 12'h3B2) begin csr_rdata = csr_pmpaddr2;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR3  if (csr_addr == 12'h3B3) begin csr_rdata = csr_pmpaddr3;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR4  if (csr_addr == 12'h3B4) begin csr_rdata = csr_pmpaddr4;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR5  if (csr_addr == 12'h3B5) begin csr_rdata = csr_pmpaddr5;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR6  if (csr_addr == 12'h3B6) begin csr_rdata = csr_pmpaddr6;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR7  if (csr_addr == 12'h3B7) begin csr_rdata = csr_pmpaddr7;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR8  if (csr_addr == 12'h3B8) begin csr_rdata = csr_pmpaddr8;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR9  if (csr_addr == 12'h3B9) begin csr_rdata = csr_pmpaddr9;   csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR10 if (csr_addr == 12'h3BA) begin csr_rdata = csr_pmpaddr10;  csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR11 if (csr_addr == 12'h3BB) begin csr_rdata = csr_pmpaddr11;  csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR12 if (csr_addr == 12'h3BC) begin csr_rdata = csr_pmpaddr12;  csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR13 if (csr_addr == 12'h3BD) begin csr_rdata = csr_pmpaddr13;  csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR14 if (csr_addr == 12'h3BE) begin csr_rdata = csr_pmpaddr14;  csr_avail = TRUE; end   `endif
   `ifdef PMP_ADDR15 if (csr_addr == 12'h3BF) begin csr_rdata = csr_pmpaddr15;  csr_avail = TRUE; end   `endif

   `ifdef add_DM
   // ------------------------------ Debug/Trace Registers (shared with Debug Mode)
   // 12'h7A0 - 12'h7AF
   if (csr_addr == 12'h7A0) begin csr_rdata = csr_tselect;       csr_avail = TRUE; end
   if (csr_addr == 12'h7A1) begin csr_rdata = csr_tdata1;        csr_avail = TRUE; end
   if (csr_addr == 12'h7A2) begin csr_rdata = csr_tdata2;        csr_avail = TRUE; end
   if (csr_addr == 12'h7A3) begin csr_rdata = csr_tdata3;        csr_avail = TRUE; end

   // ------------------------------ Debug Mode Registers
   // "implementations should raise illegal instruction exceptions on machine-mode access to the latter set of registers [12'h7B0 - 12'h7BF]." riscv-privileged.pdf p 6
   // 12'h7B0 - 12'h7BF
   if (csr_addr == 12'h7b0) begin csr_rdata = csr_dcsr;          csr_avail = FALSE; end
   if (csr_addr == 12'h7b1) begin csr_rdata = csr_dpc;           csr_avail = FALSE; end
   if (csr_addr == 12'h7b2) begin csr_rdata = csr_dscratch0;     csr_avail = FALSE; end
   if (csr_addr == 12'h7b3) begin csr_rdata = csr_dscratch1;     csr_avail = FALSE; end
   `endif // add_DM

   // ------------------------------ Machine Counter/Timers
   // lower 32 bits of counters. see 'hB80, 'hB81, 'hB82
   if (csr_addr == 12'hB00) begin csr_rdata = csr_mcycle_lo;     csr_avail = TRUE; end
   if (csr_addr == 12'hB01) begin csr_rdata = mtime[RSZ-1:0];    csr_avail = TRUE; end
   if (csr_addr == 12'hB02) begin csr_rdata = csr_minstret_lo;   csr_avail = TRUE; end

   // 12'hB03 = 12'b1011_0000_0011  hpmcounter3 (lower 32 bits)
   // "All counters should be implemented, but a legal implementation is to hard-wire both the counter and its corresponding event selector to 0." riscv-privileged p 33
   if (csr_addr inside {[12'hB03 : 12'hB1F]}) csr_avail = TRUE;
   `ifndef use_MHPM
      csr_rdata = 0;
   `else
   if (NUM_MHPM >  0) csr_rdata = (csr_addr == 12'hB03) ? csr_mhpmcounter_lo[ 0] : 0;   // hpmcounter3 lo
   if (NUM_MHPM >  1) csr_rdata = (csr_addr == 12'hB04) ? csr_mhpmcounter_lo[ 1] : 0;
   if (NUM_MHPM >  2) csr_rdata = (csr_addr == 12'hB05) ? csr_mhpmcounter_lo[ 2] : 0;
   if (NUM_MHPM >  3) csr_rdata = (csr_addr == 12'hB06) ? csr_mhpmcounter_lo[ 3] : 0;
   if (NUM_MHPM >  4) csr_rdata = (csr_addr == 12'hB07) ? csr_mhpmcounter_lo[ 4] : 0;
   if (NUM_MHPM >  5) csr_rdata = (csr_addr == 12'hB08) ? csr_mhpmcounter_lo[ 5] : 0;
   if (NUM_MHPM >  6) csr_rdata = (csr_addr == 12'hB09) ? csr_mhpmcounter_lo[ 6] : 0;
   if (NUM_MHPM >  7) csr_rdata = (csr_addr == 12'hB0A) ? csr_mhpmcounter_lo[ 7] : 0;
   if (NUM_MHPM >  8) csr_rdata = (csr_addr == 12'hB0B) ? csr_mhpmcounter_lo[ 8] : 0;
   if (NUM_MHPM >  9) csr_rdata = (csr_addr == 12'hB0C) ? csr_mhpmcounter_lo[ 9] : 0;
   if (NUM_MHPM > 10) csr_rdata = (csr_addr == 12'hB0D) ? csr_mhpmcounter_lo[10] : 0;
   if (NUM_MHPM > 11) csr_rdata = (csr_addr == 12'hB0E) ? csr_mhpmcounter_lo[11] : 0;
   if (NUM_MHPM > 12) csr_rdata = (csr_addr == 12'hB0F) ? csr_mhpmcounter_lo[12] : 0;
   if (NUM_MHPM > 13) csr_rdata = (csr_addr == 12'hB10) ? csr_mhpmcounter_lo[13] : 0;
   if (NUM_MHPM > 14) csr_rdata = (csr_addr == 12'hB11) ? csr_mhpmcounter_lo[14] : 0;
   if (NUM_MHPM > 15) csr_rdata = (csr_addr == 12'hB12) ? csr_mhpmcounter_lo[15] : 0;
   if (NUM_MHPM > 16) csr_rdata = (csr_addr == 12'hB13) ? csr_mhpmcounter_lo[16] : 0;
   if (NUM_MHPM > 17) csr_rdata = (csr_addr == 12'hB14) ? csr_mhpmcounter_lo[17] : 0;
   if (NUM_MHPM > 18) csr_rdata = (csr_addr == 12'hB15) ? csr_mhpmcounter_lo[18] : 0;
   if (NUM_MHPM > 19) csr_rdata = (csr_addr == 12'hB16) ? csr_mhpmcounter_lo[19] : 0;
   if (NUM_MHPM > 20) csr_rdata = (csr_addr == 12'hB17) ? csr_mhpmcounter_lo[20] : 0;
   if (NUM_MHPM > 21) csr_rdata = (csr_addr == 12'hB18) ? csr_mhpmcounter_lo[21] : 0;
   if (NUM_MHPM > 22) csr_rdata = (csr_addr == 12'hB19) ? csr_mhpmcounter_lo[22] : 0;
   if (NUM_MHPM > 23) csr_rdata = (csr_addr == 12'hB1A) ? csr_mhpmcounter_lo[23] : 0;
   if (NUM_MHPM > 24) csr_rdata = (csr_addr == 12'hB1B) ? csr_mhpmcounter_lo[24] : 0;
   if (NUM_MHPM > 25) csr_rdata = (csr_addr == 12'hB1C) ? csr_mhpmcounter_lo[25] : 0;
   if (NUM_MHPM > 26) csr_rdata = (csr_addr == 12'hB1D) ? csr_mhpmcounter_lo[26] : 0;
   if (NUM_MHPM > 27) csr_rdata = (csr_addr == 12'hB1E) ? csr_mhpmcounter_lo[27] : 0;
   if (NUM_MHPM > 28) csr_rdata = (csr_addr == 12'hB1F) ? csr_mhpmcounter_lo[28] : 0;   // hpmcounter31 lo
   `endif

   // ------------------------------ Machine Counter/Timers
   // upper 32 bits of counters
   if (csr_addr == 12'hB80) begin csr_rdata = csr_mcycle_hi;       csr_avail = TRUE; end
   if (csr_addr == 12'hB81) begin csr_rdata = mtime[2*RSZ-1:RSZ];  csr_avail = TRUE; end
   if (csr_addr == 12'hB82) begin csr_rdata = csr_minstret_hi;     csr_avail = TRUE; end

   // 12'hB83 = 12'b1011_0000_0011  hpmcounter3 (upper 32 bits)
   // "All counters should be implemented, but a legal implementation is to hard-wire both the counter and its corresponding event selector to 0." riscv-privileged p 33
   if (csr_addr inside {[12'hB83 : 12'hB9F]}) csr_avail = TRUE;
   `ifndef use_MHPM
      csr_rdata = 0;
   `else
   if (NUM_MHPM >  0) csr_rdata = (csr_addr == 12'hB83) ? csr_mhpmcounter_hi[ 0] : 0;   // hpmcounter3 hi
   if (NUM_MHPM >  1) csr_rdata = (csr_addr == 12'hB84) ? csr_mhpmcounter_hi[ 1] : 0;  
   if (NUM_MHPM >  2) csr_rdata = (csr_addr == 12'hB85) ? csr_mhpmcounter_hi[ 2] : 0;  
   if (NUM_MHPM >  3) csr_rdata = (csr_addr == 12'hB86) ? csr_mhpmcounter_hi[ 3] : 0;  
   if (NUM_MHPM >  4) csr_rdata = (csr_addr == 12'hB87) ? csr_mhpmcounter_hi[ 4] : 0;  
   if (NUM_MHPM >  5) csr_rdata = (csr_addr == 12'hB88) ? csr_mhpmcounter_hi[ 5] : 0;  
   if (NUM_MHPM >  6) csr_rdata = (csr_addr == 12'hB89) ? csr_mhpmcounter_hi[ 6] : 0;  
   if (NUM_MHPM >  7) csr_rdata = (csr_addr == 12'hB8A) ? csr_mhpmcounter_hi[ 7] : 0;  
   if (NUM_MHPM >  8) csr_rdata = (csr_addr == 12'hB8B) ? csr_mhpmcounter_hi[ 8] : 0;  
   if (NUM_MHPM >  9) csr_rdata = (csr_addr == 12'hB8C) ? csr_mhpmcounter_hi[ 9] : 0;  
   if (NUM_MHPM > 10) csr_rdata = (csr_addr == 12'hB8D) ? csr_mhpmcounter_hi[10] : 0;  
   if (NUM_MHPM > 11) csr_rdata = (csr_addr == 12'hB8E) ? csr_mhpmcounter_hi[11] : 0;  
   if (NUM_MHPM > 12) csr_rdata = (csr_addr == 12'hB8F) ? csr_mhpmcounter_hi[12] : 0;  
   if (NUM_MHPM > 13) csr_rdata = (csr_addr == 12'hB90) ? csr_mhpmcounter_hi[13] : 0;  
   if (NUM_MHPM > 14) csr_rdata = (csr_addr == 12'hB91) ? csr_mhpmcounter_hi[14] : 0;  
   if (NUM_MHPM > 15) csr_rdata = (csr_addr == 12'hB92) ? csr_mhpmcounter_hi[15] : 0;  
   if (NUM_MHPM > 16) csr_rdata = (csr_addr == 12'hB93) ? csr_mhpmcounter_hi[16] : 0;  
   if (NUM_MHPM > 17) csr_rdata = (csr_addr == 12'hB94) ? csr_mhpmcounter_hi[17] : 0;  
   if (NUM_MHPM > 18) csr_rdata = (csr_addr == 12'hB95) ? csr_mhpmcounter_hi[18] : 0;  
   if (NUM_MHPM > 19) csr_rdata = (csr_addr == 12'hB96) ? csr_mhpmcounter_hi[19] : 0;  
   if (NUM_MHPM > 20) csr_rdata = (csr_addr == 12'hB97) ? csr_mhpmcounter_hi[20] : 0;  
   if (NUM_MHPM > 21) csr_rdata = (csr_addr == 12'hB98) ? csr_mhpmcounter_hi[21] : 0;  
   if (NUM_MHPM > 22) csr_rdata = (csr_addr == 12'hB99) ? csr_mhpmcounter_hi[22] : 0;  
   if (NUM_MHPM > 23) csr_rdata = (csr_addr == 12'hB9A) ? csr_mhpmcounter_hi[23] : 0;  
   if (NUM_MHPM > 24) csr_rdata = (csr_addr == 12'hB9B) ? csr_mhpmcounter_hi[24] : 0;  
   if (NUM_MHPM > 25) csr_rdata = (csr_addr == 12'hB9C) ? csr_mhpmcounter_hi[25] : 0;  
   if (NUM_MHPM > 26) csr_rdata = (csr_addr == 12'hB9D) ? csr_mhpmcounter_hi[26] : 0;  
   if (NUM_MHPM > 27) csr_rdata = (csr_addr == 12'hB9E) ? csr_mhpmcounter_hi[27] : 0;  
   if (NUM_MHPM > 28) csr_rdata = (csr_addr == 12'hB9F) ? csr_mhpmcounter_hi[28] : 0;   // hpmcounter31 hi
   `endif
   
   // ------------------------------ Machine Information Registers
   // Vendor ID
   // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
   if (csr_addr == 12'hF11) begin csr_rdata = csr_mvendorid;  csr_avail = TRUE; end

   // Architecture ID
   // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
   if (csr_addr == 12'hF12) begin csr_rdata = csr_marchid;    csr_avail = TRUE; end

   // Implementation ID
   // 12'hF13 = 12'b1111_0001_0011  mempid      (read-only)
   if (csr_addr == 12'hF13) begin csr_rdata = csr_mimpid;     csr_avail = TRUE; end

   // Hardware Thread ID
   // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
   if (csr_addr == 12'hF14) begin csr_rdata = csr_mhartid;    csr_avail = TRUE; end
