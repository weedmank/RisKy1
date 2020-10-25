// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  top_tb1.v - Top Level test bench #1
// Description   :  new RV32IM  architect tailored to the RISC_V 32bit ISA
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module  top_tb1 ();

   logic    reset;
   logic    clk_100;
   logic    debug;
   integer    clock_cycle;
   logic    sim_stop;

   `define DelayClockCycles(a) \
   repeat (a) @(posedge clk_100)

   // Changing MAX_INSTR requires a change to "Instr_Depth" and maybe "Phys_Addr_Hi" in cpu_params.svh.
   // It also requires changing the contents of the .rom file being used - see "mem_arb_model.sv" in top_tb1.do
   // Typically the file rand.rom is used and can be regenerated for N instructions with gen_rand_instr.sv (parameter N) & gen_rand_instr.do
   parameter MAX_INSTR = 1000;

   initial
   begin
      debug    = FALSE;
      reset    = TRUE;

      `DelayClockCycles(50);
      reset    = 1'b0;
      $display("Reset completed, Simulation started.");


      `ifdef RANDOM
      $display("Testing %0d constrained random instructions", MAX_INSTR);
      `endif

      clock_cycle = 0;

      do
      begin
         @ (posedge clk_100);
         clock_cycle += 1;
      end
      `ifdef RANDOM
      while (clock_cycle != (MAX_INSTR+20));    // fixed number of clock cycle for random testing with rand.rom - limited by Instr_Depth. see cpu_params.svh
      `else
      while (!sim_stop);                        // sampling of this signal takes place in middle of clock cycle
      @ (posedge clk_100);

      check_gpr(10,1);                          // return value in x10  - in C tests, use something like "return(n)" inside main() where 1 = pass, 0 = fail
      `endif

      `DelayClockCycles(5);
      $display("Simulation passed.");
      $stop;
   end

   //-----------------------------------------------------------------------------
   // Generate 100 Mhz clock
   //-----------------------------------------------------------------------------

	initial
	begin
		clk_100 = 1'b0;
		#44 // simulate some startup delay
		forever
			clk_100 = #5 ~clk_100;
	end

   // Invalidate Cache Line request from Memory Arbiter
   logic                      inv_req;                // Write to L1 D$ caused an invalidate requesdt to L1 I$
   logic          [PC_SZ-1:0] inv_addr;               // which cache line address to invalidate
   logic                      inv_ack;                // L1 I$ acknowledge if invalidate

   // Signals for L1_icache requests a cache line of data from Arbiter/System Memory
   logic    [PC_SZ-CL_SZ-1:0] arb_ic_req_addr;        // Cache Line Address to Arbiter/System Memory.
   logic                      arb_ic_req_valid;       // valid to Arbiter/System Memory
   logic                      arb_ic_req_rdy;         // ready from Arbiter/System Memory

   // Signals for L1_dcache requests a cache line of data from Arbiter/System Memory
   ARB_Data                   arb_dc_req_info;
   logic                      arb_dc_req_valid;
   logic                      arb_dc_req_rdy;

   // Signals for Arbiter/System Memory acknowledges and passes cache line of data to L1_icache
   logic       [CL_LEN*8-1:0] arb_ic_ack_data;        // data from Arbiter/System Memory. will contain a cache line of data. This could be "input logic  [CL_LEN*8-1:0] arb_dc_data_in;", where CL_LEN = 32, 64 ???
   logic                      arb_ic_ack_valid;       // valid from Arbiter/System Memory
   logic                      arb_ic_ack_rdy;         // ready to Arbiter/System Memory

   // Signals for Arbiter/System Memory acknowledges and passes cache line of data to L1_dcache
   logic       [CL_LEN*8-1:0] arb_dc_ack_data;
   logic                      arb_dc_ack_valid;
   logic                      arb_dc_ack_rdy;

   //------------------------------------------------------------------------------------------------
   // L1 Instruction Cache model (synthesizable but uses Flip Flops)
   //------------------------------------------------------------------------------------------------
   logic          [PC_SZ-1:0] ic_addr;
   logic                      ic_req;
   logic                      ic_ack;
   logic       [CL_LEN*8-1:0] ic_rd_data;             // rd data input (this contains CL_LEN bytes of data => CL_LEN/4 instructions)
   logic                      ic_flush;

   L1_icache #(.A_SZ(PC_SZ)) L1_ic
   (  .clk_in(clk_100), .reset_in(reset),

      // Request from L1 D$ to Invalidate a specific Cache Line
      .inv_req_in(inv_req),               .inv_addr_in(inv_addr),               .inv_ack_out(inv_ack),            // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_req_addr_out(arb_ic_req_addr), .arb_req_valid_out(arb_ic_req_valid), .arb_req_rdy_in(arb_ic_req_rdy),  // L1_icache line of data to Arbiter/System Memory
      .arb_ack_data_in(arb_ic_ack_data),  .arb_ack_valid_in(arb_ic_ack_valid),  .arb_ack_rdy_out(arb_ic_ack_rdy), // Arbiter/System Memory Acknowledges and passes cache line of data to L1_icache

      .ic_addr_in(ic_addr), .ic_req_in(ic_req), .ic_ack_out(ic_ack), .ic_rd_data_out(ic_rd_data),
      .ic_flush(ic_flush)
   );

   //------------------------------------------------------------------------------------------------
   // L1 Data Cache model (synthesizable but uses Flip Flops)
   //------------------------------------------------------------------------------------------------
   // Interface signals to CPU
   L1DC_DIN             dc_data;       // Address from CPU specifying which cache line to get
   logic                dc_req;
   logic                dc_ack;
   logic      [RSZ-1:0] dc_rd_data;    // CL_LEN bytes of data (cache line) from cache to Fetch stage plus branch information
   logic                dc_flush;

   L1_dcache #(.A_SZ(PC_SZ)) L1_dc
   (  .clk_in(clk_100), .reset_in(reset),

      // Request to L1 I$ to Invalidate a specific Cache Line
      .inv_req_out(inv_req),              .inv_addr_out(inv_addr),              .inv_ack_in(inv_ack),             // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_req_data_out(arb_dc_req_info), .arb_req_valid_out(arb_dc_req_valid), .arb_req_rdy_in(arb_dc_req_rdy),  // L1_dcache Requests a cache line of data from Arbiter/System Memory
      .arb_ack_data_in(arb_dc_ack_data),  .arb_ack_valid_in(arb_dc_ack_valid),  .arb_ack_rdy_out(arb_dc_ack_rdy), // Arbiter/System Memory Acknowledges and passes cache line of data to L1_dcache

      .dc_data_in(dc_data), .dc_req_in(dc_req), .dc_ack_out(dc_ack), .dc_rd_data_out(dc_rd_data),
      .dc_flush(dc_flush)
   );

   //------------------------------------------------------------------------------------------------
   //  Memory Arbiter Model - System Memory is inside the model
   //------------------------------------------------------------------------------------------------
   mem_arb_model arb
   (
      .clk_in(clk_100), .reset_in(reset),
      // Request commumication channel with L1 Instruction Cache
      .arb_ic_req_addr_in(arb_ic_req_addr),  .arb_ic_req_valid_in(arb_ic_req_valid),  .arb_ic_req_rdy_out(arb_ic_req_rdy),
      // Request commumication channel with L1 Data Cache
      .arb_dc_req_info_in(arb_dc_req_info),  .arb_dc_req_valid_in(arb_dc_req_valid),  .arb_dc_req_rdy_out(arb_dc_req_rdy),
      // Acknowledge communication channel with L1 Instruction Cache
      .arb_ic_ack_data_out(arb_ic_ack_data), .arb_ic_ack_valid_out(arb_ic_ack_valid), .arb_ic_ack_rdy_in(arb_ic_ack_rdy),
      // Acknowledge communication channel with L1 Data Cache
      .arb_dc_ack_data_out(arb_dc_ack_data), .arb_dc_ack_valid_out(arb_dc_ack_valid), .arb_dc_ack_rdy_in(arb_dc_ack_rdy)
   );

   //---------------------------------------------------------------------------
	// Risky1 CPU core
   //---------------------------------------------------------------------------
   RisKy1_core RK1
   (  .clk_in(clk_100), .reset_in(reset),

      // L1 Instruction Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .ic_addr_out(ic_addr), .ic_req_out(ic_req), .ic_ack_in(ic_ack), .ic_rd_data_in(ic_rd_data),
      .ic_flush(ic_flush),

      // L1 Data Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .dc_data_out(dc_data), .dc_req_out(dc_req), .dc_ack_in(dc_ack), .dc_rd_data_in(dc_rd_data),
      .dc_flush(dc_flush),

      // External I/O accesses
      .io_req_out(),                   // Output:  I/O Request
      .io_ack_in(TRUE),                // Input:   I/O Acknowledge   - No external devices right now...
      .io_addr(),                      // Output:  I/O Address
      .io_wr(),                        // Output:  I/O write signal
      .io_wr_data(),                   // Output:  I/O write data
      .io_rd_data(32'hdeadbeef),       // Input:   I/O read data     - No external devices right now...

      .sim_stop(sim_stop),             // used to know when to stop a particular assembly/C program in simulation.

      .ext_irq(1'b0)                   // Input:  Machine mode External Interrupt - could be driven by this test bench
   );

   `ifdef BIND_ASSERTS
// Usable in Questasim
// cmd    DUT-module-name   module-name    instance-name ...
   bind   gpr               gpr_asserts    b1 (.*);
   bind   wb                wb_asserts     b3 (.*);
   bind   mem               mem_asserts    b4 (.*);
   bind   csr_fu            csr_asserts    b5 (.*);
   `endif

   task check_gpr;
      input  [GPR_ASZ-1:0] rx;
      input [RSZ-1:0] value;
      if (RK1.GPR.gpr[rx] !== value)
      begin
         $display("ERROR: top_tb1.sv: check_gpr(): GPR[%0d] = %0d, not %0d", rx, RK1.GPR.gpr[rx], value);
         $stop;
      end
   endtask

endmodule