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
// File          :  fpr.sv
// Description   :  RV32F Single Precision FLoating Point Registers
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;

module fpr
(
   input    logic                            clk_in,
   input    logic                            reset_in,

   output   logic   [MAX_FPR-1:0] [FLEN-1:0] fpr,                 // MAX_FPR General Purpose registers

   FBUS_intf.slave                           fpr_bus
);

   // For RISC-V ISA RV32IM, F0 - F15 are 32-bit R/W registers
   genvar k;
   generate
   for (k = 0; k < MAX_FPR; k++)
   begin : WR_SPFP_REGS
      always_ff @(posedge clk_in)
      begin
         if (reset_in)
            fpr[k] <= 1'd0;
         else if (fpr_bus.Fd_wr & (fpr_bus.Fd_addr == k))         // register Fd must match loop count to know which one to write to
            fpr[k] <= fpr_bus.Fd_data;
      end
   end
   endgenerate

endmodule
