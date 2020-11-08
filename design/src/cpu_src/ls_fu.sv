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
// File          :  ls_fu.sv
// Description   :  Load/Store Functional Unit
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

module ls_fu
(
   LSFU_intf.slave      lsfu_bus
);

   // Load/Store logic
   assign lsfu_bus.ls_addr    = lsfu_bus.Rs1_data + lsfu_bus.imm;             // op_x = 0 (Rs1Data), op_y = 2 (imm)
   assign lsfu_bus.st_data    = lsfu_bus.Rs2_data;                            // Store Data

   // Loads
   // C.LW     - funct3 = 3'b010 = 2
   // C.LWSP   - funct3 = 3'b010 = 2
   // C.FLW    - funct3 = 3'b011 = 3
   // C.FLWSP  - funct3 = 3'b011 = 3

   // LB       - funct3 = 3'b000 = 0
   // LH       - funct3 = 3'b001 = 1
   // LW       - funct3 = 3'b010 = 2
   // LBU      - funct3 = 3'b010 = 4
   // LHU      - funct3 = 3'b010 = 5

   // Stores
   // C.SW     - funct3 = 3'b110 = 6
   // C.SWSP   - funct3 = 3'b110 = 6
   // C.FSW    - funct3 = 3'b111 = 7
   // C.FSWSP  - funct3 = 3'b111 = 7

   // SB       - funct3 = 3'b000 = 0
   // SH       - funct3 = 3'b001 = 1
   // SW       - funct3 = 3'b010 = 2

   always_comb
   begin
      lsfu_bus.size  = 1'd1;                                                  // 1 byte alignment for LB, LBU, SB (funct3 = 4,4,0)
      lsfu_bus.mis   = FALSE;
      case(lsfu_bus.funct3)
         1,5:
         begin
            lsfu_bus.size  = 2'd2;
            lsfu_bus.mis   = lsfu_bus.ls_addr[0];                             // 2 byte alignment required
         end
         2,3,6,7:
         begin
            lsfu_bus.size  = 3'd4;
            lsfu_bus.mis   = lsfu_bus.ls_addr[1:0];                           // 4 byte alignment required
         end
      endcase
   end

   assign lsfu_bus.zero_ext = (lsfu_bus.funct3 inside {4,5}) ? 1'b1 : 1'b0;   // 1 = LBU or LHU

endmodule