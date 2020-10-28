// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  environment.sv
// Description   :  
// Testbench Environment classwhich creates handles/objects of the following classes
// generator, driver, monitor and scoreboard.
// Also provides post test results which are displayed in the transcript.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

// include the file which has transaction, generator, driver, monitor and scoreboard class
`include "TGDMS_afu.sv"


class environment;

// instances of 4 classes
	generator_afu  gen;
	driver_afu    driv;
	monitor_afu    mon;
	scoreboard_afu scb;

// mailbox handles
	mailbox gen2driv;
	mailbox mon2scb;

// virtual interface
	virtual AFU vif;

// constructor
	function new(virtual AFU vif);
	// get the interface from test
		this.vif = vif;
	

// creating the mailbox (handles)
		gen2driv = new();
		mon2scb  = new();

// creating the generator and driver, Monitor and scoreboard
		gen  = new(gen2driv);
		driv = new(vif, gen2driv);
		mon  = new(vif, mon2scb);
		scb  = new(mon2scb);

	endfunction

// driving signals of interest before the test
	task pre_test();
		driv.reset();
	endtask : pre_test

// tasks and functions to run during test
	task test();
		fork
			gen.main();
			driv.main();
			mon.main();
			scb.main();
		join_none
	endtask : test

// post test tasks
// waits till the total number of transactions are done.
// Functional coverage implemented here as counters.
// total number of transactions, errors and types of operations are counted for display
	task post_test();
		wait(gen.end_generation.triggered);
		wait(gen.repeat_count == driv.no_transactions);
		scb.error_no = scb.add_error_no + scb.sub_error_no + scb.and_error_no + scb.or_error_no + scb.xor_error_no + scb.sll_error_no + scb.srl_error_no + scb.sra_error_no + scb.slt_error_no + scb.sltu_error_no;

		$display("======================================================");
	     $display("\n              *** COVERAGE REPORT  ***                  ");
		$display("======================================================");

		$display("\n------------------------------------------------------");
	   	$display("   COMBINATIONS of 'sel_x' and 'sel_y' ");
		$display("------------------------------------------------------");
	   	$display("    {sel_x, sel_y} ==  Test Cases");
		$display("------------------------------------------------------");
		$display("  {AM_RS1, AM_RS1} ==    %4d  ", scb.rs1_rs1_no );
		$display("  {AM_RS1, AM_RS2} ==    %4d  ", scb.rs1_rs2_no );
		$display("  {AM_RS1, AM_IMM} ==    %4d  ", scb.rs1_imm_no );
		$display("  {AM_RS1, AM_PC}  ==    %4d  ", scb.rs1_pc_no );
		$display("\n" );
		$display("  {AM_RS2, AM_RS1} ==    %4d  ", scb.rs2_rs1_no );
		$display("  {AM_RS2, AM_RS2} ==    %4d  ", scb.rs2_rs2_no );
		$display("  {AM_RS2, AM_IMM} ==    %4d  ", scb.rs2_imm_no );
		$display("  {AM_RS2, AM_PC}  ==    %4d  ", scb.rs2_pc_no );
		$display("\n" );
		$display("  {AM_IMM, AM_RS1} ==    %4d  ", scb.imm_rs1_no );
		$display("  {AM_IMM, AM_RS2} ==    %4d  ", scb.imm_rs2_no );
		$display("  {AM_IMM, AM_IMM} ==    %4d  ", scb.imm_imm_no );
		$display("  {AM_IMM, AM_PC}  ==    %4d  ", scb.imm_pc_no );
		$display("\n" );
		$display("  {AM_PC, AM_RS1} ==    %4d  ", scb.pc_rs1_no );
		$display("  {AM_PC, AM_RS2} ==    %4d  ", scb.pc_rs2_no );
		$display("  {AM_PC, AM_IMM} ==    %4d  ", scb.pc_imm_no );
		$display("  {AM_PC, AM_PC}  ==    %4d  ", scb.pc_pc_no );
		$display("------------------------------------------------------");



		$display("\n------------------------------------------------------");
	        $display("       ALU        Test        Errors ");
	        $display("    OPERATION ==  Cases  ==  Identified");
		$display("------------------------------------------------------");
		$display("       ADD    ==   %4d   ==     %4d      ", scb.add_no, scb.add_error_no);
		$display("       SUB    ==   %4d   ==     %4d      ", scb.sub_no, scb.sub_error_no);
		$display("       AND    ==   %4d   ==     %4d      ", scb.and_no, scb.and_error_no);
		$display("       OR     ==   %4d   ==     %4d      ", scb.or_no,  scb.or_error_no);
		$display("       XOR    ==   %4d   ==     %4d      ", scb.xor_no, scb.xor_error_no);
		$display("       SLL    ==   %4d   ==     %4d      ", scb.sll_no, scb.sll_error_no);
		$display("       SRL    ==   %4d   ==     %4d      ", scb.srl_no, scb.srl_error_no);
		$display("       SRA    ==   %4d   ==     %4d      ", scb.sra_no, scb.sra_error_no);
		$display("       SLT    ==   %4d   ==     %4d      ", scb.slt_no, scb.slt_error_no);
		$display("       SLTU   ==   %4d   ==     %4d      ", scb.sltu_no, scb.sltu_error_no);
		$display("------------------------------------------------------");

		$display("\n \n",$time ,"s SCOREBOARD -      TOTAL Test cases    = %d", gen.repeat_count);
		$display($time ,"s SCOREBOARD - TOTAL ERRORS encountered = %d \n", scb.error_no);


	endtask : post_test

// task to run  pre, post and test tasks.
// $stop stops the simulation.
	task run;
		pre_test();
		test();
		post_test();
		$stop;
	endtask : run


endclass