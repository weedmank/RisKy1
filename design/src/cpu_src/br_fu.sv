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
// File          :  br_fu.svh
// Description   :  Determines if the branch is Taken/Not Taken and what the next PC will be.
//               :  Also determines if instruction is mis-aligned
//               :  This unit decodes at the same time other functional units decode a specific
//               :  instruction. However the EXE stage will only pick the FU output results depending
//               :  on the type of instruction
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module br_fu
(
   BFU_intf.slave       brfu_bus
);

   logic      [RSZ-1:0] mux_x;
   logic      [RSZ-1:0] mux_y;

   // separated input data
   logic      [RSZ-1:0] Rs1_data;
   logic      [RSZ-1:0] Rs2_data;
   logic    [PC_SZ-1:0] pc;
   logic      [RSZ-1:0] imm;
   logic          [2:0] funct3;
   logic                ci;            // 1 = compressed 16-bit instructions
   BR_SEL_TYPE          sel_x;
   BR_SEL_TYPE          sel_y;
   BR_OP_TYPE           op;
   logic    [PC_SZ-1:0] mepc;
   `ifdef ext_S
   logic    [PC_SZ-1:0] sepc;
   `endif
   `ifdef ext_U
   logic    [PC_SZ-1:0] uepc;
   `endif

   logic    [PC_SZ-1:0] no_br_pc;       // PC + 4 (32 bit instruction) or PC + 2 (compressed 16 bit instruction)

   // pull out the signals
   assign Rs1_data   = brfu_bus.Rs1_data;
   assign Rs2_data   = brfu_bus.Rs2_data;
   assign pc         = brfu_bus.pc;
   assign imm        = brfu_bus.imm;
   assign funct3     = brfu_bus.funct3;
   assign ci         = brfu_bus.ci;
   assign sel_x      = brfu_bus.sel_x;
   assign sel_y      = brfu_bus.sel_y;
   assign op         = brfu_bus.op;
   assign mepc       = brfu_bus.mepc;
   `ifdef ext_S
   assign sepc       = brfu_bus.sepc;
   `endif
   `ifdef ext_U
   assign uepc       = brfu_bus.uepc;
   `endif

   always_comb
   begin
      mux_x = 0;
      case(sel_x)
         BS_RS1:  mux_x = Rs1_data;
         BS_IMM:  mux_x = imm;
         BS_PC:   mux_x = pc;
      endcase
   end

   always_comb
   begin
      mux_y = 0;
      case(sel_y)
         BS_RS1:  mux_y = Rs1_data;
         BS_IMM:  mux_y = imm;
         BS_PC:   mux_y = pc;
      endcase
   end

   logic             branch_taken;
   logic [PC_SZ-1:0] addxy;

   assign addxy = mux_x + mux_y;

   assign no_br_pc = ci ? (pc + 3'd2) : (pc + 3'd4);   // Address of the instruction immediately after this branch instruction

   // Branch ALU Functions
   always_comb
   begin
      branch_taken = FALSE;
      case(op)
         B_ADD:
            case(funct3)      // see decode.sv
               0: branch_taken = (Rs1_data == Rs2_data);                   // beq
               1: branch_taken = (Rs1_data != Rs2_data);                   // bne
               4: branch_taken = ($signed(Rs1_data) <  $signed(Rs2_data)); // blt
               5: branch_taken = ($signed(Rs1_data) >= $signed(Rs2_data)); // bge
               6: branch_taken = (Rs1_data < Rs2_data);                    // bltu
               7: branch_taken = (Rs1_data >= Rs2_data);                   // bgeu
            endcase
            
         `ifdef ext_C
         B_C:
            case(funct3)      // see decode_core.sv
               6: branch_taken = (Rs1_data == 0);                          // c.beqz
               7: branch_taken = (Rs1_data != 0);                          // c.bnez
            endcase
         `endif
         
         B_JAL,B_JALR:           branch_taken = TRUE;                      // jal          -> PC = PC + sext(imm),                        R[rd] = no_br_pc;
                                                                           // jalr         -> PC = ( R[rs1] + sext(imm) ) & 0xfffffffe,   R[rd] = no_br_pc;
         B_MRET:  branch_taken = TRUE;                                     // mret
         `ifdef ext_S
         B_SRET:  branch_taken = TRUE;                                     // sret
         `endif
         `ifdef ext_U
         B_URET:  branch_taken = TRUE;                                     // uret
         `endif
      endcase
   end

   logic [PC_SZ-1:0] br_pc;

   always_comb
   begin
      br_pc = 0;
      case(op)
         B_ADD:
         begin
            case(funct3)      // synopsys parallel_case     see decode.v
               0: br_pc = branch_taken ? addxy : no_br_pc;                 // beq   -> PC = ( R[rs1] ==  R[rs2] ) ? addxy : no_br_pc
               1: br_pc = branch_taken ? addxy : no_br_pc;                 // bne   -> PC = ( R[rs1] !=  R[rs2] ) ? addxy : no_br_pc
               4: br_pc = branch_taken ? addxy : no_br_pc;                 // blt   -> PC = ( R[rs1] <s  R[rs2] ) ? addxy : no_br_pc
               5: br_pc = branch_taken ? addxy : no_br_pc;                 // bge   -> PC = ( R[rs1] >=s R[rs2] ) ? addxy : no_br_pc
               6: br_pc = branch_taken ? addxy : no_br_pc;                 // bltu  -> PC = ( R[rs1] <   R[rs2] ) ? addxy : no_br_pc
               7: br_pc = branch_taken ? addxy : no_br_pc;                 // bgeu  -> PC = ( R[rs1] >=  R[rs2] ) ? addxy : no_br_pc
            endcase
         end

         `ifdef ext_C
         B_C:
            case(funct3)      // see decode_core.sv
               6: br_pc = branch_taken ? addxy : no_br_pc;                 // c.beqz -> PC + sext(imm)
               7: br_pc = branch_taken ? addxy : no_br_pc;                 // c.bnez -> PC + sext(imm)
            endcase
         `endif
         
         B_JAL:   br_pc = addxy;                                           // jal   -> PC = PC + sext(imm)                         R[rd] = no_br_pc;
         B_JALR:  br_pc = {addxy[PC_SZ-1:1],1'b0};                         // jalr  -> PC = ( R[rs1] + sext(imm) ) & 0xfffffffe,   R[rd] = no_br_pc;
         B_MRET:  br_pc = mepc;
         `ifdef ext_S
         B_SRET:  br_pc = sepc;
         `endif
         `ifdef ext_U
         B_URET:  br_pc = uepc;
         `endif
      endcase
   end

   assign brfu_bus.no_br_pc   = no_br_pc;  // address of instruction following a Bxx, JAL, or JALR - see p 15,16
   assign brfu_bus.br_pc      = br_pc;

   `ifndef ext_C                        // With the addition of the C extension, no instructions can raise instruction-address-misaligned exceptions. p95
   assign brfu_bus.mis        = (br_pc[1:0] != 2'b00);
   `endif

endmodule