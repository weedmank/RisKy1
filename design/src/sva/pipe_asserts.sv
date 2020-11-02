// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  pipe_asserts.sv
// Description   :  Assertions for binding to file pipe.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module pipe_asserts    // simple buffer of Flip Flops between two stages
  #(
      parameter type T = logic
   )
(
   input       logic    clk_in,
   input       logic    reset_in,

   input       logic    write_in,
   input       T        data_in,
   input       logic    full_out,

   input       logic    read_in,
   input       T        data_out,
   input       logic    valid_out
);


   // ************************************************ ASSERTIONS ************************************************
   always @(negedge clk_in)
   begin
      // when write_in is asserted, data_in should be KNOWN
      PIPE_WR_DATA_UNKNOWN:
      assert (!(write_in & $isunknown(data_in)))   else $error("pipe: data_in (i.e. 0x%0x) is UNKNOWN during assertion of write_in",data_in);

      // when valid_out is deasserted, read_in should not occur
      PIPE_READ_BUT_NO_VALID:
      assert (!(!valid_out & read_in))             else $error("pipe: read_in = TRUE should not occur during deassertion of valid_out");
      // valid_out should not occur when pipe is empty or during a reset
      PIPE_VALID_WHILE_RESET:
      assert (!(reset_in & valid_out))             else $error("pipe: valid_out should not occur during assertion of reset");
      PIPE_VALID_WHILE_EMPTY:
      assert (!(!full_out & valid_out))            else $error("pipe: valid_out should not occur when pipe is empty");

      // when pipe is full and read_in is FALSE, no write_in should occur
      PIPE_FULL_WRITE_NO_READ:
      assert (!(write_in & full_out & !read_in))   else $error("pipe: write_in should not occur when pipe is full and no data is being read out of it!");
   end
endmodule