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
// File          :  alu_fu.svh
// Description   :  Calculates the Right Hand side of an equation (i.e R2 = R3 + R4)
//               :  This unit decodes at the same time other functional units decode a specific
//               :  instruction. However the EXE stage will only pick the FU output results depending
//               :  on the type of instruction
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module alu_fu
(
   AFU_intf.slave       afu_bus
);

   logic      [RSZ-1:0] mux_x;
   logic      [RSZ-1:0] mux_y;

   // separated input data
   logic      [RSZ-1:0] Rs1_data;
   logic      [RSZ-1:0] Rs2_data;
   logic      [RSZ-1:0] imm;
   ALU_SEL_TYPE         sel_x, sel_y;
   ALU_OP_TYPE          op;
   logic    [PC_SZ-1:0] pc;

   // pull out the signals
   assign Rs1_data   = afu_bus.Rs1_data;
   assign Rs2_data   = afu_bus.Rs2_data;
   assign pc         = afu_bus.pc;
   assign imm        = afu_bus.imm;
   assign sel_x      = afu_bus.sel_x;
   assign sel_y      = afu_bus.sel_y;
   assign op         = afu_bus.op;

   always_comb
   begin
      unique case(sel_x)
         AM_RS1:  mux_x = Rs1_data;
         AM_RS2:  mux_x = Rs2_data;
         AM_IMM:  mux_x = imm;
         AM_PC:   mux_x = pc;
      endcase
   end

   always_comb
   begin
      unique case(sel_y)
         AM_RS1:  mux_y = Rs1_data;
         AM_RS2:  mux_y = Rs2_data;
         AM_IMM:  mux_y = imm;
         AM_PC:   mux_y = pc;
      endcase
   end

   // ALU Functions
   always_comb
   begin
      unique case(op)
         A_AND:   afu_bus.Rd_data = mux_x & mux_y;
         A_OR:    afu_bus.Rd_data = mux_x | mux_y;             // see lui
         A_XOR:   afu_bus.Rd_data = mux_x ^ mux_y;
         A_ADD:   afu_bus.Rd_data = mux_x + mux_y;             // see auipc
         A_SUB:   afu_bus.Rd_data = mux_x - mux_y;
         A_SLL:   afu_bus.Rd_data = mux_x << mux_y[4:0];
         A_SRL:   afu_bus.Rd_data = mux_x >> mux_y[4:0];
         A_SRA:   afu_bus.Rd_data = mux_x >>> mux_y[4:0];
         A_SLT:   afu_bus.Rd_data = ($signed(mux_x) < $signed(mux_y)) ? 'd1 : 'd0; // signed compare
         A_SLTU:  afu_bus.Rd_data = (mux_x < mux_y) ? 'd1 : 'd0; // unsigned compare
      endcase
   end



   //                  Rs1_data Rs2_data  imm     pc                  Rs1_data Rs2_data  imm     pc
   //                    |       |       |       |                    |       |       |       |
   //                ----+-------+-------+-------+----            ----+-------+-------+-------+----
   //                \                               /            \                               /
   //       sel_x---->\                             /              \                             /<---- sel_y
   //                  --------------+--------------                --------------+--------------     (AM_RS1,AM_RS2,AM_IMM,AM_PC)
   //                                |                                            |
   //                                |   mux_x                            mux_y   |
   //                                +------------+                    +----------+
   //                                             |                    |
   //                                             |                    |
   //                                         ----+---              ---+----
   //                                          \      \            /      /
   //                                           \      +----------+      /
   //                                            \         ALU          /
   //                                             --+---+---+---+---+---
   //                                               | & |OR | ^ | + | -
   //                                               |   |   |   |   |
   //                                               |   |   |   |   |
   //                                            ---+---+---+---+---+---
   //                                            \                     /
   //                                             \       MUX_A       /<----- op
   //                                              \                 /    (A_AND,A_OR,A_XOR,A_ADD,A_SUB...)
   //                                               --------+--------
   //                                                       |
   //                                                       v
   //                                                  alu_out

endmodule