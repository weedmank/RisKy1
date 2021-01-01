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
// File          :  csr_regs.sv
// Description   :  Contains all Control & Status Registers
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_regs
(
   input    logic          clk_in,
   input    logic          reset_in,

   input    logic          ext_irq,
   input    EVENTS         current_events,

   output   logic          total_retired,
   `ifdef use_MHPM
   output   logic          emu_hpm_events[0:23],            // 24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
   `endif

   `ifdef ext_U
   `ifdef ext_N
   input    var UCSR       nxt_ucsr,                        // all of the User mode Control & Status Registers
   output   UCSR           ucsr,                            // all of the next User mode Control & Status Registers
   `endif
   `endif

   `ifdef ext_S
   input    var SCSR       nxt_scsr,                        // all of the Supervisor mode Control & Status Registers
   output   SCSR           scsr,                            // all of the next Supervisor mode Control & Status Registers
   `endif

   input    var MCSR       nxt_mcsr,                        // all of the Machine mode Control & Status Registers
   output   MCSR           mcsr                             // all of the next Machine mode Control & Status Registers
);

   // ================================================================== User Mode CSRs =====================================================================
   `ifdef ext_U
      `ifdef ext_N
      // ------------------------------ User Status Register
      // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
      //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
      // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};
      csr_ff #(USTAT_INIT,5,USTAT_MASK) Ustatus             (clk_in,reset_in, nxt_ucsr.ustatus, ucsr.ustatus); // only lower 5 bits implemented so far 12/21/2020

      `ifdef ext_F
      // ------------------------------ User Floating-Point CSRs
      // 12'h001 - 12'h003
      `endif   // ext_F

      // ------------------------------ User Interrupt-Enable Register
      // 12'h004 = 12'b0000_0000_0100  uie                  (read-write)  user mode
      csr_ff #(0,9,32'hFFFF_FEEE) Uie                       (clk_in,reset_in, nxt_ucsr.uie, ucsr.uie);

      // User Trap Handler Base address.
      // 12'h005 = 12'b0000_0000_0101  utvec                (read-write)  user mode
      // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
      csr_ff #(UTVEC_INIT,RSZ,32'h0000_0002) Utvec          (clk_in,reset_in, nxt_ucsr.utvec, ucsr.utvec);

      // ------------------------------ User Trap Handling
      // Scratch register for user trap handlers.
      // 12'h040 = 12'b0000_0100_0000  uscratch             (read-write)
      csr_ff #(0,RSZ,32'h0) Uscratch                        (clk_in,reset_in, nxt_ucsr.uscratch, ucsr.uscratch);

      // ------------------------------ User Exception Program Counter
      // 12'h041 = 12'b0000_0100_0001  uepc                 (read-write)
      csr_ff #(0,RSZ,32'h1) Uepc                            (clk_in,reset_in, nxt_ucsr.uepc, ucsr.uepc); // ls-bit is RO so it remains at 0 after reset

      // ------------------------------ User Exception Cause
      // 12'h042 = 12'b0000_0100_0010  ucause               (read-write)
      csr_ff #(0,32) Ucause                                 (clk_in,reset_in, nxt_ucsr.ucause, ucsr.ucause); // ucause is currently 4 Flops wide

      // ------------------------------ User Exception Trap Value    see riscv-privileged p. 38-39
      // 12'h043 = 12'b0000_0100_0011  utval                (read-write)
      csr_ff #(0,RSZ,32'h0) Utval                           (clk_in,reset_in, nxt_ucsr.utval, ucsr.utval);

      // ------------------------------ User Interrupt Pending bits
      // 12'h044 = 12'b0000_0100_0100  uip                  (read-write)
      //        31:10   9     8         7:6   5     4         3:2   1     0
      // uip = {22'b0, 1'b0, nxt_ueip, 2'b0, 1'b0, nxt_utip, 2'b0, 1'b0, nxt_usip};
      csr_ff #(0,9,32'hFFFF_FEEE) Uip                       (clk_in,reset_in, nxt_ucsr.uip, ucsr.uip);
      `endif // ext_N
   `endif // ext_U



   // ================================================================== Supervisor Mode CSRs ===============================================================
   `ifdef ext_S
      // ------------------------------ Supervisor Status Register
      // The sstatus register is a subset of the mstatus register. In a straightforward implementation,
      // reading or writing any field in sstatus is equivalent to reading or writing the homonymous field
      // in mstatus
      // 12'h100 = 12'b0001_0000_0000  sstatus              (read-write)
      // 31 30:20 19    18  17   16:15   14:13   12:9 8   7    6   5    4    3:2  1   0
      // SD WPRI  MXR   SUM WPRI XS[1:0] FS[1:0] WPRI SPP WPRI UBE SPIE UPIE WPRI SIE UIE
      // 1  11    1     1   1    2       2       4    1   1    1   1    1    2    1   1
      csr_ff #(SSTAT_INIT,9,32'hFFFF_FECC) Sstatus                   (clk_in,reset_in, nxt_scsr.sstatus, scsr.sstatus); // only lower 9 implemented so far 12/21/2020

      // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
      // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged
      `ifdef ext_N
         // ------------------------------ Supervisor Exception Delegation Register.
         // 12'h102 = 12'b0001_0000_0010  sedeleg           (read-write)
         csr_ff #(SEDLG_INIT,RSZ,SEDLG_MASK) Sedeleg        (clk_in,reset_in, nxt_scsr.sedeleg, scsr.sedeleg);

         // ------------------------------ Supervisor Interrupt Delegation Register.
         // 12'h103 = 12'b0001_0000_0011  sideleg           (read-write)
         csr_ff #(SIDLG_INIT,RSZ,SIDLG_MASK) Sideleg        (clk_in,reset_in, nxt_scsr.sideleg, scsr.sideleg);
      `endif // ext_N

      // ------------------------------ Supervisor Interrupt Enable Register.
      // 12'h104 = 12'b0001_0000_0100  sie                  (read-write)
      // Read Only bits of 32'hFFFF_FCCC;  // Note: bits 31:10, 7:6, 3:2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
      csr_ff #(0,RSZ,32'hFFFF_FCCC) Sie                     (clk_in,reset_in, nxt_scsr.sie, scsr.sie);

      // ------------------------------ Supervisor Trap handler base address.
      // 12'h105 = 12'b0001_0000_0101  stvec                (read-write)
      // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
      csr_ff #(STVEC_INIT & ~32'd2,RSZ,32'h0000_0002) Stvec (clk_in,reset_in, nxt_scsr.stvec, scsr.stvec);

      // 12/31/202 - Andrew Waterman "scounteren only exists if S Mode is implemented"
      // ------------------------------ Supervisor Counter Enable.
      // 12'h106 = 12'b0001_0000_0110  scounteren           (read-write)
      csr_ff #(SCNTEN_INIT,RSZ,SCNTEN_MASK) Scounteren      (clk_in,reset_in, nxt_scsr.scounteren, scsr.scounteren);

      // ------------------------------ Supervisor Scratch Register
      // Scratch register for supervisor trap handlers.
      // 12'h140 = 12'b0001_0100_0000  sscratch             (read-write)
      csr_ff #(0,RSZ) Sscratch                              (clk_in,reset_in, nxt_scsr.sscratch, scsr.sscratch);

      // ------------------------------ Supervisor Exception Program Counter
      // 12'h141 = 12'b0001_0100_0001  sepc                 (read-write)
      csr_ff #(0,RSZ,32'h1) Sepc                            (clk_in,reset_in, nxt_scsr.sepc, scsr.sepc); // ls-bit is RO so it remains at 0 after reset

      // ------------------------------ Supervisor Exception Cause
      // 12'h142 = 12'b0001_0100_0010  scause               (read-write)
      csr_ff #(0,RSZ) Scause                                (clk_in,reset_in, nxt_scsr.scause, scsr.scause);   // scause is currently 4 Flops wide

      // ------------------------------ Supervisor Exception Trap Value                       see riscv-privileged p. 38-39
      // 12'h143 = 12'b0001_0100_0011  stval                (read-write)
      csr_ff #(0,RSZ) Stval                                 (clk_in,reset_in, nxt_scsr.stval, scsr.stval);

      // ------------------------------ Supervisor Interrupt Pending bits
      // 12'h144 = 12'b0001_0100_0100  sip                  (read-write)
      //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
      // {20'b0, 1'b0, 1'b0, seip, ueip, 1'b0, 1'b0, stip, utip, 1'b0, 1'b0, ssip, usip}; // All bits besides SSIP, USIP, and UEIP in the sip register are read-only. p 59 riscv-privileged.pdf
      csr_ff #(0,RSZ,32'hFFFF_FCCC) Sip                     (clk_in,reset_in, nxt_scsr.sip, scsr.sip);

      // ------------------------------ Supervisor Protection and Translation
      // 12'h180 = 12'b0001_1000_0000  satp                 (read-write)
      // Supervisor address translation and protection.
      csr_ff #(0,RSZ) Satp                                  (clk_in,reset_in, nxt_scsr.satp, scsr.satp);
   `endif // ext_S

   // ================================================================== Machine Mode CSRs ==================================================================
   // ------------------------------ Machine Status Register
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)   p. 56 riscv-privileged
   // mie,sie,uie    - global interrupt enables
   // mpie,spie,upie - pending interrupt enables
   // mpp, spp       - previous privileged mode stacks
   //  31        22   21  20   19   18   17    16:15 14:13 12:11 10:9  8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv, xs,   fs,   mpp,  2'b0, spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};

   // register currently creates flops for bits 12:11,8,7,5,4,3,1,0
   csr_ff #(MSTAT_INIT,13,MSTAT_MASK) Mstatus               (clk_in,reset_in, nxt_mcsr.mstatus, mcsr.mstatus); // only lower 13 bits implemented 12/21/2020

   // ------------------------------ Machine ISA Register

   // currently this is just a constant (all bits R0)
   csr_ff #(MISA,RSZ,MISA_MASK) Misa                        (clk_in,reset_in, nxt_mcsr.misa, mcsr.misa);

   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28
   `ifdef MDLG // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // ------------------------------ Machine Exception Delegation Register
      // 12'h302 = 12'b0011_0000_0010  medeleg              (read-write)
      csr_ff #(MEDLG_INIT,RSZ,MEDLG_MASK) Medeleg           (clk_in,reset_in, nxt_mcsr.medeleg, mcsr.medeleg);

      // ------------------------------ Machine Interrupt Delegation Register
      // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
      csr_ff #(MIDLG_INIT,RSZ,MIDLG_MASK) Mideleg           (clk_in,reset_in, nxt_mcsr.mideleg, mcsr.mideleg);
  `endif

   // ------------------------------ Machine Interrupt Enable Register
   // 12'h304 = 12'b0011_0000_0100  mie                     (read-write)
   //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
   // {WPRI, meie, WPRI, seie, ueie, mtie, WPRI, stie, utie, msie, WPRI, ssie, usie};
   // Note: bits 31:12 are WPRI. Also bits 10,6,2 are WPRI
   csr_ff #(MIP_INIT,RSZ,MIP_MASK)  Mie                     (clk_in,reset_in, nxt_mcsr.mie, mcsr.mie);

   // ------------------------------ Machine Trap Handler Base Address
   // 12'h305 = 12'b0011_0000_0101  mtvec                   (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   csr_ff #(MTVEC_INIT & ~32'd2,RSZ,32'h2) Mtvec            (clk_in,reset_in, nxt_mcsr.mtvec, mcsr.mtvec);
   // WARNING: I force bit 1 to always be 0, but it could be that if a non legal value is written the user wants the value to go specifically to 1 or 0

   // Andrew Waterman: 12/31/2020 - "There is also a clear statement that mcounteren exists if and only if U mode is implemented"
   `ifdef ext_U
   // ------------------------------ Machine Counter Enable
   // 12'h306 = 12'b0011_0000_0110  mcounteren              (read-write)
   csr_ff #(MCNTEN_INIT,RSZ,MCNTEN_MASK) Mcounteren         (clk_in,reset_in, nxt_mcsr.mcounteren, mcsr.mcounteren);
   `endif

   // ------------------------------ Machine Counter Inhibit
   // If not implemented, set all bits to 0 => no inhibits will ocur
   // 12'h320 = 12'b0011_0010_00000  mcountinhibit          (read-write)
   // NOTE: bit 1 always "hardwired" to 0
   csr_ff #(MINHIBIT_INIT,RSZ,32'h0000_0002) Mcountinhibit  (clk_in,reset_in, nxt_mcsr.mcountinhibit, mcsr.mcountinhibit);

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
   // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31           (read-write)
   `ifdef use_MHPM
   genvar m;
   generate
      for (m = 0; m < NUM_MHPM; m++)
      begin
         // Note: width of mhpmevent[] is define as 5 bits - up to 32 different event selections
         csr_ff #(0,EV_SEL_SZ) Mhpmevent                    (clk_in,reset_in, nxt_mcsr.mhpmevent[m], mcsr.mhpmevent[m]);
      end
   endgenerate
   `endif

   // ------------------------------ Machine Scratch Register
   // 12'h340 = 12'b0011_0100_0000  mscratch                (read-write)
   csr_ff #(0,RSZ) Mscratch                                 (clk_in,reset_in, nxt_mcsr.mscratch, mcsr.mscratch);

   // ------------------------------ Machine Exception Program Counter
   // Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  mepc                    (read-write)   see riscv-privileged p 36
   csr_ff #(0,PC_SZ,32'h1) Mepc                             (clk_in,reset_in, nxt_mcsr.mepc, mcsr.mepc);    // LSbit always remains at 0 (reset init value) p. 36 riscv-privileged

   // ------------------------------ Machine Exception Cause
   // 12'h342 = 12'b0011_0100_0010  mcause                  (read-write)
   csr_ff #(MCS_INIT,RSZ) Mcause                            (clk_in,reset_in, nxt_mcsr.mcause, mcsr.mcause);

   // ------------------------------ Machine Exception Trap Value
   // 12'h343 = 12'b0011_0100_0011  mtval                   (read-write)
   csr_ff #(0,RSZ) Mtval                                    (clk_in,reset_in, nxt_mcsr.mtval, mcsr.mtval);

   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  mip                     (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meip, 1'b0, seip, ueip, mtip, 1'b0, stip, utip, msip, 1'b0, ssip, usip};
   csr_ff #(MIP_INIT,RSZ,MIP_MASK) Mip                      (clk_in,reset_in, nxt_mcsr.mip, mcsr.mip);


   // ------------------------------ Machine Protection and Translation
   // 12'h3A0 - 12'h3A3
   `ifdef USE_PMPCFG
      // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0              (read-write)
      csr_ff #(0,RSZ) Mpmpcfg0                              (clk_in,reset_in, nxt_mcsr.pmpcfg0, mcsr.pmpcfg0);
      // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1              (read-write)
      csr_ff #(0,RSZ) Mpmpcfg1                              (clk_in,reset_in, nxt_mcsr.pmpcfg1, mcsr.pmpcfg1);
      // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2              (read-write)
      csr_ff #(0,RSZ) Mpmpcfg2                              (clk_in,reset_in, nxt_mcsr.pmpcfg2, mcsr.pmpcfg2);
      // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3              (read-write)
      csr_ff #(0,RSZ) Mpmpcfg3                              (clk_in,reset_in, nxt_mcsr.pmpcfg3, mcsr.pmpcfg3);
   `endif

   // 12'h3B0 - 12'h3BF
   // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
   `ifdef PMP_ADDR0  csr_ff #(0,RSZ) Mpmpaddr0              (clk_in,reset_in, nxt_mcsr.pmpaddr0,  mcsr.pmpaddr0);    `endif
   `ifdef PMP_ADDR1  csr_ff #(0,RSZ) Mpmpaddr1              (clk_in,reset_in, nxt_mcsr.pmpaddr1,  mcsr.pmpaddr1);    `endif
   `ifdef PMP_ADDR2  csr_ff #(0,RSZ) Mpmpaddr2              (clk_in,reset_in, nxt_mcsr.pmpaddr2,  mcsr.pmpaddr2);    `endif
   `ifdef PMP_ADDR3  csr_ff #(0,RSZ) Mpmpaddr3              (clk_in,reset_in, nxt_mcsr.pmpaddr3,  mcsr.pmpaddr3);    `endif
   `ifdef PMP_ADDR4  csr_ff #(0,RSZ) Mpmpaddr4              (clk_in,reset_in, nxt_mcsr.pmpaddr4,  mcsr.pmpaddr4);    `endif
   `ifdef PMP_ADDR5  csr_ff #(0,RSZ) Mpmpaddr5              (clk_in,reset_in, nxt_mcsr.pmpaddr5,  mcsr.pmpaddr5);    `endif
   `ifdef PMP_ADDR6  csr_ff #(0,RSZ) Mpmpaddr6              (clk_in,reset_in, nxt_mcsr.pmpaddr6,  mcsr.pmpaddr6);    `endif
   `ifdef PMP_ADDR7  csr_ff #(0,RSZ) Mpmpaddr7              (clk_in,reset_in, nxt_mcsr.pmpaddr7,  mcsr.pmpaddr7);    `endif
   `ifdef PMP_ADDR8  csr_ff #(0,RSZ) Mpmpaddr8              (clk_in,reset_in, nxt_mcsr.pmpaddr8,  mcsr.pmpaddr8);    `endif
   `ifdef PMP_ADDR9  csr_ff #(0,RSZ) Mpmpaddr9              (clk_in,reset_in, nxt_mcsr.pmpaddr9,  mcsr.pmpaddr9);    `endif
   `ifdef PMP_ADDR10 csr_ff #(0,RSZ) Mpmpaddr10             (clk_in,reset_in, nxt_mcsr.pmpaddr10, mcsr.pmpaddr10);   `endif
   `ifdef PMP_ADDR11 csr_ff #(0,RSZ) Mpmpaddr11             (clk_in,reset_in, nxt_mcsr.pmpaddr11, mcsr.pmpaddr11);   `endif
   `ifdef PMP_ADDR12 csr_ff #(0,RSZ) Mpmpaddr12             (clk_in,reset_in, nxt_mcsr.pmpaddr12, mcsr.pmpaddr12);   `endif
   `ifdef PMP_ADDR13 csr_ff #(0,RSZ) Mpmpaddr13             (clk_in,reset_in, nxt_mcsr.pmpaddr13, mcsr.pmpaddr13);   `endif
   `ifdef PMP_ADDR14 csr_ff #(0,RSZ) Mpmpaddr14             (clk_in,reset_in, nxt_mcsr.pmpaddr14, mcsr.pmpaddr14);   `endif
   `ifdef PMP_ADDR15 csr_ff #(0,RSZ) Mpmpaddr15             (clk_in,reset_in, nxt_mcsr.pmpaddr15, mcsr.pmpaddr15);   `endif

   `ifdef add_DM
   // ------------------------------  Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
   csr_ff #(0,RSZ) Mtsel                                    (clk_in,reset_in, nxt_mcsr.tselect, mcsr.tselect);          // Trigger Select Register
   csr_ff #(0,RSZ) Mtdr1                                    (clk_in,reset_in, nxt_mcsr.tdata1,  mcsr.tdata1);           // Trigger Data Register 1
   csr_ff #(0,RSZ) Mtdr2                                    (clk_in,reset_in, nxt_mcsr.tdata2,  mcsr.tdata2);           // Trigger Data Register 2
   csr_ff #(0,RSZ) Mtdr3                                    (clk_in,reset_in, nxt_mcsr.tdata3,  mcsr.tdata3);           // Trigger Data Register 3

   // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
   // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
   csr_ff #(0,RSZ) Mdcsr                                    (clk_in,reset_in, nxt_mcsr.dcsr,      mcsr.dcsr);           // Debug Control and Status Register
   csr_ff #(0,RSZ) Mdpc                                     (clk_in,reset_in, nxt_mcsr.dpc,       mcsr.dpc);            // Debug PC Register
   csr_ff #(0,RSZ) Mdsr0                                    (clk_in,reset_in, nxt_mcsr.dscratch0, mcsr.dscratch0);      // Debug Scratch Register 0
   csr_ff #(0,RSZ) Mdsr1                                    (clk_in,reset_in, nxt_mcsr.dscratch1, mcsr.dscratch1);      // Debug Scratch Register 1
   `endif // add_DM

   // ------------------------------ Machine Cycle Counter
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // mhpmcountern, respectively. p 34 risvcv-privileged.pdf
   csr_ff #(0,RSZ) Mcycle_lo                                (clk_in,reset_in, nxt_mcsr.mcycle_lo, mcsr.mcycle_lo);      // Timer Lower 32 bits
   csr_ff #(0,RSZ) Mcycle_hi                                (clk_in,reset_in, nxt_mcsr.mcycle_hi, mcsr.mcycle_hi);      // Timer Higher 32 bits


   // ------------------------------ Machine Instructions-Retired Counter
   // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
   // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf

   csr_ff #(0,RSZ) Minstret_lo                              (clk_in,reset_in, nxt_mcsr.minstret_lo, mcsr.minstret_lo);  // Timer Lower 32 bits
   csr_ff #(0,RSZ) Minstret_hi                              (clk_in,reset_in, nxt_mcsr.minstret_hi, mcsr.minstret_hi);  // Timer Higher 32 bits

   // ------------------------------ Machine Performance-Monitoring Counters
   // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
   // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31     (read-write)
   //
   // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
   // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h   (read-write)
   `ifdef use_MHPM
   genvar n;
   generate
      for (n = 0; n < NUM_MHPM; n++)
      begin : MHPM_CNTRS
         csr_ff #(0,RSZ) Mmhpmcounter_lo                    (clk_in,reset_in, nxt_mcsr.mhpmcounter_lo[n], mcsr.mhpmcounter_lo[n]);  // Lower 32 bits
         csr_ff #(0,RSZ) Mmhpmcounter_hi                    (clk_in,reset_in, nxt_mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_hi[n]);  // Higher 32 bits
      end
   endgenerate
   `endif

   // ------------------------------ Machine Information Registers
   // Vendor ID
   // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
   assign mcsr.mvendorid   = nxt_mcsr.mvendorid;

   // Architecture ID
   // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
   assign mcsr.marchid     = nxt_mcsr.marchid;

   // Implementation ID
   // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
   assign mcsr.mimpid      = nxt_mcsr.mimpid;

   // Hardware Thread ID
   // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
   assign mcsr.mhartid     = nxt_mcsr.mhartid;


   // Machine instructions-retired counter.
   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
    // At most, for this pipelined design, only 1 instruction can retire per clock so just OR the retire bits (instead of adding)
   assign total_retired    = current_events.ret_cnt[LD_RET]  | current_events.ret_cnt[ST_RET]   | current_events.ret_cnt[CSR_RET]  | current_events.ret_cnt[SYS_RET]  |
                             current_events.ret_cnt[ALU_RET] | current_events.ret_cnt[BXX_RET]  | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET] |
                             current_events.ret_cnt[IM_RET]  | current_events.ret_cnt[ID_RET]   | current_events.ret_cnt[IR_RET]   | current_events.ret_cnt[HINT_RET] |
               `ifdef ext_F  current_events.ret_cnt[FLD_RET] | current_events.ret_cnt[FST_RET]  | current_events.ret_cnt[FP_RET]   | `endif
                             current_events.ret_cnt[UNK_RET];

   // Just assign the hpm_events that will be used and comment those that are not used. Also adjust the number (i.e. 24 right now)
   `ifdef use_MHPM
   logic             br_cnt;
   logic             misaligned_cnt;

   assign br_cnt           = current_events.ret_cnt[BXX_RET] | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET];
   assign misaligned_cnt   = (current_events.e_flag & (current_events.e_cause == 0)) |  /* 0 = Instruction Address Misaligned */
                             (current_events.e_flag & (current_events.e_cause == 4)) |  /* 4 = Load Address Misaligned        */
                             (current_events.e_flag & (current_events.e_cause == 6));   /* 6 = Store Address Misaligned       */

   assign hpm_events[0 ]   = 0;                                      // no change to mhpm counter when this even selected
   // The following hpm_events return a count value which is used by a mhpmcounter[]. mhpmcounter[n] can use whichever event[x] it wants by setting mphmevent[n]
   // The count sources (i.e. current_events.ret_cnt[LD_RET]) may be changed by the user to reflect what information they want to use for a given counter.
   // Any of the logic on the RH side of the assignment can changed or used for any hpm_events[x] - even new logic can be created for a new event source.
   assign hpm_events[1 ]   = current_events.ret_cnt[LD_RET];         // Load Instruction retirement count. See ret_cnt[] in cpu_structs_pkg.sv. One ret_cnt for each instruction type.
   assign hpm_events[2 ]   = current_events.ret_cnt[ST_RET];         // Store Instruction retirement count.
   assign hpm_events[3 ]   = current_events.ret_cnt[CSR_RET];        // CSR
   assign hpm_events[4 ]   = current_events.ret_cnt[SYS_RET];        // System
   assign hpm_events[5 ]   = current_events.ret_cnt[ALU_RET];        // ALU
   assign hpm_events[6 ]   = current_events.ret_cnt[BXX_RET];        // BXX
   assign hpm_events[7 ]   = current_events.ret_cnt[JAL_RET];        // JAL
   assign hpm_events[8 ]   = current_events.ret_cnt[JALR_RET];       // JALR
   assign hpm_events[9 ]   = current_events.ret_cnt[IM_RET];         // Integer Multiply
   assign hpm_events[10]   = current_events.ret_cnt[ID_RET];         // Integer Divide
   assign hpm_events[11]   = current_events.ret_cnt[IR_RET];         // Integer Remainder
   assign hpm_events[12]   = current_events.ret_cnt[HINT_RET];       // Hint Instructions
   assign hpm_events[13]   = current_events.ret_cnt[UNK_RET];        // Unknown Instructions
   assign hpm_events[14]   = current_events.e_flag ? (current_events.e_cause == 0) : 0; // e_cause = 0 = Instruction Address Misaligned
   assign hpm_events[15]   = current_events.e_flag ? (current_events.e_cause == 1) : 0; // e_cause = 1 = Instruction Access Fault
   assign hpm_events[16]   = current_events.e_flag ? (current_events.e_cause == 2) : 0; // e_cause = 2 = Illegal Instruction
   assign hpm_events[17]   = br_cnt;                                 // all bxx, jal, jalr instructions
   assign hpm_events[18]   = misaligned_cnt;                         // all misaligned instructions
   assign hpm_events[19]   = total_retired;                          // total of all instructions retired this clock cycle
   `ifdef ext_F
   assign hpm_events[20]   = current_events.ret_cnt[FLD_RET];        // single precision Floating Point Load retired
   assign hpm_events[21]   = current_events.ret_cnt[FST_RET];        // single precision Floating Point Store retired
   assign hpm_events[22]   = current_events.ret_cnt[FP_RET];         // single precision Floating Point operation retired
   assign hpm_events[23]   = current_events.ext_irq;                 // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
   `else
   assign hpm_events[20]   = current_events.e_flag ? (current_events.e_cause == 3) : 0; // e_cause = 3 = Environment Break
   assign hpm_events[21]   = current_events.e_flag ? (current_events.e_cause == 6) : 0; // e_cause = 6 = Store Address Misaligned
   assign hpm_events[22]   = current_events.e_flag ? (current_events.e_cause == 8) : 0; // e_cause = 8 = User ECALL
   assign hpm_events[23]   = current_events.ext_irq;                 // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
   `endif // uxt_F
   `endif

   // Note: currently there are NUM_EVENTS hpm_events as specified at the beginning of this generate block. The number can be changed if more or less event types are needed


endmodule