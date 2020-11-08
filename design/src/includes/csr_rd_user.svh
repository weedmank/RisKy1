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
// File          :  csr_rd_user.svh
// Description   :  Contains CSR Read logic for User mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // see riscv-privileged.pdf p. 8
   `ifdef ext_U
      // csr_avail = CSR register exists in this design
      case(csr_addr)
         // ================================================= User Mode =================================================
         // The user-visible CSRs added to support the N extension are listed in Table 22.1 see riscv-privileged.pdf p 123

         // ------------------------------ User Trap Setup
         `ifdef ext_N
         // User Status Register
         // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
         12'h000: begin csr_rdata = csr_ustatus;    csr_avail = TRUE; end
         `endif

         `ifdef ext_F
         // ------------------------------ User Floating-Point CSRs
         // 12'h001 - 12'h003
         `endif   // ext_F

         `ifdef ext_N
         // User Interrupt-Enable Register
         // 12'h004 = 12'b0000_0000_0100  uie         (read-write)  user mode
         12'h004: begin csr_rdata = csr_uie;        csr_avail = TRUE; end

         // User Trap Handler Base address.
         // 12'h005 = 12'b0000_0000_0101  utvec       (read-write)  user mode
         12'h005: begin csr_rdata = csr_utvec;      csr_avail = TRUE; end

         // ------------------------------ User Trap Handling
         // Scratch register for user trap handlers.
         // 12'h040 = 12'b0000_0100_0000  uscratch    (read-write)
         12'h040: begin csr_rdata = csr_uscratch;   csr_avail = TRUE; end

         // User exception program counter.
         // 12'h041 = 12'b0000_0100_0001  uepc        (read-write)
         12'h041: begin csr_rdata = csr_uepc;       csr_avail = TRUE; end

         // User exception program counter.
         // 12'h042 = 12'b0000_0100_0010  ucause      (read-write)
         12'h042: begin csr_rdata = csr_ucause;     csr_avail = TRUE; end

         // User bad address or instruction.
         // 12'h043 = 12'b0000_0100_0011  utval       (read-write)
         12'h043: begin csr_rdata = csr_utval;      csr_avail = TRUE; end

         // User interrupt pending.
         // 12'h044 = 12'b0000_0100_0100  uip         (read-write)
         12'h044: begin csr_rdata = csr_uip;        csr_avail = TRUE;  end
         `endif

      endcase
   `endif   // ext_U
