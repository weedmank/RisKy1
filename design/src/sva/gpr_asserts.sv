// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  gpr_asserts.sv
// Description   :  Assertions for binding to file gpr.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import cpu_params_pkg::*;

module gpr_asserts
(
   input    logic                               clk_in,
   input    logic                               reset_in,

   input    var logic   [MAX_GPR-1:0] [RSZ-1:0] gpr,              // MAX_GPR General Purpose registers

   RBUS_intf.slave                              gpr_bus
);
   // ************************************************ ASSERTIONS ************************************************

   // property to do sampling on negative edge of clock
   `define assert_clkfall( arg ) \
      assert property (@(negedge clk_in) disable iff (reset_in) arg)

   property gpr_reg_save;
      bit [GPR_ASZ-1:0] addr;
      bit [RSZ-1:0] data;
      // when a GPR register write occurs, save the GPR address and data during this clock cycle so they can be used for verificaion in the next clock cycle
      (gpr_bus.Rd_wr, addr = gpr_bus.Rd_addr, data = gpr_bus.Rd_data) |-> ##1 (gpr[addr] == data);
   endproperty

   ERROR_GPR_REG_NOT_SAVED: `assert_clkfall( gpr_reg_save );

   always @(negedge clk_in)
   begin
      GPR_RD_WR_RESET:
      assert (!(gpr_bus.Rd_wr & reset_in))                     else $fatal("gpr_bus.Rd_wr should not be asserted during reset");
      GPR_RD_WR_RD_ADDR_UNKNOWN:
      assert (!(gpr_bus.Rd_wr & $isunknown(gpr_bus.Rd_addr)))  else $fatal("gpr_bus.Rd_addr (i.e. 0x%0x) is UNKNOWN during assertion of gpr_bus.Rd_wr",gpr_bus.Rd_addr);
      GPR_RD_WR_RD_DATA_UNKNOWN:
      assert (!(gpr_bus.Rd_wr & $isunknown(gpr_bus.Rd_data)))  else $fatal("gpr_bus.Rd_data (i.e. 0x%0x) is UNKNOWN during assertion of gpr_bus.Rd_wr",gpr_bus.Rd_data);
   end

   // All GPR registers should have 0 values in 1st clock cycle after reset falls
   property gpr_after_reset;
      $fell(reset_in) |-> ##1 (gpr == '0);
   endproperty

   ERROR_NOT_ALL_GPR_REGS_ZERO: `assert_clkfall( gpr_after_reset );

   // All GPR registers should have KNOWN values after reset


endmodule