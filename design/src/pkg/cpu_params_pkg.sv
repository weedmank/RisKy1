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
// File          :  cpu_params_pkg.sv
// Description   :  parameters used in various modules
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package cpu_params_pkg;
import functions_pkg::*;

   `ifndef ext_S
   `ifndef ext_U
   `define M_MODE_ONLY
   `endif
   `endif


   // The following M_xxxx are used in csr_wr_mach.svh and should be set by the user to a 32 bit value
   parameter   M_VENDOR_ID = "KIRK";
   parameter   M_ARCH_ID   = "RKY1";
   parameter   M_IMP_ID    = 1;
   parameter   M_HART_ID   = 0;

   parameter   PC_SZ       = 32;                                     // Program Counter address size
   parameter   MAX_RAS     = 8;                                      // Size of the Return Address Stack (RAS) - number does not have to be a power of 2 - see fetch.sv

   // Note: Physical Memory is declared to be very small right now to keep simulation speed at a maximum.  The larger the memory the slower the simulation will be.
   // 8K of Physical Memory - This space should include both Instruction Space & Data Space
   parameter   Phys_Depth           = 8192;
   parameter   Phys_Addr_Lo         = 32'h0000_0000;                 // first byte address of Physical RAM Memory space
   localparam  Phys_Addr_Hi         = Phys_Addr_Lo + Phys_Depth - 1; // last  byte address of Physical RAM memory space

   // NOTE: Illegal Address Access exception generated for addresses not in the Physical Address range, or in the Internal I/O rnage or External I/O range.
   // Internal I/O access range - see mem_io.sv
   parameter   Int_IO_Addr_Lo       = 32'h0200_0000;                 // first byte address of Internal Memory Mapped I/O Devices space
   parameter   Int_IO_Addr_Hi       = 32'h02FF_FFFF;                 // last  byte address of Internal Memory Mapped I/O Devices space

   // Internal Memory Mapped I/O - see mem_io.sv.  These addresses must be within Int_IO_Addr_Lo and Int_IO_Addr_Hi address range
   parameter   MSIP_Base_Addr       = 32'h0200_0000;
   parameter   MTIME_Base_Addr      = 32'h0200_1000;
   parameter   MTIMECMP_Base_Addr   = 32'h0200_2000;

   // External I/O Memory access range
   parameter   Ext_IO_Addr_Lo       = 32'h0300_0000;
   parameter   Ext_IO_Addr_Hi       = 32'h0300_FFFF;

   // lower 4K of Physical Memory is Instruction Space in this setup, so use upper 4K (of the 8K Physical Memory) for Data Space
   parameter   Instr_Depth          = 4096;                          // size of area covered by L1 I$, starting at L1_IC_LO
   parameter   L1_IC_Lo             = Phys_Addr_Lo;                  // L1_icache.sv:     beginning of L1 I$ space
   localparam  L1_IC_Hi             = L1_IC_Lo+Instr_Depth-1;        // L1_icache.sv:     end of L1 I$ space

   // Simulation: signal sim_stop is used in simulation to know when a program has finished. A testbench can monitor this to know when to stop simulation
   parameter   Sim_Stop_Addr        = 32'hFFFF_FFF0;                 // writing (Store) to this address will assert the sim_stop signal from RisKy1_core - make sure this address doesn't interfere with any other address

   // Power-up Reset Vector
   parameter   RESET_VECTOR_ADDR    = Phys_Addr_Lo;                  // Can be any address. Doesn't have to be Phys_Addr_Lo.  However, RESET_VECTOR_ADDR must be inside the Phys_Addr_xx range. See fetch.sv

   // MEDELEG, SEDELEG, MIDELEG, SIDELEG - init values loaded into registers upon reset. _MASK defines read only bits
   // Some exceptions cannot occur at less privileged modes, and corresponding x edeleg bits should be
   // hardwired to zero. In particular, medeleg[11] and sedeleg[11:9] are all hardwired to zero.
   parameter   MEDLG_INIT           = 32'h0000_0000;
   parameter   MEDLG_MASK           = 32'h0000_0000;
   parameter   MIDLG_INIT           = 32'h0000_0000;
   parameter   MIDLG_MASK           = 32'h0000_0000;
   parameter   SEDLG_INIT           = 32'h0000_0000;
   parameter   SEDLG_MASK           = 32'h0000_0000;
   parameter   SIDLG_INIT           = 32'h0000_0000;
   parameter   SIDLG_MASK           = 32'h0000_0000;
   
   // MTVEC, STVEC, UTVEC  - values loaded into registers upon reset. Note: MODE >= 2 is Reserved see p 27 risv-privileged.pdf
   parameter   MTVEC_INIT           = 32'h0000_0000;
   parameter   STVEC_INIT           = 32'h0000_0000;
   parameter   UTVEC_INIT           = 32'h0000_0000;
   
   // MCOUNTEREN, SCOUNTEREN - init values and mask values (a 1 in a bit means the corresponding reset value will always remain the same)
   parameter   MCNTEN_INIT          = 32'h0000_0000;
   parameter   MCNTEN_MASK          = 32'h0000_0000;                 // all bits are writable
   parameter   SCNTEN_INIT          = 32'h0000_0000; 
   parameter   SCNTEN_MASK          = 32'h0000_0000;                 // all bits are writable
   
//   parameter   WFI_IS_NOP           = TRUE;
   
   parameter   NUM_MHPM = 0;                                         // CSR: number of mhpmcounter's and mhpmevent's, where first one starts at mphmcounter3 if NUM_MHPM > 0
   // NOTE: Max NUM_MHPM is 29

   parameter   NUM_EVENTS = 24;                                      // Number of event selectors to use. See EV_SEL_SZ below, then csr_mhpmevent[], and events[] in csr_wr_mach.sv

   parameter   SET_MCOUNTINHIBIT = 0;                                // CSR: setting this to 1 will cause mcountinhibit to be a constant (Read Only) with bits defined by SET_MCOUNTINHIBIT_BITS
   parameter   SET_MCOUNTINHIBIT_BITS = 32'h0000_0000;

   // NOTE: The following PMP related logic is NOT IMPLEMENTED YET !!!!
// `define     USE_PMPCFG                                            // CSR: comment this line out if you don't want logic for pmpcfg0-3 registers. see csr_wr_mach.sv and csr_rd_mach.svh
// `define     PMP_ADDR0                                             //      tell code to generate pmpaddr0, pmpaddr9 and pmpaddr15 registers
// `define     PMP_ADDR9
// `define     PMP_ADDR15

// `define     MM_MSIP                                               // create a memory mapped register for the MSIP bit of CSR MIP register

   // parameters related to Memory, L1 D$ and L1 I$
   parameter   CL_LEN   = 32; // cache line length in bytes

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

   parameter   MISA_MASK = 32'hFFFF_FFFF; // each bit == 1 specifies Read Only. Currently, no logic is implemented to allow dynamic change of this register
   
// Options to add user enabled HINTs and RESERVEs.  See decode_core.sv
// Logic related to each specific hint will need to be decoded and added to file execute.sv
// Example: if "`define H_C_NOP" line below is uncommented then the C.NOP related HINT logic (in decode_core.sv) will be included during the RTL compile. The user will
// then need to add all the necessary logic for the new instruction in the cpu design.

// `define     H_C_NOP
// `define     H_C_ADDI
// `define     H_C_LI
// `define     H_C_LUI
// `define     H_C_SRLI
// `define     H_C_SRLI2
// `define     H_C_SRAI
// `define     H_C_SRAI2
// `define     H_C_SLLI
// `define     H_C_SLLI2
// `define     H_C_MV
// `define     H_C_ADD

// `define     H_ADDI
// `define     H_SLLI
// `define     H_SLTI
// `define     H_SLTIU
// `define     H_XORI
// `define     H_SRLI
// `define     H_SRAI
// `define     H_ORI
// `define     H_ANDI
// `define     H_AUIPC
// `define     R_ADD
// `define     R_SLL
// `define     R_SLT
// `define     R_SLTU
// `define     R_XOR
// `define     R_SRL
// `define     R_OR
// `define     R_AND
// `define     R_SUB
// `define     R_SRA
// `define     H_LUI

   //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   //!!!      WARNING: The localparams below are not intended to be user modified      !!!!
   //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   parameter   M_MODE      = 2'b11;                                  // Machine Mode
   parameter   S_MODE      = 2'b01;                                  // Supervisor Mode
   parameter   U_MODE      = 2'b00;                                  // User Mode

   `ifdef ext_C
   parameter   is_IALIGN16 = 1'b1;                                   // 16 bit instruction alignment
   `else
   parameter   is_IALIGN16 = 1'b0;                                   // 32 bit instruction alignment
   `endif

   localparam  XLEN        = 6'd32;                                  // instruction word width
   localparam  CI_SZ       = 5'd16;                                  // compressed instruction word width
   localparam  RSZ         = XLEN;                                   // General Purpose Register width
   localparam  MAX_GPR     = 32;                                     // maximum number of CPU General Purpose Registers
   localparam  MAX_CSR     = 4096;                                   // maximum number of CSR Registers

   localparam  FLEN        = 32;
   localparam  MAX_FPR     = 32;                                     // maximum number of CPU Single Precision Floating Point Registers

   localparam  EV_SEL_SZ   = bit_size(NUM_EVENTS-1);                 // Number of bits to hold values from 0 through NUM_EVENTS-1
   localparam  EV_SEL_MASK = {EV_SEL_SZ{1'b1}};                      // EV_SEL_SZ is always >= 1

   localparam  GPR_ASZ     = bit_size(MAX_GPR-1);
   localparam  FPR_ASZ     = bit_size(MAX_FPR-1);
   localparam  CSR_ASZ     = bit_size(MAX_CSR-1);

   localparam  BPI         = XLEN/8;                                 // 32/8 =>  4 : Bytes Per RV32  Instruction
   localparam  CBPI        = CI_SZ/8;                                // 16/8 =>  2 : Bytes Per RV32C Instruction

   localparam ASSEMBLY     = 1'b0;                                   // see disasm_B64.sv
   localparam SEMANTICS    = 1'b1;

   localparam  CL_SZ       = bit_size(CL_LEN-1);
`ifdef ext_C
   localparam  MAX_IPCL    = CL_LEN/CBPI;                            // 32/2 =>  up to 16 Instructions Per Cache Line (if using compressed)
`else
   localparam  MAX_IPCL    = CL_LEN/BPI;                             // 32/4 =>  up to 8 Instructions Per Cache Line (if not using compressed)
`endif

   // See decode_core.sv
   // NOTE: These are the HINT and RESERVED values associated with specific HINTs that can be seen in decode_core.sv.  To use a HINT in a design, the corresponing
   //       "`define H_xxxx" must be enabled above.  For example, let's say a deisnger wants to use the code point at HINT_C_NOP.  `define H_C_NOP would neeed to be enabled
   //       and then code written in the "HINT_INSTR:" section of execute.sv.  To decode the HINT in execute.sv, code such as the following could be added:
   //       HINT_INSTR:
   //       begin
   //          case (data_in.imm)
   //             HINT_C_NOP:
   //             begin
   //                ...more code to do the HINT_C_NOP would go here
   //             end
   //             ...
   //          endcase
   //       end
   localparam  HINT_C_NOP        = 1,
               HINT_C_ADDI       = 2,
               HINT_C_LI         = 3,
               HINT_C_LUI        = 4,
               HINT_C_SRLI       = 5,
               HINT_C_SRLI2      = 6,
               HINT_C_SRAI       = 7,
               HINT_C_SRAI2      = 8,
               HINT_C_SLLI       = 9,
               HINT_C_SLLI2      = 10,
               HINT_C_MV         = 11,
               HINT_C_ADD        = 12,
               HINT_ADDI         = 13,
               HINT_SLLI         = 14,
               HINT_SLTI         = 15,
               HINT_SLTIU        = 16,
               HINT_XORI         = 17,
               HINT_SRLI         = 18,
               HINT_SRAI         = 19,
               HINT_ORI          = 20,
               HINT_ANDI         = 21,
               HINT_AUIPC        = 22,
               RES_ADD           = 23,
               RES_SLL           = 24,
               RES_SLT           = 25,
               RES_SLTU          = 26,
               RES_XOR           = 27,
               RES_SRL           = 28,
               RES_OR            = 29,
               RES_AND           = 30,
               RES_SUB           = 31,
               RES_SRA           = 32,
               HINT_LUI          = 33;
endpackage