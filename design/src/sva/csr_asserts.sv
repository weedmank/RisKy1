// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
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