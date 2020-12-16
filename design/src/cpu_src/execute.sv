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
// File          :  execute.sv
// Description   :  This module instantiates various functional units that execute instructions
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module execute
(
   input    logic                         clk_in,
   input    logic                         reset_in,

   input   logic                          cpu_halt,                        // Input:  cause CPU to stop processing instructions & data

   // signals shared between EXE stage and csr.sv
   CSR_EXE_intf.slave                     csr_exe_bus,

   // pipeline flush signal
   input    logic                         pipe_flush,                      // Input:   1 = Flush this segment of the pipeline

   // Fetch PC reload signals
   output   logic                         rld_pc_flag,                     // Output:  Cause the Fetch unit to reload the PC
   output   logic             [PC_SZ-1:0] rld_pc_addr,                     // Output:  PC address that will need to be reloaded

   // interface to forwarding signals
   input    var FWD_CSR                   fwd_mem_csr,
   input    var FWD_GPR                   fwd_mem_gpr,

   input    var FWD_CSR                   fwd_wb_csr,
   input    var FWD_GPR                   fwd_wb_gpr,

   `ifdef ext_F
   // interface to forwarding signals
   input    var FWD_FPR                   fwd_mem_fpr,
   input    var FWD_FPR                   fwd_wb_fpr,

   // interface to FPR
   input         [MAX_FPR-1:0] [FLEN-1:0] fpr,                             // MAX_FPR single-precision Floating Point registers
   `endif

   // interface to GPR
   input          [MAX_GPR-1:0] [RSZ-1:0] gpr,                             // MAX_GPR General Purpose registers

   // interface to Decode stage
   D2E_intf.slave                         D2E_bus,

   // interface to Memory stage
   E2M_intf.master                        E2M_bus,

   // CSR read bus - connects to CSR to read current value of CSR[addr]
   RCSR_intf.master                       csr_rd_bus,
   // CSR NEXT port access
   CSR_NXT_intf.master                    csr_nxt_bus
);

   logic                                  xfer_out, xfer_in;
   logic                                  pipe_full;

   EXE_2_MEM                              exe_dout;

   logic                    [GPR_ASZ-1:0] Rd_addr;                         // Which register to write (destination register)
   logic                    [GPR_ASZ-1:0] Rs1_addr;                        // Which register to read for Rs1_data
   logic                    [GPR_ASZ-1:0] Rs2_addr;                        // Which register to read for Rs2_data
   logic                           [11:0] csr_addr;                        // which CSR[] to read from

   `ifdef ext_F
   logic                                  Fd_wr;                           // floating Point Destination Register write signal
   logic                    [FPR_ASZ-1:0] Fs1_addr;                        // Which register to read for Rs1_data
   logic                    [FPR_ASZ-1:0] Fs2_addr;                        // Which register to read for Rs2_data
   `endif
   logic                                  Rd_wr;                           // RV32i Destination Register write signal
   logic                                  Rs1_rd;
   logic                                  Rs2_rd;

   logic                        [RSZ-1:0] Rs1_data;                        // gpr[Rs1_addr]
   logic                        [RSZ-1:0] Rs2_data;                        // gpr[Rs2_addr]

   logic                        [RSZ-1:0] Rs1D;                            // data is either from Rs1_data or forwarding data
   logic                        [RSZ-1:0] Rs2D;                            // data is either from Rs2_data or forwarding data

   `ifdef ext_F
   logic                        [RSZ-1:0] Fs1_data;                        // fpr[Rs1_addr]
   logic                        [RSZ-1:0] Fs2_data;                        // fpr[Rs2_addr]

   logic                        [RSZ-1:0] Fs1D;                            // data is either from Fs1_data or forwarding data
   logic                        [RSZ-1:0] Fs2D;                            // data is either from Fs2_data or forwarding data
   `endif

   logic                        [RSZ-1:0] CSD;                             // data is either from csr_rd_data or forwarding data

   // These signal when a particular functional unit is completed
   logic       alu_fu_done;
   logic       br_fu_done;
   `ifdef ext_M
   logic       im_fu_done;
   logic       idr_fu_done;
   `endif
   `ifdef ext_F
   logic       spfp_fu_done;
   `endif
   logic       csr_fu_done;
   logic       ls_fu_done;
   logic       hint_done;     // no related F.U. for these instructions
   logic       sys_done;      // no related F.U. for these instructions
   logic       ill_done;      // no related F.U. for this instruction
   logic       fu_done;

   logic       [OP_SZ-1:0] op_type;
   logic       [PC_SZ-1:0] predicted_addr;

   IG_TYPE                 ig_type;
   logic                   ci;


   logic             [1:0] mode;
   logic       [PC_SZ-1:0] mepc;
   `ifdef ext_S
   logic       [PC_SZ-1:0] sepc;
   `endif
   `ifdef ext_U
   logic       [PC_SZ-1:0] uepc;
   `endif

   // --------------------------------- csr_exe_bus signal assignments
   // signals to csr.sv
   logic                   mret;
   `ifdef ext_S
   logic                   sret;
   `endif
   `ifdef ext_U
   logic                   uret;
   `endif

   assign csr_exe_bus.mret    = mret;
   `ifdef ext_S
   assign csr_exe_bus.sret    = sret;
   `endif
   `ifdef ext_U
   assign csr_exe_bus.uret    = uret;
   `endif

   // signals from csr.sv
   assign mode    = csr_exe_bus.mode;
   assign mepc    = csr_exe_bus.mepc;
   `ifdef ext_S
   assign sepc    = csr_exe_bus.sepc;
   `endif
   `ifdef ext_U
   assign uepc    = csr_exe_bus.uepc;
   `endif

   // --------------------------------- fu_done goes high whenever an instruction finishes execution.
   // Most instructions are executed in Functional Units and a few are not
   assign fu_done =  alu_fu_done  | br_fu_done |
   `ifdef ext_M
                     im_fu_done   | idr_fu_done |
   `endif
   `ifdef ext_F
                     spfp_fu_done |
   `endif
                     csr_fu_done  | ls_fu_done | hint_done | sys_done | ill_done;

   // --------------------------------- control logic for interface to Decode stage and Memory stage
   assign D2E_bus.rdy   = !reset_in & !cpu_halt & fu_done & (!pipe_full | xfer_out);

   assign xfer_in       = D2E_bus.valid & D2E_bus.rdy;                              // pop data from DEC_PIPE pipeline register..
   assign xfer_out      = E2M_bus.valid & E2M_bus.rdy;                              // pops data from EXE_PIPE registers to next stage

   // --------------------------------- use these addresses to get data from gpr[Rs1_addr], gpr[Rs2_addr]
   assign Rd_addr       = D2E_bus.data.Rd_addr;
   assign Rs1_addr      = D2E_bus.data.Rs1_addr;
   assign Rs2_addr      = D2E_bus.data.Rs2_addr;

   `ifdef ext_F
   assign Fd_wr         = D2E_bus.data.Fd_wr;                                       // see spfp_instr_cases.svh for use of this variable
   assign Fs1_rd        = D2E_bus.data.Fs1_rd;
   assign Fs2_rd        = D2E_bus.data.Fs2_rd;
   `endif
   assign Rd_wr         = D2E_bus.data.Rd_wr;
   assign Rs1_rd        = D2E_bus.data.Rs1_rd;
   assign Rs2_rd        = D2E_bus.data.Rs2_rd;

   assign ig_type       = D2E_bus.data.ig_type;
   assign ci            = D2E_bus.data.ci;

   assign Rs1_data      = gpr[Rs1_addr];
   assign Rs2_data      = gpr[Rs2_addr];

   `ifdef ext_F
   assign Fs1_data      = fpr[Rs1_addr];
   assign Fs2_data      = fpr[Rs2_addr];
   `endif
   //------------------------------- Debugging: disassemble instruction in this stage ------------------------------------
   `ifdef SIM_DEBUG
   string   i_str;
   string   pc_str;

   disasm exe_dis (ASSEMBLY,D2E_bus.data.ipd,i_str,pc_str);                         // disassemble each instruction
   `endif
   //---------------------------------------------------------------------------------------------------------------------

   //************************************ ALU Functional Unit ************************************
   // get the necessary information from the Decode data & GPR and pass to ALU functional unit
   AFU_intf afu_bus();

   assign afu_bus.Rs1_data   = Rs1D;
   assign afu_bus.Rs2_data   = Rs2D;
   assign afu_bus.pc         = D2E_bus.data.ipd.pc;
   assign afu_bus.imm        = D2E_bus.data.imm;
   assign afu_bus.sel_x      = D2E_bus.data.sel_x.alu_sel;         // ENUM type: see cpu_structs.svh ALU_SEL_TYPE
   assign afu_bus.sel_y      = D2E_bus.data.sel_y.alu_sel;
   assign afu_bus.op         = ALU_OP_TYPE'(op_type[ALU_OP_SZ-1:0]);

   assign alu_fu_done = D2E_bus.valid & (ig_type == ALU_INSTR); // This functional unit only takes 1 clock cycle
   alu_fu AFU
   (
      .afu_bus(afu_bus)
   );

   //************************************ Branch Functional Unit *********************************
   // get the necessary information from the Decode data & GPR and pass to Branch functional unit
   // pull out the signals
   BFU_intf brfu_bus();

   assign brfu_bus.Rs1_data    = Rs1D;
   assign brfu_bus.Rs2_data    = Rs2D;
   assign brfu_bus.pc          = D2E_bus.data.ipd.pc;
   assign brfu_bus.imm         = D2E_bus.data.imm;
   assign brfu_bus.funct3      = D2E_bus.data.funct3;
   assign brfu_bus.ci          = D2E_bus.data.ci;
   assign brfu_bus.sel_x       = D2E_bus.data.sel_x.br_sel;                // ENUM type: see cpu_structs.svh BR_SEL_TYPE
   assign brfu_bus.sel_y       = D2E_bus.data.sel_y.br_sel;
   assign brfu_bus.op          = BR_OP_TYPE'(op_type[BR_OP_SZ-1:0]);
   assign brfu_bus.mepc        = mepc;
   `ifdef ext_S
   assign brfu_bus.sepc        = sepc;
   `endif
   `ifdef ext_U
   assign brfu_bus.uepc        = uepc;
   `endif

   assign br_fu_done = D2E_bus.valid & (ig_type == BR_INSTR);  // This functional unit only takes 1 clock cycle
   br_fu BFU
   (
      .brfu_bus(brfu_bus)
   );

   `ifdef ext_M
   //************************************ Integer Multiply Functional Unit ***********************
   // get the necessary information from the Decode data & GPR and pass to Integer Multiply functional unit
   // pull out the signals

   IMFU_intf   imfu_bus();

   assign imfu_bus.Rs1_data   = Rs1D;
   assign imfu_bus.Rs2_data   = Rs2D;
   assign imfu_bus.op         = IM_OP_TYPE'(op_type[IM_OP_SZ-1:0]);

   assign im_fu_done = D2E_bus.valid & (ig_type == IM_INSTR);  // This functional unit (currently using vedic multiplier) only takes 1 clock cycle. Note: try mult_N_by_N.sv to improve clock speed
   im_fu IMFU
   (
      .imfu_bus(imfu_bus)
   );

   //************************************ Integer Divide/Remainder Functional Unit ***************
   IDRFU_intf idrfu_bus();

   assign idrfu_bus.Rs1_data  = Rs1D;
   assign idrfu_bus.Rs2_data  = Rs2D;
   assign idrfu_bus.op        = IDR_OP_TYPE'(op_type[IDR_OP_SZ-1:0]);
   assign idrfu_bus.start     = D2E_bus.valid & (ig_type == IDR_INSTR);

   assign idr_fu_done         = idrfu_bus.done;

   // NOTE: This functional unit may take many clock cycles to execute
   idr_fu #(RSZ) IDRFU
   (
      .clk_in(clk_in),
      .reset_in(reset_in),
      .idrfu_bus(idrfu_bus)
   );
   `endif

  //************************************ CSR Functional Unit *********************************
  CSRFU_intf            csrfu_bus();
   logic                   csr_avail;

   logic                   csr_wr;
   logic                   csr_rd;
   logic         [RSZ-1:0] csr_Rd_data;      // value to write into R[Rd]
   logic         [RSZ-1:0] csr_wr_data;      // value to write into CSR[csr_addr} in WB stage
   logic         [RSZ-1:0] nxt_csr_rd_data;  // data to use as forwarding value for CSR[csr_addr]
   logic                   ill_csr_access;   // 1 = illegal csr access
   logic            [11:0] ill_csr_addr;
   
   assign csr_addr                  = D2E_bus.data.imm[11:0];
   // ----------------------------------- csr_rd_bus interface
   // Read CSR access port signals to/from CSR module (csr.sv)
   assign csr_rd_bus.csr_rd_addr    = csr_addr;                            // Output:  to csr.sv
   assign csr_avail                 = csr_rd_bus.csr_rd_avail;             // Input:   from csr.sv
   // see forwarding logic that uses  csr_rd_bus.csr_rd_data;              // Input:   from csr.sv


   // ----------------------------------- csrfu_bus interface
   assign csrfu_bus.csr_valid       = (ig_type == CSR_INSTR) & D2E_bus.valid; // permission to write to the CSR
   assign csrfu_bus.csr_addr        = csr_addr;                               // csr_addr = CSR Address - see decode_core.sv imm field
   assign csrfu_bus.csr_avail       = csr_avail;                              // csr_addr = CSR Address - see decode_core.sv imm field
   assign csrfu_bus.csr_rd_data     = CSD;                                    // CSR read data (from csr_rd_bus.csr_rd_data or forwarding data)
   assign csrfu_bus.Rd_addr         = Rd_addr;                                // Rd address value
   assign csrfu_bus.Rs1_addr        = Rs1_addr;                               // Rs1 address value
   assign csrfu_bus.Rs1_data        = Rs1D;                                   // contents of R[Rs1]
   assign csrfu_bus.funct3          = D2E_bus.data.funct3;
   assign csrfu_bus.mode            = mode;

   assign csr_fu_done = D2E_bus.valid & (ig_type == CSR_INSTR);               // This functional unit only takes 1 clock cycle
   // Control & Status Registers
   csr_fu CSRFU
   (
      .csrfu_bus(csrfu_bus),
      .csr_nxt_bus(csr_nxt_bus)
   );

   assign csr_wr                    = csrfu_bus.csr_wr;
   assign csr_rd                    = csrfu_bus.csr_rd;
   assign csr_Rd_data               = csrfu_bus.Rd_data;
   assign csr_wr_data               = csrfu_bus.csr_wr_data;
   assign nxt_csr_rd_data           = csrfu_bus.nxt_csr_rd_data;              // value to use in CSR forwarding data
   assign ill_csr_access            = csrfu_bus.ill_csr_access;
   assign ill_csr_addr              = csrfu_bus.ill_csr_addr;

   //************************************ System Instruction & Illegal Instructions **************
   // There are no Functional Units related to these instructions so they complete in the current clock cycle
   assign hint_done = D2E_bus.valid & (ig_type == HINT_INSTR); // These instruction types only take 1 clock cycle - unless logic changed
   assign sys_done  = D2E_bus.valid & (ig_type == SYS_INSTR);  // These instruction types only take 1 clock cycle
   assign ill_done  = D2E_bus.valid & (ig_type == ILL_INSTR);  // These instruction types only takes 1 clock cycle


   `ifdef ext_F
   //********************* Single-precision Floating Point Functional Unit //*********************
   // get the necessary information from the Decode data & GPR and pass to SFPU functional unit
   SPFPFU_intf spfpfu_bus();

   assign spfpfu_bus.Fs1_data  = Fs1D;
   assign spfpfu_bus.Fs2_data  = Fs2D;
   assign spfpfu_bus.imm       = D2E_bus.data.imm;
   assign spfpfu_bus.sel_x     = D2E_bus.data.sel_x.spfp_sel;                 // ENUM type: see cpu_structs.svh SPFP_SEL_TYPE
   assign spfpfu_bus.sel_y     = D2E_bus.data.sel_y.spfp_sel;
   assign spfpfu_bus.op        = SPFP_OP_TYPE'(op_type[SPFP_OP_SZ-1:0]);      // cast the op type of data (bit [N:0]) to SPFP_OP_TYPE. see cpu_struts.svh

   assign spfp_fu_start = D2E_bus.valid & (ig_type == SPFP_INSTR);            // This functional unit may takes several clock cycles
   spfp_fu SPFPFU
   (
      .spfpfu_bus(spfpfu_bus) // WARNING:  There's no code yet in this module to send spfpfu data onward (via exe_dout like other instructions do) to next stage...needs to be added
   );
   `endif

   //************************************ Load/Store Functional Unit *****************************
   // Calculate the Load/Store address

   LSFU_intf lsfu_bus();

   assign lsfu_bus.Rs1_data    = Rs1D;
   assign lsfu_bus.Rs2_data    = Rs2D;
   assign lsfu_bus.imm         = D2E_bus.data.imm;
   assign lsfu_bus.funct3      = D2E_bus.data.funct3;

   assign ls_fu_done = D2E_bus.valid & ((ig_type == LD_INSTR) | (ig_type == ST_INSTR));   // This functional unit only takes 1 clock cycle

   ls_fu LSFU
   (
      .lsfu_bus(lsfu_bus)
   );

   //************************************ Forwarding Logic ***************************************
   always_comb
   begin
      // Register Write Forwarding - data that gets written into R[n]
      // Note: Forwarding may takes place when:
      //       1. This instruction needs to read (Rs1_rd) the contents of R[Rs1_addr]
      //       2. The forwarfed instruction is valid (i.e. fwd_???_gpr.valid)
      //       3. The forwarded instruction is writing to a destination register Rd (i.e. fwd_mem_gpr.Rd_wr)
      //       4. This instruciton's Rs1 address is the same as the Rd address being forwarded
      //       5. The Rs1/Rd address is not for R0 (constant 0 value)
      // This applies for Rs1, Rs2 registers
      // forwarding priority uses the most recent match - i.e. MEM stage before WB stage
      if (Rs1_rd & fwd_mem_gpr.valid & fwd_mem_gpr.Rd_wr & (Rs1_addr == fwd_mem_gpr.Rd_addr) & (Rs1_addr != 0))
         Rs1D = fwd_mem_gpr.Rd_data;
      else if (Rs1_rd & fwd_wb_gpr.valid & fwd_wb_gpr.Rd_wr & (Rs1_addr == fwd_wb_gpr.Rd_addr) & (Rs1_addr != 0))
         Rs1D = fwd_wb_gpr.Rd_data;
      else
         Rs1D = Rs1_data; // pull it from GPR[Rs1_addr]

      if (Rs2_rd & fwd_mem_gpr.valid & fwd_mem_gpr.Rd_wr & (Rs2_addr == fwd_mem_gpr.Rd_addr) & (Rs2_addr != 0))
         Rs2D = fwd_mem_gpr.Rd_data;
      else if (Rs2_rd & fwd_wb_gpr.valid & fwd_wb_gpr.Rd_wr & (Rs2_addr == fwd_wb_gpr.Rd_addr)  & (Rs2_addr != 0))
         Rs2D = fwd_wb_gpr.Rd_data;
      else
         Rs2D = Rs2_data; // pull it from GPR[Rs2_addr]

      `ifdef ext_F
      // For Single Precision Floating Point, Rs1_addr, Rs2_addr are shared, but separate forwarding info (fwd_mem_fpr, fwd_wb_fpr and Fs1D, Fs2D) are used/created
      if (Fs1_rd & fwd_mem_fpr.valid & fwd_mem_fpr.Fd_wr & (Rs1_addr == fwd_mem_fpr.Fd_addr) & (Rs1_addr != 0))
         Fs1D = fwd_mem_fpr.Fd_data;
      else if (Fs1_rd & fwd_wb_fpr.valid & fwd_wb_fpr.Fd_wr & (Rs1_addr == fwd_wb_fpr.Fd_addr) & (Rs1_addr != 0))
         Fs1D = fwd_wb_fpr.Fd_data;
      else
         Fs1D = Fs1_data; // pull it from FPR[Rs1_addr]

      if (Fs2_rd & fwd_mem_fpr.valid & fwd_mem_fpr.Fd_wr & (Rs2_addr == fwd_mem_fpr.Fd_addr) & (Rs2_addr != 0))
         Fs2D = fwd_mem_fpr.Fd_data;
      else if (Fs2_rd & fwd_wb_fpr.valid & fwd_wb_fpr.Fd_wr & (Rs2_addr == fwd_wb_fpr.Fd_addr)  & (Rs2_addr != 0))
         Fs2D = fwd_wb_fpr.Fd_data;
      else
         Fs2D = Fs2_data; // pull it from FPR[Rs2_addr]
      `endif

      // CSR forwarding
      if (csr_rd & fwd_mem_csr.valid & fwd_mem_csr.csr_wr & (csr_addr == fwd_mem_csr.csr_addr))
         CSD = fwd_mem_csr.csr_data;
      else if (csr_rd & fwd_wb_csr.valid & fwd_wb_csr.csr_wr & (csr_addr == fwd_wb_csr.csr_addr))
         CSD = fwd_wb_csr.csr_data;
      else
         CSD = csr_rd_bus.csr_rd_data; // value calculated in CSRFU
   end

   `ifdef ext_N
   logic    trigger_wfi;
   `endif

   // ****** Decide which Functional Unit output data will get used and passed to next stage *****
   // record of signals for WB stage verification tests BEFORE changes are made (i.e. changes to Registers, Memory, CSRs, etc..)
   always_comb
   begin
      rld_pc_flag       = FALSE;
      rld_pc_addr       = '0;

      // signals used in MEM stage
      exe_dout          = '0;                                                       // Default values for every signal are 0 - see struct EXE_2_MEM in cpu_structs.svh

      op_type           = '0;
      predicted_addr    = '0;
      mret              = FALSE;
      `ifdef ext_S
      sret              = FALSE;
      `endif
      `ifdef ext_U
      uret              = FALSE;
      `endif

      `ifdef ext_N
         trigger_wfi    = FALSE;
      `endif

      if (D2E_bus.valid)                                                            // should this instruction be processed by this stage? Default exe_dout.? values may be overriden inside this if()
      begin
         op_type                    = D2E_bus.data.op;
         predicted_addr             = D2E_bus.data.predicted_addr;

         // trap_pc, interrupt_flag, interrupt_cause need to come from CSR in this stage so they can be passed to next stages as they relate to current instruction
         exe_dout.trap_pc           = csr_exe_bus.trap_pc;                          // trap_pc, interrupt_flag, interrupt_cause not used in this stage,but needed in WB stage
         `ifdef ext_N         
         exe_dout.interrupt_flag    = csr_exe_bus.interrupt_flag;
         exe_dout.interrupt_cause   = csr_exe_bus.interrupt_cause;
         `endif

         exe_dout.ipd               = D2E_bus.data.ipd;                             // pass on to next stage
         exe_dout.ci                = ci;                                           // 1 = compressed 16 bit instruction, 0 = 32 bit instruction
         exe_dout.ig_type           = ig_type;

         exe_dout.op_type           = op_type;
         exe_dout.mode              = mode;                                         // pass mode value associated with this instruction
         
         // NOTE: illegal instructions (ILL_INSTR) will cause an exception in WB stage
         case(ig_type)                                                              // select which functional unit output data is the appropriate one and save it
            ALU_INSTR:
            begin
               exe_dout.Rd_wr    = Rd_wr & (Rd_addr != 0);                          // Writeback stage needs to know whether to write to destination register Rd
               exe_dout.Rd_addr  = Rd_addr;
               exe_dout.Rd_data  = afu_bus.Rd_data;                                 // Data may be written into Rd register
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
               // -------------- URET,SRET,MRET --------------
               case(op_type)
                  `ifdef ext_U
                  B_URET:                                                           // URET
                  begin // "OK to use in all modes though maybe technically nonsensical in S or M mode"
                     if (predicted_addr != uepc)
                     begin
                        exe_dout.mispre   = TRUE;

                        rld_pc_flag       = TRUE;
                        rld_pc_addr       = uepc;                                   // reload PC and flush pipeline
                     end
                     uret  = TRUE;                                                  // notify csr.sv
                  end
                  `endif // ext_U

                  `ifdef ext_S
                  B_SRET:                                                           // SRET
                  begin
                     if (mode >= S_MODE)                                            // if not, an exception will be taken in WB stage
                     begin
                        if (predicted_addr != sepc)
                        begin
                           exe_dout.mispre   = TRUE;

                           rld_pc_flag       = TRUE;
                           rld_pc_addr       = sepc;                                // reload PC and flush pipeline
                        end
                        sret  = TRUE;                                               // notify csr.sv
                     end
                  end
                  `endif // ext_S

                  B_MRET:                                                           // MRET
                  begin
                     if (mode == M_MODE)                                            // if not, an exception will be taken in WB stage
                     begin
                        if (predicted_addr != mepc)
                        begin
                           exe_dout.mispre   = TRUE;

                           rld_pc_flag       = TRUE;                                // flush pipeline and reload new fetch address
                           rld_pc_addr       = mepc;                                // reload PC and flush pipeline
                        end
                        mret  = TRUE;                                               // notify csr.sv
                     end
                  end

                  // -------------- Bxx --------------
                  `ifdef ext_C
                  B_C,
                  `endif
                  B_ADD:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (brfu_bus.mis)
                     begin
                        exe_dout.instr_err   = brfu_bus.mis;                        // Misaligned Addresses Trap
                        exe_dout.br_pc       = brfu_bus.br_pc;                      // Exception Trap info for use in MEM stage
                     end
                     else
                     `endif
                     if (predicted_addr != brfu_bus.br_pc)
                     begin
                        exe_dout.mispre      = TRUE;

                        rld_pc_flag          = TRUE;
                        rld_pc_addr          = brfu_bus.br_pc;
                     end
                  end

                  // -------------- JAL,JALR --------------
                  B_JAL, B_JALR:
                  begin
                     // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p. 95
                     `ifndef ext_C
                     if (brfu_bus.mis)
                     begin
                        exe_dout.instr_err   = brfu_bus.mis;
                        exe_dout.br_pc       = brfu_bus.br_pc;
                     end
                     else
                     `endif
                     if (predicted_addr != brfu_bus.br_pc)
                     begin
                        exe_dout.mispre      = TRUE;

                        rld_pc_flag          = TRUE;
                        rld_pc_addr          = brfu_bus.br_pc;
                     end
                     else
                     begin
                        exe_dout.Rd_wr       = Rd_wr & (Rd_addr != 0);              // Writeback stage needs to know whether to write to destination register Rd
                        exe_dout.Rd_addr     = Rd_addr;
                        exe_dout.Rd_data     = brfu_bus.no_br_pc;                   // address of instruction immediately after this branch instruction
                     end
                  end
               endcase
            end

            `ifdef ext_M
            IM_INSTR:
            begin
               exe_dout.Rd_wr       = Rd_wr & (Rd_addr != 0);                       // Writeback stage needs to know whether to write to destination register Rd
               exe_dout.Rd_addr     = Rd_addr;
               exe_dout.Rd_data     = imfu_bus.Rd_data;
            end

            IDR_INSTR:
            begin
               exe_dout.Rd_wr       = Rd_wr & (Rd_addr != 0);                       // Writeback stage needs to know whether to write to destination register Rd
               exe_dout.Rd_addr     = Rd_addr;

               if (op_type inside {REM, REMU})
                  exe_dout.Rd_data  = idrfu_bus.remainder;
               else
                  exe_dout.Rd_data  = idrfu_bus.quotient;
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
            end
            `endif

//            SYS_INSTR:
//            begin
//               unique case(op_type)
//                  `ifdef ext_ZiF
//                  FENCEI:
//                  begin
//// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
//                     // Flush pipeline and fetch buffer
//                  end
//
//                  FENCE:
//                  begin
//// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
//                     // flush pipeline
//                  end
//                  `endif
//
//                  ECALL: // see MEM stage
//                  begin
//                  end
//
//                  EBREAK:
//                  begin
//                  end
//
//                  WFI:                                                              // NOTE: "...a legal implementation is to simply implement WFI as a NOP"
//                  begin
// !!!!!!!!!!!!!! NEEDS TO BE COMPLETED !!!!!!!!!!!!!!
//                     if (mstatus.twi || (D2E_bus.data.funct3 > mode))               // see riscv_privileged-20190608.pdf  p.41
//                     begin
//                        ...
//                     end
//                     else
//                        trigger_wfi       = TRUE;
//                  end
//               endcase
//            end

            CSR_INSTR:
            begin
               if (ill_csr_access)
               begin
                  exe_dout.instr_err   = TRUE;
                  exe_dout.Rd_data     = ill_csr_addr;                              // save in Rd_data for use in mem.sv
               end
               else
               begin
                  exe_dout.Rd_wr    = Rd_wr & (Rd_addr != 0);                       // Writeback stage needs to know whether to write to destination register Rd
                  exe_dout.Rd_addr  = Rd_addr;
                  exe_dout.Rd_data  = csr_Rd_data;                                  // value used to update Rd in WB stage
                  exe_dout.csr_wr   = csr_wr;
                  exe_dout.csr_addr = csr_addr;
                  exe_dout.csr_wr_data = csr_wr_data;                               // Data to be written at WB stage
                  exe_dout.csr_fwd_data = nxt_csr_rd_data;                          // This is the data that should be used in forwarding as it may be different than csr_wr_data
               end
            end

            LD_INSTR:
            begin
               // Load exceptions can only be done once Load finishes in MEM stage
               // Note: exe_dout.Rd_data cannot be determined here - it is determined in mem.sv where it gets loaded from memory and passed on to Write Back Stage.
               exe_dout.Rd_wr       = Rd_wr & (Rd_addr != 0);                       // Writeback stage needs to know whether to write to destination register Rd
               exe_dout.Rd_addr     = Rd_addr;
               exe_dout.is_ld       = TRUE;
               exe_dout.ls_addr     = lsfu_bus.ls_addr;
               exe_dout.size        = lsfu_bus.size;                                // 0 byte default, 1 byte, 2 byte, or 4 byte
               exe_dout.instr_err   = lsfu_bus.mis;
            end

            ST_INSTR:
            begin
               // Note: write to Rd never occurs for a Store instruction
               // Store exceptions can only be done once Store finishes in MEM stage
               exe_dout.is_st       = TRUE;
               exe_dout.ls_addr     = lsfu_bus.ls_addr;
               exe_dout.st_data     = lsfu_bus.st_data;
               exe_dout.size        = lsfu_bus.size;                                // 0 byte default, 1 byte, 2 byte, or 4 byte
               exe_dout.zero_ext    = lsfu_bus.zero_ext;                            // 1 = LBU or LHU instruction - zero extend
               exe_dout.inv_flag    = (lsfu_bus.ls_addr >= L1_IC_Lo) && (lsfu_bus.ls_addr <= L1_IC_Hi);  // write will also occur in the L1 I$ address space
               exe_dout.instr_err   = lsfu_bus.mis;
            end

            `ifdef ext_F

// need equivalent FP logic like LD_INSTR and ST_INSTR for each floating point instruction

            `endif
         endcase // only process listed case items in EXE stage
      end
   end

   // Set of Flip Flops (for pipelining) with control logic ('full' signal) sitting between Execute stage and the Memory stage
   pipe #( .T(type(EXE_2_MEM)) ) EXE_PIPE
   (
      .clk_in(clk_in),  .reset_in(reset_in | pipe_flush),
      .write_in(xfer_in), .data_in(exe_dout), .full_out(pipe_full),
      .read_in(xfer_out), .data_out(E2M_bus.data)
   );
   assign E2M_bus.valid = pipe_full;
endmodule
