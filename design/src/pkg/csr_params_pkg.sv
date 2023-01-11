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
// File          :  csr_params_pkg.sv
// Description   :  parameters used by CSR's
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package csr_params_pkg;
import functions_pkg::*;
import cpu_params_pkg::*;

//   parameter SET_MCOUNTINHIBIT = 0;
//   parameter SET_MCOUNTINHIBIT_BITS = 0;

   // ================================================================== Machine Mode CSRs ==================================================================
   // "The mstatush register is not required to be implemented if every field would be hardwired to zero." riscv_privileged 1.12 draft
   // ------------------------------ Machine Status Register
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)   p. 56 riscv-privileged
   //  31        22   21  20   19   18   17    16:15 14:13 12:11 10:9  8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv, xs,   fs,   mpp,  2'b0, spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};
   //    WARNING: bits 31:13 have not been implemented yet 1/17/2021
   parameter UIE_RO_MASK            = 13'h0001;          // Read Only - value read will be INIT value for mstatus register in csr_regs.sv
   parameter UPIE_RO_MASK           = 13'h0010;
   parameter SIE_RO_MASK            = 13'h0002;          // Read Only if ext_S not defined
   parameter SPIE_RO_MASK           = 13'h0020;
   parameter SPP_RO_MASK            = 13'h0100;

   // MSTATUS Read_only masks change based on extensions needed.  Each mask bit disables writing to the bit and the read value will be the init value
   `ifdef ext_U
      `ifdef ext_N
         parameter M_UIE_RO_MASK    = 32'h0000;
         parameter M_UPIE_RO_MASK   = 32'h0000;
      `else
         parameter M_UIE_RO_MASK    = UIE_RO_MASK;       // Read Only - value read will be INIT value for mstatus register in csr_regs.sv
         parameter M_UPIE_RO_MASK   = UPIE_RO_MASK;
      `endif
   `else
      parameter M_UIE_RO_MASK       = UIE_RO_MASK;       // Read Only - value read will be INIT value for mstatus register in csr_regs.sv
      parameter M_UPIE_RO_MASK      = UPIE_RO_MASK;
   `endif

   `ifdef ext_S
      parameter M_SIE_RO_MASK       = 32'h0000;
      parameter M_SPIE_RO_MASK      = 32'h0000;
      parameter M_SPP_RO_MASK       = 32'h0000;
   `else
      parameter M_SIE_RO_MASK       = SIE_RO_MASK;       // Read Only if ext_S not defined
      parameter M_SPIE_RO_MASK      = SPIE_RO_MASK;
      parameter M_SPP_RO_MASK       = SPP_RO_MASK;
   `endif

   // In systems that do not implement S-mode and do not have a floating-point unit, the FS field is hardwired to zero. p. 26 tiscv-privileged draft-1.12
   `ifndef ext_S
      `ifndef ext_F
         parameter M_FS_RO = 32'b110_0000_0000_0000;     // fs will be hardwaired to 0 (i.e. bits 14:13 of MSTAT_INIT)
      `else
         parameter M_FS_RO = 32'h0;
      `endif
   `else
      parameter M_FS_RO = 32'h0;
   `endif


   localparam  MSTAT_INIT        = {19'd0,M_MODE,11'b0};    // init to M_MODE
   // These bits do not change based on build configuration
   // Each register bit that corresponds to MSTAT_WPTRI=1 will not change and will always output the corresponding MSTAT_INIT bits
   // Each register bit that corresponds to MSTAT_WPTRI=0 will be a FF that will be reset to corresponding MSTAT_INIT bits
   localparam  MSTAT_WPRI        = 32'h7F80_0644; // these correspond to all the bits that = 0
   // These bits can change based on build configuration (i.e. ext_S, ext_U)
   localparam  MSTAT_RO          = (M_FS_RO | M_SPP_RO_MASK | M_SPIE_RO_MASK | M_UPIE_RO_MASK | M_SIE_RO_MASK | M_UIE_RO_MASK);

   // ------------------------------ Machine ISA Register
   // 12'h301 = 12'b0011_0000_0001  misa     (read-write)   p. 56 riscv-privileged
   // currently this CSR is just a constant (all bits R0)
                  //   MXL     ZY XWVU TSRQ PONM LKJI HGFE DCBA
   parameter MISA = 32'b0100_0000_0000_0000_0000_0001_0000_0000      /* MXLEN bits = 2'b01 = RV32, and I bit -----> RV32I */
   `ifdef ext_A
                  | 32'b0000_0000_0000_0000_0000_0000_0000_0001      /* A bit - Atomic Instruction support */
   `endif
   `ifdef ext_C
                  | 32'b0000_0000_0000_0000_0000_0000_0000_0100      /* C bit - Compressed Instruction support */
   `endif
   `ifdef ext_F
                  | 32'b0000_0000_0000_0000_0000_0000_0010_0000      /* F bit - Single Precision Floating Point support */
   `endif
   `ifdef ext_M
                  | 32'b0000_0000_0000_0000_0001_0000_0000_0000      /* M bit - integer Multiply, Divide, Remainder support */
   `endif
   `ifdef ext_N
                  | 32'b0000_0000_0000_0000_0010_0000_0000_0000      /* N bit - Interrupt support */
   `endif
   `ifdef ext_S
                  | 32'b0000_0000_0000_0100_0000_0000_0000_0000      /* S bit - Supervisor mode support */
   `endif
   `ifdef ext_U
                  | 32'b0000_0000_0001_0000_0000_0000_0000_0000      /* U bit - User mode support */
   `endif
   ;//                         ZY XWVU TSRQ PONM LKJI HGFE DCBA
   localparam  MISA_INIT         = (MISA);                  // static bits for now
   localparam  MISA_RO           = 32'hFFFF_FFFF;           // each bit == 1 specifies Read Only. Currently, no logic is implemented to allow dynamic change of this register

   // example to have ext M be turned on or off
//   localparam  MISA_INIT         = MISA;                    // static bits for now
//   localparam  MISA_RO           = 32'hFFFF_EFFF;           // each bit == 1 specifies Read Only. Currently, no logic is implemented to allow dynamic change of this register

// PROBLEM: assume bits D and F are both set, but someone writes D=1 and F=0! If D is set, then F must also be set.
//          SO, do we force D=0 or force F=1 and how do we do this in a buildable/configurable way?????????????

   // MEDELEG, SEDELEG, MIDELEG, SIDELEG - init values loaded into registers upon reset. _MASK defines read only bits
   // Some exceptions cannot occur at less privileged modes, and corresponding x edeleg bits should be
   // hardwired to zero. In particular, medeleg[11] and sedeleg[11:9] are all hardwired to zero.
   // ------------------------------ Machine Exception Delegation Register
   // 12'h302 = 12'b0011_0000_0010  medeleg                 (read-write)
   parameter   MEDLG_INIT        = 32'h0000_0000;
   parameter   MEDLG_RO          = 32'h0000_0000;

   // ------------------------------ Machine Interrupt Delegation Register
   // 12'h303 = 12'b0011_0000_0011  mideleg                 (read-write)
   parameter   MIDLG_INIT        = 32'h0000_0000;
   parameter   MIDLG_RO          = 32'h0000_0000;


   // "In systems with S-mode, the medeleg and mideleg registers must exist,..." see p. 28 riscv-privileged.pdf, csr_wr_mach.svh
   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. see riscv-privileged.pdf p 28
   `ifdef ext_S
      `define MDLG
   `elsif ext_U
      `ifdef ext_N // U-mode trap supprt
         `define MDLG
      `endif
   `endif

   // ------------------------------ Machine Interrupt Enable Register
   // 12'h304 = 12'b0011_0000_0100  mie                                          (read-write)
   // only 3 bits in the actual mcsr.mie -> meie, mtie, msie


   // ------------------------------ Machine Trap Handler Base Address
   // 12'h305 = 12'b0011_0000_0101  mtvec                                        (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0. see csr_regs.sv
   // MTVEC, STVEC, UTVEC  - values loaded into registers upon reset. Note: MODE >= 2 is Reserved see p 27 risv-privileged.pdf
   parameter   MTVEC_INIT        = 32'h0000_0000;
   parameter   MTVEC_MASKED      = MTVEC_INIT & ~32'd2;
   parameter   MTVEC_RO          = 32'h2;

   // Andrew Waterman: 12/31/2020 - "There is also a clear statement that mcounteren exists if and only if U mode is implemented"
   // MCOUNTEREN, SCOUNTEREN - init values and mask values (a 1 in a bit means the corresponding reset value will always remain the same)
   // ------------------------------ Machine Counter Enable
   // 12'h306 = 12'b0011_0000_0110  mcounteren                                   (read-write)
   // Read Only Mask bits that are 1 correspond to unimplemented hpm counters) and the corresponding mcounten bits will read as 0
   parameter   MCNTEN_INIT       = 32'h0000_0000;
   parameter   MCNTEN_RO         = 32'hFFFF_FFFF << (3+NUM_MHPM);

   // ------------------------------ Machine Counter Inhibit
   // If not implemented, set all bits to 0 => no inhibits will ocur
   // 12'h320 = 12'b0011_0010_00000  mcountinhibit                               (read-write)
   // NOTE: bit 1 should always be "hardwired" to 0
   //       Setting a bit in MINHIBIT_INIT = 1 will cause mcountinhibit to be a constant (Read Only) with bits defined by SET_MCOUNTINHIBIT_BITS
   parameter   MINHIBIT_INIT     = 32'h0000_0000;
   parameter   MINHIBIT_RO       = 32'h2;
   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
   // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                                (read-write)
   parameter   NUM_EVENTS        = 24;                                                 // Number of event selectors to use. See EV_SEL_SZ below, then csr_mhpmevent[], and events[] in csr_wr_mach.sv
   localparam  EV_SEL_SZ         = bit_size(NUM_EVENTS-1);                             // Number of bits to hold values from 0 through NUM_EVENTS-1
   localparam  EV_SEL_MASK       = {EV_SEL_SZ{1'b1}};                                  // EV_SEL_SZ is always >= 1

   // ------------------------------ Machine Scratch Register
   // 12'h340 = 12'b0011_0100_0000  mscratch                                     (read-write)
   parameter   MSCRATCH_INIT     = 32'h0;
   parameter   MSCRATCH_RO       = 32'h0;

   // ------------------------------ Machine Exception Program Counter
   // Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  mepc                                         (read-write)   see riscv-privileged p 36


   // ------------------------------ Machine Exception Cause
   // 12'h342 = 12'b0011_0100_0010  mcause                                       (read-write)
   parameter   MCS_INIT          = 32'h0000_0000;  // When a trap is taken into M-mode, mcause is written with a code indicating the event that caused the trap.p 37 riscv-privileged draft1.12


   // ------------------------------ Machine Exception Trap Value
   // 12'h343 = 12'b0011_0100_0011  mtval                                        (read-write)


   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  mip                                          (read-write)  machine mode
   // only 3 bits in the actual mcsr.mip -> meip, mtip, msip


   // ------------------------------ Machine Protection and Translation
   // 12'h3A0 - 12'h3A3
   // NOTE: The following PMP related logic is NOT IMPLEMENTED YET !!!!
// `define     USE_PMPCFG           // CSR: comment this line out if you don't want logic for pmpcfg0-3 registers. see csr_wr_mach.sv and csr_rd_mach.svh
// `define     PMP_ADDR0            //      tell code to generate pmpaddr0, pmpaddr9 and pmpaddr15 registers
// `define     PMP_ADDR9
// `define     PMP_ADDR15


   // ------------------------------  Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)


   // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
   // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf


   // ------------------------------ Machine Cycle Counter
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // mhpmcountern, respectively. p 34 risvcv-privileged.pdf


   // ------------------------------ Machine Instructions-Retired Counter
   // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
   // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf
   parameter   MINSTRET_LO_INIT  = 32'h0;
   parameter   MINSTRET_LO_RO    = 32'h0;
   parameter   MINSTRET_HI_INIT  = 32'h0;
   parameter   MINSTRET_HI_RO    = 32'h0;

   // ------------------------------ Machine Performance-Monitoring Counters
   // Lower 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
   // 12'hB03 - 12'hB1F  mhpmcounter3 - mhpmcounter31                            (read-write)
   //
   // Upper 32 bits of mhpmcounter3 - mhpmcounter31, RV32I only.
   // 12'hB83 - 12'hB9F mhpmcounter3h - mhpmcounter31h                           (read-write)

   // ------------------------------ Machine Information Registers
   // Vendor ID
   // 12'hF11 = 12'b1111_0001_0001  mvendorid                                    (read-only)
   parameter   M_VENDOR_ID       = "KIRK";
   parameter   M_VENDOR_ID_RO    = 32'hFFFFFFFF;

   // Architecture ID
   // 12'hF12 = 12'b1111_0001_0010  marchid                                      (read-only)
   parameter   M_ARCH_ID         = "RKY1";
   parameter   M_ARCH_ID_RO      = 32'hFFFFFFFF;

   // Implementation ID
   // 12'hF13 = 12'b1111_0001_0011  mimpid                                       (read-only)
   parameter   M_IMP_ID          = 1;
   parameter   M_IMP_ID_RO       = 32'hFFFFFFFF;

   // Hardware Thread ID
   // 12'hF14 = 12'b1111_0001_0100  mhartid                                      (read-only)
   parameter   M_HART_ID         = 0;
   parameter   M_HART_ID_RO      = 32'hFFFFFFFF;

   // ================================================================== Supervisor Mode CSRs ===============================================================

   // ------------------------------ Supervisor Status Register - see p. 59-60 riscv-privileged 1.12-draft
   // The sstatus register is a subset of the mstatus register. In a straightforward implementation,
   // reading or writing any field in sstatus is equivalent to reading or writing the homonymous field
   // in mstatus
   // 12'h100 = 12'b0001_0000_0000  sstatus              (read-write)
   // 31 30:20 19    18  17   16:15   14:13   12:9 8   7    6   5    4    3:2  1   0
   // 0  0     0     0   0      0       0     0    SPP WPRI UBE SPIE UPIE WPRI SIE UIE
   //    WARNING: bits 31:8, and bit UBE have not been implemented yet 1/17/2021
   localparam  SSTAT_INIT        = 0;
   localparam  SSTAT_RO          = (SPP_RO_MASK | SPIE_RO_MASK | UPIE_RO_MASK | SIE_RO_MASK | UIE_RO_MASK);  // just bits spp, spie, upie, sie, and uie bits (8,5,4,1,0)

   // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
   // exist if the N extension for user-mode interrupts is also implemented. p 30 riscv-privileged.pdf 1.12-draft
   // ------------------------------ Supervisor Exception Delegation Register.
   // 12'h102 = 12'b0001_0000_0010  sedeleg                                      (read-write)
   parameter   SEDLG_INIT        = 32'h0000_0000;
   parameter   SEDLG_RO          = 32'h0000_0000;

   // ------------------------------ Supervisor Interrupt Delegation Register
   // 12'h103 = 12'b0001_0000_0011  sideleg                                      (read-write)
   parameter   SIDLG_INIT        = 32'h0000_0000;
   parameter   SIDLG_RO          = 32'h0000_0000;

   // ------------------------------ Supervisor Interrupt Enable Register
   // 12'h104 = 12'b0001_0000_0100  sie                                          (read-write)
   // only 3 bits in the actual scsr.sie -> seie, stie, ssie
   parameter   SIE_INIT          = 0;
   parameter   SIE_RO            = 32'hFFFF_FDDD;                                // bits 9, 5, 1 are read-write, others are read only

   // ------------------------------ Supervisor Trap handler base address
   // 12'h105 = 12'b0001_0000_0101  stvec                                        (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   parameter   STVEC_INIT        = 32'h0000_0000;
   parameter   STVEC_MASK        = STVEC_INIT & ~32'd2;
   parameter   STVEC_RO          = 32'h0000_0002;

   // 12/31/202 - Andrew Waterman "scounteren only exists if S Mode is implemented"
   // ------------------------------ Supervisor Counter Enable.
   // 12'h106 = 12'b0001_0000_0110  scounteren                                   (read-write)
   // NOTE: scounteren is always implemented. see p. 60 riscv-privileged.pdf
   parameter   SCNTEN_INIT       = 32'h0000_0000;                                // No counters are enabled at reset
   parameter   SCNTEN_RO         = 32'hFFFF_FFFF << (3+NUM_MHPM);                // Mask bits that are 1 correspond to unimplemented hpm counters) and the corresponding scounten bits will read as 0

   // ------------------------------ Supervisor Scratch Register
   // Scratch register for supervisor trap handlers.
   // 12'h140 = 12'b0001_0100_0000  sscratch                                     (read-write)
   parameter   SSCRATCH_INIT     = 32'h0;
   parameter   SSCRATCH_RO       = 32'h0;

   // ------------------------------ Supervisor Exception Program Counter
   // 12'h141 = 12'b0001_0100_0001  sepc                                         (read-write)

   // ------------------------------ Supervisor Exception Cause
   // 12'h142 = 12'b0001_0100_0010  scause                                       (read-write)

   // ------------------------------ Supervisor Exception Trap Value                       see p. 9,30,67 115 riscv-privileged.pdf 1.12-draft
   // 12'h143 = 12'b0001_0100_0011  stval                                        (read-write)

   // ------------------------------ Supervisor Interrupt Pending bits
   // 12'h144 = 12'b0001_0100_0100  sip                                          (read-write)
   // only 3 bits in the actual scsr.sip -> seip, stip, ssip

   // ------------------------------ Supervisor Protection and Translation
   // 12'h180 = 12'b0001_1000_0000  satp                                         (read-write)
   // Supervisor address translation and protection.

   // ================================================================== User Mode CSRs =====================================================================
   // ------------------------------ User Status Register- see p. 113-114 riscv-privileged 1.12-draft
   // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
   //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
   // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};
   localparam  USTAT_INIT        = 0;
   localparam  USTAT_RO          = (UPIE_RO_MASK | UIE_RO_MASK);                 // just upie and uie bits 4, 0

   // ------------------------------ User Interrupt-Enable Register
   // 12'h004 = 12'b0000_0000_0100  uie                                          (read-write)  user mode
   // only 3 bits in the actual ucsr.uie -> ueie, utie, usie


   // User Trap Handler Base address.
   // 12'h005 = 12'b0000_0000_0101  utvec                                        (read-write)  user mode
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   parameter   UTVEC_INIT        = 32'h0000_0000;

   // ------------------------------ User Trap Handling
   // Scratch register for user trap handlers.
   // 12'h040 = 12'b0000_0100_0000  uscratch                                     (read-write)


   // ------------------------------ User Exception Program Counter
   // 12'h041 = 12'b0000_0100_0001  uepc                                         (read-write)
   parameter   UEXC_PC_INIT      = 32'h0;                                        // Value loaded into register on reset

   // ------------------------------ User Exception Cause
   // 12'h042 = 12'b0000_0100_0010  ucause                                       (read-write)


   // ------------------------------ User Exception Trap Value    see p. 8,115 riscv-privileged.pdf 1.12-draft
   // 12'h043 = 12'b0000_0100_0011  utval                                        (read-write)


   // ------------------------------ User Interrupt Pending bits
   // 12'h044 = 12'b0000_0100_0100  uip                                          (read-write)
   // only 3 bits in the actual ucsr.uip -> ueip, utip, usip



endpackage