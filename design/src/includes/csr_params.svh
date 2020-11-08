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
// File          :  csr_params_RV.svh
// Description   :  parameters used in RisKy1_Formal_Asserts.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`ifndef _csr_params_
   `define _csr_params_

   localparam  MSTATUS           = 12'h300;
   localparam  MISA              = 12'h301;
   localparam  MEDELEG           = 12'h302;
   localparam  MIDELEG           = 12'h303;
   localparam  MIE               = 12'h304;
   localparam  MTVEC             = 12'h305;
   localparam  MCOUNTEREN        = 12'h306;
      
   localparam  MCOUNTINHIBIT     = 12'h320;
   localparam  MHPMEVENT3        = 12'h323;
   localparam  MHPMEVENT4        = 12'h324;
   localparam  MHPMEVENT5        = 12'h325;
   localparam  MHPMEVENT6        = 12'h326;
   localparam  MHPMEVENT7        = 12'h327;
   localparam  MHPMEVENT8        = 12'h328;
   localparam  MHPMEVENT9        = 12'h329;
   localparam  MHPMEVENT10       = 12'h32A;
   localparam  MHPMEVENT11       = 12'h32B;
   localparam  MHPMEVENT12       = 12'h32C;
   localparam  MHPMEVENT13       = 12'h32D;
   localparam  MHPMEVENT14       = 12'h32E;
   localparam  MHPMEVENT15       = 12'h32F;
   localparam  MHPMEVENT16       = 12'h330;
   localparam  MHPMEVENT17       = 12'h331;
   localparam  MHPMEVENT18       = 12'h332;
   localparam  MHPMEVENT19       = 12'h333;
   localparam  MHPMEVENT20       = 12'h334;
   localparam  MHPMEVENT21       = 12'h335;
   localparam  MHPMEVENT22       = 12'h336;
   localparam  MHPMEVENT23       = 12'h337;
   localparam  MHPMEVENT24       = 12'h338;
   localparam  MHPMEVENT25       = 12'h339;
   localparam  MHPMEVENT26       = 12'h33A;
   localparam  MHPMEVENT27       = 12'h33B;
   localparam  MHPMEVENT28       = 12'h33C;
   localparam  MHPMEVENT29       = 12'h33D;
   localparam  MHPMEVENT30       = 12'h33E;
   localparam  MHPMEVENT31       = 12'h33F;
   
   localparam  MSCRATCH          = 12'h340;
   localparam  MEPC              = 12'h341;
   localparam  MCAUSE            = 12'h342;
   localparam  MTVAL             = 12'h343;
   localparam  MIP               = 12'h344;
      
   localparam  MPMPCFG0          = 12'h3A0;
   localparam  MPMPCFG1          = 12'h3A1;
   localparam  MPMPCFG2          = 12'h3A2;
   localparam  MPMPCFG3          = 12'h3A3;
   
   localparam  MSELECT           = 12'h7A0;
   localparam  MDATA1            = 12'h7A1;
   localparam  MDATA2            = 12'h7A2;
   localparam  MDATA3            = 12'h7A3;
   
   localparam  MDCSR             = 12'h7B0;
   localparam  MDPC              = 12'h7B1;
   localparam  MSCRATCH0         = 12'h7B2;
   localparam  MSCRATCH1         = 12'h7B3;
   
   localparam  MCYCLE_LO         = 12'hB00;
   localparam  MTIME_LO          = 12'hB01;
   localparam  MINSTRET_LO       = 12'hB02;

   localparam  MHPMCOUNTER3_LO   = 12'hB03;
   localparam  MHPMCOUNTER4_LO   = 12'hB04;
   localparam  MHPMCOUNTER5_LO   = 12'hB05;
   localparam  MHPMCOUNTER6_LO   = 12'hB06;
   localparam  MHPMCOUNTER7_LO   = 12'hB07;
   localparam  MHPMCOUNTER8_LO   = 12'hB08;
   localparam  MHPMCOUNTER9_LO   = 12'hB09;
   localparam  MHPMCOUNTER10_LO  = 12'hB0A;
   localparam  MHPMCOUNTER11_LO  = 12'hB0B;
   localparam  MHPMCOUNTER12_LO  = 12'hB0C;
   localparam  MHPMCOUNTER13_LO  = 12'hB0D;
   localparam  MHPMCOUNTER14_LO  = 12'hB0E;
   localparam  MHPMCOUNTER15_LO  = 12'hB0F;
   localparam  MHPMCOUNTER16_LO  = 12'hB10;
   localparam  MHPMCOUNTER17_LO  = 12'hB11;
   localparam  MHPMCOUNTER18_LO  = 12'hB12;
   localparam  MHPMCOUNTER19_LO  = 12'hB13;
   localparam  MHPMCOUNTER20_LO  = 12'hB14;
   localparam  MHPMCOUNTER21_LO  = 12'hB15;
   localparam  MHPMCOUNTER22_LO  = 12'hB16;
   localparam  MHPMCOUNTER23_LO  = 12'hB17;
   localparam  MHPMCOUNTER24_LO  = 12'hB18;
   localparam  MHPMCOUNTER25_LO  = 12'hB19;
   localparam  MHPMCOUNTER26_LO  = 12'hB1A;
   localparam  MHPMCOUNTER27_LO  = 12'hB1B;
   localparam  MHPMCOUNTER28_LO  = 12'hB1C;
   localparam  MHPMCOUNTER29_LO  = 12'hB1D;
   localparam  MHPMCOUNTER30_LO  = 12'hB1E;
   localparam  MHPMCOUNTER31_LO  = 12'hB1F;

   localparam  MCYCLE_HI         = 12'hB80;
   localparam  MTIME_HI          = 12'hB81;
   localparam  MINSTRET_HI       = 12'hB82;
   
   localparam  MHPMCOUNTER3_HI   = 12'hB83;
   localparam  MHPMCOUNTER4_HI   = 12'hB84;
   localparam  MHPMCOUNTER5_HI   = 12'hB85;
   localparam  MHPMCOUNTER6_HI   = 12'hB86;
   localparam  MHPMCOUNTER7_HI   = 12'hB87;
   localparam  MHPMCOUNTER8_HI   = 12'hB88;
   localparam  MHPMCOUNTER9_HI   = 12'hB89;
   localparam  MHPMCOUNTER10_HI  = 12'hB8A;
   localparam  MHPMCOUNTER11_HI  = 12'hB8B;
   localparam  MHPMCOUNTER12_HI  = 12'hB8C;
   localparam  MHPMCOUNTER13_HI  = 12'hB8D;
   localparam  MHPMCOUNTER14_HI  = 12'hB8E;
   localparam  MHPMCOUNTER15_HI  = 12'hB8F;
   localparam  MHPMCOUNTER16_HI  = 12'hB90;
   localparam  MHPMCOUNTER17_HI  = 12'hB91;
   localparam  MHPMCOUNTER18_HI  = 12'hB92;
   localparam  MHPMCOUNTER19_HI  = 12'hB93;
   localparam  MHPMCOUNTER20_HI  = 12'hB94;
   localparam  MHPMCOUNTER21_HI  = 12'hB95;
   localparam  MHPMCOUNTER22_HI  = 12'hB96;
   localparam  MHPMCOUNTER23_HI  = 12'hB97;
   localparam  MHPMCOUNTER24_HI  = 12'hB98;
   localparam  MHPMCOUNTER25_HI  = 12'hB99;
   localparam  MHPMCOUNTER26_HI  = 12'hB9A;
   localparam  MHPMCOUNTER27_HI  = 12'hB9B;
   localparam  MHPMCOUNTER28_HI  = 12'hB9C;
   localparam  MHPMCOUNTER29_HI  = 12'hB9D;
   localparam  MHPMCOUNTER30_HI  = 12'hB9E;
   localparam  MHPMCOUNTER31_HI  = 12'hB9F;

   localparam  MVENDORID         = 12'hF11;
   localparam  MARCHID           = 12'hF12;
   localparam  MIMPID            = 12'hF13;
   localparam  MHARTID           = 12'hF14;
   
   
`endif
