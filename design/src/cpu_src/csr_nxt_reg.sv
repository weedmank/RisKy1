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
import csr_params_pkg::*;

module csr_nxt_reg
(
   input    logic                ext_irq,
   input    logic                timer_irq,
   input    logic                sw_irq,           // msip_reg[] see irq.sv

   input    logic         [11:0] csr_addr,
   input    logic                csr_wr,
   input    logic      [RSZ-1:0] csr_wr_data,

   input    logic                total_retired,    // In this design, at most, 1 instruction can retire per clock cycle
   input    var EXCEPTION        exception,

   `ifdef use_MHPM
   input    var logic            hpm_events[0:23], // 24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
   `endif

   input    logic          [1:0] mode,
   input    logic          [1:0] nxt_mode,

   `ifdef ext_U
   `ifdef ext_N
   input    logic                uret,
   input    var UCSR             ucsr,             // all of the User mode Control & Status Registers
   output   UCSR                 nxt_ucsr,         // all of the next User mode Control & Status Registers
   `endif
   `endif

   `ifdef ext_S
   input    logic                sret,
   input    var SCSR             scsr,             // all of the Supervisor mode Control & Status Registers
   output   SCSR                 nxt_scsr,         // all of the next Supervisor mode Control & Status Registers
   `endif

   input    logic                mret,
   input    var MCSR             mcsr,             // all of the Machine mode Control & Status Registers
   output   MCSR                 nxt_mcsr          // all of the next Machine mode Control & Status Registers
);

   `ifdef use_MHPM
   logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_lo;   // 12'hB03 - 12'B1F
   logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_hi;   // 12'hB83 - 12'B9F
   logic   [NUM_MHPM-1:0] [EV_SEL_SZ-1:0] mhpmevent;        // 12'h323 - 12'h33F, mhpmevent3 - mhpmevent31
   `endif

   // Machine Status signals
   logic       nxt_mpie, nxt_mie;
   logic       nxt_spp,  nxt_spie, nxt_sie;
   logic       nxt_upie, nxt_uie;
   logic       nxt_sd, nxt_tsr, nxt_tw, nxt_tvm, nxt_mxr, nxt_sum, nxt_mprv;
   logic [1:0] nxt_xs, nxt_fs;
   logic [1:0] nxt_mpp;

   always_comb
   begin
      nxt_spp     = 1'b0;
      nxt_spie    = 1'b0;
      nxt_sie     = 1'b0;

      nxt_upie    = '0;
      nxt_uie     = FALSE;

      // ==================================================================== Machine Mode Registers =================================================================

      // ------------------------------ Machine Status Register
      // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)

      // (read-write)   p. 56 riscv-privileged
      if (exception.flag & (nxt_mode == M_MODE))                              // holds the previous privilege mode
         nxt_mcsr.mstatus.mpp  = mode;                                        // When a trap is taken from privilege mode y into privilege mode x, ... and xPP is set to y. p. 21 riscv-privileged.pdf 1.12-draft
      else if (mret)
      `ifdef ext_U
         nxt_mcsr.mstatus.mpp  = U_MODE;                                      // "and xPP is set to U (or M if user-mode is not supported)."
      `else
         nxt_mcsr.mstatus.mpp  = M_MODE;
      `endif
      else if (csr_wr & (csr_addr == 12'h300) & (mode == M_MODE))             // xPP fields are WARL fields that can hold only privilege mode x and any implemented privilege mode lower than x.
         nxt_mcsr.mstatus.mpp  = csr_wr_data[12:11];                          // writable in M_MODE
      else
         nxt_mcsr.mstatus.mpp  = mcsr.mstatus.mpp;                            // xPP holds the previous privilege mode
      nxt_mpp    = nxt_mcsr.mstatus.mpp;

      if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mstatus.mpie = mcsr.mstatus.mie;                            // When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE
      else if (mret)
         nxt_mcsr.mstatus.mpie = 1'b1;                                        // When executing an xRET instruction, ... xPIE is set to 1;
      else
         nxt_mcsr.mstatus.mpie = mcsr.mstatus.mpie;                           // x PIE holds the value of the interrupt-enable bit active prior to the trap
      nxt_mpie   = nxt_mcsr.mstatus.mpie;

      nxt_mprv = mcsr.mstatus.mprv;
      if ((nxt_mcsr.mstatus.mpp != M_MODE) & mret)                            // If xPP̸=M, xRET also sets MPRV=0.
         nxt_mprv = 0;
      `ifdef ext_S
      else if ((nxt_scsr.sstatus.spp != (M_MODE[0])) & sret)                  // spp is made from the lower bit of mode
         nxt_mprv = 0;
      `endif

      // p. 20 The xIE bits are in the low-order bits of mstatus, allowing them to be atomically set or cleared with a single CSR instruction
      //       or cleared with a single CSR instruction.
      if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mstatus.mie  = 1'b0;                                        // When a trap is taken from privilege mode y into privilege mode x, ... xIE is set to 0;
      else if (mret)
         nxt_mcsr.mstatus.mie  = mcsr.mstatus.mpie;                           // When executing an xRET instruction, supposing xPP holds the value y, xIE is set to xPIE;
      else if (csr_wr & (csr_addr == 12'h300) & (mode == M_MODE))             // modes lower than Machine cannot modify mie bit
         nxt_mcsr.mstatus.mie  = csr_wr_data[3];
      else
         nxt_mcsr.mstatus.mie  = mcsr.mstatus.mie;                            // keep current value
      nxt_mie    = nxt_mcsr.mstatus.mie;


      //nxt_mcsr.mstatus.tsr = ?????;
      nxt_tsr     = nxt_mcsr.mstatus.tsr;

      //nxt_mcsr.mstatus.tw = ???;
      nxt_tw      = nxt_mcsr.mstatus.tw;

      //nxt_mcsr.mstatus.tvm = ???;
      nxt_tvm     = nxt_mcsr.mstatus.tvm;

      //nxt_mcsr.mstatus.mxr = ????;
      nxt_mxr     = nxt_mcsr.mstatus.mxr;

      //nxt_mcsr.mstatus.sum = ???
      nxt_sum     = nxt_mcsr.mstatus.sum;

      //nxt_mcsr.mstatus.mprv = ???;
      nxt_mprv    = nxt_mcsr.mstatus.mprv;

      // nxt_mcsr.mstatus.xs = ???;
      nxt_xs      = nxt_mcsr.mstatus.xs;

      //nxt_mcsr.mstatus.fs = ???;
      nxt_fs      = nxt_mcsr.mstatus.fs;

      nxt_mcsr.mstatus.sd = ((nxt_fs == 2'b11) || (nxt_xs == 2'b11));
      nxt_sd   = nxt_mcsr.mstatus.sd;

      //                           WPRI                                                                                 WPRI                     ube             WPRI           WPRI           WPRI
      //                   31      30:23 22        21      20       19       18       17       16:15   14:13   12:11    10:9   8        7         6     5         4     3        2     1        0
      nxt_mcsr.mstatus  = {nxt_sd, 8'b0, nxt_tsr, nxt_tw, nxt_tvm, nxt_mxr, nxt_sum, nxt_mprv, nxt_xs, nxt_fs, nxt_mpp, 2'b0, nxt_spp, nxt_mpie, 1'b0, nxt_spie, 1'b0, nxt_mie, 1'b0, nxt_sie, 1'b0};


      // ------------------------------ Machine ISA Register
      // ISA and extensions
      // 12'h301 = 12'b0011_0000_0001  misa                                   (read-write but currently Read Only)
      // NOTE: if made to be writable, don't allow bit  2 to change to 1 if ext_C not defined
      // NOTE: if made to be writable, don't allow bit  5 to change to 1 if ext_F not defined
      // NOTE: if made to be writable, don't allow bit 12 to change to 1 if ext_M not defined
      // NOTE: if made to be writable, don't allow bit 13 to change to 1 if ext_N not defined
      // NOTE: if made to be writable, don't allow bit 18 to change to 1 if ext_S not defined
      // NOTE: if made to be writable, don't allow bit 20 to change to 1 if ext_U not defined
      // etc...
      nxt_mcsr.misa  = mcsr.misa; // currently, no logic is implemented for allowing any MISA bits to dynamically change!


      // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
      // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers now do not exist. see p. iii riscv-privileged.pdf 1.12-draftp
      // In systems with only M and U privilege modes, setting a bit in medeleg or mideleg delegates the corresponding trap in U-mode to the U-mode trap handler. see p 115 riscv-privileged.pdf 1.12-draft

      // medeleg has a bit position allocated for every synchronous exception shown in Table 3.6 on page 37,
      // with the index of the bit position equal to the value returned in the mcause register (i.e., setting
      // bit 8 allows user-mode environment calls to be delegated to a lower-privilege trap handler).

      // mideleg holds trap delegation bits for individual interrupts, with the layout of bits matching those
      // in the mip register (i.e., STIP interrupt delegation control is located in bit 5).
      // Some exceptions cannot occur at less privileged modes, and corresponding x edeleg bits should be
      // hardwired to zero. In particular, medeleg[11] and sedeleg[11:9] are all hardwired to zero.

      // ------------------------------ Machine Delegation Registers
      `ifdef MDLG // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
         // Machine exception delegation register
         // 12'h302 = 12'b0011_0000_0010  Medeleg                             (read-write)
         if (csr_wr & (csr_addr == 12'h302) & (mode == M_MODE))               // writable in M_MODE
            nxt_mcsr.medeleg  = csr_wr_data;
         else
            nxt_mcsr.medeleg  = mcsr.medeleg;                                 // keep current value

         // Machine interrupt delegation register
         // 12'h303 = 12'b0011_0000_0011  Mideleg                             (read-write)
         if (csr_wr & (csr_addr == 12'h303) & (mode == M_MODE))               // writable in M_MODE
            nxt_mcsr.mideleg  = csr_wr_data;
         else
            nxt_mcsr.mideleg  = mcsr.mideleg;                                 // keep current value
      `endif // MDLG

      // ------------------------------ Machine Interrupt Enable register
      // 12'h304 = 12'b0011_0000_0100  Mie                                    (read-write)
      //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
      // {20'b0, meie, 1'b0, seie, 1'b0, mtie, 1'b0, stie, 1'b0, msie, 1'b0, ssie, 1'b0};
      nxt_mcsr.mie   = mcsr.mie;                                              // keep current value
      if (csr_wr & (csr_addr == 12'h304) & (mode == M_MODE))                  // writable in M_MODE
      begin
         nxt_mcsr.mie.msie = csr_wr_data[3];                                  // see sie bits ssie,stie,seie during 12'h304 CSR write
         nxt_mcsr.mie.mtie = csr_wr_data[7];
         nxt_mcsr.mie.meie = csr_wr_data[11];
      end

      // ------------------------------ Machine Trap-handler Base Address
      // 12'h305 = 12'b0011_0000_0101  Mtvec                                  (read-write)
      if (csr_wr & (csr_addr == 12'h305))                                     // writable in M_MODE
         nxt_mcsr.mtvec = csr_wr_data;                                        // see csr.sv - value written may be masked going into register
      else
         nxt_mcsr.mtvec = mcsr.mtvec;                                         // keep current value

      // Andrew Waterman: 12/31/2020 - "There is also a clear statement that mcounteren exists if and only if U mode is implemented"
      `ifdef ext_U
      // ------------------------------ Machine Counter Enable
      // 12'h306 = 12'b0011_0000_0110  Mcounteren                             (read-write)
      if (csr_wr && (csr_addr == 12'h306) & (mode == M_MODE))                 // writable in M_MODE
         nxt_mcsr.mcounteren = csr_wr_data;
      else
         nxt_mcsr.mcounteren = mcsr.mcounteren;                               // keep current value
      `endif

      // ------------------------------ Machine StatusH - additional status register
      // 12'h310 = 12'b0011_0001_0000  mstatush                (read-write)


      // ------------------------------ Machine Counter Setup
      // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
      // 12'h320 = 12'b0011_0010_00000  Mcountinhibit                         (read-write)
      if (csr_wr & (csr_addr == 12'h320) & (mode == M_MODE))                  // writable in M_MODE
         nxt_mcsr.mcountinhibit = csr_wr_data;
      else
         nxt_mcsr.mcountinhibit = mcsr.mcountinhibit;                         // keep current value

      `ifdef use_MHPM
         // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
         // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                       (read-write)
         //
         // see generate/always_comb logic further below
         nxt_mcsr.mhpmevent      = mhpmevent;
      `endif

      // ------------------------------ Machine Scratch register
      // Scratch register for machine trap handlers.
      // 12'h340 = 12'b0011_0100_0000  Mscratch                               (read-write)
      if (csr_wr & (csr_addr == 12'h340) & (mode == M_MODE))                  // writable in M_MODE
         nxt_mcsr.mscratch = csr_wr_data;
      else
         nxt_mcsr.mscratch = mcsr.mscratch;                                   // keep current value

      // ------------------------------ Machine Exception Program Counter
      // Used by MRET instruction at end of Machine mode trap handler
      // 12'h341 = 12'b0011_0100_0001  Mepc                                   (read-write)   see riscv-privileged p 36
      if ((exception.flag) & (nxt_mode == M_MODE))
         nxt_mcsr.mepc     = exception.pc;                                    // save exception pc - low bit is always 0 (see csr.sv)
      else if (csr_wr & (csr_addr == 12'h341) & (mode == M_MODE))             // writable in M_MODE
         nxt_mcsr.mepc     = csr_wr_data & (mcsr.misa[2] ? ~32'h1 : ~32'h3);  // Software settable - low bit is always 0 (see csr.sv)
      else
         nxt_mcsr.mepc     = mcsr.mepc;                                       // keep current value

      // ------------------------------ Machine Exception Cause
      // 12'h342 = 12'b0011_0100_0010  Mcause                                 (read-write)
      if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mcause   = exception.cause;                                 // save code for exception cause
      else if (csr_wr & (csr_addr == 12'h342) & (mode == M_MODE))             // writable in M_MODE
         nxt_mcsr.mcause   = csr_wr_data;                                     // Sotware settable
      else
         nxt_mcsr.mcause   = mcsr.mcause;                                     // keep current value

      // ------------------------------ Machine Exception Trap Value
      // 12'h343 = 12'b0011_0100_0011  Mtval                                  (read-write)
      //
      if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mtval    = exception.tval;                                  // save trap value for exception
      else if (csr_wr & (csr_addr == 12'h343) & (mode == M_MODE))             // writable in M_MODE
         nxt_mcsr.mtval    = csr_wr_data;                                     // Sotware settable
      else
         nxt_mcsr.mtval    = mcsr.mtval;                                      // keep current value

      // ------------------------------ Machine Interrupt Pending bits
      // 12'h344 = 12'b0011_0100_0100  Mip                                    (read-write)  machine mode
      //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
      // {20'b0, meip, 1'b0, seip, 1'b0, mtip, 1'b0, stip, 1'b0, msip, 1'b0, ssip, 1'b0};

      // Only the bits corresponding to lower-privilege software interrupts (USIP, SSIP), timer interrupts
      // (UTIP, STIP), and external interrupts (UEIP, SEIP) in mip are writable through this CSR address;
      // the remaining bits are read-only.

      // If an interrupt is delegated to privilege mode M by setting a bit in the mideleg register,
      // it becomes visible in the Mip register and is maskable using the Mie register.
      // Otherwise, the corresponding bits in Mip and Mie appear to be hardwired to zero. p 29

      // The machine-level MSIP bits are written by accesses to memory-mapped control registers,
      // which are used by remote harts to provide machine-mode interprocessor interrupts. p. 30
      nxt_mcsr.mip.msip = sw_irq;                                             // msip_reg[] see irq.sv

      // The MTIP bit is read-only and is cleared by writing to the memory-mapped machine-mode timer compare register
      if (mode == M_MODE)                                                     // irq setting during Machine mode
         nxt_mcsr.mip.mtip = timer_irq;
      else
         nxt_mcsr.mip.mtip = mcsr.mip.mtip;                                   // hold last value

      // The MEIP field in mip is a read-only bit that indicates a machine-mode external interrupt is pending. p 30 riscv-privileged.pdf
      if (mode == M_MODE)
         nxt_mcsr.mip.meip = ext_irq;                                         // external interrupt
      else
         nxt_mcsr.mip.meip = mcsr.mip.meip;                                   // keep current value

      // ------------------------------ Machine Protection and Translation

      // 12'h3A0 - 12'h3A3
      `ifdef USE_PMPCFG
         // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                             (read-write)
         if (csr_wr & (csr_addr == 12'h3A0) & (mode == M_MODE))
            nxt_mcsr.pmpcfg0 = csr_wr_data;
         else
            nxt_mcsr.pmpcfg0 = mcsr.pmpcfg0;                                  // keep current value

         // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                             (read-write)
         if (csr_wr & (csr_addr == 12'h3A1) & (mode == M_MODE))
            nxt_mcsr.pmpcfg1 = csr_wr_data;
         else
            nxt_mcsr.pmpcfg1 = mcsr.pmpcfg1;

         // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                             (read-write)
         if (csr_wr & (csr_addr == 12'h3A2) & (mode == M_MODE))
            nxt_mcsr.pmpcfg2 = csr_wr_data;
         else
            nxt_mcsr.pmpcfg2 = mcsr.pmpcfg2;

         // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                             (read-write)
         if (csr_wr && (csr_addr == 12'h3A3) & (mode == M_MODE))
            nxt_mcsr.pmpcfg3 = csr_wr_data;
         else
            nxt_mcsr.pmpcfg3 = mcsr.pmpcfg3;
      `endif

      // 12'h3B0 - 12'h3BF
      // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)

      // NOTE: These PMP registers currently NOT fully implemented!!!!!!!!!!!

      `ifdef PMP_ADDR0
         if (csr_wr & (csr_addr == 12'h3B0) & (mode == M_MODE))
            nxt_mcsr.pmpaddr0 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr0 = mcsr.pmpaddr0;
      `endif
      `ifdef PMP_ADDR1
         if (csr_wr & (csr_addr == 12'h3B1) & (mode == M_MODE))
            nxt_mcsr.pmpaddr1 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr1 = mcsr.pmpaddr1;
      `endif
      `ifdef PMP_ADDR2
         if (csr_wr & (csr_addr == 12'h3B2) & (mode == M_MODE))
            nxt_mcsr.pmpaddr2 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr2 = mcsr.pmpaddr2;
      `endif
      `ifdef PMP_ADDR3
         if (csr_wr & (csr_addr == 12'h3B3) & (mode == M_MODE))
            nxt_mcsr.pmpaddr3 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr3 = mcsr.pmpaddr3;
      `endif
      `ifdef PMP_ADDR4
         if (csr_wr & (csr_addr == 12'h3B4) & (mode == M_MODE))E
            nxt_mcsr.pmpaddr4 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr4 = mcsr.pmpaddr4;
      `endif
      `ifdef PMP_ADDR5
         if (csr_wr & (csr_addr == 12'h3B5) & (mode == M_MODE))
            nxt_mcsr.pmpaddr5 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr5 = mcsr.pmpaddr5;
      `endif
      `ifdef PMP_ADDR6
         if (csr_wr & (csr_addr == 12'h3B6) & (mode == M_MODE))
            nxt_mcsr.pmpaddr6 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr6 = mcsr.pmpaddr6;
      `endif
      `ifdef PMP_ADDR7
         if (csr_wr & (csr_addr == 12'h3B7) & (mode == M_MODE))
            nxt_mcsr.pmpaddr7 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr7 = mcsr.pmpaddr7;
      `endif
      `ifdef PMP_ADDR8
         if (csr_wr & (csr_addr == 12'h3B8) & (mode == M_MODE))
            nxt_mcsr.pmpaddr8 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr8 = mcsr.pmpaddr8;
      `endif
      `ifdef PMP_ADDR9
         if (csr_wr & (csr_addr == 12'h3B9) & (mode == M_MODE))
            nxt_mcsr.pmpaddr9 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr9 = mcsr.pmpaddr9;
      `endif
      `ifdef PMP_ADDR10
         if (csr_wr & (csr_addr == 12'h3BA) & (mode == M_MODE))
            nxt_mcsr.pmpaddr10 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr10 = mcsr.pmpaddr10;
      `endif
      `ifdef PMP_ADDR11
         if (csr_wr & (csr_addr == 12'h3BB) & (mode == M_MODE))
            nxt_mcsr.pmpaddr11 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr11 = mcsr.pmpaddr11;
      `endif
      `ifdef PMP_ADDR12
         if (csr_wr & (csr_addr == 12'h3BC) & (mode == M_MODE))
            nxt_mcsr.pmpaddr12 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr12 = mcsr.pmpaddr12;
      `endif
      `ifdef PMP_ADDR13
         if (csr_wr & (csr_addr == 12'h3BD) & (mode == M_MODE))
            nxt_mcsr.pmpaddr13 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr13 = mcsr.pmpaddr13;
      `endif
      `ifdef PMP_ADDR14
         if (csr_wr & (csr_addr == 12'h3BE) & (mode == M_MODE))
            nxt_mcsr.pmpaddr14 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr14 = mcsr.pmpaddr14;
      `endif
      `ifdef PMP_ADDR15
         if (csr_wr & (csr_addr == 12'h3BF) & (mode == M_MODE))
            nxt_mcsr.pmpaddr15 = csr_wr_data;
         else
            nxt_mcsr.pmpaddr15 = mcsr.pmpaddr15;
      `endif

      `ifdef add_DM
      // Debug Write registers
      // NOTE: These PMP registers currently NOT fully implemented!!!!!!!!!!!

      // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
         if (csr_wr & (csr_addr == 12'h7A0) & (mode >= M_MODE))               // writable in M_MODE
            nxt_mcsr.tselect     = csr_wr_data;                               // change Trigger Select Register
         else
            nxt_mcsr.tselect     = mcsr.tselect;                              // keep current value

         if (csr_wr & (csr_addr == 12'h7A1) & (mode >= M_MODE))               // writable in M_MODE
            nxt_mcsr.tdata1      = csr_wr_data;                               // change Trigger Data Register 1
         else
            nxt_mcsr.tdata1      = mcsr.tdata1;                               // keep current value

         if (csr_wr & (csr_addr == 12'h7A2) & (mode >= M_MODE))               // writable in M_MODE
            nxt_mcsr.tdata2      = csr_wr_data;                               // change Trigger Data Register 2
         else
            nxt_mcsr.tdata2      = mcsr.tdata2;                               // keep current value

         if (csr_wr & (csr_addr == 12'h7A3) & (mode >= M_MODE))               // writable in M_MODE
            nxt_mcsr.tdata3      = csr_wr_data;                               // change Trigger Data Register 3
         else
            nxt_mcsr.tdata3      = mcsr.tdata3;                               // keep current value

         // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
         // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
         if (csr_wr & (csr_addr == 12'h7B0) & Dbg_mode)                       // writable in Debug MODE
            nxt_mcsr.dcsr        = csr_wr_data;                               // change Debug Control and Status Register
         else
            nxt_mcsr.dcsr        = mcsr.dcsr;                                 // keep current value

         if (csr_wr & (csr_addr == 12'h7B1) & Dbg_mode)                       // writable in Debug MODE
            nxt_mcsr.dpc         = csr_wr_data;                               // change Debug PC Register
         else
            nxt_mcsr.dpc         = mcsr.dpc;

         if (csr_wr & (csr_addr == 12'h7B2) & Dbg_mode)                       // writable in Debug MODE
            nxt_mcsr.dscratch0   = csr_wr_data;                               // change Debug Scratch Register 0
         else
            nxt_mcsr.dscratch0   = mcsr.dscratch0;

         if (csr_wr & (csr_addr == 12'h7B3) & Dbg_mode)                       // writable in Debug MODE
            nxt_mcsr.dscratch1   = csr_wr_data;                               // change Debug Scratch Register 1
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
      if (csr_wr && (csr_addr == 12'hB00))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB80))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {csr_wr_data,mcsr.mcycle_lo};
      else if (!mcsr.mcountinhibit[0])
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = 2*RSZ ' ({mcsr.mcycle_hi,mcsr.mcycle_lo} + 'd1);  // increment counter/timer - cast result to 2*RSZ bits before assigning
      else
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,mcsr.mcycle_lo};        // keep current value

      // ------------------------------ Machine Instructions-Retired Counter
      // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
      // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf
      // Lower 32 bits of minstret, RV32I only.
      // 12'hB02 = 12'b1011_0000_0010  minstret_lo                            (read-write)
      //
      // Upper 32 bits of minstret, RV32I only.
      // 12'hB82 = 12'b1011_1000_0010  minstret_hi                            (read-write)
      //
      if (csr_wr && (csr_addr == 12'hB02))                                    // writable in M_MODE
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB82))                               // writable in M_MODE
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {csr_wr_data,mcsr.minstret_lo};
      else if (!mcsr.mcountinhibit[2])
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = 2*RSZ ' ({mcsr.minstret_hi,mcsr.minstret_lo} + total_retired);    // cast result to 2*RSZ bits before assigning
      else
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,mcsr.minstret_lo}; // keep current value

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
      // 12'hF11 = 12'b1111_0001_0001  Mvendorid   (read-only)
      nxt_mcsr.mvendorid = M_VENDOR_ID;

      // Architecture ID
      // 12'hF12 = 12'b1111_0001_0010  Marchid     (read-only)
      nxt_mcsr.marchid  = M_ARCH_ID;

      // Implementation ID
      // 12'hF13 = 12'b1111_0001_0011  Mimpid      (read-only)
      nxt_mcsr.mimpid   = M_IMP_ID;

      // Hardware Thread ID
      // 12'hF14 = 12'b1111_0001_0100  Mhartid     (read-only)
      nxt_mcsr.mhartid  = M_HART_ID;
      // ==================================================================== Supervisor Mode Registers ==============================================================
      `ifdef ext_S
         nxt_scsr    = '{default: '0};    // defaults unless overrriden

         // ------------------------------ Supervisor Status Register
         // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
         //                   31    30:23 22    21    20     19    18    17     16:15 14:13 12:11    10:9   8        7    6     5         4         3     2     1        0
         nxt_scsr.sstatus  = {                                                                             nxt_spp, 1'b0, 1'b0, nxt_spie, nxt_upie, 1'b0, 1'b0, nxt_sie, nxt_uie}; // see csr.sv

         if (exception.flag & (nxt_mode == S_MODE))
            nxt_scsr.sstatus.spp = mode[0];                                   // spp = Supervisor Prevous Privileged mode
         else if (sret)                                                       // Note: S mode implies there's a U-mode because S mode is not allowed unless U is supported
            nxt_scsr.sstatus.spp = 1'b0;                                      // "and xPP is set to U (or M if user-mode is not supported)." p. 20 riscv-privileged-v1.10
         else
            nxt_scsr.sstatus.spp = scsr.sstatus.spp;                          // hold current value
         nxt_spp    = nxt_scsr.sstatus.spp;

         if (exception.flag & (nxt_mode == S_MODE))
            nxt_scsr.sstatus.spie = scsr.sstatus.sie;                         // spie <= sie
         else if (sret)
            nxt_scsr.sstatus.spie = TRUE;                                     // "xPIE is set to 1"
         else
            nxt_scsr.sstatus.spie = scsr.sstatus.spie;                        // keep current value
         nxt_spie   = nxt_scsr.sstatus.spie;

         // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
         //       or cleared with a single CSR instruction.
         if (exception.flag & (nxt_mode == S_MODE))
            nxt_scsr.sstatus.sie = 1'b0;
         else if (sret)                                                       // "xIE is set to xPIE;"
            nxt_scsr.sstatus.sie = scsr.sstatus.spie;
         else if (csr_wr & (csr_addr[8:0] == 9'h100) & (mode >=S_MODE))       // writable in M or S mode
            nxt_scsr.sstatus.sie = csr_wr_data[1];
         else
            nxt_scsr.sstatus.sie = scsr.sstatus.sie;                          // keep current value
         nxt_sie    = nxt_scsr.sstatus.sie;

         // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
         // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged
         `ifdef ext_N
            // ------------------------------ Supervisor exception delegation register
            // 12'h102 = 12'b0001_0000_0010  sedeleg                          (read-write)
            if (csr_wr & (csr_addr[8:0] == 9'h102) & (mode >= S_MODE))        // writable in mode >= S_MODE
               nxt_scsr.sedeleg  = csr_wr_data;
            else
               nxt_scsr.sedeleg  = scsr.sedeleg;                              // keep current value

            // ------------------------------ Supervisor interrupt delegation register
            // 12'h103 = 12'b0001_0000_0011  sideleg                          (read-write)
            if (csr_wr & (csr_addr[8:0] == 9'h103) & (mode >= S_MODE))        // writable in mode >= S_MODE
               nxt_scsr.sideleg  = csr_wr_data;
            else
               nxt_scsr.sideleg  = scsr.sideleg;                              // keep current value
         `endif // ext_N

         // ------------------------------ Supervisor Interrupt-Enable register.
         // 12'h104 = 12'b0001_0000_0100  sie                                 (read-write)
         nxt_scsr.sie         = scsr.sie;                                     // keep current value unless written to
         if (csr_wr & (csr_addr[8:0] == 9'h104) & (mode >= S_MODE))           // writable in mode >= S_MODE
         begin
            nxt_scsr.sie.ssie   = csr_wr_data[1];
            nxt_scsr.sie.stie   = csr_wr_data[5];
            nxt_scsr.sie.seie   = csr_wr_data[9];
         end

         // ------------------------------ Supervisor trap handler base address
         // 12'h105 = 12'b0001_0000_0101  stvec                               (read-write)
         if (csr_wr & (csr_addr[8:0] == 9'h105) & (mode >= S_MODE))           // writable in mode >= S_MODE
            nxt_scsr.stvec = csr_wr_data;                                     // see csr.sv - value written may be masked going into register
         else
            nxt_scsr.stvec = scsr.stvec;

         // 12/31/202 - Andrew Waterman "scounteren only exists if S Mode is implemented"
         // ------------------------------ Supervisor Counter Enable
         // 12'h106 = 12'b0001_0000_0110  scounteren                          (read-write)
         if (csr_wr & (csr_addr[8:0] == 9'h106) & (mode >= S_MODE))           // writable in mode >= S_MODE
            nxt_scsr.scounteren = csr_wr_data;
         else
            nxt_scsr.scounteren = scsr.scounteren;                            // keep current value

         // ------------------------------ Supervisor Scratch register
         // Scratch register for supervisor trap handlers.
         // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
         if (csr_wr & (csr_addr[8:0] == 9'h140) & (mode >= S_MODE))           // writable in mode >= S_MODE
            nxt_scsr.sscratch = csr_wr_data;
         else
            nxt_scsr.sscratch = scsr.sscratch;                                // keep current value

         // ------------------------------ Supervisor Exception Program Counter
         // 12'h141 = 12'b0001_0100_0001  sepc                                (read-write)
         if ((exception.flag) & (nxt_mode == S_MODE))
            nxt_scsr.sepc  = exception.pc;                                    // save exception pc - low bit is always 0 (see csr.sv)
         else if (csr_wr & (csr_addr[8:0] == 9'h141) & (mode >= S_MODE))      // writable in mode >= S_MODE
            nxt_scsr.sepc  = csr_wr_data & (mcsr.misa[2] ? ~32'h1 : ~32'h3);  // Software settable  - low bit is always 0 (see csr.sv)
         else
            nxt_scsr.sepc  = scsr.sepc;                                       // keep current value

         // ------------------------------ Supervisor Exception Cause
         // 12'h142 = 12'b0001_0100_0010  scause                              (read-write)
         if (exception.flag & (nxt_mode == S_MODE))
            nxt_scsr.scause   = exception.cause;                              // save code for exception cause
         else if (csr_wr & (csr_addr[8:0] == 9'h142) & (mode >= S_MODE))      // writable in mode >= S_MODE
            nxt_scsr.scause   = csr_wr_data[3:0];                             // Sotware settable - currently scause is only 4 bits wide
         else
            nxt_scsr.scause   = scsr.scause;                                  // keep current value


         // ------------------------------ Supervisor Exception Trap Value    see p 9,30,67 riscv-privileged.pdf 1.12-draft
         // 12'h143 = 12'b0001_0100_0011  stval                               (read-write)
         if (exception.flag & (nxt_mode == S_MODE))
            nxt_scsr.stval    = exception.tval;                               // save code for exception cause
         else if (csr_wr & (csr_addr[8:0] == 9'h143) & (mode >= S_MODE))      // writable in mode >= S_MODE
            nxt_scsr.stval    = csr_wr_data;                                  // Sotware settable
         else
            nxt_scsr.stval    = scsr.stval;                                   // keep current value

         // ------------------------------ Supervisor Interrupt Pending
         // 12'h144 = 12'b0001_0100_0100  sip                                 (read-write)
         // uip = mip & MASK -> see csr.sv

         // If implemented, SEIP is read-only in sip, and is set and cleared by the
         // execution environment, typically through a platform-specific interrupt controller. see p 63 riscv-privileged 1.12-draft
         if (sw_irq)
            nxt_scsr.sip.ssip = TRUE;                                         // software interrupt = msip_reg[] see irq.sv
         else
            nxt_scsr.sip.ssip = scsr.sip.ssip;

         // f implemented, STIP is read-only in sip, and is set and cleared by the execution environment. see p 63 riscv-privileged 1.12-draft
         if (mode == S_MODE)
            nxt_scsr.sip.stip = timer_irq;                                    // timer interrupt
         else
            nxt_scsr.sip.stip = scsr.sip.stip;

         // If implemented, SSIP is writable in sip.... p. 63 riscv-privileged.pdf 1.12-draft
         if (csr_wr & (csr_addr == 12'h344) & (mode == M_MODE))
            nxt_scsr.sip.seip = csr_wr_data[9];
         else if (mode == S_MODE)
            nxt_scsr.sip.seip = ext_irq;                                      // external interrupt
         else
            nxt_scsr.sip.seip = scsr.sip.seip;                                // keep current value

         // ------------------------------ Supervisor Protection and Translation
         // Supervisor address translation and protection.
         // 12'h180 = 12'b0001_1000_0000  satp                                (read-write)
         if (csr_wr & (csr_addr[8:0] == 9'h180) & (mode >= S_MODE))           // writable in mode >= S_MODE
            nxt_scsr.satp = csr_wr_data;
         else
            nxt_scsr.satp = scsr.satp;                                        // keep current value
      `endif // ext_S

      `ifdef ext_U
      // ==================================================================== User Mode Registers ====================================================================
         `ifdef ext_F
            // ------------------------------ User Floating-Point CSRs
            // 12'h001 - 12'h003
            if (csr_wr & (csr_addr == 12'h001))
               nxt_ucsr.???? = ???
            else
               nxt_ucsr.???? = ucsr.????
      
            if (csr_wr & (csr_addr == 12'h002))
               nxt_ucsr.???? = ???
            else
               nxt_ucsr.???? = ucsr.????
      
            if (csr_wr & (csr_addr == 12'h003))
               nxt_ucsr.???? = ???
            else
               nxt_ucsr.???? = ucsr.????
            `endif   // ext_F
         `ifdef ext_N
            nxt_ucsr    = '{default: '0};

            // ------------------------------ User Status Register
            // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
            //                   31:5  4         3     2     1     0
            nxt_ucsr.ustatus  = {      nxt_upie, 1'b0, 1'b0, 1'b0, nxt_uie}; // see csr.sv

            // p. 21. To support nested traps, each privilege mode x has a two-level stack of interrupt-enable
            //        bits and privilege modes. xPIE holds the value of the interrupt-enable bit active
            //        prior to the trap, and xPP holds the previous privilege mode.

            // p. 21  When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE;
            //        xIE is set to 0; and xPP is set to y.

            // p. 21  The MRET, SRET, or URET instructions are used to return from traps in M-mode, S-mode, or
            //        U-mode respectively. When executing an xRET instruction, supposing xPP holds the value y, xIE
            //        is set to xPIE; the privilege mode is changed to y; xPIE is set to 1; and xPP is set to U (or M if
            //        user-mode is not supported).
            if (exception.flag & (nxt_mode == U_MODE))
               nxt_ucsr.ustatus.upie  = ucsr.ustatus.uie;
            else if (uret)
               nxt_ucsr.ustatus.upie  = 1'b1;
            else
               nxt_ucsr.ustatus.upie  = ucsr.ustatus.upie;                    // keep current value... get this from corresponding mstatus bit
            nxt_upie   = nxt_ucsr.ustatus.upie;

            // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
            //       or cleared with a single CSR instruction.
            if (exception.flag & (nxt_mode == U_MODE))
               nxt_ucsr.ustatus.uie  = 1'b0;
            else if (uret)
               nxt_ucsr.ustatus.uie  = ucsr.ustatus.upie;                     // "xIE is set to xPIE;"  p. 21 riscv-privileged.pdf
            else if (csr_wr && (csr_addr[7:0] == 8'h00))                      // writable in all modes
               nxt_ucsr.ustatus.uie  = csr_wr_data[0];
            else
               nxt_ucsr.ustatus.uie  = ucsr.ustatus.uie;                      // hold last value
            nxt_uie    = nxt_ucsr.ustatus.uie;   // need by mstatus


            // ------------------------------ User Interrupt-Enable Register
            // 12'h004 = 12'b0000_0000_0100  uie                              (read-write)  user mode
            if (csr_wr & (csr_addr[7:0] == 8'h04))                            // writable in all modes
            begin
               nxt_ucsr.uie.usie   = csr_wr_data[0];
               nxt_ucsr.uie.utie   = csr_wr_data[4];
               nxt_ucsr.uie.ueie   = csr_wr_data[8];
            end

            // ------------------------------ User Trap Handler Base address
            // 12'h005 = 12'b0000_0000_0101  utvec                            (read-write)  user mode
            if (csr_wr & (csr_addr[7:0] == 8'h05))                            // writable in all modes
               nxt_ucsr.utvec = csr_wr_data;                                  // see csr.sv - value written may be masked going into register
            else
               nxt_ucsr.utvec = ucsr.utvec;                                   // keep current value

            // ------------------------------ User Trap Handling
            // Scratch register for user trap handlers.
            // 12'h040 = 12'b0000_0100_0000  uscratch                         (read-write)
            if (csr_wr & (csr_addr[7:0] == 8'h40))                            // writable in all modes
               nxt_ucsr.uscratch = csr_wr_data;
            else
               nxt_ucsr.uscratch = ucsr.uscratch;                             // keep current value

            // ------------------------------ User Exception Program Counter
            // 12'h041 = 12'b0000_0100_0001  uepc                             (read-write)
            if (exception.flag & (nxt_mode == U_MODE))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_ucsr.uepc     = exception.pc;                              // save exception pc - low bit is always 0 (see csr.sv)
            else if (csr_wr & (csr_addr[7:0] == 8'h41))                       // writable in all modes
               nxt_ucsr.uepc     = csr_wr_data & (mcsr.misa[2] ? ~32'h1 : ~32'h3);  // Software settable - low bit is always 0 (see csr.sv)
            else
               nxt_ucsr.uepc     = ucsr.uepc;                                 // keep current value

            // ------------------------------ User Exception Cause
            // 12'h042 = 12'b0000_0100_0010  ucause                           (read-write)
            if (exception.flag & (nxt_mode == U_MODE))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_ucsr.ucause   = exception.cause;                           // save code for exception cause
            else if (csr_wr && (csr_addr[7:0] == 8'h42))                      // writable in all modes
               nxt_ucsr.ucause   = csr_wr_data[3:0];                          // Sotware settable
            else
               nxt_ucsr.ucause   = ucsr.ucause;                               // keep current value

            // ------------------------------ User Exception Trap Value       see p 8m 115 riscv-privileged.pdf 1.12-draft
            // 12'h043 = 12'b0000_0100_0011  utval                            (read-write)
            if (exception.flag & (nxt_mode == U_MODE))                        // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_ucsr.utval    = exception.tval;                            // save code for exception cause
            else if (csr_wr && (csr_addr[7:0] == 8'h43))                      // writable in all modes
               nxt_ucsr.utval    = csr_wr_data;                               // Sotware settable
            else
               nxt_ucsr.utval    = ucsr.utval;                                // keep current value

            // ------------------------------ User Interrupt Pending
            // 12'h044 = 12'b0000_0100_0100  uip                              (read-write)

            // All bits besides USIP in the uip register are read-only. riscv-privileged draft 1.12  p 114
            if (csr_wr & (csr_addr[7:0] == 8'h44))                            // writable in any mode
               nxt_ucsr.uip.usip = csr_wr_data[0];
            else if (sw_irq)
               nxt_ucsr.uip.usip = TRUE;                                      // software interrupt = msip_reg[] see irq.sv
            else
               nxt_ucsr.uip.usip = ucsr.uip.usip;                             // keep current value

            if (mode == U_MODE)
               nxt_ucsr.uip.utip = timer_irq;                                 // timer interrupt
            else
               nxt_ucsr.uip.utip = ucsr.uip.utip;                             // otherwise hold last value

            if (mode == U_MODE)
               nxt_ucsr.uip.ueip = ext_irq;                                   // external interrupt
            else
               nxt_ucsr.uip.ueip = ucsr.uip.ueip;                             // keep current value
         `endif // ext_N
      `endif // ext_U
   end // always_comb

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors & Counters

   `ifdef use_MHPM
   genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
   generate
      for (n = 0; n < NUM_MHPM; n++)
      begin : MHPM_CNTR_EVENTS
         always_comb
         begin
            // Machine hardware performance-monitoring event selectors mhpmevent3 - mhpmevent31
            // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                    (read-write)
            if (csr_wr && (csr_addr == 12'h323+n))                       // writable in M_MODE
               mhpmevent[n]    = csr_wr_data[EV_SEL_SZ-1:0];                  // write to this event register to change which event is selected
            else
               mhpmevent[n]    = mcsr.mhpmevent[n];                           // keep current value it

            // Machine hardware performance-monitoring counters
            // increment mhpmcounter[] if the Event Selector is not 0 and the corresponding mcountinhibit[] bit is not set.
            // currently there are 24 possible hpm_events[], where event[0] = 0
            // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31                (read-write)
            //
            // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h               (read-write)
            if (csr_wr && (csr_addr == (12'hB03+n)))                     // writable in M_MODE
               {mhpmcounter_hi[n], mhpmcounter_lo[n]} = {mcsr.mhpmcounter_hi[n],csr_wr_data};
            else if (csr_wr && (csr_addr == (12'hB83+n)))                     // writable in M_MODE
               {mhpmcounter_hi[n], mhpmcounter_lo[n]} = {csr_wr_data,mcsr.mhpmcounter_lo[n]};
            else
               {mhpmcounter_hi[n], mhpmcounter_lo[n]}  = mcsr.mcountinhibit[n+3] ? {mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} :
                                                                                             2*RSZ ' ({mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} + hpm_events[mcsr.mhpmevent[n]]); // cast result to 2*RSZ bits before assigning
         end
      end
   endgenerate
   `endif // use_MHPM

endmodule
