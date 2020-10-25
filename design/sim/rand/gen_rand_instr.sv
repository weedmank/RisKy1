// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  gen_rand_inst.sv - Generate a stream of random instructions to test in simulation
// Description   :  new RV32IM  architect tailored to the RISC_V 32bit ISA
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

///**************************** WARNING ************************ NOT COMPLETED!!!
`timescale 1ns/100ps

`include "functions.svh"
`include "logic_params.svh"
`include "cpu_params.svh"
`include "cpu_structs.svh"


module  gen_rand_instr ();
   parameter N = 1000;                           // Number of random instructions to create - limited by Instr_Depth. see cpu_params.svh

   `define R_TYPE(op, f3, f7) \
         opcode   = op; \
         rd       = $urandom_range(0,31); \
         funct3   = f3; \
         rs1      = $urandom_range(0,31); \
         rs2      = $urandom_range(0,31); \
         funct7   = f7; \
         instr    = {funct7, rs2, rs1, funct3, rd, opcode};

   `define I_TYPE(op, f3) \
         opcode   = op; \
         rd       = $urandom_range(0,31); \
         funct3   = f3; \
         rs1      = $urandom_range(0,31); \
         imm      = $urandom_range(0,(1<<12)-1); \
         /* $display("I_TYPE: imm = %12b, rs1 = %5b, funct3 = %3b, rd = %5b, opcode = %7b", imm, rs1, funct3, rd, opcode); */ \
         instr    = {imm, rs1, funct3, rd, opcode};

   `define S_TYPE(op, f3) \
         opcode   = op; \
         imm      = $urandom_range(0,(1<<12)-1); \
         funct3   = f3; \
         rs1      = $urandom_range(0,31); \
         rs2      = $urandom_range(0,31); \
         instr    = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
         
   `define B_TYPE(op, f3) \
         opcode   = op; \
         imm      = $urandom_range(0,(1<<12)-1); \
         funct3   = f3; \
         rs1      = $urandom_range(0,31); \
         rs2      = $urandom_range(0,31); \
         instr    = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};

   `define U_J_TYPE(op) \
         opcode   = op; \
         rd       = $urandom_range(0,31); \
         imm      = $urandom_range(0,(1<<20)-1); \
         instr    = {imm, rd, opcode};

   `define gen_lui      `U_J_TYPE(7'b0110111);                 // LUI
   `define gen_auipc    `U_J_TYPE(7'b0010111);                 // AUIPC
   `define gen_jal      `U_J_TYPE(7'b1101111);                 // JAL
   `define gen_jalr     `I_TYPE(7'b1100111,3'b000);            // JALR
   `define gen_beq      `B_TYPE(7'b1100011,3'b000);            // BEQ
   `define gen_bne      `B_TYPE(7'b1100011,3'b001);            // BNE
   `define gen_blt      `B_TYPE(7'b1100011,3'b100);            // BLT
   `define gen_bge      `B_TYPE(7'b1100011,3'b101);            // BGE
   `define gen_bltu     `B_TYPE(7'b1100011,3'b110);            // BLTU
   `define gen_bgeu     `B_TYPE(7'b1100011,3'b111);            // BGEU
   `define gen_lb       `B_TYPE(7'b0000011,3'b000);            // LB
   `define gen_lh       `B_TYPE(7'b0000011,3'b001);            // LH
   `define gen_lw       `B_TYPE(7'b0000011,3'b010);            // LW
   `define gen_lbu      `B_TYPE(7'b0000011,3'b100);            // LBU
   `define gen_lhu      `B_TYPE(7'b0000011,3'b101);            // LHU
   `define gen_sb       `S_TYPE(7'b0100011,3'b000);            // SB
   `define gen_sh       `S_TYPE(7'b0100011,3'b001);            // SH
   `define gen_sw       `S_TYPE(7'b0100011,3'b010);            // SW
   `define gen_addi     `I_TYPE(7'b0010011,3'b000);            // ADDI
   `define gen_slti     `I_TYPE(7'b0010011,3'b010);            // SLTI
   `define gen_sltiu    `I_TYPE(7'b0010011,3'b011);            // SLTIU
   `define gen_xori     `I_TYPE(7'b0010011,3'b100);            // XORI
   `define gen_ori      `I_TYPE(7'b0010011,3'b110);            // ORI
   `define gen_andi     `I_TYPE(7'b0010011,3'b111);            // ANDI
   `define gen_slli     `R_TYPE(7'b0010011,3'b001,7'b0);       // SLLI
   `define gen_srli     `R_TYPE(7'b0010011,3'b101,7'b0);       // SRLI
   `define gen_srai     `R_TYPE(7'b0010011,3'b101,7'b0100000); // SRAI
   `define gen_add      `R_TYPE(7'b0110011,3'b000,7'b0000000); // ADD
   `define gen_sub      `R_TYPE(7'b0110011,3'b000,7'b0100000); // SUB
   `define gen_sll      `R_TYPE(7'b0110011,3'b001,7'b0000000); // SLL
   `define gen_slt      `R_TYPE(7'b0110011,3'b010,7'b0000000); // SLT
   `define gen_sltu     `R_TYPE(7'b0110011,3'b011,7'b0000000); // SLTU
   `define gen_xor      `R_TYPE(7'b0110011,3'b100,7'b0000000); // XOR
   `define gen_srl      `R_TYPE(7'b0110011,3'b101,7'b0000000); // SRL
   `define gen_sra      `R_TYPE(7'b0110011,3'b101,7'b0100000); // SRA
   `define gen_or       `R_TYPE(7'b0110011,3'b110,7'b0000000); // OR
   `define gen_and      `R_TYPE(7'b0110011,3'b111,7'b0000000); // AND
   `define gen_fence    `I_TYPE(7'b0001111,3'b000);            // FENCE
   `define gen_ecall    {12'b1, 5'b0, 3'b0, 5'b0, 7'b1110011}; // ECALL
   `define gen_ebreak   {12'b1, 5'b0, 3'b0, 5'b0, 7'b1110011}; // EBREAK

   initial
   begin
      $display("Generating random instructions");

      create_rand_instr();
      
      $display("generation complete - see instr/rand.rom");
      $stop;
   end

   task create_rand_instr;
      begin
         integer           k;
         integer           fd;   // file descriptor
         logic       [7:0] sel;
         logic   [RSZ-1:0] instr;
         
         // needed for gen_??? tasks
         logic       [6:0] opcode;
         logic       [4:0] rd;
         logic       [2:0] funct3;
         logic       [4:0] rs1;
         logic       [4:0] rs2;
         logic       [6:0] funct7;
         logic      [19:0] imm;
         
         // open file "rand.rom" here
         fd = $fopen("instr_tests/rand.rom","w+");
         for (k = 0; k < N; k++)
         begin
            sel = $urandom_range(0,20);                                    // randomly select which instruciton type
            case (sel)
               0:  begin  `gen_lui;    end
               1:  begin  `gen_auipc;  end
               2:  begin  `gen_addi;   end
               3:  begin  `gen_slti;   end
               4:  begin  `gen_sltiu;  end
               5:  begin  `gen_xori;   end
               6:  begin  `gen_ori;    end
               7:  begin  `gen_andi;   end
               8:  begin  `gen_slli;   end
               9:  begin  `gen_srli;   end
               10: begin  `gen_srai;   end
               11: begin  `gen_add;    end
               12: begin  `gen_sub;    end
               13: begin  `gen_sll;    end
               14: begin  `gen_slt;    end
               15: begin  `gen_sltu;   end
               16: begin  `gen_xor;    end
               17: begin  `gen_srl;    end
               18: begin  `gen_sra;    end
               19: begin  `gen_or;     end
               20: begin  `gen_and;    end
               // can't totally randomize the following instructions
//             21: begin  `gen_jal;    end                            // FIX: jumps and branches wiill take exceptions if not aligned, must be within Physical memory space and code would have to exist at that location
//             22: begin  `gen_jalr;   end
//             23: begin  `gen_beq;    end
//             24: begin  `gen_bne;    end
//             25: begin  `gen_blt;    end
//             26: begin  `gen_bge;    end
//             27: begin  `gen_bltu;   end
//             28: begin  `gen_bgeu;   end
//             29: begin  `gen_lb;     end                            // FIX: Loads and Stores wiill take exceptions if not aligned and must be in Physical Memory space and not overwrite instruction space.
//             30: begin  `gen_lh;     end
//             31: begin  `gen_lw;     end
//             32: begin  `gen_lbu;    end
//             33: begin  `gen_lhu;    end
//             34: begin  `gen_sb;     end                            // Also, Stores should not write into instruction space and should write into data space
//             35: begin  `gen_sh;     end
//             36: begin  `gen_sw;     end
//             37: begin  `gen_fence;  end
//             38: begin  `gen_ecall;  end
//             39: begin  `gen_ebreak; end
            endcase
            $display("%0d: instr = 0x%8x", k, instr);
            // write instruction as ascii hex data to the file
            $fwrite(fd,"%8x\n", instr);
         end
         $fclose(fd);
      end
   endtask
   
endmodule