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
// File          :  csr_std_wr.sv
// Description   :  Standard Write Only portion of a CSR
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;

module csr_std_wr
  #(
      parameter INIT_VALUE = 0,
      parameter ADDR = 0,
      parameter SZ = RSZ,
      parameter ROmask = 0
   )
(
   input       logic             clk_in,
   input       logic             reset_in,

   input       logic       [1:0] mode,
   input       logic             csr_wr,
   input       logic    [SZ-1:0] csr_data,
   output      logic    [SZ-1:0] csr_name
);
   logic       [1:0] lowest_priv;

   assign lowest_priv = ADDR[9:8];

   genvar m;
   generate
      for (m = 0; m < SZ; m++)
      begin
         always_ff @(posedge clk_in)
         begin
            if (reset_in)
               csr_name[m] <= INIT_VALUE[m];
            else if (csr_wr & (mode >= lowest_priv) & !ROmask[m])
               csr_name[m] <= csr_data[m];
         end
      end
   endgenerate
endmodule