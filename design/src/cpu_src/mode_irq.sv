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

   output   logic    [PC_SZ-1:0] trap_pc,           // Output: trap vector handler address - connects to WB stage
   `ifdef ext_N
   output   logic                interrupt_flag,    // Output: 1 = take an interrupt trap - connects to WB stage
   output   logic      [RSZ-1:0] interrupt_cause,   // Output: value specifying what type of interrupt - connects to WB stage
   `endif

   // only a few of these CSR registers are needed by this module
//   `ifdef ext_U
//   UCSR_REG_intf                 ucsr,              // Input:   current register state of all the User Mode Control & Status Registers
//   `endif
//   `ifdef ext_S
//   SCSR_REG_intf                 scsr,              // Input:   current register state of all the Supervisor Mode Control & Status Registers
//   `endif
//   MCSR_REG_intf                 mcsr               // Input:   current register state of all the Machine Mode Control & Status Registers
   `ifdef ext_U
   input var UCSR                  ucsr,              // Input:   current register state of all the User Mode Control & Status Registers
   `endif
   `ifdef ext_S
   input var SCSR                  scsr,              // Input:   current register state of all the Supervisor Mode Control & Status Registers
   `endif
   input var MCSR                  mcsr               // Input:   current register state of all the Machine Mode Control & Status Registers
);

   //----------------------------------------------------------------------------------------------------------------------------------------
   //------------------------------------- "N" Standard Extension for User_Level Interrupts, Version 1.1 ------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------

   `ifdef ext_N
      logic          m_irq, s_irq, u_irq;
      logic          usie,ssie,msie,  utie,stie,mtie,  ueie,seie,meie;
      logic          usip,ssip,msip,  utip,stip,mtip,  ueip,seip,meip;

      // csr_mstatus info
      logic       [1:0] mpp;  // from mcsr.mstatus[12:11]
      logic             spp;  // from mcsr.mstatus[8]

      // ---------------------- Interrupt Enable bits ----------------------
      // see Machine Mode Mie register 12'h304
      assign usie = mcsr.mie.usie;     // USIE - User       mode Software Interrupt Enable
      assign ssie = mcsr.mie.ssie;     // SSIE - Supervisor mode Software Interrupt Enable
      assign msie = mcsr.mie.msie;     // MSIE - Machine    mode Software Interrupt Enable

      assign utie = mcsr.mie.utie;     // UTIE - User       mode Timer    Interrupt Enable
      assign stie = mcsr.mie.stie;     // STIE - Supervisor mode Timer    Interrupt Enable
      assign mtie = mcsr.mie.mtie;     // MTIE - Machine    mode Timer    Interrupt Enable
                                       //
      assign ueie = mcsr.mie.ueie;     // UEIE - User       mode External Interrupt Enable
      assign seie = mcsr.mie.seie;     // SEIE - Supervisor mode External Interrupt Enable
      assign meie = mcsr.mie.meie;     // MEIE - Machine    mode External Interrupt Enable

      assign usip = mcsr.mip.usip;     // USIP - User       mode Software Interrupt Pending
      assign ssip = mcsr.mip.ssip;     // SSIP - Supervisor mode Software Interrupt Pending
      assign msip = mcsr.mip.msip;     // MSIP - Machine    mode Software Interrupt Pending

      // see Machine Mode Mip register 12'h344
      assign utip = mcsr.mip.utip;     // UTIP - User       mode Timer    Interrupt Pending
      assign stip = mcsr.mip.stip;     // STIP - Supervisor mode Timer    Interrupt Pending
      assign mtip = mcsr.mip.mtip;     // MTIP - Machine    mode Timer    Interrupt Pending

      assign ueip = mcsr.mip.ueip;     // UEIP - User       mode External Interrupt Pending
      assign seip = mcsr.mip.seip;     // SEIP - Supervisor mode External Interrupt Pending
      assign meip = mcsr.mip.meip;     // MEIP - Machine    mode External Interrupt Pending

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
      assign interrupt_flag = (mode == 3) ? (mcsr.mstatus.mie & m_irq) : ((mode == 1) ? (m_irq  | (mcsr.mstatus.sie & s_irq)) : (m_irq | s_irq | (mcsr.mstatus.uie & u_irq)));

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
   assign spp = mcsr.mstatus.spp;

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
   logic     [GPR_ASZ-1:0] cause,mc;
   logic         [RSZ-1:0] tvec;
   logic             [1:0] trap_mode;
   
   assign mc = mcsr.mcause[GPR_ASZ-1:0];
   
   `ifdef ext_S
   logic     [GPR_ASZ-1:0] sc;
   assign sc = scsr.scause[GPR_ASZ-1:0];
   `endif // ext_S
   
   `ifdef ext_U
   logic     [GPR_ASZ-1:0] uc;
   assign uc = ucsr.ucause[GPR_ASZ-1:0];
   `endif // ext_U
   
   always_comb
   begin
      
      trap_pc     = RESET_VECTOR_ADDR; // This should not get used. It should be set/overrriden by being set in code below to a valid location

      `ifdef ext_U
      if (mode == U_MODE)
      begin
         cause    = uc;
         tvec     = ucsr.utvec;
      end
      `endif // ext_U
      `ifdef ext_S
      if (mode == S_MODE)
      begin
         cause    = sc;
         tvec     = scsr.stvec;
      end
      `endif // ext_S
      if (mode == M_MODE)
      begin
         cause    = mc;
         tvec     = mcsr.mtvec;
      end
      
      nxt_mode    = mode;      // default unless code below changes it
      
      // Traps that increase privilege level are termed vertical traps, while traps that remain at the same privilege level are termed
      // horizontal traps.The RISC-V privileged architecture provides flexible routing of traps to different privilege layers. p4 riscv-privileged.pdf

      // Traps never transition from a more-privileged mode to a less-privileged mode.
      `ifdef ext_N
      if (interrupt_flag)
      begin
         // In systems with all three privilege modes (M/S/U), setting a bit in medeleg or mideleg will
         // delegate the corresponding trap in S-mode or U-mode to the S-mode trap handler. p. 28 - riscv-privileged.pdf
         `ifdef ext_S
            `ifdef ext_U
            if (mcsr.mideleg[mc] && ((mode == S_MODE) || (mode == U_MODE)) )
            begin
               cause    = sc;
               tvec     = scsr.stvec;
               nxt_mode = S_MODE;
            end
            if (scsr.sideleg[mc] && (mode == U_MODE)) // see p. 28 riscv-privileged.pdf
            begin
               cause    = uc;
               tvec     = ucsr.utvec;
               nxt_mode = U_MODE;
            end
            `endif // ext_U
         `else // !ext_S
            // In systems with two privilege modes (M/U) and support for U-mode traps, setting a bit in medeleg or mideleg will
            // delegate the corresponding trap in U-mode to the U-mode trap handler.
            `ifdef ext_U
            if (mcsr.mideleg[mc] && (mode == U_MODE))
            begin
               cause    = uc;
               tvec     = ucsr.utvec;
               nxt_mode = U_MODE;
            end
            `endif
         `endif
      end
      else
      `endif // ext_N
      if (exception_flag)
      begin
         // In systems with all three privilege modes (M/S/U), setting a bit in medeleg or mideleg will
         // delegate the corresponding trap in S-mode or U-mode to the S-mode trap handler. p. 28 - riscv-privileged.pdf
         `ifdef ext_S
            `ifdef ext_U
            if (mcsr.medeleg[mc] && ((mode == S_MODE) || (mode == U_MODE)) )
            begin
               cause    = sc;
               tvec     = scsr.stvec;
               nxt_mode = S_MODE;
            end
            if (scsr.sedeleg[mc] && (mode == U_MODE)) // see p. 28 riscv-privileged.pdf
            begin
               cause    = uc;
               tvec     = ucsr.utvec;
               nxt_mode = U_MODE;
            end
            `endif // ext_U
         `else // !ext_S
            // In systems with two privilege modes (M/U) and support for U-mode traps, setting a bit in medeleg or mideleg will
            // delegate the corresponding trap in U-mode to the U-mode trap handler.
            `ifdef ext_U
            if (mcsr.medeleg[mc] && (mode == U_MODE))
            begin
               cause    = uc;
               tvec     = ucsr.utvec;
               nxt_mode = U_MODE;
            end
            `endif
         `endif
      end
      else if (mret)
         nxt_mode = mpp;                                    // "When executing an MRET instruction, supposing MPP holds the value y, ... the privilege mode is changed to y; ..."
      `ifdef ext_S
      else if (sret)
         nxt_mode = {1'b0,spp};                             // "When executing an SRET instruction, supposing SPP holds the value y, ... the privilege mode is changed to y; ..."
      `endif
      `ifdef ext_U
      else if (uret)
         nxt_mode = 2'b00;                                  // "When executing an URET instruction, ... the privilege mode is changed to User; ..."
      `endif
      else // default
         nxt_mode = mode;

      case(nxt_mode)
         S_MODE,M_MODE:    // Machine Mode.     see riscv-priviledged.pdf p. 27
         begin
            `ifdef ext_N
            if (interrupt_flag && (tvec[1:0] == 2'b01))           // Optional vectored interrupt support has been added to the mtvec and stvec CSRs. riscv_privileged.pdf p iii
               //        BASE          +  cause        * 4
               trap_pc = tvec[RSZ-1:2] + { {RSZ-GPR_ASZ-2{1'b0}}, cause, 2'b00 };
            else
            `endif
            trap_pc  = {tvec[RSZ-1:2],2'b00};
         end

         `ifdef ext_U
         U_MODE:    // User Mode
         begin
            trap_pc = {tvec[RSZ-1:2],2'b00};
         end
         `endif
      endcase
   end
endmodule
