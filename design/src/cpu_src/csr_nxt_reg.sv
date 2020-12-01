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

   EV_EXC_intf.slave             EV_EXC_bus,

   input    logic          [1:0] mode,
   input    logic          [1:0] nxt_mode,

   `ifdef ext_U
   input    logic                uret,
   UCSR_REG_intf.slave           ucsr,          // all of the User mode Control & Status Registers
   UCSR_REG_intf.master          nxt_ucsr,      // all of the next User mode Control & Status Registers
   `endif

   `ifdef ext_S
   input    logic                sret,
   SCSR_REG_intf.slave           scsr,          // all of the Supervisor mode Control & Status Registers
   SCSR_REG_intf.master          nxt_scsr,      // all of the next Supervisor mode Control & Status Registers
   `endif

   input    logic                mret,
   MCSR_REG_intf.slave           mcsr,          // all of the Machine mode Control & Status Registers
   MCSR_REG_intf.master          nxt_mcsr       // all of the next Machine mode Control & Status Registers
);
   EVENTS                  current_events;
   EXCEPTION               exception;

   assign current_events   = EV_EXC_bus.current_events;
   assign exception        = EV_EXC_bus.exception;

   logic sd, tsr, tw, tvm, mxr, sum, mprv;
   logic [1:0] xs, fs, mpp;
   logic mpie, mie;
   logic spp, spie, sie;
   logic upie, uie;

   assign sd      = 1'b0;
   assign tsr     = 1'b0;
   assign tw      = 1'b0;
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
         nxt_mpp <= 2'b11;                                              // mpp = Machine Prevous Privileged mode
      else if (exception.flag & (nxt_mode == M_MODE))                   // holds the previous privilege mode
         nxt_mpp  = mode;                                               // When a trap is taken from privilege mode y into privilege mode x, ... and xPP is set to y.
      else if (mret)
         `ifdef ext_U
         nxt_mpp  = 2'b00;                                              // "and xPP is set to U (or M if user-mode is not supported)." p. 21 riscv-privileged.pdf
         `else
         nxt_mpp  = 2'b11;
         `endif
      else if (csr_wr & (csr_addr == 12'h300) & (mode == M_MODE))
         nxt_mpp <= csr_wr_data[12:11];
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

   // ------------------------------ Supervisor Status Register bits
   // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
   `ifdef ext_S
   `ifdef ext_N
   always_comb // must be equivalent logic in csr_super_wr_reg.sv
   begin
      if (reset_in)
         nxt_spp = 1'b0;                                                // spp = User?
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_spp = mode[0];                                             // spp = Supervisor Prevous Privileged mode
      else if (sret)                                                    // Note: S mode implies there's a U-mode because S mode is not allowed unless U is supported
         nxt_spp = 1'b0;                                                // "and xPP is set to U (or M if user-mode is not supported)." p. 20 riscv-privileged-v1.10
      else
         nxt_spp = mcsr.mstatus.spp;                                    // spp

      if (reset_in)                                                     // spie
         nxt_spie = 'd0;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_spie = sie;                                                // spie <= sie
      else if (sret)
         nxt_spie = TRUE;                                               // "xPIE is set to 1"
      else
         nxt_spie = mcsr.mstatus.spie;                                  // spie

      // p. 20 The xIE bits are located in the low-order bits of mstatus, allowing them to be atomically set
      //       or cleared with a single CSR instruction.
      if (reset_in)
         nxt_sie = FALSE;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_sie = 'd0;
      else if (sret)                                                    // "xIE is set to xPIE;"
         nxt_sie = mcsr.mstatus.spie;
      else if (csr_wr && (csr_addr == 12'h100) && (nxt_mode >= S_MODE))
         nxt_sie = csr_wr_data[1];
      else
         nxt_sie = mcsr.mstatus.sie;
   end
   `else
   assign nxt_spp    = 1'b0;
   assign nxt_spie   = 1'b0;
   assign nxt_sie    = 1'b0;
   `endif // ext_N
   `else
   assign nxt_spp    = 1'b0;
   assign nxt_spie   = 1'b0;
   assign nxt_sie    = 1'b0;
   `endif

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
      assign nxt_upp    = 1'b0;
      assign nxt_upie   = 1'b0;
      assign nxt_uie    = 1'b0;
      `endif // ext_N
   `else // !ext_N
   assign nxt_upp    = 1'b0;
   assign nxt_upie   = 1'b0;
   assign nxt_uie    = 1'b0;
   `endif // ext_U

   logic nxt_usip, nxt_utip, nxt_ueip;
   `ifdef ext_U
      `ifdef ext_N
      // User Interrupt-Pending Register bits
      always_comb
      begin
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
         else if (mode == S_MODE)                                           // irq setting during supervisor mode
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
      end
      `else // !ext_N
      assign nxt_usip = FALSE;
      assign nxt_utip = FALSE;
      assign nxt_ueip = FALSE;
      `endif // etx_N
   `else // !ext_U
   assign nxt_usip = FALSE;
   assign nxt_utip = FALSE;
   assign nxt_ueip = FALSE;
   `endif // etx_U

   always_comb
   begin
      case(csr_addr)
         `ifdef ext_U
         // ==================================================================== User Mode Registers ====================================================================

         // ------------------------------ User Status Register
         // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
         // ustatus = mstatus & MASK - see cntrl_status_regs.sv

         `ifdef ext_F
         // ------------------------------ User Floating-Point CSRs
         // 12'h001 - 12'h003
         12'h001:
         begin
            nxt_mcsr.mstatus = ?
         end
         12'h002:
         begin
            nxt_mcsr.mstatus = ?
         end
         12'h003:
         begin
            nxt_mcsr.mstatus = ?
         end
         `endif   // ext_F

         `ifdef ext_N
         // ------------------------------ User Interrupt-Enable Register
         // 12'h004 = 12'b0000_0000_0100  uie         (read-write)  user mode
         12'h004: nxt_ucsr.uie = csr_wr_data;
         `endif // ext_N

         // ------------------------------ User Trap Handler Base address.
         // 12'h005 = 12'b0000_0000_0101  utvec       (read-write)  user mode
         12'h005: nxt_ucsr.utvec = csr_wr_data;

         // ------------------------------ User Trap Handling
         // Scratch register for user trap handlers.
         // 12'h040 = 12'b0000_0100_0000  uscratch    (read-write)
         12'h040: nxt_ucsr.uscratch = csr_wr_data;

         // ------------------------------ User exception program counter.
         // 12'h041 = 12'b0000_0100_0001  uepc        (read-write)
         //
         // see always_comb logic further below

         // ------------------------------ User exception program counter.
         // 12'h042 = 12'b0000_0100_0010  ucause      (read-write)
         //
         // see always_comb logic further below

         // ------------------------------ User Trap Value - bad address or instruction.
         // 12'h043 = 12'b0000_0100_0011  utval       (read-write)
         //
         // see always_comb logic further below

         `ifdef ext_N
         // ------------------------------ User interrupt pending.
         // 12'h044 = 12'b0000_0100_0100  uip         (read-write)
         // uip = mip & MASK -> see cntrl_st
         `endif // ext_N

         `endif // ext_U


         `ifdef ext_S
         // ==================================================================== Supervisor Mode Registers ==============================================================

         // ------------------------------ Supervisor Status Register
         // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
         // sstats = mstatus & MASK - see cntrl_status_regs.sv

         // ------------------------------ Supervisor exception delegation register.
         // 12'h102 = 12'b0001_0000_0010  sedeleg     (read-write)
         12'h102: nxt_scsr.sedeleg = csr_wr_data;

         `ifdef ext_N
         // ------------------------------ Supervisor interrupt delegation register.
         // 12'h103 = 12'b0001_0000_0011  sideleg     (read-write)
         12'h103: nxt_scsr.sideleg = csr_wr_data;

         // ------------------------------ Supervisor interrupt-enable register.
         // 12'h104 = 12'b0001_0000_0100  sie         (read-write)
         12'h104: nxt_scsr.sie = csr_wr_data;
         `endif // ext_N

         // ------------------------------ Supervisor trap handler base address.
         // 12'h105 = 12'b0001_0000_0101  stvec       (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h105: nxt_scsr.stvec = csr_wr_data;

         // ------------------------------ Supervisor counter enable.
         // 12'h106 = 12'b0001_0000_0110  scounteren  (read-write)
         12'h106: nxt_scsr.scounteren = csr_wr_data;  // see csr_rd_cntr_tmr.svh

         // ------------------------------ Supervisor Scratch register
         // Scratch register for supervisor trap handlers.
         // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
         12'h140: nxt_scsr.sscratch = csr_wr_data;

         // ------------------------------ Supervisor Exception Program Counter
         // 12'h141 = 12'b0001_0100_0001  sepc        (read-write)
         //
         // see always_comb logic further below

         // ------------------------------ Supervisor Exception Cause
         // 12'h142 = 12'b0001_0100_0010  scause      (read-write)
         //
         // see always_comb logic further below

         // ------------------------------ Supervisor Exception Trap Value
         // 12'h143 = 12'b0001_0100_0011  stval       (read-write)
         //
         // see always_comb logic further below

         `ifdef ext_N
         // ------------------------------ Supervisor interrupt pending.
         // p. 29 SUPERVISOR mode: The logical-OR of the software-writeable bit and the signal from the external interrupt controller is used to generate external
         // interrupts to the supervisor. When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the rd destination register
         // contains the logical-OR of the software-writable bit and the interrupt signal from the interrupt controller. However, the value used in the  read-modify-write
         // sequence of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt value from the external interrupt controller.

         // 12'h144 = 12'b0001_0100_0100  sip         (read-write)
         //                       31:10   9         8        7:6    5         4         3:2   1         0
         12'h144: nxt_scsr.sip = {22'b0, nxt_seip, nxt_ueip, 2'b0, nxt_stip, nxt_utip, 2'b0, nxt_ssip, nxt_usip};
         `endif // ext_N

         // ------------------------------ Supervisor Protection and Translation
         // Supervisor address translation and protection.
         // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
         12'h180: nxt_scsr.satp = csr_wr_data;
         `endif // ext_S

         // ==================================================================== Machine Mode Registers =================================================================

         // ------------------------------ Machine Status Register
         // Machine status register.
         // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
         //                           31        22   21  20   19   18   17   16:15 14:13  12:11    10:9    8        7         6     5         4         3        2     1        0
         12'h300: nxt_mcsr.mstatus = {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs, nxt_mpp, 2'b0,  nxt_spp, nxt_mpie, 1'b0, nxt_spie, nxt_upie, nxt_mie, 1'b0, nxt_sie, nxt_uie};

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
         12'h301: nxt_mcsr.misa  = MISA;


         // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
         // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

         //!!! NOTE: Don't yet know how to implement all the logic for medeleg and mideleg!!!

         `ifdef ext_S // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
            // Machine exception delegation register
            // 12'h302 = 12'b0011_0000_0010  medeleg                       (read-write)
            12'h302: nxt_mcsr.medeleg  = csr_wr_data;

            // Machine interrupt delegation register
            // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
            12'h303: nxt_mcsr.mideleg  = csr_wr_data;
         `else // !ext_S
            `ifdef ext_U
               `ifdef ext_N
               // Machine exception delegation register
               // 12'h302 = 12'b0011_0000_0010  medeleg                    (read-write)
               12'h302: nxt_mcsr.medeleg  = csr_wr_data;

               // Machine interrupt delegation register
               // 12'h303 = 12'b0011_0000_0011  mideleg                    (read-write)
               12'h303: nxt_mcsr.mideleg  = csr_wr_data;
               `endif
            `endif
         `endif

         `ifdef ext_N
         // ------------------------------ Machine interrupt-enable register
         // 12'h304 = 12'b0011_0000_0100  mie                              (read-write)
         12'h304: nxt_mcsr.mie   = csr_wr_data;
         `endif

         // ------------------------------ Machine trap-handler base address
         // 12'h305 = 12'b0011_0000_0101  mtvec                            (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h305: nxt_mcsr.mtvec = (SET_MCOUNTINHIBIT == 1) ? SET_MCOUNTINHIBIT_BITS : csr_wr_data;

         // ------------------------------ Machine counter enable
         // 12'h306 = 12'b0011_0000_0110  mcounteren                       (read-write)
         12'h306: nxt_mcsr.mcounteren = csr_wr_data;

         // ------------------------------ Machine Counter Setup
         // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
         // 12'h320 = 12'b0011_0010_00000  mcountinhibit                   (read-write)
         12'h320: nxt_mcsr.mcountinhibit = csr_wr_data;

         // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
         // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                    (read-write)
         //
         // see always_comb logic further below


         // ------------------------------ Machine Scratch register
         // Scratch register for machine trap handlers.
         // 12'h340 = 12'b0011_0100_0000  mscratch                         (read-write)
         12'h340: nxt_mcsr.mscratch = csr_wr_data;

         // ------------------------------ Machine Exception Program Counter. Used by MRET instruction at end of Machine mode trap handler
         // 12'h341 = 12'b0011_0100_0001  mepc                             (read-write)   see riscv-privileged p 36
         //
         // see always_comb logic further below


         // ------------------------------ Machine Exception Cause
         // 12'h342 = 12'b0011_0100_0010  mcause                           (read-write)
         //
         // see always_comb logic further below


         // ------------------------------ Machine Exception Trap Value
         // 12'h343 = 12'b0011_0100_0011  mtval                            (read-write)
         //
         // see always_comb logic further below


         `ifdef ext_N
         // ---------------------- Machine Interrupt Pending bits ----------------------
         // 12'h344 = 12'b0011_0100_0100  mip                              (read-write)  machine mode
         12'h344: nxt_mcsr.mip = {20'b0, nxt_meip, 1'b0, nxt_seip, nxt_ueip, nxt_mtip, 1'b0, nxt_stip, nxt_utip, nxt_msip, 1'b0, nxt_ssip, nxt_usip};  // see p 29 riscv-privileged
         `endif

         // ------------------------------ Machine Protection and Translation

         // 12'h3A0 - 12'h3A3
         `ifdef USE_PMPCFG
         // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                          (read-write)
         12'h3A0: nxt_mcsr.pmpcfg0 = csr_wr_data;
         // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                          (read-write)
         12'h3A1: nxt_mcsr.pmpcfg1 = csr_wr_data;
         // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                          (read-write)
         12'h3A2: nxt_mcsr.pmpcfg2 = csr_wr_data;
         // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                          (read-write)
         12'h3A3: nxt_mcsr.pmpcfg3 = csr_wr_data;
         `endif

         // 12'h3B0 - 12'h3BF
         // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
         `ifdef PMP_ADDR0  12'h3B0: nxt_mcsr.pmpaddr0  = csr_wr_data; `endif
         `ifdef PMP_ADDR1  12'h3B1: nxt_mcsr.pmpaddr1  = csr_wr_data; `endif
         `ifdef PMP_ADDR2  12'h3B2: nxt_mcsr.pmpaddr2  = csr_wr_data; `endif
         `ifdef PMP_ADDR3  12'h3B3: nxt_mcsr.pmpaddr3  = csr_wr_data; `endif
         `ifdef PMP_ADDR4  12'h3B4: nxt_mcsr.pmpaddr4  = csr_wr_data; `endif
         `ifdef PMP_ADDR5  12'h3B5: nxt_mcsr.pmpaddr5  = csr_wr_data; `endif
         `ifdef PMP_ADDR6  12'h3B6: nxt_mcsr.pmpaddr6  = csr_wr_data; `endif
         `ifdef PMP_ADDR7  12'h3B7: nxt_mcsr.pmpaddr7  = csr_wr_data; `endif
         `ifdef PMP_ADDR8  12'h3B8: nxt_mcsr.pmpaddr8  = csr_wr_data; `endif
         `ifdef PMP_ADDR9  12'h3B9: nxt_mcsr.pmpaddr9  = csr_wr_data; `endif
         `ifdef PMP_ADDR10 12'h3BA: nxt_mcsr.pmpaddr10 = csr_wr_data; `endif
         `ifdef PMP_ADDR11 12'h3BB: nxt_mcsr.pmpaddr11 = csr_wr_data; `endif
         `ifdef PMP_ADDR12 12'h3BC: nxt_mcsr.pmpaddr12 = csr_wr_data; `endif
         `ifdef PMP_ADDR13 12'h3BD: nxt_mcsr.pmpaddr13 = csr_wr_data; `endif
         `ifdef PMP_ADDR14 12'h3BE: nxt_mcsr.pmpaddr14 = csr_wr_data; `endif
         `ifdef PMP_ADDR15 12'h3BF: nxt_mcsr.pmpaddr15 = csr_wr_data; `endif

         `ifdef add_DM
         // Debug Write registers - INCOMPLETE!!!!!!!!!!!
         // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
         12'h7A0: nxt_mcsr.tselect     = mcsr.tselect;   // Trigger Select Register
         12'h7A1: nxt_mcsr.tdata1      = mcsr.tdata1;    // Trigger Data Register 1
         12'h7A2: nxt_mcsr.tdata2      = mcsr.tdata2;    // Trigger Data Register 2
         12'h7A3: nxt_mcsr.tdata3      = mcsr.tdata3;    // Trigger Data Register 3

         // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
         // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
         12'h7B0: nxt_mcsr.dcsr       = mcsr.dcsr;       // Debug Control and Status Register
         12'h7B1: nxt_mcsr.dpc        = mcsr.dpc;        // Debug PC Register
         12'h7B2: nxt_mcsr.dscratch0  = mcsr.dscratch0;  // Debug Scratch Register 0
         12'h7B3: nxt_mcsr.dscratch1  = mcsr.dscratch1;  // Debug Scratch Register 1
         `endif // add_DM

         // ------------------------------ Machine Machine Cycle Counter
         // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
         // mhpmcountern, respectively. p 34 risvcv-privileged.pdf
         //
         // Lower 32 bits of mcycle, RV32I only.
         // 12'hB00 = 12'b1011_0000_0000  mcycle_lo (read-write)
         //
         // Upper 32 bits of mcycle, RV32I only.
         // 12'hB80 = 12'b1011_1000_0000  mcycle_hi (read-write)
         //
         // see always_comb logic further below


         // ------------------------------ Machine Instructions-Retired Counter
         // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
         // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf
         // Lower 32 bits of minstret, RV32I only.
         // 12'hB02 = 12'b1011_0000_0010  minstret_lo                      (read-write)
         //
         // Upper 32 bits of minstret, RV32I only.
         // 12'hB82 = 12'b1011_1000_0010  minstret_hi                      (read-write)
         //
         // see always_comb logic further below

         // ------------------------------ Machine Hardware Performance-Monitoring Counters
         // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
         // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
         //
         // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
         // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
         //
         // see always_comb logic further below


         // ------------------------------ Machine Information Registers
         // Vendor ID
         // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
         12'hF11: nxt_mcsr.mvendorid = M_VENDOR_ID;

         // Architecture ID
         // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
         12'hF12: nxt_mcsr.marchid  = M_ARCH_ID;

         // Implementation ID
         // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
         12'hF13: nxt_mcsr.mimpid   = M_IMP_ID;

         // Hardware Thread ID
         // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
         12'hF14: nxt_mcsr.mhartid  = M_HART_ID;
      endcase
   end

   `ifdef ext_U
   // ------------------------------ User Exception Program Counter
   // 12'h041 = 12'b0000_0100_0001  uepc                             (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_ucsr.uepc     =  '0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.uepc     = {exception.pc[RSZ-1:1], 1'b0};          // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h041))                      // All modes can write to this CSR
         nxt_ucsr.uepc     = {csr_wr_data[RSZ-1:1], 1'b0};           // Software settable - low bit is always 0
   end

   // ------------------------------ User Exception Cause
   // 12'h042 = 12'b0000_0100_0010  ucause                           (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_ucsr.ucause   =  'b0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.ucause   = exception.cause;                        // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h042))
         nxt_ucsr.ucause   = csr_wr_data;                            // Sotware settable
   end

   // ------------------------------ User Exception Trap Value       see riscv-privileged p. 38-39
   // 12'h043 = 12'b0000_0100_0011  utval                            (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_ucsr.utval    =  'b0;
      else if (exception.flag & (nxt_mode == U_MODE))                // An exception in MEM stage has priority over a csr_wr (in EXE stage)
         nxt_ucsr.utval    = exception.tval;                         // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h043))                      // all modes can write to this CSR
         nxt_ucsr.utval    = csr_wr_data;                            // Sotware settable
   end
   `endif

   `ifdef ext_S
   // ------------------------------ Supervisor Exception Program Counter
   // 12'h141 = 12'b0001_0100_0001  sepc                             (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_scsr.sepc  =  '0;
      else if ((exception.flag) & (nxt_mode == S_MODE))
         nxt_scsr.sepc  = {exception.pc[RSZ-1:1], 1'b0};             // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h141) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.sepc  = {csr_wr_data[RSZ-1:1], 1'b0};              // Software settable - low bit is always 0
   end

   // ------------------------------ Supervisor Exception Cause
   // 12'h142 = 12'b0001_0100_0010  scause                           (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_scsr.scause   =  'b0;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_scsr.scause   = exception.cause;                        // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h142) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.scause   = csr_wr_data;                            // Sotware settable
   end

   // ------------------------------ Supervisor Exception Trap Value                            see riscv-privileged p. 38-39
   // 12'h143 = 12'b0001_0100_0011  stval                            (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_scsr.stval =  'b0;
      else if (exception.flag & (nxt_mode == S_MODE))
         nxt_scsr.stval = exception.tval;                            // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h143) & (mode >= S_MODE))   // Only >= Supervisor mode can write to this CSR
         nxt_scsr.stval = csr_wr_data;                               // Sotware settable
   end
   `endif
   
   // ------------------------------ Machine Exception Program Counter
   always_comb
   begin
      if (reset_in)
         nxt_mcsr.mepc     =  '0;
      else if ((exception.flag) & (nxt_mode == M_MODE))
         nxt_mcsr.mepc     = {exception.pc[RSZ-1:1], 1'b0};          // save exception pc - low bit is always 0
      else if (csr_wr && (csr_addr == 12'h341) & (mode == M_MODE))   // Only Machine mode can write to this CSR
         nxt_mcsr.mepc     = {csr_wr_data[RSZ-1:1], 1'b0};           // Software settable - low bit is always 0
   end

   // ------------------------------ Machine Exception Cause
   always_comb
   begin
      if (reset_in)
         nxt_mcsr.mcause   = 'b0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mcause   = exception.cause;                        // save code for exception cause
      else if (csr_wr && (csr_addr == 12'h342) & (mode == M_MODE))
         nxt_mcsr.mcause   = csr_wr_data;                            // Sotware settable
   end

   // ------------------------------ Machine Exception Trap Value
   always_comb                                       // see riscv-privileged p. 38-39
   begin
      if (reset_in)
         nxt_mcsr.mtval    = 'b0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_mcsr.mtval    = exception.tval;                         // save trap value for exception
      else if (csr_wr && (csr_addr == 12'h343) & (mode == M_MODE))   // Only Machine mode can write to this CSR
         nxt_mcsr.mtval    = csr_wr_data;                            // Sotware settable
   end

   // ------------------------------ Machine Cycle Counter
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // mhpmcountern, respectively. p 34 risvcv-privileged.pdf
   // p 136 "Cycle counter for RDCYCLE instruction"
   always_comb
   begin
      if (reset_in)
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = 'd0;
      else if (csr_wr && (csr_addr == 12'hB00) && (mode == M_MODE))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB80) && (mode == M_MODE))
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {csr_wr_data,mcsr.mcycle_lo};
      else if (!mcsr.mcountinhibit[0])
         {nxt_mcsr.mcycle_hi,nxt_mcsr.mcycle_lo}   = {mcsr.mcycle_hi,mcsr.mcycle_lo} + 'd1;   // increment counter/timer
   end

   // ------------------------------ Machine Instructions-Retired Counter
   logic             tot_retired;      // In this design, at most, 1 instruction can retire per clock cycle

   always_comb
   begin
      if (reset_in)
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = 'd0;
      else if (csr_wr && (csr_addr == 12'hB02) && (mode == 3))
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,csr_wr_data};
      else if (csr_wr && (csr_addr == 12'hB82) && (mode == 3))
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {csr_wr_data,nxt_mcsr.minstret_lo};
      else if (!mcsr.mcountinhibit[2])
         {nxt_mcsr.minstret_hi,nxt_mcsr.minstret_lo}  = {mcsr.minstret_hi,mcsr.minstret_lo} + tot_retired;
   end

    // At most, for this design, only 1 instruction can retire per clock so just OR the retire bits (instead of adding)
   assign tot_retired      = current_events.ret_cnt[LD_RET]  | current_events.ret_cnt[ST_RET]   | current_events.ret_cnt[CSR_RET]  | current_events.ret_cnt[SYS_RET]  |
                             current_events.ret_cnt[ALU_RET] | current_events.ret_cnt[BXX_RET]  | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET] |
                             current_events.ret_cnt[IM_RET]  | current_events.ret_cnt[ID_RET]   | current_events.ret_cnt[IR_RET]   | current_events.ret_cnt[HINT_RET] |
               `ifdef ext_F  current_events.ret_cnt[FLD_RET] | current_events.ret_cnt[FST_RET]  | current_events.ret_cnt[FP_RET]   | `endif
                             current_events.ret_cnt[UNK_RET];

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors & Counters
   // ------------------------------ Machine Hardware Performance-Monitoring Counters
   logic             events[0:23];  // 24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)

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
               nxt_mcsr.mhpmevent[n]    = '0;
            else if (csr_wr && (csr_addr == 12'h323+n) && (mode == M_MODE))
               nxt_mcsr.mhpmevent[n]    = csr_wr_data[EV_SEL_SZ-1:0];   // write to this event register to change which event is selected
            else
               nxt_mcsr.mhpmevent[n]    = mcsr.mhpmevent[n];            // don't change it

            // Machine hardware performance-monitoring counters
            // increment mhpmcounter[] if the Event Selector is not 0 and the corresponding mcountinhibit[] bit is not set.
            // currently there are 24 possible events[], where event[0] = 0
            // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
            //
            // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
            // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
            if (reset_in)
               {nxt_mcsr.mhpmcounter_hi[n], nxt_mcsr.mhpmcounter_lo[n]} = 'd0;
            else if (csr_wr && (csr_addr == (12'hB03+n)) && (mode == M_MODE)) // Andrew Waterman says these are writable in an Apr 8, 2019 post
               {nxt_mcsr.mhpmcounter_hi[n], nxt_mcsr.mhpmcounter_lo[n]} = {mcsr.mhpmcounter_hi[n],csr_wr_data};
            else if (csr_wr && (csr_addr == (12'hB83+n)) && (mode == M_MODE))
               {nxt_mcsr.mhpmcounter_hi[n], nxt_mcsr.mhpmcounter_lo[n]} = {csr_wr_data,mcsr.mhpmcounter_lo[n]};
            else
               {nxt_mcsr.mhpmcounter_hi[n], nxt_mcsr.mhpmcounter_lo[n]}  = mcsr.mcountinhibit[n+3] ? {mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} :
                                                                                                     {mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_lo[n]} + events[mcsr.mhpmevent[n]];
         end
      end
   endgenerate

   // Machine instructions-retired counter.
   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
   logic             br_cnt;
   logic             misaligned_cnt;

   assign br_cnt           = current_events.ret_cnt[BXX_RET] | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET];
   assign misaligned_cnt   = (current_events.e_flag ? current_events.e_cause[0] : 0) |  /* 0 = Instruction Address Misaligned */
                             (current_events.e_flag ? current_events.e_cause[4] : 0) |  /* 4 = Load Address Misaligned        */
                             (current_events.e_flag ? current_events.e_cause[4] : 0);   /* 6 = Store Address Misaligned       */

   assign events[0 ]  = 0;                                        // no change to mhpm counter when this even selected
   // The following events return a count value which is used by a mhpmcounter[]. mhpmcounter[n] can use whichever event[x] it wants by setting mphmevent[n]
   // The count sources (i.e. current_events.ret_cnt[LD_RET]) may be changed by the user to reflect what information they want to use for a given counter.
   // Any of the logic on the RH side of the assignment can changed or used for any events[x] - even new logic can be created for a new event source.
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
   `else
   assign events[20]  = 0;
   assign events[21]  = 0;
   assign events[22]  = 0;
   assign events[23]  = current_events.ext_irq;                   // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
   `endif // uxt_F

   `endif // use_MHPM
   // Note: currently there are NUM_EVENTS events as specified at the beginning of this generate block. The number can be changed if more or less event types are needed

endmodule
