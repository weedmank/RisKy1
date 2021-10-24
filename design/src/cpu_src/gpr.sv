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
// File          :  gpr.sv
// Description   :  RV32I General Purpose Registers
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;

module gpr
(
   input    logic                            clk_in,
   input    logic                            reset_in,

   output   logic    [MAX_GPR-1:0] [RSZ-1:0] gpr,              // MAX_GPR General Purpose registers

   RBUS_intf.slave                           gpr_bus
);

   // For RISC-V ISA, X0 is Read Only
   assign gpr[0] = 0;

   // For RISC-V ISA RV32IM, X1 - X15 are 32-bit R/W registers
   genvar k;
   generate
   for (k = 1; k < MAX_GPR; k++)
   begin : WR_REGS
      always_ff @(posedge clk_in)
      begin
         if (reset_in)
            gpr[k] <= 1'd0;
         else if (gpr_bus.Rd_wr & (gpr_bus.Rd_addr == k))      // register Rd must match loop count to know which one to write to
            gpr[k] <= gpr_bus.Rd_data;
      end
   end
   endgenerate

endmodule
