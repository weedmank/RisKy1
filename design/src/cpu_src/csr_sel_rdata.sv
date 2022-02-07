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
// File          :  csr_sel_rdata.sv - CSRs counter availability according to extensions being used,
//                  and read data from the registers
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

module csr_sel_rdata
(
   input    logic    [RSZ*2-1:0] mtime,

   input    logic          [1:0] mode,

   CSR_REG_intf.slave            csr_reg_bus,         // slave:   inputs: Ucsr, Scsr, Mcsr

   CSR_NXT_REG_intf.slave        csr_nxt_reg_bus,     // slave:   inputs: Dbg_mode, nxt_Ucsr, nxt_Scsr, nxt_Mcsr

   CSR_RD_intf.slave             csr_rd_bus           // slave:   inputs: csr_rd_addr, outputs: csr_rd_avail, csr_rd_data, csr_fwd_data
);
   logic             av;

   logic      [11:0] csr_rd_addr;
   logic             csr_rd_avail;                    // 1 = register exists (available) in design
   logic   [RSZ-1:0] csr_rd_data;                     // based on Mcsr, Scsr, Ucsr
   logic   [RSZ-1:0] csr_fwd_data;                    // based on csr_rd_addr in EXE stage and nxt_Mcsr, nxt_Scsr, nct_Ucsr

   assign csr_rd_addr = csr_rd_bus.csr_rd_addr;

   assign csr_rd_bus.csr_rd_avail   = csr_rd_avail;
   assign csr_rd_bus.csr_rd_data    = csr_rd_data;
   assign csr_rd_bus.csr_fwd_data   = csr_fwd_data;

   `ifdef add_DM
      logic    Dbg_mode;
      assign   Dbg_mode = csr_nxt_reg_bus.Dbg_mode;
   `endif

   `ifdef ext_U
   `ifdef ext_N
      UCSR  Ucsr, nxt_Ucsr;                           // all of the User mode Control & Status Registers
      assign Ucsr = csr_reg_bus.Ucsr;
      assign nxt_Ucsr = csr_nxt_reg_bus.nxt_Ucsr;
   `endif
   `endif

   `ifdef ext_S
      SCSR  Scsr, nxt_Scsr;                           // all of the Supervisor mode Control & Status Registers
      assign Scsr = csr_reg_bus.Scsr;
      assign nxt_Scsr = csr_nxt_reg_bus.nxt_Scsr;
   `endif

   MCSR  Mcsr, nxt_Mcsr;                              // all of the Machine mode Control & Status Registers
   assign Mcsr = csr_reg_bus.Mcsr;
   assign nxt_Mcsr = csr_nxt_reg_bus.nxt_Mcsr;

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
      if (mode == M_MODE)                             // Machine mode
         av = TRUE;

      `ifdef ext_S
      if (mode == S_MODE)                             // Supervisor mode
         av = Mcsr.mcounteren[csr_rd_addr[4:0]];      // lower 5 bits of csr_addr determine index into mcounteren[]
      `endif

      `ifdef ext_U
      `ifdef ext_N
      if (mode == U_MODE)                             // User mode
         `ifdef ext_S
         av = Scsr.scounteren[csr_rd_addr[4:0]];
         `else
         av = Mcsr.mcounteren[csr_rd_addr[4:0]];      // NOT SURE ABOUT THIS CONDITION!!!!!!!!!!!!!!!!!!!!!!!!!
         `endif
      `endif
      `endif
   end

   always_comb
   begin
      csr_rd_avail   = FALSE;                         // default values
      csr_rd_data    = '0;
      csr_fwd_data   = '0;

      `ifdef use_MHPM
      genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
      generate
         for (n = 0; n < NUM_MHPM; n++)
         begin : MHPM_CNTR_EVENTS
            // ------------------------------ Machine hardware performance-monitoring counters
            // 12'hBO3 - 12'hB1F  mhpmcounter3 - mhpmcounter31
            if (csr_rd_addr == (12'hB03+n))
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Mcsr.mhpmcounter_lo[n];
               csr_fwd_data      = nxt_Mcsr.mhpmcounter_lo[n];
            end
            // 12'hB83 - 12'hB9F
            if (csr_rd_addr == (12'hB83+n))
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Mcsr.mhpmcounter_hi[n];
               csr_fwd_data      = nxt_Mcsr.mhpmcounter_hi[n];
            end

            // 12'hC03 - 12'hC1F
            if ((csr_rd_addr == (12'hC03+n)) & av)
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Mcsr.mhpmcounter_lo[n];
               csr_fwd_data      = nxt_Mcsr.mhpmcounter_lo[n];
            end
            // 12'hC83 - 12'hC9F
            if ((csr_rd_addr == (12'hC83+n)) & av)
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Mcsr.mhpmcounter_hi[n];
               csr_fwd_data      = nxt_Mcsr.mhpmcounter_hi[n];
            end

            // ------------------------------ Machine hardware performance-monitoring event selectors mhpmevent3 - mhpmevent31
            // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31
            if (csr_rd_addr == 12'h323+n)
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Mcsr.mhpmevent[n];
               csr_fwd_data      = nxt_Mcsr.mhpmevent[n];
            end
         end
      endgenerate
      `endif

      // logic that can be done inside a case statement
      case(csr_rd_addr)
         // ==================================================================== Machine Mode Registers =================================================================

         // ------------------------------ Machine Status Register
         // Machine status register.
         // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)
         //                    31        22   21  20   19   18   17   16:15 14:13 12:11  10:9    8    7     6     5     4     3     2     1    0
         //                   {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs,  mpp, 2'b0,  spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};
         12'h300:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mstatus;
            csr_fwd_data      = nxt_Mcsr.mstatus;
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
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.misa;
            csr_fwd_data      = nxt_Mcsr.misa;
         end
         // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
         // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

         `ifdef MDLG // see cpu_params_pkg.sv
         // ------------------------------ Machine Exception Delegation Register
         // 12'h302 = 12'b0011_0000_0010  medeleg                          (read-write)
         12'h302:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.medeleg;
            csr_fwd_data      = nxt_Mcsr.medeleg;
         end

         // ------------------------------ Machine Interrupt Delegation Register
         // 12'h303 = 12'b0011_0000_0011  mideleg                       (read-write)
         12'h303:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mideleg;
            csr_fwd_data      = nxt_Mcsr.mideleg;
         end
         `endif

         // ------------------------------ Machine Interrupt Enable Register
         // 12'h304 = 12'b0011_0000_0100  mie                                 (read-write)
         //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
         // {20'b0, meie, 1'b0, seie, 1'b0, mtie, 1'b0, stie, 1'b0, msie, 1'b0, ssie, 1'b0}; see riscv-privileged p. 32
         12'h304:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mie;
            csr_fwd_data      = nxt_Mcsr.mie;
         end

         // ------------------------------ Machine Trap-handler base address.
         // 12'h305 = 12'b0011_0000_0101  mtvec                            (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h305:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mtvec;
            csr_fwd_data      = nxt_Mcsr.mtvec;
         end

         // Andrew Waterman: 12/31/2020 - "There is also a clear statement that mcounteren exists if and only if U mode is implemented"
         `ifdef ext_U
         // ------------------------------ Machine Counter Enable.
         // 12'h306 = 12'b0011_0000_0110  mcounteren                       (read-write)
         12'h306:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mcounteren;
            csr_fwd_data      = nxt_Mcsr.mcounteren;
         end
         `endif

         // ------------------------------ Machine Counter Setup
         // Machine Counter Inhibit  (if not implemented, set all bits to 0 => no inhibits will ocur)
         // 12'h320 = 12'b0011_0010_00000  mcountinhibit                   (read-write)
         12'h320:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mcountinhibit;
            csr_fwd_data      = nxt_Mcsr.mcountinhibit;
         end

         // ------------------------------ Machine Trap Handling
         // Scratch register for machine trap handlers.
         // 12'h340 = 12'b0011_0100_0000  mscratch                         (read-write)
         12'h340:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mscratch;
            csr_fwd_data      = nxt_Mcsr.mscratch;
         end

         // ------------------------------ Machine Exception Program Counter. Used by MRET instruction at end of Machine mode trap handler
         // 12'h341 = 12'b0011_0100_0001  mepc                             (read-write)   see riscv-privileged p 36
         12'h341:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mepc;
            csr_fwd_data      = nxt_Mcsr.mepc;
         end

         // ------------------------------ Machine Exception Cause
         // 12'h342 = 12'b0011_0100_0010  mcause                           (read-write)
         12'h342:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mcause;
            csr_fwd_data      = nxt_Mcsr.mcause;
         end

         // ------------------------------ Machine Exception Trap Value     see riscv-privileged p. 38-39
         // 12'h343 = 12'b0011_0100_0011  mtval                            (read-write)
         12'h343:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mtval;
            csr_fwd_data      = nxt_Mcsr.mtval;
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
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mip;
            csr_fwd_data      = nxt_Mcsr.mip;
         end

         // ------------------------------ Machine Protection and Translation

         // 12'h3A0 - 12'h3A3
         `ifdef USE_PMPCFG
         // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                          (read-write)
         12'h3A0:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.pmpcfg0;
            csr_fwd_data      = nxt_Mcsr.pmpcfg0;
         end
         // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                          (read-write)
         12'h3A1:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.pmpcfg1;
            csr_fwd_data      = nxt_Mcsr.pmpcfg1;
         end
         // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                          (read-write)
         12'h3A2:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.pmpcfg2;
            csr_fwd_data      = nxt_Mcsr.pmpcfg2;
         end
         // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                          (read-write)
         12'h3A3:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.pmpcfg3;
            csr_fwd_data      = nxt_Mcsr.pmpcfg3;
         end
         `endif

         // 12'h3B0 - 12'h3BF
         // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
         `ifdef PMP_ADDR0  12'h3B0: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr0);  csr_fwd_data = nxt_Mcsr.pmpaddr0);  end `endif
         `ifdef PMP_ADDR1  12'h3B1: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr1);  csr_fwd_data = nxt_Mcsr.pmpaddr1);  end `endif
         `ifdef PMP_ADDR2  12'h3B2: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr2);  csr_fwd_data = nxt_Mcsr.pmpaddr2);  end `endif
         `ifdef PMP_ADDR3  12'h3B3: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr3);  csr_fwd_data = nxt_Mcsr.pmpaddr3);  end `endif
         `ifdef PMP_ADDR4  12'h3B4: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr4);  csr_fwd_data = nxt_Mcsr.pmpaddr4);  end `endif
         `ifdef PMP_ADDR5  12'h3B5: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr5);  csr_fwd_data = nxt_Mcsr.pmpaddr5);  end `endif
         `ifdef PMP_ADDR6  12'h3B6: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr6);  csr_fwd_data = nxt_Mcsr.pmpaddr6);  end `endif
         `ifdef PMP_ADDR7  12'h3B7: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr7);  csr_fwd_data = nxt_Mcsr.pmpaddr7);  end `endif
         `ifdef PMP_ADDR8  12'h3B8: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr8);  csr_fwd_data = nxt_Mcsr.pmpaddr8);  end `endif
         `ifdef PMP_ADDR9  12'h3B9: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr9);  csr_fwd_data = nxt_Mcsr.pmpaddr9);  end `endif
         `ifdef PMP_ADDR10 12'h3BA: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr10); csr_fwd_data = nxt_Mcsr.pmpaddr10); end `endif
         `ifdef PMP_ADDR11 12'h3BB: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr11); csr_fwd_data = nxt_Mcsr.pmpaddr11); end `endif
         `ifdef PMP_ADDR12 12'h3BC: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr12); csr_fwd_data = nxt_Mcsr.pmpaddr12); end `endif
         `ifdef PMP_ADDR13 12'h3BD: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr13); csr_fwd_data = nxt_Mcsr.pmpaddr13); end `endif
         `ifdef PMP_ADDR14 12'h3BE: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr14); csr_fwd_data = nxt_Mcsr.pmpaddr14); end `endif
         `ifdef PMP_ADDR15 12'h3BF: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.pmpaddr15); csr_fwd_data = nxt_Mcsr.pmpaddr15); end `endif

         `ifdef add_DM
         // Debug Write registers - INCOMPLETE!!!!!!!!!!!
         // ------------------------------ Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
         // visible to machine mode and debug mode
         12'h7A0: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.tselect; csr_fwd_data = nxt_Mcsr.tselect;  end     // Trigger Select Register
         12'h7A1: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.tdata1;  csr_fwd_data = nxt_Mcsr.tdata1;   end     // Trigger Data Register 1
         12'h7A2: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.tdata2;  csr_fwd_data = nxt_Mcsr.tdata2;   end     // Trigger Data Register 2
         12'h7A3: begin csr_rd_avail = TRUE; csr_rd_data = Mcsr.tdata3;  csr_fwd_data = nxt_Mcsr.tdata3;   end     // Trigger Data Register 3

         // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
         // "0x7B0–0x7BF are only visible to debug mode" see. p 6 riscv-privileged-sail-draft.pdf
         12'h7B0: begin csr_rd_avail = Dbg_mode; csr_rd_data = Mcsr.dcsr;      csr_fwd_data = nxt_Mcsr.dcsr;      end     // Debug Control and Status Register
         12'h7B1: begin csr_rd_avail = Dbg_mode; csr_rd_data = Mcsr.dpc;       csr_fwd_data = nxt_Mcsr.dpc;       end     // Debug PC Register
         12'h7B2: begin csr_rd_avail = Dbg_mode; csr_rd_data = Mcsr.dscratch0; csr_fwd_data = nxt_Mcsr.dscratch0; end     // Debug Scratch Register 0
         12'h7B3: begin csr_rd_avail = Dbg_mode; csr_rd_data = Mcsr.dscratch1; csr_fwd_data = nxt_Mcsr.dscratch1; end     // Debug Scratch Register 1
         `endif // add_DM


         // ------------------------------ Machine Cycle Counter
         // Lower 32 bits of mcycle
         // 12'hB00 = 12'b1011_0000_0000  mcycle_lo (read-write)
         12'hB00:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mcycle_lo;
            csr_fwd_data      = nxt_Mcsr.mcycle_lo;
         end

         // ------------------------------ Upper 32 bits of mcycle
         // 12'hB80 = 12'b1011_1000_0000  mcycle_hi (read-write)
         12'hB80:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mcycle_hi;
            csr_fwd_data      = nxt_Mcsr.mcycle_hi;
         end

         // ------------------------------ Machine Instructions-Retired Counter - IR
         // 12'hB02 = 12'b1011_0000_0010  minstret_lo
         12'hB02:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.minstret_lo;
            csr_fwd_data      = nxt_Mcsr.minstret_lo;
         end

         // ------------------------------ Upper 32 bits of minstret
         // 12'hB82 = 12'b1011_1000_0010  minstret_hi
         12'hB82:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.minstret_hi;
            csr_fwd_data      = nxt_Mcsr.minstret_hi;
         end

         // ------------------------------ Counter/Timers (12'hCxx = Read Only - readable by Machine, Supervisor and User modes)
         // ------------------------------ Cycle Counter for RDCYCLE instruction - CY
         // 12'hC00 = 12'b1100_0000_0000  cycle          (read-only)
         12'hC00:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = Mcsr.mcycle_lo;
            if (av) csr_fwd_data    = nxt_Mcsr.mcycle_lo;
         end

         // ------------------------------ Timer Counter - TM
         // 12'hC01 = 12'b1100_0000_0001  time           (read-only)
         12'hC01:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = mtime[RSZ-1:0];
            if (av) csr_fwd_data    = mtime[RSZ-1:0];
         end

         // ------------------------------ Number of Instructions Retired
         // 12'hC02 = 12'b1100_0000_0010  instret        (read-only)
         12'hC02:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = Mcsr.minstret_lo;
            if (av) csr_fwd_data    = nxt_Mcsr.minstret_lo;
         end


         // ------------------------------ Upper 32 bits of Cycle Counter - CY
         // 12'hC80 = 12'b1100_1000_0000  mcycle hi      (read-only)
         12'hC80:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = Mcsr.mcycle_hi;
            if (av) csr_fwd_data    = nxt_Mcsr.mcycle_hi;
         end

         // ------------------------------ Upper 32 bits of Timer Counter - TM
         // 12'hC81 = 12'b1100_1000_0001  time hi        (read-only)
         12'hC81:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = mtime[RSZ*2-1:RSZ];
            if (av) csr_fwd_data    = mtime[RSZ*2-1:RSZ];
         end

         // ------------------------------ Upper 32 bits of Instructions Retired, RV32I only.
         // 12'hC82 = 12'b1100_1000_0010  uinstret hi    (read-only)
         12'hC82:
         begin
            csr_rd_avail   = av;
            if (av) csr_rd_data     = Mcsr.minstret_hi;
            if (av) csr_fwd_data    = nxt_Mcsr.minstret_hi;
         end

         // ------------------------------ Machine Information Registers
         // Vendor ID
         // 12'hF11 = 12'b1111_0001_0001  mvendorid   (read-only)
         12'hF11:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mvendorid;
            csr_fwd_data      = nxt_Mcsr.mvendorid;
         end

         // ------------------------------ Architecture ID
         // 12'hF12 = 12'b1111_0001_0010  marchid     (read-only)
         12'hF12:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.marchid;
            csr_fwd_data      = nxt_Mcsr.marchid;
         end

         // ------------------------------ Implementation ID
         // 12'hF13 = 12'b1111_0001_0011  mimpid      (read-only)
         12'hF13:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mimpid;
            csr_fwd_data      = nxt_Mcsr.mimpid;
         end

         // ------------------------------ Hardware Thread ID
         // 12'hF14 = 12'b1111_0001_0100  mhartid     (read-only)
         12'hF14:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Mcsr.mhartid;
            csr_fwd_data      = nxt_Mcsr.mhartid;
         end

         `ifdef ext_S
         // ==================================================================== Supervisor Mode Registers ==============================================================

         // ------------------------------ Supervisor Status Register
         // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)
         //                    31          22    21    20   19    18    17  16:15 14:13 12:11 10:9    8     7     6     5     4     3     2     1    0
         //                   {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0,  spp, 1'b0, 1'b0, spie, upie, 1'b0, 1'b0,  sie, uie};
         12'h100:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sstatus;
            csr_fwd_data      = nxt_Scsr.sstatus;
         end

         // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
         // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged
         `ifdef ext_N
         // ------------------------------ Supervisor Exception Delegation Register.
         // 12'h102 = 12'b0001_0000_0010  sedeleg  (read-write)
         12'h102:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sedeleg;
            csr_fwd_data      = nxt_Scsr.sedeleg;
         end

         // ------------------------------ Supervisor Interrupt Delegation Register.
         // 12'h103 = 12'b0001_0000_0011  sideleg  (read-write)
         12'h103:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sideleg;
            csr_fwd_data      = nxt_Scsr.sideleg;
         end
         `endif // ext_N

         // ------------------------------ Supervisor Interrupt Enable Register.
         // 12'h104 = 12'b0001_0000_0100  sie         (read-write)
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,   seie,  0,    0,    0,   stie,  0,    0,    0,   ssie,  0}; riscv-privileged draft 1.12
         12'h104:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sie;
            csr_fwd_data      = nxt_Scsr.sie;
         end

         // ------------------------------ Supervisor Trap handler base address.
         // 12'h105 = 12'b0001_0000_0101  stvec       (read-write)
         // Only MODE values of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
         12'h105:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.stvec;
            csr_fwd_data      = nxt_Scsr.stvec;
         end

         // 12/31/202 - Andrew Waterman "scounteren only exists if S Mode is implemented"
         // ------------------------------ Supervisor Counter Enable.
         // 12'h106 = 12'b0001_0000_0110  scounteren  (read-write)
         12'h106:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.scounteren;
            csr_fwd_data      = nxt_Scsr.scounteren;
         end

         // ------------------------------ Supervisor Scratch Register
         // Scratch register for supervisor trap handlers.
         // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
         12'h140:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sscratch;
            csr_fwd_data      = nxt_Scsr.sscratch;
         end

         // ------------------------------ Supervisor Exception Program Counter.
         // 12'h141 = 12'b0001_0100_0001  sepc        (read-write)
         12'h141:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sepc;
            csr_fwd_data      = nxt_Scsr.sepc;
         end

         // ------------------------------ Supervisor Trap Cause.
         // 12'h142 = 12'b0001_0100_0010  scause      (read-write)
         12'h142:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.scause;
            csr_fwd_data      = nxt_Scsr.scause;
         end

         // ------------------------------ Supervisor Trap Value = bad address or instruction.
         // 12'h143 = 12'b0001_0100_0011  stval       (read-write)
         12'h143:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.scause;
            csr_fwd_data      = nxt_Scsr.scause;
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
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.sip;
            csr_fwd_data      = nxt_Scsr.sip;
         end

         // ------------------------------ Supervisor Protection and Translation
         // Supervisor address translation and protection.
         // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
         12'h180:
         begin
            csr_rd_avail      = TRUE;
            csr_rd_data       = Scsr.satp;
            csr_fwd_data      = nxt_Scsr.satp;
         end
         `endif // ext_S

         `ifdef ext_U
         // ==================================================================== User Mode Registers ====================================================================
            `ifdef ext_N
            // ------------------------------ User Status Register
            // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
            //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
            // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};
            12'h000:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.ustatus;
               csr_fwd_data      = nxt_Ucsr.ustatus;
            end

            // ------------------------------ User Floating-Point CSRs
            // 12'h001 - 12'h003



            // User Interrupt-Enable Register
            // 12'h004 = 12'b0000_0000_0100  uie         (read-write)  user mode
            //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
            // { 0,    0,    0,    0,   ueie,  0,    0,    0,   utie,  0,    0,    0,   usie}; riscv-privileged draft 1.12  p. 114
            12'h004:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.uie;
               csr_fwd_data      = nxt_Ucsr.uie;
            end

            // ------------------------------ User Trap Handler Base address
            // 12'h005 = 12'b0000_0000_0101  utvec       (read-write)  user mode
            12'h005:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.utvec;
               csr_fwd_data      = nxt_Ucsr.utvec;
            end

            // ------------------------------ User Trap Handling
            // Scratch register for user trap handlers.
            // 12'h040 = 12'b0000_0100_0000  uscratch    (read-write)
            12'h040:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.uscratch;
               csr_fwd_data      = nxt_Ucsr.uscratch;
            end

            // ------------------------------ User Exception Program Counter
            // 12'h041 = 12'b0000_0100_0001  uepc        (read-write)
            12'h041:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.uepc;
               csr_fwd_data      = nxt_Ucsr.uepc;
            end

            // ------------------------------ User Exception Cause
            // 12'h042 = 12'b0000_0100_0010  ucause      (read-write)
            12'h042:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.ucause;
               csr_fwd_data      = nxt_Ucsr.ucause;
            end

            // ------------------------------ User Trap Value = bad address or instruction
            // 12'h043 = 12'b0000_0100_0011  utval       (read-write)
            12'h043:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.utval;
               csr_fwd_data      = nxt_Ucsr.utval;
            end

            // ------------------------------ User Interrupt Pending.
            // 12'h044 = 12'b0000_0100_0100  uip         (read-write)
            //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
            // { 0,    0,    0,    0,   ueip,  0,    0,    0,   utip,  0,    0,    0,   usip}; riscv-privileged draft 1.12  p. 114
            12'h044:
            begin
               csr_rd_avail      = TRUE;
               csr_rd_data       = Ucsr.uip;
               csr_fwd_data      = nxt_Ucsr.uip;
            end
            `endif // ext_N
         `endif // ext_U
      endcase
   end // always_comb
endmodule
