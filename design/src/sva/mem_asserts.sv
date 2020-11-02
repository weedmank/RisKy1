// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  mem_asserts.sv
// Description   :  Assertions for binding to file mem.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module mem_asserts
(
   input    logic                      clk_in,
   input    logic                      reset_in,

   input    logic                      cpu_halt,               // Input:   disable CPU operations by not allowing any more input to this stage

   // interface to forwarding signals
   input    var FWD_GPR                fwd_mem_gpr,

   // System Memory or I/O interface signals
   L1DC_intf.slave                     MIO_bus,

   input    logic                      full,
   input    logic                      rd_pipe_in,
   input    logic                      is_st,
   input    logic                      is_ld,

   // interface to Execute stage
   E2M_intf.slave                      E2M_bus,

   input    var MEM_2_WB               mem_dout                // data going into mem pipe registers
   );

   // ************************************************ ASSERTIONS ************************************************
   always @(negedge clk_in)
   begin
      if (!reset_in)
      begin
         // E2M_bus.rdy should not be asserted whenever reset_in or cpu_halt or full are asserted
         MEM_RDY_FULL:  assert (!(E2M_bus.rdy & full))       else $fatal ("mem_asserts: rdy should not go high during full");
         MEM_RDY_RESET: assert (!(E2M_bus.rdy & reset_in))   else $fatal ("mem_asserts: rdy should not go high during reset");
         MEM_RDY_HALT:  assert (!(E2M_bus.rdy & cpu_halt))   else $fatal ("mem_asserts: rdy should not go high during cpu_halt");

         // when E2M_bus.valid is asserted, both fwd_mem_gpr.Rd_wr and fwd_mem_gpr.Rd_addr and fwd_mem_gpr.Rd_data should not contain X's or Z's
         MEM_E2M_BUS_RDY_VALID_X:
         assert (!(fwd_mem_gpr.valid & ($isunknown(fwd_mem_gpr.Rd_wr) | $isunknown(fwd_mem_gpr.Rd_addr) | $isunknown(fwd_mem_gpr.Rd_data))))
            else $fatal ("mem_asserts: gpr_Rd_wr asserted but gpr_Rd_addr and/or gpr_Rd_data is unknown");

         // when E2M_bus.valid is asserted, E2M_bus.data.Rd_addr should be the range of 0 ... 31
         MEM_E2M_BUS_RD_ADDR_RANGE:
         assert (!(E2M_bus.valid & !(E2M_bus.data.Rd_addr inside {[0:31]})))  else $fatal("mem_asserts: GPR register address range not between 0 and 31");

         // when MIO_bus.req is asserted, .rw, .rw_addr, .wr_data, .size, .zer_ext should all be KNOWN values
         MEM_IO_RD_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.rd)) )           else $fatal ("mem_asserts: MIO_bus.req_data.rd is unknown during MIO_bus.req assertion");
         MEM_IO_WR_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.wr)) )           else $fatal ("mem_asserts: MIO_bus.req_data.wr is unknown during MIO_bus.req assertion");
         MEM_IO_RW_ADDR_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.rw_addr)) )      else $fatal ("mem_asserts: MIO_bus.req_data.rw_addr is unknown during MIO_bus.req assertion");
         MEM_IO_WR_DATA_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.wr_data)) )      else $fatal ("mem_asserts: MIO_bus.req_data.wr_data is unknown during MIO_bus.req assertion");
         MEM_IO_SIZE_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.size)) )         else $fatal ("mem_asserts: MIO_bus.req_data.size is unknown during MIO_bus.req assertion");
         MEM_IO_ZERO_EXT_UNKNOWN:
         assert (!(MIO_bus.req & $isunknown(MIO_bus.req_data.zero_ext)) )     else $fatal ("mem_asserts: MIO_bus.req_data.zero_ext is unknown during MIO_bus.req assertion");

         FWD_MEM_GPR_RD_WR:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_gpr.Rd_wr)) )       else $fatal ("mem_asserts: fwd_mem_gpr.Rd_wr is unknown when fwd_mem_gpr.valid == TRUE");
         FWD_MEM_GPR_RD_ADDR:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_gpr.Rd_addr)) )     else $fatal ("mem_asserts: fwd_mem_gpr.Rd_addr is unknown when fwd_mem_gpr.valid == TRUE");
         FWD_MEM_GPR_RD_DATA:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_gpr.Rd_data)) )     else $fatal ("mem_asserts: fwd_mem_gpr.Rd_data is unknown when fwd_mem_gpr.valid == TRUE");

         `ifdef ext_F
         FWD_MEM_FPR_RD_WR:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_fpr.Rd_wr)) )       else $fatal ("mem_asserts: fwd_mem_fpr.Rd_wr is unknown when fwd_mem_fpr.valid == TRUE");
         FWD_MEM_FPR_RD_ADDR:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_fpr.Rd_addr)) )     else $fatal ("mem_asserts: fwd_mem_fpr.Rd_addr is unknown when fwd_mem_fpr.valid == TRUE");
         FWD_MEM_FPR_RD_DATA:
         assert (!(fwd_mem_gpr.valid & $isunknown(fwd_mem_fpr.Rd_data)) )     else $fatal ("mem_asserts: fwd_mem_fpr.Rd_data is unknown when fwd_mem_fpr.valid == TRUE");
         `endif
         
         // when MIO_bus.req is asserted, MIO_bus.req_data.size needs to be specific values
         MEM_IO_REQ_SIZE:
         assert (!(MIO_bus.req & !(MIO_bus.req_data.size inside {0,1,2,4})) ) else $fatal ("mem_asserts: MIO_bus.req_data.size has invalid value of %d", MIO_bus.req_data.size);

         // when rd_pipe_in is asserted, .Rd_wr, .Rd_addr and .Rd_data must be KNOWN
         MEM_RD_WR:
         assert (!(rd_pipe_in & $isunknown(mem_dout.Rd_wr)) )                 else $fatal ("mem_asserts: mem_dout.Rd_wr (i.e %d) is unknown during rd_pipe_in", mem_dout.Rd_wr);
         MEM_RD_ADDR:
         assert (!(rd_pipe_in & $isunknown(mem_dout.Rd_addr)) )               else $fatal ("mem_asserts: mem_dout.Rd_addr (i.e %d) is unknown during rd_pipe_in", mem_dout.Rd_addr);
         MEM_RD_DATA:
         assert (!(rd_pipe_in & $isunknown(mem_dout.Rd_data)) )               else $fatal ("mem_asserts: mem_dout.Rd_data (i.e 0x%0x) is unknown during rd_pipe_in", mem_dout.Rd_data);

         // when mem_dout.Rd_wr is asserted, .Rd_addr must be in range
         MEM_RD_WR_RD_ADDR_RANGE:
         assert (!(mem_dout.Rd_wr & !(mem_dout.Rd_addr inside {[0:31]})))     else $fatal ("mem_asserts: mem_dout.Rd_addr address range not between 0 and 31");

         // is_st and is_ld should never be asserted at the same time
         MEM_LS_ST:
         assert (!(is_st & is_ld)) else $fatal ("mem_asserts: is_ld and is_st asserted at the same time");
      end
   end

endmodule