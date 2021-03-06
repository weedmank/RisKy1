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

   parameter   NUM_MHPM = 0;                                         // CSR: number of mhpmcounter's and mhpmevent's, where first one starts at mphmcounter3 if NUM_MHPM > 0
   // NOTE: Max NUM_MHPM is 29

//   parameter   WFI_IS_NOP           = TRUE;


// `define     MM_MSIP                                               // create a memory mapped register for the MSIP bit of CSR MIP register

   // parameters related to Memory, L1 D$ and L1 I$
   parameter   CL_LEN   = 32; // cache line length in bytes

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
   //!!!      WARNING: The localparams below are not intended to be user modified     !!!!
   //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   parameter   M_MODE      = 2'b11;          // Machine Mode
   parameter   S_MODE      = 2'b01;          // Supervisor Mode
   parameter   U_MODE      = 2'b00;          // User Mode

   localparam  XLEN        = 6'd32;                                  // instruction word width
   localparam  CI_SZ       = 5'd16;                                  // compressed instruction word width
   localparam  RSZ         = XLEN;                                   // General Purpose Register width
   localparam  MAX_GPR     = 32;                                     // maximum number of CPU General Purpose Registers
   localparam  MAX_CSR     = 4096;                                   // maximum number of CSR Registers
   localparam  DEL_SZ      = bit_size(RSZ-1);                        // Number of bits that define "cause" when indexing a delegation register. see mode_irq.sv

   localparam  FLEN        = 32;
   localparam  MAX_FPR     = 32;                                     // maximum number of CPU Single Precision Floating Point Registers

   localparam  GPR_ASZ     = bit_size(MAX_GPR-1);
   localparam  FPR_ASZ     = bit_size(MAX_FPR-1);
   localparam  CSR_ASZ     = bit_size(MAX_CSR-1);

   localparam  BPI         = XLEN/8;                                 // 32/8 =>  4 : Bytes Per RV32  Instruction
   localparam  CBPI        = CI_SZ/8;                                // 16/8 =>  2 : Bytes Per RV32C Instruction

   localparam  ASSEMBLY    = 1'b0;                                   // see disasm_B64.sv
   localparam  SEMANTICS   = 1'b1;

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