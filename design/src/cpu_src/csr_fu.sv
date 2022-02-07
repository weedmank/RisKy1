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
// File          :  csr_fu.sv
// Description   :  Contains the Control & Status Registers R/W operation
//               :  Determines data that will be written to CSR and paas it on to WB stage
//               :  Also deterimes the data that will be read from the CSR
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_fu
(
   CSRFU_intf.slave  csrfu_bus
);
   logic                   is_csr_inst;                           // 1 = A CSR instruction is occuring during this clock cylce
   logic            [11:0] csr_addr;                              // R/W address
   logic     [GPR_ASZ-1:0] Rd_addr;                               // Rd address
   logic     [GPR_ASZ-1:0] Rs1_addr;                              // Rs1 address
   logic         [RSZ-1:0] Rs1_data;                              // Contents of R[rs1]
   logic             [2:0] funct3;
   logic             [1:0] mode;                                  // CPU mode: Machine, Supervisor, or User
   logic                   sw_irq;                                // Software Interrupt Pending
   logic         [RSZ-1:0] csr_rd_data;                           // current read data from CSR[csr_addr] with any mods due to which R/W mode - {CSRRW,CSRRS,CSRRC,CSRRWI,CSRRSI,CSRRCI}

   // signals that will get passed to Mem Stage related to current contents of CSR[csr_addr]
   logic                   csr_wr;                                //
   logic                   csr_rd;                                //
   logic         [RSZ-1:0] csr_rw_data;                           // read data after it is written into CSR[csr_addr] - can be very different that what gets written
   logic         [RSZ-1:0] csr_wr_data;                           // write data to CSR[csr_addr]
   logic                   ill_csr_access;                        // 1 = illegal csr access
   logic            [11:0] ill_csr_addr;
   logic                   csr_rd_avail;                          // Is the CSR[csr_addr] available for use?

   logic         [RSZ-1:0] imm_data;                              // immediate data used in calculation of next CSR[csr_addr]

   // ---------------------------------- csrfu_bus.slave interface I/O
   assign is_csr_inst                  = csrfu_bus.is_csr_inst;   // Input:   1 = A CSR instruction is occuring during this clock cylce
   assign csr_addr                     = csrfu_bus.csr_addr;      // Input:   CSR address to access
   assign Rd_addr                      = csrfu_bus.Rd_addr;       // Input:   rd
   assign Rs1_addr                     = csrfu_bus.Rs1_addr;      // Input:   rs1
   assign Rs1_data                     = csrfu_bus.Rs1_data;      // Input:   R[rs1]
   assign funct3                       = csrfu_bus.funct3;        // Input:   type of CSR R/W
   assign mode                         = csrfu_bus.mode;          // Input:   current CPU mode
   assign sw_irq                       = csrfu_bus.sw_irq;        // Input:   Software Interrupt Pending
   assign csr_rd_data                  = csrfu_bus.csr_rd_data;   // Input:   csr read data directly from csr logic
   assign csr_rd_avail                 = csrfu_bus.csr_rd_avail;  // Input:   csr register is available for use

   assign csrfu_bus.csr_rd             = csr_rd;                  // Output:  1 = read from CSR[csr_addr]
   assign csrfu_bus.csr_wr             = csr_wr;                  // Output:  1 = write csr_wr_data to CSR[csr_addr]
   assign csrfu_bus.csr_rw_data        = csr_rw_data;             // Output:  csr_rd_data plus any software interrupt modifications (depends on csr_addr)
   assign csrfu_bus.csr_wr_data        = csr_wr_data;             // Output:  data that will be written to CSR[csr_addr] in WB stage
   assign csrfu_bus.ill_csr_access     = ill_csr_access;          // Output:  used by EXE stage to pass on to WB stage
   assign csrfu_bus.ill_csr_addr       = ill_csr_addr;            // Output:  used by EXE stage to pass on to WB stage

   assign imm_data                     = {27'd0,Rs1_addr};        // 5 bits of intruction imbedded data


   // Check for valid reads and writes to CSRs
   logic       [1:0] lowest_priv;
   logic             writable;

   //---------------------------------- 12 bit address info ----------------------------------
   //           bits [11:10]    bits[9:8]             [7:6]
   //           00 R/W          00 user mode          standard/non-standard info
   //           01 R/W          01 supervisor mode
   //           10 R/W          10 unused
   //           11 RO           11 machine mode
   //             \            /
   //              \          /
   //               \        /   // Note:  The next two bits (csr[9:8]) encode the lowest privilege level that can access the CSR.
   //                \      /
   // Counters        \    /
   //    Clock Cycle   \  /
   //    12'hC00 = 12'b1100_0000_0000  cycle       (read-only)   user mode
   //    12'hB00 = 12'b1011_0000_0000  mcycle      (read-write)  machine mode

   // determine if there's a write to a CSR, the write data, whether this is an illegeal access, the read data from a CSR, etc..
   always_comb
   begin
      csr_wr_data    = '0;

      csr_wr         = FALSE;
      csr_rd         = FALSE;
      ill_csr_access = FALSE;
      ill_csr_addr   = 0;
      csr_rw_data    = 0;

      writable       = (csr_addr[11:10] != 2'b11);       // read/write (00, 01, or 10) or read-only (11)
      lowest_priv    = csr_addr[9:8];

      // see riscv-spec.pdf p 54
      if (is_csr_inst)
      begin
         // When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the
         // rd destination register contains the logical-OR of the software writable bit and the interrupt
         // signal from the interrupt controller. However, the value used in the read-modify-write sequence
         // of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt
         // value from the external interrupt controller. p. 30 riscv-privileged.pdf  see csr_fu.sv for implementation

         if (((mode < lowest_priv) || !csr_rd_avail || !writable))
         begin
            ill_csr_access = TRUE;
            ill_csr_addr   = csr_addr;
         end
         else // not an illegal CSR access
         begin
            case(funct3)   // {CSRRW,CSRRS,CSRRC,CSRRWI,CSRRSI,CSRRCI}
               CSRRW:      // 1
               begin       // If rd=x0, then the instruction shall not read the CSR and shall not cause any of the side effects that might occur on a CSR read. riscv-spec p 53-54
                  csr_wr_data = Rs1_data;                // R[Rd] = CSR; CSR = R[rs1];          Atomic Read/Write CSR  p. 22
                  csr_wr = TRUE;
                  csr_rd = (Rd_addr != 0);               // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd)
                  begin
                     csr_rw_data = csr_rd_data;          // from the current CSR[csr_addr]
                     if (csr_addr[8:0] == 9'h144)        // Machine Interrupt Pending register - Mip and Supervisor Interrupt Pending register
                        csr_rw_data |= (sw_irq << 9);    // the value returned in the rd destination register contains the logical-OR of the software writable bit and the interrupt signal from the interrupt controller. p 30 riscv-privileged.pdf
                  end
               end
               // For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and
               // so shall not cause any of the side effects that might otherwise occur on a CSR write, such as raising
               // illegal instruction exceptions on accesses to read-only CSRs
               CSRRS:   // 2
               begin    // Other bits in the CSR are unaffected (though CSRs might have side effects when written). risv-spec p. 54
                  csr_wr_data = csr_rd_data | Rs1_data;    // R[Rd] = CSR; CSR = CSR | R[rs1];    Atomic Read and Set Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
                  csr_rd = TRUE;
                  csr_rw_data = csr_rd_data;
                  if (csr_addr[8:0] == 9'h144)           // Machine Interrupt Pending register - Mip and Supervisor Interrupt Pending register
                     csr_rw_data |= (sw_irq << 9);       // the value returned in the rd destination register contains the logical-OR of the software writable bit and the interrupt signal from the interrupt controller. p 30 riscv-privileged.pdf
               end
               CSRRC:   // 3
               begin
                  csr_wr_data = csr_rd_data & ~Rs1_data; // R[Rd] = CSR; CSR = CSR & ~R[rs1];   Atomic Read and Clear Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
                  csr_rd = TRUE;
                  csr_rw_data = csr_rd_data;
                  if (csr_addr[8:0] == 9'h144)           // Machine Interrupt Pending register - Mip and Supervisor Interrupt Pending register
                     csr_rw_data |= (sw_irq << 9);       // the value returned in the rd destination register contains the logical-OR of the software writable bit and the interrupt signal from the interrupt controller. p 30 riscv-privileged.pdf
               end
               CSRRWI:  // 5
               begin
                  csr_wr_data = imm_data;                // R[Rd] = CSR; CSR = imm;             p. 22-23
                  csr_wr = TRUE;
                  csr_rd = (Rd_addr != 0);               // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd) csr_rw_data = csr_rd_data;
               end
               CSRRSI:  // 6
               begin
                  csr_wr_data = csr_rd_data | imm_data;  // R[Rd] = CSR; CSR = CSR | imm;       Atomic Read and Set Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
                  csr_rd = TRUE;
                  csr_rw_data = csr_rd_data;
               end
               CSRRCI:  // 7
               begin
                  csr_wr_data = csr_rd_data & ~imm_data; // R[Rd] = CSR; CSR = CSR & ~imm;      Atomic Read and Clear Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
                  csr_rd = TRUE;
                  csr_rw_data = csr_rd_data;
               end
            endcase
         end // illegal CSR access
      end // valid
   end // always_comb
endmodule
