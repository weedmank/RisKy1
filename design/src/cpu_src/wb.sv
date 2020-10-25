// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
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
   M2W.slave                              M2W_bus,

   `ifdef ext_F
   // interface to forwarding signals
   output   FWD_FPR                       fwd_wb_fpr,

   // interface to FPR
   output   logic                         fpr_Fd_wr,                                            // 1 = write to destination register
   output   logic           [FPR_ASZ-1:0] fpr_Fd_addr,                                          // Destination Register to write
   output   logic              [FLEN-1:0] fpr_Fd_data,                                          // data that will be written to the destination register
   `endif

   // interface to forwarding signals
   output   FWD_GPR                       fwd_wb_gpr,

   // interface to GPR
   RBUS.master                            gpr_bus
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

   assign fpr_Fd_wr           = xfer_in & M2W_bus.data.Fd_wr;                                   // when to write
   assign fpr_Fd_addr         = M2W_bus.data.Rd_addr;                                           // Which destination register
   assign fpr_Fd_data         = M2W_bus.data.Rd_data;                                           // data for destination register
   `endif

   assign M2W_bus.rdy         = !reset_in & !cpu_halt;                                          // always ready to process results
endmodule