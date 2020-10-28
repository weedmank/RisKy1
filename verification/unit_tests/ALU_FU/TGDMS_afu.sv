// *************** TGDMS_afu stands for Transaction, generator, Driver, Monitor, Scoreboard classes all together in one file.

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

// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  driver_afu.sv
// Description   :  
// Driver class for the alu_fu testbench
// Provides a connection between transactions and the values passed into DUT interface.
// Accepts transactions from generator class
// Reset logic for signals
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

//---------------------------------------------------
// 		Driver class
//---------------------------------------------------


class driver_afu;

	int no_transactions;
	virtual AFU vif;
	mailbox gen2driv;

	function new(virtual AFU vif, mailbox gen2driv);
	  this.vif = vif;
	  this.gen2driv = gen2driv;	
	endfunction

	task reset;
	  wait(vif.reset);
	  $display($time, "s [ DRIVER ] ---- Reset begin ----");
	  vif.Rs1_data <= 0;
	  vif.Rs2_data <= 0;
	  vif.Rd_data  <= 0;
     	  vif.imm      <= 0; 
	  vif.pc       <= 0;
	  wait(!vif.reset);
	  $display($time, "s [ DRIVER ] ---- Reset ended ----");
	endtask

	task main;
	  forever begin
	    transaction_afu trans;
	    gen2driv.get(trans);
	    @(posedge vif.clk);
	    	vif.Rs1_data <= trans.Rs1_data;
	    	vif.Rs2_data <= trans.Rs2_data;
        	vif.imm      <= trans.imm; 
	   	vif.pc       <= trans.pc;
	    	vif.sel_x    <= trans.sel_x;
	    	vif.sel_y    <= trans.sel_y;
	    	vif.op       <= trans.op;
	    @(posedge vif.clk);
	    	trans.display("[ Driver ]");
	    no_transactions++;
	  end
	endtask

endclass : driver_afu


// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  monitor_afu.sv
// Description   :  
// Monitor class for the alu_fu testbench
// Provides a connection between transactions and the values coming in from DUT interface.
// creates a mailbox to send transactions to the scoreboard class.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

//---------------------------------------------------
// 		Monitor class
//---------------------------------------------------

class monitor_afu; 

virtual AFU vif;

mailbox mon2scb;

function new(virtual AFU vif, mailbox mon2scb);
  this.vif = vif;
  this.mon2scb = mon2scb;
endfunction 

task main;
	forever begin
		transaction_afu trans;
    		trans = new();
    	@(posedge vif.clk);
    	wait(!vif.reset);
	@(posedge vif.clk);
	    	trans.Rs1_data = vif.Rs1_data;
	    	trans.Rs2_data = vif.Rs2_data;
        	trans.imm      = vif.imm;        
	   	trans.pc       = vif.pc;        
	    	trans.sel_x    = vif.sel_x;     
	    	trans.sel_y    = vif.sel_y;      
	    	trans.op       = vif.op;    
		trans.Rd_data  = vif.Rd_data;
		mon2scb.put(trans);
		trans.display("[ Monitor ]");    
	end
endtask

endclass : monitor_afu


// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  scoreboard_afu.sv
// Description   :  
// Scoreboard class for the alu_fu testbench
// Implements a golden model for self checking.
// Uses counters for manual checking of coverage.
// All possible combinations of input values (sel_x, sel_y) and operations are checked.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

//---------------------------------------------------
// 		Scoreboard class
//---------------------------------------------------

class scoreboard_afu;

	mailbox mon2scb;
	int no_transactions;

	bit [RSZ-1:0] x_sel, y_sel;


// counters for manual coverage metrics
	int error_no = 0;
	int add_no, and_no, sub_no, or_no, xor_no, sll_no, srl_no, sra_no, slt_no, sltu_no = 0;
	int add_error_no, and_error_no, sub_error_no, or_error_no, xor_error_no, sll_error_no, srl_error_no, sra_error_no, slt_error_no, sltu_error_no = 0;
	int rs1_rs1_no, rs1_rs2_no, rs1_imm_no, rs1_pc_no = 0;
	int rs2_rs1_no, rs2_rs2_no, rs2_imm_no, rs2_pc_no = 0;
	int imm_rs1_no, imm_rs2_no, imm_imm_no, imm_pc_no = 0;
	int  pc_rs1_no, pc_rs2_no,  pc_imm_no,  pc_pc_no = 0;
	

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;		
	endfunction
	
	task select_xy (transaction_afu trans);
		case ({trans.sel_x, trans.sel_y}) 
			{AM_RS1, AM_RS1} : begin x_sel = trans.Rs1_data; y_sel = trans.Rs1_data; rs1_rs1_no++;  end
	 		{AM_RS1, AM_RS2} : begin x_sel = trans.Rs1_data; y_sel = trans.Rs2_data; rs1_rs2_no++;  end
	      		{AM_RS1, AM_IMM} : begin x_sel = trans.Rs1_data; y_sel = trans.imm;  	 rs1_imm_no++;  end
			{AM_RS1, AM_PC}  : begin x_sel = trans.Rs1_data; y_sel = trans.pc; 	 rs1_pc_no++;   end
	
	 		{AM_RS2, AM_RS1} : begin x_sel = trans.Rs2_data; y_sel = trans.Rs1_data; rs2_rs1_no++;  end
			{AM_RS2, AM_RS2} : begin x_sel = trans.Rs2_data; y_sel = trans.Rs2_data; rs2_rs2_no++;  end
	      		{AM_RS2, AM_IMM} : begin x_sel = trans.Rs2_data; y_sel = trans.imm; 	 rs2_imm_no++;  end
			{AM_RS2, AM_PC}  : begin x_sel = trans.Rs2_data; y_sel = trans.pc; 	 rs2_pc_no++;   end
	
			{AM_IMM, AM_RS1} : begin x_sel = trans.imm; y_sel = trans.Rs1_data;  	 imm_rs1_no++;  end
	 		{AM_IMM, AM_RS2} : begin x_sel = trans.imm; y_sel = trans.Rs2_data; 	 imm_rs2_no++;  end
	      		{AM_IMM, AM_IMM} : begin x_sel = trans.imm; y_sel = trans.imm;  	 imm_imm_no++;  end
			{AM_IMM, AM_PC}  : begin x_sel = trans.imm; y_sel = trans.pc;  	 	 imm_pc_no++;   end
	
			{AM_PC, AM_RS1} : begin x_sel = trans.pc; y_sel = trans.Rs1_data; 	 pc_rs1_no++;   end
	 		{AM_PC, AM_RS2} : begin x_sel = trans.pc; y_sel = trans.Rs2_data; 	 pc_rs2_no++;   end
	      		{AM_PC, AM_IMM} : begin x_sel = trans.pc; y_sel = trans.imm; 	 	 pc_imm_no++;   end
			{AM_PC, AM_PC}  : begin x_sel = trans.pc; y_sel = trans.pc;		 pc_pc_no++;    end						
		endcase
	endtask :select_xy

	task main;
		transaction_afu trans;		

//	declaring a result variable for self-checker.			
		bit [RSZ-1:0] result = 0;

		forever begin

//		getting the transaction object from the monitor through the mailbox.
			mon2scb.get(trans);
		
//		case statement for all possible operations
			case (trans.op)

// 			Addition
				A_ADD  :        begin 					
							select_xy(trans);
							result = x_sel + y_sel; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_ADD_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_ADD_assert]"); add_error_no++ ; end	
							add_no++;						
						 end
// 			Subtraction
				A_SUB  :         begin 
							select_xy(trans);
							result = x_sel - y_sel; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SUB_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SUB_assert]"); sub_error_no++ ;end	
							sub_no++;							
						 end
// 			AND logic
				A_AND  :         begin 
							select_xy(trans);
							result = x_sel & y_sel; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_AND_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_AND_assert]"); and_error_no++ ;end	
							and_no++;							
						 end
// 			OR logic
				A_OR   :         begin 							
							select_xy(trans);
							result = x_sel | y_sel; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_OR_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_OR_assert]"); or_error_no++ ;end	
							or_no++;							
						 end

// 			XOR logic
				A_XOR  :         begin 						
							select_xy(trans);
							result = x_sel ^ y_sel; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_XOR_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_XOR_assert]"); xor_error_no++ ;end	
							xor_no++;							
						 end

//		Shift left logical (fill with zeroes)
				A_SLL  :         begin 							
							select_xy(trans);
							result = x_sel << y_sel[4:0]; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SLL_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SLL_assert]"); sll_error_no++ ;end	
							sll_no++;							
						 end

//		Shift right logical (fill with zeroes)
				A_SRL  :         begin 							
							select_xy(trans);
							result = x_sel >> y_sel[4:0]; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SRL_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SRL_assert]"); srl_error_no++ ;end	
							srl_no++;							
						 end

//		Shift right arithmetic (keep sign)
				A_SRA  :	begin 
							select_xy(trans);
							result = x_sel >>> y_sel[4:0];
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SRA_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SRA_assert]"); sra_error_no++ ;end	
							sra_no++;							
						 end

//			signed compare
				A_SLT  :	begin 							
							select_xy(trans);
							result = ($signed(x_sel)) < ($signed(y_sel)) ? 'd1 : 'd0; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SLT_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SLT_assert]"); slt_error_no++ ;end	
							slt_no++;							
						 end

//			unsigned compare
				A_SLTU :	begin 
							select_xy(trans);
							result = (x_sel < y_sel) ? 'd1 : 'd0; 
							$display("        Rd_data = %7h", trans.Rd_data);
							$display("Checker Result  = %7h", result);
							A_SLTU_assert: assert (result == trans.Rd_data) else begin $error("ERROR!! @[A_SLTU_assert]"); sltu_error_no++ ;end		
							sltu_no++;						
						 end
			endcase
		end
	endtask : main



endclass : scoreboard_afu

