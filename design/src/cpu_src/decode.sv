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
// File          :  decode.sv
// Description   :  Sequential Logic: latches decode_core.sv control signals into pipeline FlipFlops
//               :  and controls transfer of data from Fetch unit and transfer of data to Execute unit
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module decode
(
   input    logic                   clk_in,
   input    logic                   reset_in,

   input    logic                   cpu_halt,               // Input:   disable CPU operations by not allowing any more input to this stage

   // misprediction signal
   input    logic                   pipe_flush,             // Input:   1 = Flush this segment of the pipeline

   // connections with FETCH stage
   F2D_intf.slave                   F2D_bus,

   // connections with Decode stage
   D2E_intf.master                  D2E_bus
);


   logic       rd_pipe_in;
   logic       rd_pipe_out, wr_pipe_out;
   logic       full;
   DEC_2_EXE   dec_out;

   DCORE_intf  dcore_bus();

   assign F2D_bus.rdy      = !full & !reset_in & !cpu_halt;

   assign rd_pipe_in       = F2D_bus.valid & F2D_bus.rdy;      // pop data from fetch pipeline register..
   assign wr_pipe_out      = rd_pipe_in;                       // ...and write new data into DEC_PIPE registers
   assign rd_pipe_out      = D2E_bus.valid & D2E_bus.rdy;      // pops data from DEC_PIPE registers to next stage

   //------------------------------- Debugging: disassemble instruction in this stage ------------------------------------
   `ifdef SIM_DEBUG
   string   i_str;
   string   pc_str;

   disasm dec_dis (ASSEMBLY,F2D_bus.data.ipd,i_str,pc_str); // disassemble each instruction
   `endif
   //---------------------------------------------------------------------------------------------------------------------

   assign dcore_bus.fet_data = F2D_bus.data;   // Fetch info going in and Decode data coming back

   decode_core dcore ( .dcore_bus(dcore_bus) );

   always_comb
   begin
      dec_out = '0;     // default values until valid info available
      if (F2D_bus.valid)
         dec_out = dcore_bus.dec_data;
   end

   // Set of Flip Flops (for pipelining) with control logic ('full' signal) sitting between Decode logic and the next stage
   pipe #( .T(type(DEC_2_EXE)) ) DEC_PIPE
   (
      .clk_in(clk_in),  .reset_in(reset_in | pipe_flush),
      .write_in(wr_pipe_out),  .data_in(dcore_bus.dec_data),   .full_out(full),
      .read_in(rd_pipe_out),   .data_out(D2E_bus.data),        .valid_out(D2E_bus.valid)
   );
endmodule
