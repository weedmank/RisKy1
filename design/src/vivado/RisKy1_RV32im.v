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
// File          :  RisKy1_RV32i.v
// Description   :  Top level - wrapper for RisKy1_core.sv so it can be instantiated in a Vivado Block Design
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

// We cannot include System Verilog packages.  We NEED 3 values from ../pkg/cpu_params_pkg.sv"
// Make sure the 3 parameters below match those in cpu_params_pkg.sv before synthesizing this design

module RisKy1_RV32im
   #(parameter PC_SZ=32,
     parameter RSZ=32,
     parameter CL_LEN=32)
   (
   input    wire                       clk_in,
   input    wire                       reset_in,

   // L1 Instruction cache interface signals
   output   wire                       ic_req,                                // Output: Request            - Fetch unit is requesting a cache line of data from the I $
   output   wire           [PC_SZ-1:0] ic_addr,                               // Output: Request address    - Memory address that Fetch unit wants to get a cache line of data from
   output   wire                       ic_flush,                              // Output: Request Flush      - signal specifying to flush the Instruction Cache

   input    wire                       ic_ack,                                // Input:  Ackknowledge       - I$ is ackknowledging it has data (ic_rd_data_in) for the Fetch unit
   input    wire        [CL_LEN*8-1:0] ic_ack_data,                           // Input:  Acknowledge data   - this contains CL_LEN bytes of data => CL_LEN/4 instructions

   // L1 Data cache interface signals
   output   wire                       dc_req,                                // Output: Request - must remain high until ack
   output   wire                       dc_rw,                                 // Output: Request - is_ld
   output   wire           [PC_SZ-1:0] dc_rw_addr,                            // Output: Request - ls_addr - Load/Store Address
   output   wire             [RSZ-1:0] dc_wr_data,                            // Output: Request - st_data - Store data
   output   wire                 [2:0] dc_size,                               // Output: Request - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   output   wire                       dc_zero_ext,                           // Output: Request - 1 = Zero Extend
   output   wire                       dc_inv_flag,                           // Output: Request - invalidate flag
   output   wire                       dc_flush,                              // Output: Request - Output: signal requesting to flush the Data Cache

   input    wire                       dc_ack,
   input    wire             [RSZ-1:0] dc_ack_data,

   `ifdef ext_N
   input    wire                       ext_irq,                               // Input:  Machine mode External Interrupt
   `endif

   // External I/O accesses
   output   wire                       io_req_out,                            // Output:  I/O Request
   input    wire                       io_ack_in,                             // Input:   I/O Acknowledge
   output   wire           [PC_SZ-1:0] io_addr,                               // Output:  I/O Address
   output   wire                       io_rd,                                 // Output:  I/O Read signal. 1 = read
   output   wire                       io_wr,                                 // Output:  I/O Write signal. 1 = write
   output   wire             [RSZ-1:0] io_wr_data,                            // Output:  I/O Write data that is written when io_wr == 1
   input    wire             [RSZ-1:0] io_rd_data                             // Input:   I/O Read data
);

   //---------------------------------------------------------------------------
	// Risky1 CPU core
   //---------------------------------------------------------------------------
   RisKy1_core RK1
   (  .clk_in(clk_in), .reset_in(reset_in),

      `ifdef ext_N
      .ext_irq(ext_irq),               // Input:  Machine mode External Interrupt - could be driven by this test bench
      `endif

      // L1 Instruction Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      // Verilog style ports below must be used.
      .ic_req(ic_req),                 // Output:  Request           - Fetch unit is requesting a cache line of data from the I $
      .ic_addr(ic_addr),               // Output:  Request address   - Memory address that Fetch unit wants to get a cache line of data from
      .ic_ack(ic_ack),                 // Input:   Ackknowledge      - I$ is ackknowledging it has data (ic_rd_data_in) for the Fetch unit
      .ic_ack_data(ic_ack_data),       // Input:   Acknowledge data  - this contains CL_LEN bytes of data => CL_LEN/4 instructions

      .ic_flush(ic_flush),             // Output:  signal requesting to flush the Instruction Cache

      // L1 Data Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      // Verilog style ports below must be used.
      .dc_req(dc_req),                 // Output:  Request           - must remain high until ack
      .dc_rd(dc_rd),                   // Output:  Request           - is_ld
      .dc_wr(dc_wr),                   // Output:  Request           - is_st
      .dc_rw_addr(dc_rw_addr),         // Output:  Request           - ls_addr - Load/Store Address
      .dc_wr_data(dc_wr_data),         // Output:  Request           - st_data - Store data
      .dc_size(dc_size),               // Output:  Request           - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
      .dc_zero_ext(dc_zero_ext),       // Output:  Request           - 1 = Zero Extend
      .dc_inv_flag(dc_inv_flag),       // Output:  Request           - invalidate flag
      .dc_ack(dc_ack),                 // Input:   Acknowledge       - D$ is ackknowledging it has data (dc_ack_data) for the MEM unit
      .dc_ack_data(dc_ack_data),       // Input:   Acknowledge data

      .dc_flush(dc_flush),             // Output: signal requesting to flush the Data Cache

      // External I/O accesses
      .io_req(io_req),                 // Output:  I/O Request
      .io_addr(io_addr),               // Output:  I/O Address
      .io_rd(io_rd),                   // Output:  I/O Read signal
      .io_wr(io_wr),                   // Output:  I/O Write signal
      .io_wr_data(io_wr_data),         // Output:  I/O Write Data
      
      .io_ack(io_ack),                 // Input:   I/O Acknowledge   - No external devices right now...
      .io_ack_fault(io_ack_fault),     // Input:   I/O Acccess Fault - No external devices right now...
      .io_rd_data(io_rd_data)          // Input:   I/O read data     - No external devices right now...
   );

endmodule