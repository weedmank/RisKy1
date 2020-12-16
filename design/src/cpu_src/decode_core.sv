// ----------------------------------------------------------------------------------------------------
// Copyright (c) 2020 Kirk Weedman www.hdlexpress.com
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  decode_core.sv
// Description   :  Combinational Only logic - produces control signals needed by other stages of CPU
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module decode_core
(
   DCORE_intf.slave     dcore_bus
);

   // ----------------------------------------------------------------------------------------------------------
   // RISC_V Decode Logic
   // ----------------------------------------------------------------------------------------------------------
   logic     [XLEN-1:0] i;

   logic      [RSZ-1:0] s_imm;
   logic      [RSZ-1:0] i_imm;
   logic      [RSZ-1:0] b_imm;
   logic      [RSZ-1:0] u_imm;
   logic      [RSZ-1:0] j_imm;
   logic      [RSZ-1:0] shamt;
   logic      [RSZ-1:0] csrx;
   logic  [GPR_ASZ-1:0] Rd_addr;
   logic  [GPR_ASZ-1:0] Rs1_addr;
   logic  [GPR_ASZ-1:0] Rs2_addr;
   logic          [2:0] funct3;

   `ifdef ext_F
   logic      [RSZ-1:0] rs3_rm;
   `endif

   `ifdef ext_C
   logic      [RSZ-1:0] c_addi4spn_imm;
   logic      [RSZ-1:0] c_lwsp_imm;
   logic      [RSZ-1:0] c_swsp_imm;
   logic      [RSZ-1:0] c_b_imm;
   logic      [RSZ-1:0] c_lw_imm;
   logic      [RSZ-1:0] c_sw_imm;
   logic      [RSZ-1:0] c_imm;
   logic      [RSZ-1:0] c_j_imm;
   logic      [RSZ-1:0] c_addi16sp_imm;
   logic      [RSZ-1:0] c_lui_imm;
   logic      [RSZ-1:0] c_shamt;
   `endif
   ROM_Data             cntrl_sigs;

   assign   i  = dcore_bus.fet_data.ipd.instruction;

   // The two values 0x00000000 and 0xFFFFFFFF are specified as “illegal instructions” and will cause an “illegal
   // instruction exception” if fetched and executed.

   assign dcore_bus.dec_data.ipd             = dcore_bus.fet_data.ipd;             // add this dcore_bus info to the Dec_Data
   assign dcore_bus.dec_data.predicted_addr  = dcore_bus.fet_data.predicted_addr;  // add this dcore_bus info to the Dec_Data. Note: dcore_bus.predicted.is_br not passed since execute doesn't need it

   assign dcore_bus.dec_data.Rs1_rd          = cntrl_sigs.Rs1_rd;
   assign dcore_bus.dec_data.Rs2_rd          = cntrl_sigs.Rs2_rd;
   assign dcore_bus.dec_data.Rd_wr           = cntrl_sigs.Rd_wr;
   `ifdef ext_F
   assign dcore_bus.dec_data.Fs1_rd          = cntrl_sigs.Fs1_rd;
   assign dcore_bus.dec_data.Fs2_rd          = cntrl_sigs.Fs2_rd;
   assign dcore_bus.dec_data.Fd_wr           = cntrl_sigs.Fd_wr;
   `endif
   assign dcore_bus.dec_data.ig_type         = cntrl_sigs.ig_type;
   assign dcore_bus.dec_data.sel_x           = cntrl_sigs.sel_x;
   assign dcore_bus.dec_data.sel_y           = cntrl_sigs.sel_y;
   assign dcore_bus.dec_data.op              = cntrl_sigs.op;
   assign dcore_bus.dec_data.ci              = cntrl_sigs.ci;
   assign dcore_bus.dec_data.imm             = cntrl_sigs.imm;

   assign dcore_bus.dec_data.Rd_addr         = Rd_addr;
   assign dcore_bus.dec_data.Rs1_addr        = Rs1_addr;
   assign dcore_bus.dec_data.Rs2_addr        = Rs2_addr;
   assign dcore_bus.dec_data.funct3          = funct3;

   // RV32I immediate values that will be needed depending on instruction
   assign i_imm   = {{21{i[31]}},i[30:20]};
   assign s_imm   = {{21{i[31]}},i[30:25],i[11:7]};
   assign b_imm   = {{20{i[31]}},i[7],i[30:25],i[11:8],1'b0};
   assign u_imm   = {i[31:12],12'd0};
   assign j_imm   = {{12{i[31]}},i[19:12],i[20],i[30:21],1'b0};
   assign shamt   = {27'd0,i[25:20]};
   assign csrx    = {20'd0,i[31:20]};     // address of chosen CSR

   `ifdef ext_C
   assign c_addi4spn_imm   = {24'b0,i[10:7],i[12:11],i[5],i[6],2'b00};                    // see C.ADDI4SPN
   // c_addi4spn_imm                  9:6     5:4     3    2

   assign c_b_imm          = {{25{i[12]}},i[6:5],i[2],i[11:10],i[4:3],1'b0};
   // c_b_imm                        8      7:6    5     4:3     2:1

   assign c_lwsp_imm       = {24'b0,i[3:2],i[12],i[6:4],2'b00};                           // See C.LWSP
   // c_lwsp_imm                      7:6     5    4:2

   assign c_swsp_imm       = {24'b0,i[8:7],i[12:9],2'b00};                                // See C.SWSP
   // c_swsp_imm                      7:6     5:2

   assign c_lw_imm         = {25'b0,i[5],i[12:10],i[6],2'b00};                            // see C.LW, C.FLW
   // c_lw_imm                        6    5:3      2

   assign c_sw_imm         = {25'b0,i[5],i[12:10],i[6],2'b00};                            // see C.SW, C.FSW
   // c_sw_imm                        6    5:3      2

   assign c_imm            = {{27{i[12]}},i[6:2]};                                        // see C.ADDI, C.NOP, C.LI, C.ANDI

   assign c_shamt          = {26'b0,i[12],i[6:2]};                                        // see C.SRLI

   assign c_j_imm          = {{21{i[12]}},i[8],i[10:9],i[6],i[7],i[2],i[11],i[5:3],1'b0}; // see C.JAL p 102
   // c_j_imm                       11     10    9  8    7    6    5    4     3:1

   assign c_addi16sp_imm   = {{23{i[12]}},i[4:3],i[5],i[2],i[6],4'b0000};                 // See C.ADDI16SP
   // c_addi16sp_imm                9       8:7    6    5    4

   assign c_lui_imm        = {{15{i[12]}},i[6:2],12'b0};                                  // see C.LUI
   // c_lui_imm                     17     16:12
   `endif

   `ifdef ext_F
   assign rs3_rm   = {24'd0,i[31:27],funct3};    // Rs3 and rm values for certain Single Precision Floating Point instructions
   `endif

   // signals that go on to other pipeline stages
   always_comb
   begin
      Rd_addr  = i[11:7];
      Rs1_addr = i[19:15];
      Rs2_addr = i[24:20];
      funct3   = i[14:12];

      priority if (i[1:0] != 2'b11) // Compressed Instruction?
      begin
         // RV32C instruction decode. See riscv-spec.pdf p 95 - 112
         // NOTE: Even though ext_C may not be defined, we have to handle what happens
         // if a compressed instruction is encounterd (i.e. deafult to illegal instruction)

         // number of bits                     1      1      1     1      1      1      4           2       2       4       1     32
         //                                    Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         cntrl_sigs =                        '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  ILL_INSTR,  AM_IMM, AM_IMM, A_ADD,  1'b1, 'd0          };    // includes `C_ILLEGAL  16'b000___00000000_000_00

         // ext_C must be defined at compile time in order to create decode logic for Compressed instructions, otherwise the above ILL_INSTR will occur
         `ifdef ext_C

         // Register values come from different instruction bits for Compressed
         funct3   = i[15:13];

         // full_case — at least one item is true
         // parallel_case — at most one item is true
         case (i[1:0])
            0: // Quadrant 0  see p 110
            begin
               Rd_addr  = {2'b00,i[4:2]};
               Rs1_addr = {2'b00,i[9:7]};
               Rs2_addr = {2'b00,i[4:2]};
               // number of bits               1      1      1     1      1      1      4           2       2       4       1     32
               //                              Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case (funct3)
                  0:
                  begin
                     // C.ADDI4SPN is only valid when nzuimm̸=0; the code points with nzuimm=0 are reserved. p. 105 riscv-spec.pdf
                     Rs1_addr = 2;                                                                                               // expands to ADDI Rd, R2, nzuimm[9:2]  p. 105
                     if (c_addi4spn_imm != 0)
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_ADD,  1'b1, c_addi4spn_imm};   // C.ADDI4SPN   16'b000___????????_???_00
                     // else reserved decoding space
                  end

                  `ifdef ext_D
                  1: cntrl_sigs =                                                                                                // C.FLD  16'b001_???_???_??_???_00     (RV32/64)
                  `endif

                  2: cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b1, c_lw_imm     };    // C.LW         16'b010_???_???_??_???_00

                  `ifdef ext_F
                  3: cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_IMM, F_LW,   1'b1, c_lw_imm     };    // C.FLW
                  `endif

                  `ifdef ext_D
                  5: cntrl_sigs =                                                                                                // C.FSD  16'b101_???_???_??_???_00     (RV32/64)
                  `endif

                  6: cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  ST_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b1, c_sw_imm     };    // C.SW         16'b110_???_???_??_???_00

                  `ifdef ext_F
                  7: cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  SPFP_INSTR, FM_RS1, FM_IMM, F_SW,   1'b1, c_sw_imm     };    // C.FSW
                  `endif
               endcase
            end

            1: // Quadrant 1  see p. 111
            begin
               Rd_addr     = i[15] ? {2'b00,i[9:7]} : i[11:7];
               Rs1_addr    = i[15] ? {2'b00,i[9:7]} : i[11:7];
               Rs2_addr    = {2'b00,i[4:2]};
                // number of bits               1      1      1     1      1      1      4           2       2       4       1     32
               //                              Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case (funct3)
                  0: // Quadrant 1:0
                  begin
                     // C.ADDI is only valid when rd̸=x0. The code point with both rd=x0 and nzimm=0 encodes the C.NOP instruction;
                     // the remaining code points with either rd=x0 or nzimm=0 encode HINTs. p. 104 riscv-spec.pdf
                     if (Rd_addr == 0)
                     begin
                        if (c_imm == 0)
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  ALU_INSTR,  AM_RS1, AM_IMM, A_ADD,  1'b1, 32'd0        };    // nop - The code point with both rd=x0 and nzimm=0 encodes the C.NOP instruction p 104
                        `ifdef H_C_NOP
                        else // if ((Rd_addr == 0) && (c_imm != 0))
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_NOP   };    // HINT
                        `endif
                     end
                     else // rd̸=x0 (i.e. Rd_addr != 0) "C.ADDI is only valid when rd̸=x0." see riscv-spec.pdf p. 104
                     begin
                        if (c_imm != 0)   // "C.ADDI adds the non-zero sign-extended 6-bit immediate to the value in register rd then writes the result to rd." see riscv-spec.pdf p. 104
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_ADD,  1'b1, c_imm        };    // C.ADDI - addi Rd, Rd, nzimm[5:0].  see p. 104, 111
                        `ifdef H_C_ADDI
                        else  // (Rd_addr != 0) && (c_imm == 0)
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_ADDI  };    // HINT
                        `endif
                     end
                  end

                  1: // Quadrant 1:1
                  // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
                  //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
                  begin
                     Rd_addr  = 1;                                                                                               // x1 will get updated to pc + 2
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  BR_INSTR,   BS_PC,  BS_IMM, B_JAL,  1'b1, c_j_imm      };    // C.JAL = JAL R1, offset[11:1]
                  end

                  2: // Quadrant 1:2
                  // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
                  //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
                  begin
                     // C.LI is only valid when rd̸=x0; the code points with rd=x0 encode HINTs. see riscv-spec.pdf p. 104
                     if (Rd_addr != 0)
                        cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  ALU_INSTR,  AM_IMM, AM_IMM, A_OR,   1'b1, c_imm        };    // C.LI = ADDI Rd, R0, imm5_0. p 104
                     `ifdef H_C_LI
                     else
                        cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_LI    };    // HINT
                     `endif
                  end

                  3: // Quadrant 1:3
                  // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
                  //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
                  begin
                     // C.LUI is only valid when rd̸={x0, x2}, and when the immediate is not equal to zero. The code points with nzimm=0 are reserved;
                     // the remaining code points with rd=x0 are HINTs; and the remaining code points with rd=x2 correspond to the C.ADDI16SP instruction. p 104
                     if (Rd_addr == 2)       // Rs1_addr is the same as Rd_addr
                     begin
                        if (c_addi16sp_imm != 0)
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_ADD,  1'b1, c_addi16sp_imm};   // C.ADDI16SP --> addi x2, x2, nzimm[9:4]
                     end
                     else if (Rd_addr != 0)
                     begin
                        if (c_lui_imm != 0)  // C.LUI is only valid when rd̸={x0, x2}, and when the immediate is not equal to zero.
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  ALU_INSTR,  AM_IMM, AM_IMM, A_OR,   1'b1, c_lui_imm    };    // C.LUI = LUI Rd, nzimm[17:12]. see p. 104
                     end
                     `ifdef H_C_LUI
                     else                       // Rd_addr = X0 -> "the remaining code points with rd=x0 are HINTs"
                        cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_LUI   };    // HINT
                     `endif
                  end

                  4: // Quadrant 1:4
                  // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
                  //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
                  begin
                     case (i[11:10])
                        0:
                        if (!c_shamt[5])        // "For RV32C, shamt[5] must be zero;" see p 105
                        begin
                           if (c_shamt[4:0] != 0) // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                           begin
                              if (Rd_addr != 0) // "For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C." p. 105
                                 cntrl_sigs ='{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SRL,  1'b1, c_shamt      };    // C.SRLI = SRLI Rd, Rd, shamt[5:0] p. 105
                              `ifdef H_C_SRLI
                              else
                                 cntrl_sigs ='{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SRLI  };    // HINT
                              `endif
                           end
                           `ifdef H_C_SRLI2
                           else
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SRLI2 };    // HINT - "the code points with shamt=0 are HINTs" p 105
                           `endif
                        end
                        // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105

                        1:
                        if (!c_shamt[5])        // "For RV32C, shamt[5] must be zero;" see p 105
                        begin
                           if (c_shamt != 0)    // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                           begin
                              if (Rd_addr != 0) //For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C. p. 105
                                 cntrl_sigs ='{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SRA,  1'b1, c_shamt      };    // C.SRAI = SRAI Rd, Rd, shamt[5:0] p.105-106
                              `ifdef H_C_SRAI
                              else
                                 cntrl_sigs ='{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SRAI  };    // HINT
                              `endif
                           end
                           `ifdef H_C_SRAI2
                           else                 // "the code points with shamt=0 are HINTs" p 105
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SRAI2 };    // HINT - "the code points with shamt=0 are HINTs" p 105
                           `endif
                        end
                        // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105

                        2: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_AND,  1'b1, c_imm        };    // C.ANDI = ANDI Rd, Rd, sext(imm[5:0]) p. 106

                        3:
                        if (!i[12])
                        begin
                           case (i[6:5])
                           0: cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SUB,  1'b1, 32'd0        };    // C.SUB  = SUB Rd, Rd, Rs2   p. 107
                           1: cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_XOR,  1'b1, 32'd0        };    // C.XOR  = XOR Rd, Rd, Rs2
                           2: cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_OR,   1'b1, 32'd0        };    // C.OR   = OR  Rd, Rd, Rs2
                           3: cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_AND,  1'b1, 32'd0        };    // C.AND  = AND Rd, Rd, Rs2
                           endcase
                        end
                     endcase
                  end

                  // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
                  //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
                  5: // Quadrant 1:5
                  begin
                     Rd_addr = 0;            // Rd = x0 which wont get updated
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_JAL,  1'b1, c_j_imm      };    // C.J = JAL X0, offset[11:1] PC = PC + sext(imm), R[rd] = PC + 2;
                  end

                  6: // Quadrant 1:6
                  begin
                     Rs2_addr = 0;  // br_fu.sv needs Rs1_data and Rs2_data to do compare
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_C,    1'b1, c_b_imm      };    // C.BEQZ = beq Rs1, X0, offset[8:1]
                  end

                  7: // Quadrant 1:7
                  begin
                     Rs2_addr = 0;  // br_fu.sv needs Rs1_data and Rs2_data to do compare
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_C,   1'b1, c_b_imm      };    // C.BNEZ = bne Rs1, X0, offset[8:1]
                  end
               endcase
            end

            2: // Quadrant 2  see p. 111
            begin
               Rd_addr  = i[11:7];
               Rs1_addr = i[11:7];
               Rs2_addr = i[6:2];
               // number of bits               1      1      1     1      1      1      4           2       2       4       1     32
               //                              Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case(funct3)
                  0: // Quadrant 2:0
                  begin
                     if (!c_shamt[5])        // "For RV32C, shamt[5] must be zero;" see p 105
                     begin
                        if (c_shamt[4:0] != 0)  // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                        begin
                           if (Rd_addr != 0) // "For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C." p. 105
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SLL,  1'b1, c_shamt      };    // C.SLLI = SLLI Rd, Rd, shamt[5:0] p. 105
                           `ifdef H_C_SLLI
                           else
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SLLI  };    // HINT
                           `endif
                        end
                        `ifdef H_C_SLLI2
                        else
                           cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_SLLI2 };    // HINT - "the code points with shamt=0 are HINTs" p 105
                        `endif
                     end
                     // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105
                  end

                  `ifdef ext_D
                  1: // Quadrant 2:1
                     // C.FLDSP   16'b001_?_?????_?????_10  (RV32/64)
                     // Rs1_addr = 2;           // SP is X2
                  `endif

                  2: // Quadrant 2:2
                  if (Rd_addr != 0)          // C.LWSP is only valid when rd̸=x0; p.99
                  begin
                     Rs1_addr = 2;           // SP is X2
                     cntrl_sigs  =           '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b1, c_lwsp_imm   };    // C.LWSP
                  end
               // else                       // " the code points with rd=x0 are reserved." p.99

                  `ifdef ext_F
                  3: // Quadrant 2:3
                  begin
                     Rs1_addr = 2;           // Rs1 = x2
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_IMM, F_LW,   1'b1, c_swsp_imm   };    // C.FLWSP - flw rd, offset[7:2](x2).
                  end
                  `endif

                  4: // Quadrant 2:4
                  begin
                     if (!i[12])
                     begin
                        if (Rs2_addr == 0)         // Rs2 == X0?
                        begin
                           if (Rs1_addr != 0)      // C.JR is only valid when rs1̸=x0; see p. 106 riscv_spec.pdf
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b0,  BR_INSTR,   BS_RS1, BS_IMM, B_JALR, 1'b1, 32'd0        };    // C.JR - jalr x0, 0(rs1), PC = R[rs1]
                        // else                    // the code point with rs1=x0 is reserved
                        end
                        else                       // Rs2 != X0
                        begin                      // C.MV is only valid when rs2̸=x0; the code points with rs2=x0 correspond to the C.JR instruction
                           if (Rd_addr != 0)
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_IMM, AM_RS2, A_ADD,  1'b1, 32'd0        };    // C.MV = ADD Rd, R0, Rs2
                           `ifdef H_C_MV
                           else                    //  The code points with rs2̸=x0 and rd=x0 are HINTs.
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_MV    };    // HINT
                           `endif
                        end
                     end
                     else // i[12] == 1'b1
                     // C.ADD is only valid when rs2̸=x0; the code points with rs2=x0 correspond
                     // to the C.JALR and C.EBREAK instructions. The code points with rs2̸=x0 and rd=x0 are HINTs.
                     begin
                        case ({(Rs1_addr != 0),(Rs2_addr != 0)})
                           2'b00:      // Rs1_addr = 0, Rs2_addr = 0   NOTE: Rd_addr = Rs1_addr = 0
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   EBREAK, 1'b1, 32'd0        };    // C.EBREAK

                           `ifdef H_C_ADD
                           2'b01:      // Rs1_addr = 0, Rs2_addr != 0   NOTE: "The code points with rs2̸=x0 and rd=x0 are HINTs." p 106
                              cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b1, HINT_C_ADD   };    // HINT - see p 111
                           `endif

                           2'b10:      // Rs1_addr != 0, Rs2_addr == 0
                           begin
                              Rd_addr  = 1;                                                                                      // PC = R[rs1], R[rd] = PC + 2 where Rd = 1
                              cntrl_sigs  =  '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  BR_INSTR,   BS_RS1, BS_IMM, B_JALR, 1'b1, 32'd0        };    // C.JALR = JALR R1, Rs1, 0
                           end

                           2'b11:      // Rs1_addr != 0, Rs2_addr != 0
                              cntrl_sigs  =  '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_ADD,  1'b1, 32'd0        };    // C.ADD = ADD Rd, Rd, Rs2  p. 106
                        endcase
                     end
                  end

                  `ifdef ext_D
                  5: // Quadrant 2:5
                     //  Rs1_addr = 2;    // Rs1 = x2
                     //  cntrl_sigs =   // C.FSDSP 16'b101__??????_?????_10     (RV32/64)
                  `endif

                  6: // Quadrant 2:6
                  begin
                     Rs1_addr = 2;        // Rs1 = x2
                     cntrl_sigs  =           '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  ST_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b1, c_swsp_imm   };    // C.SWSP = sw rs2, offset[7:2](x2)
                  end

                  `ifdef ext_F
                  7: // Quadrant 2:7
                  begin
                     Rs1_addr = 2;        // Rs1 = x2
                     cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  SPFP_INSTR, FM_RS1, FM_IMM, F_SW, 1'b1, c_swsp_imm     };    // C.FSWSP - flw rd, offset[7:2](x2).
                  end
                  `endif
               endcase
            end
         endcase
         `endif // ext_C
      end
      // --------------------------------------------------------------------------------------------------------------------------------------------------------------------
      else if (i[4:2] != 3'b111)    // 32 bit RV32I instruction?
      begin
         // RV32I instruction decode. See riscv-spec.pdf

         // undecoded instructions = illegal instructions  (must inlude 32'hFFFF_FFFF)
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         cntrl_sigs =               '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  ILL_INSTR,  AM_IMM, AM_IMM, A_ADD,  1'b0, 32'd0    };

         // ************************************************************************** Load instructins
         if (i[6:2] == 5'b00000)
         begin
            case(funct3)
               // number of bits      1      1      1     1      1      1      4           2       2       4       1     32
               //                     Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               0: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };        // LB       32'b???????_?????_?????_000_?????_0000011
               1: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };        // LH       32'b???????_?????_?????_001_?????_0000011
               2: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };        // LW       32'b???????_?????_?????_010_?????_0000011
               4: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };        // LBU      32'b???????_?????_?????_100_?????_0000011
               5: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  LD_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };        // LHU      32'b???????_?????_?????_101_?????_0000011
            endcase
         end

         `ifdef ext_ZiF
         // ************************************************************************** FENCE type ins tructions
         if (i[6:2] == 5'b00011)
         begin
            // NOTE: pred=0 or succ=0 - reserved for future standard use

            // number of bits         1      1      1     1      1      1      4           2       2       4       1     32
            //                        Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
            case (funct3)
               0: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   FENCE,  1'b0, 32'd0    };        // FENCE    32'b???????_?????_?????_000_?????_0001111
               1: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   FENCEI, 1'b0, 32'd0    };        // FENCE_I  32'b???????_?????_?????_001_?????_0001111
            endcase
         end
         `endif

         // ************************************************************************** Integer Register-Immediate type instructions
         // The HINT encodings shown below have been chosen so that simple implementations can ignore HINTs altogether,
         // and instead execute a HINT as a regular computational instruction that happens not to
         // mutate the architectural state. For example, ADD is a HINT if the destination register is x0; the
         // five-bit rs1 and rs2 fields encode arguments to the HINT. However, a simple implementation can
         // simply execute the HINT as an ADD of rs1 and rs2 that writes x0, which has no architecturally
         // visible effect. see p. 29 riscv-spec.pdf

         if (i[6:2] == 5'b00100)
         begin
            case(funct3)
               // number of bits      1      1      1     1      1      1      4           2       2       4       1     32
               //                     Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               0:
               `ifdef H_ADDI
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_ADDI};         // ADDI  HINT
               else
               `endif // NOP - addi x0, x0, 0 - if ((Rs1_addr == 0) & (i_imm == 0))
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_ADD,  1'b0, i_imm    };         // ADDI     32'b???????_?????_?????_000_?????_0010011
               1:
               if (i[31:25] == 7'b0000000)
               begin
                  `ifdef H_SLLI
                  if (Rd_addr == 0)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_SLLI};         // SLLI  HINT
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SLL,  1'b0, shamt    };         // SLLI     32'b0000000_?????_?????_001_?????_0010011
               end
               2:
               `ifdef H_SLTI
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_SLTI};         // SLTI  HINT
               else
               `endif
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SLT,  1'b0, i_imm    };         // SLTI     32'b???????_?????_?????_010_?????_0010011
               3:
               `ifdef H_SLTIU
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_SLTIU};        // SLTIU  HINT
               else
               `endif
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SLTU, 1'b0, i_imm    };         // SLTIU    32'b???????_?????_?????_011_?????_0010011
               4:
               `ifdef H_XORI
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_XORI};         // XORI  HINT
               else
               `endif
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_XOR,  1'b0, i_imm    };         // XORI     32'b???????_?????_?????_100_?????_0010011
               5:
               if (i[31:25] == 7'b0000000)
               begin
                  `ifdef H_SRLI
                  if (Rd_addr == 0)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_SRLI};         // SRLI  HINT
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SRL,  1'b0, shamt    };         // SRLI     32'b0000000_?????_?????_101_?????_0010011
               end
               else if (i[31:25] == 7'b0100000)
               begin
                  `ifdef H_SRAI
                  if (Rd_addr == 0)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_SRAI};         // SRAI  HINT
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_SRA , 1'b0, shamt    };         // SRAI     32'b0100000_?????_?????_101_?????_0010011
               end
               6:
               `ifdef H_ORI
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_ORI };         // ORI  HINT
               else
               `endif
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_OR,   1'b0, i_imm    };         // ORI      32'b???????_?????_?????_110_?????_0010011
               7:
               `ifdef H_ANDI
               if (Rd_addr == 0)
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_ANDI};         // ANDI  HINT
               else
               `endif
                  cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  ALU_INSTR,  AM_RS1, AM_IMM, A_AND,  1'b0, i_imm    };         // ANDI     32'b???????_?????_?????_111_?????_0010011
            endcase
         end

         // ************************************************************************** AUIPC instruction
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         if (i[6:2] == 5'b00101)
         begin
            `ifdef H_AUIPC
            if (Rd_addr == 0)
               cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_AUIPC};        // AUIPC  HINT
            else
            `endif
               cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  ALU_INSTR,  AM_PC,  AM_IMM, A_ADD , 1'b0, u_imm    };         // AUIPC    32'b???????_?????_?????_???_?????_0010111
         end


         // ************************************************************************** Store type instructions - SB, SH, SW
         if (i[6:2] == 5'b01000)
         begin
            case(funct3)
               0: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  ST_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, s_imm    };         // SB       32'b???????_?????_?????_000_?????_0100011
               1: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  ST_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, s_imm    };         // SH       32'b???????_?????_?????_001_?????_0100011
               2: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  ST_INSTR,   AM_RS1, AM_IMM, A_ADD,  1'b0, s_imm    };         // SW       32'b???????_?????_?????_010_?????_0100011
            endcase
         end

         // ************************************************************************** Atomic instructions - NOT  IMPLEMENTED YET !!!!!!!!!!
         `ifdef ext_A  // RV32A instructions
         if (i[6:2] == 5'b01011)
         begin
            if (funct3 == 3'b010)
            begin
               // AMOADD.W    32'b00000_?_?_?????_?????_010_?????_0101111
               // AMOSWAP.W   32'b00001_?_?_?????_?????_010_?????_0101111
               // LR.W        32'b00010_?_?_00000_?????_010_?????_0101111
               // SC.W        32'b00011_?_?_?????_?????_010_?????_0101111
               // AMOXOR.W    32'b00100_?_?_?????_?????_010_?????_0101111
               // AMOAND.W    32'b01100_?_?_?????_?????_010_?????_0101111
               // AMOOR.W     32'b01000_?_?_?????_?????_010_?????_0101111
               // AMOMIN.W    32'b10000_?_?_?????_?????_010_?????_0101111
               // AMOMAX.W    32'b10100_?_?_?????_?????_010_?????_0101111
               // AMOMINU.W   32'b11000_?_?_?????_?????_010_?????_0101111
               // AMOMAXU.W   32'b11100_?_?_?????_?????_010_?????_0101111
            end
         end
         `endif // ext_A

         // ************************************************************************** Integere Register-Register type instructions
         // This HINT encoding has been chosen so that simple implementations can ignore HINTs altogether,
         // and instead execute a HINT as a regular computational instruction that happens not to
         // mutate the architectural state. For example, ADD is a HINT if the destination register is x0; the
         // five-bit rs1 and rs2 fields encode arguments to the HINT. However, a simple implementation can
         // simply execute the HINT as an ADD of rs1 and rs2 that writes x0, which has no architecturally
         // visible effect. p. 29

         if (i[6:2] == 5'b01100)
         begin
            if (i[31:25] == 7'b0000000)
            begin
               // number of bits      1      1      1     1      1      1      4           2       2       4       1     32
               //                     Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case(funct3)
                  0:
                  `ifdef R_ADD
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_ADD  };        // ADD  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_ADD , 1'b0, 32'd0    };        // ADD      32'b0000000_?????_?????_000_?????_0110011
                  1:
                  `ifdef R_SLL
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SLL  };        // SLL  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SLL , 1'b0, 32'd0    };        // SLL      32'b0000000_?????_?????_001_?????_0110011
                  2:
                  `ifdef R_SLT
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SLT  };        // SLT  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SLT , 1'b0, 32'd0    };        // SLT      32'b0000000_?????_?????_010_?????_0110011
                  3:
                  `ifdef R_SLTU
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SLTU };        // SLTU Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SLTU, 1'b0, 32'd0    };        // SLTU     32'b0000000_?????_?????_011_?????_0110011
                  4:
                  `ifdef R_XOR
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_XOR  };        // XOR  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_XOR , 1'b0, 32'd0    };        // XOR      32'b0000000_?????_?????_100_?????_0110011
                  5:
                  `ifdef R_SRL
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SRL  };        // SRL  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SRL , 1'b0, 32'd0    };        // SRL      32'b0000000_?????_?????_101_?????_0110011
                  6:
                  `ifdef R_OR
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_OR   };        // OR   Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_OR  , 1'b0, 32'd0    };        // OR       32'b0000000_?????_?????_110_?????_0110011
                  7:
                  `ifdef R_AND
                  if (Rd_addr == 0) // see p. 30
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_AND  };        // AND  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_AND , 1'b0, 32'd0    };        // AND      32'b0000000_?????_?????_111_?????_0110011
               endcase
            end
            else if (i[31:25] == 7'b0100000)
            begin
               // number of bits      1      1      1     1      1      1      4           2       2       4       1     32
               //                     Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case(funct3)
                  0:
                  `ifdef R_SUB
                  if (Rd_addr == 0)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SUB  };        // SUB  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SUB,  1'b0, 32'd0    };        // SUB      32'b0100000_?????_?????_000_?????_0110011
                  5:
                  `ifdef R_SRA
                  if (Rd_addr == 0)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, RES_SRA  };        // SRA  Reserved
                  else
                  `endif
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  ALU_INSTR,  AM_RS1, AM_RS2, A_SRA,  1'b0, 32'd0    };        // SRA      32'b0100000_?????_?????_101_?????_0110011
               endcase
            end

            `ifdef ext_M  // RV32M instructions
            else if (i[31:25] == 7'b0000001)                                                                            // Multiply, Divide, Remainder instructions
            begin
               // number of bits      1      1      1     1      1      1      4           2       2       4       1     32
               //                     Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
               case(funct3)
               0: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IM_INSTR,   2'd0,   2'd0,   MUL,    1'b0, 32'd0    };        // MUL      32'b0000001_?????_?????_000_?????_0110011    unsigned x unsigned - return lower 32 bits
               1: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IM_INSTR,   2'd0,   2'd0,   MULH,   1'b0, 32'd0    };        // MULH     32'b0000001_?????_?????_001_?????_0110011    signed x signed   - return upper 32 bits
               2: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IM_INSTR,   2'd0,   2'd0,   MULHSU, 1'b0, 32'd0    };        // MULHSU   32'b0000001_?????_?????_010_?????_0110011    signed x unsigned - return upper 32 bits
               3: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IM_INSTR,   2'd0,   2'd0,   MULHU,  1'b0, 32'd0    };        // MULHU    32'b0000001_?????_?????_011_?????_0110011    unsigned x unsigned - return upper 32 bits
               4: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IDR_INSTR,  2'd0,   2'd0,   DIV,    1'b0, 32'd0    };        // DIV      32'b0000001_?????_?????_100_?????_0110011
               5: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IDR_INSTR,  2'd0,   2'd0,   DIVU,   1'b0, 32'd0    };        // DIVU     32'b0000001_?????_?????_101_?????_0110011
               6: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IDR_INSTR,  2'd0,   2'd0,   REM,    1'b0, 32'd0    };        // REM      32'b0000001_?????_?????_110_?????_0110011
               7: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b1,  IDR_INSTR,  2'd0,   2'd0,   REMU,   1'b0, 32'd0    };        // REMU     32'b0000001_?????_?????_111_?????_0110011
               endcase
            end
            `endif // ext_M
         end

         // ************************************************************************** LUI instruction
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         if (i[6:2] == 5'b01101)
         begin
            `ifdef H_LUI
            if (Rd_addr == 0)
               cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  HINT_INSTR, 2'd0,   2'd0,   4'd0,   1'b0, HINT_LUI };        // LUI  HINT
            else
            `endif
               cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  ALU_INSTR,  AM_IMM, AM_IMM, A_OR,   1'b0, u_imm    };        // LUI      32'b???????_?????_?????_???_?????_0110111
         end

         // ************************************************************************** Bxx type instructions
         if (i[6:2] == 5'b11000)
         begin
            // number of bits         1      1      1     1      1      1      4           2       2       4       1     32
            //                        Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
            case(funct3)
               0: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BEQ      32'b???????_?????_?????_000_?????_1100011
               1: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BNE      32'b???????_?????_?????_001_?????_1100011
               4: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BLT      32'b???????_?????_?????_100_?????_1100011
               5: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BGE      32'b???????_?????_?????_101_?????_1100011
               6: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BLTU     32'b???????_?????_?????_110_?????_1100011
               7: cntrl_sigs =      '{1'b0,  1'b0,  1'b0, 1'b1,  1'b1,  1'b0,  BR_INSTR,   BS_PC,  BS_IMM, B_ADD , 1'b0, b_imm    };        // BGEU     32'b???????_?????_?????_111_?????_1100011
            endcase
         end

         // ************************************************************************** JALR  instruction
            // number of bits         1      1      1     1      1      1      4           2       2       4       1     32
            //                        Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         if (i[6:2] == 5'b11001)                                                                                                            //  PC = ( R[rs1] + sext(imm) ) & 0xfffffffe, R[rd] = PC + 4; (PC + 2 for compressed)
         begin
            if (funct3 == 0)
               cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  BR_INSTR,   BS_RS1, BS_IMM, B_JALR, 1'b0, i_imm    };        // JALR     32'b???????_?????_?????_000_?????_1100111
         end
         // ************************************************************************** JAL instruction
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         if (i[6:2] == 5'b11011)                                                                                        //  PC = PC + sext(imm), R[rd] = PC + 4;
            cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  BR_INSTR ,  BS_PC,  BS_IMM, B_JAL,  1'b0, j_imm    };        // JAL      32'b???????_?????_?????_???_?????_1101111

         // ************************************************************************** SYS, RET, CSR instructions
         if (i[6:2] == 5'b11100)
         begin
            // number of bits         1      1      1     1      1      1      4           2       2       4       1     32
            //                        Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
            case (funct3)
            0:
            begin
               if ((i[19:15] == 5'b00000) && (i[11:7] == 5'b00000))
               begin
                  if (i[31:20] == 12'b0000000_00000)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   ECALL , 1'b0, 32'd0    };        // ECALL    32'b0000000_00000_00000_000_00000_1110011
                  if (i[31:20] == 12'b0000000_00001)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   EBREAK, 1'b0, 32'd0    };        // EBREAK   32'b0000000_00001_00000_000_00000_1110011

                  `ifdef ext_U
                  if (i[31:20] == 12'b0000000_00010)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b0,  BR_INSTR,   2'd0,   2'd0,   B_URET, 1'b0, 32'd0    };        // URET     32'b0000000_00010_00000_000_00000_1110011
                  `endif
                  `ifdef ext_S
                  if (i[31:20] == 12'b0001000_00010)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b0,  BR_INSTR,   2'd0,   2'd0,   B_SRET, 1'b0, 32'd0    };        // SRET     32'b0001000_00010_00000_000_00000_1110011
                  `endif

                  if (i[31:20] == 12'b0001000_00101)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  SYS_INSTR,  2'd0,   2'd0,   WFI   , 1'b0, 32'd0    };        // WFI      32'b0001000_00101_00000_000_00000_1110011
                  if (i[31:20] == 12'b0011000_00010)
                     cntrl_sigs =   '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b0,  BR_INSTR,   2'd0,   2'd0,   B_MRET, 1'b0, 32'd0    };        // MRET     32'b0011000_00010_00000_000_00000_1110011
               end
            end
            1: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRW    32'b???????_?????_?????_001_?????_1110011
            2: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRS    32'b???????_?????_?????_010_?????_1110011
            3: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b1,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRC    32'b???????_?????_?????_011_?????_1110011
         // 4:
            5: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRWI   32'b???????_?????_?????_101_?????_1110011
            6: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRSI   32'b???????_?????_?????_110_?????_1110011
            7: cntrl_sigs =         '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  CSR_INSTR,  2'd0,   2'd0,   3'd0,   1'b0, csrx     };        // CSRRCI   32'b???????_?????_?????_111_?????_1110011
            endcase
         end

         // ************************************************************************** Floating Point instructions
         `ifdef ext_F // RV32F instructions
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
         if ((i[6:2] == 5'b00001) && (funct3 == 3'b010))
            cntrl_sigs =            '{1'b0,  1'b0,  1'b1, 1'b1,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_IMM, F_LW,   1'b0, i_imm    };        // FLW         32'b????????????__?????_010_?????_0000111
         if ((i[6:2] == 5'b01001) && (funct3 == 3'b010))
            cntrl_sigs =            '{1'b0,  1'b1,  1'b0, 1'b1,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_IMM, F_SW,   1'b0, s_imm    };        // FSW         32'b???????_?????_?????_010_?????_0100111
         if ((i[6:2] == 5'b10000) && (i[26:25] == 2'b00))
            cntrl_sigs =            '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MADD, 1'b0, rs3_rm   };        // FMADD.S     32'b?????00_?????_?????_???_?????_1000011
         if ((i[6:2] == 5'b10001) && (i[26:25] == 2'b00))
            cntrl_sigs =            '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MSUB, 1'b0, rs3_rm   };        // FMSUB.S     32'b?????00_?????_?????_???_?????_1000111
         if ((i[6:2] == 5'b10010) && (i[26:25] == 2'b00))
            cntrl_sigs =            '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_NMSUB,1'b0, rs3_rm   };        // FNMSUB.S    32'b?????00_?????_?????_???_?????_1001011
         if ((i[6:2] == 5'b10011) && (i[26:25] == 2'b00))
            cntrl_sigs =            '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_NMADD,1'b0, rs3_rm   };        // FNMADD.S    32'b?????00_?????_?????_???_?????_1001111
         if (i[6:2] == 5'b10100)
         begin
            if (i[31:25] == 7'b0000000)
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_ADD,  1'b0, rs3_rm   };        // FADD.S      32'b0000000_?????_?????_???_?????_1010011
            if (i[31:25] == 7'b0000100)
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_SUB,  1'b0, rs3_rm   };        // FSUB.S      32'b0000100_?????_?????_???_?????_1010011
            if (i[31:25] == 7'b0001000)
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MUL,  1'b0, rs3_rm   };        // FMUL.S      32'b0001000_?????_?????_???_?????_1010011
            if (i[31:25] == 7'b0001100)
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_DIV,  1'b0, rs3_rm   };        // FDIV.S      32'b0001100_?????_?????_???_?????_1010011
            if ((i[31:25] == 7'b0101100) && (Rs2_addr == 0))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_IMM, F_SQRT, 1'b0, rs3_rm   };        // FSQRT.S     32'b0101100_00000_?????_???_?????_1010011
            if ((i[31:25] == 7'b0010000) && (funct3 == 3'b000))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_SGNJ, 1'b0, 32'd0    };        // FSGNJ.S     32'b0010000_?????_?????_000_?????_1010011
            if ((i[31:25] == 7'b0010000) && (funct3 == 3'b001))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_SGNJN,1'b0, 32'd0    };        // FSGNJN.S    32'b0010000_?????_?????_001_?????_1010011
            if ((i[31:25] == 7'b0010000) && (funct3 == 3'b010))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_SGNJX,1'b0, 32'd0    };        // FSGNJX.S    32'b0010000_?????_?????_010_?????_1010011
            if ((i[31:25] == 7'b0010100) && (funct3 == 3'b000))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MIN,  1'b0, 32'd0    };        // FMIN.S      32'b0010100_?????_?????_000_?????_1010011
            if ((i[31:25] == 7'b0010100) && (funct3 == 3'b001))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b1, 1'b0,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MAX,  1'b0, 32'd0    };        // FMAX.S      32'b0010100_?????_?????_001_?????_1010011
            if ((i[31:25] == 7'b1100000) && (Rs2_addr == 0))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_CVTW, 1'b0, rs3_rm   };        // FCVT.W.S    32'b1100000_00000_?????_???_?????_1010011
            if ((i[31:25] == 7'b1100000) && (Rs2_addr == 1))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_CVTWU,1'b0, rs3_rm   };        // FCVT.WU.S   32'b1100000_00001_?????_???_?????_1010011
            if ((i[31:25] == 7'b1110000) && (Rs2_addr == 0) && (funct3 == 3'b000))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_MVXW, 1'b0, 32'd0    };        // FMV.X.W     32'b1110000_00000_?????_000_?????_1010011
            if ((i[31:25] == 7'b1010000) && (funct3 == 3'b010))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_EQ,   1'b0, 32'd0    };        // FEQ.S       32'b1010000_?????_?????_010_?????_1010011
            if ((i[31:25] == 7'b1010000) && (funct3 == 3'b001))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_LT,   1'b0, 32'd0    };        // FLT.S       32'b1010000_?????_?????_001_?????_1010011
            if ((i[31:25] == 7'b1010000) && (funct3 == 3'b000))
               cntrl_sigs =         '{1'b1,  1'b1,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_LE,   1'b0, 32'd0    };        // FLE.S       32'b1010000_?????_?????_000_?????_1010011
            if ((i[31:25] == 7'b1110000) && (Rs2_addr == 0) && (funct3 == 3'b001))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b0, 1'b0,  1'b0,  1'b1,  SPFP_INSTR, FM_RS1, FM_RS2, F_CLASS,1'b0, 32'd0    };        // FCLASS.S    32'b1110000_00000_?????_001_?????_1010011
            if ((i[31:25] == 7'b1101000) && (Rs2_addr == 0))
               cntrl_sigs =         '{1'b0,  1'b0,  1'b1, 1'b1,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_CVSW, 1'b0, rs3_rm   };        // FCVT.S.W    32'b1101000_00000_?????_???_?????_1010011
            if ((i[31:25] == 7'b1101000) && (Rs2_addr == 1))
               cntrl_sigs =         '{1'b1,  1'b0,  1'b1, 1'b1,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_CVSWU,1'b0, rs3_rm   };        // FCVT.S.WU   32'b1101000_00001_?????_???_?????_1010011
            if ((i[31:25] == 7'b1111000) && (Rs2_addr == 0) && (funct3 == 3'b000))
               cntrl_sigs =         '{1'b0,  1'b0,  1'b1, 1'b1,  1'b0,  1'b0,  SPFP_INSTR, FM_RS1, FM_RS2, F_MVWX, 1'b0, 32'd0    };        // FMV.W.X     32'b1111000_00000_?????_000_?????_1010011
         end
         `endif // ext_F
      end
      // --------------------------------------------------------------------------------------------------------------------------------------------------------------------
      else // 48, 64, etc... instruction  ILLEGAL for this CPU
      begin
         // number of bits            1      1      1     1      1      1      4           2       2       4       1     32
         //                           Fs1_rd Fs2_rd Fd_wr Rs1_rd Rs2_rd Rd_wr  ig_type     sel_x   sel_y   op      ci    imm
            cntrl_sigs =            '{1'b0,  1'b0,  1'b0, 1'b0,  1'b0,  1'b0,  ILL_INSTR,  AM_IMM, AM_IMM, A_ADD,  1'b0, 32'd0    };
      end
   end

endmodule
