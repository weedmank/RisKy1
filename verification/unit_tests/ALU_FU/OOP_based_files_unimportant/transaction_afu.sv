// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  transaction_afu.sv
// Description   :  
// Transaction class for the alu_fu testbench
// constrained randomization of input signals.
// display the signals.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

//---------------------------------------------------
// 		Transaction class
//---------------------------------------------------
    import  cpu_params_pkg::*;
    import cpu_structs_pkg::*; 

class transaction_afu;
// randomization of all input signals.


      rand bit         [RSZ-1:0] Rs1_data;
      rand bit         [RSZ-1:0] Rs2_data;
      	   bit         [RSZ-1:0] Rd_data;
      rand bit         [PC_SZ-1:0] pc;
      rand bit         [RSZ-1:0] imm;

      rand  ALU_SEL_TYPE          sel_x;
      rand  ALU_SEL_TYPE          sel_y;
      rand  ALU_OP_TYPE	  op;	

	constraint c_sel_x    {sel_x dist {AM_RS1 := 25, AM_IMM := 25, AM_RS2 := 25, AM_PC := 25};} 
	constraint c_sel_y    {sel_y dist {AM_RS1 := 25, AM_IMM := 25, AM_RS2 := 25, AM_PC := 25};} 

	//constraint c_sel_x    {sel_x dist {AM_RS1 := 100, AM_IMM := 0, AM_RS2 := 0, AM_PC := 0};} 
	//constraint c_sel_y    {sel_y dist {AM_RS1 := 0, AM_IMM := 0, AM_RS2 := 100, AM_PC := 0};} 

	constraint c_op	      {op dist {A_ADD:= 10, A_SUB :=10, A_AND :=10, A_OR:=10, A_XOR:=10, A_SLL:=10, A_SRL:=10, A_SRA:=10, A_SLT:=10, A_SLTU:=10};}
	//constraint c_op	      {op dist {A_ADD:= 100, A_SUB :=0, A_AND :=0, A_OR:=0, A_XOR:=0, A_SLL:=0, A_SRL:=0, A_SRA:=0, A_SLT:=0, A_SLTU:=0};}



	function void display(string name);
		$display("-------------------------------------------------------------------------------");
	 	$display($time, "s | Component: - %s ", name);
		$display("-------------------------------------------------------------------------------");
		$display(" INPUTS  :  RS1  -  %7h,  RS2  - %7h, IMM - %7h, PC - %7h", Rs1_data, Rs2_data, imm, pc);
		$display("-------------------------------------------------------------------------------");
		$display("SEL & OP :  sel_x- %7s,  sel_y - %7s, OP  - %7s", sel_x, sel_y, op);
		$display("-------------------------------------------------------------------------------");
	endfunction





endclass : transaction_afu
