// ---------------------------------------------------------------------------------
// Copyright (c) 2019 HDLExpress.com, Canby, OR, USA
// All rights reserved
// ---------------------------------------------------------------------------------
// Project       :
// Editor        :  Notepad++ on Windows 7/10 on wide screen monitor
// FPGA          :
// File          :  csr_lo_cnt.sv
//                  CSR - R/W/count - used as lower 32 bits of a counter
// Description   :  new KPU superscalar OoOE architect tailored to the RISC-V RV32IM ISA
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;


module csr_lo_cnt
  #(
      parameter INIT_VALUE = 0,
      parameter ADDR = 0
   )
(
   input       logic             clk_in,
   input       logic             reset_in,

   input       logic       [1:0] mode,
   input       logic             csr_wr,
   input       logic   [RSZ-1:0] newCSR,
   output      logic   [RSZ-1:0] csr
);
   logic [1:0] lowest_priv;

   assign lowest_priv = ADDR[9:8];

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         csr <= INIT_VALUE;
      else if (csr_wr & (mode >= lowest_priv))
         csr <= newCSR;
      else
         csr <= csr + 1'd1;
   end
endmodule