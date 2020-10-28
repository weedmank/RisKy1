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
`include "transaction_afu.sv"
    import  cpu_params_pkg::*;
    import cpu_structs_pkg::*; 


class driver_afu;

	int no_transactions;
	virtual interface_afu vif;
	mailbox gen2driv;

	function new(virtual interface_afu vif, mailbox gen2driv);
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

