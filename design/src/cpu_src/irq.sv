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
// File          :  irq.sv
// Description   :  Interrupt Controller and Memory Mapped Registers
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;

module irq
(
   input       logic                clk_in,
   input       logic                reset_in,

   input       logic                mtime_lo_wr,
   input       logic                mtime_hi_wr,
   input       logic                mtimecmp_lo_wr,
   input       logic                mtimecmp_hi_wr,
   input       logic      [RSZ-1:0] mmr_wr_data,
   `ifdef ext_N
   input       logic                msip_wr,
   output      logic                timer_irq,
   output      logic                sw_irq,              // msip_reg[3] = Machine mode Software Interrupt Register
   `endif
   output      logic    [RSZ*2-1:0] mtime,
   output      logic    [RSZ*2-1:0] mtimecmp             // not directly used in csr.sv
);

   `ifdef ext_N
   assign timer_irq  = (mtime >= mtimecmp);
   `endif

   always_ff @(posedge clk_in)
   begin
      // ------------------------------ MSIP Register    (Machine mode Software Interrupt Pending)
      `ifdef ext_N
      if (reset_in)
         sw_irq <= 1'b0;
      else if (msip_wr)
         sw_irq <= mmr_wr_data[3];     // same position as MIP.MSIP ---????? Should this record bits 3,1,0 - software interrupt pending bits for all modes
      `endif

      // ------------------------------ Time in Ticks Register
      if (reset_in)
         mtime <= 'd0;
      else if (mtime_lo_wr)
         mtime[RSZ-1:0] <= mmr_wr_data;                  // lower half of counter
      else if (mtime_hi_wr)
         mtime[RSZ*2-1:RSZ] <= mmr_wr_data;              // upper half of counter
      else                                               // if (mtimecmp != 0) // don't let it count if mtimecmp is 0
         mtime <= RSZ'(mtime + 'd1);                     // otherwise increment counter - cast result to RSZ bits before assigning
      //!!! ??? platform must provide a mechanism for determining the timebase of mtime.   p. 30

      // ------------------------------ Time Compare Register
      if (reset_in)
         mtimecmp <= 'd0;
      else if (mtimecmp_lo_wr)
         mtimecmp[RSZ-1:0] <= mmr_wr_data;               // lower half of counter
      else if (mtimecmp_hi_wr)
         mtimecmp[RSZ*2-1:RSZ] <= mmr_wr_data;           // upper half of counter
   end
endmodule
