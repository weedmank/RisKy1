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
   CSRFU_intf.slave     csrfu_bus,
   CSR_NXT_intf.master  csr_nxt_bus
);
   logic                   csr_valid;                             // Input:   1 = Read & Write from/to csr[csr_addr] will occur this clock cylce
   logic            [11:0] csr_addr;                              // Input:   R/W address
   logic     [GPR_ASZ-1:0] Rd_addr;                               // Input:   Rd address
   logic     [GPR_ASZ-1:0] Rs1_addr;                              // Input:   Rs1 address
   logic         [RSZ-1:0] Rs1_data;                              // Input:   Contents of R[rs1]
   logic             [2:0] funct3;                                  
   logic             [1:0] mode;                                  // Input:   CPU mode: Machine, Supervisor, or User
   `ifdef ext_N
   logic                   sw_irq;                                // Input:   Software Interrupt Pending
   `endif

   logic                   csr_wr;                                // Output: 
   logic                   csr_rd;                                // Output: 
   logic                   csr_avail;                             // Output: 
   logic         [RSZ-1:0] csr_rd_data;                           // Output: 
   logic         [RSZ-1:0] Rd_data;                               // Output:  based on current CSR[csr_addr] and function to perform. This is the value to write into Destination Register Rd in WB stage
   logic         [RSZ-1:0] csr_wr_data;                           // Output:  write data to csr[csr_addr]
   logic         [RSZ-1:0] nxt_csr_rd_data;                       // Output:  data that will be in CSR[csr_addr] after write - may be different that data being written but it can be determined
   logic                   ill_csr_access;                        // Output:  1 = illegal csr access
   logic            [11:0] ill_csr_addr;

   logic         [RSZ-1:0] imm_data;                              // immediate data

   // ----------------------------------- csr_nxt_bus interface
   assign csr_nxt_bus.nxt_csr_wr       = csr_wr;
   assign csr_nxt_bus.nxt_csr_wr_addr  = csr_addr;
   assign csr_nxt_bus.nxt_csr_wr_data  = csr_wr_data;

   assign nxt_csr_rd_data = csr_nxt_bus.nxt_csr_rd_data;          // data from csr_nxt_bus.nxt_csr_wr_addr is returned

   // ----------------------------------- csrfu_bus.slave interface
   assign csr_valid                    = csrfu_bus.csr_valid;     // Input:   valid == 1 - a CSR rad & write happens this clock cycle
   assign csr_addr                     = csrfu_bus.csr_addr;      // Input:   CSR address to access
   assign csr_avail                    = csrfu_bus.csr_avail;     // Input:   1 = CSR[csr_addr] is available for use
   assign csr_rd_data                  = csrfu_bus.csr_rd_data;   // Input:   Current read data read from CSR[csr_addr]
   assign Rd_addr                      = csrfu_bus.Rd_addr;       // Input:   rd
   assign Rs1_addr                     = csrfu_bus.Rs1_addr;      // Input:   rs1
   assign Rs1_data                     = csrfu_bus.Rs1_data;      // Input:   R[rs1]
   assign funct3                       = csrfu_bus.funct3;        // Input:   type of CSR R/W
   assign mode                         = csrfu_bus.mode;          // Input:   current CPU mode
   `ifdef ext_N
   assign sw_irq                       = csrfu_bus.sw_irq;        // Input:   Software Interrupt Pending
   `endif
   
   assign csrfu_bus.csr_wr             = csr_wr;                  // Output:   1 = write csr_wr_data to CSR[csr_addr]
   assign csrfu_bus.csr_rd             = csr_rd;                  // Output:   1 = read csr_rd_data from CSR[csr_addr]
   assign csrfu_bus.Rd_data            = Rd_data;                 // Output:  data, based on current CSR[csr_addr] and operation to perform, that will be written to Destination Register Rd in WB stage
   assign csrfu_bus.csr_wr_data        = csr_wr_data;             // Output:  data that will be written to CSR[csr_addr] in WB stage
   assign csrfu_bus.nxt_csr_rd_data    = nxt_csr_rd_data;         // Output:  next csr read data by be different than what is written. This calculated value will be forwarded as the csr read data in EXE and later stages
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


   // full_case — at least one item is true
   // parallel_case — at most one item is true
   always_comb
   begin
      csr_wr_data    = '0;
      Rd_data        = '0;    // Desitnation Register data. Gets witten to R[Rd] in WB stage

      csr_wr         = FALSE;
      csr_rd         = FALSE;
      ill_csr_access = FALSE;
      ill_csr_addr   = 0;

      writable    = (csr_addr[11:10] != 2'b11);          // read/write (00, 01, or 10) or read-only (11)
      lowest_priv = csr_addr[9:8];

      // see riscv-spec.pdf p 54
      if (csr_valid)
      begin
         // When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the
         // rd destination register contains the logical-OR of the software writable bit and the interrupt
         // signal from the interrupt controller. However, the value used in the read-modify-write sequence
         // of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt
         // value from the external interrupt controller. p. 30 riscv-privileged.pdf  see csr_fu.sv for implementation

         case(funct3)   // {CSRRW,CSRRS,CSRRC,CSRRWI,CSRRSI,CSRRCI}
            CSRRW: // 1
            begin      // If rd=x0, then the instruction shall not read the CSR and shall not cause any of the side effects that might occur on a CSR read. riscv-spec p 53-54
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = Rs1_data;                // R[Rd] = CSR; CSR = R[rs1];          Atomic Read/Write CSR  p. 22
                  csr_wr = TRUE;
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = (Rd_addr != 0); // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd)
                  begin
                     Rd_data = csr_rd_data;
                     `ifdef ext_N
                     if (csr_addr == 12'h344)   // Machine Interrupt Pending register - Mip
                        Rd_data |= {28'b0,sw_irq,3'b0};     // mip.????
                     `endif
                  end
               end
            end
            // For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and
            // so shall not cause any of the side effects that might otherwise occur on a CSR write, such as raising
            // illegal instruction exceptions on accesses to read-only CSRs
            CSRRS: // 2
            begin   // Other bits in the CSR are unaffected (though CSRs might have side effects when written). risv-spec p. 54
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rd_data |  Rs1_data;   // R[Rd] = CSR; CSR = CSR | R[rs1];    Atomic Read and Set Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  Rd_data = csr_rd_data;
               end
            end
            CSRRC: // 3
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rd_data & ~Rs1_data;   // R[Rd] = CSR; CSR = CSR & ~R[rs1];   Atomic Read and Clear Bits in CSR  p. 22
                  csr_wr = (Rs1_addr != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  Rd_data = csr_rd_data;
               end
            end
            CSRRWI: // 5
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = imm_data;                // R[Rd] = CSR; CSR = imm;             p. 22-23
                  csr_wr = TRUE;
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = (Rd_addr != 0); // if Rd = X0, don't allow any "side affects" due to read
                  if (csr_rd) Rd_data = csr_rd_data;
               end
            end
            CSRRSI: // 6
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rd_data |  imm_data;   // R[Rd] = CSR; CSR = CSR | imm;       Atomic Read and Set Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_rd = TRUE;
                  Rd_data = csr_rd_data;
               end
            end
            CSRRCI: // 7
            begin
               if (((mode < lowest_priv) || !csr_avail || !writable))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               else
               begin
                  csr_wr_data = csr_rd_data & ~imm_data;   // R[Rd] = CSR; CSR = CSR & ~imm;      Atomic Read and Clear Bits in CSR  p. 22-23
                  csr_wr = (imm_data != 0);
               end

               if (((mode < lowest_priv) || !csr_avail))
               begin
                  ill_csr_access = TRUE;
                  ill_csr_addr   = csr_addr;
               end
               begin
                  csr_rd = TRUE;
                  Rd_data = csr_rd_data;
               end
            end
         endcase
      end
   end
endmodule
