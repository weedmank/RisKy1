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
// File          :  idr_fu.sv - Integer 32x32 bit UNSIGNED divide and remainder
// Description   :  new RV32IM  architect tailored to the RISC_V 32bit ISA
//               :  This unit decodes at the same time other functional units decode a specific
//               :  instruction. However the EXE stage will only pick the FU output results depending
//               :  on the type of instruction
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module idr_fu #(parameter N = 32)
(
   input    logic    clk_in,
   input    logic    reset_in,

   IDRFU_intf.slave  idrfu_bus
);
   logic     [N-1:0] dividend;
   logic     [N-1:0] divisor;
   logic     [N-1:0] quotient;
   logic     [N-1:0] remainder;
   logic             div_by_0_err,overflow_err; // not used

   logic             start;
   logic             done;

   IDR_OP_TYPE       op;                  // DIV, DIVU, REM, REMU
   logic             is_signed;

   assign dividend   = idrfu_bus.Rs1_data;
   assign divisor    = idrfu_bus.Rs2_data;
   assign op         = idrfu_bus.op;
   assign start      = idrfu_bus.start;

   assign is_signed  = (op == DIV) | (op == REM);

   // WARNING: Currently this only handles UNSIGNED divides,remainder
   sdiv_N_by_N #(N) div1 (clk_in, reset_in, is_signed, start, done, dividend,divisor,quotient,remainder,div_by_0_err,overflow_err);

   assign idrfu_bus.done      = done;
   assign idrfu_bus.quotient  = quotient;       // div_N_by_N returns BOTH quotient and remainder
   assign idrfu_bus.remainder = remainder;

endmodule