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
// File          :  csr_regs.svh
// Description   :  Contains the Control & Status Registers names.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // note: check sizes of the following csr registers to see if they could be less than RSZ bits in some cases...
   // Machine mode Registers
   logic               [RSZ-1:0] csr_mstatus;         // 12'h300           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_misa;            // 12'h301           see csr_wr_mach.svh, csr_rd_mach.svh

   `ifdef ext_S   // // "In systems with S-mode, the medeleg and mideleg registers must exist,..." see p. 28 riscv-privileged.pdf, csr_wr_mach.svh
   logic               [RSZ-1:0] csr_medeleg;         // 12'h302           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mideleg;         // 12'h303           see csr_wr_mach.svh, csr_rd_mach.svh
   `else // !ext_S
      `ifdef ext_U
      `ifdef ext_N
      logic            [RSZ-1:0] csr_medeleg;         // 12'h302           see csr_wr_mach.svh, csr_rd_mach.svh
      logic            [RSZ-1:0] csr_mideleg;         // 12'h303           see csr_wr_mach.svh, csr_rd_mach.svh
      `endif
      `endif
   `endif
   logic               [RSZ-1:0] csr_mie;             // 12'h304           see csr_wr_mach.svh, csr_rd_mach.svh   ??? READ ONLY ????
   logic               [RSZ-1:0] csr_mtvec;           // 12'h305           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mcounteren;      // 12'h306           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mcountinhibit;   // 12'h320           see csr_wr_mach.svh, csr_rd_mach.svh
   `ifdef use_MHPM
   logic    [NUM_MHPM-1:0] [3:0] csr_mhpmevent;       // 12'h323-'h33F     see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   logic               [RSZ-1:0] csr_mscratch;        // 12'h340           see csr_wr_mach.svh, csr_rd_mach.svh
   logic             [PC_SZ-1:0] csr_mepc;            // 12'h341           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mcause;          // 12'h342           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mtval;           // 12'h343           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mip;             // 12'h344           see csr_wr_mach.svh, csr_rd_mach.svh
   `ifdef USE_PMPCFG
   logic               [RSZ-1:0] csr_pmpcfg0;         // 12'h3A0           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_pmpcfg1;         // 12'h3A1           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_pmpcfg2;         // 12'h3A2           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_pmpcfg3;         // 12'h3A3           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR0
   logic               [RSZ-1:0] csr_pmpaddr0;        // 12'h3B0           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR0
   logic               [RSZ-1:0] csr_pmpaddr0;        // 12'h3B0           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR1
   logic               [RSZ-1:0] csr_pmpaddr1;        // 12'h3B1           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR2
   logic               [RSZ-1:0] csr_pmpaddr2;        // 12'h3B2           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR3
   logic               [RSZ-1:0] csr_pmpaddr3;        // 12'h3B3           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR4
   logic               [RSZ-1:0] csr_pmpaddr4;        // 12'h3B4           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR5
   logic               [RSZ-1:0] csr_pmpaddr5;        // 12'h3B5           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR6
   logic               [RSZ-1:0] csr_pmpaddr6;        // 12'h3B6           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR7
   logic               [RSZ-1:0] csr_pmpaddr7;        // 12'h3B7           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR8
   logic               [RSZ-1:0] csr_pmpaddr8;        // 12'h3B8           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR9
   logic               [RSZ-1:0] csr_pmpaddr9;        // 12'h3B9           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR10
   logic               [RSZ-1:0] csr_pmpaddr10;       // 12'h3BA           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR11
   logic               [RSZ-1:0] csr_pmpaddr11;       // 12'h3BB           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR12
   logic               [RSZ-1:0] csr_pmpaddr12;       // 12'h3BC           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR13
   logic               [RSZ-1:0] csr_pmpaddr13;       // 12'h3BD           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR14
   logic               [RSZ-1:0] csr_pmpaddr14;       // 12'h3BE           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef PMP_ADDR15
   logic               [RSZ-1:0] csr_pmpaddr15;       // 12'h3BF           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   `ifdef add_DM
   logic               [RSZ-1:0] csr_tselect;         // 12'h7A0           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_tdata1;          // 12'h7A1           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_tdata2;          // 12'h7A2           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_tdata3;          // 12'h7A3           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_dcsr;            // 12'h7B0           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_dpc;             // 12'h7B1           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_dscratch0;       // 12'h7B2           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_dscratch1;       // 12'h7B3           see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   logic               [RSZ-1:0] csr_mcycle_lo;       // 12'hB00           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_minstret_lo;     // 12'hB02           see csr_wr_mach.svh, csr_rd_mach.svh
   `ifdef use_MHPM
   logic [NUM_MHPM-1:0][RSZ-1:0] csr_mhpmcounter_lo;  // 12'hB03 - 12'hB1F see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   logic               [RSZ-1:0] csr_mcycle_hi;       // 12'hB80           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_minstret_hi;     // 12'hB82           see csr_wr_mach.svh, csr_rd_mach.svh
   `ifdef use_MHPM
   logic [NUM_MHPM-1:0][RSZ-1:0] csr_mhpmcounter_hi;  // 12'hB83 - 12'hB9F see csr_wr_mach.svh, csr_rd_mach.svh
   `endif
   logic               [RSZ-1:0] csr_mvendorid;       // 12'hF11           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_marchid;         // 12'hF12           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mimpid;          // 12'hF13           see csr_wr_mach.svh, csr_rd_mach.svh
   logic               [RSZ-1:0] csr_mhartid;         // 12'hF14           see csr_wr_mach.svh, csr_rd_mach.svh

   // Supervisor mode Registers
   `ifdef ext_S
   logic               [RSZ-1:0] csr_sstatus;         // 12'h100           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_sedeleg;         // 12'h102           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_sideleg;         // 12'h103           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_sie;             // 12'h104           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_stvec;           // 12'h105           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_scounteren;      // 12'h106           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_sscratch;        // 12'h140           see csr_wr_super.svh, csr_rd_super.svh
   logic             [PC_SZ-1:0] csr_sepc;            // 12'h141           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_scause;          // 12'h142           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_stval;           // 12'h143           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_sip;             // 12'h144           see csr_wr_super.svh, csr_rd_super.svh
   logic               [RSZ-1:0] csr_satp;            // 12'h180           see csr_wr_super.svh, csr_rd_super.svh
   `endif

   // User mode Registers
   `ifdef ext_U
   logic               [RSZ-1:0] csr_ustatus;         // 12'h000           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_uie;             // 12'h004           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_utvec;           // 12'h005           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_uscratch;        // 12'h040           see csr_wr_user.svh, csr_rd_user.svh
   logic             [PC_SZ-1:0] csr_uepc;            // 12'h041           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_ucause;          // 12'h042           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_utval;           // 12'h043           see csr_wr_user.svh, csr_rd_user.svh
   logic               [RSZ-1:0] csr_uip;             // 12'h044           see csr_wr_user.svh, csr_rd_user.svh
   `endif
