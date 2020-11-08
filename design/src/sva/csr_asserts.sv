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
// File          :  csr_asserts.sv
// Description   :  Assertions for binding to file csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_asserts
(
   input    logic                         clk_in,
   input    logic                         reset_in,

   input    logic                   [1:0] mode,
   input    var EXCEPTION                 exception
);
   // Bind this module to csr_fu.sv

   // property to do sampling on negative edge of clock
   `define assert_clkfall( arg ) \
      assert property (@(negedge clk_in) disable iff (reset_in) arg)

   property mode_chk;
      !$stable(mode) |-> (mode != 2);     // check it everytime it changes
   endproperty

   property mode_after_reset;
      $fell(reset_in) |-> ##1 (mode == 3);
   endproperty

   property mode_after_exception_flag;
      $fell(exception.flag) |-> ##1 (mode == 3);
   endproperty

   CSR_BAD_MODE:               `assert_clkfall( mode_chk )                    else $fatal ("mode should never be 2. mode is %0d",mode);
   CSR_WRONG_RESET_MODE:       `assert_clkfall( mode_after_reset )            else $fatal ("mode after reset should be 3. mode is %0d",mode);
   CSR_WRONG_EXCEPTION_MODE:   `assert_clkfall( mode_after_exception_flag )   else $fatal ("mode after exception should be 3. mode is %0d",mode);
endmodule