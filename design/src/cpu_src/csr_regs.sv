// ----------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Kirk Weedman www.hdlexpress.com
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
// Description   :  Contains all Control & Status Registers. Provides the next CSR contents and the
//               :  current CSR contents based on csr_wr, csr_wr_addr, csr_wr_data, and other signals
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;
import csr_params_pkg::*;

module csr_regs
(
   input    logic             clk_in,
   input    logic             reset_in,

   input    logic [RSZ*2-1:0] mtime,

   input    logic       [1:0] mode,                   // current instruction mode
   input    logic       [1:0] nxt_mode,               // next mode on rising edge of clk_in. This is used when exception.flag = 1

   input    logic             ext_irq,
   input    logic             timer_irq,

   EPC_bus_intf.master        epc_bus,                // master: Mepc, Sepc, Uepc - needed by Execute stage

   CSR_REG_intf.master        csr_reg_bus,            // master: outputs: Ucsr, Scsr, Mcsr. Needed by mode_irq.sv and csr_sel_rdata.sv

   CSR_RD_intf.slave          csr_rd_bus,             // slave: inputs: csr_rd_addr, outputs: csr_rd_avail, csr_fwd_data

   CSR_WR_intf.slave          csr_wr_bus              // slave: input: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret
);

CSR_REG_intf   csr_nxt_reg_bus();                     // master: outputs: Dbg_mode, Ucsr, Scsr, Mcsr. Needed by csr_sel_rdata.sv


`ifdef ext_U
`ifdef ext_N
   assign epc_bus.Uepc = Ucsr.Uepc;

   UCSR        Ucsr, nxt_Ucsr;                        // all of the next User mode Control & Status Registers
   assign csr_reg_bus.Ucsr       = Ucsr;
   assign csr_nxt_reg_bus.Ucsr   = nxt_Ucsr;
`endif
`endif

`ifdef ext_S
   assign epc_bus.Sepc = Scsr.Sepc;

   SCSR        Scsr, nxt_Scsr;                        // all of the next Supervisor mode Control & Status Registers
   assign csr_reg_bus.Scsr       = Scsr;
   assign csr_nxt_reg_bus.Scsr   = nxt_Scsr;
`endif

assign epc_bus.Mepc = Mcsr.Mepc;

MCSR           Mcsr, nxt_Mcsr;                        // all of the next Machine mode Control & Status Registers
assign csr_reg_bus.Mcsr          = Mcsr;
assign csr_nxt_reg_bus.Mcsr      = nxt_Mcsr;

`ifdef add_DM
   Dbg_mode  = 1;    // !!!!!!!!!!!!!!!!!!!!! FIX THIS SOMEDAY !!!!!!!!!!!!!!!!!!
`endif

`define CSR_REG(md, name, reg_addr, INIT, RO_BITS)                                                                                                             \
   genvar ``md``_``name``_gv;                                                                                                                                  \
   generate                                                                                                                                                    \
      for (``md``_``name``_gv = 0; ``md``_``name``_gv < 32; ``md``_``name``_gv++)                                                                              \
      begin                                                                                                                                                    \
         if (RO_BITS[``md``_``name``_gv])                                                                                                                      \
         begin                                                                                                                                                 \
            assign nxt_``md``csr.``md``name[``md``_``name``_gv] = INIT[``md``_``name``_gv];                                                                    \
            assign     ``md``csr.``md``name[``md``_``name``_gv] = nxt_``md``csr.``md``name[``md``_``name``_gv];                                                \
         end                                                                                                                                                   \
         else                                                                                                                                                  \
         begin                                                                                                                                                 \
            always_comb                                                                                                                                        \
            begin                                                                                                                                              \
               if (reset_in)                                                                                                                                   \
                  nxt_``md``csr.``md``name[``md``_``name``_gv] = INIT[``md``_``name``_gv];                                                                     \
               else if (csr_wr & (csr_wr_addr == ``reg_addr``) & (mode >= ``md``_MODE))                                                                        \
                  nxt_``md``csr.``md``name[``md``_``name``_gv] = csr_wr_data[``md``_``name``_gv];   /* WARL, WARL affects should be done to csr_data */        \
               else                                                                                                                                            \
                  nxt_``md``csr.``md``name[``md``_``name``_gv] = ``md``csr.``md``name[``md``_``name``_gv]; /* no change */                                     \
            end                                                                                                                                                \
            always_ff @(posedge clk_in)   /* create a resetable, writable, Flop for this bit */                                                                \
               ``md``csr.``md``name[``md``_``name``_gv] <= nxt_``md``csr.``md``name[``md``_``name``_gv];   /* WARL, WARL affects should be done to csr_data */ \
         end                                                                                                                                                   \
      end                                                                                                                                                      \
   endgenerate

   logic    [RSZ-1:0] total_retired;

   // Signals from WB stae - which CSR to write to
   logic             csr_wr;
   logic      [11:0] csr_wr_addr;
   logic      [31:0] csr_wr_data;
   logic             sw_irq;
   EXCEPTION         exception;
   EVENTS            current_events;
   assign current_events   = csr_wr_bus.current_events;

   assign csr_wr           = csr_wr_bus.csr_wr;
   assign csr_wr_addr      = csr_wr_bus.csr_wr_addr;
   assign csr_wr_data      = csr_wr_bus.csr_wr_data;
   assign sw_irq           = csr_wr_bus.sw_irq;                // sw_irq, exception, current_events, uret, sret, mret
   assign exception        = csr_wr_bus.exception;

   `ifdef ext_U
   `ifdef ext_N
   logic             uret;
   assign uret             = csr_wr_bus.uret;
   `endif
   `endif

   `ifdef ext_S
   logic             sret;
   assign sret             = csr_wr_bus.sret;
   `endif

   logic             mret;
   assign mret             = csr_wr_bus.mret;

   // Get the current contents of CSR[csr_addr] and whether it's available or not
   csr_sel_rdata CSR_SEL
   (
      .mtime(mtime),                            // Input:

      .mode(mode),                              // Input:

      .csr_reg_bus(csr_reg_bus),                // slave:   inputs: Ucsr, Scsr, Mcsr

      .csr_nxt_reg_bus(csr_nxt_reg_bus),        // slave:   inputs: nxt_Ucsr, nxt_Scsr, nxt_Mcsr

      .csr_rd_bus(csr_rd_bus)                   // slave:   inputs: csr_rd_addr, outputs: csr_rd_avail, csr_fwd_data
   );

   // ================================================================== Machine Mode CSRs ==================================================================
   // ------------------------------ Machine Status Register
   // 12'h300 = 12'b0011_0000_0000  Mstatus                                   (read-write)   p. 56 riscv-privileged
   // mie,sie,uie    - global interrupt enables
   // mpie,spie,upie - pending interrupt enables
   // mpp, spp       - previous privileged mode stacks
   //  31        22   21  20   19   18   17    16:15 14:13 12:11 10:9  8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv, xs,   fs,   mpp,  2'b0, spp, mpie, 1'b0, spie, 1'b0,  mie, 1'b0,  sie, 1'b0};

   // (read-write)   p. 56 riscv-privileged
   // NOTE: nxt_Mcsr.??? is what the nxt read data will be after next rising clock edge - this can be used to determine forwarding data
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mstatus     = MSTAT_INIT;
      else
      begin
         nxt_Mcsr.Mstatus     = Mcsr.Mstatus;                                 // default unless overridden by logic below

//       nxt_Mcsr.Mstatus.tsr    = ?;  No logic for these bits yet!!!
//       nxt_Mcsr.Mstatus.tw     = ?;
//       nxt_Mcsr.Mstatus.tvm    = ?;
//       nxt_Mcsr.Mstatus.mxr    = ?;
//       nxt_Mcsr.Mstatus.sum    = ?;
//
//       nxt_Mcsr.Mstatus.xs     = ?;
//       nxt_Mcsr.Mstatus.fs     = ?;

`ifdef ext_S
         nxt_Mcsr.Mstatus.spp    = nxt_Scsr.Sstatus.spp;
         nxt_Mcsr.Mstatus.spie   = nxt_Scsr.Sstatus.spie;
         nxt_Mcsr.Mstatus.sie    = nxt_Scsr.Sstatus.sie;
`else
         nxt_Mcsr.Mstatus.spp    = 0;
         nxt_Mcsr.Mstatus.spie   = 0;
         nxt_Mcsr.Mstatus.sie    = 0;
`endif
         nxt_Mcsr.Mstatus.sd     = ((nxt_Mcsr.Mstatus.fs == 2'b11) || (nxt_Mcsr.Mstatus.xs == 2'b11));

         if ((Mcsr.Mstatus.spp != M_MODE) & mret)                             // If xPP̸=M, xRET also sets MPRV=0.
            nxt_Mcsr.Mstatus.mprv   = 0;
         `ifdef ext_S
         else if ((Scsr.Sstatus.spp != (M_MODE[0])) & sret)                   // spp is made from the lower bit of mode
            nxt_Mcsr.Mstatus.mprv   = 0;
         `endif

         if (exception.flag & (nxt_mode == M_MODE))                           // holds the previous privilege mode
            nxt_Mcsr.Mstatus.mpp    = mode;                                   // When a trap is taken from privilege mode y into privilege mode x, ... and xPP is set to y. p. 21 riscv-privileged.pdf 1.12-draft
         else if (mret)
         `ifdef ext_U
            nxt_Mcsr.Mstatus.mpp    = U_MODE;                                 // "and xPP is set to U (or M if user-mode is not supported)."
         `else
            nxt_Mcsr.Mstatus.mpp    = M_MODE;
         `endif
         else if (csr_wr & (csr_wr_addr == 12'h300) & (mode == M_MODE))       // xPP fields are WARL fields that can hold only privilege mode x and any implemented privilege mode lower than x.
            nxt_Mcsr.Mstatus.mpp    = csr_wr_data[12:11];                     // writable in M_MODE

         if (exception.flag & (nxt_mode == M_MODE))
            nxt_Mcsr.Mstatus.mpie   = Mcsr.Mstatus.mie;                       // When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE
         else if (mret)
            nxt_Mcsr.Mstatus.mpie   = 1'b1;                                   // When executing an xRET instruction, ... xPIE is set to 1;

         // p. 20 The xIE bits are in the low-order bits of status, allowing them to be atomically set or cleared with a single CSR instruction
         //       or cleared with a single CSR instruction.
         if (exception.flag & (nxt_mode == M_MODE))
            nxt_Mcsr.Mstatus.mie    = 1'b0;                                   // When a trap is taken from privilege mode y into privilege mode x, ... xIE is set to 0;
         else if (mret)
            nxt_Mcsr.Mstatus.mie    = Mcsr.Mstatus.mpie;                      // When executing an xRET instruction, supposing xPP holds the value y, xIE is set to xPIE;
         else if (csr_wr & (csr_wr_addr == 12'h300) & (mode == M_MODE))       // modes lower than Machine cannot modify mie bit
            nxt_Mcsr.Mstatus.mie    = csr_wr_data[3];
      end
   end
   always_ff @(posedge clk_in)
      Mcsr.Mstatus <= nxt_Mcsr.Mstatus;

   // ------------------------------ Machine ISA Register
   // 12'h301 = 12'b0011_0000_0001  Misa     (read-write)   p. 56 riscv-privileged
   // currently this is just a constant (all bits R0)
   // NOTE: if made to be writable, don't allow bit  2 to change to 1 if ext_C not defined
   // NOTE: if made to be writable, don't allow bit  5 to change to 1 if ext_F not defined
   // NOTE: if made to be writable, don't allow bit 12 to change to 1 if ext_M not defined
   // NOTE: if made to be writable, don't allow bit 13 to change to 1 if ext_N not defined
   // NOTE: if made to be writable, don't allow bit 18 to change to 1 if ext_S not defined
   // NOTE: if made to be writable, don't allow bit 20 to change to 1 if ext_U not defined
   // etc...
   `CSR_REG(M,isa,12'h301,MISA_INIT,MISA_RO)

   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28
   // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
   `ifdef MDLG // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // ------------------------------ Machine Exception Delegation Register
      // 12'h302 = 12'b0011_0000_0010  Medeleg                                (read-write)
      `CSR_REG(M,edeleg,12'h302,MEDLG_INIT,MEDLG_RO)

      // ------------------------------ Machine Interrupt Delegation Register
      // 12'h303 = 12'b0011_0000_0011  Mideleg                                (read-write)
      `CSR_REG(M,ideleg,12'h303,MIDLG_INIT,MIDLG_RO)
   `endif

   // ------------------------------ Machine Interrupt Enable Register
   // 12'h304 = 12'b0011_0000_0100  mie                                       (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meie, 1'b0, seie, 1'b0, mtie, 1'b0, stie, 1'b0, msie, 1'b0, ssie, 1'b0};
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mie   = 0;
      else
      begin
         nxt_Mcsr.Mie = Mcsr.Mie;                                             // default unless overrriden by logic

         `ifdef ext_S
         nxt_Mcsr.Mie.seie = Scsr.Sie.seie;
         nxt_Mcsr.Mie.stie = Scsr.Sie.stie;
         nxt_Mcsr.Mie.ssie = Scsr.Sie.ssie;
         `else
         nxt_Mcsr.Mie.seie = 0;
         nxt_Mcsr.Mie.stie = 0;
         nxt_Mcsr.Mie.ssie = 0;
         `endif

         if (csr_wr & (csr_wr_addr == 12'h304) & (mode == M_MODE))            // writable in M_MODE
         begin
            nxt_Mcsr.Mie.meie  = csr_wr_data[11];
            nxt_Mcsr.Mie.mtie  = csr_wr_data[7];
            nxt_Mcsr.Mie.msie  = csr_wr_data[3];                              // see sie bits ssie,stie,seie during 12'h304 CSR write
         end
      end
   end
   always_ff @(posedge clk_in)
      Mcsr.Mie <= nxt_Mcsr.Mie;
   // ------------------------------ Machine Trap Handler Base Address
   // 12'h305 = 12'b0011_0000_0101  Mtvec                                     (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   `CSR_REG(M,tvec,12'h305,MTVEC_MASKED,MTVEC_RO)

   // Andrew Waterman: 12/31/2020 - "There is also a clear statement that Mcounteren exists if and only if U mode is implemented"
   `ifdef ext_U
      // ------------------------------ Machine Counter Enable
      // 12'h306 = 12'b0011_0000_0110  Mcounteren                             (read-write)
      `CSR_REG(M,counteren,12'h306,MCNTEN_INIT,MCNTEN_RO)
   `endif

   // ------------------------------ Machine StatusH - additional status register
   // 12'h310 = 12'b0011_0001_0000  Mstatush                                  (read-write)



   // ------------------------------ Machine Counter Inhibit
   // If not implemented, set all bits to 0 => no inhibits will ocur
   // 12'h320 = 12'b0011_0010_00000  Mcountinhibit                            (read-write)
   // NOTE: bit 1 should always be "hardwired" to 0
   `CSR_REG(M,countinhibit,12'h320,{MINHIBIT_INIT[31:2],1'b0,MINHIBIT_INIT[0]},MINHIBIT_RO)

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
   // 12'h323 - 12'h33F  Mhpmevent3 - Mhpmevent31                             (read-write)
   `ifdef use_MHPM
   genvar m;
   generate
      for (m = 0; m < NUM_MHPM; m++)
      begin
         // Note: width of Mhpmevent[] is define as 5 bits - up to 32 different event selections
         `CSR_REG(M,hpmevent[m],12'h323+m,0,32'h0) //,EV_SEL_SZ)
      end
   endgenerate
   `endif

   // ------------------------------ Machine Scratch Register
   // 12'h340 = 12'b0011_0100_0000  Mscratch                                  (read-write)
   `CSR_REG(M,scratch,12'h340,MSCRATCH_INIT,MSCRATCH_RO)

   // ------------------------------ Machine Exception Program Counter
   // Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  Mepc                                      (read-write)   see riscv-privileged p 36
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mepc  = 0;
      else if ((exception.flag) & (nxt_mode == M_MODE))
         nxt_Mcsr.Mepc  = exception.pc;                                       // save exception pc - low bit is always 0 (see csr.sv)
      else if (csr_wr & (csr_wr_addr == 12'h341) & (mode == M_MODE))          // writable in M_MODE
         nxt_Mcsr.Mepc  = csr_wr_data & (Mcsr.Misa[2] ? ~32'h1 : ~32'h3);     // Software settable - low bit is always 0 (see csr.sv)
      else
         nxt_Mcsr.Mepc  = Mcsr.Mepc;
   end
   always_ff @(posedge clk_in)
      Mcsr.Mepc <= nxt_Mcsr.Mepc;

   // ------------------------------ Machine Exception Cause
   // 12'h342 = 12'b0011_0100_0010 Mcause
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mcause   = 0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_Mcsr.Mcause   = exception.cause;                                 // save code for exception cause
      else if (csr_wr & (csr_wr_addr == 12'h342) & (mode == M_MODE))          // writable in M_MODE
         nxt_Mcsr.Mcause   = csr_wr_data;                                     // Sotware settable
      else
         nxt_Mcsr.Mcause   = Mcsr.Mcause;                                     // Sotware settable
   end
   always_ff @(posedge clk_in)
      Mcsr.Mcause <= nxt_Mcsr.Mcause;

   // ------------------------------ Machine Exception Trap Value
   // 12'h343 = 12'b0011_0100_0011  Mtval                   (read-write)
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mtval = 0;
      else if (exception.flag & (nxt_mode == M_MODE))
         nxt_Mcsr.Mtval = exception.tval;                                     // save trap value for exception
      else if (csr_wr & (csr_wr_addr == 12'h343) & (mode == M_MODE))          // writable in M_MODE
         nxt_Mcsr.Mtval = csr_wr_data;                                        // Sotware settable
      else
         nxt_Mcsr.Mtval = Mcsr.Mtval;
   end
   always_ff @(posedge clk_in)
      Mcsr.Mtval <= nxt_Mcsr.Mtval;

   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  Mip                                       (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meip, 1'b0, seip, 1'b0, mtip, 1'b0, stip, 1'b0, msip, 1'b0, ssip, 1'b0}; riscv-privileged draft 1.12

   // Only the bits corresponding to lower-privilege software interrupts (USIP, SSIP), timer interrupts
   // (UTIP, STIP), and external interrupts (UEIP, SEIP) in mip are writable through this CSR address;
   // the remaining bits are read-only.

   // If an interrupt is delegated to privilege mode M by setting a bit in the mideleg register,
   // it becomes visible in the Mip register and is maskable using the Mie register.
   // Otherwise, the corresponding bits in Mip and Mie appear to be hardwired to zero. p 29

   // The machine-level MSIP bits are written by accesses to memory-mapped control registers,
   // which are used by remote harts to provide machine-mode interprocessor interrupts. p. 30
   always_comb
   begin
      if (reset_in)
         nxt_Mcsr.Mip      = 0;
      else
      begin
         nxt_Mcsr.Mip      = Mcsr.Mip;                                        // default unless overriden below

         `ifdef ext_S
         nxt_Mcsr.Mip.seip = nxt_Scsr.Sip.seip;
         nxt_Mcsr.Mip.stip = nxt_Scsr.Sip.stip;
         nxt_Mcsr.Mip.ssip = nxt_Scsr.Sip.ssip;
         `else
         nxt_Mcsr.Mip.seip = 0;
         nxt_Mcsr.Mip.stip = 0;
         nxt_Mcsr.Mip.ssip = 0;
         `endif

         // The meip field in Mip is a read-only bit that indicates a machine-mode external interrupt is pending. p 30 riscv-privileged.pdf
         if (mode == M_MODE)
            nxt_Mcsr.Mip.meip = ext_irq;                                      // External Interrupt Pending - bit 11

         // The MTIP bit is read-only and is cleared by writing to the memory-mapped machine-mode timer compare register
         if (mode == M_MODE)                                                  // irq setting only during Machine mode
            nxt_Mcsr.Mip.mtip = timer_irq;                                    // Timer Interrupt Pending - bit 7

         nxt_Mcsr.Mip.msip    = sw_irq;                                       // Software Interrupt Pending - bit 3 see irq.sv
      end
   end
   always_ff @(posedge clk_in)
      Mcsr.Mip <= nxt_Mcsr.Mip;

   // ------------------------------ Machine Protection and Translation - NOT YET IMPLEMENTED 1/31/2021
   // 12'h3A0 - 12'h3A3
   `ifdef USE_PMPCFG
      // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                                (read-write)
      `CSR_REG(M,pmpcfg0,12'h3A0,0,32'h0)
      // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                                (read-write)
      `CSR_REG(M,pmpcfg1,12'h3A1,0,32'h0)
      // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                                (read-write)
      `CSR_REG(M,pmpcfg2,12'h3A2,0,32'h0)
      // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                                (read-write)
      `CSR_REG(M,pmpcfg3,12'h3A3,0,32'h0)
   `endif

   // 12'h3B0 - 12'h3BF
   // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
   `ifdef PMP_ADDR0  `CSR_REG(M,pmpaddr0, 12'h3B0,0,32'h0) `endif
   `ifdef PMP_ADDR1  `CSR_REG(M,pmpaddr1, 12'h3B1,0,32'h0) `endif
   `ifdef PMP_ADDR2  `CSR_REG(M,pmpaddr2, 12'h3B2,0,32'h0) `endif
   `ifdef PMP_ADDR3  `CSR_REG(M,pmpaddr3, 12'h3B3,0,32'h0) `endif
   `ifdef PMP_ADDR4  `CSR_REG(M,pmpaddr4, 12'h3B4,0,32'h0) `endif
   `ifdef PMP_ADDR5  `CSR_REG(M,pmpaddr5, 12'h3B5,0,32'h0) `endif
   `ifdef PMP_ADDR6  `CSR_REG(M,pmpaddr6, 12'h3B6,0,32'h0) `endif
   `ifdef PMP_ADDR7  `CSR_REG(M,pmpaddr7, 12'h3B7,0,32'h0) `endif
   `ifdef PMP_ADDR8  `CSR_REG(M,pmpaddr8, 12'h3B8,0,32'h0) `endif
   `ifdef PMP_ADDR9  `CSR_REG(M,pmpaddr9, 12'h3B9,0,32'h0) `endif
   `ifdef PMP_ADDR10 `CSR_REG(M,pmpaddr10,12'h3BA,0,32'h0) `endif
   `ifdef PMP_ADDR11 `CSR_REG(M,pmpaddr11,12'h3BB,0,32'h0) `endif
   `ifdef PMP_ADDR12 `CSR_REG(M,pmpaddr12,12'h3BC,0,32'h0) `endif
   `ifdef PMP_ADDR13 `CSR_REG(M,pmpaddr13,12'h3BD,0,32'h0) `endif
   `ifdef PMP_ADDR14 `CSR_REG(M,pmpaddr14,12'h3BE,0,32'h0) `endif
   `ifdef PMP_ADDR15 `CSR_REG(M,pmpaddr15,12'h3BF,0,32'h0) `endif

   `ifdef add_DM
      // ------------------------------  Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
      `CSR_REG(M,tselect,12'h7A0,0,32'h0)                                     // Trigger Select Register
      `CSR_REG(M,tdata1, 12'h7A1,0,32'h0)                                     // Trigger Data Register 1
      `CSR_REG(M,tdata2, 12'h7A2,0,32'h0)                                     // Trigger Data Register 2
      `CSR_REG(M,tdata3, 12'h7A3,0,32'h0)                                     // Trigger Data Register 3

      // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
      // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
      `CSR_REG(M,dcsr,      12'h7B0,0,32'h0)                                  // Debug Control and Status Register
      `CSR_REG(M,dpc,       12'h7B1,0,32'h0)                                  // Debug PC Register
      `CSR_REG(M,dscratch0, 12'h7B2,0,32'h0)                                  // Debug Scratch Register 0
      `CSR_REG(M,dscratch1, 12'h7B3,0,32'h0)                                  // Debug Scratch Register 1
   `endif // add_DM

   // ------------------------------ Machine Cycle Counter
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // Mhpmcountern, respectively. p 34 risvcv-privileged.pdf
   // p 136 "Cycle counter for RDCYCLE instruction"
   //
   // Lower 32 bits of mcycle, RV32I only.
   // 12'hB00 = 12'b1011_0000_0000  Mcycle_lo (read-write)
   //
   // Upper 32 bits of mcycle, RV32I only.
   // 12'hB80 = 12'b1011_1000_0000  Mcycle_hi (read-write)
   //
   always_comb
   begin
      if (reset_in)
         {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo}   = 0;
      else if (csr_wr && (csr_wr_addr == 12'hB00) & (mode == M_MODE))
         {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo}   = {Mcsr.Mcycle_hi,csr_wr_data};
      else if (csr_wr && (csr_wr_addr == 12'hB80) & (mode == M_MODE))
         {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo}   = {csr_wr_data,Mcsr.Mcycle_lo};
      else if (!Mcsr.Mcountinhibit[0])
         {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo}   = 2*RSZ ' ({Mcsr.Mcycle_hi,Mcsr.Mcycle_lo} + 'd1);  // increment counter/timer - cast result to 2*RSZ bits before assigning
      else
         {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo}   = {Mcsr.Mcycle_hi,Mcsr.Mcycle_lo};
   end
   always_ff @(posedge clk_in)
      {Mcsr.Mcycle_hi,Mcsr.Mcycle_lo} <= {nxt_Mcsr.Mcycle_hi,nxt_Mcsr.Mcycle_lo};

   // ------------------------------ Machine Instructions-Retired Counter
   // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
   // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf
   //
   // Lower 32 bits of minstret, RV32I only.
   // 12'hB02 = 12'b1011_0000_0010  Minstret_lo                               (read-write)
   //
   // Upper 32 bits of minstret, RV32I only.
   // 12'hB82 = 12'b1011_1000_0010  Minstret_hi                               (read-write)

//   `CSR_REG(M,instret_lo,12'hB02,MINSTRET_LO_INIT,MINSTRET_LO_RO)            // Timer Lower 32 bits
//   `CSR_REG(M,instret_hi,12'hB82,MINSTRET_HI_INIT,MINSTRET_HI_RO)            // Timer Higher 32 bits
   always_comb
   begin
      if (reset_in)
         {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo}  = 0;
      else if (csr_wr && (csr_wr_addr == 12'hB02))                            // writable in M_MODE
         {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo}  = {Mcsr.Minstret_hi,csr_wr_data};
      else if (csr_wr && (csr_wr_addr == 12'hB82))                            // writable in M_MODE
         {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo}  = {csr_wr_data,Mcsr.Minstret_lo};
      else if (!Mcsr.Mcountinhibit[2])
         {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo}  = 2*RSZ ' ({Mcsr.Minstret_hi,Mcsr.Minstret_lo} + total_retired);    // cast result to 2*RSZ bits before assigning
      else
         {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo}  = {Mcsr.Minstret_hi,Mcsr.Minstret_lo};
   end
   always_ff @(posedge clk_in)
      {Mcsr.Minstret_hi,Mcsr.Minstret_lo} = {nxt_Mcsr.Minstret_hi,nxt_Mcsr.Minstret_lo};
   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
   // At most, for this pipelined design, only 1 instruction can retire per clock so just OR the retire bits (instead of adding)
   // Just assign the hpm_events that will be used and comment those that are not used. Also adjust the number (i.e. 24 right now)
   assign total_retired = current_events.ret_cnt[LD_RET]  | current_events.ret_cnt[ST_RET]   | current_events.ret_cnt[CSR_RET]  | current_events.ret_cnt[SYS_RET]  |
                          current_events.ret_cnt[ALU_RET] | current_events.ret_cnt[BXX_RET]  | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET] |
                          current_events.ret_cnt[IM_RET]  | current_events.ret_cnt[ID_RET]   | current_events.ret_cnt[IR_RET]   | current_events.ret_cnt[HINT_RET] |
            `ifdef ext_F  current_events.ret_cnt[FLD_RET] | current_events.ret_cnt[FST_RET]  | current_events.ret_cnt[FP_RET]   | `endif
                          current_events.ret_cnt[UNK_RET];

   // =============================================== Hardware Performance-Monitoring Event selectors  ===============================================
   `ifdef use_MHPM
      logic       br_cnt;
      logic       misaligned_cnt;
      logic       hpm_events[0:NUM_EVENTS-1]; // 1 bit needed per event for this design (1 instruction max per clock cycle in RisKy1 design)
      // Note: currently there are NUM_EVENTS=24 hpm_events. The number can be changed if more or less event types are needed. see csr_params_pkg.sv to change.


      assign br_cnt           = current_events.ret_cnt[BXX_RET] | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET];
      assign misaligned_cnt   = (current_events.e_flag & (current_events.e_cause == 0)) |    /* 0 = Instruction Address Misaligned */
                                (current_events.e_flag & (current_events.e_cause == 4)) |    /* 4 = Load Address Misaligned        */
                                (current_events.e_flag & (current_events.e_cause == 6));     /* 6 = Store Address Misaligned       */

      assign hpm_events[0 ]      = 0;                                         // no change to mhpm counter when this even selected
      // The following hpm_events return a count value which is used by a Mhpmcounter[]. Mhpmcounter[n] can use whichever event[x] it wants by setting mphmevent[n]
      // The count sources (i.e. current_events.ret_cnt[LD_RET]) may be changed by the user to reflect what information they want to use for a given counter.
      // Any of the logic on the RH side of the assignment can changed or used for any hpm_events[x] - even new logic can be created for a new event source.
      assign hpm_events[1 ]      = current_events.ret_cnt[LD_RET];            // Load Instruction retirement count. See ret_cnt[] in cpu_structs_pkg.sv. One ret_cnt for each instruction type.
      assign hpm_events[2 ]      = current_events.ret_cnt[ST_RET];            // Store Instruction retirement count.
      assign hpm_events[3 ]      = current_events.ret_cnt[CSR_RET];           // CSR
      assign hpm_events[4 ]      = current_events.ret_cnt[SYS_RET];           // System
      assign hpm_events[5 ]      = current_events.ret_cnt[ALU_RET];           // ALU
      assign hpm_events[6 ]      = current_events.ret_cnt[BXX_RET];           // BXX
      assign hpm_events[7 ]      = current_events.ret_cnt[JAL_RET];           // JAL
      assign hpm_events[8 ]      = current_events.ret_cnt[JALR_RET];          // JALR
      assign hpm_events[9 ]      = current_events.ret_cnt[IM_RET];            // Integer Multiply
      assign hpm_events[10]      = current_events.ret_cnt[ID_RET];            // Integer Divide
      assign hpm_events[11]      = current_events.ret_cnt[IR_RET];            // Integer Remainder
      assign hpm_events[12]      = current_events.ret_cnt[HINT_RET];          // Hint Instructions
      assign hpm_events[13]      = current_events.ret_cnt[UNK_RET];           // Unknown Instructions
      assign hpm_events[14]      = current_events.e_flag ? (current_events.e_cause == 0) : 0; // e_cause = 0 = Instruction Address Misaligned
      assign hpm_events[15]      = current_events.e_flag ? (current_events.e_cause == 1) : 0; // e_cause = 1 = Instruction Access Fault
      assign hpm_events[16]      = current_events.e_flag ? (current_events.e_cause == 2) : 0; // e_cause = 2 = Illegal Instruction
      assign hpm_events[17]      = br_cnt;                                    // all bxx, jal, jalr instructions
      assign hpm_events[18]      = misaligned_cnt;                            // all misaligned instructions
      assign hpm_events[19]      = total_retired;                             // total of all instructions retired this clock cycle
      `ifdef ext_F
         assign hpm_events[20]   = current_events.ret_cnt[FLD_RET];           // single precision Floating Point Load retired
         assign hpm_events[21]   = current_events.ret_cnt[FST_RET];           // single precision Floating Point Store retired
         assign hpm_events[22]   = current_events.ret_cnt[FP_RET];            // single precision Floating Point operation retired
         assign hpm_events[23]   = current_events.ext_irq;                    // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
      `else
         assign hpm_events[20]   = current_events.e_flag ? (current_events.e_cause == 3) : 0; // e_cause = 3 = Environment Break
         assign hpm_events[21]   = current_events.e_flag ? (current_events.e_cause == 6) : 0; // e_cause = 6 = Store Address Misaligned
         assign hpm_events[22]   = current_events.e_flag ? (current_events.e_cause == 8) : 0; // e_cause = 8 = User ECALL
         assign hpm_events[23]   = current_events.ext_irq;                    // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
      `endif // ext_F
   `endif

   // ------------------------------ Machine Hardware Performance-Monitoring Event Counters
   // Lower 32 bits of Mhpmcounter3 - Mhpmcounter31, RV32I only.
   // 12'hB03 - 12'hB1F  Mhpmcounter3 - Mhpmcounter31                         (read-write)
   //
   // Upper 32 bits of Mhpmcounter3 - Mhpmcounter31, RV32I only.
   // 12'hB83 - 12'hB9F Mhpmcounter3h - Mhpmcounter31h                        (read-write)

   `ifdef use_MHPM
   genvar n;  // n must be a genvar even though we cannot use generate/endgenerate due to logic being nested inside "if (NUM_MHPM)"
   generate
      for (n = 0; n < NUM_MHPM; n++)
      begin : MHPM_CNTR_EVENTS
         // Machine hardware performance-monitoring counters
         // increment Mhpmcounter[] if the Event Selector is not 0 and the corresponding mcountinhibit[] bit is not set.
         // currently there are 24 possible hpm_events[], where event[0] = 0
         // Lower 32 bits of Mhpmcounter3 - Mhpmcounter31, RV32I only.
         // 12'hB03 - 12'hB1F  Mhpmcounter3 - Mhpmcounter31                   (read-write)

         // Upper 32 bits of Mhpmcounter3 - Mhpmcounter31, RV32I only.
         // 12'hB83 - 12'hB9F Mhpmcounter3h - Mhpmcounter31h                  (read-write)
         always_comb
         begin
            if (csr_wr && (csr_wr_addr == (12'hB03+n)))                          // writable in M_MODE
               {nxt_Mcsr.Mhpmcounter_hi[n], nxt_Mcsr.Mhpmcounter_lo[n]} = {Mcsr.Mhpmcounter_hi[n],csr_wr_data};
            else if (csr_wr && (csr_wr_addr == (12'hB83+n)))                    // writable in M_MODE
               {nxt_Mcsr.Mhpmcounter_hi[n], nxt_Mcsr.Mhpmcounter_lo[n]} = {csr_wr_data,Mcsr.Mhpmcounter_lo[n]};
            else
               {nxt_Mcsr.Mhpmcounter_hi[n], nxt_Mcsr.Mhpmcounter_lo[n]} = Mcsr.mcountinhibit[n+3] ? {Mcsr.Mhpmcounter_hi[n], Mcsr.Mhpmcounter_lo[n]} :
                 2*RSZ ' ({Mcsr.Mhpmcounter_hi[n], Mcsr.Mhpmcounter_lo[n]} + hpm_events[Mcsr.Mhpmevent[n]]); // cast result to 2*RSZ bits before assigning
         end
         always_ff @(posedge clk_in)
            {Mcsr.Mhpmcounter_hi[n], Mcsr.Mhpmcounter_lo[n]} <= {nxt_Mcsr.Mhpmcounter_hi[n], nxt_Mcsr.Mhpmcounter_lo[n]};
      end
   endgenerate
   `endif // use_MHPM

   // ------------------------------ Machine Information Registers
   // Vendor ID
   // 12'hF11 = 12'b1111_0001_0001  Mvendorid   (read-only)
   `CSR_REG(M,vendorid,12'hF11,M_VENDOR_ID,M_VENDOR_ID_RO)

   // Architecture ID
   // 12'hF12 = 12'b1111_0001_0010  Marchid     (read-only)
   `CSR_REG(M,archid,12'hF12,M_ARCH_ID,M_ARCH_ID_RO)

   // Implementation ID
   // 12'hF13 = 12'b1111_0001_0011  Mimpid      (read-only)
   `CSR_REG(M,impid,12'hF13,M_IMP_ID,M_IMP_ID_RO)

   // Hardware Thread ID
   // 12'hF14 = 12'b1111_0001_0100  Mhartid     (read-only)
   `CSR_REG(M,hartid,12'hF14,M_HART_ID,M_HART_ID_RO)

   // ================================================================== Supervisor Mode CSRs ===============================================================
   `ifdef ext_S
      // ------------------------------ Supervisor Status Register
      // The Sstatus register is a subset of the Mstatus register. In a straightforward implementation,
      // reading or writing any field in Sstatus is equivalent to reading or writing the homonymous field
      // in Mstatus
      // 12'h100 = 12'b0001_0000_0000  Sstatus        (read-write)
      //                   31    30:23 22    21    20     19    18    17     16:15 14:13 12:11    10:9   8   7     6     5     4     3     2     1    0
      // Scsr.Sstatus    = {                                                                             spp, 1'b0, 1'b0, spie, upie, 1'b0, 1'b0, sie, uie}; // see csr.sv

      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Sstatus  = SSTAT_INIT;                                   // Currrently unused bits
         begin
            nxt_Scsr.Sstatus  = Scsr.Sstatus;                                 // Default unless overridden below

            if (exception.flag & (nxt_mode == S_MODE))
               nxt_Scsr.Sstatus.spp    = mode[0];                             // spp = Supervisor Prevous Privileged mode
            else if (sret)                                                    // Note: S mode implies there's a U-mode because S mode is not allowed unless U is supported
               nxt_Scsr.Sstatus.spp    = 1'b0;                                // "and xPP is set to U (or M if user-mode is not supported)." p. 20 riscv-privileged-v1.10

            if (exception.flag & (nxt_mode == S_MODE))
               nxt_Scsr.Sstatus.spie   = Scsr.Sstatus.sie;                    // spie <= sie
            else if (sret)
               nxt_Scsr.Sstatus.spie   = TRUE;                                // "xPIE is set to 1"

            // p. 20 The xIE bits are located in the low-order bits of Mstatus, allowing them to be atomically set
            //       or cleared with a single CSR instruction.
            if (exception.flag & (nxt_mode == S_MODE))
               nxt_Scsr.Sstatus.sie    = 1'b0;
            else if (sret)                                                    // "xIE is set to xPIE;"
               nxt_Scsr.Sstatus.sie    = Scsr.Sstatus.spie;
            else if (csr_wr & (csr_wr_addr[8:0] == 9'h100) & (mode >=S_MODE)) // writable in M or S mode
               nxt_Scsr.Sstatus.sie    = csr_wr_data[1];
         end
      end
      always_ff @(posedge clk_in)
         Scsr.Sstatus <= nxt_Scsr.Sstatus;

      // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
      // exist if the N extension for user-mode interrupts is also implemented. p 30 riscv-privileged.pdf 1.12-draft
      `ifdef ext_N
         // ------------------------------ Supervisor Exception Delegation Register.
         // 12'h102 = 12'b0001_0000_0010  Sedeleg                             (read-write)
         `CSR_REG(S,edeleg,12'h102,SEDLG_INIT,SEDLG_RO)

         // ------------------------------ Supervisor Interrupt Delegation Register.
         // 12'h103 = 12'b0001_0000_0011  Sideleg                             (read-write)
         `CSR_REG(S,ideleg,12'h103,SIDLG_INIT,SIDLG_RO)
      `endif // ext_N

      // ------------------------------ Supervisor Interrupt Enable Register.
      // 12'h104 = 12'b0001_0000_0100  Sie                                    (read-write)
      `CSR_REG(S,ie,12'h104,SIE_INIT,SIE_RO)                                  // bits 9, 5, 1 are read-write, others are read only

      // ------------------------------ Supervisor Trap handler base address.
      // 12'h105 = 12'b0001_0000_0101  Stvec                                  (read-write)
      // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
      `CSR_REG(S,tvec,12'h105,STVEC_MASK,STVEC_RO)

      // 12/31/2020 - Andrew Waterman "scounteren only exists if S Mode is implemented"
      // ------------------------------ Supervisor Counter Enable.
      // 12'h106 = 12'b0001_0000_0110  Scounteren                             (read-write)
      `CSR_REG(S,counteren,12'h106,SCNTEN_INIT,SCNTEN_RO)

      // ------------------------------ Supervisor Scratch Register
      // Scratch register for supervisor trap handlers.
      // 12'h140 = 12'b0001_0100_0000  Sscratch                               (read-write)
      `CSR_REG(S,scratch,12'h140,SSCRATCH_INIT,SSCRATCH_RO)

      // ------------------------------ Supervisor Exception Program Counter
      // 12'h141 = 12'b0001_0100_0001  Sepc                                   (read-write)
      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Sepc  = 0;                                               // ls-bit is RO so it remains at 0 after reset
         else if ((exception.flag) & (nxt_mode == S_MODE))
            nxt_Scsr.Sepc  = exception.pc;                                    // save exception pc - low bit is always 0 (see csr.sv)
         else if (csr_wr & (csr_wr_addr[8:0] == 9'h141) & (mode >= S_MODE))   // writable in mode >= S_MODE
            nxt_Scsr.Sepc  = csr_wr_data & (Mcsr.Misa[2] ? ~32'h1 : ~32'h3);  // Software settable  - low bit is always 0 (see csr.sv)
         else
            nxt_Scsr.Sepc  = Scsr.Sepc;
      end
      always_ff @(posedge clk_in)
         Scsr.Sepc <= nxt_Scsr.Sepc;

      // ------------------------------ Supervisor Exception Cause
      // 12'h142 = 12'b0001_0100_0010  Scause                                 (read-write)
      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Scause   = 0;                                            // ls-bit is RO so it remains at 0 after reset
         else if (exception.flag & (nxt_mode == S_MODE))
            nxt_Scsr.Scause   = exception.cause;                              // save code for exception cause
         else if (csr_wr & (csr_wr_addr[8:0] == 9'h142) & (mode >= S_MODE))   // writable in mode >= S_MODE
            nxt_Scsr.Scause   = csr_wr_data[3:0];                             // Sotware settable - currently Scause is only 4 bits wide
         else
            nxt_Scsr.Scause   = Scsr.Scause;
      end
      always_ff @(posedge clk_in)
         Scsr.Scause <= nxt_Scsr.Scause;

      // ------------------------------ Supervisor Exception Trap Value       see p 9,30,67 riscv-privileged.pdf 1.12-draft
      // 12'h143 = 12'b0001_0100_0011  Stval                                  (read-write)
      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Stval    = 0;                                            // ls-bit is RO so it remains at 0 after reset
         else if (exception.flag & (nxt_mode == S_MODE))
            nxt_Scsr.Stval    = exception.tval;                               // save code for exception cause
         else if (csr_wr & (csr_wr_addr[8:0] == 9'h143) & (mode >= S_MODE))   // writable in mode >= S_MODE
            nxt_Scsr.Stval    = csr_wr_data;                                  // Sotware settable
         else
            nxt_Scsr.Stval    = Scsr.Stval;
      end
      always_ff @(posedge clk_in)
         Scsr.Stval <= nxt_Scsr.Stval;

      // ------------------------------ Supervisor Interrupt Pending bits
      // 12'h144 = 12'b0001_0100_0100  Sip                  (read-write)
      //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
      // {20'b0, 1'b0, 1'b0, seip, 1'b0, 1'b0, 1'b0, stip, 1'b0, 1'b0, 1'b0, ssip, 1'b0};
      // Uip = mip & MASK -> see csr.sv

      // If implemented, seip is read-only in Sip, and is set and cleared by the
      // execution environment, typically through a platform-specific interrupt controller. see p 63 riscv-privileged 1.12-draft
      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Sip   = 0;
         else
         begin
            nxt_Scsr.Sip   = Scsr.Sip;                                        // default unless overriden by logic below

            nxt_Scsr.Sip.ssip = nxt_Ucsr.Uip.usip;
            nxt_Scsr.Sip.stip = nxt_Ucsr.Uip.utip;
            nxt_Scsr.Sip.seip = nxt_Ucsr.Uip.ueip;

            if (sw_irq)
               nxt_Scsr.Sip.ssip = TRUE;                                      // software interrupt = msip_reg[] see irq.sv

            // if implemented, stip is read-only in Sip, and is set and cleared by the execution environment. see p 63 riscv-privileged 1.12-draft
            if (mode == S_MODE)
               nxt_Scsr.Sip.stip = timer_irq;                                 // timer interrupt

            // If implemented, ssip is writable in Sip.... p. 63 riscv-privileged.pdf 1.12-draft
            if (csr_wr & (csr_wr_addr == 12'h344) & (mode == M_MODE))
               nxt_Scsr.Sip.seip = csr_wr_data[9];
            else if (mode == S_MODE)
               nxt_Scsr.Sip.seip = ext_irq;                                   // external interrupt
         end
      end
      always_ff @(posedge clk_in)
         Scsr.Sip <= nxt_Scsr.Sip;

      // ------------------------------ Supervisor Address Translation and Protection
      // Supervisor address translation and protection.
      // 12'h180 = 12'b0001_1000_0000  Satp                                   (read-write)
      always_comb
      begin
         if (reset_in)
            nxt_Scsr.Satp  = FALSE;
         else if (csr_wr & (csr_wr_addr[8:0] == 9'h180) & (mode >= S_MODE))   // writable in mode >= S_MODE
            nxt_Scsr.Satp  = csr_wr_data;
         else
            nxt_Scsr.Satp  = Scsr.Satp;
      end
      always_ff @(posedge clk_in)
         Scsr.Satp <= nxt_Scsr.Satp;
   `endif // ext_S

   // ================================================================== User Mode CSRs =====================================================================
   `ifdef ext_U
      `ifdef ext_F
         // ------------------------------ User Floating-Point CSRs
         // 12'h001 - 12'h003
         if (csr_wr & (csr_wr_addr == 12'h001))
            Ucsr.???? <= Ucsr.????
         else
            Ucsr.???? <= Ucsr.????

         if (csr_wr & (csr_wr_addr == 12'h002))
            Ucsr.???? <= Ucsr.????
         else
            Ucsr.???? <= Ucsr.????

         if (csr_wr & (csr_wr_addr == 12'h003))
            Ucsr.???? <= Ucsr.????
         else
            Ucsr.???? <= Ucsr.????
      `endif   // ext_F

      `ifdef ext_N
         // ------------------------------ User Status Register
         // 12'h000 = 12'b0000_0000_0000  Ustatus     (read-write)  user mode
         //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
         // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};

         // p. 21. To support nested traps, each privilege mode x has a two-level stack of interrupt-enable
         //        bits and privilege modes. xPIE holds the value of the interrupt-enable bit active
         //        prior to the trap, and xPP holds the previous privilege mode.

         // p. 21  When a trap is taken from privilege mode y into privilege mode x, xPIE is set to the value of xIE;
         //        xIE is set to 0; and xPP is set to y.

         // p. 21  The MRET, SRET, or URET instructions are used to return from traps in M-mode, S-mode, or
         //        U-mode respectively. When executing an xRET instruction, supposing xPP holds the value y, xIE
         //        is set to xPIE; the privilege mode is changed to y; xPIE is set to 1; and xPP is set to U (or M if
         //        user-mode is not supported).
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Ustatus  = USTAT_INIT;
            else
            begin
               nxt_Ucsr.Ustatus  = Ucsr.Ustatus;                              // default unless overrriden by logic below

//             nxt_Ucsr.Ustatus.sd  = sd;             // bit  [31]      - no logic yet for this  bit
//             nxt_Ucsr.Ustatus.mxr = mxr;            // bit  [19]      - no logic yet for this  bit
//             nxt_Ucsr.Ustatus.sum = sum;            // bit  [18]      - no logic yet for this  bit
//             nxt_Ucsr.Ustatus.xs  = xs;             // bits [16:15]   - no logic yet for these bits
//             nxt_Ucsr.Ustatus.fs  = fs;             // bits [14:13]   - no logic yet for these bits

               if (exception.flag & (nxt_mode == U_MODE))
                  nxt_Ucsr.Ustatus.upie   = Ucsr.Ustatus.uie;
               else if (uret)
                  nxt_Ucsr.Ustatus.upie   = 1'b1;

               // p. 20 The xIE bits are located in the low-order bits of Mstatus, allowing them to be atomically set
               //       or cleared with a single CSR instruction.
               if (exception.flag & (nxt_mode == U_MODE))
                  nxt_Ucsr.Ustatus.uie    = 1'b0;
               else if (uret)
                  nxt_Ucsr.Ustatus.uie    = Ucsr.Ustatus.upie;                // "xIE is set to xPIE;"  p. 21 riscv-privileged.pdf
               else if (csr_wr && (csr_wr_addr[7:0] == 8'h00))                // writable in all modes
                  nxt_Ucsr.Ustatus.uie    = csr_wr_data[0];
            end
         end
         always_ff @(posedge clk_in)
            Ucsr.Ustatus <= nxt_Ucsr.Ustatus;

         // ------------------------------ User Interrupt-Enable Register
         // 12'h004 = 12'b0000_0000_0100  Uie         (read-write)  user mode
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,    0,   ueie,  0,    0,    0,   utie,  0,    0,    0,   usie}; riscv-privileged draft 1.12  p. 114
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Uie      = 0;
            else if (csr_wr & (csr_wr_addr[7:0] == 8'h04))                    // writable in all modes
            begin
               nxt_Ucsr.Uie = 0;                                              // 0 value into bits [31:9],7:5],[3:1]
               nxt_Ucsr.Uie.usie = csr_wr_data[0];
               nxt_Ucsr.Uie.utie = csr_wr_data[4];
               nxt_Ucsr.Uie.ueie = csr_wr_data[8];
            end
            else
               nxt_Ucsr.Uie = Ucsr.Uie;
         end
         always_ff @(posedge clk_in)
            Ucsr.Uie <= nxt_Ucsr.Uie;

         // ------------------------------ User Trap Handler Base address
         // 12'h005 = 12'b0000_0000_0101  Utvec                               (read-write)  user mode
         // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Utvec = UTVEC_INIT;
            else if (csr_wr & (csr_wr_addr[7:0] == 8'h05))                    // writable in all modes
               nxt_Ucsr.Utvec = {csr_wr_data[31:2],1'b0,csr_wr_data[0]};      // see csr.sv - value written may be masked going into register
            else
               nxt_Ucsr.Utvec = Ucsr.Utvec;
         end
         always_ff @(posedge clk_in)
            Ucsr.Utvec <= Ucsr.Utvec;

         // ------------------------------ User Trap Handling
         // Scratch register for user trap handlers.
         // 12'h040 = 12'b0000_0100_0000  Uscratch                            (read-write)
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Uscratch = 0;
            else if (csr_wr & (csr_wr_addr[7:0] == 8'h40))                    // writable in all modes
               nxt_Ucsr.Uscratch = csr_wr_data;
            else
               nxt_Ucsr.Uscratch = Ucsr.Uscratch;
         end
         always_ff @(posedge clk_in)
            Ucsr.Uscratch <= Ucsr.Uscratch;

         // ------------------------------ User Exception Program Counter
         // 12'h041 = 12'b0000_0100_0001  Uepc                                (read-write)
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Uepc  = {UEXC_PC_INIT[31:1],1'b0};                    // ls-bit is Read Only so it remains at 0 after reset
            else if (exception.flag & (nxt_mode == U_MODE))                   // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_Ucsr.Uepc  = exception.pc;                                 // save exception pc - ls bit is Read Only and thus always 0 (see csr.sv)
            else if (csr_wr & (csr_wr_addr[7:0] == 8'h41))                    // writable in all modes
               nxt_Ucsr.Uepc  = csr_wr_data & (Mcsr.Misa[2] ? ~32'h1 : ~32'h3); // Software settable - low bit is always 0 (see csr.sv)
            else
               nxt_Ucsr.Uepc  = Ucsr.Uepc;
         end
         always_ff @(posedge clk_in)
            Ucsr.Uepc <= nxt_Ucsr.Uepc;

         // ------------------------------ User Exception Cause
         // 12'h042 = 12'b0000_0100_0010  Ucause                              (read-write)
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Ucause = 0;                                           // Ucause is currently 4 Flops wide
            else if (exception.flag & (nxt_mode == U_MODE))                   // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_Ucsr.Ucause = exception.cause;                             // save code for exception cause
            else if (csr_wr && (csr_wr_addr[7:0] == 8'h42))                   // writable in all modes
               nxt_Ucsr.Ucause = csr_wr_data[3:0];                            // Sotware settable
            else
               nxt_Ucsr.Ucause   = Ucsr.Ucause;
         end
         always_ff @(posedge clk_in)
            Ucsr.Ucause <= nxt_Ucsr.Ucause;

         // ------------------------------ User Exception Trap Value    see p. 8,115 riscv-privileged.pdf 1.12-draft
         // 12'h043 = 12'b0000_0100_0011  Utval                               (read-write)
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Utval = 0;
            else if (exception.flag & (nxt_mode == U_MODE))                   // An exception in MEM stage has priority over a csr_wr (in EXE stage)
               nxt_Ucsr.Utval = exception.tval;                               // save code for exception cause
            else if (csr_wr && (csr_wr_addr[7:0] == 8'h43))                   // writable in all modes
               nxt_Ucsr.Utval = csr_wr_data;                                  // Sotware settable
            else
               nxt_Ucsr.Utval= Ucsr.Utval;
         end
         always_ff @(posedge clk_in)
            Ucsr.Utval <= nxt_Ucsr.Utval;

         // ------------------------------ User Interrupt Pending bits
         // 12'h044 = 12'b0000_0100_0100  Uip                                 (read-write)
         //  31:12  11    10    9     8     7     6     5     4     3     2     1     0
         // { 0,    0,    0,    0,   ueip,  0,    0,    0,   utip,  0,    0,    0,   usip}; riscv-privileged draft 1.12  p. 114
         always_comb
         begin
            if (reset_in)
               nxt_Ucsr.Uip   = 0;
            else
            begin
               nxt_Ucsr.Uip   = Ucsr.Uip;                                     // default unless overridden by logic below

               // All bits besides USIP in the Uip register are read-only. riscv-privileged draft 1.12  p 114
               if (csr_wr & (csr_wr_addr[7:0] == 8'h44))                      // writable in any mode
                  nxt_Ucsr.Uip.usip = csr_wr_data[0];
               else if (sw_irq)
                  nxt_Ucsr.Uip.usip = TRUE;                                   // software interrupt = msip_reg[] see irq.sv

               if (mode == U_MODE)
                  nxt_Ucsr.Uip.utip = timer_irq;                              // timer interrupt

               if (mode == U_MODE)
                  nxt_Ucsr.Uip.ueip = ext_irq;                                // external interrupt
            end
         end
         always_ff @(posedge clk_in)
            Ucsr.Uip <= nxt_Ucsr.Uip;
      `endif // ext_N
   `endif // ext_U

endmodule