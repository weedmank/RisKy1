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
// File          :  csr_ff.sv
// Description   :  Standard Write Only portion of a CSR
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;

module csr_ff
  #(
      parameter INIT_VALUE = 0,
      parameter ROmask = 0
   )
(
   input       logic             clk_in,
   input       logic             reset_in,

   input       logic   [RSZ-1:0] csr_data,
   output      logic   [RSZ-1:0] csr_name
);
   genvar m;
   generate
      for (m = 0; m < RSZ; m++)
      begin
         if (ROmask[m])
            assign csr_name[m] = INIT_VALUE[m];          // assign a constant value for this bit
         else // not a read only bit
            always_ff @(posedge clk_in)                  // create a resetable, writable, Flop for this bit
            begin
               if (reset_in)
                  csr_name[m] <= INIT_VALUE[m];
               else
                  csr_name[m] <= csr_data[m];
            end
      end
   endgenerate
endmodule