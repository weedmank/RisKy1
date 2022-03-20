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
// Description   :  Determines CPU mode, trap_pc, irq_flag and irq_cause
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

   input    logic                ext_irq,

   output   logic          [1:0] mode,                               // Output:  mode goes ONLY to stage EXE, where it travels to proceeding stages with the instruction
   output   logic          [1:0] nxt_mode,                           // Output:  mode goes ONLY to csr_regs.sv

   CSR_REG_intf.slave            csr_reg_bus,                        // slave:   inputs: Ucsr, Scsr, Mcsr

   CSR_WR_intf.slave             csr_wr_bus,                         // slave:   inputs: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret

   TRAP_intf.master              trap_bus                            // master:  output: trap_pc, irq_flag, irq_cause
);

   `ifdef ext_U
   `ifdef ext_N
      logic       uret;
      UCSR        Ucsr;                                              // Input:   current register state of all the User Mode Control & Status Registers
      assign uret = csr_wr_bus.uret;
      assign Ucsr = csr_reg_bus.Ucsr;
   `endif
   `endif

   `ifdef ext_S
      logic       sret;
      SCSR        Scsr;                                              // Input:   current register state of all the Supervisor Mode Control & Status Registers
      assign sret = csr_wr_bus.sret;
      assign Scsr = csr_reg_bus.Scsr;
   `endif

   logic          mret;
   MCSR           Mcsr;                                              // Input:   current register state of all the Machine Mode Control & Status Registers
   assign mret = csr_wr_bus.mret;
   assign Mcsr = csr_reg_bus.Mcsr;

   logic          retire_exception_flag;                             // Input:   TRUE for regular exceptions and also for interrupt exceptions
   logic          retire_interrupt_flag;                             // Input:   1 = both retire_exception_flag is TRUE and the MS bit of the exception cause is TRUE

   assign retire_exception_flag = csr_wr_bus.exception.flag;         // Input:   An exception occured for the retiring instruction
   assign retire_interrupt_flag = csr_wr_bus.exception.cause[RSZ-1]; // Input:   Was exception due due to an interrupt

   logic     [PC_SZ-2-1:0] trap_pc;
   logic                   irq_flag;
   logic             [3:0] irq_cause;

   assign trap_bus.trap_pc    = trap_pc;                             // lower two bits are missing (beause they're always 0), will get added once it reaches WB stage where it gets used
   assign trap_bus.irq_flag   = irq_flag;
   assign trap_bus.irq_cause  = irq_cause;

   //--------------------------------------------------------------------------------------
   //------------------------------------- Interrupts -------------------------------------
   //--------------------------------------------------------------------------------------

   logic          m_irq;

   logic          msie, mtie, meie;
   logic          msip, mtip, meip;

   `ifdef ext_S
   logic          ssie, stie, seie;
   logic          ssip, stip, seip;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   logic          usie, utie, ueie;
   logic          usip, utip, ueip;
   `endif
   `endif

   // ---------------------- Interrupt Enable bits ----------------------
   // see Machine Mode Mie register 12'h304
   `ifdef ext_U
   `ifdef ext_N
      assign usie = Ucsr.Uie.usie;           // USIE - User       mode Software Interrupt Enable
      assign utie = Ucsr.Uie.utie;           // UTIE - User       mode Timer    Interrupt Enable
      assign ueie = Ucsr.Uie.ueie;           // UEIE - User       mode External Interrupt Enable
   `endif
   `endif

   `ifdef ext_S
      assign ssie = Scsr.Sie.ssie;           // SSIE - Supervisor mode Software Interrupt Enable
      assign stie = Scsr.Sie.stie;           // STIE - Supervisor mode Timer    Interrupt Enable
      assign seie = Scsr.Sie.seie;           // SEIE - Supervisor mode External Interrupt Enable
   `endif

   assign msie = Mcsr.Mie.msie;              // MSIE - Machine    mode Software Interrupt Enable
   assign mtie = Mcsr.Mie.mtie;              // MTIE - Machine    mode Timer    Interrupt Enable
   assign meie = Mcsr.Mie.meie;              // MEIE - Machine    mode External Interrupt Enable

   // ---------------------- Interrupt Pending bits ----------------------
   // see Machine Mode Mip register 12'h344
   `ifdef ext_U
   `ifdef ext_N
      assign usip = Ucsr.Uip.usip;           // USIP - User       mode Software Interrupt Pending
      assign utip = Ucsr.Uip.utip;           // UTIP - User       mode Timer    Interrupt Pending
      assign ueip = Ucsr.Uip.ueip;           // UEIP - User       mode External Interrupt Pending
   `endif
   `endif

   `ifdef ext_S
      assign ssip = Scsr.Sip.ssip;           // SSIP - Supervisor mode Software Interrupt Pending
      assign stip = Scsr.Sip.stip;           // STIP - Supervisor mode Timer    Interrupt Pending
      // The logical-OR of the software-writable bit and the signal from the external interrupt
      // controller is used to generate external interrupts to the supervisor. see p 30 riscv-privileged.pdf
      assign seip = Scsr.Sip.seip & ext_irq; // SEIP - Supervisor mode External Interrupt Pending
   `endif

   assign msip = Mcsr.Mip.msip;              // MSIP - Machine    mode Software Interrupt Pending
   assign mtip = Mcsr.Mip.mtip;              // MTIP - Machine    mode Timer    Interrupt Pending
   assign meip = Mcsr.Mip.meip;              // MEIP - Machine    mode External Interrupt Pending

   // ---------------------- IRQs ----------------------
   assign m_irq = (msip & msie) | (mtip & mtie) | (meip & meie);  // any of the machine mode interrupts

   `ifdef ext_S
   logic    s_irq;
   assign s_irq = (ssip & ssie) | (stip & stie) | (seip & seie);  // any of the supervisor mode interrupts
   `endif

   `ifdef ext_U
   `ifdef ext_N
   logic    u_irq;
   assign u_irq = (usip & usie) | (utip & utie) | (ueip & ueie);  // any of the user mode interrupts
   `endif
   `endif

   // When a hart is executing in privilege mode x, interrupts are globally enabled when xIE=1 and
   // globally disabled when xIE=0. Interrupts for lower-privilege modes, w<x, are always globally
   // disabled regardless of the setting of the lower-privilege mode’s global wIE bit. Interrupts for
   // higher-privilege modes, y>x, are always globally enabled regardless of the setting of the higher privilege
   // mode’s global yIE bit. Higher-privilege-level code can use separate per-interrupt enable
   // bits to disable selected higher-privilege-mode interrupts before ceding control to a lower-privilege
   // mode.   riscv-privileged p 20

   // determine interrupt request flag and cause
   always_comb
   begin
      irq_flag    = FALSE; // default value
      irq_cause   = '0;

      // Note: observation: lower two bits of irq_cause are the same as "mode", bits [3:2] -> 0 for SW, 1 for Timer and 2 for External
      case(mode)   // what should the interrupt priority be if multiple interrupts???????????????????????????????????? SW, then Timer, then External ??????????????????
         M_MODE:
         begin
            irq_flag = (Mcsr.Mstatus.mie & m_irq);

            if      (msip & msie) irq_cause = 'd3;  // Machine Mode Software Interrupt
            else if (mtip & mtie) irq_cause = 'd7;  // Machine Mode Timer    Interrupt
            else if (meip & meie) irq_cause = 'd11; // Machine Mode External Interrupt
         end

         `ifdef ext_S
         S_MODE:
         begin
            irq_flag = (m_irq  | (Scsr.Sstatus.sie & s_irq));

            if      (ssip & ssie) irq_cause = 'd1;  // Supervisor Mode Software Interrupt
            else if (stip & stie) irq_cause = 'd5;  // Supervisor Mode Timer    Interrupt
            else if (seip & seie) irq_cause = 'd9;  // Supervisor Mode External Interrupt
         end
         `endif

         `ifdef ext_U
         `ifdef ext_N
         U_MODE:
         begin
            irq_flag = (m_irq |  `ifdef ext_S s_irq | `endif (Ucsr.Ustatus.uie & u_irq));

            if      (usip & usie) irq_cause = 'd0;  // User Mode Software Interrupt
            else if (utip & utie) irq_cause = 'd4;  // User Mode Timer    Interrupt
            else if (ueip & ueie) irq_cause = 'd8;  // User Mode External Interrupt
         end
         `endif
         `endif
      endcase
   end

   //----------------------------------------------------------------------------------------------------------------------------------------
   //--------------------------------------------------------------- CPU Mode ---------------------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------

   // csr_mstatus info
   logic       [1:0] mpp;                       // from Mcsr.Mstatus[12:11]
   assign mpp = Mcsr.Mstatus.mpp;

   `ifdef ext_S
   logic    spp;  // from Scsr.Sstatus[8]
   assign spp = Scsr.Sstatus.spp;
   `endif

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         mode <= M_MODE;                        // nxt_mode == 3 during reset_in
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
   logic         [RSZ-1:0] tvec;
   logic      [DEL_SZ-1:0] cause;               // index into delegation registers can only be from 0 to RSZ-1
   logic                   mdlg,sdlg;


   always_comb
   begin
      tvec        = Mcsr.Mtvec;                 // This default Trap PC will only get used if retire_exception_flag asserts when an instruction tries to retire in stage WB
      cause       = csr_wr_bus.exception.cause;

      // By default, all traps at any privilege level are handled in machine mode, though a machine-mode
      // handler can redirect traps back to the appropriate level with the MRET instruction
      nxt_mode    = mode;                       // no change from last clock cycle, unless retire_exception_flag asserts

      mdlg        = FALSE;                      // default flag is that no delegation will take place
      sdlg        = FALSE;

      if (retire_exception_flag)                // exception flag from instruction that tried to retire in stage WB, but instead it caused an exception
      begin
         cause       = Mcsr.Mcause[DEL_SZ-1:0];
         nxt_mode    = M_MODE;                  // default unless delegation occurs

         // ----------------------------------------------  logic to include if delegation is allowed
         `ifdef MDLG
            mdlg     = Mcsr.Medeleg[cause];     // Machine    delegation bit based on mcause
            `ifdef ext_S
            sdlg     = Scsr.Sedeleg[cause];     // Supervisor delegation bit based on mcause
            `endif

            if (retire_interrupt_flag)          // interrupt flag from instruction that is retiring in stage WB. We'll let interrupt override normal exception causes
            begin
               mdlg     = Mcsr.Mideleg[cause];
               `ifdef ext_S
               `ifdef ext_N
               sdlg     = Scsr.Sideleg[cause];
               `endif
               `endif
            end

            // Traps that increase privilege level are termed vertical traps, while traps that remain at the same privilege level are termed
            // horizontal traps.The RISC-V privileged architecture provides flexible routing of traps to different privilege layers. p4 riscv-privileged.pdf

            // Traps never transition from a more-privileged mode to a less-privileged mode. p.28
            if (mdlg)  // possible exception or interrupt trap delegation?
            begin
               `ifdef ext_S
                  // In systems with all three privilege modes (M/S/U), setting a bit in medeleg or mideleg will
                  // delegate the corresponding trap in (S-mode or U-mode) to the S-mode trap handler. p. 28 - riscv-privileged.pdf
                  if (mdlg && (mode <= S_MODE))
                  begin
                     tvec     = Scsr.Stvec;
                     nxt_mode = S_MODE;
                  end
                  `ifdef ext_U
                  `ifdef ext_N
                  // If U-mode traps are supported, S-mode may in turn set corresponding bits in the sedeleg and sideleg registers
                  // to delegate traps that occur in U-mode to the U-mode trap handler.  see p. 28 riscv-privileged.pdf
                  if (sdlg && (mode == U_MODE))
                  begin
                     tvec     = Ucsr.Utvec;
                     nxt_mode = U_MODE;
                  end
                  `endif // ext_N
                  `endif // ext_U
               `else // !ext_S
                  // In systems with two privilege modes (M/U) and support for U-mode traps, setting a bit in medeleg or mideleg will
                  // delegate the corresponding trap in U-mode to the U-mode trap handler.
                  `ifdef ext_U
                  `ifdef ext_N
                     if (mdlg && (mode == U_MODE))
                     begin
                        tvec     = Ucsr.Utvec;
                        nxt_mode = U_MODE;      // will cause Ucsr.Ucause, Ucsr.Uepc, and Ucsr.Utval to be updated with exception information. see csr_nxt_reg.sv
                     end
                  `endif
                  `endif
               `endif
            end
         `endif // MDLG
         // ----------------------------------------------  end of logic to include if delegation is allowed
      end // if (retire_exception_flag)

      // trap_pc only used during an exception
      trap_pc = tvec[RSZ-1:2];                                 // default trap_pc - 4 byte alignment (lower two bits not needed for passing this variable)
      if ((nxt_mode > U_MODE) & retire_interrupt_flag & (tvec[1:0] == 2'b01))
         trap_pc = (PC_SZ-2)'(tvec[RSZ-1:2] + cause);          // 4 byte aligment - since lower 2 bits are 0, no need to pass them. i.e logic [PC_SZ-1:2] trap_pc

      // MRET, SRET, URET will not occur if an exception occurrs (i.e. retire_exception_flag)
      // mret, sret. uret come from retirement stage WB, so these ONLY need to affect the mode.  The are mutually exclusive signals (only 1 should occur in a clock cycle)
      if (mret)
         nxt_mode = mpp;                        // "When executing an MRET instruction, supposing MPP holds the value y, ... the privilege mode is changed to y; ..."

      `ifdef ext_S
      if (sret)
         nxt_mode = {1'b0,spp};                 // "When executing an SRET instruction, supposing SPP holds the value y, ... the privilege mode is changed to y; ..."
      `endif

      `ifdef ext_U
      `ifdef ext_N
      if (uret)
         nxt_mode = 2'b00;                      // "When executing an URET instruction, ... the privilege mode is changed to User; ..."
      `endif
      `endif
   end
endmodule
