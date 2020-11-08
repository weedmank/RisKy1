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
// File          :  vedic_mult16x16.v
// Description   :  Design of a 16x16 Vedic Multiplier in Verilog
//               :  Uses design of a 2x2, then a 4x4, then an 8x8.
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

//                   a[15:8]   b[15:8]                 a[7:0]    b[15:8]                 a[15:8]   b[7:0]                  a[7:0]    b[7:0]
//                     |         |                       |         |                       |         |                       |         |
//                     |         |                       |         |                       |         |                       |         |
//                +----+---------+----+             +----+---------+----+             +----+---------+----+             +----+---------+----+
//                |        8x8        |             |        8x8        |             |        8x8        |             |        8x8        |
//                |      multiply     |             |      multiply     |             |      multiply     |             |      multiply     |
//                +---------+---------+             +---------+---------+             +---------+---------+             +---------+---------+
//                          | q3[15:0]                        | q2[15:0]                        | q1[15:0]                        | q0[15:0]
//                          |         +-----------------------+                                 |         +-----------------------+
//                          |         |                                                         |         |                       |
//        temp3 = {q3,8'b0} @         @ temp2 = {8'b0,q2}                                       |         @ temp1 ={8'b0,q0[15:8]}|
//                     +----+---------+----+                                               +----+---------+----+                  |
//                     |       24 bit      |                                               |       16 bit      |                  |
//                     |       adder       |                                               |       adder       |                  |
//                     +---------+---------+                                               +---------+---------+                  |
//                               | q5                                                                | q4                         |
//                               |                                                                   |                            |
//                               +-----------+         +---------------------------------------------+                            |
//                                           |         |                                                                          |
//                                           |         @ temp4 = {8'b0,q4}                                                        @ q0[7:0]
//                                      +----+---------+----+                                                                     |
//                                      |       24 bit      |          +----------------------------------------------------------+
//                                      |       adder       |          |
//                                      +---------+---------+          |
//                                                | q6                 |
//                                                |                    |
//                                              c[31:8]              c[7:0]
module vedic_mult16x16
(
    input  wire   [15:0] a, b,
    output wire   [31:0] c
);

    wire   [15:0] q0,q1,q2,q3,q4,temp1;
    wire   [23:0] q5,q6,temp2,temp3,temp4;

    vedic_mult8 z1(a[7:0], b[7:0], q0);
    vedic_mult8 z2(a[15:8],b[7:0], q1);
    vedic_mult8 z3(a[7:0], b[15:8],q2);
    vedic_mult8 z4(a[15:8],b[15:8],q3);

    assign temp1  = {8'b0,q0[15:8]};
    assign q4     = q1 + temp1;
    assign temp2  = {8'b0,q2};
    assign temp3  = {q3,8'b0};
    assign q5     = temp2 + temp3;
    assign temp4  = {8'b0,q4};
    assign q6     = temp4 + q5;

    assign c[31:8]= q6;
    assign c[7:0] = q0[7:0];

endmodule

module vedic_mult8(a,b,c);
    input   wire  [7:0] a, b;
    output  wire [15:0] c;

    wire    [7:0] q0,q1,q2,q3,q4,temp1;
    wire   [11:0] q5,q6,temp2,temp3,temp4;

    vedic_mult4 z1(a[3:0],b[3:0],q0);
    vedic_mult4 z2(a[7:4],b[3:0],q1);
    vedic_mult4 z3(a[3:0],b[7:4],q2);
    vedic_mult4 z4(a[7:4],b[7:4],q3);

    assign temp1  = {4'b0,q0[7:4]};
    assign q4     = q1 + temp1;
    assign temp2  = {4'b0,q2};
    assign temp3  = {q3,4'b0};
    assign q5     = temp2 + temp3;
    assign temp4  = {4'b0,q4};
    assign q6     = temp4 + q5;

    // final output assignment
    assign c[15:4]= q6;
    assign c[3:0] = q0[3:0];
endmodule

module vedic_mult4(a,b,c);
    input   wire  [3:0] a, b;
    output  wire  [7:0] c;

    wire [3:0] q0,q1,q2,q3,q4,temp1;
    wire [5:0] q5,q6,temp2,temp3,temp4;

    vedic_mult2 z1(a[1:0],b[1:0],q0);
    vedic_mult2 z2(a[3:2],b[1:0],q1);
    vedic_mult2 z3(a[1:0],b[3:2],q2);
    vedic_mult2 z4(a[3:2],b[3:2],q3);

    assign temp1  = {2'b0,q0[3:2]};
    assign q4     = q1 + temp1;
    assign temp2  = {2'b0,q2};
    assign temp3  = {q3,2'b0};
    assign q5     = temp2 + temp3;
    assign temp4  = {2'b0,q4};
    assign q6     = temp4 + q5;

    assign c[7:2] = q6;
    assign c[1:0] = q0[1:0];
endmodule


module vedic_mult2(a, b, c);
    input [1:0]a, b;
    output [3:0]c;
    wire [3:0]c, temp;

    assign c[0]=a[0]&b[0];
    assign temp[0]=a[1]&b[0];
    assign temp[1]=a[0]&b[1];
    assign temp[2]=a[1]&b[1];

    ha z1(temp[0],temp[1],c[1],temp[3]);
    ha z2(temp[2],temp[3],c[2],c[3]);

endmodule

module ha(a,b,s,c);
    input a,b;
    output s,c;

    assign s = a^b;
    assign c = a&b;
endmodule
