// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  pipe.sv - single word deep fifo with full/empty flag, and output valid signal
// Description   :  Sequential Logic: latches data into pipeline FlipFlops
//               :  and controls transfer of data from one Stage to the next Stage
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module pipe    // simple buffer of Flip Flops between two stages
  #(
      parameter type T = logic
   )
(
   input       logic    clk_in,
   input       logic    reset_in,

   input       logic    write_in,
   input       T        data_in,
   output      logic    full_out,

   input       logic    read_in,
   output      T        data_out,
   output      logic    valid_out
);

   logic       full;

   assign full_out   = full & !read_in; // just one item means full, but only if data is not going to be read this cycle
   assign valid_out  = full;

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         data_out <= '0;
      else if (write_in)
         data_out <= data_in;

      if (reset_in)
         full <= FALSE;
      else if (write_in)
         full <= TRUE;
      else if (read_in)
         full <= FALSE;
   end
endmodule
