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
// ---------------------------------------------------------------------------------
// Project     :
// Editor      :  Notepad++ on Windows 7
// FPGA        :
// File        :  disasm_RV.sv
// Description :  Code to disassemble RV32IM 32bit instructions.
//                For use in ModelSim simulations.
// Designer    :  Kirk Weedman - kirk@hdlexpress.com
// Note        :  Uses "string" variables - must be compiled with System Verilog
// ---------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module disasm
(
   input  logic            dm,      // decode mode: ASSEMBLY, SEMANTICS
   input  var IP_Data      ipd,
   output string           i_str,
   output string           pc_str
);

//   import instr_pkg::*;

   string                  decode_type;
   string                  tmp_str;       // temporary use string
   string                  Rs1_str;
   string                  Rs2_str;
   string                  Rd_str;

   // RISC_V Decode Logic
   logic     [XLEN-1:0] i;
   logic    [PC_SZ-1:0] pc;

   logic      [RSZ-1:0] s_imm;
   logic      [RSZ-1:0] i_imm;
   logic      [RSZ-1:0] b_imm;
   logic      [RSZ-1:0] u_imm;
   logic      [RSZ-1:0] j_imm;
   logic      [RSZ-1:0] shamt;
   logic      [RSZ-1:0] csr;
   logic      [RSZ-1:0] nzuimm9_2;
   logic      [RSZ-1:0] offset7_2;
   logic      [RSZ-1:0] offset7_2_css;
   logic      [RSZ-1:0] offset8_1;
   logic      [RSZ-1:0] offset6_2;
   logic      [RSZ-1:0] nzimm5_0;
   logic      [RSZ-1:0] imm5_0;
   logic      [RSZ-1:0] imm11_1;
   logic      [RSZ-1:0] nzimm9_4;
   logic      [RSZ-1:0] nzuimm17_12;
   logic      [RSZ-1:0] shamt5_0;
   ROM_Data             cntrl_sigs;

   logic        [GPR_ASZ-1:0] Rs1;
   logic        [GPR_ASZ-1:0] Rs2;
   logic        [GPR_ASZ-1:0] Rd;
   logic                [2:0] funct3;
   logic            [RSZ-1:0] imm;
   logic signed     [RSZ-1:0] simm;

   assign   i  = ipd.instruction;
   assign   pc = ipd.pc;

   task RegNum;
   input [GPR_ASZ-1:0] m;
   inout string str;
   begin
      $sformat(str,"x%0d",m); // can replace this with the case statement code below
//      case (m) // Table 18.2: RISC-V calling convention register usage.
//          0: $sformat(str,"zero");
//          1: $sformat(str,"ra");
//          2: $sformat(str,"sp");
//          3: $sformat(str,"gp");
//          4: $sformat(str,"tp");
//          5: $sformat(str,"t0");
//          6: $sformat(str,"t1");
//          7: $sformat(str,"t2");
//          8: $sformat(str,"fp");
//          9: $sformat(str,"s1");
//         10: $sformat(str,"a0");
//         11: $sformat(str,"a1");
//         12: $sformat(str,"a2");
//         13: $sformat(str,"a3");
//         14: $sformat(str,"a4");
//         15: $sformat(str,"a5");
//         16: $sformat(str,"a6");
//         17: $sformat(str,"a7");
//         18: $sformat(str,"s2");
//         19: $sformat(str,"s3");
//         20: $sformat(str,"s4");
//         21: $sformat(str,"s5");
//         22: $sformat(str,"s6");
//         23: $sformat(str,"s7");
//         24: $sformat(str,"s8");
//         25: $sformat(str,"s9");
//         26: $sformat(str,"s10");
//         27: $sformat(str,"s11");
//         28: $sformat(str,"t3");
//         29: $sformat(str,"t4");
//         30: $sformat(str,"t5");
//         31: $sformat(str,"t6");
//      endcase
   end
   endtask

   task ld_form;   // LB/LH/LW/LBU/LHU
   input logic             [2:0] funct3;
   input string                  Rd_str;
   input string                  Rs1_str;
   input logic signed  [RSZ-1:0] i_imm;
   inout string                  i_str;
   begin
      string   tmp_str;

      tmp_str = "LD?";
      case (funct3)
         0: tmp_str = "lb";
         1: tmp_str = "lh";
         2: tmp_str = "lw";
         // 3: tmp_str = "ld"; // RV64I
         4: tmp_str = "lbu";
         5: tmp_str = "lhu";
      endcase
      if (dm == ASSEMBLY)
         $sformat(i_str,"%s %s, %0d(%s)", tmp_str, Rd_str, i_imm, Rs1_str);       // Assembly  : lw rd, imm(rs1)
      else
         $sformat(i_str,"%s = %0d(%s) :%s",Rd_str, i_imm, Rs1_str, tmp_str);      // Semantics : R[rd] = i_imm(R[rs1])
   end
   endtask

   task st_form;   // SB/SH/SW
   input logic             [2:0] funct3;
   input string                  Rs1_str;
   input string                  Rs2_str;
   input logic signed  [RSZ-1:0] s_imm;
   inout string                  i_str;
   begin
      string   tmp_str;

      tmp_str = "SD?";
      case (funct3)
         0:tmp_str = "sb";   // SB
         1:tmp_str = "sh";   // SH
         2:tmp_str = "sw";   // SW
         // 3:tmp_str = "sd";   // RV64I
      endcase
      if (dm == ASSEMBLY)
         $sformat(i_str,"%s %s, %0d(%s)", tmp_str, Rs2_str, s_imm, Rs1_str);     // Assembly  : sw rs2, imm(rs1)
      else
         $sformat(i_str,"%0d(%s) = %s :%s", s_imm, Rs1_str, Rs2_str, tmp_str);   // Semantics : s_imm(R[rs1]) = R[rs2]
   end
   endtask

   task bxx_form;
   input logic signed  [RSZ-1:0] b_imm;
   input logic         [RSZ-1:0] Rs1;
   input string                  Rs1_str;
   input logic         [RSZ-1:0] Rs2;
   input string                  Rs2_str;
   input               [RSZ-1:0] pc;
   input logic             [2:0] funct3;
   inout string                  i_str;
   begin
      logic             flg1;
      logic             flg2;
      logic       [1:0] p;
      string            tmp_str;

      flg1 = 1'b0;
      if (Rs1 == 1'd0)
         flg1 = 1'b1;
      flg2 = 1'b0;
      if (Rs2 == 1'd0)
         flg2 = 1'b1;

      p = 1'd0; // default
      tmp_str = "???";
      case ({flg1,flg2,funct3})
         {1'b0,1'b0,3'd0}: tmp_str = "beq";
         {1'b0,1'b1,3'd0}: begin p = 1'd1; tmp_str = "beqz"; end  // Rs2 == 0
         {1'b1,1'b0,3'd0}: tmp_str = "beq";                       // Rs1 == 0
         {1'b1,1'b1,3'd0}: tmp_str = "beq";

         {1'b0,1'b0,3'd1}: tmp_str = "bne";
         {1'b0,1'b1,3'd1}: begin p = 1'd1; tmp_str = "bnez"; end  // Rs2 == 0
         {1'b1,1'b0,3'd1}: tmp_str = "bne";                       // Rs1 == 0
         {1'b1,1'b1,3'd1}: tmp_str = "bne";

         {1'b0,1'b0,3'd4}: tmp_str = "blt";
         {1'b0,1'b1,3'd4}: begin p = 1'd1; tmp_str = "bltz"; end  // Rs2 == 0
         {1'b1,1'b0,3'd4}: begin p = 2'd2; tmp_str = "bgtz"; end  // Rs1 == 0
         {1'b1,1'b1,3'd4}: tmp_str = "blt";

         {1'b0,1'b0,3'd5}: tmp_str = "bge";
         {1'b0,1'b1,3'd5}: begin p = 1'd1; tmp_str = "bgez"; end  // Rs2 == 0
         {1'b1,1'b0,3'd5}: begin p = 2'd2; tmp_str = "blez"; end  // Rs1 == 0
         {1'b1,1'b1,3'd5}: tmp_str = "bge";

         {1'b0,1'b0,3'd6}: tmp_str = "bltu";
         {1'b0,1'b1,3'd6}: tmp_str = "bltu"; // Rs2 == 0  //!!! FINISH THESE
         {1'b1,1'b0,3'd6}: tmp_str = "bltu"; // Rs1 == 0
         {1'b1,1'b1,3'd6}: tmp_str = "bltu";

         {1'b0,1'b0,3'd7}: tmp_str = "bgeu";
         {1'b0,1'b1,3'd7}: tmp_str = "bgeu"; // Rs2 == 0  //!!! FINISH THESE
         {1'b1,1'b0,3'd7}: tmp_str = "bgeu"; // Rs1 == 0
         {1'b1,1'b1,3'd7}: tmp_str = "bgeu";
      endcase

      if (dm == ASSEMBLY)
      begin
         case (p)
            0: $sformat(i_str,"%s %s, %s, %0d",tmp_str, Rs1_str, Rs2_str, b_imm); // Assembly  : beq rs1, rs2, imm
            1: $sformat(i_str,"%s %s, %0d",tmp_str, Rs1_str, b_imm);              // Assembly  : beqz rs1, imm
            2: $sformat(i_str,"%s %s, %0d",tmp_str, Rs2_str, b_imm);              // Assembly  : blez rs2, imm
         endcase
      end
      else
      begin
         case(funct3)
            0: $sformat(i_str,"pc = (%s == %s)  ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] ==  R[rs2] ) ? PC + sext(imm) : PC + 4
            1: $sformat(i_str,"pc = (%s != %s)  ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] !=  R[rs2] ) ? PC + sext(imm) : PC + 4
            4: $sformat(i_str,"pc = (%s < %s)   ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1]  <  R[rs2] ) ? PC + sext(imm) : PC + 4
            5: $sformat(i_str,"pc = (%s >= %s)  ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] >=  R[rs2] ) ? PC + sext(imm) : PC + 4
            6: $sformat(i_str,"pc = (%s <=u %s) ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] <=u R[rs2] ) ? PC + sext(imm) : PC + 4
            7: $sformat(i_str,"pc = (%s >=u %s) ? 0x%0x : 0x%0x", Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] >=u R[rs2] ) ? PC + sext(imm) : PC + 4
// Use the following if you want to see the branch type i.e. tmp_str
//          0: $sformat(i_str,"%s: pc = (%s == %s)  ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] ==  R[rs2] ) ? PC + sext(imm) : PC + 4
//          1: $sformat(i_str,"%s: pc = (%s != %s)  ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] !=  R[rs2] ) ? PC + sext(imm) : PC + 4
//          4: $sformat(i_str,"%s: pc = (%s < %s)   ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1]  <  R[rs2] ) ? PC + sext(imm) : PC + 4
//          5: $sformat(i_str,"%s: pc = (%s >= %s)  ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] >=  R[rs2] ) ? PC + sext(imm) : PC + 4
//          6: $sformat(i_str,"%s: pc = (%s <=u %s) ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] <=u R[rs2] ) ? PC + sext(imm) : PC + 4
//          7: $sformat(i_str,"%s: pc = (%s >=u %s) ? 0x%0x : 0x%0x", tmp_str, Rs1_str, Rs2_str, pc+b_imm, pc+4); // Semantics : PC = ( R[rs1] >=u R[rs2] ) ? PC + sext(imm) : PC + 4
            default: $sformat(i_str,"Invalid branch instruction!!!");
         endcase
      end
   end
   endtask


   always_comb
   begin
      decode_type    = "";
      i_str          = "";
      tmp_str        = "";
      Rs1_str        = "";
      Rs2_str        = "";
      Rd_str         = "";

      Rd             = i[11:7];
      Rs1            = i[19:15];
      Rs2            = i[24:20];    //RV32I defaults
      funct3         = i[14:12];

      i_imm          = {{21{i[31]}},i[30:20]};
      s_imm          = {{21{i[31]}},i[30:25],i[11:7]};
      b_imm          = {{20{i[31]}},i[7],i[30:25],i[11:8],1'b0};
      u_imm          = {i[31:12],12'd0};
      j_imm          = {{12{i[31]}},i[19:12],i[20],i[30:21],1'b0};
      shamt          = {27'd0,i[24:20]};
      csr            = {20'd0,i[31:20]};
      imm            = 0;
      simm           = 0;

      `ifdef ext_C
         nzuimm9_2         = {24'b0,i[10:7],i[12:11],i[5],i[6],2'b0};         // see C.ADDI4SPN
         // nzuimm9_2                  9:6     5:4     3    2

         offset8_1         = {{25{i[12]}},i[6:5],i[2],i[11:10],i[4:3],1'b0};
         // offset8_1                8      7:6    5     4:3     2:1

         offset7_2         = {24'b0,i[3:2],i[12],i[6:4],2'b00};               // See C.LWSP
         // offset7_2                 7:6     5    4:2

         offset7_2_css     = {24'b0,i[8:7],i[12:9],2'b00};                    // See C.SWSP
         // offset7_2_css             7:6     5:2

         offset6_2         = {25'b0,i[5],i[12:10],i[6],2'b0};                 // see C.LW
         // offset6_2                 6    5:3      2

         nzimm5_0          = {{27{i[12]}},i[6:2]};                            // see C.ADDI
         imm5_0            = {{27{i[12]}},i[6:2]};                            // see C.LI

         shamt5_0          = {26'b0,i[12],i[6:2]};                            // see C.SRLI

         imm11_1           = {{21{i[12]}},i[8],i[10:9],i[6],i[7],i[2],i[11],i[5:3],1'b0};  // see C.JAL
         // imm11_1                 11     10    9  8    7    6    5    4     3:1

         nzimm9_4          = {{23{i[12]}},i[4:3],i[5],i[2],i[6],4'b0};        // See C.ADDI16SP
         // nzimm9_4                9       8:7    6    5    4

         nzuimm17_12       = {{15{i[12]}},i[6:2],12'b0};                      // see C.LUI
         // nzuimm17_12             17     16:12
      `endif

      if ((i[1:0] != 2'b11))
      begin
         $sformat(pc_str,"0x%0x", pc);
         $sformat(i_str,"C.Illegal: 0x%0x",i);                                                                 // default if nothing gets decoded below

         `ifdef ext_C
         // Register values come from different instruction bits for Compressed
         funct3   = i[15:13];

         case (i[1:0])
            0: // -------------------------------- Quadrant 0  see p 82 --------------------------------
            begin
               Rd  = {2'b01,i[4:2]}; // defaults for Compressed ISA instructions
               Rs1 = {2'b01,i[9:7]};
               Rs2 = {2'b01,i[4:2]};
               RegNum(Rs1,Rs1_str);
               RegNum(Rs2,Rs2_str);
               RegNum(Rd,Rd_str);

               case (i[15:13])
                  0:                                                                                           // C.ADDI4SPN   16'b000___????????_???_00
                  begin                                                                                        // ADDI Rd, R2, nzuimm[9:2]  p. 105
                     Rs1 = 2;                                                                                  // Rd = R2 + nzuimm
                     RegNum(Rs1,Rs1_str);
                     if (nzuimm9_2 != 0)
                     begin
                        if (dm == ASSEMBLY)
                           $sformat(i_str,"c.addi4spn %s, 0x%0x",Rd_str,nzuimm9_2);                            // Assembly  : addi4spn rd, imm
                        else // equation type format
                           $sformat(i_str,"c.addi4spn: %s = 0x%0x",Rd_str,nzuimm9_2);                          // Semantics : c.addi4spn: R[Rd] = R2 + nzuimm[9:2]
                     end
                  end

                  `ifdef ext_D
                  1:                                                                                           // C.FLD  16'b001_???_???_??_???_00     (RV32/64)
                  begin // fld rd, offset[7:3](rs10).
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.fld %s, %0d(%s)", Rd_str, offset7_3, Rs1_str);                       // Assembly  : c.fld rd, imm(rs1)
                     else
                        $sformat(i_str,"c.fld: %s = %0d(%s)",Rd_str, offset7_3, Rs1_str);                      // Semantics : c.fld: R[Rd] = simm(R[Rs1])
                  end
                  `endif

                  2:                                                                                           // C.LW         16'b010_???_???_??_???_00
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.lw %s, %0d(%s)", Rd_str, offset6_2, Rs1_str);                        // Assembly  : c.lw rd, imm(rs1)
                     else
                        $sformat(i_str,"c.lw: %s = %0d(%s)",Rd_str, offset6_2, Rs1_str);                       // Semantics : c.lw: R[Rd] = imm(R[Rs1])
                  end

                  `ifdef ext_F
                  3:                                                                                           // C_FLW        16'b011_???_???_??_???_00
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.flw %s, %0d(%s)", Rd_str, offset6_2, Rs1_str);                       // Assembly  : c.flw rd, imm(rs1)
                     else
                        $sformat(i_str,"c.flw: %s = %0d(%s)",Rd_str, offset6_2, Rs1_str);                      // Semantics : c.flw: R[Rd] = imm(R[Rs1])
                  end
                  `endif

                  `ifdef ext_D
                  5:                                                                                           // C.FSD  16'b101_???_???_??_???_00     (RV32/64)
                  begin //  fsd rs2, offset[7:3](rs1)
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.fsd %s, %0d(%s)", Rs2_str, offset7_3, Rs1_str);                      // Assembly  : c.fsd rs2, imm(rs1)
                     else
                        $sformat(i_str,"c.fsd: %0d(%s) = %s", offset7_3, Rs1_str, Rs2_str);                    // Semantics : c.fsd: imm(R[Rs1]) = R[Rs2]
                  end
                  `endif
                  6:                                                                                           // C.SW         16'b110_???_???_??_???_00
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.sw %s, %0d(%s)", Rs2_str, offset6_2, Rs1_str);                       // Assembly  : c.sw rs2, imm(rs1)
                     else
                        $sformat(i_str,"c.sw: %0d(%s) = %s", offset6_2, Rs1_str, Rs2_str);                     // Semantics : c.sw: imm(R[Rs1]) = R[Rs2]
                  end

                  `ifdef ext_F
                  7:                                                                                           // C.FSW        16'b111_???_???_??_???_00
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.fsw %s, %0d(%s)", Rs2_str, offset6_2, Rs1_str);                      // Assembly  : c.fsw rs2, imm(rs1)
                     else
                        $sformat(i_str,"c.fsw: %0d(%s) = %s", offset6_2, Rs1_str, Rs2_str);                    // Semantics : c.fsw: imm(R[Rs1]) = R[Rs2]
                  end
                  `endif
               endcase
            end

            1: // -------------------------------- Quadrant 1  see p. 82 --------------------------------
            begin
               Rd    = (i[15:13] < 4) ? i[11:7] : {2'b01,i[9:7]};
               Rs1   = (i[15:13] < 4) ? i[11:7] : {2'b01,i[9:7]};
               Rs2   = {2'b01,i[4:2]};
               RegNum(Rd,Rd_str);
               RegNum(Rs1,Rs1_str);
               RegNum(Rs2,Rs2_str);
               case (i[15:13])
                  0: // Quadrant 1:0
                  begin
                     if (Rd == 0)                                                                              // C.NOP       16'b000_0__00000__00000_01
                     begin
                        if (nzimm5_0 == 0)
                           $sformat(i_str,"c.nop");                                                            // Assembly  : c.nop
                        else
                           $sformat(i_str,"hint_c.nop");                                                       // Assembly  : hint_c.nop
                     end
                     else // (Rd != 0)                                                                         // C.ADDI is only valid when rd̸=x0.
                     begin                                                                                     // C.ADDI      16'b010_?__?????__?????_01  (HINT, nzimm=0)
                        if (nzimm5_0 != 0)
                        begin
                           if (dm == ASSEMBLY)
                              $sformat(i_str,"c.addi %s, %s, %0d", Rd_str, Rd_str, nzimm5_0);                  // Assembly  : c.addi Rd, Rd, nzimm[5:0].  see p. 104, 111
                           else
                              $sformat(i_str,"c.addi: %s = %s + %0d", Rd_str, Rd_str, nzimm5_0);               // Semantics : c.addi:  R[Rd] = R[Rd] + nzimm[5:0]
                        end
                        else
                           $sformat(i_str,"hint_c.addi");                                                      // Assembly  : hint_c.addi
                     end
                  end

                  1: // Quadrant 1:1
                  begin
                     Rd  = 1; // Rd = x1. x1 will get updated to pc + 2
                     RegNum(Rd,Rd_str);
                     if (dm == ASSEMBLY)                                                                       // C.JAL = JAL R1, offset[11:1]
                        $sformat(i_str,"c.jal %s, 0x%0x",Rd_str, pc+imm11_1);                                  // Assembly  : c.jal rd, pc+imm
                     else
                        $sformat(i_str,"c.jal: %s = pc + 2, pc = %0d", Rd_str, pc+imm11_1);                    // Semantics : c.jal: R[Rd] = PC + 2; PC = PC + sext(imm)
                  end

                  2: // Quadrant 1:2
                  if (Rd != 0)                                                                                 // C.LI        16'b010_?__?????__?????_01
                  begin
                     if (dm == ASSEMBLY)                                                                       // C.LI = ADDI Rd, R0, imm5_0. p 104
                        $sformat(i_str,"c.li %s, %0d",Rd_str, imm5_0);                                         // Assembly  : c.li rd, imm5_0
                     else
                        $sformat(i_str,"c.li: %s = %0d", Rd_str, imm5_0);                                      // Semantics : c.li: R[Rd] = imm5_0
                  end
                  else
                     $sformat(i_str,"hint_c.li");                                                              // Assembly  : hint_c.li

                  3:  // Quadrant 1:3
                  if (Rd == 2)
                  begin                                                                                        // C.ADDI16SP
                     Rs1 = 2;
                     RegNum(Rs1,Rs1_str);

                     if (nzimm9_4 != 0)
                     begin
                        if (dm == ASSEMBLY)                                                                    // addi x2, x2, nzimm[9:4]
                           $sformat(i_str,"c.addi16sp %s, %s, %0d)", Rd_str, Rd_str, nzimm9_4);                // Assembly  : c.addi16sp Rd, Rd, nzimm[9:4].  see p. 104, 111
                        else
                           $sformat(i_str,"c.addi16sp: %s += %0d", Rd_str, nzimm9_4);                          // Semantics : c.addi16sp:  R[Rd] = R[Rd] + nzimm[9:4]
                     end
                  // else // "the code point with nzimm=0 is reserved" p 105
                  end
                  else if (Rd != 0)
                  begin
                      if (nzuimm17_12 != 0)                                                                    // C.LUI       16'b011_?__?????__?????_01
                      begin
                        if (dm == ASSEMBLY)                                                                    // C.LUI = LUI Rd, nzimm[17:12]. see p. 104
                           $sformat(i_str,"c.lui %s, 0x%0x",Rd_str,nzuimm17_12 >> 12);                         // Assembly  : c.lui rd, imm
                        else // equation type format
                           $sformat(i_str,"c.lui: %s = 0x%0x",Rd_str,nzuimm17_12);                             // Semantics : c.lui: R[Rd] = imm
                      end
                   // else // "The code points with nzimm=0 are reserved" p 104
                   end
                   `ifdef H_C_LUI
                   else // Rd = X0 -> "the remaining code points with rd=x0 are HINTs"
                      $sformat(i_str,"hint_c.lui");                                                            // Assembly  : hint_c.lui
                   `endif

                  4: // Quadrant 1:4
                  begin
                     case (i[11:10])   // see p 111
                        0:
                        if (!shamt5_0[5])       // "For RV32C, shamt[5] must be zero;" see p 105
                        begin
                           if (shamt5_0 != 0)   // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                           begin
                              if (Rd != 0)      // "For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C." p. 105
                              begin
                                 if (dm == ASSEMBLY)                                                           // C.SRLI = SRLI Rd, Rd, shamt[5:0] p. 105
                                    $sformat(i_str,"c.srli %s, %s, %0d", Rs1_str, Rs1_str, shamt5_0);          // Assembly  : c.srli rd, rs1, imm
                                 else
                                    $sformat(i_str,"c.srli: %s = %s >> %0d", Rs1_str, Rs1_str, shamt5_0);      // Semantics : c.srli: R[Rd] = R[Rs1] >> imm
                              end
                              `ifdef H_C_SRLI
                              else
                                 $sformat(i_str,"hint_c.srli");                                                // Assembly  : hint_c.srli
                              `endif
                           end
                           `ifdef H_C_SRLI2
                           else
                              $sformat(i_str,"hint_c.srli2");                                                  // Assembly  : hint_c.srli2
                           `endif
                        end
                        // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105

                        1:
                        if (!shamt5_0[5])       // "For RV32C, shamt[5] must be zero;" see p 105
                        begin
                           if (shamt5_0 != 0)   // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                           begin
                              if (Rd != 0)      //For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C. p. 105
                              begin
                                 if (dm == ASSEMBLY)                                                           // C.SRAI = SRAI Rd, Rd, shamt[5:0] p.105-106
                                    $sformat(i_str,"c.srai %s, %s, %0d", Rs1_str, Rs1_str, shamt5_0);          // Assembly  : c.srai rd, rs1, imm
                                 else
                                    $sformat(i_str,"c.srai: %s = %s >>> %0d", Rs1_str, Rs1_str, shamt5_0);     // Semantics : c.srai: R[Rd] = R[Rs1] >>> imm
                              end
                              `ifdef H_C_SRAI
                              else
                                 $sformat(i_str,"hint_c.srai");                                                // Assembly  : hint_c.srai
                              `endif
                           end
                           `ifdef H_C_SRAI2
                           else                 // "the code points with shamt=0 are HINTs" p 105
                              $sformat(i_str,"hint_c.srai2");                                                  // Assembly  : hint_c.srai2
                           `endif
                        end
                        // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105

                        2:
                        begin
                           if (dm == ASSEMBLY)
                              $sformat(i_str,"c.andi %s, %s, %0d", Rs1_str, Rs1_str, imm5_0);                  // Assembly  : c.andi rd, rs1, imm
                           else
                              $sformat(i_str,"c.andi: %s = %s & %0d", Rs1_str, Rs1_str, imm5_0);               // Semantics : c.andi: R[Rd] = R[Rs1] & sext(imm)
                        end

                        3:
                        if (!i[12])
                        begin
                           case (i[6:5])
                              0:
                              begin
                                 if (dm == ASSEMBLY)
                                    $sformat(i_str,"c.sub %s, %s, %s", Rs1_str, Rs1_str, Rs2_str);             // Assembly  : c.sub rd, rs1, rs2
                                 else
                                    $sformat(i_str,"c.sub: %s = %s - %s", Rs1_str, Rs1_str, Rs2_str);          // Semantics : c.sub: R[Rd] = R[Rs1] - R[Rs2]
                              end
                              1:
                              begin
                                 if (dm == ASSEMBLY)
                                    $sformat(i_str,"c.xor %s, %s, %s", Rs1_str, Rs1_str, Rs2_str);             // Assembly  : c.xor rd, rs1, rs2
                                 else
                                    $sformat(i_str,"c.xor: %s = %s ^ %s", Rs1_str, Rs1_str, Rs2_str);          // Semantics : c.xor: R[Rd] = R[Rs1] ^ R[Rs2]
                              end
                              2:
                              begin
                                 if (dm == ASSEMBLY)
                                    $sformat(i_str,"c.or %s, %s, %s", Rs1_str, Rs1_str, Rs2_str);              // Assembly  : c.or rd, rs1, rs2
                                 else
                                    $sformat(i_str,"c.or: %s = %s | %s", Rs1_str, Rs1_str, Rs2_str);           // Semantics : c.or: R[Rd] = R[Rs1] - R[Rs2]
                              end
                              3:
                              begin
                                 if (dm == ASSEMBLY)
                                    $sformat(i_str,"c.and %s, %s, %s", Rd_str, Rs1_str, Rs2_str);              // Assembly  : c.and rd, rs1, rs2
                                 else
                                    $sformat(i_str,"c.and: %s = %s & %s", Rd_str, Rs1_str, Rs2_str);           // Semantics : c.and: R[Rd] = R[Rs1] - R[Rs2]
                              end
                           endcase
                        end
                        // else // Reserved
                     endcase
                  end

                  5: // Quadrant 1:5
                  begin                                                                                        // C.J = JAL R0, offset[11:1]
                     if (dm == ASSEMBLY)                                                                       // PC = PC + sext(imm), R[rd] = PC + 4; (PC + 2 for compressed)
                        $sformat(i_str,"c.j 0x%0x",pc+imm11_1);                                                // Assembly  : c.j pc+imm
                     else
                        $sformat(i_str,"c.j: pc = 0x%0x", pc+imm11_1);                                         // Semantics : c.j: PC = PC + sext(imm)
                  end

                  6: // Quadrant 1:6
                  begin                                                                                        // C.BEQZ Rs1, R0, offset[8:1]
                     if (dm == ASSEMBLY)                                                                       // PC = PC + sext(imm)
                        $sformat(i_str,"c.beqz $s, %0d", Rs1_str, offset8_1);                                  // Assembly  : c.beqz Rs1, offset8_1
                     else
                        $sformat(i_str,"c.beqz: PC = (%s == 0) ? %0d : PC+2", Rs1_str, pc+offset8_1);          // Semantics  : c.beqz: PC = (Rs1 == 0) ? PC + offset8_1 : PC + 2
                 end
                  7: // Quadrant 1:7
                  begin                                                                                        // C.BNEZ Rs1, R0, offset[8:1]
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.bnez %s, %0d", Rs1_str, offset8_1);                                  // Assembly  : c.bnez rs1, imm
                     else
                        $sformat(i_str,"c.bnez: PC = (%s != 0) ? %0d : PC+2", Rs1_str, pc+offset8_1);          // Assembly  : c.bnez: PC = (Rs1 != 0) ? PC + offset8_1 : PC + 2
                  end
               endcase
            end

            2: // -------------------------------- Quadrant 2  see p. 82 --------------------------------
            begin
               Rd    = i[11:7];
               Rs1   = i[11:7];
               Rs2   = i[6:2];
               RegNum(Rd,Rd_str);
               RegNum(Rs1,Rs1_str);
               RegNum(Rs2,Rs2_str);

               case(i[15:13])
                  0: // Quadrant 2:0
                  begin
                     if (!shamt5_0[5])       // "For RV32C, shamt[5] must be zero;" see p 105
                     begin
                        if (shamt5_0 != 0)   // "For RV32C and RV64C, the shift amount must be non-zero;" p.105
                        begin
                           if (Rd != 0)      // "For all base ISAs, the code points with rd=x0 are HINTs, except those with shamt[5]=1 in RV32C." p. 105
                           begin                                                                               // C.SLLI Rd, Rd, shamt[5:0] p. 105
                              if (dm == ASSEMBLY)                                                              // C_SLLI       16'b000_?_?????_?????_10
                                 $sformat(i_str,"c.slli %s, %s, %0d", Rd_str, Rd_str, shamt5_0);               // Assembly  : c.slli rd, rd, imm
                              else
                                 $sformat(i_str,"c.slli: %s = %s << %0d", Rd_str, Rd_str, shamt5_0);           // Semantics : c.slli: R[Rd] = R[Rd] << imm
                           end
                           `ifdef H_C_SRLI
                           else
                               $sformat(i_str,"hint_c.slli");                                                  // Assembly  : hint_c.slli
                           `endif
                        end
                        `ifdef H_C_SRLI2
                        else
                           $sformat(i_str,"hint_c.slli2");                                                     // Assembly  : hint_c.slli2
                        `endif
                     end
                     // else                 // "the code points with shamt[5]=1 are reserved for custom extensions." p 105
                  end

                  `ifdef ext_D
                  1: // Quadrant 2:1
                  // C.FLDSP   16'b001_?_?????_?????_10 - Double Precision Floating Point Load from SP - RV32DC
                  begin // fldsp rd, offset[8:3](x2).
                     Rs1 = 2;  // SP is X2
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.fldsp %s, %0d(%s)", Rd_str, offset8_3, Rs1_str);                     // Assembly  : c.fldsp R[rd], imm(rs1)
                     else
                        $sformat(i_str,"c.fldsp: %s = %0d(%s)",Rd_str, offset8_3, Rs1_str);                    // Semantics : c.fldsp: R[Rd] = imm(R[Rs1])
                  end
                  `endif

                  2: // Quadrant 2:2
                  if (Rd != 0)               // C.LWSP is only valid when rd̸=x0;
                  begin
                     Rs1 = 2;                // SP is X2
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)                                                                       // C_LWSP       16'b010_?_?????_?????_10
                        $sformat(i_str,"c.lwsp %s, %0d(%s)", Rd_str, offset7_2, Rs1_str);                      // Assembly  : c.lwsp rd, imm(rs1)
                     else
                        $sformat(i_str,"c.lwsp: %s = %0d(%s)",Rd_str, offset7_2, Rs1_str);                     // Semantics : c.lwsp: R[Rd] = imm(R[Rs1])
                  end
               // else                       // " the code points with rd=x0 are reserved."

                  `ifdef ext_F
                  3: // Quadrant 2:3
                  begin
                     Rs1 = 2;  // SP is X2
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)                                                                       // C.FLWSP - Single Precision Floating Point Load from SP
                        $sformat(i_str,"c.flwsp %s, %0d(%s)", Rd_str, offset7_2, Rs1_str);                     // Assembly  : c.flwsp rd, imm(rs1)
                     else
                        $sformat(i_str,"c.flwsp: %s = %0d(%s)",Rd_str, offset7_2, Rs1_str);                    // Semantics : c.flwsp: R[Rd] = imm(R[Rs1])
                  end
                  `endif

                  4: // Quadrant 2:4
                  begin
                     if (!i[12])
                     begin
                        if (Rs2 == 0)              // Rs2 == X0?
                        begin
                           if (Rs1 != 0)           // C.JR is only valid when rs1̸=x0;
                           begin
                              if (dm == ASSEMBLY)                                                              // C.JR = JALR R0, Rs1, 0 : PC = R[rs1]
                                 $sformat(i_str,"c.jr (%s)", Rs1_str);                                         // Assembly  : c.jr rs1
                              else
                                 $sformat(i_str,"c.jr: pc = %0s", Rs1_str);                                    // Semantics : c.jr: PC = Rs1
                           end
                        // else                    // the code point with rs1=x0 is reserved.
                        end
                        else                       // Rs2 != X0
                        begin
                           if (Rd != 0)
                           begin
                              if (dm == ASSEMBLY)                                                              // C.MV = ADD Rd, R0, Rs2
                                 $sformat(i_str,"c.mv %s, %s", Rd_str, Rs2_str);                               // Assembly  : c.mv rd, rs2
                              else
                                 $sformat(i_str,"c.mv: %s = %s", Rd_str, Rs2_str);                             // Semantics : c.mv: R[Rd] = R[Rs2]
                           end
                           `ifdef H_C_MV
                           else
                             $sformat(i_str,"hint_c.mv");                                                      // Assembly  : hint_c.mv
                           `endif
                        end
                     end
                     else // i[12] == 1'b1
                     begin
                        case ({(Rs1 != 0),(Rs2 != 0)})
                           2'b00:      // Rs1 = 0, Rs2 = 0   NOTE: Rd = Rs1 = 0
                              $sformat(i_str,"c.ebreak");                                                      // Assembly  : c.ebreak

                           `ifdef H_C_ADD
                           2'b01:      // Rs1 = 0, Rs2 != 0   NOTE: "The code points with rs2̸=x0 and rd=x0 are HINTs." p 106
                               $sformat(i_str,"hint_c.add0");                                                  // Assembly  : hint_c.add
                           `endif

                           2'b10:      // Rs1 != 0, Rs2 == 0
                           begin
                              if (dm == ASSEMBLY)
                                 $sformat(i_str,"c.jalr R1, %s", Rs1_str);                                     // Assembly  : c.jalr R1, rs1
                              else
                                 $sformat(i_str,"c.jalr: pc = (%s), R1 = PC+2 = 0x%0x", Rs1_str, pc+2);        // Semantics : c.jalr: PC = (R[Rs1]), R[Rd] = PC+2
                           end

                           2'b11:      // Rs1 != 0, Rs2 != 0
                              if (dm == ASSEMBLY)                                                              // C.ADD = ADD Rd, Rd, Rs2  p. 106
                                 $sformat(i_str,"c.add %s, %s, %s", Rd_str, Rd_str, Rs2_str);                  // Assembly  : c.add rd, rd, rs2
                              else
                                 $sformat(i_str,"c.add: %s += %s", Rd_str, Rs2_str);                           // Semantics : R[Rd] += R[Rs2]
                        endcase
                     end
                  end

                  `ifdef ext_D
                  5: // Quadrant 2:5
                  // C.FSDSP 16'b101__??????_?????_10    - Double Precision Floating point - RV32DC
                  begin //  fsdsp rs2, offset[8:3](x2).
                     Rs1 = 2;
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"c.fsdsp %s, %0d(%s)", Rs2_str, offset8_3, Rs1_str);                    // Assembly  : c.fldsp rs2, imm(R[rs1])
                     else
                        $sformat(i_str,"c.fsdsp: %s = %0d(%s)",Rs2_str, offset8_3, Rs1_str);                   // Semantics : c.fldsp: R[Rs2] = imm(R[Rs1])
                  end
                  `endif

                  6: // Quadrant 2:6
                  begin
                     Rs1 = 2;
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)                                                                       // C.SWSP = sw rs2, offset[7:2](x2)
                        $sformat(i_str,"c.swsp %s, %0d(%s)", Rs2_str, offset7_2_css, Rs1_str);                 // Assembly  : c.swsp rs2, imm(rs1)
                     else
                        $sformat(i_str,"c.swsp: %0d(%s) = %s", offset7_2_css, Rs1_str, Rs2_str);               // Semantics : c.swsp: imm(R[Rs1]) = R[Rs2]
                  end

                  `ifdef ext_F
                  7: // Quadrant 2:7
                  begin
                     Rs1 = 2;
                     RegNum(Rs1,Rs1_str);
                     if (dm == ASSEMBLY)                                                                       // C.FSWSP
                        $sformat(i_str,"c.fswsp %s, %0d(%s)", Rs2_str, offset7_2_css, Rs1_str);                // Assembly  : c.fswsp rs2, imm(rs1)
                     else
                        $sformat(i_str,"c.fswsp: %0d(%s) = %s", offset7_2_css, Rs1_str, Rs2_str);              // Semantics : c.fswsp: imm(R[Rs1]) = R[Rs2]
                  end
                  `endif
               endcase
            end
         endcase

         `endif
      end
      else if (i[4:2] != 3'b111)    // 32 bit RV32I instruction?
      begin
         RegNum(Rs1,Rs1_str);
         RegNum(Rs2,Rs2_str);
         RegNum(Rd,Rd_str);

         $sformat(pc_str,"0x%0x", pc);
         $sformat(i_str,"Illegal 32 bit instruction: 0x%0x",i);                                    // default if nothing gets decoded below

         // ************************************************************************** Load instructions
         if (i[6:2] == 5'b00000)
         begin
            case(funct3)
               0: ld_form (i[14:12], Rd_str, Rs1_str, i_imm, i_str);                               // LB
               1: ld_form (i[14:12], Rd_str, Rs1_str, i_imm, i_str);                               // LH
               2: ld_form (i[14:12], Rd_str, Rs1_str, i_imm, i_str);                               // LW
               4: ld_form (i[14:12], Rd_str, Rs1_str, i_imm, i_str);                               // LBU
               5: ld_form (i[14:12], Rd_str, Rs1_str, i_imm, i_str);                               // LHU
            endcase
         end

         // ************************************************************************** FENCE type instructions
         if (i[6:2] == 5'b00011)
         begin
            if (funct3 == 3'b000)
               $sformat(i_str,"fence");                                                            // Assembly  : fence// FENCE    32'b???????_?????_?????_000_?????_0001111
            else if (funct3 == 3'b001)
               $sformat(i_str,"fence.i");                                                          // Assembly  : fence.i// FENCE_I  32'b???????_?????_?????_001_?????_0001111
         end

         // ************************************************************************** Arithmetic Immediate type instructions
         if (i[6:2] == 5'b00100)
         begin
            case(funct3)
               0:
               if (Rd != 0) // see p. 30
               begin
                  simm = $signed(i_imm);
                  if (dm == ASSEMBLY)
                  begin
                     if (Rs1 == 1'd0)
                        $sformat(i_str,"li %s, %0d", Rd_str, simm);                                // Assembly  : li rd, sext(i_imm)
                     else if (i_imm == 0)
                        $sformat(i_str,"mv %s, %s", Rd_str, Rs1_str);                              // Assembly  : mv rd, rs1
                     else
                        $sformat(i_str,"addi %s, %s, %0d", Rd_str, Rs1_str, simm);                 // Assembly  : addi rd, rs1, sext(i_imm)
                  end
                  else
                     $sformat(i_str,"%s = %s + %0d", Rd_str, Rs1_str, simm);                       // Semantics : R[Rd] = R[Rs1] + sext(i_imm)
               end
               else if ((Rs1 == 0) & (i_imm == 0))
                  $sformat(i_str,"nop");                                                           // Assembly  : nop - addi x0, x0, 0
               `ifdef H_ADDI
               else
                   $sformat(i_str,"hint.addi");                                                    // Assembly  : hint.addi
               `endif

               1:                                                                                  // SLLI     32'b0000000_?????_?????_001_?????_0010011
               if ((Rd != 0) & (i[31:25] == 7'b0000000))
               begin
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"slli %s, %s, %0d", Rd_str, Rs1_str, imm);                     // Assembly  : slli rd, rs1, imm
                  else
                     $sformat(i_str,"%s = %s << %0d", Rd_str, Rs1_str, imm);                       // Semantics : R[Rd] = R[Rs1] << imm
               end
               `ifdef H_SLLI
               else
                  $sformat(i_str,"hint.slli");                                                     // Assembly  : hint.slli
               `endif

               2:                                                                                  // SLTI     32'b???????_?????_?????_010_?????_0010011
               if (Rd != 0)
               begin
                  simm = $signed(i_imm);
                  if (dm == ASSEMBLY)
                  // if (simm == 'd0) $sformat(i_str,"mv %s, %s", Rd_str, Rs1_str);                // Assembly  : mv rd, rs1   // Semantics : R[rd] = R[rs1]
                  $sformat(i_str,"slti %s, %s, %0d", Rd_str, Rs1_str, simm);                       // Assembly  : slti rd, rs1, imm
                  else
                     $sformat(i_str,"%s = (%s < %0d)", Rd_str, Rs1_str, simm);                     // Semantics : R[Rd] = ( R[Rs1] < sext(imm) )
               end
               `ifdef H_SLTI
               else
                  $sformat(i_str,"hint.slti");                                                     // Assembly  : hint.slti
               `endif

               3:                                                                                  // SLTIU    32'b???????_?????_?????_011_?????_0010011
               if (Rd != 0)
               begin
                  // if (simm == 1'd0) $sformat(i_str,"mv %s, %s", Rd_str, Rs1_str);               // Assembly  : mv rd, rs1   // Semantics : R[rd] = R[rs1]
                  if (dm == ASSEMBLY)
                  begin
                     if (i_imm == 1'd1)
                        $sformat(i_str,"seqz %s, %s", Rd_str, Rs1_str);                            // Assembly  : seqz rd, rs1
                     else
                        $sformat(i_str,"sltiu %s, %s, %0d", Rd_str, Rs1_str, i_imm);               // Assembly  : sltiu rd, rs1, imm
                  end
                  else
                     $sformat(i_str,"%s = (%s <u %0d)", Rd_str, Rs1_str, i_imm);                   // Semantics : R[Rd] = ( R[Rs1] <u sext(imm) )
               end
               `ifdef H_SLTIU
               else
                  $sformat(i_str,"hint.sltiu");                                                    // Assembly  : hint.sltiu
               `endif

               4:                                                                                  // XORI     32'b???????_?????_?????_100_?????_0010011
               if (Rd != 0)
               begin
                  simm = $signed(i_imm);
                  // if (simm == 1'd0) $sformat(i_str,"mv %s, %s", Rd_str, Rs1_str);               // Assembly  : mv rd, rs1   // Semantics : R[rd] = R[rs1]
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"xori %s, %s, %0d", Rd_str, Rs1_str, simm);                    // Assembly  : xori rd, rs1, imm
                  else
                     $sformat(i_str,"%s = %s ^ %0d", Rd_str, Rs1_str, simm);                       // Semantics : R[Rd] = R[Rs1] ^ sext(imm)
               end
               `ifdef H_XORI
               else
                  $sformat(i_str,"hint.xori");                                                     // Assembly  : hint_c.xori
               `endif

               5:
               if (i[31:25] == 7'b0000000)
               begin
                  if (Rd != 0)
                  begin                                                                            // SRLI     32'b0000000_?????_?????_101_?????_0010011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"srli %s, %s, %0d", Rd_str, Rs1_str, shamt);                // Assembly  : srli rd, rs1, shamt
                     else
                        $sformat(i_str,"%s = %s >> %0d", Rd_str, Rs1_str, shamt);                  // Semantics : R[Rd] = R[Rs1] >> shamt
                  end
                  `ifdef H_SRLI
                  else
                      $sformat(i_str,"hint.srli");                                                 // Assembly  : hint.srli
                  `endif
               end
               else if (i[31:25] == 7'b0100000)
               begin
                  if (Rd != 0)
                  begin                                                                            // SRAI     32'b0100000_?????_?????_101_?????_001001
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"srai %s, %s, %0d", Rd_str, Rs1_str, shamt);                // Assembly  : srai rd, rs1, shamt
                     else
                        $sformat(i_str,"%s = %s >>> %0d", Rd_str, Rs1_str, shamt);                 // Semantics : R[Rd] = R[Rs1] >>> shamt
                  end
                  `ifdef H_SRAI
                  else
                     $sformat(i_str,"hint.srai");                                                  // Assembly  : hint.srai
                  `endif
               end

               6:
               if (Rd != 0)
               begin                                                                               // ORI      32'b???????_?????_?????_110_?????_0010011
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"ori %s, %s, %0d", Rd_str, Rs1_str, i_imm);                    // Assembly  : ori rd, rs1, i_imm
                  else
                     $sformat(i_str,"%s = %s | %0d", Rd_str, Rs1_str, i_imm);                      // Semantics : R[Rd] = R[Rs1] | i_imm
               end
               `ifdef H_ORI
               else
                  $sformat(i_str,"hint.ori");                                                      // Assembly  : hint.ori
               `endif

               7:
               if (Rd != 0)
               begin                                                                               // ANDI     32'b???????_?????_?????_111_?????_0010011
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"andi %s, %s, %0d", Rd_str, Rs1_str, i_imm);                   // Assembly  : andi rd, rs1, i_imm
                  else
                     $sformat(i_str,"%s = %s & %0d", Rd_str, Rs1_str, i_imm);                      // Semantics : R[Rd] = R[Rs1] & i_imm
               end
               `ifdef H_ANDI
               else
                  $sformat(i_str,"hint.andi");                                                     // Assembly  : hint.andi
               `endif
            endcase
         end

         // ************************************************************************** AUIPC instruction
         if (i[6:2] == 5'b00101)                                                                   // AUIPC    32'b???????_?????_?????_???_?????_0010111
         begin
            if (Rd != 0)
            begin
               imm = u_imm >> 12;
               if (dm == ASSEMBLY)
                  $sformat(i_str,"auipc %s, %0d",Rd_str, imm);                                     // Assembly  : auipc rd, imm
               else
                  $sformat(i_str,"%s = pc + %0d",Rd_str, u_imm);                                   // Semantics : R[Rd] = PC + ( imm << 12 )
            end
            `ifdef H_AUIPC
            else
               $sformat(i_str,"hint.auipc");                                                       // Assembly  : hint.auipc
            `endif
         end

         // ************************************************************************** Store type instructions - SB, SH, SW
         if (i[6:2] == 5'b01000)
         begin
            case(funct3)
               0: st_form(i[14:12], Rs1_str,Rs2_str,s_imm,i_str);                                  // SB
               1: st_form(i[14:12], Rs1_str,Rs2_str,s_imm,i_str);                                  // SH
               2: st_form(i[14:12], Rs1_str,Rs2_str,s_imm,i_str);                                  // SW
            endcase
         end

         // ************************************************************************** Atomic instructions - NOT  IMPLEMENTED YET !!!!!!!!!!
         `ifdef ext_A  // RV32A instructions
         if ((i[6:2] == 5'b01011) & (funct3 == 3'b010))
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
         `endif // ext_A

         // ************************************************************************** Arithmetic Register type instructions
         if (i[6:2] == 5'b01100)
         begin
            if (i[31:25] == 7'b0000000)
            begin
               case(funct3)
                  0:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // ADD      32'b0000000_?????_?????_000_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"add %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : add rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s + %s", Rd_str, Rs1_str, Rs2_str);                  // Semantics : R[Rd] = R[Rs1] + R[Rs2]
                  end
                  `ifdef R_ADD
                  else
                      $sformat(i_str,"res.add");                                                   // Assembly  : res.add
                  `endif

                  1:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // SLL      32'b0000000_?????_?????_001_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"sll %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : sll rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s << %s[4:0]", Rd_str, Rs1_str, Rs2_str);            // Semantics : R[Rd] = R[Rs1] << R[Rs2][4:0]
                  end
                  `ifdef R_SLL
                  else
                     $sformat(i_str,"res.sll");                                                   // Assembly  : res.sll
                  `endif

                  2:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // SLT      32'b0000000_?????_?????_010_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"slt %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : slt rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s <s %s", Rd_str, Rs1_str, Rs2_str);                 // Semantics : R[Rd] = ( R[Rs1] <s R[Rs2] )
                  end
                  `ifdef R_SLT
                  else
                     $sformat(i_str,"res.slt");                                                    // Assembly  : res.slt
                  `endif

                  3:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // SLTU     32'b0000000_?????_?????_011_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"sltu %s, %s, %s", Rd_str, Rs1_str, Rs2_str);               // Assembly  : sltu rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s <u %s", Rd_str, Rs1_str, Rs2_str);                 // Semantics : R[Rd] = ( R[Rs1] <u R[Rs2] )
                  end
                  `ifdef R_SLTU
                  else
                     $sformat(i_str,"res.sltu");                                                   // Assembly  : re.sltu
                  `endif

                  4:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // XOR      32'b0000000_?????_?????_100_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"xor %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : xor rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s ^ %s", Rd_str, Rs1_str, Rs2_str);                  // Semantics : R[Rd] = R[Rs1] ^ R[Rs2]
                  end
                  `ifdef R_XOR
                  else
                     $sformat(i_str,"res.xor");                                                    // Assembly  : res.xor
                  `endif

                  5:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // SRL      32'b0000000_?????_?????_101_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"srl %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : srl rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s >> %s", Rd_str, Rs1_str, Rs2_str);                 // Semantics : R[Rd] = R[Rs1] >> R[Rs2][4:0]
                  end
                  `ifdef R_SRL
                  else
                     $sformat(i_str,"res.srl");                                                    // Assembly  : res.srl
                  `endif

                  6:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // OR       32'b0000000_?????_?????_110_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"or %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                 // Assembly  : or rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s | %s", Rd_str, Rs1_str, Rs2_str);                  // Semantics : R[Rd] = R[Rs1] | R[Rs2]
                  end
                  `ifdef R_OR
                  else
                     $sformat(i_str,"res.or");                                                     // Assembly  : res.or
                  `endif

                  7:
                  if (Rd != 0) // see p. 30
                  begin                                                                            // AND      32'b0000000_?????_?????_111_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"and %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : and rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s & %s", Rd_str, Rs1_str, Rs2_str);                  // Semantics : R[Rd] = R[Rs1] & R[Rs2]
                  end
                  `ifdef R_AND
                  else
                     $sformat(i_str,"res.and");                                                    // Assembly  : res.and
                  `endif
               endcase
            end
            else if (i[31:25] == 7'b0100000)
            begin
               case(funct3)
                  0:
                  if (Rd != 0)
                  begin                                                                            // SUB      32'b0100000_?????_?????_000_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"sub %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : sub rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s - %s", Rd_str, Rs1_str, Rs2_str);                  // Semantics : R[Rd] = R[Rrs1] - R[Rs2]
                  end
                  `ifdef H_SUB
                  else
                     $sformat(i_str,"res.sub");                                                    // Assembly  : res.sub
                  `endif

                  5:
                  if (Rd != 0)
                  begin                                                                            // SRA      32'b0100000_?????_?????_101_?????_0110011
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"sra %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : sra rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s >>> %s[4:0]", Rd_str, Rs1_str, Rs2_str);           // Semantics : R[rd] = R[rs1] >>> R[rs2][4:0]
                  end
                  `ifdef H_SRA
                  else
                     $sformat(i_str,"res.sra");                                                    // Assembly  : res.sra
                  `endif
               endcase
            end

            `ifdef ext_M  // RV32M instructions
            else if (i[31:25] == 7'b0000001)                                                       // Multiply, Divide, Remainder instructions
            begin
               case(funct3)
                  0: // MUL      32'b0000001_?????_?????_000_?????_0110011    unsigned x unsigned - return lower 32 bits
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"mul %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : mul rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s * %s :mul", Rd_str, Rs1_str, Rs2_str);             // Semantics : R[Rd] = R[Rs1] * R[Rs2]
                  end
                  1: // MULH     32'b0000001_?????_?????_001_?????_0110011    signed x signed   - return upper 32 bits
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"mulh %s, %s, %s", Rd_str, Rs1_str, Rs2_str);               // Assembly  : mulh rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s * %s :mulh", Rd_str, Rs1_str, Rs2_str);            // Semantics : R[Rd] = R[Rs1] * R[Rs2]
                  end
                  2: // MULHSU   32'b0000001_?????_?????_010_?????_0110011    signed x unsigned - return upper 32 bits
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"mulhsu %s, %s, %s", Rd_str, Rs1_str, Rs2_str);             // Assembly  : mulhsu rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s * %s :mulhsu", Rd_str, Rs1_str, Rs2_str);          // Semantics : R[Rd] = R[Rs1] * R[Rs2]
                  end
                  3: // MULHU    32'b0000001_?????_?????_011_?????_0110011    unsigned x unsigned - return upper 32 bits
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"mulhu %s, %s, %s", Rd_str, Rs1_str, Rs2_str);              // Assembly  : mulhu rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s * %s :mulhu", Rd_str, Rs1_str, Rs2_str);           // Semantics : R[Rd] = R[Rs1] * R[Rs2]
                  end
                  4: // DIV      32'b0000001_?????_?????_100_?????_0110011
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"div %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : div rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s / %s :div", Rd_str, Rs1_str, Rs2_str);             // Semantics : R[Rd] = R[Rs1] / R[Rs2]
                  end
                  5: // DIVU     32'b0000001_?????_?????_101_?????_0110011
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"divu %s, %s, %s", Rd_str, Rs1_str, Rs2_str);               // Assembly  : divu rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s / %s :divu", Rd_str, Rs1_str, Rs2_str);            // Semantics : R[Rd] = R[Rs1] / R[Rs2]
                  end
                  6: // REM      32'b0000001_?????_?????_110_?????_0110011
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"rem %s, %s, %s", Rd_str, Rs1_str, Rs2_str);                // Assembly  : rem rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s / %s :rem", Rd_str, Rs1_str, Rs2_str);             // Semantics : R[Rd] = R[Rs1] % R[Rs2]
                  end
                  7: // REMU     32'b0000001_?????_?????_111_?????_0110011
                  begin
                     if (dm == ASSEMBLY)
                        $sformat(i_str,"remu %s, %s, %s", Rd_str, Rs1_str, Rs2_str);               // Assembly  : remu rd, rs1, rs2
                     else
                        $sformat(i_str,"%s = %s / %s :remu", Rd_str, Rs1_str, Rs2_str);            // Semantics : R[Rd] = R[Rs1] % R[Rs2]
                  end
               endcase
            end
            `endif // ext_M
         end

         // ************************************************************************** LUI instruction
         if (i[6:2] == 5'b01101)                                                                   // LUI      32'b???????_?????_?????_???_?????_0110111
         begin
            if (Rd != 0)
            begin
               imm = u_imm >> 12;
               if (dm == ASSEMBLY)
                  $sformat(i_str,"lui %s, %0d",Rd_str,imm);                                        // Assembly  : lui rd, imm
               else // equation type format
                  $sformat(i_str,"%s = %0d",Rd_str,u_imm);                                         // Semantics : R[Rd] = imm << 12
            end
            `ifdef H_LUI
            else
               $sformat(i_str,"hint.lui");                                                         // Assembly  : hint.lui
            `endif
         end

         // ************************************************************************** Bxx type instructions
         if (i[6:2] == 5'b11000)
         begin
            case(funct3)
               0: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BEQ      32'b???????_?????_?????_000_?????_1100011
               1: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BNE      32'b???????_?????_?????_001_?????_1100011
               4: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BLT      32'b???????_?????_?????_100_?????_1100011
               5: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BGE      32'b???????_?????_?????_101_?????_1100011
               6: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BLTU     32'b???????_?????_?????_110_?????_1100011
               7: bxx_form(b_imm, Rs1, Rs1_str, Rs2, Rs2_str, pc, i[14:12], i_str);                // BGEU     32'b???????_?????_?????_111_?????_1100011
            endcase
         end

         // ************************************************************************** JALR  instruction
         if ((i[6:2] == 5'b11001) & (funct3 == 0))                                                 // JALR     32'b???????_?????_?????_000_?????_1100111
         begin                                                                                     //  PC = ( R[rs1] + sext(imm) ) & 0xfffffffe, R[rd] = PC + 4; (PC + 2 for compressed)
            simm = $signed(i_imm);
            if (dm == ASSEMBLY)
            begin
               if ((Rd == 1'd0) && (Rs1 == 1'd1) && (simm == 1'd0))
                  $sformat(i_str,"ret",Rs1_str);                                                   // Assembly  : ret
               else if ((Rd == 1'd0) &&  (simm == 1'd0))
                  $sformat(i_str,"jr %s",Rs1_str);                                                 // Assembly  : jr rs1
               else if ((Rd == 1'd1) && (simm == 1'd0))
                  $sformat(i_str,"jalr (%s)", Rs1_str);                                            // Assembly  : jalr (rs1)
               else
                  $sformat(i_str,"jalr %s, %0d(%s)", Rd_str, simm, Rs1_str);                       // Assembly  : jalr rd, imm(rs1)
            end
            else
               $sformat(i_str,"%s = pc + 4, pc = (%s + %0d) & 0xfffffffe", Rd_str, Rs1_str, imm);  // Semantics : R[Rd] = PC + 4; PC = ( R[Rs1] + sext(imm) ) & 0xfffffffe
         end

         // ************************************************************************** JAL instruction
         if (i[6:2] == 5'b11011)                                                                   // JAL      32'b???????_?????_?????_???_?????_1101111
         begin                                                                                     //  PC = PC + sext(imm), R[rd] = PC + 4; (PC + 2 for compressed)
            if (dm == ASSEMBLY)
            begin
               if (Rd == 1'd0)
                  $sformat(i_str,"j 0x%0x",pc+j_imm);                                              // Assembly  : j offset
               else if (Rd == 1'd1)
                  $sformat(i_str,"jal 0x%0x",pc+j_imm);                                            // Assembly  : jal offset
               else
                  $sformat(i_str,"jal %s, 0x%0x",Rd_str, pc+j_imm);                                // Assembly  : jal rd, pc+imm
            end
            else
               $sformat(i_str,"%s = pc + 4, pc = pc + %0d", Rd_str, imm);                          // Semantics : R[Rd] = PC + 4; PC = PC + sext(imm)
         end


         // ************************************************************************** ECALL instruction
         if (i[31:2] == 30'b0000000_00000_00000_000_00000_11100)                                   // ECALL    32'b0000000_00000_00000_000_00000_1110011
             $sformat(i_str,"ecall");                                                              // Assembly  : ecall


         // ************************************************************************** EBREAK instruction
         if (i[31:2] == 30'b0000000_00001_00000_000_00000_11100)                                   // EBREAK   32'b0000000_00001_00000_000_00000_1110011
            $sformat(i_str,"ebreak");                                                              // Assembly  : ebreak

         // ************************************************************************** URET instruction
         `ifdef ext_U
         if (i[31:2] == 30'b0000000_00010_00000_000_00000_11100)                                   // URET     32'b0000000_00010_00000_000_00000_1110011
            $sformat(i_str,"uret");
         `endif

         // ************************************************************************** SRET instruction
         `ifdef ext_S
         if (i[31:2] == 32'b0001000_00010_00000_000_00000_11100)                                   // SRET     32'b0001000_00010_00000_000_00000_1110011
            $sformat(i_str,"sret");
         `endif

         // ************************************************************************** WFI instruction
         if (i[31:2] == 30'b0001000_00101_00000_000_00000_11100)                                   // WFI      32'b0001000_00101_00000_000_00000_1110011
            $sformat(i_str,"wfi");

         // ************************************************************************** MRET instruction
         if (i[31:2] == 30'b0011000_00010_00000_000_00000_11100)                                   // MRET     32'b0011000_00010_00000_000_00000_1110011
            $sformat(i_str,"mret");


         // ************************************************************************** CSR instructions
         if (i[6:2] == 5'b11100)
         begin
            case(funct3)
               1:                                                                                  // CSRRW    32'b???????_?????_?????_001_?????_1110011
               begin                                                                               // Atomic Read/Write CSR
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrw %s, 0x%3x, %s",  Rd_str, csr, Rs1_str);                 // Assembly  : csrrw R[Rd], csr, R[rs1]
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR[0x%3x] = %s", Rd_str, csr, csr, Rs1_str);   // CSRRW: R[Rd] = CSR[csr], CSR = R[Rs1]
               end
               2:                                                                                  // CSRRS    32'b???????_?????_?????_010_?????_1110011
               begin                                                                               // CSRRS: Atomic Read and Set Bits in CSR  p. 21
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrs %s, 0x%3x, %s",  Rd_str, csr, Rs1_str);                 // Assembly  : csrrs R[Rd], csr, R[rs1]]
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR[0x%3x] = CSR[0x%3x] | %s", Rd_str, csr, csr, csr, Rs1_str);   // CSRRS: R[Rd] = CSR[csr], CSR[csr] = CSR[csr] | R[Rs1]
               end
               3:                                                                                  // CSRRC    32'b???????_?????_?????_011_?????_1110011
               begin                                                                               // CSRRC: Atomic Read and Clear Bits in CSR  p. 21
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrc %s, 0x%3x, %s",  Rd_str, csr, Rs1_str);                 // Assembly  : csrrc R[Rd], csr, R[rs1]]
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR0x%3x] = CSR[0x%3x] & ~%s", Rd_str, csr, csr, csr, Rs1_str);  // CSRRC: R[Rd] = CSR[csr], CSR[csr] = CSR[csr] & ~R[Rs1]
               end
               5:                                                                                  // CSRRWI   32'b???????_?????_?????_101_?????_1110011
               begin                                                                               // CSRRWI: Atomic Read/Write CSR
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrwi %s, 0x%3x, 0x%0x",  Rd_str, csr, imm);                 // Assembly  : csrrwi R[Rd], csr, imm
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR[0x%3x] = 0x%0x", Rd_str, csr, csr, imm); // CSRRW: R[Rd] = CSR[csr], CSR[csr] = imm
                  // Note: p21: If Rd == 0 then don't read the CSR - read shouldn't matter in this design since R0 can't be updated in GPR
               end
               6:                                                                                  // CSRRSI   32'b???????_?????_?????_110_?????_1110011
               begin                                                                               // CSRRSI: Atomic Read and Set Bits in CSR  p. 21
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrsi %s, 0x%3x, 0x%0x",  Rd_str, csr, imm);                 // Assembly  : csrrsi R[Rd], csr, imm
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR[0x%3x] = CSR[0x%3x] | 0x%0x", Rd_str, csr, csr, csr, imm);    // CSRRS: R[Rd] = CSR[csr], CSR[csr] = CSR[csr] | imm
               end
               7:                                                                                  // CSRRCI   32'b???????_?????_?????_111_?????_1110011
               begin                                                                               // CSRRCI: Atomic Read and Clear Bits in CSR  p. 21
                  if (dm == ASSEMBLY)
                     $sformat(i_str,"csrrci %s, 0x%3x, 0x%0x",  Rd_str, csr, imm);                 // Assembly  : csrrci R[Rd], csr, imm
                  else
                     $sformat(i_str,"%s = CSR[0x%3x], CSR[0x%3x] = CSR[0x%3x] & ~0x%0x", Rd_str, csr, csr, csr, imm);   // CSRRC: R[Rd] = CSR[csr], CSR[csr] = CSR[csr] & ~imm
               end
            endcase
         end


         // ************************************************************************** Floating Point instructions
         `ifdef ext_F // RV32F instructions
         if (i[6:2] == 5'b?????)
         begin
               // FLW         32'b????????????__?????_010_?????_0000111
               // FSW         32'b???????_?????_?????_010_?????_0100111

               // FMADD_S     32'b?????00_?????_?????_???_?????_1000011

               // FMSUB_S     32'b?????00_?????_?????_???_?????_1000111

               // FNMSUB_S    32'b?????00_?????_?????_???_?????_1001011

               // FNMADD_S    32'b?????00_?????_?????_???_?????_1001111

               // FADD_S      32'b0000000_?????_?????_???_?????_1010011
               // FSUB_S      32'b0000100_?????_?????_???_?????_1010011
               // FMUL_S      32'b0001000_?????_?????_???_?????_1010011
               // FDIV_S      32'b0001100_?????_?????_???_?????_1010011
               // FSGNJ_S     32'b0010000_?????_?????_000_?????_1010011
               // FSGNJN_S    32'b0010000_?????_?????_001_?????_1010011
               // FSGNJX_S    32'b0010000_?????_?????_010_?????_1010011
               // FMIN_S      32'b0010100_?????_?????_000_?????_1010011
               // FMAX_S      32'b0010100_?????_?????_001_?????_1010011
               // FSQRT_S     32'b0101100_00000_?????_???_?????_1010011
               // FLE_S       32'b1010000_?????_?????_000_?????_1010011
               // FLT_S       32'b1010000_?????_?????_001_?????_1010011
               // FEQ_S       32'b1010000_?????_?????_010_?????_1010011
               // FCVT_W_S    32'b1100000_00000_?????_???_?????_1010011
               // FCVT_WU_S   32'b1100000_00001_?????_???_?????_1010011
               // FCVT_S_W    32'b1101000_00000_?????_???_?????_1010011
               // FCVT_S_WU   32'b1101000_00001_?????_???_?????_1010011
               // FMV.X_W     32'b1110000_00000_?????_000_?????_1010011
               // FCLASS_S    32'b1110000_00000_?????_001_?????_1010011
               // FMV_W.X     32'b1111000_00000_?????_000_?????_1010011
         end
         `endif // ext_F
      end
      else // 48, 64, etc... instruction  ILLEGAL for this CPU
          $sformat(i_str,"Illegal 48 bit instruction: 0x%0x",i);
   end
endmodule

