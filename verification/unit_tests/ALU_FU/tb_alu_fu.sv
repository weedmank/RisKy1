// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  tb_alu_fu.sv
// Description   :  
// Top level testbench(TB) for the OOP based verification environment
// Generates clock, instantiates and connects the interface, test program and the DUT
//              
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/systemverilog-examples/systemverilog-testbench-example-with-scb/
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

// import all package files
import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;
//`include "AFU_intf.sv"


module tb_alu_fu;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#20 reset = 0;
	end

   	AFU i_intf(clk, reset);   // instantiate the AFU verification interface which supplies the clock and reset signals.

	test t1(i_intf);          // instantiate the program with randon_test functionality

    	alu_fu alu (i_intf.slave);// instantiate the  DUT 

endmodule
