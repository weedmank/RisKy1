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

   `ifdef ext_N
   input    logic             ext_irq,
   input    logic             timer_irq,
   `endif

   // signals shared between CSR and EXE stage
   CSR_EXE_intf.master        csr_exe_bus,

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

   logic       [1:0] mode, nxt_mode;               // from mode_irq(). This is the next mode (what mode will be on the next clock cycle)

   logic             hpm_events [0:23];            // 23 ---> create a parameter in cpu_params for this!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   EXCEPTION         exception;
   EVENTS            current_events;
   logic             tot_retired;      // In this design, at most, 1 instruction can retire per clock cycle

   assign exception        = EV_EXC_bus.exception;
   assign current_events   = EV_EXC_bus.current_events;
   assign sw_irq           = EV_EXC_bus.sw_irq;

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
   logic                   [PC_SZ-1:2] trap_pc;             // Output:  trap vector handler address.
   `ifdef ext_N
   logic                               interrupt_flag;      // 1 = take an interrupt trap
   logic                         [3:0] interrupt_cause;     // value specifying what type of interrupt
   `endif
   assign csr_exe_bus.mode             = mode;

   assign csr_exe_bus.mepc             = mcsr.mepc;
   `ifdef ext_S
   assign csr_exe_bus.sepc             = scsr.sepc;
   `endif
   `ifdef ext_U
   assign csr_exe_bus.uepc             = ucsr.uepc;
   `endif
   assign csr_exe_bus.trap_pc          = trap_pc;
   `ifdef ext_N
   assign csr_exe_bus.interrupt_flag   = interrupt_flag;
   assign csr_exe_bus.interrupt_cause  = interrupt_cause;
   `endif

   logic    mret;
   assign mret = csr_exe_bus.mret;
   `ifdef ext_S
   logic    sret;
   assign sret = csr_exe_bus.sret;
   `endif
   `ifdef ext_U
   logic    uret;
   assign uret = csr_exe_bus.uret;
   `endif

   // ================================================================== Next CSR Register Contents logic ======================================================
   // The state of all Control & Status egisters is determined and output as nxt_mcsr,nxt_scsr,nxt_ucsr (depending on type of CSR). These values are then
   // latched into the actual CSR FF's on the next rising clock edge as seen in csr_std_wr() registers used further below
   // Used by WB stage to write data to a specific CSR
   csr_nxt_reg cnr (
      .reset_in(reset_in),

      `ifdef ext_N
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      .sw_irq(sw_irq),
      `endif

      .csr_addr(csr_wr_addr),                               // Input:   CSR write address
      .csr_wr(csr_wr),                                      // Input:   CSR write control
      .csr_wr_data(csr_wr_data),                            // Input:   CSR write data

      .tot_retired(tot_retired),                            // Input:
      .exception(exception),                                // Input:
      `ifdef use_MHPM
      .hpm_events(hpm_events),                              // Input:   24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
      `endif

      .mode(mode),                                          // Input:
      .nxt_mode(nxt_mode),                                  // Input:

      `ifdef ext_U
      .uret(uret),                                          // Input:
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_ucsr),                                  // Output:  next register state of all the User Mode Control & Status Registers
      `endif

      `ifdef ext_S
      .sret(sret),                                          // Input:
      .scsr(scsr),                                          // Input:   current register sstate of all the Supervisor Mode Control & Status Registers
      .nxt_scsr(nxt_scsr),                                  // Output:  next register state of all the Supervisor Mode Control & Status Registers
      `endif

      .mret(mret),                                          // Input:
      .mcsr(mcsr),                                          // Input:   current register state of all the Machine Mode Control & Status Registers
      .nxt_mcsr(nxt_mcsr)                                   // Output:  next register state of all the Machine Mode Control & Status Registers
   );

   // ================================================================== csr_rd_data logic ============================================================
   // produces current values of csr_rd_data and csr_rd_avail based in input csr_rd_addr. Needed by CSR Functional Unit inside EXE stage to read
   // a specific CSR register - i.e. csr[csr_addr]
   csr_av_rdata car
   (
      .csr_rd_addr(csr_rd_addr),                            // Input:
      .csr_rd_data(csr_rd_data),                            // Output:
      .csr_rd_avail(csr_rd_avail),                          // Output:  1 = register exists (available) in design

      .mtime(mtime),                                        // Input:
      .mode(mode),                                          // Input:

      `ifdef ext_U
      .ucsr(ucsr),                                          // Input:   all of the User Mode Control & Status Registers
      `endif
      `ifdef ext_S
      .scsr(scsr),                                          // Input:   all of the Supervisor Mode Control & Status Registers
      `endif
      .mcsr(mcsr)                                           // Input:   all of the Machine Mode Control & Status Registers
   );

   // ************************************************************************************************************************************
   // Used by CSR Functional Unit to determine what csr_rd_data for a specific CSR will be on the NEXT clock cycle.
   // ************************************************************************************************************************************
   // Althouhg the logic uses signals csr_wr, csr_wr_addr and csr_wr_data, NO physical write occurs to any CSR register. This just calculates
   // what the next data would be in the specific CSR[].  This is needed by the EXE stage for forwarding information because writing to
   // a CSR does NOT mean that it will contain all the write data or even the same data that is written!
   //
   // Note: Forwarding of Architectural Registers is easy because what you write to them will be the same as what you later read from them. Not so
   //       with some CSRs
   // Read the contents of a specific CSR and know if it's available (exists for reading)

   MCSR             nxt_FWD_mcsr;
   `ifdef ext_S
   SCSR             nxt_FWD_scsr;
   `endif
   `ifdef ext_U
   UCSR             nxt_FWD_ucsr;
   `endif

   csr_nxt_reg cnr_2 (
      .reset_in(reset_in),

      `ifdef ext_N
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      .sw_irq(sw_irq),                                      // captured value of sw_irq in EXE stage (i.e. csr_fu.sv)
      `endif

      .csr_addr(nxt_csr_wr_addr),                           // Input:   CSR write address
      .csr_wr(nxt_csr_wr),                                  // Input:   CSR write control
      .csr_wr_data(nxt_csr_wr_data),                        // Input:   CSR write data

      .tot_retired(tot_retired),                            // Input:
      .exception(exception),                                // Input:
      `ifdef use_MHPM
      .hpm_events(hpm_events),                              // Input:   24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
      `endif

      .mode(mode),
      .nxt_mode(nxt_mode),

      `ifdef ext_U
      .uret(uret),                                          // Input:
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_FWD_ucsr),                              // Output:  next register state of all the User Mode Control & Status Registers
      `endif

      `ifdef ext_S
      .sret(sret),                                          // Input:
      .scsr(scsr),                                          // Input:   current register state of all the Supervisor Mode Control & Status Registers
      .nxt_scsr(nxt_FWD_scsr),                              // Output:  next register state of all the Supervisor Mode Control & Status Registers
      `endif

      .mret(mret),                                          // Input:
      .mcsr(mcsr),                                          // Input:   current register state of all the Machine Mode Control & Status Registers
      .nxt_mcsr(nxt_FWD_mcsr)                               // Output:  next register state of all the Machine Mode Control & Status Registers
   );

   csr_av_rdata car_2
   (
      .csr_rd_addr(nxt_csr_wr_addr),                        // Input:
      .csr_rd_data(nxt_csr_rd_data),                        // Output:
      .csr_rd_avail(),                                      // Output:  1 = register exists (available) in design NOTE: not needed by CSR Functional Unit we only need the read result for NEXT clock cycle

      .mtime(mtime),                                        // Input:
      .mode(mode),                                          // Input:

      `ifdef ext_U
      .ucsr(nxt_FWD_ucsr),                                  // Input:   all of the User Mode Control & Status Registers
      `endif
      `ifdef ext_S
      .scsr(nxt_FWD_scsr),                                  // Input:   all of the Supervisor Mode Control & Status Registers
      `endif
      .mcsr(nxt_FWD_mcsr)                                   // Input:   all of the Machine Mode Control & Status Registers
   );

   // ================================================================== Mode & Interrupt Control logic ======================================================
   mode_irq mi (
      .reset_in(reset_in),
      .clk_in(clk_in),

      .exception_flag(exception.flag),                      // Input:

      .mode(mode),                                          // Output:  current mode
      .nxt_mode(nxt_mode),                                  // output:  next mode - needed by csr_nxt_reg

      `ifdef ext_U
      .uret(uret),
      `endif
      `ifdef ext_S
      .sret(sret),
      `endif
      .mret(mret),

      .trap_pc(trap_pc),                                    // Output:  needed in WB logic
      `ifdef ext_N
      .ext_irq(ext_irq),
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
   `ifdef ext_N
   // ------------------------------ User Status Register
   // 12'h000 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
   //  31          22    21    20   19    18   17   16:15 14:13 12:11 10:9   8     7     6     5     4     3     2     1     0
   // {sd, 8'b0, 1'b0, 1'b0, 1'b0, mxr,  sum, 1'b0,   xs,   fs, 2'b0, 2'b0, 1'b0, 1'b0, 1'b0, 1'b0, upie, 1'b0, 1'b0, 1'b0, uie};
   csr_std_wr #(0,12'h000,5,32'hFFFF_FFEE) Ustatus                (clk_in,reset_in, mode, TRUE, nxt_ucsr.ustatus, ucsr.ustatus); // only lower 5 bits implemented so far 12/21/2020
   `endif

   `ifdef ext_F
   // ------------------------------ User Floating-Point CSRs
   // 12'h001 - 12'h003
   `endif   // ext_F

   `ifdef ext_N
   // ------------------------------ User Interrupt-Enable Register
   // 12'h004 = 12'b0000_0000_0100  uie                           (read-write)  user mode
   csr_std_wr #(0,12'h004,9,32'hFFFF_FEEE) Uie                    (clk_in,reset_in, mode, TRUE, nxt_ucsr.uie, ucsr.uie);

   // User Trap Handler Base address.
   // 12'h005 = 12'b0000_0000_0101  utvec                         (read-write)  user mode
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   csr_std_wr #(UTVEC_INIT,12'h005,RSZ,32'h0000_0002) Utvec       (clk_in,reset_in, mode, TRUE, nxt_ucsr.utvec, ucsr.utvec);

   // ------------------------------ User Trap Handling
   // Scratch register for user trap handlers.
   // 12'h040 = 12'b0000_0100_0000  uscratch                      (read-write)
   csr_std_wr #(0,12'h040,RSZ) Uscratch                           (clk_in,reset_in, mode, TRUE, nxt_ucsr.uscratch, ucsr.uscratch);

   // ------------------------------ User Exception Program Counter
   // 12'h041 = 12'b0000_0100_0001  uepc                          (read-write)
   csr_std_wr #(0,12'h041,RSZ,32'h1) Uepc                         (clk_in,reset_in, mode, TRUE, nxt_ucsr.uepc, ucsr.uepc); // ls-bit is RO so it remains at 0 after reset

   // ------------------------------ User Exception Cause
   // 12'h042 = 12'b0000_0100_0010  ucause                        (read-write)
   csr_std_wr #(0,12'h042,4) Ucause                               (clk_in,reset_in, mode, TRUE, nxt_ucsr.ucause, ucsr.ucause); // ucause is currently 4 Flops wide

   // ------------------------------ User Exception Trap Value    see riscv-privileged p. 38-39
   // 12'h043 = 12'b0000_0100_0011  utval                         (read-write)
   csr_std_wr #(0,12'h043,RSZ) Utval                              (clk_in,reset_in, mode, TRUE, nxt_ucsr.utval, ucsr.utval);

   // ------------------------------ User Interrupt Pending bits
   // 12'h044 = 12'b0000_0100_0100  uip                           (read-write)
   //        31:10   9     8         7:6   5     4         3:2   1     0
   // uip = {22'b0, 1'b0, nxt_ueip, 2'b0, 1'b0, nxt_utip, 2'b0, 1'b0, nxt_usip};
   csr_std_wr #(0,12'h044,9,32'hFFFF_FEEE) Uip                    (clk_in,reset_in, mode, TRUE, nxt_ucsr.uip, ucsr.uip);
   `endif

   `endif // ext_U



   `ifdef ext_S
   // ================================================================== Supervisor Mode CSRs ===============================================================
   // ------------------------------ Supervisor Status Register
   // The sstatus register is a subset of the mstatus register. In a straightforward implementation,
   // reading or writing any field in sstatus is equivalent to reading or writing the homonymous field
   // in mstatus
   // 12'h100 = 12'b0001_0000_0000  sstatus                       (read-write)
   // 31 30:20 19    18  17   16:15   14:13   12:9 8   7    6   5    4    3:2  1   0
   // SD WPRI  MXR   SUM WPRI XS[1:0] FS[1:0] WPRI SPP WPRI UBE SPIE UPIE WPRI SIE UIE
   // 1  11    1     1   1    2       2       4    1   1    1   1    1    2    1   1
   csr_std_wr #(0,12'h100,9,32'hFFFF_FECC) Sstatus                (clk_in,reset_in, mode, TRUE, nxt_scsr.sstatus, scsr.sstatus); // only lower 9 implemented so far 12/21/2020

   // In systems with S-mode, the  medeleg and mideleg registers must exist, whereas the sedeleg and sideleg registers should only
   // exist if the N extension for user-mode interrupts is also implemented. p 28 riscv-privileged
   `ifdef ext_N
   // ------------------------------ Supervisor Exception Delegation Register.
   // 12'h102 = 12'b0001_0000_0010  sedeleg                       (read-write)
   csr_std_wr #(SEDLG_INIT,12'h102,RSZ,SEDLG_MASK) Sedeleg        (clk_in,reset_in, mode, TRUE, nxt_scsr.sedeleg, scsr.sedeleg);

   // ------------------------------ Supervisor Interrupt Delegation Register.
   // 12'h103 = 12'b0001_0000_0011  sideleg                       (read-write)
   csr_std_wr #(SIDLG_INIT,12'h103,RSZ,SIDLG_MASK) Sideleg        (clk_in,reset_in, mode, TRUE, nxt_scsr.sideleg, scsr.sideleg);

   // ------------------------------ Supervisor Interrupt Enable Register.
   // 12'h104 = 12'b0001_0000_0100  sie                           (read-write)
   // Read Only bits of 32'hFFFF_FCCC;  // Note: bits 31:10, 7:6, 3:2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   csr_std_wr #(0,12'h104,RSZ,32'hFFFF_FCCC) Sie                  (clk_in,reset_in, mode, TRUE, nxt_scsr.sie, scsr.sie);
   `endif // ext_N

   // ------------------------------ Supervisor Trap handler base address.
   // 12'h105 = 12'b0001_0000_0101  stvec                         (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   csr_std_wr #(STVEC_INIT & ~32'd2,12'h105,RSZ,32'h0000_0002) Stvec (clk_in,reset_in, mode, TRUE, nxt_scsr.stvec, scsr.stvec);

   // ------------------------------ Supervisor Counter Enable.
   // 12'h106 = 12'b0001_0000_0110  scounteren                    (read-write)
   csr_std_wr #(SCNTEN_INIT,12'h106,RSZ,SCNTEN_MASK) Scounteren   (clk_in,reset_in, mode, TRUE, nxt_scsr.scounteren, scsr.scounteren);

   // ------------------------------ Supervisor Scratch Register
   // Scratch register for supervisor trap handlers.
   // 12'h140 = 12'b0001_0100_0000  sscratch                      (read-write)
   csr_std_wr #(0,12'h140,RSZ) Sscratch                           (clk_in,reset_in, mode, TRUE, nxt_scsr.sscratch, scsr.sscratch);

   // ------------------------------ Supervisor Exception Program Counter
   // 12'h141 = 12'b0001_0100_0001  sepc                          (read-write)
   csr_std_wr #(0,12'h141,RSZ,32'h1) Sepc                         (clk_in,reset_in, mode, TRUE, nxt_scsr.sepc, scsr.sepc); // ls-bit is RO so it remains at 0 after reset

   // ------------------------------ Supervisor Exception Cause
   // 12'h142 = 12'b0001_0100_0010  scause                        (read-write)
   csr_std_wr #(0,12'h142,4) Scause                               (clk_in,reset_in, mode, TRUE, nxt_scsr.scause, scsr.scause);   // scause is currently 4 Flops wide

   // ------------------------------ Supervisor Exception Trap Value                             see riscv-privileged p. 38-39
   // 12'h143 = 12'b0001_0100_0011  stval                         (read-write)
   csr_std_wr #(0,12'h142,RSZ) Stval                              (clk_in,reset_in, mode, TRUE, nxt_scsr.stval, scsr.stval);

   // ------------------------------ Supervisor Interrupt Pending bits
   // 12'h144 = 12'b0001_0100_0100  sip                           (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, 1'b0, 1'b0, seip, ueip, 1'b0, 1'b0, stip, utip, 1'b0, 1'b0, ssip, usip}; // All bits besides SSIP, USIP, and UEIP in the sip register are read-only. p 59 riscv-privileged.pdf
   csr_std_wr #(0,12'h344,RSZ,32'hFFFF_FCCC) Sip                  (clk_in,reset_in, mode, TRUE, nxt_scsr.sip, scsr.sip);

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
   //  31        22   21  20   19   18   17   16:15 14:13 12:11 10:9  8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs fs,   mpp,  2'b0, spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};

   // register currently creates flops for bits 12:11,8,7,5,4,3,1,0
   csr_std_wr #(0,12'h300,13,32'hFFFF_E644) Mstatus               (clk_in,reset_in, mode, TRUE, nxt_mcsr.mstatus, mcsr.mstatus); // only lower 13 bits implemented 12/21/2020

   // ------------------------------ Machine ISA Register

   // currently this is just a constant (all bits R0)
   csr_std_wr #(MISA,12'h301,RSZ,MISA_MASK) Misa                  (clk_in,reset_in, mode, TRUE, nxt_mcsr.misa, mcsr.misa);

   // In systems with only M-mode and U-mode, the medeleg and mideleg registers should only be implemented if the N extension for user-mode interrupts is implemented.
   // In systems with only M-mode, or with both M-mode and U-mode but without U-mode trap support, the medeleg and mideleg registers should not exist. seee riscv-privileged.pdf p 28
   `ifdef MDLG // "In systems with S-mode, the medeleg and mideleg registers must exist,..." p. 28 riscv-privileged.pdf
      // ------------------------------ Machine Exception Delegation Register
      // 12'h302 = 12'b0011_0000_0010  medeleg                    (read-write)
      csr_std_wr #(MEDLG_INIT,12'h302,RSZ,MEDLG_MASK) Medeleg     (clk_in,reset_in, mode, TRUE, nxt_mcsr.medeleg, mcsr.medeleg);

      // ------------------------------ Machine Interrupt Delegation Register
      // 12'h303 = 12'b0011_0000_0011  mideleg                    (read-write)
      csr_std_wr #(MIDLG_INIT,12'h303,RSZ,MIDLG_MASK) Mideleg     (clk_in,reset_in, mode, TRUE, nxt_mcsr.mideleg, mcsr.mideleg);
  `endif

   `ifdef ext_N
   // ------------------------------ Machine Interrupt Enable Register
   // 12'h304 = 12'b0011_0000_0100  mie                           (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meie, WPRI, seie, ueie, mtie, WPRI, stie, utie, msie, WPRI, ssie, usie};
   // Read Only bits of 32'hFFFF_F444;  // Note: bits 31:12, 10, 6, 2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   csr_std_wr #(0,12'h304,RSZ,32'hFFFF_F444)  Mie                 (clk_in,reset_in, mode, TRUE, nxt_mcsr.mie, mcsr.mie);
   `endif

   // ------------------------------ Machine Trap Handler Base Address
   // 12'h305 = 12'b0011_0000_0101  mtvec                         (read-write)
   // Current design only allows MODE of 0 or 1 - thus bit 1 forced to retain it's reset value which is 0.
   csr_std_wr #(MTVEC_INIT & ~32'd2,12'h305,RSZ,32'h2) Mtvec      (clk_in,reset_in, mode, TRUE, nxt_mcsr.mtvec, mcsr.mtvec);

   // ------------------------------ Machine Counter Enable
   // 12'h306 = 12'b0011_0000_0110  mcounteren                    (read-write)
   csr_std_wr #(MCNTEN_INIT,12'h306,RSZ,MCNTEN_MASK) Mcounteren   (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcounteren, mcsr.mcounteren);

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

   // ------------------------------ Machine Scratch Register
   // 12'h340 = 12'b0011_0100_0000  mscratch                      (read-write)
   csr_std_wr #(0,12'h340,RSZ) Mscratch                           (clk_in,reset_in, mode, TRUE, nxt_mcsr.mscratch, mcsr.mscratch);

   // ------------------------------ Machine Exception Program Counter
   // Used by MRET instruction at end of Machine mode trap handler
   // 12'h341 = 12'b0011_0100_0001  mepc                          (read-write)   see riscv-privileged p 36
   csr_std_wr #(0,12'h341,RSZ,32'h1) Mepc                         (clk_in,reset_in, mode, TRUE, nxt_mcsr.mepc, mcsr.mepc);    // LSbit always remains at 0 (reset init value)

   // ------------------------------ Machine Exception Cause
   // 12'h342 = 12'b0011_0100_0010  mcause                        (read-write)
   csr_std_wr #(0,12'h342,4) Mcause                               (clk_in,reset_in, mode, TRUE, nxt_mcsr.mcause, mcsr.mcause);   // mcause is currently 4 Flops wide

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


   // Machine instructions-retired counter.
   // The size of thefollowig counters must be large enough to hold the maximum number that can retire in a given clock cycle
    // At most, for this pipelined design, only 1 instruction can retire per clock so just OR the retire bits (instead of adding)
   assign tot_retired      = current_events.ret_cnt[LD_RET]  | current_events.ret_cnt[ST_RET]   | current_events.ret_cnt[CSR_RET]  | current_events.ret_cnt[SYS_RET]  |
                             current_events.ret_cnt[ALU_RET] | current_events.ret_cnt[BXX_RET]  | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET] |
                             current_events.ret_cnt[IM_RET]  | current_events.ret_cnt[ID_RET]   | current_events.ret_cnt[IR_RET]   | current_events.ret_cnt[HINT_RET] |
               `ifdef ext_F  current_events.ret_cnt[FLD_RET] | current_events.ret_cnt[FST_RET]  | current_events.ret_cnt[FP_RET]   | `endif
                             current_events.ret_cnt[UNK_RET];

   // Just assign the hpm_events that will be used and comment those that are not used. Also adjust the number (i.e. 24 right now)
   `ifdef use_MHPM
   logic             br_cnt;
   logic             misaligned_cnt;

   assign br_cnt           = current_events.ret_cnt[BXX_RET] | current_events.ret_cnt[JAL_RET]  | current_events.ret_cnt[JALR_RET];
   assign misaligned_cnt   = (current_events.e_flag & (current_events.e_cause == 0)) |  /* 0 = Instruction Address Misaligned */
                             (current_events.e_flag & (current_events.e_cause == 4)) |  /* 4 = Load Address Misaligned        */
                             (current_events.e_flag & (current_events.e_cause == 6));   /* 6 = Store Address Misaligned       */

   assign hpm_events[0 ]   = 0;                                      // no change to mhpm counter when this even selected
   // The following hpm_events return a count value which is used by a mhpmcounter[]. mhpmcounter[n] can use whichever event[x] it wants by setting mphmevent[n]
   // The count sources (i.e. current_events.ret_cnt[LD_RET]) may be changed by the user to reflect what information they want to use for a given counter.
   // Any of the logic on the RH side of the assignment can changed or used for any hpm_events[x] - even new logic can be created for a new event source.
   assign hpm_events[1 ]   = current_events.ret_cnt[LD_RET];         // Load Instruction retirement count. See ret_cnt[] in cpu_structs_pkg.sv. One ret_cnt for each instruction type.
   assign hpm_events[2 ]   = current_events.ret_cnt[ST_RET];         // Store Instruction retirement count.
   assign hpm_events[3 ]   = current_events.ret_cnt[CSR_RET];        // CSR
   assign hpm_events[4 ]   = current_events.ret_cnt[SYS_RET];        // System
   assign hpm_events[5 ]   = current_events.ret_cnt[ALU_RET];        // ALU
   assign hpm_events[6 ]   = current_events.ret_cnt[BXX_RET];        // BXX
   assign hpm_events[7 ]   = current_events.ret_cnt[JAL_RET];        // JAL
   assign hpm_events[8 ]   = current_events.ret_cnt[JALR_RET];       // JALR
   assign hpm_events[9 ]   = current_events.ret_cnt[IM_RET];         // Integer Multiply
   assign hpm_events[10]   = current_events.ret_cnt[ID_RET];         // Integer Divide
   assign hpm_events[11]   = current_events.ret_cnt[IR_RET];         // Integer Remainder
   assign hpm_events[12]   = current_events.ret_cnt[HINT_RET];       // Hint Instructions
   assign hpm_events[13]   = current_events.ret_cnt[UNK_RET];        // Unknown Instructions
   assign hpm_events[14]   = current_events.e_flag ? (current_events.e_cause == 0) : 0; // e_cause = 0 = Instruction Address Misaligned
   assign hpm_events[15]   = current_events.e_flag ? (current_events.e_cause == 1) : 0; // e_cause = 1 = Instruction Access Fault
   assign hpm_events[16]   = current_events.e_flag ? (current_events.e_cause == 2) : 0; // e_cause = 2 = Illegal Instruction
   assign hpm_events[17]   = br_cnt;                                 // all bxx, jal, jalr instructions
   assign hpm_events[18]   = misaligned_cnt;                         // all misaligned instructions
   assign hpm_events[19]   = tot_retired;                            // total of all instructions retired this clock cycle
   `ifdef ext_F
   assign hpm_events[20]   = current_events.ret_cnt[FLD_RET];        // single precision Floating Point Load retired
   assign hpm_events[21]   = current_events.ret_cnt[FST_RET];        // single precision Floating Point Store retired
   assign hpm_events[22]   = current_events.ret_cnt[FP_RET];         // single precision Floating Point operation retired
   assign hpm_events[23]   = current_events.ext_irq;                 // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
   `else
   assign hpm_events[20]   = current_events.e_flag ? (current_events.e_cause == 3) : 0; // e_cause = 3 = Environment Break
   assign hpm_events[21]   = current_events.e_flag ? (current_events.e_cause == 6) : 0; // e_cause = 6 = Store Address Misaligned
   assign hpm_events[22]   = current_events.e_flag ? (current_events.e_cause == 8) : 0; // e_cause = 8 = User ECALL
   assign hpm_events[23]   = current_events.ext_irq;                 // this will always be a 0 or 1 count as only 1 per clock cycle can ever occur
   `endif // uxt_F
   `endif

   // Note: currently there are NUM_EVENTS hpm_events as specified at the beginning of this generate block. The number can be changed if more or less event types are needed


endmodule