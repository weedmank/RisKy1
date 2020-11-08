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
// File          :  RisKy1_L1_caches_arbiter.v
// Description   :  Top level - compatible to use inside a wrapper for a Vivado Block Design. RisKy1_core.sv + L1 Caches + Cache Arbiter
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

`define VIVADO // need to figure out how to add these defines into Vivado project - these MUST be commented out if not using Vivado!!!!!
`define ext_M

//        ...........................................................................................................................................................
//        : RisKy1_L1_cache_arbiter                                                                                                                                 :
//        :                                                                                                                                                         :
//        :                                                                         ............................................................................    :
//        :                                                                         :  RisKy1_core                                                             :    :
//        :                                                                         :                                                                          :    :
//        :                                                                         :                                                                          :    :
//        :                                                                         :           +--------------+                                               :    :
//        :                                                                         :           |    FETCH     |                                               :    :
//        :     +-------------------------------------------------------------------:---------->|              |                                               :    :
//        :     |                                                                   :           |              |                                               :    :
//        :     |                                                                   :           +------+-------+                                               :    :
//        :     |                                                                   :                  |                                                       :    :
//        :     |                                                                   :                  v                                                       :    :
//        :     |                                                                   :           +------+-------+                                               :    :
//        :     |                                                                   :           |              |                                               :    :
//        :     |                                                                   :           |    DECODE    |                                               :    :
//        :     |                                                                   :           |              |                                               :    :
//        :     |                                                                   :           +------+-------+                                               :    :
//        :     |                                                                   :                  |                                                       :    :
//        :     |                                                                   :                  v                          +-----------+                :    :
//        :     |                                                                   :           +------+-------+                  |   IRQ     |                :    :
//        :     |                                                                   :           |              |   timer_irq      |           |<---------------:----:---- External Interrupts (optional)
//        :     |                                                                   :       +-->|    EXECUTE   |<-----------------|           |                :    :
//        :     |           +-----------+               +-----------+               :       |   |              |   sw_irq         +-----+-----+                :    :
//        :     |           |           |               |           |               :       |   +------+-------+                        ^                      :    :
//        :     +---------->| L1_ICACHE |               | L1_DCACHE |<--------------:       |          |                                |                      :    :
//        :                 |           |               |           |               :       |          v                                v                      :    :
//        :                 +-----+-----+               +-----+-----+               :       |   +------+-------+                  +-----+-----+                :    :
//        :                       |                           |                     :       |   |              |                  |   MEM_IO  |<---------------:----:---> External I/O interface
//        :                       +----------+     +----------+                     :       |   |     MEM      |<---------------->|           |                :    :
//        :                                  |     |                                :       |   |              |                  |           |<----------+    :    :
//        :                                  |     |                                :       |   +------+-------+                  +-----------+           |    :    :
//        :                               +--+-----+--+                             :       |          |                                                  |    :    :
//        :                               |   Cache   |                             :       |          v                          +------------------+    |    :    :
//        :                               |  Arbiter  |                             :       |   +------+-------+                  |   Architectural  |    |    :    :
//        :                               |           |                             :       |   |              |----------------->|   Registers      |    |    :    :
//        :                               +-----+-----+                             :       |   |      WB      |                  |   (gpr, fpr)     |    |    :    :
//        :                                     |                                   :       |   |              |                  +----------+-------+    |    :    :
//        :                                     |                                   :       |   +--------------+                             |            |    :    :
//        :                                     |                                   :       |                                                |            |    :    :
//        :                                     |                                   :       |                                                |            |    :    :
//        :                                     |                                   :       |                                                |            |    :    :
//        :                                     |                                   :       +------------------------------------------------+            |    :    :
//        :                                     |                                   :                                                                     |    :    :
//        :                                     |                                   :---------------------------------------------------------------------+    :    :
//        :                                     |                                   :                                                                          :    :
//        :                                     |                                   :..........................................................................:    :
//        :                                     |                                                                                                                   :
//        ...........................................................................................................................................................
//                                              |      
//                                        +-----+-----+
//                                        |  System   |
//                                        |  Memory   |
//                                        |           |
//                                        +-----------+
module RisKy1_L1_caches_arbiter
(
   // Note that ports are all Verilog style. See comment further below about Vivado top level modules.
   input    wire                       clk_in,
   input    wire                       reset_in,

   `ifdef ext_N
   input    wire                       ext_irq,                      // Input:  Machine mode External Interrupt
   `endif   
   
   // External I/O accesses   
   output   wire                       io_req,                       // Output:  I/O Request
   input    wire                       io_ack,                       // Input:   I/O Acknowledge
//   output   wire           [PC_SZ-1:0] io_addr,                      // Output:  I/O Address
   output   wire              [32-1:0] io_addr,                      // Output:  I/O Address
   output   wire                       io_rd,                        // Output:  I/O Read signal. 1 = read
   output   wire                       io_wr,                        // Output:  I/O Write signal. 1 = write
//   output   wire             [RSZ-1:0] io_wr_data,                   // Output:  I/O Write data that is written when io_wr == 1
//   input    wire             [RSZ-1:0] io_rd_data                    // Input:   I/O Read data
   output   wire              [32-1:0] io_wr_data,                   // Output:  I/O Write data that is written when io_wr == 1
   input    wire              [32-1:0] io_rd_data,                   // Input:   I/O Read data

   // Interface to External System Memory
      // Requests a cache line read or write from/to the System Memory
   input    wire                       sys_mem_req_rw,               // Read = 1, Write = 0
   input    wire     [PC_SZ-CL_SZ-1:0] sys_mem_req_addr,             // Request address to System Memory
   input    wire        [CL_LEN*8-1:0] sys_mem_req_wr_data,          // Request write data to System Memory when rw==0
   input    wire                       sys_mem_req_valid,            // Request valid to System Memory
   output   wire                       sys_mem_req_rdy,              // Request ready from System Memory
   
      // System Memory Acknowledges and passes a cache line of data to the Arbiter
   output   wire        [CL_LEN*8-1:0] sys_mem_ack_rd_data,          // Acknowledge read data from System Memory. will contain a cache line of data if reading, N/A if writing.
   output   wire                       sys_mem_ack_valid,            // Acknowledge valid from System Memory
   input    wire                       sys_mem_ack_rdy               // Acknowledge ready to System Memory
);


   L1IC     L1IC_intf();
   L1IC_ARB IC_arb_bus();
   logic    ic_flush;
   
   L1DC     L1DC_intf();
   L1DC_ARB DC_arb_bus();
   logic    dc_flush;
   
   SysMem   sysmem_bus();
   
   // The following assignment monkey business is due only to Vivado. Vivado cannot instantiate a file with module ports using System Verilog constructs!
   // NOTHING can be System Verilog when instantiating a top level module into the Block Design environment/schematic.
   assign sys_mem_req_rdy        = sysmem_bus.req_rdy;
   assign sys_mem_ack_rd_data    = sysmem_bus.ack_rd_data;
   assign sys_mem_ack_valid      = sysmem_bus.ack_valid;
   
   assign sysmem_bus.req_rw      = sys_mem_req_rw;
   assign sysmem_bus.req_addr    = sys_mem_req_addr;
   assign sysmem_bus.req_wr_data = sys_mem_req_wr_data;
   assign sysmem_bus.req_valid   = sys_mem_req_valid;
   assign sysmem_bus.ack_rdy     = sys_mem_ack_rdy;
   
  // Invalidate Cache Line request from Memory Arbiter
   logic                      inv_req;                // Write to L1 D$ caused an invalidate requesdt to L1 I$
   logic          [PC_SZ-1:0] inv_addr;               // which cache line address to invalidate
   logic                      inv_ack;                // L1 I$ acknowledge if invalidate

   //------------------------------------------------------------------------------------------------
   // L1 Instruction Cache model (synthesizable but uses Flip Flops!!!)
   //------------------------------------------------------------------------------------------------
   L1_icache #(.A_SZ(PC_SZ)) L1_ic
   (  .clk_in(clk_100), .reset_in(reset),

      .L1IC_intf(L1IC_intf),        // CPU interface
      .ic_flush(ic_flush),

      // Request from L1 D$ to Invalidate a specific Cache Line
      .inv_req_in(inv_req), .inv_addr_in(inv_addr), .inv_ack_out(inv_ack),            // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_bus(IC_arb_bus)          // Memory Arbiter interface
   );

   //------------------------------------------------------------------------------------------------
   // L1 Data Cache model (synthesizable but uses Flip Flops!!!)
   //------------------------------------------------------------------------------------------------
   L1_dcache #(.A_SZ(PC_SZ)) L1_dc
   (  .clk_in(clk_100), .reset_in(reset),

      .L1DC_intf(L1DC_intf),        // CPU interface
      .dc_flush(dc_flush),

      // Request to L1 I$ to Invalidate a specific Cache Line
      .inv_req_out(inv_req), .inv_addr_out(inv_addr), .inv_ack_in(inv_ack),             // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_bus(DC_arb_bus)          // Memory Arbiter interface
   );

   //------------------------------------------------------------------------------------------------
   //  Cache Arbiter - synthesizable
   //------------------------------------------------------------------------------------------------
   cache_arbiter carb
   (
      .clk_in(clk_100), .reset_in(reset),
      
      .IC_arb_bus(IC_arb_bus),
      .DC_arb_bus(DC_arb_bus),
      .sysmem_bus(sysmem_bus)          // interface to external System Memory - contains a Request channel and an Acknowledge channel
   );


   //---------------------------------------------------------------------------
	// Risky1 CPU core - synthesizable
   //---------------------------------------------------------------------------
   RisKy1_core RK1
   (  .clk_in(clk_100), .reset_in(reset),
      
      `ifdef ext_N
      .ext_irq(ext_irq),               // Input:  Machine mode External Interrupt - could be driven by this test bench
      `endif

      // L1 Instruction Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .L1IC_intf(L1IC_intf),
      .ic_flush(ic_flush),

      // L1 Data Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .L1DC_intf(L1DC_intf),
      .dc_flush(dc_flush),

      // External I/O accesses
      .io_req(io_req),                 // Output:  I/O Request
      .io_addr(io_addr),               // Output:  I/O Address
      .io_rd(io_rd),                   // Output:  I/O Read signal
      .io_wr(io_wr),                   // Output:  I/O Write signal
      .io_wr_data(io_wr_data),         // Output:  I/O write data

      .io_ack(io_ack),                 // Input:   I/O Acknowledge   - No external devices right now...
      .io_ack_fault(io_ack_fault),     // Input:   I/O Acknowledge   - No external devices right now...
      .io_rd_data(io_rd_data)          // Input:   I/O read data     - No external devices right now...
   );


endmodule