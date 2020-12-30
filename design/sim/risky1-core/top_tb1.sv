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
   integer  clock_cycle;
   logic    sim_stop;

   `define DelayClockCycles(a) \
   repeat (a) @(posedge clk_100)

   initial
   begin
      debug    = FALSE;
      reset    = TRUE;

      `DelayClockCycles(50);
      reset    = 1'b0;
      $display("Reset completed, Simulation started.");
      
      `ifdef M_MODE_ONLY
         $display("RisKy1 set for M Mode Only");
      `else
         $display("RisKy1 simulation is currently set to support the following:");
         $display("   Machine mode");
         `ifdef ext_S
            $display("   Supervisor mode");
         `endif
         `ifdef ext_U
            $display("   User mode");
         `endif
      `endif
      `ifdef ext_N
         $display("   Interrupts");
      `endif
      `ifdef ext_M
         $display("   Integer Mul/Div/Rem instructions");
      `endif
      `ifdef ext_C
         $display("   Compressed (16-bit) instructions");
      `endif
      `ifdef SIM_DEBUG
         $display("   Simulation Debugging logic");
      `endif

      clock_cycle = 0;

      do
      begin
         @ (posedge clk_100);
         clock_cycle += 1;
      end
      while (!sim_stop);                        // sampling of this signal takes place in middle of clock cycle
      @ (posedge clk_100);

      check_gpr(10,1);                          // return value in x10  - in C tests, use something like "return(n)" inside main() where 1 = pass, 0 = fail

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

   //------------------------------------------------------------------------------------------------
   // L1 Instruction Cache model (synthesizable but uses Flip Flops)
   //------------------------------------------------------------------------------------------------
   L1IC_intf   L1IC_bus();
   L1IC_ARB    IC_arb_bus();
   logic ic_flush;

   L1_icache #(.A_SZ(PC_SZ)) L1_ic
   (  .clk_in(clk_100), .reset_in(reset),

      .L1IC_bus(L1IC_bus),        // CPU interface
      .ic_flush(ic_flush),

      // Request from L1 D$ to Invalidate a specific Cache Line
      .inv_req_in(inv_req), .inv_addr_in(inv_addr), .inv_ack_out(inv_ack),            // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_bus(IC_arb_bus)          // Memory Arbiter interface
   );

   //------------------------------------------------------------------------------------------------
   // L1 Data Cache model (synthesizable but uses Flip Flops)
   //------------------------------------------------------------------------------------------------
   // Interface signals to CPU
   L1DC_intf   L1DC_bus();
   L1DC_ARB    DC_arb_bus();
   logic dc_flush;

   L1_dcache #(.A_SZ(PC_SZ)) L1_dc
   (  .clk_in(clk_100), .reset_in(reset),

      .L1DC_bus(L1DC_bus),          // CPU interface
      .dc_flush(dc_flush),

      // Request to L1 I$ to Invalidate a specific Cache Line
      .inv_req_out(inv_req), .inv_addr_out(inv_addr), .inv_ack_in(inv_ack),             // This can occur when a write to L1 D$ occurs to a location in L1 I$ space

      .arb_bus(DC_arb_bus)          // Memory Arbiter interface
   );
/*
   //------------------------------------------------------------------------------------------------
   //  Cache Arbiter with System Memory - non synthesizable - can be substituted for cache_arbiter + sys_mem_model
   //------------------------------------------------------------------------------------------------
   arb_sysmem_model arb
   (
      .clk_in(clk_100), .reset_in(reset),

      .IC_arb_bus(IC_arb_bus),
      .DC_arb_bus(DC_arb_bus)
   );
*/

   //------------------------------------------------------------------------------------------------
   //  Cache Arbiter - synthesizable
   //------------------------------------------------------------------------------------------------
   SysMem   sysmem_bus();
   cache_arbiter carb
   (
      .clk_in(clk_100), .reset_in(reset),

      .IC_arb_bus(IC_arb_bus),
      .DC_arb_bus(DC_arb_bus),
      .sysmem_bus(sysmem_bus)
   );

   //------------------------------------------------------------------------------------------------
   //  System Memory - non synthesizable
   //------------------------------------------------------------------------------------------------
   sys_mem_model sm
   (
      .clk_in(clk_100), .reset_in(reset),

      .sysmem_bus(sysmem_bus)
   );


   //---------------------------------------------------------------------------
	// Risky1 CPU core - synthesizable
   //---------------------------------------------------------------------------
   EIO_intf    EIO_bus();
   
   assign EIO_bus.ack         = TRUE;
   assign EIO_bus.ack_fault   = TRUE;
   assign EIO_bus.ack_data    = 32'hdeadbeef;

   RisKy1_core RK1
   (  .clk_in(clk_100), .reset_in(reset),

      // L1 Instruction Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .L1IC_bus(L1IC_bus),
      .ic_flush(ic_flush),

      // L1 Data Cache Interface - could also be used to interface to "RAM Blocks" in an FPGA
      .L1DC_bus(L1DC_bus),
      .dc_flush(dc_flush),

      .sim_stop(sim_stop),             // used to know when to stop a particular assembly/C program in simulation.

      .ext_irq(1'b0),                  // Input:  Machine mode External Interrupt - could be driven by this test bench
      
      // External I/O accesses
      .EIO_bus(EIO_bus)
   );

   `ifdef BIND_ASSERTS
// Usable in Questasim
// cmd    DUT-module-name   module-name         instance-name ...
   bind   RK1               RV_EMU_asserts      b1 (.*);
   bind   RK1.GPR           gpr_asserts         b2 (.*);
   bind   RK1.WB            wb_asserts          b3 (.*);
   bind   RK1.MEM           mem_asserts         b4 (.*);
   bind   RK1.EXE.CSRFU     csr_asserts         b5 (.*);
//   bind   RK1.EXE.EXE_PIPE  pipe_asserts   b6 (.*); // ** Error: (vsim-8378) Port size (1) does not match connection size (248) for implicit .name connection port 'data_in'. The port definition is at: ../../src/sva/pipe_asserts.sv(30)....
//   bind   RK1.EXE.EXE_PIPE  pipe_asserts   b6 #( .T(type(EXE_2_MEM)) ) (.*); // Doesn't like trying to pass the type EXE_2_MEM 
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
