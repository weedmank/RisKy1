// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
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

   output   logic   [MAX_FPR-1:0] [FLEN-1:0] fpr,              // MAX_FPR General Purpose registers
   input    logic                            fpr_Fd_wr,
   input    logic              [FPR_ASZ-1:0] fpr_Fd_addr,
   input    logic                 [FLEN-1:0] fpr_Fd_data
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
         else if (fpr_Fd_wr & (fpr_Fd_addr == k))              // register Fd must match loop count to know which one to write to
            fpr[k] <= fpr_Fd_data;
      end
   end
   endgenerate

endmodule
