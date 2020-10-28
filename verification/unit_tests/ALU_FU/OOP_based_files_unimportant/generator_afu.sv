// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  generator_afu.sv
// Description   :  
// generator class for the alu_fu testbench
// creates a handle to transaction_afu class, randomizes the transactions.
// creates a repeat_count variable to control the number of test cases.
// creates a mailbox to send transactions to the driver class.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

//---------------------------------------------------
// 		Generator class
//---------------------------------------------------
`include "transaction_afu.sv"
    import  cpu_params_pkg::*;
    import cpu_structs_pkg::*; 



class generator_afu;

	rand transaction_afu trans;
	int repeat_count;
	
	mailbox gen2driv;
	event end_generation;
	
	function new(mailbox gen2driv);
		this.gen2driv = gen2driv;
	endfunction

	task main();
		repeat(repeat_count) begin
		trans = new();
		if(!trans.randomize()) $fatal("Generator: trans randomization failed!!");
		trans.display("[ Generator ]");
		gen2driv.put(trans);
		end
	    -> end_generation; // event triggered.
	endtask


endclass : generator_afu
