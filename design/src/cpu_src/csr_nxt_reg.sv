// ----------------------------------------------------------------------------------------------------
// Copyright (c) 2020 Kirk Weedman www.hdlexpress.com
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_nxt_reg.sv - CSRs related to Machine mode
// Description   :  Contains only combinatorial logic to determine what will be the next value to write
//               :  into a CSR[] regsiter on the next clock cycle.  Results used by logic in csr.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_nxt_reg
(
   input    logic                reset_in,

   `ifdef ext_N
   input    logic                ext_irq,
   input    logic                timer_irq,
   `endif

   input    logic         [11:0] csr_addr,
   input    logic                csr_wr,
   input    logic      [RSZ-1:0] csr_wr_data,

   input    logic                tot_retired,      // In this design, at most, 1 instruction can retire per clock cycle
   input    var EXCEPTION        exception,
   input    var logic            hpm_events[0:23], // 24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)

   input    logic          [1:0] mode,
   input    logic          [1:0] nxt_mode,

//   `ifdef ext_U
//   input    logic                uret,
//   UCSR_REG_intf.slave           ucsr,             // all of the User mode Control & Status Registers
//   UCSR_REG_intf.master          nxt_ucsr,         // all of the next User mode Control & Status Registers
//   `endif
//
//   `ifdef ext_S
//   input    logic                sret,
//   SCSR_REG_intf.slave           scsr,             // all of the Supervisor mode Control & Status Registers
//   SCSR_REG_intf.master          nxt_scsr,         // all of the next Supervisor mode Control & Status Registers
//   `endif
//
//   input    logic                mret,
//   MCSR_REG_intf.slave           mcsr,             // all of the Machine mode Control & Status Registers
//   MCSR_REG_intf.master          nxt_mcsr          // all of the next Machine mode Control & Status Registers

   `ifdef ext_U
   input    logic                uret,
   input    var UCSR             ucsr,             // all of the User mode Control & Status Registers
   output   UCSR                 nxt_ucsr,         // all of the next User mode Control & Status Registers
   `endif

   `ifdef ext_S
   input    logic                sret,
   input    var SCSR             scsr,             // all of the Supervisor mode Control & Status Registers
   output   SCSR                 nxt_scsr,         // all of the next Supervisor mode Control & Status Registers
   `endif

   input    logic                mret,
   input var MCSR  mcsr,                           // all of the Machine mode Control & Status Registers
   output MCSR  nxt_mcsr                           // all of the next Machine mode Control & Status Registers
);

   logic sd, tsr, tw, tvm, mxr, sum, mprv;
   logic [1:0] xs, fs, mpp;
   logic mpie, mie;
   logic spp, spie, sie;
   logic upie, uie;

   //!!!!!!!!!!!!!!!!!!!! Mstatus Bits To Be Updated As Needed !!!!!!!!!!!!!!!!!!!!
   assign sd      = 1'b0;
   assign tsr     = 1'b0;
   assign tw      = 1'b0;
   assign tvm     = 1'b0;
   assign mxr     = 1'b0;
   assign sum     = 1'b0;
   assign mprv    = 1'b0;
   assign xs      = 2'b0;
   assign fs      = 2'b0;

   logic  [1:0] nxt_mpp;
   logic        nxt_mpie, nxt_mie;


   // ------------------------------ Machine Status Register
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)   p. 56 riscv-privileged
   always_comb // must be equivalent logic in csr_mach_wr_reg.sv
   begin
      if (reset_in)
         nxt_mpp  = 2'b11;                                              // mpp = Machine Prevous Privileged mode
      else if (exception.flag & (nxt_mode == M_MODE))                   // holds the previous privilege mode
         nxt_mpp  = mode;                                               // When a trap is taken from privilege mode y into privilege mode x, ... and xPP is set to y.
      else if (mret)
         `ifdef ext_U
         nxt_mpp  = 2'b00;                                              // "and xPP is set to U (or M if user-mode is not supported)." p. 21 riscv-privileged.pdf
         `else
         nxt_mpp  = 2'b11;
         `endif
      else if (csr_wr & (csr_addr == 12'h300) & (mode == M_MODE))
         nxt_mpp  = csr_wr_data[12:11];
      else
         nxt_mpp  = mcsr.mstatus.mpp;                                   // xPP holds the previous privilege mode

      if (reset_in)
         nxt_mpie = 1'b0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mpie = mcsr.mstatus.mie;                                   // When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE
      else if (mret)
         nxt_mpie = 1'b1;                                               // When executing an xRET instruction, ... xPIE is set to 1;   p. 21 riscv-privilege
      else
         nxt_mpie = mcsr.mstatus.mpie;  // x PIE holds the value of the interrupt-enable bit active prior to the trap

      // p. 20 The xIE bits are in the low-order bits of mstatus, allowing them to be atomically set or cleared with a single CSR instruction
      //       or cleared with a single CSR instruction.
      if (reset_in)
         nxt_mie  = FALSE;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mie  = 1'b0;                                               // When a trap is taken from privilege mode y into privilege mode x, ... xIE is set to 0;   p. 21 riscv-privileged.pdf
      else if (mret)
         nxt_mie  = mcsr.mstatus.mpie;                                  // When executing an xRET instruction, supposing xPP holds the value y, xIE is set to xPIE;
      else if (csr_wr && (csr_addr == 12'h300) && (mode == M_MODE))     // modes lower than 3 cannot modify mie bit
         nxt_mie  = csr_wr_data[3];
      else
         nxt_mie  = mcsr.mstatus.mie;  // keep current value
   end

   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  mip                                 (read-write)  machine mode
   `ifdef ext_N
   logic nxt_msip, nxt_mtip, nxt_meip;

   always_comb // logic for what WILL happen to msip, mtip, meip under a given condition
   begin
      if (reset_in)  // Software Interrupts
         nxt_msip    = FALSE;
      else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
         nxt_msip    = csr_wr_data[3];                                  // set or clear MSIP
      else
         nxt_msip    = mcsr.mip.msip;

      if (reset_in)
         nxt_mtip    = FALSE;
      else if (mode == M_MODE)                                           // irq setting during Machine mode
         nxt_mtip    = timer_irq;
      else
         nxt_mtip    = mcsr.mip.mtip;                                   // STIP - read only

      if (reset_in)
         nxt_meip    = FALSE;                                           // MEIP - read only
      else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
         nxt_meip    = csr_wr_data[11];                                 // set or clear SEIP
      else if (mode == M_MODE)
         nxt_meip    = ext_irq;                                         // external interrupt
      else
         nxt_meip    = mcsr.mip.meip;
   end
   `endif

   logic nxt_spp, nxt_spie, nxt_sie;


    logic nxt_seip, nxt_stip, nxt_ssip;       // used in csr_super_av_rdata_nxt.sv, csr_mach_av_rdata_nxt.sv
   `ifdef ext_S
      `ifdef ext_N
      // Supervisor Interrupt-Pending Register bits
      always_comb // logic for what WILL happen to ssip, stip, seip under a given condition
      begin
         if (reset_in)  // Software Interrupts
            nxt_ssip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE)) // see p. 29 riscv-privileged to see about M_MODE writes to this bit
            nxt_ssip    = csr_wr_data[1];                            // set or clear USIP
         else if (csr_wr & (csr_addr == 12'h144) & (mode >= S_MODE))
            nxt_ssip    = csr_wr_data[1];                            // set or clear SSIP
         else
            nxt_ssip    = scsr.sip.ssip;

         // The ... STIP bits may be written by M-mode software to deliver timer interrupts to lower privilege levels. see p. 30 riscv-privileged
         if (reset_in)  // Timer Interrupts
            nxt_stip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
            nxt_stip    = csr_wr_data[5];                            // set or clear STIP
         else if (mode == S_MODE)                                     // irq setting during supervisor mode
            nxt_stip    = timer_irq;
         else
            nxt_stip    = scsr.sip.stip;                             // STIP - read only

         // SEIP may be written by M-mode software to indicate to S-mode that an external interrupt is pending. p. 30 riscv-privileged
         if (reset_in)  // External Interrupts
            nxt_seip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
            nxt_seip    = csr_wr_data[9];                            // set or clear SEIP
         else if (mode == S_MODE)
            nxt_seip    = ext_irq;                                   // external interrupt
         else
            nxt_seip    = scsr.sip.seip;
      end
      `else
      assign nxt_seip = FALSE;
      assign nxt_stip = FALSE;
      assign nxt_ssip = FALSE;
      `endif
   `else
      assign nxt_seip = FALSE;
      assign nxt_stip = FALSE;
      assign nxt_ssip = FALSE;
   `endif

   logic nxt_upie, nxt_uie;
   `ifdef ext_U
      `ifdef ext_N
      // User Status Register bits
      always_comb // must be equivalent logic in csr_user_wr_reg.sv
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
            nxt_upie  = 1'b0;
         else if (exception.flag & (nxt_mode == U_MODE))
            nxt_upie  = uie;
         else if (uret)
            nxt_upie  = 1'b1;

         // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
         //       or cleared with a single CSR instruction.
         if (reset_in)
            nxt_uie  = FALSE;
         else if (csr_wr && (csr_addr == 12'h300) && (mode == M_MODE))
            nxt_uie  = csr_wr_data[0];
         `ifdef ext_S
         else if (csr_wr && (csr_addr == 12'h100) && (mode == S_MODE))
            nxt_uie  = csr_wr_data[0];
         `endif // ext_S
         else if (csr_wr && (csr_addr == 12'h000))
            nxt_uie  = csr_wr_data[0];
         else if (exception.flag & (nxt_mode == U_MODE))
            nxt_uie  = 'd0;
         else if (uret)
            nxt_uie  = mcsr.mstatus.mpie;                                  // "xIE is set to xPIE;"  p. 21 riscv-privileged.pdf
      end
      `else // !ext_N
      assign nxt_upie   = 1'b0;
      assign nxt_uie    = 1'b0;
      `endif // ext_N
   `else // !ext_N
   assign nxt_upie   = 1'b0;
   assign nxt_uie    = 1'b0;
   `endif // ext_U


   `ifdef use_MHPM
   logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_lo;   // 12'hB03 - 12'B1F
   logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_hi;   // 12'hB83 - 12'B9F
   logic   [NUM_MHPM-1:0] [EV_SEL_SZ-1:0] mhpmevent;        // 12'h323 - 12'h33F, mhpmevent3 - mhpmevent31
   `endif

   logic nxt_usip, nxt_utip, nxt_ueip;
   always_comb
   begin
      nxt_mcsr = '{default: '0};
      `ifdef ext_U
      // ==================================================================== User Mode Registers ====================================================================

      // ------------------------------ User Status Register
      // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
      // ustatus = mstatus & MASK - see cntrl_status_regs.sv

      `ifdef ext_F
      // ------------------------------ User Floating-Point CSRs
      // 12'h001 - 12'h003
      if (csr_wr & (csr_addr == 12'h001))
         nxt_mcsr.???? = ???
      else
         nxt_mcsr.???? = mcsr.????

      if (csr_wr & (csr_addr == 12'h002))
         nxt_mcsr.???? = ???
      else
         nxt_mcsr.???? = mcsr.????

      if (csr_wr & (csr_addr == 12'h003))
         nxt_mcsr.???? = ???
      else
         nxt_mcsr.???? = mcsr.????
      `endif   // ext_F

      `ifdef ext_N
      // ------------------------------ User Interrupt-Enable Register
      // 12'h004 = 12'b0000_0000_0100  uie                           (read-write)  user mode
      if (csr_wr & (csr_addr == 12'h004))
         nxt_ucsr.uie = csr_wr_data;
      else
         nxt_ucsr.uie = ucsr.uie;                                    // no change
      `endif // ext_N

      // ------------------------------ User Trap Handler Base address.
      // 12'h005 = 12'b0000_0000_0101  utvec                         (read-write)  user mode
      if (csr_wr & (csr_addr == 12'h005))
         nxt_ucsr.utvec = csr_wr_data;
      else
         nxt_ucsr.utvec = ucsr.utvec;                                // no change

      // ------------------------------ User Trap Handling
      // Scratch register for user trap handlers.
      // 12'h040 = 12'b0000_0100_0000  uscratch                      (read-write)
      if (csr_wr & (csr_addr == 12'h040))
         nxt_ucsr.uscratch = csr_wr_data;
      else
         nxt_ucsr.uscratch = ucsr.uscratch;                          // no change

      // ------------------------------ User Exception Program Counter
      // 12'h041 = 12'b0000_0100_0001  uepc                          (read-write)
      if (reset_in)
         nxt_ucsr.uepc     =  '0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.uepc     = {exception.pc[RSZ-1:1], 1'b0};          // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h041))                      // All modes can write to this CSR
         nxt_ucsr.uepc     = {csr_wr_data[RSZ-1:1], 1'b0};           // Software settable - low bit is always 0
      else
         nxt_ucsr.uepc     = ucsr.uepc;                              // no change

      // ------------------------------ User Exception Cause
      // 12'h042 = 12'b0000_0100_0010  ucause                        (read-write)
      if (reset_in)
         nxt_ucsr.ucause   =  'b0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.ucause   = exception.cause;                        // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h042))
         nxt_ucsr.ucause   = csr_wr_data;                            // Sotware settable
      else
         nxt_ucsr.ucause   = ucsr.ucause;                            // no change

      // ------------------------------ User Exception Trap Value    see riscv-privileged p. 38-39
      // 12'h043 = 12'b0000_0100_0011  utval                         (read-write)
      if (reset_in)
         nxt_ucsr.utval    =  'b0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.utval    = exception.tval;                         // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h043))                      // all modes can write to this CSR
         nxt_ucsr.utval    = csr_wr_data;                            // Sotware settable
      else
         nxt_ucsr.utval    = ucsr.utval;                             // no change

      `ifdef ext_N
      // ------------------------------ User interrupt pending.
      // 12'h044 = 12'b0000_0100_0100  uip         (read-write)
      // uip = mip & MASK -> see cntrl_st
         // User interrupt pending.
         // 12'h044 = 12'b0000_0100_0100  uip                              (read-write)  user mode
         if (reset_in)  // Software Interrupts
            nxt_usip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))       // see p. 29 riscv-privileged to see about M_MODE writes to this bit
            nxt_usip    = csr_wr_data[0];                                  // set or clear USIP
         else if (csr_wr & (csr_addr == 12'h144) & (mode >= S_MODE))
            nxt_usip    = csr_wr_data[0];                                  // set or clear USIP
         else if (csr_wr & (csr_addr == 12'h044))
            nxt_usip    = csr_wr_data[0];                                  // set or clear USIP
         else
            nxt_usip    = ucsr.uip.usip;

         // The UTIP ... bits may be written by M-mode software to deliver timer interrupts to lower privilege levels. see p. 30 riscv-privileged
         if (reset_in)  // Timer Interrupts
            nxt_utip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
            nxt_utip    = csr_wr_data[4];                                  // set or clear UTIP
         else if (csr_wr & (csr_addr == 12'h144) & (mode >= S_MODE))
            nxt_utip    = csr_wr_data[4];                                  // set or clear UTIP
         else if (mode == S_MODE)                                          // irq setting during supervisor mode
            nxt_utip    = timer_irq;
         else
            nxt_utip    = ucsr.uip.utip;

         // UEIP may be written by M-mode software to indicate to S-mode that an external interrupt is pending. p. 30 riscv-privileged
         if (reset_in)  // External Interrupts
            nxt_ueip    = FALSE;
         else if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
            nxt_ueip    = csr_wr_data[8];                                  // set or clear UEIP
         else if (mode == U_MODE)
            nxt_ueip    = ext_irq;                                         // external interrupt
         else
            nxt_ueip    = ucsr.uip.ueip;
      `else //  ext_U and !ext_N
         nxt_usip = FALSE;
         nxt_utip = FALSE;
         nxt_ueip = FALSE;
      `endif // etx_N
      `else // !ext_U
      nxt_usip = FALSE;
      nxt_utip = FALSE;
      nxt_ueip = FALSE;
      `endif // etx_U


      `ifdef ext_S
      // ==================================================================== Supervisor Mode Registers ==============================================================

      // ------------------------------ Supervisor Status Register
      // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
      // sstatus = mstatus & MASK - see cntrl_status_regs.sv
      `ifdef ext_N
         if (reset_in)
            nxt_spp = 1'b0;                                          // spp = User?
         else if (exception.flag & (nxt_mode == S_MODE))
            nxt_spp = mode[0];                                       // spp = Supervisor Prevous Privileged mode
         else if (sret)                                              // Note: S mode implies there's a U-mode because S mode is not allowed unless U is supported
            nxt_spp = 1'b0;                                          // "and xPP is set to U (or M if user-mode is not supported)." p. 20 riscv-privileged-v1.10
         else
            nxt_spp = mcsr.mstatus.spp;                              // spp

         if (reset_in)                                               // spie
            nxt_spie = 'd0;
         else if (exception.flag & (nxt_mode == S_MODE))
            nxt_spie = sie;                                          // spie <= sie
         else if (sret)
            nxt_spie = TRUE;                                         // "xPIE is set to 1"
         else
            nxt_spie = mcsr.mstatus.spie;                            // spie

         // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
         //       or cleared with a single CSR instruction.
         if (reset_in)
            nxt_sie = FALSE;
         else if (exception.flag & (nxt_mode == S_MODE))
            nxt_sie = 'd0;
         else if (sret)                                              // "xIE is set to xPIE;"
            nxt_sie = mcsr.mstatus.spie;
         else if (csr_wr && (csr_addr == 12'h100) && (nxt_mode >= S_MODE))
            nxt_sie = csr_wr_data[1];
         else
            nxt_sie = mcsr.mstatus.sie;
      `else // !ext_N
         nxt_spp    = 1'b0;
         nxt_spie   = 1'b0;
         nxt_sie    = 1'b0;
      `endif // ext_N

      // ------------------------------ Supervisor exception delegation register.
      // 12'h102 = 12'b0001_0000_0010  sedeleg                       (read-write)
      if (csr_wr && (csr_addr == 12'h102))
         nxt_scsr.sedeleg  = csr_wr_data;
      else
         nxt_scsr.sedeleg  = scsr.sedeleg;

      `ifdef ext_N
      // ------------------------------ Supervisor interrupt delegation register.
      // 12'h103 = 12'b0001_0000_0011  sideleg                       (read-write)
      if (csr_wr && (csr_addr == 12'h103))
         nxt_scsr.sideleg  = csr_wr_data;
      else
         nxt_scsr.sideleg  = scsr.sideleg;

      // ------------------------------ Supervisor interrupt-enable register.
      // 12'h104 = 12'b0001_0000_0100  sie                           (read-write)
      if (csr_wr && (csr_addr == 12'h104))
         nxt_scsr.sie   = csr_wr_data;
      else
         nxt_scsr.sie   = scsr.sie;
      `endif // ext_N

      // ------------------------------ Supervisor trap handler base address.
      // 12'h105 = 12'b0001_0000_0101  stvec       (read-write)
      // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
      if (csr_wr && csr_addr == 12'h105)
         nxt_scsr.stvec = csr_wr_data;
      else
         nxt_scsr.stvec = scsr.stvec;

      // ------------------------------ Supervisor counter enable.
      // 12'h106 = 12'b0001_0000_0110  scounteren                    (read-write)
      if (csr_wr && (csr_addr == 12'h106))
         nxt_scsr.scounteren = csr_wr_data;
      else
         nxt_scsr.scounteren = scsr.scounteren;

      // ------------------------------ Supervisor Scratch register
      // Scratch register for supervisor trap handlers.
      // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
      if (csr_wr && (csr_addr == 12'h140))
         nxt_scsr.sscratch = csr_wr_data;
      else
         nxt_scsr.sscratch = scsr.sscratch;

      // ------------------------------ Supervisor Exception Program Counter
      // 12'h141 = 12'b0001_0100_0001  sepc                          (read-write)
      if (reset_in)
         nxt_scsr.sepc  =  '0;
      else if ((exception.flag) & (nxt_mode == S_MODE))
         nxt_scsr.sepc  = {exception.pc[RSZ-1:1], 1'b0};             // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h141) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.sepc  = {csr_wr_data[RSZ-1:1], 1'b0};              // Software settable - low bit is always 0
      else
         nxt_scsr.sepc  = scsr.sepc;                                 // no change

      // ------------------------------ Supervisor Exception Cause
      // 12'h142 = 12'b0001_0100_0010  scause                        (read-write)
      if (reset_in)
         nxt_scsr.scause   =  'b0;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_scsr.scause   = exception.cause;                        // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h142) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.scause   = csr_wr_data;                            // Sotware settable
      else
         nxt_scsr.scause   = scsr.scause;                            // no change


      // ------------------------------ Supervisor Exception Trap Value                            see riscv-privileged p. 38-39
      // 12'h143 = 12'b0001_0100_0011  stval                         (read-write)
      if (reset_in)
         nxt_scsr.stval =  'b0;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_scsr.stval = exception.tval;                            // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h143) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.stval = csr_wr_data;                               // Sotware settable
      else
         nxt_scsr.stval = scsr.stval;                                // no change

      // ------------------------------ Supervisor interrupt pending.
      // p. 29 SUPERVISOR mode: The logical-OR of the software-writeable bit and the signal from the external interrupt controller is used to generate external
      // interrupts to the supervisor. When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the rd destination register
      // contains the logical-OR of the software-writable bit and the interrupt signal from the interrupt controller. However, the value used in the  read-modify-write
      // sequence of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt value from the external interrupt controller.
      `ifdef ext_N
      // 12'h144 = 12'b0001_0100_0100  sip         (read-write)
      //                 31:10   9         8        7:6    5         4         3:2   1         0
      if (csr_wr && (csr_addr == 12'h144))
         nxt_scsr.sip = {22'b0, nxt_seip, nxt_ueip, 2'b0, nxt_stip, nxt_utip, 2'b0, nxt_ssip, nxt_usip};
      else
         nxt_scsr.sip = scsr.sip;

      `endif // ext_N

      // ------------------------------ Supervisor Protection and Translation
      // Supervisor address translation and protection.
      // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
      if (csr_wr && (csr_addr == 12'h180))
         nxt_scsr.satp = csr_wr_data;
      else
         nxt_scsr.satp = scsr.satp;

      `else // !ext_S
      nxt_spp    = 1'b0;
      nxt_spie   = 1'b0;
      nxt_sie    = 1'b0;
      `endif

      // ==================================================================== Machine Mode Registers =================================================================

      // ------------------------------ Machine Status Register
      // Machine status register.
      // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
      //                      31        22   21  20   19   18   17   16:15 14:13  12:11    10:9    8        7         6     5         4         3        2     1        0
      if (csr_wr && (csr_addr == 12'h300))
         nxt_mcsr.mstatus  = {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs, nxt_mpp, 2'b0,  nxt_spp, nxt_mpie, 1'b0, nxt_spie, nxt_upie, nxt_mie, 1'b0, nxt_sie, nxt_uie};
      else
         nxt_mcsr.mstatus  = mcsr.mstatus;

      // -------------------------------------- MISA -------------------------------------
      // ISA and extensions
      // 12'h301 = 12'b0011_0000_0001  misa                          (read-write but currently Read Only)
      // NOTE: if made to be writable, don't allow bit  2 to change to 1 if ext_C not defined
      // NOTE: if made to be writable, don't allow bit  5 to change to 1 if ext_F not defined
      // NOTE: if made to be writable, don't allow bit 12 to change to 1 if ext_M not defined
      // NOTE: if made to be writable, don't allow bit 13 to change to 1 if ext_N not defined
      // NOTE: if made to be writable, don't allow bit 18 to change to 1 if ext_S not defined
      // NOTE: if made to be writable, don't allow bit 20 to change to 1 if ext_U not defined
      // etc...
 //   if (csr_wr && (csr_addr == 12'h301))
 //
 //   else
         nxt_mcsr.misa  = MISA;


      // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
      // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

      //!!! NOTE: Don't yet know how to implement all the logic for medeleg and mideleg!!!

      `ifdef ext_S // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
         // Machine exception delegation register
         // 12'h302 = 12'b0011_0000_0010  medeleg                       (read-write)
         if (csr_wr && (csr_addr == 12'h302))
            nxt_mcsr.medeleg  = csr_wr_data;
         else
            nxt_mcsr.medeleg  = mcsr.medeleg;

         // Machine interrupt delegation register
         // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
         if (csr_wr && (csr_addr == 12'h303))
            nxt_mcsr.mideleg  = csr_wr_data;
         else
            nxt_mcsr.mideleg  = mcsr.mideleg;
      `else // !ext_S
         `ifdef ext_U
            `ifdef ext_N
            // Machine exception delegation register
            // 12'h302 = 12'b0011_0000_0010  medeleg                    (read-write)
            if (csr_wr && (csr_addr == 12'h302))
               nxt_mcsr.medeleg  = csr_wr_data;
            else
               nxt_mcsr.medeleg  = mcsr.medeleg;

            // Machine interrupt delegation register
            // 12'h303 = 12'b0011_0000_0011  mideleg                    (read-write)
            if (csr_wr && (csr_addr == 12'h303))
               nxt_mcsr.mideleg  = csr_wr_data;
            else
               nxt_mcsr.mideleg  = mcsr.mideleg;
            `endif
         `endif
      `endif

      `ifdef ext_N
      // ------------------------------ Machine interrupt-enable register
      // 12'h304 = 12'b0011_0000_0100  mie                              (read-write)
      if (csr_wr && (csr_addr == 12'h304))
         nxt_mcsr.mie   = csr_wr_data;
      else
         nxt_mcsr.mie   = mcsr.mie;                                     // no change
      `endif

      // ------------------------------ Machine trap-handler base address
      // 12'h305 = 12'b0011_0000_0101  mtvec                            (read-write)
      // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
      if (csr_wr & (csr_addr == 12'h305))
         nxt_mcsr.mtvec = csr_wr_data & 32'hFFFF_FFC3;
      else
         nxt_mcsr.mtvec = mcsr.mtvec;                                   // no change

      // ------------------------------ Machine counter enable
      // 12'h306 = 12'b0011_0000_0110  mcounteren                       (read-write)
      if (csr_wr && (csr_addr == 12'h306))
         nxt_mcsr.mcounteren = csr_wr_data;
      else
         nxt_mcsr.mcounteren = mcsr.mcounteren;

      // ------------------------------ Machine Counter Setup
      // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
      // 12'h320 = 12'b0011_0010_00000  mcountinhibit                   (read-write)
      if (reset_in)
         nxt_mcsr.mcountinhibit = (SET_MCOUNTINHIBIT == 1) ? SET_MCOUNTINHIBIT_BITS : 0;
      else if (csr_wr && (csr_addr == 12'h320))
         nxt_mcsr.mcountinhibit = csr_wr_data;
      else
         nxt_mcsr.mcountinhibit = mcsr.mcountinhibit;

      `ifdef use_MHPM
      // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
      // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                    (read-write)
      //
      // see generate/always_comb logic further below
      nxt_mcsr.mhpmevent      = mhpmevent;
      `endif

      // ------------------------------ Machine Scratch register
      // Scratch register for machine trap handlers.
      // 12'h340 = 12'b0011_0100_0000  mscratch                         (read-write)
      if (csr_wr && (csr_addr == 12'h340))
         nxt_mcsr.mscratch = csr_wr_data;
      else
         nxt_mcsr.mscratch = mcsr.mscratch;

      // ------------------------------ Machine Exception Program Counter. Used by MRET instruction at end of Machine mode trap handler
      // 12'h341 = 12'b0011_0100_0001  mepc                             (read-write)   see riscv-privileged p 36
      if (reset_in)
         nxt_mcsr.mepc     =  '0;
      else if ((exception.flag) & (nxt_mode == M_MODE))
         nxt_mcsr.mepc     = {exception.pc[RSZ-1:1], 1'b0};             // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h341) & (mode == M_MODE))      // Only Machine mode can write to this CSR
         nxt_mcsr.mepc     = {csr_wr_data[RSZ-1:1], 1'b0};              // Software settable - low bit is always 0
      else
         nxt_mcsr.mepc     = mcsr.mepc;                                 // no change

      // ------------------------------ Machine Exception Cause
      // 12'h342 = 12'b0011_0100_0010  mcause                           (read-write)
      if (reset_in)
         nxt_mcsr.mcause   = 'b0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mcause   = exception.cause;                           // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h342) & (mode == M_MODE))
         nxt_mcsr.mcause   = csr_wr_data;                               // Sotware settable
      else
         nxt_mcsr.mcause   = mcsr.mcause;                               // no change

      // ------------------------------ Machine Exception Trap Value
      // 12'h343 = 12'b0011_0100_0011  mtval                            (read-write)
      //
      if (reset_in)
         nxt_mcsr.mtval    = 'b0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mtval    = exception.tval;                            // save trap value for exception
      else if (csr_wr && (csr_addr == 12'h343) & (mode == M_MODE))      // Only Machine mode can write to this CSR
         nxt_mcsr.mtval    = csr_wr_data;                               // Sotware settable
      else
         nxt_mcsr.mtval    = mcsr.mtval;                                // no change

      `ifdef ext_N
      // ---------------------- Machine Interrupt Pending bits ----------------------
      // 12'h344 = 12'b0011_0100_0100  mip                              (read-write)  machine mode
      nxt_mcsr.mip = {20'b0, nxt_meip, 1'b0, nxt_seip, nxt_ueip, nxt_mtip, 1'b0, nxt_stip, nxt_utip, nxt_msip, 1'b0, nxt_ssip, nxt_usip};  // see p 29 riscv-privileged
      `endif

      // ------------------------------ Machine Protection and Translation

      // 12'h3A0 - 12'h3A3
      `ifdef USE_PMPCFG
      // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                          (read-write)
      if (csr_wr && (csr_addr == 12'h3A0))
         nxt_mcsr.pmpcfg0 = csr_wr_data;
      else
         nxt_mcsr.pmpcfg0 = mcsr.pmpcfg0;

      // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                          (read-write)
      if (csr_wr && (csr_addr == 12'h3A1))
         nxt_mcsr.pmpcfg1 = csr_wr_data;
      else
         nxt_mcsr.pmpcfg1 = mcsr.pmpcfg1;

      // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                          (read-write)
      if (csr_wr && (csr_addr == 12'h3A2))
         nxt_mcsr.pmpcfg2 = csr_wr_data;
      else
         nxt_mcsr.pmpcfg2 = mcsr.pmpcfg2;

      // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                          (read-write)
      if (csr_wr && (csr_addr == 12'h3A3))
         nxt_mcsr.pmpcfg3 = csr_wr_data;
      else
         nxt_mcsr.pmpcfg3 = mcsr.pmpcfg3;

      `endif

      // 12'h3B0 - 12'h3BF
      // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
      `ifdef PMP_ADDR0
      if (csr_wr && (csr_addr == 12'h3B0))
         nxt_mcsr.pmpaddr0 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr0 = mcsr.pmpaddr0;
      `endif
      `ifdef PMP_ADDR1
      if (csr_wr && (csr_addr == 12'h3B1))
         nxt_mcsr.pmpaddr1 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr1 = mcsr.pmpaddr1;
      `endif
      `ifdef PMP_ADDR2
      if (csr_wr && (csr_addr == 12'h3B2))
         nxt_mcsr.pmpaddr2 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr2 = mcsr.pmpaddr2;
      `endif
      `ifdef PMP_ADDR3
      if (csr_wr && (csr_addr == 12'h3B3))
         nxt_mcsr.pmpaddr3 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr3 = mcsr.pmpaddr3;
      `endif
      `ifdef PMP_ADDR4
      if (csr_wr && (csr_addr == 12'h3B4))
         nxt_mcsr.pmpaddr4 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr4 = mcsr.pmpaddr4;
      `endif
      `ifdef PMP_ADDR5
      if (csr_wr && (csr_addr == 12'h3B5))
         nxt_mcsr.pmpaddr5 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr5 = mcsr.pmpaddr5;
      `endif
      `ifdef PMP_ADDR6
      if (csr_wr && (csr_addr == 12'h3B6))
         nxt_mcsr.pmpaddr6 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr6 = mcsr.pmpaddr6;
      `endif
      `ifdef PMP_ADDR7
      if (csr_wr && (csr_addr == 12'h3B7))
         nxt_mcsr.pmpaddr7 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr7 = mcsr.pmpaddr7;
      `endif
      `ifdef PMP_ADDR8
      if (csr_wr && (csr_addr == 12'h3B8))
         nxt_mcsr.pmpaddr8 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr8 = mcsr.pmpaddr8;
      `endif
      `ifdef PMP_ADDR9
      if (csr_wr && (csr_addr == 12'h3B9))
         nxt_mcsr.pmpaddr9 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr9 = mcsr.pmpaddr9;
      `endif
      `ifdef PMP_ADDR10
      if (csr_wr && (csr_addr == 12'h3BA))
         nxt_mcsr.pmpaddr10 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr10 = mcsr.pmpaddr10;
      `endif
      `ifdef PMP_ADDR11
      if (csr_wr && (csr_addr == 12'h3BB))
         nxt_mcsr.pmpaddr11 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr11 = mcsr.pmpaddr11;
      `endif
      `ifdef PMP_ADDR12
      if (csr_wr && (csr_addr == 12'h3BC))
         nxt_mcsr.pmpaddr12 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr12 = mcsr.pmpaddr12;
      `endif
      `ifdef PMP_ADDR13
      if (csr_wr && (csr_addr == 12'h3BD))
         nxt_mcsr.pmpaddr13 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr13 = mcsr.pmpaddr13;
      `endif
      `ifdef PMP_ADDR14
      if (csr_wr && (csr_addr == 12'h3BE))
         nxt_mcsr.pmpaddr14 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr14 = mcsr.pmpaddr14;
      `endif
      `ifdef PMP_ADDR15
      if (csr_wr && (csr_addr == 12'h3BF))
         nxt_mcsr.pmpaddr15 = csr_wr_data;
      else
         nxt_mcsr.pmpaddr15 = mcsr.pmpaddr15;
      `endif

      `ifdef add_DM
      // Debug Write registers - INCOMPLETE!!!!!!!!!!!
      // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
      if (csr_wr && (csr_addr == 12'h7A0))
         nxt_mcsr.tselect     = csr_wr_data;          // change Trigger Select Register
      else
         nxt_mcsr.tselect     = mcsr.tselect;         // No change

      if (csr_wr && (csr_addr == 12'h7A1))
         nxt_mcsr.tdata1      = csr_wr_data;          // change Trigger Data Register 1
      else
         nxt_mcsr.tdata1      = mcsr.tdata1;          // No change

      if (csr_wr && (csr_addr == 12'h7A2))
         nxt_mcsr.tdata2      = csr_wr_data;          // change Trigger Data Register 2
      else
         nxt_mcsr.tdata2      = mcsr.tdata2;          // No change

      if (csr_wr && (csr_addr == 12'h7A3))
         nxt_mcsr.tdata3      = csr_wr_data;          // change Trigger Data Register 3
      else
         nxt_mcsr.tdata3      = mcsr.tdata3;          // No change

      // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
      // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
      if (csr_wr && (csr_addr == 12'h7B0))
         nxt_mcsr.dcsr        = csr_wr_data;          // change Debug Control and Status Register
      else
         nxt_mcsr.dcsr        = mcsr.dcsr;            // No change

      if (csr_wr && (csr_addr == 12'h7B1))
         nxt_mcsr.dpc         = csr_wr_data;          // change Debug PC Register
      else
         nxt_mcsr.dpc         = mcsr.dpc;

      if (csr_wr && (csr_addr == 12'h7B2))
         nxt_mcsr.dscratch0   = csr_wr_data;          // change Debug Scratch Register 0
      else
         nxt_mcsr.dscratch0   = mcsr.dscratch0;

      if (csr_wr && (csr_addr == 12'h7B3))
         nxt_mcsr.dscratch1   = csr_wr_data;          // change Debug Scratch Register 1
      else
         nxt_mcsr.dscratch1   = mcsr.dscratch1;

      `endif // add_DM

      // ------------------------------ Machine Cycle Counter
      // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
      // mhpmcountern, respectively. p 34 risvcv-privileged.pdf
      // p 136 "Cycle counter for RDCYCLE instruction"
      //
      // Lower 32 bits of mcycle, RV32I only.
      // 12'hB00 = 12'b1011_0000_0000  mcycle_lo (read-write)
      //
      // Upper 32 bits of mcycle, RV32I only.
      // 12'hB80 = 12'b1011_1000_0000  mcycle_hi (read-write)
      //
      if (reset_in)
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = '0;
      else if (csr_wr && (csr_addr == 12'hB00) && (mode == M_MODE))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB80) && (mode == M_MODE))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {csr_wr_data,mcsr.mcycle_lo};
      else if (!mcsr.mcountinhibit[0])
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,mcsr.mcycle_lo} + 'd1;  // increment counter/timer
      else
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,mcsr.mcycle_lo};        // no change

      // ------------------------------ Machine Instructions-Retired Counter
      // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
      // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf
      // Lower 32 bits of minstret, RV32I only.
      // 12'hB02 = 12'b1011_0000_0010  minstret_lo                      (read-write)
      //
      // Upper 32 bits of minstret, RV32I only.
      // 12'hB82 = 12'b1011_1000_0010  minstret_hi                      (read-write)
      //
      if (reset_in)
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = 'd0;
      else if (csr_wr && (csr_addr == 12'hB02) && (mode == 3))
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB82) && (mode == 3))
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {csr_wr_data,mcsr.minstret_lo};
      else if (!mcsr.mcountinhibit[2])
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,mcsr.minstret_lo} + tot_retired;
      else
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,mcsr.minstret_lo};

      `ifdef use_MHPM
      // ------------------------------ Machine Hardware Performance-Monitoring Counters
      // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
      // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
      //
      // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
      // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
      //
      // see generate/always_comb logic further below
      nxt_mcsr.mhpmcounter_hi = mhpmcounter_hi;
      nxt_mcsr.mhpmcounter_lo = mhpmcounter_lo;
      `endif

      // ------------------------------ Machine Information Registers
      // NOTE: These can be changed as needed. currently they are just constants
      // Vendor ID
      // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
      nxt_mcsr.mvendorid = M_VENDOR_ID;

      // Architecture ID
      // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
      nxt_mcsr.marchid  = M_ARCH_ID;

      // Implementation ID
      // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
      nxt_mcsr.mimpid   = M_IMP_ID;

      // Hardware Thread ID
      // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
      nxt_mcsr.mhartid  = M_HART_ID;
   end

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors & Counters

   `ifdef use_MHPM
   genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
   generate
      for (n = 0; n < NUM_MHPM; n++)
      begin : MHPM_CNTR_EVENTS
         always_comb
         begin
            // Machine hardware performance-monitoring event selectors mhpmevent3 - mhpmevent31
            // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31           (read-write)
            if (reset_in)
               mhpmevent[n]    = '0;
            else if (csr_wr && (csr_addr == 12'h323+n) && (mode == M_MODE))
               mhpmevent[n]    = csr_wr_data[EV_SEL_SZ-1:0];   // write to this event register to change which event is selected
            else
               mhpmevent[n]    = mcsr.mhpmevent[n];            // don't change it

            // Machine hardware performance-monitoring counters
            // increment mhpmcounter[] if the Event Selector is not 0 and the corresponding mcountinhibit[] bit is not set.
            // currently there are 24 possible hpm_events[], where event[0] = 0
            // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
            //
            // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
            if (reset_in)
               {mhpmcounter_hi[n], mhpmcounter_lo[n]} = 'd0;
            else if (csr_wr && (csr_addr == (12'hB03+n)) && (mode == M_MODE)) // Andrew Waterman says these are writable in an Apr 8, 2019 post
               {mhpmcounter_hi[n], mhpmcounter_lo[n]} = {mcsr.mhpmcounter_hi[n],csr_wr_data};
            else if (csr_wr && (csr_addr == (12'hB83+n)) && (mode == M_MODE))
               {mhpmcounter_hi[n], mhpmcounter_lo[n]} = {csr_wr_data,mcsr.mhpmcounter_lo[n]};
            else
               {mhpmcounter_hi[n], mhpmcounter_lo[n]}  = mcsr.mcountinhibit[n+3] ? {mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} :
                                                                                                     {mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} + hpm_events[mcsr.mhpmevent[n]];
         end
      end
   endgenerate
   `endif // use_MHPM

endmodule
