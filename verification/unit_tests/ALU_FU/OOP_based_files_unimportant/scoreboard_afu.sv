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
`include "transaction_afu.sv"
    import  cpu_params_pkg::*;
    import cpu_structs_pkg::*; 

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

