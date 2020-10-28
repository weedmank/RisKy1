// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  AFU_intf.sv
//
// Description   :  
// A seperate interface file for AFU testbench.
// An interface file containing AFU interface from design\src\cpu_src\cpu_intf.sv
// Parameterized inputs clk and reset are provided for running the testbench.
// 
//
// TB Designer      :  Abhishek Yadav (ya.abhishek@gmail.com)
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

// importing parameters and structure packages
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

// interface for AFU FU testbench environment
interface AFU(input logic clk, reset);
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      logic       [PC_SZ-1:0] pc;
      logic         [RSZ-1:0] imm;
      ALU_SEL_TYPE            sel_x;
      ALU_SEL_TYPE            sel_y;
      ALU_OP_TYPE             op;

      logic         [RSZ-1:0] Rd_data;

      modport master (output Rs1_data, Rs2_data, pc, imm, sel_x, sel_y, op, input  Rd_data);
      modport slave  (input  Rs1_data, Rs2_data, pc, imm, sel_x, sel_y, op, output Rd_data);
endinterface: AFU