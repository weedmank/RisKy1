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
// File          :  wb.sv
// Description   :  Write Back stage
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module wb
(
   input    logic                         reset_in,

   input    logic                         cpu_halt,                                 // Output:  disable CPU operations by not allowing any more input to this stage

   output   logic                         trigger_wfi,                              // WFI instruction may trigger a CPU halt

   // Fetch PC reload signals
   output   logic                         rld_pc_flag,                              // Output:  Cause the Fetch unit to reload the PC
   output   logic                         rld_ic_flag,                              // Output:  A STORE to L1 D$ also wrote to L1 I$ address space
   output   logic             [PC_SZ-1:0] rld_pc_addr,                              // Output:  PC address that will need to be reloaded

   // interface to Memory stage
   M2W_intf.slave                         M2W_bus,

   // CSR forwarding signals
   output   FWD_CSR                       fwd_wb_csr,
   // Register forwarding signals
   output   FWD_GPR                       fwd_wb_gpr,
   `ifdef ext_F
   // FPR forwarding signals
   output   FWD_FPR                       fwd_wb_fpr,

   // interface to FP Registers
   FPR_WR_intf.master                     fpr_wr_bus,
   `endif


   // interface to GPR
   GPR_WR_intf.master                     gpr_wr_bus,                               // master:  outputs:  Rd_wr, Rd_addr, Rd_data

   CSR_WR_intf.master                     csr_wr_bus                                // master -> output: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, instr_mode, uret, sret, mret
);

   // signals from MEM stage
   IP_Data                 ipd;
   logic       [PC_SZ-1:0] ls_addr;
   logic                   inv_flag;
   logic                   instr_err;
   `ifndef ext_C
   logic       [PC_SZ-1:0] br_pc;
   `endif
   logic                   ci;
   IG_TYPE                 ig_type;
   logic       [OP_SZ-1:0] op_type;
   logic                   mio_ack_fault;

   // signals created in this WB stage
   `ifdef ext_F
   logic                   wb_Fd_wr;                                                // Writeback stage needs to know whether to write to destination register Rd
   `endif
   logic                   wb_Rd_wr;                                                // Writeback stage needs to know whether to write to destination register Rd
   logic     [GPR_ASZ-1:0] wb_Rd_addr;
   logic         [RSZ-1:0] wb_Rd_data;

   logic                   wb_csr_wr;                                               // Writeback stage needs to know whether to write to destination register Rd
   logic            [11:0] wb_csr_addr;
   logic         [RSZ-1:0] wb_csr_wr_data;
   logic         [RSZ-1:0] wb_csr_fwd_data;

   // misc
   logic                   xfer_in;

   logic             [1:0] instr_mode;                                              // CPU mode when this instruction was in EXE stage

   logic       [PC_SZ-1:0] trap_pc;                                                 // Output:  trap vector handler address.
   logic                   irq_flag;                                                // 1 = take an interrupt trap
   logic             [3:0] irq_cause;                                               // value specifying what type of interrupt


   // --------------------------------- signals from MEM stage that are used in WB stage
   assign ipd                 = M2W_bus.data.ipd;
   assign ls_addr             = M2W_bus.data.ls_addr;
   assign inv_flag            = M2W_bus.data.inv_flag;
   assign instr_err           = M2W_bus.data.instr_err;                             // misaligned, illegal CSR access...
   assign ci                  = M2W_bus.data.ci;
   `ifndef ext_C
   assign br_pc               = M2W_bus.data.br_pc;
   `endif
   assign ig_type             = M2W_bus.data.ig_type;                               // override default values
   assign op_type             = M2W_bus.data.op_type;
   assign mio_ack_fault       = M2W_bus.data.mio_ack_fault;
   assign instr_mode          = M2W_bus.data.instr_mode;

   assign trap_pc             = {M2W_bus.data.trap_pc, 2'b00};                      // lower 2 bits (always 0) reattached. see mode_irq() module where they got removed
   assign irq_flag            = M2W_bus.data.irq_flag;
   assign irq_cause           = M2W_bus.data.irq_cause;

   // --------------------------------- asserted when this stage is ready to finish it's processing
   assign M2W_bus.rdy         = !reset_in & !cpu_halt;                              // always ready to process results

   assign xfer_in             = M2W_bus.valid & M2W_bus.rdy;

   // Forwarding of GPR info
   assign fwd_wb_gpr.valid    = M2W_bus.valid;
   assign fwd_wb_gpr.Rd_wr    = wb_Rd_wr;
   assign fwd_wb_gpr.Rd_addr  = wb_Rd_addr;
   assign fwd_wb_gpr.Rd_data  = wb_Rd_data;

   assign gpr_wr_bus.Rd_wr    = xfer_in & wb_Rd_wr;                                 // when to write
   assign gpr_wr_bus.Rd_addr  = wb_Rd_addr;                                         // Which destination register
   assign gpr_wr_bus.Rd_data  = wb_Rd_data;                                         // data for destination register

   `ifdef ext_F
   // Forwarding of FPR info
   assign fwd_wb_fpr.valid    = M2W_bus.valid;
   assign fwd_wb_fpr.Fd_wr    = wb_Fd_wr;
   assign fwd_wb_fpr.Fd_addr  = wb_Rd_addr;                                         // Rd_aadr and Rd_data can be shared from execute.sv as only Fd_wr and Rd_wr are mutually exclusive
   assign fwd_wb_fpr.Fd_data  = wb_Rd_data;

   assign fpr_wr_bus.Fd_wr       = xfer_in & wb_Fd_wr;                              // when to write
   assign fpr_wr_bus.Fd_addr     = wb_Rd_addr;                                      // Which destination register
   assign fpr_wr_bus.Fd_data     = wb_Rd_data;                                      // data for destination register
   `endif

   // Forwarding of CSR info
   assign fwd_wb_csr.valid       = M2W_bus.valid;
   assign fwd_wb_csr.csr_wr      = wb_csr_wr;
   assign fwd_wb_csr.csr_addr    = wb_csr_addr;
   assign fwd_wb_csr.csr_data    = wb_csr_fwd_data;

   //-------------------- csr_wr_bus --------------------
   // master (output: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret);
   logic   mret;
   assign csr_wr_bus.mret  = mret;

   `ifdef ext_S
   logic   sret;
   assign csr_wr_bus.sret  = sret;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   logic   uret;
   assign csr_wr_bus.uret  = uret;
   `endif
   `endif

   assign csr_wr_bus.csr_wr         = xfer_in & wb_csr_wr;                          // when to write
   assign csr_wr_bus.csr_wr_addr    = wb_csr_addr;                                  // Which destination register
   assign csr_wr_bus.csr_wr_data    = wb_csr_wr_data;                               // data for destination register
   //------------------------------- Debugging: disassemble instruction in this stage ------------------------------------
   `ifdef SIM_DEBUG
   string   i_str;
   string   pc_str;

   disasm wb_dis (ASSEMBLY,M2W_bus.data.ipd,i_str,pc_str);                          // disassemble each instruction
   `endif
   //---------------------------------------------------------------------------------------------------------------------

   EXCEPTION   exception;
   EVENTS      current_events;                                                   // number of retired instructions for current clock cycle
   logic       sw_irq;

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
   // 12-15            Reserved for future standard use
   // >=16             Reserved for platform use

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
   // 16-23            Reserved for future standard use
   // 24-31            Reserved for custom use
   // 32-47            Reserved for future standard use
   // 48-63            Reserved for custom use
   // >=64             Reserved for future standard use

   // p. 39 riscv-privileged draft 1.12
   // Priority    Exception Code    Description
   // Highest     3                 Instruction address breakpoint
   //             12                Instruction page fault
   //             1                 Instruction access fault
   //             2                 Illegal instruction
   //             0                 Instruction address misaligned
   //             8, 9, 11          Environment call
   //             3                 Environment break
   //             3                 Load/Store/AMO address breakpoint
   // Optionally, these may have    6 Store/AMO address misaligned
   // lowest priority instead.      4 Load address misaligned
   //             15                Store/AMO page fault
   //             13                Load page fault
   //             7                 Store/AMO access fault
   //             5                 Load access fault

   // ****** Exception handling also occurs here for all instructions - see data from EXE stage *****
   // Completed Load Instructions pass data on to WB stage. All exceptions occur in this MEM stage.  When an exception occurs,
   // all instructions in all stages of the pipeline are flushed.  See pipe_flush signal and how it affects pipe()
   always_comb
   begin
      // signals to update Rd/Fd in WB stage
      `ifdef ext_F
      wb_Fd_wr             = FALSE;
      `endif
      wb_Rd_wr             = FALSE;
      wb_Rd_addr           = '0;
      wb_Rd_data           = '0;

      wb_csr_wr            = FALSE;                                                 // Writeback stage needs to know whether to write to destination register Rd
      wb_csr_addr          = '0;
      wb_csr_wr_data       = '0;
      wb_csr_fwd_data      = '0;

      sw_irq               = 0;                                                     // msip_reg[3] = Software Interrupt Pending - from EXE stage

      rld_pc_flag          = FALSE;
      rld_ic_flag          = FALSE;
      rld_pc_addr          = '0;

      exception            = '0;          // default values

      current_events       = '0;

      trigger_wfi          = FALSE;

      mret                 = FALSE;

      `ifdef ext_S
      sret                 = FALSE;
      `endif

      `ifdef ext_U
      `ifdef ext_N
      uret                 = FALSE;
      `endif
      `endif

      // Note: All Exceptions are associated with trap_pc
      if (M2W_bus.valid)                                                            // should this instruction be processed by this stage?
      begin
         //////////////////////////////////////////////////////////
         // Exceptions, current events, and flush pipeline logic //
         //////////////////////////////////////////////////////////
         if (irq_flag)                                                              // overrides the current instruction - current instruction will be re-executed after interrupt
         begin
            rld_pc_flag                = TRUE;                                      // if irq_flag is set then an exception.flag CANNOT get set this cycle
            rld_pc_addr                = trap_pc;                                   // Trap Vector Base Address - from csr.sv

            exception.pc               = ipd.pc;                                    // save address of current instruction
            exception.tval             = ipd.instruction;                           // current Instruction
            exception.cause            = (1'b1 << (RSZ-1)) | irq_cause;             // Machine, Supervisor, or User external interrupt. see riscv-privileged.pdf p 91
            exception.flag             = TRUE;                                      // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

            `ifdef use_MHPM
            current_events.ext_irq     = TRUE;                                      // can't be covered by e_flag...becuase irq_cause is a 32 bit value that would interfere with e_cause numbers, so just set a single bit flag (ext_irq)
            `endif
         end
         else
            case(ig_type)                                                           // select which functional unit output data is the appropriate one to process
            ILL_INSTR:
            begin
               rld_pc_flag             = TRUE;                                      // flush pipeline and reload new fetch address
               rld_pc_addr             = trap_pc;

               exception.pc            = ipd.pc;                                    // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval          = ipd.instruction;                           // current Instruction
               exception.cause         = 2;                                         // 2 = Illegal Instruction
               exception.flag          = TRUE;                                      // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

               `ifdef use_MHPM
               current_events.e_flag   = TRUE;                                      // only used when use_MHPM is defined. See hpm_events in csr_regs.sv
               current_events.e_cause  = exception.cause;
               `endif
               current_events.ret_cnt[UNK_RET] = 1'b1;                              // number of ALU instructions retiring this clock cycle
            end

            ALU_INSTR:
            begin
               wb_Rd_wr          = M2W_bus.data.Rd_wr;                              // Writeback stage needs to know whether to write to destination register Rd
               wb_Rd_addr        = M2W_bus.data.Rd_addr;                            // Address of Rd register
               wb_Rd_data        = M2W_bus.data.Rd_data;                            // Data may be written into Rd register

               current_events.ret_cnt[ALU_RET] = 1'b1;                              // number of ALU instructions retiring this clock cycle
            end

            BR_INSTR:
            begin
               // -------------- xRET --------------
               // An xRET instruction can be executed in privilege mode x or higher, where executing a lower-privilege
               // xRET instruction will pop the relevant lower-privilege interrupt enable and privilege mode stack.
               case(op_type)
                  `ifdef ext_U
                  `ifdef ext_N      // see same logic in execute.sv
                  B_URET:                                                           // URET
                  begin // "OK to use in all modes though maybe technically nonsensical in S or M mode"
                     uret                       = TRUE;                             // URET completed correctly - "xRET sets the pc to the value stored in the x epc register." riscv-privileged. p 40
                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end
                  `endif // ext_N
                  `endif // ext_U

                  `ifdef ext_S
                  B_SRET:                                                           // SRET
                  begin
                     if (instr_mode < S_MODE)
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;                          // Trap Vector Base Address - from csr.sv/mode_irq.sv

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = ipd.instruction;                  // current Instruction
                        exception.cause         = 2;                                // 2 = Illegal Instruction
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        `ifdef use_MHPM
                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                        `endif
                     end
                     else
                         sret                   = TRUE;                             // SRET completed correctly - "xRET sets the pc to the value stored in the x epc register." riscv-privileged. p 40

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end
                  `endif // ext_S

                  B_MRET:                                                           // MRET
                  begin
                     if (instr_mode < M_MODE)                                       // Illegal to use in Supervisor or User modes
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;                          // Trap Vector Base Address - from csr.sv/mode_irq.sv

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = ipd.instruction;                  // current Instruction
                        exception.cause         = 2;                                // 2 = Illegal Instruction
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        `ifdef use_MHPM
                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                        `endif
                     end
                     else
                        mret                    = TRUE;                             // MRET completed correctly - "xRET sets the pc to the value stored in the x epc register." riscv-privileged. p 40

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end

                  // -------------- Bxx --------------
                  `ifdef ext_C
                  B_C,
                  `endif
                  B_ADD:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (instr_err)
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = br_pc;                            // misaligned branch address
                        exception.cause         = 0;                                // 0 = Instruction Address Misaligned
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        `ifdef use_MHPM
                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                        `endif
                     end
                     else
                     `endif

                     current_events.ret_cnt[BXX_RET] = 1'b1;                        // number of BXX instructions retiring this clock cycle
                  end

                  // -------------- JAL, JALR --------------
                  B_JAL, B_JALR:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (instr_err)                                                 // not TRUE for 16 bit instructions
                     begin
                        rld_pc_flag             = TRUE;                             // flush pipeline and reload new fetch address
                        rld_pc_addr             = trap_pc;

                        exception.pc            = ipd.pc;                           // save address of current instruction
                        exception.tval          = br_pc;                            // misaligned branch address
                        exception.cause         = 0;                                // 0 = Instruction Address Misaligned
                        exception.flag          = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                        `ifdef use_MHPM
                        current_events.e_flag   = TRUE;
                        current_events.e_cause  = exception.cause;
                        `endif
                     end
                     else
                     `endif
                     begin
                        wb_Rd_wr                = M2W_bus.data.Rd_wr;               // Writeback stage needs to know whether to write to destination register Rd
                        wb_Rd_addr              = M2W_bus.data.Rd_addr;             // Address of Rd register
                        wb_Rd_data              = M2W_bus.data.Rd_data;             // Data may be written into Rd register
                     end
                     if (op_type == B_JALR)
                        current_events.ret_cnt[JALR_RET] = 1'b1;                    // number of CSR instructions retiring this clock cycle
                     else
                        current_events.ret_cnt[JAL_RET] = 1'b1;                     // number of JAL instructions retiring this clock cycle
                  end
               endcase
            end

            `ifdef ext_M
            IM_INSTR:
            begin
               wb_Rd_wr             = M2W_bus.data.Rd_wr;                           // Writeback stage needs to know whether to write to destination register Rd
               wb_Rd_addr           = M2W_bus.data.Rd_addr;                         // Address of Rd register
               wb_Rd_data           = M2W_bus.data.Rd_data;                         // Data may be written into Rd register

               current_events.ret_cnt[IM_RET] = 1'b1;                               // number of Integer Multiply instructions retiring this clock cycle
            end

            IDR_INSTR:
            begin
               wb_Rd_wr             = M2W_bus.data.Rd_wr;                           // Writeback stage needs to know whether to write to destination register Rd
               wb_Rd_addr           = M2W_bus.data.Rd_addr;                         // Address of Rd register
               wb_Rd_data           = M2W_bus.data.Rd_data;                         // Data may be written into Rd register

               if (op_type inside {REM, REMU})
                  current_events.ret_cnt[IR_RET] = 1'b1;                            // number of REM, REMU instructions retiring this clock cycle
               else
                  current_events.ret_cnt[ID_RET] = 1'b1;                            // number of DIV, DIVUinstructions retiring this clock cycle
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
                     exception.cause            = {2'b10,instr_mode};               // ECALL generates a different exception for each originating privilege mode so that environment call exceptions can be selectively delegated.
                     exception.flag             = TRUE;                             // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                     `ifdef use_MHPM
                     current_events.e_flag      = TRUE;
                     current_events.e_cause     = exception.cause;
                     `endif
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

                     `ifdef use_MHPM
                     current_events.e_flag      = TRUE;
                     current_events.e_cause     = exception.cause;
                     `endif
                     current_events.ret_cnt[SYS_RET] = 1'b1;                        // number of SYS instructions retiring this clock cycle
                  end

                  WFI:                                                              // NOTE: "...a legal implementation is to simply implement WFI as a NOP"
                  begin
// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
//                     if (mstatus.twi || (D2E_bus.data.funct3 > instr_mode))         // see riscv_privileged-20190608.pdf  p.41
//                     begin
                     trigger_wfi = TRUE;
//                     end

                     current_events.ret_cnt[SYS_RET] = 1'b1;                              // number of SYS instructions retiring this clock cycle
                  end
               endcase
            end

            CSR_INSTR:
            begin
               if (instr_err)
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address - from csr.sv

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = M2W_bus.data.Rd_data;                   // faulting address - saved in Rd_data in execute.sv
                  exception.cause         = 1;                                      // 1 = Instruction Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  `ifdef use_MHPM
                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
                  `endif
               end
               else
               begin
                  wb_Rd_wr                = M2W_bus.data.Rd_wr;                     // Writeback stage needs to know whether to write to destination register Rd
                  wb_Rd_addr              = M2W_bus.data.Rd_addr;                   // Address of Rd register
                  wb_Rd_data              = M2W_bus.data.Rd_data;                   // Data may be written into Rd register

                  wb_csr_wr               = M2W_bus.data.csr_wr;
                  wb_csr_addr             = M2W_bus.data.csr_addr;
                  wb_csr_wr_data          = M2W_bus.data.csr_wr_data;
                  wb_csr_fwd_data         = M2W_bus.data.csr_fwd_data;

                  sw_irq                  = M2W_bus.data.sw_irq;                    // from EXE stage - now needed in csr_fu.sv to complete instruction
               end
               current_events.ret_cnt[CSR_RET] = 1'b1;                              // number of CSR instructions retiring this clock cycle
            end

            LD_INSTR:
            begin
               // Load exceptions are done once Load finishes in MEM stage. see priority table p. 39 riscv_privileged draft 1.12
               if (instr_err)                                                       // misaligned? see execute.sv
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // bad address
                  exception.cause         = 4;                                      // 4 = Load Address Misaligned
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  `ifdef use_MHPM
                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
                  `endif
               end
               else if (mio_ack_fault)                                              // Raise exception for access to an unused address space? p7 Volume I: RISC-V Unprivileged ISA V20190608-Base-Ratified
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // acccess fault address
                  exception.cause         = 5;                                      // 5 = Load Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  `ifdef use_MHPM
                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
                  `endif
               end
               else
               begin
                  wb_Rd_wr                = M2W_bus.data.Rd_wr;                     // Writeback stage needs to know whether to write to destination register Rd
                  wb_Rd_addr              = M2W_bus.data.Rd_addr;                   // Address of Rd register
                  wb_Rd_data              = M2W_bus.data.Rd_data;                   // Data may be written into Rd register
               end
               current_events.ret_cnt[LD_RET] = 1'b1;                               // number of Load instructions retiring this clock cycle
            end

            ST_INSTR:
            begin
               // Store exceptions arer done once Store finishes in this MEM stage. see priority table p. 39 riscv_privileged draft 1.12
               if (instr_err)
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // bad address
                  exception.cause         = 6;                                      // 6 = Store Address Misaligned
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  `ifdef use_MHPM
                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
                  `endif
               end
               else if (mio_ack_fault)                                              // Raise exception for access to an unused address space. p7 Volume I: RISC-V Unprivileged ISA V20190608-Base-Ratified
               begin
                  rld_pc_flag             = TRUE;
                  rld_pc_addr             = trap_pc;                                // Trap Vector Base Address

                  exception.pc            = ipd.pc;                                 // address of current instruction to be saved in mepc, sepc, or uepc register
                  exception.tval          = ls_addr;                                // acccess fault address
                  exception.cause         = 7;                                      // 7 = Store Access Fault
                  exception.flag          = TRUE;                                   // control signal to save exception.pc, exception.tval and exception.cause in csr.sv

                  `ifdef use_MHPM
                  current_events.e_flag   = TRUE;
                  current_events.e_cause  = exception.cause;
                  `endif
               end
               else
               begin
                  if (inv_flag)                                                     // A STORE to L1 D$ also wrote to L1 I$ address space (L1D$ notifies L1I$ of issue so that it invalidates teh proper cache line)
                  begin                                                             // This is NOT an exception, but just need to flush pipe and reload I$ due to Load/Store in I$ space
                     rld_pc_flag          = TRUE;
                     rld_ic_flag          = TRUE;
                     rld_pc_addr          = PC_SZ'(ipd.pc + (ci ? 2'd2 : 3'd4));    // reload PC address after this STORE instruction due to I$ invalidation logic
                  end
                  // Store does not write any info to GPR registers
                  current_events.ret_cnt[ST_RET] = 1'b1;                            // number of Store instructions retiring this clock cycle
               end
            end

            // logic that will affect wb_Fd_wr, wb_Rd_addr and wb_Rd_data for Single Precision Floating Point
            `ifdef ext_F
            `include "spfp_instr_cases.svh"   // logic for Single-precision Floating Point instructions could get large, so including code instead of writing code here
            `endif
         endcase
      end // M2W_bus.valid
   end // always_comb

   assign csr_wr_bus.exception      = exception;
   assign csr_wr_bus.sw_irq         = sw_irq;                                       // msip_reg[3] = Software Interrupt Pending - from EXE stage
   assign csr_wr_bus.current_events = current_events;                               // number of retired instructions for current clock cycle

endmodule