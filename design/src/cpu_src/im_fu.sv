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
// File          :  im_fu.sv
// Description   :  Calculates an integer multiply
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

module im_fu
(
   IMFU_intf.slave      imfu_bus
);
   // separated input data
   logic      [RSZ-1:0] Rs1_data;
   logic      [RSZ-1:0] Rs2_data;
   IM_OP_TYPE           op;

   logic      [RSZ-1:0] m1Data;
   logic      [RSZ-1:0] m2Data;
   logic    [2*RSZ-1:0] mulx;

   // pull out the signals
   assign Rs1_data   = imfu_bus.Rs1_data;
   assign Rs2_data   = imfu_bus.Rs2_data;
   assign op         = imfu_bus.op;

   // Multiplier
   //    op      Rs1_data x Rs2_data
   //      0      unsigned x unsigned - return lower 32 bits  MUL
   //      1        signed x signed   - return upper 32 bits  MULH
   //      2        signed x unsigned - return upper 32 bits  MULHSU
   //      3      unsigned x unsigned - return upper 32 bits  MULHU
   //
   //
   //                            | m1Data                                  | m2Data
   //                        +---+-----------------------------------------+---+
   //                        |                                                 |
   //                        |              32x32 Unsigned Multiply            |
   //                        |                                                 |
   //                        +-------------------------+-----------------------+
   //                                                  | mulx[63:0]
   //                                                  |
   //                                                  |


   always_comb
   begin
      case(op)
         MUL:     m1Data = Rs1_data;
         MULH:    m1Data = Rs1_data[31] ? -Rs1_data : Rs1_data;
         MULHSU:  m1Data = Rs1_data[31] ? -Rs1_data : Rs1_data;
         MULHU:   m1Data = Rs1_data;
      endcase
   end

   always_comb
   begin
      case(op)
         MUL:     m2Data = Rs2_data;
         MULH:    m2Data = Rs2_data[31] ? -Rs2_data : Rs2_data;
         MULHSU:  m2Data = Rs2_data;
         MULHU:   m2Data = Rs2_data;
      endcase
   end

   vedic_mult32x32 ved1 (.a(m1Data),.b(m2Data),.c(mulx));

   always_comb
   begin
      case(op)
         MUL:     imfu_bus.Rd_data = mulx[31:0];
         MULH:    imfu_bus.Rd_data = (Rs1_data[31] ^ Rs2_data[31]) ? -mulx[63:32] : mulx[63:32];
         MULHSU:  imfu_bus.Rd_data = Rs1_data[31] ? -mulx[63:32] : mulx[63:32];
         MULHU:   imfu_bus.Rd_data = mulx[63:32];
      endcase
   end

endmodule