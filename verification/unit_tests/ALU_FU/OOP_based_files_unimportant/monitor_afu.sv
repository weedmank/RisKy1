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
`include "transaction_afu.sv"
    import  cpu_params_pkg::*;
    import cpu_structs_pkg::*; 


class monitor_afu; 

virtual interface_afu vif;

mailbox mon2scb;

function new(virtual interface_afu vif, mailbox mon2scb);
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
