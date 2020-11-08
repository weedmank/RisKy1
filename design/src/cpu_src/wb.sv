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
// File          :  wb.sv
// Description   :  Write Back stage
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module wb
(
   `ifdef SIM_DEBUG
   input    logic                         clk_in,                                               // Input:   clock only needed during SIM_DEBUG for ABV (Assertion Based Verification)
   `endif
   input    logic                         reset_in,

   input    logic                         cpu_halt,                                             // Input:   disable CPU operations by not allowing any more input to this stage

   // interface to Memory stage
   M2W_intf.slave                         M2W_bus,

   `ifdef ext_F
   // interface to forwarding signals
   output   FWD_FPR                       fwd_wb_fpr,

   // interface to FPR
   FBUS_intf.master                       fpr_bus,
   `endif

   // interface to forwarding signals
   output   FWD_GPR                       fwd_wb_gpr,

   // interface to GPR
   RBUS_intf.master                       gpr_bus
);
   logic xfer_in;

   //------------------------------- Debugging: disassemble instruction in this stage ------------------------------------
   `ifdef SIM_DEBUG
   string   i_str;
   string   pc_str;

   disasm wb_dis (ASSEMBLY,M2W_bus.data.ipd,i_str,pc_str);                                      // disassemble each instruction
   `endif
   //---------------------------------------------------------------------------------------------------------------------

   assign xfer_in             = M2W_bus.valid & M2W_bus.rdy;

   // Forwarding of GPR info
   assign fwd_wb_gpr.valid    = M2W_bus.valid;
   assign fwd_wb_gpr.Rd_wr    = M2W_bus.data.Rd_wr;
   assign fwd_wb_gpr.Rd_addr  = M2W_bus.data.Rd_addr;
   assign fwd_wb_gpr.Rd_data  = M2W_bus.data.Rd_data;

   assign gpr_bus.Rd_wr       = xfer_in & M2W_bus.data.Rd_wr;                                   // when to write
   assign gpr_bus.Rd_addr     = M2W_bus.data.Rd_addr;                                           // Which destination register
   assign gpr_bus.Rd_data     = M2W_bus.data.Rd_data;                                           // data for destination register

   `ifdef ext_F
   // Forwarding of FPR info
   assign fwd_wb_fpr.valid    = M2W_bus.valid;
   assign fwd_wb_fpr.Fd_wr    = M2W_bus.data.Fd_wr;
   assign fwd_wb_fpr.Fd_addr  = M2W_bus.data.Rd_addr;                                           // Rd_aadr and Rd_data can be shared from execute.sv as only Fd_wr and Rd_wr are mutually exclusive
   assign fwd_wb_fpr.Fd_data  = M2W_bus.data.Rd_data;

   assign fpr_bus.Fd_wr       = xfer_in & M2W_bus.data.Fd_wr;                                   // when to write
   assign fpr_bus.Fd_addr     = M2W_bus.data.Rd_addr;                                           // Which destination register
   assign fpr_bus.Fd_data     = M2W_bus.data.Rd_data;                                           // data for destination register
   `endif

   assign M2W_bus.rdy         = !reset_in & !cpu_halt;                                          // always ready to process results
endmodule