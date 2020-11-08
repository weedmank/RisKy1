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
// File          :  vedic_mult32x32.v
// Description   :  Design of a 32x32 Vedic Multiplier in Verilog
//               :  Uses design of a 16x16 array multiplier
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

//                   a[31:16]  b[31:16]                a[15:0]   b[31:16]                a[31:16]  b[15:0]                   a[15:0]   b[15:0]
//                     |         |                       |         |                       |         |                         |         |
//                     |         |                       |         |                       |         |                         |         |
//                +----+---------+----+             +----+---------+----+             +----+---------+----+               +----+---------+----+
//                |       16x16       |             |       16x16       |             |       16x16       |               |       16x16       |
//                |      multiply     |             |      multiply     |             |      multiply     |               |      multiply     |
//                +---------+---------+             +---------+---------+             +---------+---------+               +---------+---------+
//                          | q3[31:0]                        | q2[31:0]                        | q1[31:0]                          | q0[31:0]
//                          |         +-----------------------+                                 |         +-------------------------+
//                          |         |                                                         |         |                         |
//       temp3 = {q3,16'b0} @         @ temp2 = {16'b0,q2}                                      |         @ temp1={16'b0,q0[31:16]} |
//                     +----+---------+----+                                               +----+---------+----+                    |
//                     |       48 bit      |                                               |       32 bit      |                    |
//                     |       adder       |                                               |       adder       |                    |
//                     +---------+---------+                                               +---------+---------+                    |
//                               | q5                                                                | q4                           |
//                               |                                                                   |                              |
//                               +-----------+         +---------------------------------------------+                              |
//                                           |         |                                                                            |
//                                           |         @ temp4 = {16'b0,q4}                                                         @ q0[15:0]
//                                      +----+---------+----+                                                                       |
//                                      |       48 bit      |          +------------------------------------------------------------+
//                                      |       adder       |          |
//                                      +---------+---------+          |
//                                                | q6                 |
//                                                |                    |
//                                              c[63:16]             c[15:0]

module vedic_mult32x32
(
    input  wire   [31:0]a,b,
    output wire   [63:0]c
);

    wire [31:0]q0,q1,q2,q3,q4,temp1;
    wire [47:0]q5,q6,temp2,temp3,temp4;

    vedic_mult16x16 z1(a[15:0], b[15:0], q0);
    vedic_mult16x16 z2(a[31:16],b[15:0], q1);
    vedic_mult16x16 z3(a[15:0], b[31:16],q2);
    vedic_mult16x16 z4(a[31:16],b[31:16],q3);

    assign temp1  = {16'b0,q0[31:16]};
    assign q4     = q1 + temp1;
    assign temp2  = {16'b0,q2};
    assign temp3  = {q3,16'b0};
    assign q5     = temp2 + temp3;
    assign temp4  = {16'b0,q4};
    assign q6     = temp4 + q5;

    assign c[63:16]  = q6;
    assign c[15:0]   = q0[15:0];

endmodule
