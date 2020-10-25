// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_fu.sv
// Description   :  Contains the Control & Status Registers
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_fu
(
   input    logic    clk_in,
   input    logic    reset_in,
   CSRFU.slave       csrfu_bus
); 
   
   `include "csr_regs.svh"                               // declarations for mstatus, misa, etc. for all modes
   
   
   logic                  [11:0] csr_addr;               // R/W address
   logic                         csr_valid;              // 1 = Read & Write from/to csr[csr_addr] will occur this clock cylce
   
   logic           [GPR_ASZ-1:0] Rd_addr;                // Rd address
   logic           [GPR_ASZ-1:0] Rs1_addr;               // Rs1 address
   logic               [RSZ-1:0] Rs1_data;               // Contents of R[rs1]
   
   logic                   [2:0] csr_funct;  
   
   EXCEPTION                     exception;     
   EVENTS                        current_events;         // number of retired instructions for current clock cycle
   logic                         mret;                   // MRET retiring
   logic             [PC_SZ-1:0] mepc;                   // Machine   : Exception RET PC address
   
   `ifdef ext_S   
   logic                         sret;                   // SRET retiring
   logic             [PC_SZ-1:0] sepc;                   // Supervisor: Exception RET PC address
   `endif

   `ifdef ext_U
   logic                         uret;                   // URET retiring
   logic             [PC_SZ-1:0] uepc;                   // User      : Exception RET PC address
   `endif   
   
   logic             [2*RSZ-1:0] mtime;                  // memory mapped mtime register
   
   `ifdef ext_N   
   logic                         ext_irq;                // External Interrupt
   logic                         time_irq;               // Timer Interrupt from irq.sv
   logic                         sw_irq;                 // Software Interrupt from irq.sv
   `endif   
   
   logic               [RSZ-1:0] csr_rd_data;            // read data from csr[csr_addr]
   logic                   [1:0] mode, nxt_mode;         // CPU mode: Machine, Supervisor, or User
   logic             [PC_SZ-1:0] trap_pc;                // trap vector handler address.
   `ifdef ext_N   
   logic               [RSZ-1:0] interrupt_cause;  
   logic                         interrupt_flag;         // 1 = take an interrupt trap
   `endif   
   logic                         ill_csr_access;         // 1 = illegal csr access
   logic                  [11:0] ill_csr_addr;  
   
   logic                         ialign;                 // Instruction Alignment. 1 = 16, 0 = 32

   assign ialign           = csr_misa [2];               // 1 = compressed instruction (16 bit alignment), 0 = 32 bit alignment.  See csr_wr_mach.sv

   assign csr_addr         = csrfu_bus.csr_addr;
   assign csr_valid        = csrfu_bus.csr_valid;        // valid == 1 - a CSR rad & write happens this clock cycle

   assign exception        = csrfu_bus.exception;
   assign current_events   = csrfu_bus.current_events;
   assign mret             = csrfu_bus.mret;
   `ifdef ext_S
   assign sret             = csrfu_bus.sret;
   `endif
   `ifdef ext_U
   assign uret             = csrfu_bus.uret;
   `endif


   assign mtime            = csrfu_bus.mtime;

   `ifdef ext_N
   assign ext_irq          = csrfu_bus.ext_irq;
   assign time_irq         = csrfu_bus.time_irq;
   assign sw_irq           = csrfu_bus.sw_irq;
   `endif


   assign csrfu_bus.Rd_data  = csr_rd_data;              // Rd_data: value to write into register R[Rd] in WB stage
   assign csrfu_bus.mode     = mode;
   assign csrfu_bus.trap_pc  = trap_pc;
   `ifdef ext_N
   assign csrfu_bus.interrupt_flag  = interrupt_flag;
   assign csrfu_bus.interrupt_cause = interrupt_cause;
   `endif
   assign csrfu_bus.mepc     = mepc;                     // csr_wr_mach.svh
   `ifdef ext_S   
   assign csrfu_bus.sepc     = sepc;                     // csr_wr_super.svh
   `endif   
   `ifdef ext_U   
   assign csrfu_bus.uepc     = uepc;                     // csr_wr_user.svh
   `endif
   assign csrfu_bus.ill_csr_access  = ill_csr_access;
   assign csrfu_bus.ill_csr_addr    = ill_csr_addr;
   assign csrfu_bus.ialign          = ialign;

   logic         [RSZ-1:0] imm_data;                     // immediate data
   logic         [RSZ-1:0] csr_wr_data;                  // write data to csr[csr_addr]
   logic                   csr_wr;
   logic                   csr_rd;

   assign Rd_addr       =  csrfu_bus.Rd_addr;            // rd
   assign Rs1_addr      =  csrfu_bus.Rs1_addr;           // rs1
   assign Rs1_data      =  csrfu_bus.Rs1_data;           // R[rs1]
   assign csr_funct     =  csrfu_bus.funct3;             // type of CSR R/W

   assign imm_data      = {27'd0,Rs1_addr};              // 5 bits of intruction imbedded data


   // Check for valid reads and writes to CSRs
   logic       [1:0] lowest_priv;
   logic             writable;
   logic             csr_avail;
   logic   [RSZ-1:0] csr_rdata;

   // full_case — at least one item is true
   // parallel_case — at most one item is true
   always_comb
   begin
      csr_wr_data    = '0;
      csr_rd_data    = '0;
      csr_wr         = FALSE;
      csr_rd         = FALSE;
      ill_csr_access = FALSE;
      ill_csr_addr   = 0;

      writable    = (csr_addr[11:10] != 2'b11);          // read/write (00, 01, or 10) or read-only (11)
      lowest_priv = csr_addr[9:8];

      if (csr_valid)
      begin
         // see riscv-spec.pdf p 54
         case(csr_funct)   // synopsys parallel_case    {CSRRW,CSRRS,CSRRC,CSRRWI,CSRRSI,CSRRCI}
            CSRRW: // 1
            begin      // If rd=x0, then the instruction shall not read the CSR and shall not cause any of the side effects that might occur on a CSR read. riscv-spec p 53-54
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = Rs1_data;                // R[Rd] = CSR; CSR = R[rs1];          Atomic Read/Write CSR  p. 22
                  csr_wr = TRUE;
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = (Rd_addr != 0); // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd) csr_rd_data = csr_rdata;
               end
            end
            // For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and
            // so shall not cause any of the side effects that might otherwise occur on a CSR write, such as raising
            // illegal instruction exceptions on accesses to read-only CSRs
            CSRRS: // 2
            begin   // Other bits in the CSR are unaffected (though CSRs might have side effects when written). risv-spec p. 54
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rdata |  Rs1_data;   // R[Rd] = CSR; CSR = CSR | R[rs1];    Atomic Read and Set Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  csr_rd_data = csr_rdata;
               end
            end
            CSRRC: // 3
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rdata & ~Rs1_data;   // R[Rd] = CSR; CSR = CSR & ~R[rs1];   Atomic Read and Clear Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  csr_rd_data = csr_rdata;
               end
            end
            CSRRWI: // 5
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = imm_data;                // R[Rd] = CSR; CSR = imm;             p. 22-23
                  csr_wr = TRUE;
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = (Rd_addr != 0); // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd) csr_rd_data = csr_rdata;
               end
            end
            CSRRSI: // 6
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rdata |  imm_data;   // R[Rd] = CSR; CSR = CSR | imm;       Atomic Read and Set Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  csr_rd_data = csr_rdata;
               end
            end
            CSRRCI: // 7
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rdata & ~imm_data;   // R[Rd] = CSR; CSR = CSR & ~imm;      Atomic Read and Clear Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               begin
                  csr_rd = TRUE;
                  csr_rd_data = csr_rdata;
               end
            end
         endcase
      end
   end

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! UNDER CONSTRUCTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   //---------------------------------- 12 bit address info ----------------------------------
   //           bits [11:10]    bits[9:8]             [7:6]
   //           00 R/W          00 user mode          standard/non-standard info
   //           01 R/W          01 supervisor mode
   //           10 R/W          10 unused
   //           11 RO           11 machine mode
   //             \            /
   //              \          /
   //               \        /   // Note:  The next two bits (csr[9:8]) encode the lowest privilege level that can access the CSR.
   //                \      /
   // Counters        \    /
   //    Clock Cycle   \  /
   //    12'hC00 = 12'b1100_0000_0000  cycle       (read-only)   user mode
   //    12'hB00 = 12'b1011_0000_0000  mcycle      (read-write)  machine mode


   // csr_mstatus info
   logic             sd;
   logic             tsr, tw, tvm, mxr, sum, mprv;
   logic       [1:0] xs, fs, mpp;
   logic                  mpie, mie;
   logic             spp, spie, sie;   // needed in csr_mstatus - these will be 0 if there's no ext_S
   logic                  upie, uie;   // needed in csr_mstatus - these will be 0 if there's no ext_U or no ext_N

   // Illegal Instructions: riscv-privileged.pdf
   // 1.  Attempts to access a non-existent CSR raise an illegal instruction exception. Attempts to access a
   //     CSR without appropriate privilege level or to write a read-only register also raise illegal instruction
   //     exceptions. p. 5
   // 2.  Machine-mode standard read-write CSRs 0x7A0–0x7BF are reserved for use by the debug system.
   //     Of these CSRs, 0x7A0–0x7AF are accessible to machine mode, whereas 0x7B0–0x7BF are only visible
   //     to debug mode. Implementations should raise illegal instruction exceptions on machine-mode access
   //     to the latter set of registers. p. 6
   // 3.  The TVM (Trap Virtual Memory) bit supports intercepting supervisor virtual-memory management
   //     operations. When TVM=1, attempts to read or write the satp CSR or execute the
   //     SFENCE.VMA instruction while executing in S-mode will raise an illegal instruction exception.
   //     When TVM=0, these operations are permitted in S-mode. TVM is hard-wired to 0 when S-mode
   //     is not supported. p. 23
   // 4.  The TW (Timeout Wait) bit supports intercepting the WFI instruction (see Section 3.2.3). When
   //     TW=0, the WFI instruction may execute in lower privilege modes when not prevented for some
   //     other reason. When TW=1, then if WFI is executed in any less-privileged mode, and it does not
   //     complete within an implementation-specific, bounded time limit, the WFI instruction causes an
   //     illegal instruction exception. The time limit may always be 0, in which case WFI always causes an
   //     illegal instruction exception in less-privileged modes when TW=1. TW is hard-wired to 0 when
   //     there are no modes less privileged than M. p 23
   // 5.  When S-mode is implemented, then executing WFI in U-mode causes an illegal instruction exception,
   //     unless it completes within an implementation-specific, bounded time limit. A future revision
   //     of this specification might add a feature that allows S-mode to selectively permit WFI in U-mode.
   //     Such a feature would only be active when TW=0. p 23
   // 6.  The TSR (Trap SRET) bit supports intercepting the supervisor exception return instruction, SRET.
   //     When TSR=1, attempts to execute SRET while executing in S-mode will raise an illegal instruction
   //     exception. When TSR=0, this operation is permitted in S-mode. TSR is hard-wired to 0 when
   //     S-mode is not supported. p 23
   // 7.  When an extension’s status is set to Off, any instruction that attempts to read or write the corresponding
   //     state will cause an illegal instruction exception. p 24
   // 8.  Executing a user-mode instruction to disable a unit and place it into the Off state will cause an
   //     illegal instruction exception to be raised if any subsequent instruction tries to use the unit before
   //     it is turned back on. A user-mode instruction to turn a unit on must also ensure the unit’s state is
   //     properly initialized, as the unit might have been used by another context meantime. p 25
   // 9.  Traps never transition from a more-privileged mode to a less-privileged mode. For example, if Mmode
   //     has delegated illegal instruction exceptions to S-mode, and M-mode software later executes
   //     an illegal instruction, the trap is taken in M-mode, rather than being delegated to S-mode. By
   //     contrast, traps may be taken horizontally. Using the same example, if M-mode has delegated illegal
   //     instruction exceptions to S-mode, and S-mode software later executes an illegal instruction, the trap
   //     is taken in S-mode. p. 28
   // 10. When the CY, TM, IR, or HPMn bit in the mcounteren register is clear, attempts to read the
   //     cycle, time, instret, or hpmcountern register while executing in S-mode or U-mode will cause
   //     an illegal instruction exception. p. 34
   // 11. Registers mcounteren and scounteren are WARL registers that must be implemented if U-mode
   //     and S-mode are implemented. Any of the bits may contain a hardwired value of zero, indicating
   //     reads to the corresponding counter will cause an illegal instruction exception when executing in a
   //     less-privileged mode. p. 34
   // 12. When a hardware breakpoint is triggered, or an instruction-fetch, load, or store address-misaligned,
   //     access, or page-fault exception occurs, mtval is written with the faulting virtual address. On an
   //     illegal instruction trap, mtval may be written with the first XLEN or ILEN bits of the faulting
   //     instruction as described below. For other traps, mtval is set to zero, but a future standard may
   //     redefine mtval’s setting for other traps. p. 38
   // 13. To return after handling a trap, there are separate trap return instructions per privilege level:
   //     MRET, SRET, and URET. MRET is always provided. SRET must be provided if supervisor mode
   //     is supported, and should raise an illegal instruction exception otherwise. SRET should also raise an
   //     illegal instruction exception when TSR=1 in csr_mstatus, as described in Section 3.1.6.4. URET is only
   //     provided if user-mode traps are supported, and should raise an illegal instruction otherwise.  p. 40
   // 14. The Wait for Interrupt instruction (WFI) provides a hint to the implementation that the current
   //     hart can be stalled until an interrupt might need servicing. Execution of the WFI instruction
   //     can also be used to inform the hardware platform that suitable interrupts should preferentially be
   //     routed to this hart. WFI is available in all privileged modes, and optionally available to U-mode.
   //     This instruction may raise an illegal instruction exception when TW=1 in csr_mstatus, as described
   //     in Section 3.1.6.4. p. 41
   // 15. When the CY, TM, IR, or HPMn bit in the scounteren register is clear, attempts to read the cycle,
   //     time, instret, or hpmcountern register while executing in U-mode will cause an illegal instruction
   //     exception. When one of these bits is set, access to the corresponding register is permitted. p. 60


   // NOTE: p. 20. When a hart is executing in privilege mode x, interrupts are enabled when xIE=1.
   //       Interrupts for lower privilege modes are always disabled, whereas interrupts for higher
   //       privilege modes are always enabled.

   //----------------------------------------------------------------------------------------------------------------------------------------
   //------------------------------------- "N" Standard Extension for User_Level Interrupts, Version 1.1 ------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------
   logic             msip,mtip,meip;
   logic             ssip,stip,seip;
   logic             usip,utip,ueip;

   `ifdef ext_N
      logic          m_irq, s_irq, u_irq;
      logic          usie,ssie,msie,  utie,stie,mtie,  ueie,seie,meie;

      // ---------------------- Interrupt Enable bits ----------------------

      `ifdef ext_U assign usie = csr_mie [0];     /* USIE - User       mode Software Interrupt Enable */  `else assign usie = 1'b0; `endif
      `ifdef ext_S assign ssie = csr_mie [1];     /* SSIE - Supervisor mode Software Interrupt Enable */  `else assign ssie = 1'b0; `endif
                   assign msie = csr_mie [3];     /* MSIE - Machine    mode Software Interrupt Enable */

      `ifdef ext_U assign utie = csr_mie [4];     /* UTIE - User       mode Timer    Interrupt Enable */  `else assign utie = 1'b0; `endif
      `ifdef ext_S assign stie = csr_mie [5];     /* STIE - Supervisor mode Timer    Interrupt Enable */  `else assign stie = 1'b0; `endif
                   assign mtie = csr_mie [7];     /* MTIE - Machine    mode Timer    Interrupt Enable */

      `ifdef ext_U assign ueie = csr_mie [8];     /* UEIE - User       mode External Interrupt Enable */  `else assign ueie = 1'b0; `endif
      `ifdef ext_S assign seie = csr_mie [9];     /* SEIE - Supervisor mode External Interrupt Enable */  `else assign seie = 1'b0; `endif
                   assign meie = csr_mie [11];    /* MEIE - Machine    mode External Interrupt Enable */

      assign m_irq = (msip & msie) | (mtip & mtie) | (meip & meie);  // any of the machine mode interrupts

      `ifdef ext_S
      assign s_irq = (ssip & ssie) | (stip & stie) | (seip & seie);  // any of the supervisor mode interrupts
      `else
      assign s_irq = FALSE;
      `endif

      `ifdef ext_U
      assign u_irq = (usip & usie) | (utip & utie) | (ueip & ueie);  // any of the user mode interrupts
      `else
      assign u_irq = FALSE;
      `endif

      // When a hart is executing in privilege mode x, interrupts are globally enabled when xIE=1 and
      // globally disabled when xIE=0. Interrupts for lower-privilege modes, w<x, are always globally
      // disabled regardless of the setting of the lower-privilege mode’s global wIE bit. Interrupts for
      // higher-privilege modes, y>x, are always globally enabled regardless of the setting of the higher privilege
      // mode’s global yIE bit. Higher-privilege-level code can use separate per-interrupt enable
      // bits to disable selected higher-privilege-mode interrupts before ceding control to a lower-privilege
      // mode.   riscv-privileged p 20
      assign interrupt_flag = (mode == 3) ? (mie & m_irq) : ((mode == 1) ? (m_irq  | (sie & s_irq)) : (m_irq | s_irq | (uie & u_irq)));

      // determine interrupt cause
      always_comb
      begin
         interrupt_cause = 0;

         case(mode)   // See p. 35 riscv-privileged-v1.10
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

   //U -> M: on a page fault, unaligned address, divide by zero etc, or explicit syscall/svc/sw interrupt instruction. Or hardware interrupt.
   //M -> U: on a "return from interrupt" instruction where the saved processor status indicates the CPU should be in U mode.
   always_comb
   begin
      nxt_mode = mode;

      if (reset_in | exception.flag `ifdef ext_N | interrupt_flag `endif)
         nxt_mode = 2'b11;                                  // Machine Mode
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
   end

   always_ff @(posedge clk_in)
      mode <= nxt_mode;                                     // nxt_mode == 3 during reset_in

   //----------------------------------------------------------------------------------------------------------------------------------------
   //----------------------------------------------------------- Synchronous Exceptions -----------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------
   // When MODE=Vectored, all synchronous exceptions into supervisor mode cause the pc to be set to the address in the BASE field,
   // whereas interrupts cause the pc to be set to the address in the BASE field plus four times the interrupt cause number.
   // For example, a supervisor-mode timer interrupt (see Table 4.2) causes the  pc to be set to BASE+0x14.
   // Setting MODE=Vectored may impose a stricter alignment constraint on BASE.
   always_comb
   begin
      trap_pc = '0;
      case(nxt_mode)
         3:    // Machine Mode.     see riscv-priviledged.pdf p. 27
         begin
            `ifdef ext_N
            if (interrupt_flag && (csr_mtvec[1:0] == 2'b01))      // Optional vectored interrupt support has been added to the mtvec and stvec CSRs. riscv_privileged.pdf p iii
               //        BASE      +  cause             * 4
               trap_pc = csr_mtvec[RSZ-1:2] + {csr_mcause[29:0], 2'b00};
            else
            `endif
            trap_pc  = csr_mtvec[RSZ-1:2];
         end

         `ifdef ext_S
         1:    // Supervisor Mode.  see riscv-priviledged.pdf p. 57-58
         begin
            `ifdef ext_N
            if (interrupt_flag && (csr_stvec[1:0] == 2'b01))
               //        BASE      +  cause             * 4
               trap_pc = csr_stvec[RSZ-1:2] + {csr_scause[29:0], 2'b00};
            else
            `endif
               trap_pc = csr_stvec[RSZ-1:2];
         end
         `endif

         `ifdef ext_U
         0:    // User Mode
         begin
            trap_pc = csr_utvec[RSZ-1:2];
         end
         `endif
      endcase
   end


   //----------------------------------------------------------------------------------------------------------------------------------------
   //------------------------------------------------------------- CSR Write Logic ----------------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------

   // each include file can create a specific CSR for a given csr_addr, as well as write csr_wr_data as needed

   `include "csr_wr_mach.svh"                   // machine mode register writes

   `include "csr_wr_super.svh"                  // supervisor mode register writes

   `include "csr_wr_user.svh"                   // user mode register writes

   //----------------------------------------------------------------------------------------------------------------------------------------
   //------------------------------------------------------------- CSR Read Logic -----------------------------------------------------------
   //----------------------------------------------------------------------------------------------------------------------------------------
   logic [4:0] ndx;
   logic       av;

   assign ndx = csr_addr[4:0];

   always_comb
   begin
      `ifdef SIM_DEBUG
         csr_rdata = 32'hz;                   // default csr_rd_data return value if csr[] doesn't exist - zzz's are easy to see in simulation
      `else
         csr_rdata = 32'h0;
      `endif
      csr_avail   = FALSE;

      // each include file can produce csr_rd_data and csr_avail for a specific csr_addr
      `include "csr_rd_mach.svh"             // machine mode register reads

      `include "csr_rd_super.svh"            // supervisor mode register reads

      `include "csr_rd_user.svh"             // user mode register reads

      `include "csr_rd_cntr_tmr.svh"         // Timer/Counter register reads for all modes
   end

endmodule
