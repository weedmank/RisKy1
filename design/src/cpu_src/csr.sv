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
// File          :  csr.sv
// Description   :  Contains CSR Write logic for Machine mode.
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module csr
(
   input    logic             clk_in,
   input    logic             reset_in,

   output   logic       [1:0] mode,

   `ifdef ext_N
   input    logic             ext_irq,
   input    logic             timer_irq,
   `endif

   // signals shared between CSR and EXE stage
   CSR_EXE_intf.master        csr_exe_bus,

   // signals shared between CSR and WB stage
   CSR_WB_intf.master         csr_wb_bus,

   // signals from WB stage
   EV_EXC_intf.slave          EV_EXC_bus,                   // Events and Exception information (see wb.sv)

   input    logic [RSZ*2-1:0] mtime,

   // Channel used by WB stage to write data to a CSR
   WB_2_CSR_wr_intf.slave     csr_wr_bus,

   // Channel used by CSR Functional Unit to read the current contents a CSR
   RCSR_intf.slave            csr_rd_bus,

   // channel used by CSR Functional Unit to determine what csr_rd_data would be on the next clock cycle...
   CSR_NXT_intf.slave         csr_nxt_bus
);

//   `ifdef ext_U
//   UCSR_REG_intf              nxt_ucsr();
//   UCSR_REG_intf              ucsr();                       // all of the User mode Control & Status Registers
//   `endif
//   `ifdef ext_S
//   SCSR_REG_intf              nxt_scsr();
//   SCSR_REG_intf              scsr();                       // all of the Supervisor mode Control & Status Registers
//   `endif
//   MCSR_REG_intf              nxt_mcsr();
//   MCSR_REG_intf              mcsr();                       // all of the Machine mode Control & Status Registers
   `ifdef ext_U
   UCSR              nxt_ucsr;
   UCSR              ucsr;                         // all of the User mode Control & Status Registers
   `endif
   `ifdef ext_S
   SCSR              nxt_scsr;
   SCSR              scsr;                         // all of the Supervisor mode Control & Status Registers
   `endif
   MCSR              nxt_mcsr;
   MCSR              mcsr;                         // all of the Machine mode Control & Status Registers

   logic       [1:0] nxt_mode;                     // from mode_irq(). This is the next mode (what mode will be on the next clock cycle)

   // ----------------------------------- csr_nxt_bus interface
   logic             nxt_csr_wr;
   logic      [11:0] nxt_csr_wr_addr;
   logic   [RSZ-1:0] nxt_csr_wr_data;
   logic   [RSZ-1:0] nxt_csr_rd_data;

   assign nxt_csr_wr       = csr_nxt_bus.nxt_csr_wr;
   assign nxt_csr_wr_addr  = csr_nxt_bus.nxt_csr_wr_addr;
   assign nxt_csr_wr_data  = csr_nxt_bus.nxt_csr_wr_data;

   assign csr_nxt_bus.nxt_csr_rd_data = nxt_csr_rd_data;

   // ----------------------------------- csr_wr_bus interface
   logic             csr_wr;
   logic      [11:0] csr_wr_addr;
   logic   [RSZ-1:0] csr_wr_data;

   assign csr_wr           = csr_wr_bus.csr_wr;
   assign csr_wr_addr      = csr_wr_bus.csr_wr_addr;
   assign csr_wr_data      = csr_wr_bus.csr_wr_data;

   // ----------------------------------- csr_rd_bus interface
   logic      [11:0] csr_rd_addr;
   logic   [RSZ-1:0] csr_rd_data;
   logic             csr_rd_avail;

   assign csr_rd_addr               = csr_rd_bus.csr_rd_addr;
   assign csr_rd_bus.csr_rd_data    = csr_rd_data;
   assign csr_rd_bus.csr_rd_avail   = csr_rd_avail;

   // ----------------------------------- signals shared between csr.sv and EXE stage
   assign csr_exe_bus.mode = mode;
   assign csr_exe_bus.mepc = mcsr.mepc;
   `ifdef ext_S
   assign csr_exe_bus.sepc = scsr.sepc;
   `endif
   `ifdef ext_U
   assign csr_exe_bus.uepc = ucsr.uepc;
   `endif

   assign mret = csr_exe_bus.mret;
   `ifdef ext_S
   assign sret = csr_exe_bus.sret;
   `endif
   `ifdef ext_U
   assign uret = csr_exe_bus.uret;
   `endif

   // --------------------------------- csr_wb_bus signal assignments
   // signals to csr.sv
   logic                   [PC_SZ-1:0] trap_pc;             // Output:  trap vector handler address.
   `ifdef ext_N
   logic                               interrupt_flag;      // 1 = take an interrupt trap
   logic                     [RSZ-1:0] interrupt_cause;     // value specifying what type of interrupt
   `endif

   // signals from csr.sv
   assign csr_wb_bus.trap_pc           = trap_pc;
   `ifdef ext_N
   assign csr_wb_bus.interrupt_flag    = interrupt_flag;
   assign csr_wb_bus.interrupt_cause   = interrupt_cause;
   `endif
   assign csr_wb_bus.mode              = mode;

   // ================================================================== csr_rd_data logic ============================================================
   // produces current values of csr_rd_data and csr_rd_avail based in input csr_rd_addr. Needed by CSR Functional Unit inside EXE stage to read
   // a specific CSR register - i.e. csr[csr_addr]
   csr_av_rdata car
   (
      .csr_rd_addr(csr_rd_addr),
      .csr_rd_data(csr_rd_data),
      .csr_rd_avail(csr_rd_avail),                          // 1 = register exists (available) in design

      .mtime(mtime),
      .mode(mode),

      `ifdef ext_U
      .ucsr(ucsr),                                          // all of the User Mode Control & Status Registers
      `endif
      `ifdef ext_S
      .scsr(scsr),                                          // all of the Supervisor Mode Control & Status Registers
      `endif
      .mcsr(mcsr)                                           // all of the Machine Mode Control & Status Registers
   );

   // ================================================================== Next csr_rd_data logic ======================================================
   // Used by CSR Functional Unit to determine what csr_rd_data for a specific CSR will be on the next clock cycle.
   // Althouhg the logic is passed signals csr_wr, csr_wr_addr and csr_wr_data, NO physical write occurs to any CSR register. It just calculates what
   // would be the next data woould get saved in the specific CSR[].  This is needed by the EXE stage for forwarding information because writing to
   // a CSR does NOT mean that it will contain all the write data or even the same data that is written!
   //
   // Note: Forwarding of Architectural Registers is easy because what you write to them will be the same as what you later read from them. Not so
   //       with some CSRs

//   MCSR_REG_intf              nxt_CSRFU_mcsr();
//   `ifdef ext_S
//   SCSR_REG_intf              nxt_CSRFU_scsr();
//   `endif
//   `ifdef ext_U
//   UCSR_REG_intf              nxt_CSRFU_ucsr();
//   `endif
   MCSR             nxt_CSRFU_mcsr;
   `ifdef ext_S
   SCSR             nxt_CSRFU_scsr;
   `endif
   `ifdef ext_U
   UCSR             nxt_CSRFU_ucsr;
   `endif
   csr_nxt_reg cnr_fu (
      .reset_in(reset_in),

      `ifdef ext_N
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      `endif

      .csr_addr(nxt_csr_wr_addr),
      .csr_wr(nxt_csr_wr),
      .csr_wr_data(nxt_csr_wr_data),

      .EV_EXC_bus(EV_EXC_bus),
      .mode(mode),
      .nxt_mode(nxt_mode),

      `ifdef ext_U
      .uret(uret),
      .ucsr(ucsr),                                          // Input: current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_CSRFU_ucsr),                            // Output: next register state of all the User Mode Control & Status Registers
      `endif

      `ifdef ext_S
      .sret(sret),
      .scsr(scsr),                                          // Input: current register state of all the Supervisor Mode Control & Status Registers
      .nxt_scsr(nxt_CSRFU_scsr),                            // Output: next register state of all the Supervisor Mode Control & Status Registers
      `endif

      .mret(mret),
      .mcsr(mcsr),                                          // Input:  current register state of all the Machine Mode Control & Status Registers
      .nxt_mcsr(nxt_CSRFU_mcsr)                             // Output: next register state of all the Machine Mode Control & Status Registers
   );
   csr_av_rdata car_fu
   (
      .csr_rd_addr(nxt_csr_wr_addr),
      .csr_rd_data(nxt_csr_rd_data),
      .csr_rd_avail(),                                      // 1 = register exists (available) in design NOTE: not needed by CSR Functional Unit

      .mtime(mtime),
      .mode(mode),

      `ifdef ext_U
      .ucsr(nxt_CSRFU_ucsr),                                // all of the User Mode Control & Status Registers
      `endif
      `ifdef ext_S
      .scsr(nxt_CSRFU_scsr),                                // all of the Supervisor Mode Control & Status Registers
      `endif
      .mcsr(nxt_CSRFU_mcsr)                                 // all of the Machine Mode Control & Status Registers
   );

   // ================================================================== Next CSR Register Contents logic ======================================================
   // The state of all Control & Status egisters is determined and output as nxt_mcsr,nxt_scsr,nxt_ucsr (depending on type of CSR). These values are then
   // latched into the actual CSR FF's on the next rising clock edge as seen in csr_std_wr() registers used further below
   // Used by WB stage to write data to a specific CSR
   csr_nxt_reg cnr (
      .reset_in(reset_in),

      `ifdef ext_N
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      `endif

      .csr_addr(csr_wr_addr),
      .csr_wr(csr_wr),
      .csr_wr_data(csr_wr_data),

      .EV_EXC_bus(EV_EXC_bus),
      .mode(mode),
      .nxt_mode(nxt_mode),

      `ifdef ext_U
      .uret(uret),
      .ucsr(ucsr),                                          // Input: current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_ucsr),                                  // Output: next register state of all the User Mode Control & Status Registers
      `endif

      `ifdef ext_S
      .sret(sret),
      .scsr(scsr),                                          // Input: current register sstate of all the Supervisor Mode Control & Status Registers
      .nxt_scsr(nxt_scsr),                                  // Output: next register state of all the Supervisor Mode Control & Status Registers
      `endif

      .mret(mret),
      .mcsr(mcsr),                                          // Input:  current register state of all the Machine Mode Control & Status Registers
      .nxt_mcsr(nxt_mcsr)                                   // Output: next register state of all the Machine Mode Control & Status Registers
   );

   // ================================================================== Mode & Interrupt Control logic ======================================================
   EXCEPTION   exception;
   assign exception = EV_EXC_bus.exception;
   mode_irq mi (
      .reset_in(reset_in),
      .clk_in(clk_in),

      .mode(mode),                                          // Output:  current mode
      .nxt_mode(nxt_mode),                                  // output:  next mode - needed by csr_nxt_reg

      .exception(exception),                                // Input:

      `ifdef ext_U
      .uret(uret),
      `endif
      `ifdef ext_S
      .sret(sret),
      `endif
      .mret(mret),

      .trap_pc(trap_pc),                                    // Output:  needed in WB logic
      `ifdef ext_N
      .interrupt_flag(interrupt_flag),                      // Output:  needed in WB logic
      .interrupt_cause(interrupt_cause),                    // Output:  needed in WB logic
      `endif

      `ifdef ext_U
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      `endif
      `ifdef ext_S
      .scsr(scsr),                                          // Input:   current register state of all the Supervisor Mode Control & Status Registers
      `endif
      .mcsr(mcsr)                                           // Input:   current register state of all the Machine Mode Control & Status Registers
   );


   // ================================================================== User Mode CSRs =====================================================================
   `ifdef ext_U
   // ------------------------------ User Status Register
   // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
   //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
   // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};

   assign ucsr.ustatus = mcsr.mstatus & ~32'h7FF2_7FF2_1FFE; // just a mask of the mstatus register

   `ifdef ext_N
   // ------------------------------ User Interrupt-Enable Register
   // 12'h004 = 12'b0000_0000_0100  uie                           (read-write)  user mode
   csr_std_wr #(0,12'h004,RSZ) Uie                                (clk_in,reset_in, mode, TRUE, nxt_ucsr.uie, ucsr.uie);
   `endif // ext_N

   // User Trap Handler Base address.
   // 12'h005 = 12'b0000_0000_0101  utvec                         (read-write)  user mode
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
   csr_std_wr #(0,12'h005,RSZ,32'h0E) Utvec                       (clk_in,reset_in, mode, TRUE, nxt_ucsr.utvec, ucsr.utvec);

   // ------------------------------ User Trap Handling
   // Scratch register for user trap handlers.
   // 12'h040 = 12'b0000_0100_0000  uscratch                      (read-write)
   csr_std_wr #(0,12'h040,RSZ) Uscratch                           (clk_in,reset_in, mode, TRUE, nxt_ucsr.uscratch, ucsr.uscratch);

   // ------------------------------ User Exception Program Counter
   // 12'h041 = 12'b0000_0100_0001  uepc                          (read-write)
   csr_std_wr #(0,12'h041,RSZ) Uepc                               (clk_in,reset_in, mode, TRUE, nxt_ucsr.uepc, ucsr.uepc);

   // ------------------------------ User Exception Cause
   // 12'h042 = 12'b0000_0100_0010  ucause                        (read-write)
   csr_std_wr #(0,12'h042,RSZ) Ucause                             (clk_in,reset_in, mode, TRUE, nxt_ucsr.ucause, ucsr.ucause);

   // ------------------------------ User Exception Trap Value    see riscv-privileged p. 38-39
   // 12'h043 = 12'b0000_0100_0011  utval                         (read-write)
   csr_std_wr #(0,12'h043,RSZ) Utval                              (clk_in,reset_in, mode, TRUE, nxt_ucsr.utval, ucsr.utval);

   `ifdef ext_N
   // ------------------------------ User Interrupt Pending bits
   // 12'h044 = 12'b0000_0100_0100  uip                           (read-write)
   //        31:10   9     8         7:6   5     4         3:2   1     0
   // uip = {22'b0, 1'b0, nxt_ueip, 2'b0, 1'b0, nxt_utip, 2'b0, 1'b0, nxt_usip};
   assign ucsr.uip = mcsr.mip & 32'h0000_0111;
   `endif

   `endif // ext_U



   `ifdef ext_S
   // ================================================================== Supervisor Mode CSRs ===============================================================
   // ------------------------------ Supervisor Status Register
   // The sstatus register is a subset of the mstatus register. In a straightforward implementation,
   // reading or writing any field in sstatus is equivalent to reading or writing the homonymous field
   // in mstatus
   // 12'h100 = 12'b0001_0000_0000  sstatus        (read-write)

   assign scsr.sstatus = mcsr.mstatus & 32'h7FF2_1ECC; // just a mask of the mstatus register

   // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
   // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged

   //!!! NOTE: DOn't yet know how to implement all the logic for medeleg and mideleg!!!

   // ------------------------------ Supervisor exception delegation register.
   // 12'h102 = 12'b0001_0000_0010  sedeleg                       (read-write)
   csr_std_wr #(0,12'h102,RSZ) Sedeleg                            (clk_in,reset_in, mode, TRUE, nxt_scsr.sedeleg, scsr.sedeleg);

   `ifdef ext_N
   // ------------------------------ Supervisor interrupt delegation register.
   // 12'h103 = 12'b0001_0000_0011  sideleg                       (read-write)
   csr_std_wr #(0,12'h103,RSZ) Sideleg                            (clk_in,reset_in, mode, TRUE, nxt_scsr.sideleg, scsr.sideleg);

   // ------------------------------ Supervisor interrupt-enable register.
   // 12'h104 = 12'b0001_0000_0100  sie                           (read-write)
   // Read Only bits of 32'hFFFF_FCCC;  // Note: bits 31:10, 7:6, 3:2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   csr_std_wr #(0,12'h104,RSZ,32'hFFFF_FCCC) Sie                  (clk_in,reset_in, mode, TRUE, nxt_scsr.sie, scsr.sie);
   `endif // ext_N

   // ------------------------------ Supervisor trap handler base address.
   // 12'h105 = 12'b0001_0000_0101  stvec                         (read-write)
   // Read Only bits of 32'h0000_000E;  // Note: bits 3:2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   // Current design only allows MODE of 0 or 1 - thus bit 1 will be 0. Also lower 2 bit's of BASE (bits 3,2) will be 0
   csr_std_wr #(0,12'h105,RSZ,32'h0000_000E) Stvec                (clk_in,reset_in, mode, TRUE, nxt_scsr.stvec, scsr.stvec);

   // ------------------------------ Supervisor counter enable.
   // 12'h106 = 12'b0001_0000_0110  scounteren                    (read-write)
   csr_std_wr #(0,12'h106,RSZ) Scounteren                         (clk_in,reset_in, mode, TRUE, nxt_scsr.scounteren, scsr.scounteren);

   // ------------------------------ Supervisor Trap Handling
   // Scratch register for supervisor trap handlers.
   // 12'h140 = 12'b0001_0100_0000  sscratch                      (read-write)
   csr_std_wr #(0,12'h140,RSZ) Sscratch                           (clk_in,reset_in, mode, TRUE, nxt_scsr.sscratch, scsr.sscratch);

   // ------------------------------ Supervisor Exception Program Counter.
   // 12'h141 = 12'b0001_0100_0001  sepc                          (read-write)
   csr_std_wr #(0,12'h141,RSZ) Sepc                               (clk_in,reset_in, mode, TRUE, nxt_scsr.sepc, scsr.sepc);

   // ------------------------------ Supervisor Exception Cause.
   // 12'h142 = 12'b0001_0100_0010  scause                        (read-write)
   csr_std_wr #(0,12'h142,RSZ) Scause                             (clk_in,reset_in, mode, TRUE, nxt_scsr.scause, scsr.scause);

   // ------------------------------ Supervisor Exception Trap Value                             see riscv-privileged p. 38-39
   // 12'h143 = 12'b0001_0100_0011  stval                         (read-write)
   csr_std_wr #(0,12'h142,RSZ) Stval                              (clk_in,reset_in, mode, TRUE, nxt_scsr.stval, scsr.stval);

   `ifdef ext_N
   // ------------------------------ Supervisor Interrupt Pending bits
   // 12'h144 = 12'b0001_0100_0100  sip                           (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, 1'b0, 1'b0, seip, ueip, 1'b0, 1'b0, stip, utip, 1'b0, 1'b0, ssip, usip};
   assign scsr.sip = mcsr.mip & 32'hFFFF_FCCC; // just a mask of the mip register
   `endif   // ext_N

   // ------------------------------ Supervisor Protection and Translation
   // 12'h180 = 12'b0001_1000_0000  satp                          (read-write)
   // Supervisor address translation and protection.
   csr_std_wr #(0,12'h180) Satp                                   (clk_in,reset_in, mode, TRUE, nxt_scsr.satp, scsr.satp);
   `endif // ext_S

   // ================================================================== Machine Mode CSRs ==================================================================
   // ------------------------------ Machine Status Register
   // 12'h300 = 12'b0011_0000_0000  mstatus     (read-write)   p. 56 riscv-privileged
   // mie,sie,uie    - global interrupt enables
   // mpie,spie,upie - pending interrupt enables
   // mpp, spp       - previous privileged mode stacks
   //  31        22   21  20   19   18   17   16:15 14:13 12:11  10:9    8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs,  mpp, 2'b0,  spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};

   csr_std_wr #(0,12'h300,RSZ,32'h7FC0_0644) Mstatus              (clk_in,reset_in, mode, TRUE, nxt_mcsr.mstatus, mcsr.mstatus);

   // ------------------------------ Machine ISA Register

   assign mcsr.misa     = nxt_mcsr.misa; // currently this is just a constant

   // ------------------------------ Machine Delegation Registers - under construction...
   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28

   //!!! NOTE: Don't yet know how to implement all the logic for medeleg and mideleg!!!

   `ifdef ext_S // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // Machine exception delegation register.
      // 12'h302 = 12'b0011_0000_0010  medeleg                    (read-write)
      csr_std_wr #(0,12'h302,RSZ) Medeleg                         (clk_in,reset_in, mode, TRUE, nxt_mcsr.medeleg, mcsr.medeleg);

      // Machine interrupt delegation register.
      // 12'h303 = 12'b0011_0000_0011  mideleg                    (read-write)
      csr_std_wr #(0,12'h303,RSZ) Mideleg                         (clk_in,reset_in, mode, TRUE, nxt_mcsr.mideleg, mcsr.mideleg);
   `else // !ext_S
      `ifdef ext_U
         `ifdef ext_N
         // Machine exception delegation register.
         // 12'h302 = 12'b0011_0000_0010  medeleg                 (read-write)
         csr_std_wr #(0,12'h302,RSZ) Medeleg                      (clk_in,reset_in, mode, TRUE, nxt_mcsr.medeleg, mcsr.medeleg);

         // Machine interrupt delegation register.
         // 12'h303 = 12'b0011_0000_0011  mideleg                 (read-write)
         csr_std_wr #(0,12'h303,RSZ) Mideleg                      (clk_in,reset_in, mode, TRUE, nxt_mcsr.mideleg, mcsr.mideleg);
         `endif
      `endif
   `endif

   `ifdef ext_N
   // ------------------------------ Machine Interrupt Enable Register
   // 12'h304 = 12'b0011_0000_0100  mie                           (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meie, WPRI, seie, ueie, mtie, WPRI, stie, utie, msie, WPRI, ssie, usie};
   // Read Only bits of 32'hFFFF_F444;  // Note: bits 31:12, 10, 6, 2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   csr_std_wr #(0,12'h304,RSZ,32'hFFFF_F444) Mie                  (clk_in,reset_in, mode, TRUE, nxt_mcsr.mie, mcsr.mie);
   `endif

   // ------------------------------ Machine Trap Handler Base Address
   // 12'h305 = 12'b0011_0000_0101  mtvec                         (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to 0 below. Also lower 2 bit's of BASE (bits 3,2) must be 0
   // Read Only bits of 32'h0000_000E;  // Note: bits 3:1 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   // Current design only allows MODE of 0 or 1 - thus bit 1 will be 0. Also lower 2 bit's of BASE (bits 3,2) will be 0
   csr_std_wr #(0,12'h305,RSZ,32'h0000_000E) Mtvec                (clk_in,reset_in, mode, TRUE, nxt_mcsr.mtvec, mcsr.mtvec);

   // ------------------------------ Machine Counter Enable
   // 12'h306 = 12'b0011_0000_0110  mcounteren                    (read-write)
   csr_std_wr #(0,12'h306,RSZ) Mcounteren                         (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcounteren, mcsr.mcounteren);

   // ------------------------------ Machine Counter Inhibit
   // If not implemented, set all bits to 0 => no inhibits will ocur
   // 12'h320 = 12'b0011_0010_00000  mcountinhibit                (read-write)
   // NOTE: bit 1 always "hardwired" to 0
   csr_std_wr #(0,12'h320,RSZ,32'h0000_0002) Mcountinhibit        (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcountinhibit, mcsr.mcountinhibit);

   // ------------------------------ Machine Hardware Performance-Monitoring Event selectors
   // 12'h323 - 12'h33F  mhpmevent3 - mhpmevent31                 (read-write)
   `ifdef use_MHPM
   genvar m;
   generate
      for (m = 0; m < NUM_MHPM; m++)
      begin
         // Note: width of mhpmevent[] is define as 5 bits - up to 32 different event selections
         csr_std_wr #(0,12'h323+m,EV_SEL_SZ) Mhpmevent            (clk_in,reset_in, mode, TRUE, nxt_mcsr.mhpmevent[m], mcsr.mhpmevent[m]);
      end
   endgenerate
   `endif

   // ------------------------------ Machine Scratch Register for machine trap handlers.
   // 12'h340 = 12'b0011_0100_0000  mscratch                      (read-write)
   csr_std_wr #(0,12'h340,RSZ) Mscratch                           (clk_in,reset_in, mode, TRUE, nxt_mcsr.mscratch, mcsr.mscratch);

   // ------------------------------ Machine Exception Program Counter
   // Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  mepc                          (read-write)   see riscv-privileged p 36
   csr_std_wr #(0,12'h341,RSZ) Mepc                               (clk_in,reset_in, mode, TRUE, nxt_mcsr.mepc, mcsr.mepc);

   // ------------------------------ Machine Exception Cause
   // 12'h342 = 12'b0011_0100_0010  mcause                        (read-write)
   csr_std_wr #(0,12'h342,RSZ) Mcause                             (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcause, mcsr.mcause);

   // ------------------------------ Machine Exception Trap Value
   // 12'h343 = 12'b0011_0100_0011  mtval                         (read-write)
   csr_std_wr #(0,12'h343,RSZ) Mtval                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.mtval, mcsr.mtval);

   `ifdef ext_N
   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  mip                           (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meip, 1'b0, seip, ueip, mtip, 1'b0, stip, utip, msip, 1'b0, ssip, usip};
   csr_std_wr #(0,12'h344,RSZ,32'hFFFF_F444) Mip                  (clk_in,reset_in, mode, TRUE, nxt_mcsr.mip, mcsr.mip);
   `endif   // ext_N


   // ------------------------------ Machine Protection and Translation
   // 12'h3A0 - 12'h3A3
   `ifdef USE_PMPCFG
      // 12'h3A0 = 12'b0011_1010_0000  pmpcfg0                    (read-write)
      csr_std_wr #(0,12'h3A0,RSZ) Mpmpcfg0                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpcfg0, mcsr.pmpcfg0);
      // 12'h3A1 = 12'b0011_1010_0001  pmpcfg1                    (read-write)
      csr_std_wr #(0,12'h3A1,RSZ) Mpmpcfg1                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpcfg1, mcsr.pmpcfg1);
      // 12'h3A2 = 12'b0011_1010_0010  pmpcfg2                    (read-write)
      csr_std_wr #(0,12'h3A2,RSZ) Mpmpcfg2                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpcfg2, mcsr.pmpcfg2);
      // 12'h3A3 = 12'b0011_1010_0011  pmpcfg3                    (read-write)
      csr_std_wr #(0,12'h3A3,RSZ) Mpmpcfg3                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpcfg3, mcsr.pmpcfg3);
   `endif

   // 12'h3B0 - 12'h3BF
   // 12'h3B0 = 12'b0011_1010_0000  pmpaddr0 (read-write)
   `ifdef PMP_ADDR0  csr_std_wr #(0,12'h3B0,RSZ) Mpmpaddr0        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr0,  mcsr.pmpaddr0);    `endif
   `ifdef PMP_ADDR1  csr_std_wr #(0,12'h3B1,RSZ) Mpmpaddr1        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr1,  mcsr.pmpaddr1);    `endif
   `ifdef PMP_ADDR2  csr_std_wr #(0,12'h3B2,RSZ) Mpmpaddr2        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr2,  mcsr.pmpaddr2);    `endif
   `ifdef PMP_ADDR3  csr_std_wr #(0,12'h3B3,RSZ) Mpmpaddr3        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr3,  mcsr.pmpaddr3);    `endif
   `ifdef PMP_ADDR4  csr_std_wr #(0,12'h3B4,RSZ) Mpmpaddr4        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr4,  mcsr.pmpaddr4);    `endif
   `ifdef PMP_ADDR5  csr_std_wr #(0,12'h3B5,RSZ) Mpmpaddr5        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr5,  mcsr.pmpaddr5);    `endif
   `ifdef PMP_ADDR6  csr_std_wr #(0,12'h3B6,RSZ) Mpmpaddr6        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr6,  mcsr.pmpaddr6);    `endif
   `ifdef PMP_ADDR7  csr_std_wr #(0,12'h3B7,RSZ) Mpmpaddr7        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr7,  mcsr.pmpaddr7);    `endif
   `ifdef PMP_ADDR8  csr_std_wr #(0,12'h3B8,RSZ) Mpmpaddr8        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr8,  mcsr.pmpaddr8);    `endif
   `ifdef PMP_ADDR9  csr_std_wr #(0,12'h3B9,RSZ) Mpmpaddr9        (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr9,  mcsr.pmpaddr9);    `endif
   `ifdef PMP_ADDR10 csr_std_wr #(0,12'h3BA,RSZ) Mpmpaddr10       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr10, mcsr.pmpaddr10);   `endif
   `ifdef PMP_ADDR11 csr_std_wr #(0,12'h3BB,RSZ) Mpmpaddr11       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr11, mcsr.pmpaddr11);   `endif
   `ifdef PMP_ADDR12 csr_std_wr #(0,12'h3BC,RSZ) Mpmpaddr12       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr12, mcsr.pmpaddr12);   `endif
   `ifdef PMP_ADDR13 csr_std_wr #(0,12'h3BD,RSZ) Mpmpaddr13       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr13, mcsr.pmpaddr13);   `endif
   `ifdef PMP_ADDR14 csr_std_wr #(0,12'h3BE,RSZ) Mpmpaddr14       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr14, mcsr.pmpaddr14);   `endif
   `ifdef PMP_ADDR15 csr_std_wr #(0,12'h3BF,RSZ) Mpmpaddr15       (clk_in,reset_in, mode, TRUE, nxt_mcsr.pmpaddr15, mcsr.pmpaddr15);   `endif

   `ifdef add_DM
   // ------------------------------  Debug/Trace Registers - shared with Debug Mode (tselect,tdata1,tdata2,tdata3)
   csr_std_wr #(0,12'h7A0,RSZ) Mtsel                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.tselect, mcsr.tselect);          // Trigger Select Register
   csr_std_wr #(0,12'h7A1,RSZ) Mtdr1                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.tdata1,  mcsr.tdata1);           // Trigger Data Register 1
   csr_std_wr #(0,12'h7A2,RSZ) Mtdr2                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.tdata2,  mcsr.tdata2);           // Trigger Data Register 2
   csr_std_wr #(0,12'h7A3,RSZ) Mtdr3                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.tdata3,  mcsr.tdata3);           // Trigger Data Register 3

   // ------------------------------ Debug Mode Registers (dcsr,dpc,dscratch0,dscatch1)
   // "0x7B0–0x7BF are only visible to debug mode" p. 6 riscv-privileged.pdf
   csr_std_wr #(0,12'h7B0,RSZ) Mdcsr                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.dcsr,      mcsr.dcsr);           // Debug Control and Status Register
   csr_std_wr #(0,12'h7B1,RSZ) Mdpc                               (clk_in,reset_in, mode, TRUE, nxt_mcsr.dpc,       mcsr.dpc);            // Debug PC Register
   csr_std_wr #(0,12'h7B2,RSZ) Mdsr0                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.dscratch0, mcsr.dscratch0);      // Debug Scratch Register 0
   csr_std_wr #(0,12'h7B3,RSZ) Mdsr1                              (clk_in,reset_in, mode, TRUE, nxt_mcsr.dscratch1, mcsr.dscratch1);      // Debug Scratch Register 1
   `endif // add_DM

   // ------------------------------ Machine Cycle Counter
   // The cycle, instret, and hpmcountern CSRs are read-only shadows of mcycle, minstret, and
   // mhpmcountern, respectively. p 34 risvcv-privileged.pdf
   csr_std_wr #(0,12'hB00,RSZ) Mcycle_lo                          (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcycle_lo, mcsr.mcycle_lo);      // Timer Lower 32 bits
   csr_std_wr #(0,12'hB80,RSZ) Mcycle_hi                          (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcycle_hi, mcsr.mcycle_hi);      // Timer Higher 32 bits


   // ------------------------------ Machine Instructions-Retired Counter
   // The time CSR is a read-only shadow of the memory-mapped mtime register.                                                                               p 34 riscv-priviliged.pdf
   // Implementations can convert reads of the time CSR into loads to the memory-mapped mtime register, or emulate this functionality in M-mode software.   p 35 riscv-priviliged.pdf

   csr_std_wr #(0,12'hB02,RSZ) Minstret_lo                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.minstret_lo, mcsr.minstret_lo);  // Timer Lower 32 bits
   csr_std_wr #(0,12'hB82,RSZ) Minstret_hi                        (clk_in,reset_in, mode, TRUE, nxt_mcsr.minstret_hi, mcsr.minstret_hi);  // Timer Higher 32 bits

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
         csr_std_wr #(0,12'hB03+n,RSZ) Mmhpmcounter_lo            (clk_in,reset_in, mode, TRUE, nxt_mcsr.mhpmcounter_lo[n], mcsr.mhpmcounter_lo[n]);  // Lower 32 bits
         csr_std_wr #(0,12'hB83+n,RSZ) Mmhpmcounter_hi            (clk_in,reset_in, mode, TRUE, nxt_mcsr.mhpmcounter_hi[n], mcsr.mhpmcounter_hi[n]);  // Higher 32 bits
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

endmodule