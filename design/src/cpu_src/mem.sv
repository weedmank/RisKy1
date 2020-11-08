// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  mem.sv
// Description   :  This module read/writes to System Memory (Load/Store)
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module mem
(
   input    logic                         clk_in,
   input    logic                         reset_in,

   // used in CSRs
   `ifdef ext_N
   input    logic                         ext_irq,                // Input:   External Interrupt
   input    logic                         time_irq,               // Input:   Timer Interrupt from clint.sv
   input    logic                         sw_irq,                 // Input:   Software Interrupt from clint.sv
   `endif
   input    logic             [2*RSZ-1:0] mtime,                  // Input:   Memory-mapped mtime register contents

   // misprediction signals to other stages
   input    logic                         pipe_flush,             // Input:   1 = Flush this segment of the pipeline

   // Fetch PC reload signals
   output   logic                         rld_pc_flag,            // Output:  Cause the Fetch unit to reload the PC
   output   logic                         rld_ic_flag,            // Output:  A STORE to L1 D$ also wrote to L1 I$ address space
   output   logic             [PC_SZ-1:0] rld_pc_addr,            // Output:  PC address that will need to be reloaded

   output   logic                         cpu_halt,               // Input:   disable CPU operations by not allowing any more input to this stage

   `ifdef ext_F
   // interface to forwarding signals
   output   FWD_FPR                       fwd_mem_fpr,
   `endif

   // interface to forwarding signals
   output   FWD_GPR                       fwd_mem_gpr,

   // System Memory or I/O interface signals
   L1DC_intf.master                       MIO_bus,

   // interface to Execute stage
   E2M_intf.slave                         E2M_bus,

   // interface to WB stage
   M2W_intf.master                        M2W_bus,

   // signals between CSR Functional Unit (inside EXE stage) and MEM stage
   CSR_MEM_intf.slave                     CSR_MEM_bus
);

   MEM_2_WB                mem_dout;
   logic                   rd_pipe_out, wr_pipe_out;
   logic                   rd_pipe_in;
   logic                   full;
   logic                   is_ls;                                                   // this is a Load or Store instruction

   logic       [PC_SZ-1:0] ls_addr;
   logic         [RSZ-1:0] st_data;
   logic             [2:0] size;
   logic                   zero_ext;  // 1 = LBU or LHU
   logic                   inv_flag;
   logic                   is_ld;
   logic                   is_st;
   logic                   mis;
   logic                   mispre;
   logic                   ci;
   logic       [PC_SZ-1:0] br_pc;

   logic                   Rd_wr;                                                   // Writeback stage needs to know whether to write to destination register Rd
   logic     [GPR_ASZ-1:0] Rd_addr;
   logic         [RSZ-1:0] Rd_data;

   logic                   trigger_wfi;

   I_TYPE                  i_type;
   logic       [OP_SZ-1:0] op_type;

   IP_Data                 ipd;
   logic       [PC_SZ-1:0] predicted_addr;

      // signals used in MEM stage
   assign ls_addr                      = E2M_bus.data.ls_addr;
   assign st_data                      = E2M_bus.data.st_data;
   assign size                         = E2M_bus.data.size;                         // default when not a load or store
   assign zero_ext                     = E2M_bus.data.zero_ext;                     // 1 = LBU or LHU
   assign inv_flag                     = E2M_bus.data.inv_flag;
   assign is_ld                        = E2M_bus.data.is_ld;
   assign is_st                        = E2M_bus.data.is_st;
   assign mis                          = E2M_bus.data.mis;
   assign ci                           = E2M_bus.data.ci;
   assign br_pc                        = E2M_bus.data.br_pc;
   assign is_ls                        = (is_ld | is_st);

   // control logic for interface to Execution Stage
   // NOTE: No Load/Store QUE yet.. Just stalls until Load/Store completes - this will get updated in a future release
   assign E2M_bus.rdy                  = (!full & !reset_in & !cpu_halt & (MIO_bus.ack | !is_ls)); // Load/Store: Wait for Ack if accessing Memory or I/O

   assign rd_pipe_in                   = E2M_bus.valid & E2M_bus.rdy;               // pop data from EXE_PIPE pipeline register..
   assign wr_pipe_out                  = rd_pipe_in;                                // ...and write new data into MEM_PIPE registers
   assign rd_pipe_out                  = M2W_bus.valid & M2W_bus.rdy;               // pops data from MEM_PIPE registers to next stage

   `ifdef ext_F
   // Forwarding of FPR info
   assign fwd_mem_fpr.valid            = is_ld ? MIO_bus.ack : (E2M_bus.valid & !full & !reset_in & !cpu_halt); // Load data (MIO_bus.ack_data) not valid until MIO_bus.ack
   assign fwd_mem_fpr.Fd_wr            = mem_dout.Fd_wr;
   assign fwd_mem_fpr.Fd_addr          = mem_dout.Rd_addr;
   assign fwd_mem_fpr.Fd_data          = mem_dout.Rd_data;                          // return data from D$ if FP Load instruction, otherwise uses Rd_data from EXE stage
   `endif

   // Forwarding of GPR info
   assign fwd_mem_gpr.valid            = is_ld ? MIO_bus.ack : (E2M_bus.valid & !full & !reset_in & !cpu_halt); // Load data (MIO_bus.ack_data) not valid until MIO_bus.ack
   assign fwd_mem_gpr.Rd_wr            = mem_dout.Rd_wr;
   assign fwd_mem_gpr.Rd_addr          = mem_dout.Rd_addr;
   assign fwd_mem_gpr.Rd_data          = mem_dout.Rd_data;                          // return data from D$ if integer Load instruction, otherwise uses Rd_data from EXE stage

   // Load/Stores go to either System Memory or I/O - MIO_bus()
   assign MIO_bus.req_data.rd          = is_ld;                                     // Read == 1
   assign MIO_bus.req_data.wr          = is_st;                                     // Write == 1
   assign MIO_bus.req_data.rw_addr     = ls_addr;                                   // Load/Store Address
   assign MIO_bus.req_data.wr_data     = st_data;
   assign MIO_bus.req_data.size        = size;                                      // see ST_BYTE, ST_HALF,... values in op_encodings_B64.svh
   assign MIO_bus.req_data.zero_ext    = zero_ext;                                  // zero extend for Loads
   assign MIO_bus.req_data.inv_flag    = inv_flag;                                  // 1 = A store to L1 D$ also wrote to L1 I$ address space
   assign MIO_bus.req                  = E2M_bus.valid & !full & !reset_in & !cpu_halt & is_ls; // request to D$ only if a Load or Store instruction



   `ifdef SIM_DEBUG
   string   i_str;                                                                  // Debugging: disassemble instruction in this stage
   string   pc_str;

   disasm mem_dis (ASSEMBLY,ipd,i_str,pc_str);                                      // disassemble each instruction
   `endif
   //--------------------- CSR_MEM_bus -------------------
   `ifdef ext_N
   logic                   interrupt_flag;                                          // 1 = take an interrupt trap
   logic         [RSZ-1:0] interrupt_cause;                                         // value specifying what type of interrupt
   `endif
   logic       [PC_SZ-1:0] trap_pc;                                                 // trap vector handler address.
   logic                   ialign;                                                  // 1 = 16 bit alignment, 0 = 32 bit alignment
   logic             [1:0] mode;

   EXCEPTION               exception;
   EVENTS                  current_events;                                          // number of retired instructions for current clock cycle

   //-------------------- CSR_MEM_bus --------------------
   `ifdef ext_N
   assign interrupt_flag               = CSR_MEM_bus.interrupt_flag;
   assign interrupt_cause              = CSR_MEM_bus.interrupt_cause;
   `endif
   assign trap_pc                      = CSR_MEM_bus.trap_pc;
   assign ialign                       = CSR_MEM_bus.ialign;                        // 1 = 16 bit alignment, 0 = 32 bit alignment
   assign mode                         = CSR_MEM_bus.mode;

   assign CSR_MEM_bus.exception        = exception;
   assign CSR_MEM_bus.current_events   = current_events;                            // number of retired instructions for current clock cycle
   `ifdef ext_N
   assign CSR_MEM_bus.ext_irq          = ext_irq;
   assign CSR_MEM_bus.time_irq         = time_irq;
   assign CSR_MEM_bus.sw_irq           = sw_irq;
   `endif
   assign CSR_MEM_bus.mtime            = mtime;

   //------------------- CPU Halt Logic ------------------
   `ifdef ext_N
   // Putting CPU to sleep and waking it up
   always_ff @(posedge clk_in)
   begin
      if (reset_in || ext_irq)
         cpu_halt <= FALSE;
      else if (trigger_wfi)
         cpu_halt <= TRUE;
   end
   `else
   assign cpu_halt = FALSE;
   `endif

   //-----------------------------------------------------
   // Interrupt Code   Description - riscv_privileged.pdf p 37
   // 0                User software interrupt
   // 1                Supervisor software interrupt
   // 2                Reserved for future standard use
   // 3                Machine software interrupt
   // 4                User timer interrupt
   // 5                Supervisor timer interrupt
   // 6                Reserved for future standard use
   // 7                Machine timer interrupt
   // 8                User external interrupt
   // 9                Supervisor external interrupt
   // 10               Reserved for future standard use
   // 11               Machine external interrupt
   // 12–15            Reserved for future standard use
   // ≥16              Reserved for platform use

   // Exception Code   Description - riscv_privileged.pdf p 37
   // 0                Instruction address misaligned
   // 1                Instruction access fault
   // 2                Illegal instruction
   // 3                Breakpoint
   // 4                Load address misaligned
   // 5                Load access fault
   // 6                Store/AMO address misaligned
   // 7                Store/AMO access fault
   // 8                Environment call from U-mode
   // 9                Environment call from S-mode
   // 10               Reserved
   // 11               Environment call from M-mode
   // 12               Instruction page fault
   // 13               Load page fault
   // 14               Reserved for future standard use
   // 15               Store/AMO page fault
   // 16–23            Reserved for future standard use
   // 24–31            Reserved for custom use
   // 32–47            Reserved for future standard use
   // 48–63            Reserved for custom use
   // ≥64              Reserved for future standard use

   // ****** Exception handling also occurs here for all instructions - see data from EXE stage *****
   // Completed Load Instructions pass data on to WB stage. All exceptions occur in this MEM stage.  When an exception occurs, all instructions in this
   // stage (Memory) and previous stages (Fetch, Decode, Execute) are flushed.  See pipe_flush signal and how it affects pipe()
   always_comb
   begin
      rld_pc_flag       = FALSE;
      rld_ic_flag       = FALSE;
      rld_pc_addr       = '0;

      exception         = '0;          // default values

      current_events    = '0;

      i_type            = ILL_INSTR;
      op_type           = '0;

      // signals to update Rd/Fd in WB stage
      `ifdef ext_F
      Fd_wr             = '0;
      `endif
      Rd_wr             = '0;                                                       // Writeback stage needs to know whether to write to destination register Rd
      Rd_addr           = '0;
      Rd_data           = '0;
      ipd               = '0;
      predicted_addr    = '0;
      mispre            = FALSE;

      trigger_wfi       = FALSE;

      mem_dout          = '0;

      // Note: All Exceptions are associated with trap_pc
      if (E2M_bus.valid)                                                            // should this instruction be processed by this stage?
      begin
         i_type                        = E2M_bus.data.i_type;                       // override default values
         op_type                       = E2M_bus.data.op_type;

         // signals to update Rd/Fd in WB stage
         `ifdef ext_F
         Fd_wr                         = E2M_bus.data.Fd_wr;
         `endif
         Rd_wr                         = E2M_bus.data.Rd_wr;                        // Writeback stage needs to know whether to write to destination register Rd
         Rd_addr                       = E2M_bus.data.Rd_addr;
         Rd_data                       = E2M_bus.data.Rd_data;
         ipd                           = E2M_bus.data.ipd;
         predicted_addr                = E2M_bus.data.predicted_addr;
         mispre                        = E2M_bus.data.mispre;

         `ifdef ext_N
         if (interrupt_flag)                                                        // overrides the current instruction - current instruction will be re-executed after interrupt
         begin
            rld_pc_flag                = TRUE;                                      // if interrupt_flag is set then an exception.flag CANNOT get set this cycle
            rld_pc_addr                = trap_pc;                                   // Trap Vector Base Address - from csr.sv

            exception.pc               = ipd.pc;                                    // save address of current instruction
            exception.tval             = ipd.instruction;                           // current Instruction
            exception.cause            = interrupt_cause;                           // Machine, Supervisor, or User external interrupt. see riscv-privileged.pdf p 91
            exception.flag             = TRUE;                                      // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

            current_events.ext_irq     = TRUE;                                      // can't be covered by e_flag...becuase interrupt_cause is a 32 bit value that would interfere with e_cause numbers, so just set a single bit flag (ext_irq)
         end
         else
         `endif
         unique case(i_type)                                                        // select which functional unit output data is the appropriate one to process
            ILL_INSTR:
            begin
               rld_pc_flag             = TRUE;                                      // flush pipeline and reload new fetch address
               rld_pc_addr             = trap_pc;

               exception.pc            = ipd.pc;                                    // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval          = ipd.instruction;                           // current Instruction
               exception.cause         = 2;                                         // 2 = Illegal Instruction
               exception.flag          = TRUE;                                      // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

               current_events.e_flag   = TRUE;
               current_events.e_cause  = exception.cause;

               current_events.ret_cnt[UNK_RET] = 1'b1;                              // number of ALU instructions retiring this clock cycle
            end

            ALU_INSTR:
            begin
               mem_dout.Rd_wr          = Rd_wr;                                     // Writeback stage needs to know whether to write to destination register Rd
               mem_dout.Rd_addr        = Rd_addr;                                   // Address of Rd register
               mem_dout.Rd_data        = Rd_data;                                   // Data may be written into Rd register

               current_events.ret_cnt[ALU_RET] = 1'b1;                              // number of ALU instructions retiring this clock cycle
            end

            BR_INSTR:
            begin
               // Instruction-address-misaligned exceptions are reported on the branch or jump that would
               // cause instruction misalignment to help debugging, and to simplify hardware design for systems
               // with IALIGN=32, where these are the only places where misalignment can occur. riscv-spec.pdf p 16
               // A B_xRET instruction can be executed in privilege mode x or higher, where executing a lower-privilege
               // A B_xRET instruction will pop the relevant lower-privilege interrupt enable and privilege mode stack.
               // In addition to manipulating the privilege stack as described in Section 3.1.6.1, B_xRET sets the pc
               // to the value stored in the x epc register.  see riscv-privileged-20190608-1.pdf p 40
               // -------------- xRET --------------
               case(op_type)
                  `ifdef ext_U
                  B_URET:                                                           // URET
                  begin // "OK to use in all modes though maybe technically nonsensical in S or M mode"
                     if (mispre)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end
                  `endif // ext_U

                  `ifdef ext_S
                  B_SRET:                                                           // SRET
                  begin
                     if (mode < S_MODE)
                     begin
                        rld_pc_flag             = TRUE;
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = ipd.instruction;                  // current Instruction
                        exception.cause         = 2;                                // 2 = Illegal Instruction
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                     end
                     else if (mispre)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end
                  `endif // ext_S

                  B_MRET:                                                           // MRET
                  begin
                     if (mode < M_MODE)                                             // Illegal to use in Supervisor or User modes
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;                          // Trap Vector Base Address - from csr.sv

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = ipd.instruction;                  // current Instruction
                        exception.cause         = 2;                                // 2 = Illegal Instruction
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                     end
                     else if (mispre)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end

                  // -------------- Bxx --------------
                  B_ADD:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (mis)
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = br_pc;                            // misaligned branch address
                        exception.cause         = 0;                                // 0 = Instruction Address Misaligned
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                     end
                     else
                     `endif
                     if (predicted_addr != br_pc)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end

                  // -------------- JAL --------------
                  B_JAL:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (mis)
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = br_pc;                            // misaligned branch address
                        exception.cause         = 0;                                // 0 = Instruction Address Misaligned
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                     end
                     else
                     `endif
                     if (predicted_addr != br_pc)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception
                     else
                     begin
                        mem_dout.Rd_wr          = Rd_wr;                            // Writeback stage needs to know whether to write to destination register Rd for this jump
                        mem_dout.Rd_addr        = Rd_addr;                          // Address of Rd register
                        mem_dout.Rd_data        = Rd_data;                          // address of instruction immediately after this branch instruction - no_br_pc was saved in Rd_data in EXE stage
                     end

                     current_events.ret_cnt[JAL_RET] = 1'b1;                        // number of JAL instructions retiring this clock cycle
                  end

                  // -------------- JALR --------------
                  B_JALR:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (mis)                                                       // not TRUE for 16 bit instructions
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = br_pc;                            // misaligned branch address
                        exception.cause         = 0;                                // 0 = Instruction Address Misaligned
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                     end
                     else
                     `endif
                     if (predicted_addr != br_pc)
                        current_events.mispredict = TRUE;                           // can't be covered using e_flag... becuase this is not an exception
                     else
                     begin
                        mem_dout.Rd_wr          = Rd_wr;                            // Writeback stage needs to know whether to write to destination register Rd for this jump
                        mem_dout.Rd_addr        = Rd_addr;
                        mem_dout.Rd_data        = Rd_data;                          // address of instruction immediately after this branch instruction - no_br_pc was saved to .Rd_data in EXE stage
                     end
                     current_events.ret_cnt[JALR_RET] = 1'b1;                       // number of CSR instructions retiring this clock cycle
                  end
               endcase
            end

            `ifdef ext_M
            IM_INSTR:
            begin
               mem_dout.Rd_wr       = Rd_wr;                                        // Writeback stage needs to know whether to write to destination register Rd
               mem_dout.Rd_addr     = Rd_addr;                                      // Address of Rd register
               mem_dout.Rd_data     = Rd_data;

               current_events.ret_cnt[IM_RET] = 1'b1;                               // number of Integer Multiply instructions retiring this clock cycle
            end

            IDR_INSTR:
            begin
               mem_dout.Rd_wr       = Rd_wr;                                        // Writeback stage needs to know whether to write to destination register Rd
               mem_dout.Rd_addr     = Rd_addr;                                      // Address of Rd register
               mem_dout.Rd_data     = Rd_data;

               if (op_type inside {REM, REMU})
                  current_events.ret_cnt[ID_RET] = 1'b1;                            // number of CSR instructions retiring this clock cycle
               else
                  current_events.ret_cnt[IR_RET] = 1'b1;                            // number of CSR instructions retiring this clock cycle
            end
            `endif // ext_M

            `ifdef HINT_C_NOP // | HINT_xxx ... any other hint
            HINT_INSTR:
            begin
               // HINTS are user defined and optional

               // logic for decoding which HINT and any associated logic would go here
               // See decode_core.sv for a list of specific hints that may be used.
               /*
               case (D2E_bus.data.imm)
                  HINT_C_NOP:
                  begin
                     ...more code to do the HINT_C_NOP would go here... see decode_core.sv for the specific code point.
                  end
                  ...
               endcase
               */
               current_events.ret_cnt[HINT_RET] = 1'b1;                             // number of HINT instructions retiring this clock cycle
            end
            `endif

            SYS_INSTR:
            begin
               unique case(op_type)
                  `ifdef ext_ZiF
                  FENCEI:
                  begin
// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
                     // Flush Fetch and Decode stages
                     current_events.ret_cnt[SYS_RET] = 1'b1;                        // number of SYS instructions retiring this clock cycle
                  end

                  FENCE:
                  begin
// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
                     current_events.ret_cnt[SYS_RET] = 1'b1;                        // number of SYS instructions retiring this clock cycle
                  end
                  `endif

                  ECALL:
                  begin
                     rld_pc_flag                = TRUE;                             // flush pipeline and reload new fetch address
                     rld_pc_addr                = trap_pc;                          // Trap Vector Base Address - from csr.sv

                     exception.pc               = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
                     exception.tval             = ipd.instruction;                  // current Instruction (can't find anything about this for this exception! maybe it shouldn't be tested???)
                     exception.cause            = {2'b10,mode};                     // ECALL generates a different exception for each originating privilege mode so that environment call exceptions can be selectively delegated.
                     exception.flag             = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                     current_events.e_flag      = TRUE;
                     current_events.e_cause     = exception.cause;
                     current_events.ret_cnt[SYS_RET] = 1'b1;                        // number of SYS instructions retiring this clock cycle
                  end

                  EBREAK:
                  begin
                     rld_pc_flag                = TRUE;                             // flush pipeline and reload new fetch address
                     rld_pc_addr                = trap_pc;                          // Trap Vector Base Address - from csr.sv

                     exception.pc               = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
                     exception.tval             = ipd.instruction;                  // current Instruction
                     exception.cause            = 3;                                // 3 = Environment Break. see p. 38 riscv-privileged.pdf
                     exception.flag             = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                     current_events.e_flag      = TRUE;
                     current_events.e_cause     = exception.cause;
                     current_events.ret_cnt[SYS_RET] = 1'b1;                        // number of SYS instructions retiring this clock cycle
                  end

                  WFI:                                                              // NOTE: "...a legal implementation is to simply implement WFI as a NOP"
                  begin
// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
//                     if (mstatus.twi || (D2E_bus.data.funct3 > mode))               // see riscv_privileged-20190608.pdf  p.41
//                     begin
//                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
//                        rld_pc_addr             = trap_pc;
//
//                        exception.pc            = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
//                        exception.tval          = ipd.instruction;                  // current Instruction
//                        exception.cause         = 2;                                // 2 = Illegal Instruction
//                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv
//                     end
                  end
               endcase

               current_events.ret_cnt[SYS_RET] = 1'b1;                              // number of SYS instructions retiring this clock cycle
            end

            CSR_INSTR:
            begin
               if (mis)
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address - from csr.sv

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = Rd_data;                                // faulting address - saved in Rd_data in execute.sv
                  exception.cause         = 1;                                      // 1 = Instruction Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
               end
               else
               begin
                  mem_dout.Rd_wr          = Rd_wr;                                  // Writeback stage needs to know whether to write to destination register Rd
                  mem_dout.Rd_addr        = Rd_addr;                                // Address of Rd register
                  mem_dout.Rd_data        = Rd_data;                                // value used to update Rd in WB stage
               end

               current_events.ret_cnt[CSR_RET] = 1'b1;                              // number of CSR instructions retiring this clock cycle
            end

            LD_INSTR:
            begin
               // Load exceptions are done once Load finishes in MEM stage
               if (MIO_bus.ack & mis)                                              // misaligned?
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // bad address
                  exception.cause         = 4;                                      // 4 = Load Address Misaligned
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
               end
               else if (MIO_bus.ack & MIO_bus.ack_fault)                            // Raise exception for access to an unused address space? p7 Volume I: RISC-V Unprivileged ISA V20190608-Base-Ratified
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // acccess fault address
                  exception.cause         = 5;                                      // 5 = Load Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
               end
               else
               begin
                  mem_dout.Rd_wr          = Rd_wr;                                  // Writeback stage needs to know whether to write to destination register Rd
                  mem_dout.Rd_addr        = Rd_addr;                                // Address of Rd register
                  mem_dout.Rd_data        = MIO_bus.ack_data;                       // value used to update Rd in WB stage
               end
               current_events.ret_cnt[LD_RET] = 1'b1;                               // number of Load instructions retiring this clock cycle
            end

            ST_INSTR:
            begin
               // Store exceptions arer done once Store finishes in this MEM stage
               if (MIO_bus.ack & mis)
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // bad address
                  exception.cause         = 6;                                      // 6 = Store Address Misaligned
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
               end
               else if (MIO_bus.ack & MIO_bus.ack_fault)                            // Raise exception for access to an unused address space. p7 Volume I: RISC-V Unprivileged ISA V20190608-Base-Ratified
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // acccess fault address
                  exception.cause         = 7;                                      // 7 = Store Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
               end
               else
               begin
                  if (inv_flag)                                                     // A STORE to L1 D$ also wrote to L1 I$ address space (L1D$ notifies L1I$ of issue so that it invalidates teh proper cache line)
                  begin                                                             // This is NOT an exception, but just need to flush pipe and reload I$ due to Load/Store in I$ space
                     rld_pc_flag          = TRUE;
                     rld_ic_flag          = TRUE;
                     rld_pc_addr          = ipd.pc + (ci ? 2'd2 : 3'd4);            // reload PC address after this STORE instruction due to I$ invalidation logic
                  end
                  // Store does not write any info to GPR registers
                  current_events.ret_cnt[ST_RET] = 1'b1;                            // number of Store instructions retiring this clock cycle
               end
            end

            `ifdef ext_F

            `include "spfp_instr_cases.svh"   // logic for Single-precision Floating Point instructions could get large, so including code instead of writing code here

            `endif
         endcase
      end
   end

   // Set of Flip Flops (for pipelining) with control logic ('full' signal) sitting between Memory stage and the WB stage
   pipe #( .T(type(MEM_2_WB)) ) MEM_PIPE
   (
      .clk_in(clk_in),    .reset_in(reset_in | pipe_flush),
      .write_in(wr_pipe_out),  .data_in(mem_dout),      .full_out(full),
      .read_in(rd_pipe_out),   .data_out(M2W_bus.data), .valid_out(M2W_bus.valid)
   );

endmodule
