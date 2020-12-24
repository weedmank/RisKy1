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
// File          :  mode_irq.sv
// Description   :  Determines CPU mode, trap_pc, interrupt_flag and interrupt_cause
//               :  Also deterimes the data that will be read from the CSR
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module mode_irq
(
   input    logic                reset_in,
   input    logic                clk_in,

   output   logic          [1:0] mode,
   output   logic          [1:0] nxt_mode,

   input    logic                exception_flag,

   `ifdef ext_U
   input    logic                uret,
   `endif
   `ifdef ext_S
   input    logic                sret,
   `endif
   input    logic                mret,

   output   logic    [PC_SZ-1:2] trap_pc,           // Output: trap vector handler address - connects to WB stage. minimum 2 byte alignment
   `ifdef ext_N
   input    logic                ext_irq,
   output   logic                interrupt_flag,    // Output: 1 = take an interrupt trap - connects to WB stage
   output   logic          [3:0] interrupt_cause,   // Output: value specifying what type of interrupt - connects to WB stage
   `endif

   // only a few of these CSR registers are needed by this module
   `ifdef ext_U
   input var UCSR                  ucsr,              // Input:   current register state of all the User Mode Control & Status Registers
   `endif
   `ifdef ext_S
   input var SCSR                  scsr,              // Input:   current register state of all the Supervisor Mode Control & Status Registers
   `endif
   input var MCSR                  mcsr               // Input:   current register state of all the Machine Mode Control & Status Registers
);

   //----------------------------------------------------------------------------------------------------------------------------
   //------------------------------------- "N" Standard Extension for User_Level Interrupts -------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------

   `ifdef ext_N
      logic          m_irq, s_irq, u_irq;
      logic          usie,ssie,msie,  utie,stie,mtie,  ueie,seie,meie;
      logic          usip,ssip,msip,  utip,stip,mtip,  ueip,seip,meip;

      // csr_mstatus info
      logic       [1:0] mpp;  // from mcsr.mstatus[12:11]
      `ifdef ext_S
      logic             spp;  // from mcsr.mstatus[8]
      `endif

      // ---------------------- Interrupt Enable bits ----------------------
      // see Machine Mode Mie register 12'h304
      `ifdef ext_U
         assign usie = ucsr.uie.usie;           // USIE - User       mode Software Interrupt Enable
         assign utie = ucsr.uie.utie;           // UTIE - User       mode Timer    Interrupt Enable
         assign ueie = ucsr.uie.ueie;           // UEIE - User       mode External Interrupt Enable
      `else
         assign usie = 0;
         assign utie = 0;
         assign ueie = 0;
      `endif

      `ifdef ext_S
         assign ssie = scsr.sie.ssie;           // SSIE - Supervisor mode Software Interrupt Enable
         assign stie = scsr.sie.stie;           // STIE - Supervisor mode Timer    Interrupt Enable
         assign seie = scsr.sie.seie;           // SEIE - Supervisor mode External Interrupt Enable
      `else
         assign ssie = 0;
         assign stie = 0;
         assign seie = 0;
      `endif

      assign msie = mcsr.mie.msie;              // MSIE - Machine    mode Software Interrupt Enable
      assign mtie = mcsr.mie.mtie;              // MTIE - Machine    mode Timer    Interrupt Enable
      assign meie = mcsr.mie.meie;              // MEIE - Machine    mode External Interrupt Enable

      // ---------------------- Interrupt Pending bits ----------------------
      // see Machine Mode Mip register 12'h344
      `ifdef ext_U
         assign usip = ucsr.uip.usip;           // USIP - User       mode Software Interrupt Pending
         assign utip = ucsr.uip.utip;           // UTIP - User       mode Timer    Interrupt Pending
         assign ueip = ucsr.uip.ueip;           // UEIP - User       mode External Interrupt Pending
      `else
         assign usip = 0;
         assign utip = 0;
         assign ueip = 0;
      `endif

      `ifdef ext_S
         assign ssip = scsr.sip.ssip;           // SSIP - Supervisor mode Software Interrupt Pending
         assign stip = scsr.sip.stip;           // STIP - Supervisor mode Timer    Interrupt Pending
         // The logical-OR of the software-writable bit and the signal from the external interrupt
         // controller is used to generate external interrupts to the supervisor. see p 30 riscv-privileged.pdf
         assign seip = scsr.sip.seip & ext_irq; // SEIP - Supervisor mode External Interrupt Pending
      `else
         assign ssip = 0;
         assign stip = 0;
         assign seip = 0;
      `endif

      assign msip = mcsr.mip.msip;              // MSIP - Machine    mode Software Interrupt Pending
      assign mtip = mcsr.mip.mtip;              // MTIP - Machine    mode Timer    Interrupt Pending
      assign meip = mcsr.mip.meip;              // MEIP - Machine    mode External Interrupt Pending

      // ---------------------- IRQs ----------------------
      assign m_irq = (msip & msie) | (mtip & mtie) | (meip & meie);  // any of the machine mode interrupts
      assign s_irq = (ssip & ssie) | (stip & stie) | (seip & seie);  // any of the supervisor mode interrupts
      assign u_irq = (usip & usie) | (utip & utie) | (ueip & ueie);  // any of the user mode interrupts

      // When a hart is executing in privilege mode x, interrupts are globally enabled when xIE=1 and
      // globally disabled when xIE=0. Interrupts for lower-privilege modes, w<x, are always globally
      // disabled regardless of the setting of the lower-privilege mode’s global wIE bit. Interrupts for
      // higher-privilege modes, y>x, are always globally enabled regardless of the setting of the higher privilege
      // mode’s global yIE bit. Higher-privilege-level code can use separate per-interrupt enable
      // bits to disable selected higher-privilege-mode interrupts before ceding control to a lower-privilege
      // mode.   riscv-privileged p 20
      assign interrupt_flag = (mode == 3) ? (mcsr.mstatus.mie & m_irq) : ((mode == 1) ? (m_irq  | (scsr.sstatus.sie & s_irq)) : (m_irq | s_irq | (ucsr.ustatus.uie & u_irq)));

      // determine interrupt cause
      always_comb
      begin
         interrupt_cause = 0;

         // Note: observsation: lower two bits of interrupt_cause are the same as "mode", upper bits are [x:2] -> 0 for SW, 1 for Timer and 2 for External
         case(mode)   // what should the interrupt priority be if multiple interrupts???????????????????????????????????? SW, then Timer, then External ??????????????????
            3:
            begin
               if      (msip & msie) interrupt_cause = 3;      // Machine Mode Software Interrupt
               else if (mtip & mtie) interrupt_cause = 7;      // Machine Mode Timer Interrupt
               else if (meip & meie) interrupt_cause = 11;     // Machine Mode External Interrupt
            end

            `ifdef ext_S
            1:
            begin
               if      (ssip & ssie) interrupt_cause = 1;      // Supervisor Mode Software Interrupt
               else if (stip & stie) interrupt_cause = 5;      // Supervisor Mode Timer Interrupt
               else if (seip & seie) interrupt_cause = 9;      // Supervisor Mode External Interrupt
            end
            `endif

            `ifdef ext_U
            0:
            begin
               if      (usip & usie) interrupt_cause = 0;      // User Mode Software Interrupt
               else if (utip & utie) interrupt_cause = 4;      // User Mode Timer Interrupt
               else if (ueip & ueie) interrupt_cause = 8;      // User Mode External Interrupt
            end
            `endif
         endcase
      end
   `endif // ext_N

   //----------------------------------------------------------------------------------------------------------------------------------------
   //--------------------------------------------------------------- CPU Mode ---------------------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------

   assign mpp = mcsr.mstatus.mpp;
   `ifdef ext_S
   assign spp = scsr.sstatus.spp;
   `endif

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         mode <= M_MODE;          // nxt_mode == 3 during reset_in
      else
         mode <= nxt_mode;
   end

   //----------------------------------------------------------------------------------------------------------------------------------------
   //----------------------------------------------------------- Synchronous Exceptions -----------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------
   // When MODE=Vectored, all synchronous exceptions into supervisor mode cause the pc to be set to the address in the BASE field,
   // whereas interrupts cause the pc to be set to the address in the BASE field plus four times the interrupt cause number.
   // For example, a supervisor-mode timer interrupt (see Table 4.2) causes the  pc to be set to BASE+0x14.
   // Setting MODE=Vectored may impose a stricter alignment constraint on BASE.
   logic             [3:0] cause;
   logic         [RSZ-1:0] tvec;
   logic                   mdlg,sdlg;

   assign cause = mcsr.mcause[3:0];

   always_comb
   begin
      tvec        = RESET_VECTOR_ADDR;    // This should not get used. It should be set/overrriden by being set in code below to a valid location

      // By default, all traps at any privilege level are handled in machine mode, though a machine-mode
      // handler can redirect traps back to the appropriate level with the MRET instruction
      nxt_mode    = mode;                 // no change from last clock cycle, unless code below changes it

      mdlg        = FALSE;                // default flag is that no delegation will take place
      sdlg        = FALSE;

      if (exception_flag)                 // higher priority than interrupts
      begin
         mdlg     = mcsr.medeleg[cause];  // Machine    delegation bit based on mcause
         `ifdef ext_S
         sdlg     = scsr.sedeleg[cause];  // Supervisor delegation bit based on mcause
         `endif
      end
      `ifdef ext_N
      else if (interrupt_flag)
      begin
         mdlg     = mcsr.mideleg[cause];
         `ifdef ext_S
         sdlg     = scsr.sideleg[cause];
         `endif
      end
      `endif

      // Traps that increase privilege level are termed vertical traps, while traps that remain at the same privilege level are termed
      // horizontal traps.The RISC-V privileged architecture provides flexible routing of traps to different privilege layers. p4 riscv-privileged.pdf

      // Traps never transition from a more-privileged mode to a less-privileged mode. p.28
      if (mdlg)  // possible exception or interrupt trap delegation?
      begin
         nxt_mode    = M_MODE;                              // default unless delegation occurs
         tvec        = mcsr.mtvec;                          // default: H_MODE should never exist
         `ifdef ext_S
            `ifdef ext_U
               // In systems with all three privilege modes (M/S/U), setting a bit in medeleg or mideleg will
               // delegate the corresponding trap in (S-mode or U-mode) to the S-mode trap handler. p. 28 - riscv-privileged.pdf
               if (mdlg && (mode <= S_MODE))
               begin
                  tvec     = scsr.stvec;
                  nxt_mode = S_MODE;
               end
               // If U-mode traps are supported, S-mode may in turn set corresponding bits in the sedeleg and sideleg registers
               // to delegate traps that occur in U-mode to the U-mode trap handler.  see p. 28 riscv-privileged.pdf
               if (sdlg && (mode == U_MODE))
               begin
                  tvec     = ucsr.utvec;
                  nxt_mode = U_MODE;
               end
            `endif // ext_U
         `else // !ext_S
            // In systems with two privilege modes (M/U) and support for U-mode traps, setting a bit in medeleg or mideleg will
            // delegate the corresponding trap in U-mode to the U-mode trap handler.
            `ifdef ext_U
               if (mdlg && (mode == U_MODE))
               begin
                  tvec     = ucsr.utvec;
                  nxt_mode = U_MODE;   // will cause ucsr.ucause, ucsr.uepc, and ucsr.utval to be updated with exception information. see csr_nxt_reg.sv
               end
            `endif
         `endif
      end

      trap_pc = tvec[RSZ-1:2];                              // default trap_pc - 4 byte alignment (lower two bits not needed for passing this variable)
      `ifdef ext_N
      if ((nxt_mode > U_MODE) && interrupt_flag && (tvec[1:0] == 2'b01))
         trap_pc = PC_SZ-2'(tvec[RSZ-1:2] + cause); // 4 byte aligment - since lower 2 bits are 0, no need to pass them. i.e logic [PC_SZ-1:2] trap_pc
      `endif

      // mret, sret. uret come from EXE (which starts a PC reload), so these ONLY need to affect the mode.  The are mutually exclusive signals (only 1 should occur in a clock cycle)
      if (mret)
         nxt_mode = mpp;                                    // "When executing an MRET instruction, supposing MPP holds the value y, ... the privilege mode is changed to y; ..."

      `ifdef ext_S
      if (sret)
         nxt_mode = {1'b0,spp};                             // "When executing an SRET instruction, supposing SPP holds the value y, ... the privilege mode is changed to y; ..."
      `endif

      `ifdef ext_U
      if (uret)
         nxt_mode = 2'b00;                                  // "When executing an URET instruction, ... the privilege mode is changed to User; ..."
      `endif

   end
endmodule
