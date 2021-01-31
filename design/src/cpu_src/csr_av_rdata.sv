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
// File          :  csr_av_rdata.sv - CSRs related to Machine mode
// Description   :  Contains CSR logic to determine which CSR[] regsiters are available and the data
//               :  that can be read
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr_av_rdata
(
   input    logic         [11:0] csr_rd_addr,
   output   logic      [RSZ-1:0] csr_rd_data,
   output   logic                csr_rd_avail,     // 1 = register exists (available) in design

   input    logic    [RSZ*2-1:0] mtime,

   input    logic          [1:0] mode,

   `ifdef add_DM
   input    logic                Dbg_mode,
   `endif

   `ifdef ext_U
   `ifdef ext_N
   input var UCSR  ucsr,          // all of the User mode Control & Status Registers
   `endif
   `endif

   `ifdef ext_S
   input var SCSR  scsr,          // all of the Supervisor mode Control & Status Registers
   `endif

   input var MCSR  mcsr           // all of the Machine mode Control & Status Registers
);
   logic             av;

   // The counter-enable registers mcounteren and scounteren are 32-bit registers that control the
   // availability of the hardware performance-monitoring counters to the next-lowest privileged mode....
   // When the CY, TM, IR, or HPMn bit in the mcounteren register is clear, attempts to read the
   // cycle, time, instret, or hpmcountern register while executing in S-mode or U-mode will cause
   // an illegal instruction exception. When one of these bits is set, access to the corresponding register
   // is permitted in the next implemented privilege mode (S-mode if implemented, otherwise U-mode). riscv-privileged.pdf p 34
   always_comb
   begin
      // see p 34 riscv-privileged.pdf
      av = FALSE;
      if (mode == M_MODE)                          // Machine mode
         av = TRUE;

      `ifdef ext_S
      if (mode == S_MODE)                          // Supervisor mode
         av = mcsr.mcounteren[csr_rd_addr[4:0]];   // lower 5 bits of csr_addr determine index into mcounteren[]
      `endif

      `ifdef ext_U
      `ifdef ext_N
      if (mode == U_MODE)                          // User mode
         `ifdef ext_S
         av = scsr.scounteren[csr_rd_addr[4:0]];
         `else
         av = mcsr.mcounteren[csr_rd_addr[4:0]];   // NOT SURE ABOUT THIS CONDITION!!!!!!!!!!!!!!!!!!!!!!!!!
         `endif
      `endif
      `endif
   end

   always_comb
   begin
      csr_rd_avail   = FALSE; // default values
      csr_rd_data    = '0;

      case(csr_rd_addr)
      `ifdef ext_U
         // ==================================================================== User Mode Registers ====================================================================

         `ifdef ext_N
         // ------------------------------ User Status Register
         // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
         //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
         // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};
         12'h000:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.ustatus;            // see this in csr.sv
         end

         // ------------------------------ User Floating-Point CSRs
         // 12'h001 - 12'h003



         // User Interrupt-Enable Register
         // 12'h004 = 12'b0000_0000_0100  uie         (read-write)  user mode
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,    0,   ueie,  0,    0,    0,   utie,  0,    0,    0,   usie}; riscv-privileged draft 1.12  p. 114
         12'h004:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = {ucsr.uie.ueie, 3'b0, ucsr.uie.utie, 3'b0, ucsr.uie.usie};   // see riscv-privileged p 114
         end

         // ------------------------------ User Trap Handler Base address
         // 12'h005 = 12'b0000_0000_0101  utvec       (read-write)  user mode
         12'h005:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.utvec;
         end

         // ------------------------------ User Trap Handling
         // Scratch register for user trap handlers.
         // 12'h040 = 12'b0000_0100_0000  uscratch    (read-write)
         12'h040:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.uscratch;
         end

         // ------------------------------ User Exception Program Counter
         // 12'h041 = 12'b0000_0100_0001  uepc        (read-write)
         12'h041:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.uepc;
         end

         // ------------------------------ User Exception Cause
         // 12'h042 = 12'b0000_0100_0010  ucause      (read-write)
         12'h042:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.ucause;
         end

         // ------------------------------ User Trap Value = bad address or instruction
         // 12'h043 = 12'b0000_0100_0011  utval       (read-write)
         12'h043:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = ucsr.utval;
         end

         // ------------------------------ User Interrupt Pending.
         // 12'h044 = 12'b0000_0100_0100  uip         (read-write)
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,    0,   ueip,  0,    0,    0,   utip,  0,    0,    0,   usip}; riscv-privileged draft 1.12  p. 114
         12'h044:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = {ucsr.uip.ueip, 3'b0, ucsr.uip.utip, 3'b0, ucsr.uip.usip};   // see riscv-privileged p 114
         end
         `endif // ext_N
      `endif // ext_U


      `ifdef ext_S
         // ==================================================================== Supervisor Mode Registers ==============================================================

         // ------------------------------ Supervisor Status Register
         // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
         //                    31          22    21    20   19    18    17  16:15 14:13 12:11 10:9    8     7     6     5     4     3     2     1    0
         //                   {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0,  spp, 1'b0, 1'b0, spie, upie, 1'b0, 1'b0,  sie, uie};
         12'h100:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.sstatus;            // see this in csr.sv
         end

         // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
         // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged
         `ifdef ext_N
            // ------------------------------ Supervisor Exception Delegation Register.
            // 12'h102 = 12'b0001_0000_0010  sedeleg  (read-write)
            12'h102:
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = scsr.sedeleg;
            end

            // ------------------------------ Supervisor Interrupt Delegation Register.
            // 12'h103 = 12'b0001_0000_0011  sideleg  (read-write)
            12'h103:
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = scsr.sideleg;
            end
         `endif // ext_N

         // ------------------------------ Supervisor Interrupt Enable Register.
         // 12'h104 = 12'b0001_0000_0100  sie         (read-write)
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,   seie,  0,    0,    0,   stie,  0,    0,    0,   ssie,  0}; riscv-privileged draft 1.12
         12'h104:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = {scsr.sie.seie, 3'b0, scsr.sie.stie, 3'b0, scsr.sie.ssie, 1'b0};
         end

         // ------------------------------ Supervisor Trap handler base address.
         // 12'h105 = 12'b0001_0000_0101  stvec       (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h105:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.stvec;
         end

         // 12/31/202 - Andrew Waterman "scounteren only exists if S Mode is implemented"
         // ------------------------------ Supervisor Counter Enable.
         // 12'h106 = 12'b0001_0000_0110  scounteren  (read-write)
         12'h106:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.scounteren;
         end      // see csr_rd_cntr_tmr.svh

         // ------------------------------ Supervisor Scratch Register
         // Scratch register for supervisor trap handlers.
         // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
         12'h140:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.sscratch;
         end

         // ------------------------------ Supervisor Exception Program Counter.
         // 12'h141 = 12'b0001_0100_0001  sepc        (read-write)
         12'h141:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.sepc;
         end

         // ------------------------------ Supervisor Trap Cause.
         // 12'h142 = 12'b0001_0100_0010  scause      (read-write)
         12'h142:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.scause;
         end

         // ------------------------------ Supervisor Trap Value = bad address or instruction.
         // 12'h143 = 12'b0001_0100_0011  stval       (read-write)
         12'h143:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.scause;
         end

// ???????When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the
// rd destination register contains the logical-OR of the softwarewritable bit and the interrupt
// signal from the interrupt controller. However, the value used in the read-modify-write sequence
// of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt
// value from the external interrupt controller. p. 30 riscv-privileged.pdf  see csr_fu.sv for implementation
         // ------------------------------ Supervisor Interrupt Pending.
         // 12'h144 = 12'b0001_0100_0100  sip         (read-write)
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,   seip,  0,    0,    0,   stip,  0,    0,    0,   ssip,  0}; riscv-privileged draft 1.12
         12'h144:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = {scsr.sip.seip, 3'b0, scsr.sip.stip, 3'b0, scsr.sip.ssip, 1'b0};
         end

         // ------------------------------ Supervisor Protection and Translation
         // Supervisor address translation and protection.
         // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
         12'h180:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = scsr.satp;
         end
      `endif // ext_S

         // ==================================================================== Machine Mode Registers =================================================================

         // ------------------------------ Machine Status Register
         // Machine status register.
         // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
         //                    31        22   21  20   19   18   17   16:15 14:13 12:11  10:9    8    7     6     5     4     3     2     1    0
         //                   {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs,  mpp, 2'b0,  spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};
         12'h300:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mstatus;
         end
         // ------------------------------ Machine ISA
         // ISA and extensions
         // 12'h301 = 12'b0011_0000_0001  misa                          (read-write but currently Read Only)
         // NOTE: if made to be writable, don't allow bit  2 to change to 1 if ext_C not defined
         // NOTE: if made to be writable, don't allow bit  5 to change to 1 if ext_F not defined
         // NOTE: if made to be writable, don't allow bit 12 to change to 1 if ext_M not defined
         // NOTE: if made to be writable, don't allow bit 13 to change to 1 if ext_N not defined
         // NOTE: if made to be writable, don't allow bit 18 to change to 1 if ext_S not defined
         // NOTE: if made to be writable, don't allow bit 20 to change to 1 if ext_U not defined
         // etc...
         12'h301:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.misa;
         end
         // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
         // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

         `ifdef MDLG // see cpu_params_pkg.sv
            // ------------------------------ Machine Exception Delegation Register
            // 12'h302 = 12'b0011_0000_0010  medeleg                          (read-write)
            12'h302:
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.medeleg;
            end

            // ------------------------------ Machine Interrupt Delegation Register
            // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
            12'h303:
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mideleg;
            end
         `endif

         // ------------------------------ Machine Interrupt Enable Register
         // 12'h304 = 12'b0011_0000_0100  mie                                 (read-write)
         //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
         // {20'b0, meie, 1'b0, seie, 1'b0, mtie, 1'b0, stie, 1'b0, msie, 1'b0, ssie, 1'b0}; see riscv-privileged p. 32
         12'h304:
         begin
            csr_rd_avail   = TRUE;
            `ifdef ext_S
            csr_rd_data    = {mcsr.mie.meie, 1'b0, scsr.sie.seie, 1'b0, mcsr.mie.mtie, 1'b0, scsr.sie.stie, 1'b0, mcsr.mie.msie, 1'b0, scsr.sie.ssie, 1'b0};
            `else
            csr_rd_data    = {mcsr.mie.meie, 3b0, mcsr.mie.mtie, 3'b0, mcsr.mie.msie, 3'b0};
            `endif
         end

         // ------------------------------ Machine Trap-handler base address.
         // 12'h305 = 12'b0011_0000_0101  mtvec                            (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h305:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mtvec;
         end

         // Andrew Waterman: 12/31/2020 - "There is also a clear statement that mcounteren exists if and only if U mode is implemented"
         `ifdef ext_U
         // ------------------------------ Machine Counter Enable.
         // 12'h306 = 12'b0011_0000_0110  mcounteren                       (read-write)
         12'h306:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mcounteren;
         end
         `endif
         
         // ------------------------------ Machine Counter Setup
         // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
         // 12'h320 = 12'b0011_0010_00000  mcountinhibit                   (read-write)
         12'h320:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mcountinhibit;
         end

         // ------------------------------ Machine Trap Handling
         // Scratch register for machine trap handlers.
         // 12'h340 = 12'b0011_0100_0000  mscratch                         (read-write)
         12'h340:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mscratch;
         end

         // ------------------------------ Machine Exception Program Counter. Used by MRET instruction at end of Machine mode trap handler
         // 12'h341 = 12'b0011_0100_0001  mepc                             (read-write)   see riscv-privileged p 36
         12'h341:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mepc;
         end

         // ------------------------------ Machine Exception Cause
         // 12'h342 = 12'b0011_0100_0010  mcause                           (read-write)
         12'h342:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data   = mcsr.mcause;
         end

         // ------------------------------ Machine Exception Trap Value     see riscv-privileged p. 38-39
         // 12'h343 = 12'b0011_0100_0011  mtval                            (read-write)
         12'h343:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mtval;
         end

// ?????????????When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the
// rd destination register contains the logical-OR of the softwarewritable bit and the interrupt
// signal from the interrupt controller. However, the value used in the read-modify-write sequence
// of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt
// value from the external interrupt controller. p. 30 riscv-privileged.pdf  see csr_fu.sv for implementation
         // ------------------------------ Machine Interrupt Pending
         // 12'h344 = 12'b0011_0100_0100  mip                              (read-write)
         //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
         // {20'b0, meip, 1'b0, seip, 1'b0, mtip, 1'b0, stip, 1'b0, msip, 1'b0, ssip, 1'b0}; see riscv-privileged draft 1.12 p. 32
         12'h344:
         begin
            csr_rd_avail   = TRUE;
            `ifdef ext_S
            csr_rd_data    = {mcsr.mip.meip, 1'b0, scsr.sip.seip, 1'b0, mcsr.mip.mtip, 1'b0, scsr.sip.stip, 1'b0, mcsr.mip.msip, 1'b0, scsr.sip.ssip, 1'b0};
            `else
            csr_rd_data    = {mcsr.mip.meip, 3'b0, mcsr.mip.mtip, 3'b0, mcsr.mip.msip, 3'b0};
            `endif
         end

         // ------------------------------ Machine Protection and Translation

         // 12'h3A0 - 12'h3A3
         `ifdef USE_PMPCFG
         // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                          (read-write)
         12'h3A0:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.pmpcfg0;
         end
         // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                          (read-write)
         12'h3A1:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.pmpcfg1;
         end
         // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                          (read-write)
         12'h3A2:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.pmpcfg2;
         end
         // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                          (read-write)
         12'h3A3:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.pmpcfg3;
         end
         `endif

         // 12'h3B0 - 12'h3BF
         // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
         `ifdef PMP_ADDR0  12'h3B0: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr0);  end `endif
         `ifdef PMP_ADDR1  12'h3B1: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr1);  end `endif
         `ifdef PMP_ADDR2  12'h3B2: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr2);  end `endif
         `ifdef PMP_ADDR3  12'h3B3: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr3);  end `endif
         `ifdef PMP_ADDR4  12'h3B4: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr4);  end `endif
         `ifdef PMP_ADDR5  12'h3B5: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr5);  end `endif
         `ifdef PMP_ADDR6  12'h3B6: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr6);  end `endif
         `ifdef PMP_ADDR7  12'h3B7: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr7);  end `endif
         `ifdef PMP_ADDR8  12'h3B8: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr8);  end `endif
         `ifdef PMP_ADDR9  12'h3B9: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr9);  end `endif
         `ifdef PMP_ADDR10 12'h3BA: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr10); end `endif
         `ifdef PMP_ADDR11 12'h3BB: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr11); end `endif
         `ifdef PMP_ADDR12 12'h3BC: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr12); end `endif
         `ifdef PMP_ADDR13 12'h3BD: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr13); end `endif
         `ifdef PMP_ADDR14 12'h3BE: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr14); end `endif
         `ifdef PMP_ADDR15 12'h3BF: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.pmpaddr15); end `endif

         `ifdef add_DM
         // Debug Write registers - INCOMPLETE!!!!!!!!!!!
         // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
         // visible to machine mode and debug mode
         12'h7A0: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.tselect;   end     // Trigger Select Register
         12'h7A1: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.tdata1;    end     // Trigger Data Register 1
         12'h7A2: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.tdata2;    end     // Trigger Data Register 2
         12'h7A3: begin csr_rd_avail = TRUE; csr_rd_data = mcsr.tdata3;    end     // Trigger Data Register 3

         // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
         // "0x7B0–0x7BF are only visible to debug mode" see. p 6 riscv-privileged-sail-draft.pdf
         12'h7B0: begin csr_rd_avail = Dbg_mode; csr_rd_data = mcsr.dcsr;      end     // Debug Control and Status Register
         12'h7B1: begin csr_rd_avail = Dbg_mode; csr_rd_data = mcsr.dpc;       end     // Debug PC Register
         12'h7B2: begin csr_rd_avail = Dbg_mode; csr_rd_data = mcsr.dscratch0; end     // Debug Scratch Register 0
         12'h7B3: begin csr_rd_avail = Dbg_mode; csr_rd_data = mcsr.dscratch1; end     // Debug Scratch Register 1
         `endif // add_DM


         // ------------------------------ Machine Cycle Counter - CY
         // Lower 32 bits of mcycle
         // 12'hB00 = 12'b1011_0000_0000  mcycle_lo (read-write)
         12'hB00:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mcycle_lo;
         end

         // ------------------------------ Upper 32 bits of mcycle
         // 12'hB80 = 12'b1011_1000_0000  mcycle_hi (read-write)
         12'hB80:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mcycle_hi;
         end

         // ------------------------------ Machine Instructions-Retired Counter - IR
          // 12'hB02 = 12'b1011_0000_0010  minstret_lo
         12'hB02:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.minstret_lo;
         end

         // ------------------------------ Upper 32 bits of minstret
         // 12'hB82 = 12'b1011_1000_0010  minstret_hi
         12'hB82:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.minstret_hi;
         end

         // ------------------------------ Machine Information Registers
         // Vendor ID
         // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
         12'hF11:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mvendorid;
         end

         // ------------------------------ Architecture ID
         // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
         12'hF12:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.marchid;
         end

         // ------------------------------ Implementation ID
         // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
         12'hF13:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mimpid;
         end

         // ------------------------------ Hardware Thread ID
         // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
         12'hF14:
         begin
            csr_rd_avail   = TRUE;
            csr_rd_data    = mcsr.mhartid;
         end
      endcase

      `ifdef use_MHPM
       genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
      generate
         for (n = 0; n < NUM_MHPM; n++)
         begin : MHPM_CNTR_EVENTS
            // ------------------------------ Machine hardware performance-monitoring counters
            // 12'hBO3 - 12'hB1F  mhpmcounter3 - mhpmcounter31
            if (csr_rd_addr == (12'hB03+n))
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mhpmcounter_lo[n];
            end
            // 12'hB83 - 12'hB9F
            if (csr_rd_addr == (12'hB83+n))
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mhpmcounter_hi[n];
            end

            // 12'hC03 - 12'hC1F
            if ((csr_rd_addr == (12'hC03+n)) & av)
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mhpmcounter_lo[n];
            end
            // 12'hC83 - 12'hC9F
            if ((csr_rd_addr == (12'hC83+n)) & av)
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mhpmcounter_hi[n];
            end

            // ------------------------------ Machine hardware performance-monitoring event selectors mhpmevent3 - mhpmevent31
            // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31
            if (csr_rd_addr == 12'h323+n)
            begin
               csr_rd_avail   = TRUE;
               csr_rd_data    = mcsr.mhpmevent[n];
            end
         end
      endgenerate
      `endif

      // ==================================================================== Machine/Supervisor/User Mode Registers =================================================================
      // Note: p 3 table 1.2 riscv-privileged.pdf  Notice that if U mode does not exist then the only valid mode is M.
      // If only M mode then mcounteren is never used and can be eliminated if desired
      // Number of levels Supported Modes Intended Usage
      // 1 M Simple embedded systems
      // 2 M, U Secure embedded systems
      // 3 M, S, U Systems running Unix-like operating systems
      //

      // csr_rd_avail = CSR register exists in this design
      // ------------------------------ Counter/Timers (12'hCxx = Read Only - readable by Machine, Supervisor and User modes)
      // ------------------------------ Cycle Counter for RDCYCLE instruction - CY
      // 12'hC00 = 12'b1100_0000_0000  cycle          (read-only)
      if ((csr_rd_addr == 12'hC00) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mcsr.mcycle_lo;
      end

      // ------------------------------ Timer Counter - TM
      // 12'hC01 = 12'b1100_0000_0001  time           (read-only)
      if ((csr_rd_addr == 12'hC01) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mtime[RSZ-1:0];
      end

      // ------------------------------ Number of Instructions Retired
      // 12'hC02 = 12'b1100_0000_0010  instret        (read-only)
      if ((csr_rd_addr == 12'hC02) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mcsr.minstret_lo;
      end


      // ------------------------------ Upper 32 bits of Cycle Counter - CY
      // 12'hC80 = 12'b1100_1000_0000  mcycle hi      (read-only)
      if ((csr_rd_addr == 12'hC80) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mcsr.mcycle_hi;
      end

      // ------------------------------ Upper 32 bits of Timer Counter - TM
      // 12'hC81 = 12'b1100_1000_0001  time hi        (read-only)
      if ((csr_rd_addr == 12'hC81) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mtime[RSZ*2-1:RSZ];
      end

      // ------------------------------ Upper 32 bits of Instructions Retired, RV32I only.
      // 12'hC82 = 12'b1100_1000_0010  uinstret hi    (read-only)
      if ((csr_rd_addr == 12'hC82) & av)
      begin
         csr_rd_avail   = TRUE;
         csr_rd_data    = mcsr.minstret_hi;
      end
   end // always_comb
endmodule
