// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  wb_asserts.sv
// Description   :  Assertions for binding to file wb.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module wb_asserts
(
   input    logic                         clk_in,
   input    logic                         reset_in,

   input    logic                         cpu_halt,                                 // Input:   disable CPU operations by not allowing any more input to this stage

   // interface to Memory stage
   M2W.slave                              M2W_bus,

   input    logic                         xfer_in,

   // interface to GPR
   RBUS.slave                             gpr_bus
);

   // ************************************************ ASSERTIONS ************************************************
//   initial
//   begin
   generate
      if (!(MAX_GPR inside {16,32}))   $fatal ("MAX_GPR is non-standard value of %0d", MAX_GPR);
      if (RSZ  != 32)                  $fatal ("RSZ is non-standard value of %0d", RSZ);
   endgenerate

   always @(negedge clk_in)
   begin
      // M2W_bus.rdy should not be asserted whenever reset_in or cpu_halt are asserted
      WB_RDY_RESET:
      assert (!(M2W_bus.rdy & reset_in))                       else $fatal ("rdy should not be high during reset");
      WB_RDY_HALT:
      assert (!(M2W_bus.rdy & cpu_halt))                       else $fatal ("rdy should not be high during cpu_halt");

      // Rd_wr should not be asserted whenever xfer or M2W_bus.data.Rd_wr are not asserted or when writing to CPU register 0
      WB_RD_WR_XFER_IN:
      assert (!(gpr_bus.Rd_wr & !xfer_in))                     else $fatal ("Rd_wr should not assert when xfer_in is low");
      WB_RD_WR_M2W_RD_WR:
      assert (!(gpr_bus.Rd_wr & !M2W_bus.data.Rd_wr))          else $fatal ("Rd_wr should not assert when M2W_bus.data.Rd_wr is low");
//!!! It's OK to write to X0 so long as it does not change to non-zero value on next clock - Change this !!!
//      WB_RD_WR_GPR0:
//      assert (!(gpr_bus.Rd_wr & !(M2W_bus.data.Rd_addr != 0))) else $fatal ("Rd_wr should not assert when writing to register 0");

      // when Rd_wr is asserted, both Rd_addr and Rd_data should not contain X's or Z's
      WB_RD_WR_RD_ADDR_UNKNOWN:
      assert (!(!reset_in & gpr_bus.Rd_wr & ($isunknown(gpr_bus.Rd_addr) | $isunknown(gpr_bus.Rd_data))))
         else $fatal ("Rd_wr asserted but Rd_addr and/or Rd_data is unknown");

      WB_M2W_VALID_UNKNOWN_RD_WR_RD_ADDR:
      assert (!(!reset_in & M2W_bus.valid & ($isunknown(M2W_bus.data.Rd_wr)  | $isunknown(M2W_bus.data.Rd_addr) | $isunknown(M2W_bus.data.Rd_data))))
         else $fatal ("M2W_bus.valid asserted but one or more of Rd_wr,Rd_addr,Rd_data is unknown");

      WB_M2W_VALID_RD_ADDR_RANGE:
      assert (!(!reset_in & M2W_bus.valid & !(M2W_bus.data.Rd_addr inside {[0:31]})))
         else $fatal("GPR register address range not between 0 and 31");
   end

endmodule