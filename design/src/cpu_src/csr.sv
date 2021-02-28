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

   input    logic             ext_irq,
   input    logic             timer_irq,

   // signals shared between CSR and EXE stage
   CSR_EXE_intf.master        csr_exe_bus,

   // signals from WB stage
   WB_CSR_intf.slave          WB_CSR_bus,                   // Events and Exception information (see wb.sv)

   input    logic [RSZ*2-1:0] mtime,

   // Channel used by WB stage to write data to a CSR
   WB_2_CSR_wr_intf.slave     csr_wr_bus,

   // Channel used by CSR Functional Unit to read the current contents a CSR
   RCSR_intf.slave            csr_rd_bus,

   // channel used by CSR Functional Unit to determine what csr_rd_data would be on the next clock cycle...
   CSR_NXT_intf.slave         csr_nxt_bus
);

   `ifdef ext_U
   `ifdef ext_N
   UCSR              nxt_ucsr;
   UCSR              ucsr;                         // all of the User mode Control & Status Registers
   `endif
   `endif

   `ifdef ext_S
   SCSR              nxt_scsr;                     // scounteren MUST be implemented even if no ext_S. see p 60 riscv-privileged.pdf
   SCSR              scsr;                         // all of the Supervisor mode Control & Status Registers
   `endif

   MCSR              nxt_mcsr;
   MCSR              mcsr;                         // all of the Machine mode Control & Status Registers

   logic       [1:0] mode, nxt_mode;               // from mode_irq(). This is the next mode (what mode will be on the next clock cycle)

   `ifdef use_MHPM
   logic             hpm_events [0:23];            // 23 ---> create a parameter in cpu_params for this!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   `endif
   EXCEPTION         exception;
   EVENTS            current_events;
   logic             total_retired;                // In this design, at most, 1 instruction can retire per clock cycle

   assign exception        = WB_CSR_bus.exception;
   assign current_events   = WB_CSR_bus.current_events;
   assign sw_irq           = WB_CSR_bus.sw_irq;

   logic    mret;
   assign   mret = WB_CSR_bus.mret;
   `ifdef ext_S
   logic    sret;
   assign   sret = WB_CSR_bus.sret;
   `endif
   `ifdef ext_U
   `ifdef ext_N
   logic    uret;
   assign   uret = WB_CSR_bus.uret;
   `endif
   `endif
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
   logic                   [PC_SZ-1:2] trap_pc;       // Output:  trap vector handler address.
   logic                               irq_flag;      // 1 = take an interrupt trap
   logic                     [RSZ-1:0] irq_cause;     // value specifying what type of interrupt
   assign csr_exe_bus.mode             = mode;

   assign csr_exe_bus.mepc             = mcsr.mepc;

   `ifdef ext_S
   assign csr_exe_bus.sepc             = scsr.sepc;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   assign csr_exe_bus.uepc             = ucsr.uepc;
   `endif
   `endif

   assign csr_exe_bus.trap_pc          = trap_pc;
   assign csr_exe_bus.irq_flag         = irq_flag;
   assign csr_exe_bus.irq_cause        = irq_cause;

   // ================================================================== Next CSR Register Contents ======================================================
   // Combo logic: The next state of all Control & Status Registers is determined and output as nxt_mcsr,nxt_scsr,nxt_ucsr (depending on type of CSR).
   // These values are then latched into the actual CSR FF's on the next rising clock edge as seen in csr_std_wr() registers used module csr_regs.sv
   csr_nxt_reg cnr (
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      .sw_irq(sw_irq),

      .csr_addr(csr_wr_addr),                               // Input:   CSR write address
      .csr_wr(csr_wr),                                      // Input:   CSR write control
      .csr_wr_data(csr_wr_data),                            // Input:   CSR write data

      .total_retired(total_retired),                        // Input:
      .exception(exception),                                // Input:
      `ifdef use_MHPM
      .hpm_events(hpm_events),                              // Input:   24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
      `endif

      .mode(mode),                                          // Input:
      .nxt_mode(nxt_mode),                                  // Input:

      `ifdef ext_U
      `ifdef ext_N
      .uret(uret),                                          // Input:
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_ucsr),                                  // Output:  next register state of all the User Mode Control & Status Registers
      `endif
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

   // ================================================================== CSR Register Contents ======================================================
   // Sequential logic: All Control & Status Registers needed for a given design option(s)
   csr_regs cur_CSR (
      .clk_in(clk_in),                                      // Input:
      .reset_in(reset_in),                                  // Input:

      .ext_irq(ext_irq),                                    // Input:
      .current_events(current_events),                      // Input:

      .total_retired(total_retired),                        // Output:  needed by csr_nxt_reg.sv
      `ifdef use_MHPM
      .hpm_events(hpm_events),                              // Output:  needed by csr_nxt_reg.sv
      `endif

      `ifdef ext_U
      `ifdef ext_N
      .ucsr(ucsr),                                          // Output:  all of the User mode Control & Status Registers
      .nxt_ucsr(nxt_ucsr),                                  // Input:   all of the next User mode Control & Status Registers
      `endif
      `endif

      `ifdef ext_S
      .scsr(scsr),                                          // Output:  all of the Supervisor mode Control & Status Registers
      .nxt_scsr(nxt_scsr),                                  // Input:   all of the next Supervisor mode Control & Status Registers
      `endif

      .mcsr(mcsr),                                          // Output:  all of the Machine mode Control & Status Registers
      .nxt_mcsr(nxt_mcsr)                                   // Input:   all of the next Machine mode Control & Status Registers
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
      `ifdef ext_N
      .ucsr(ucsr),                                          // Input:   all of the User Mode Control & Status Registers
      `endif
      `endif

      `ifdef ext_S
      .scsr(scsr),                                          // Input:   all of the Supervisor Mode Control & Status Registers
      `endif

      .mcsr(mcsr)                                           // Input:   all of the Machine Mode Control & Status Registers
   );

   // ================================================================== Mode & Interrupt Control logic ======================================================
   mode_irq mi (
      .reset_in(reset_in),
      .clk_in(clk_in),

      .retire_exception_flag(exception.flag),               // Input:   An exception occured for the retiring instruction
      .retire_interrupt_flag(exception.cause[RSZ-1]),       // Input:   cause bit set if exception is due to an interrupt

      .mode(mode),                                          // Output:  current mode
      .nxt_mode(nxt_mode),                                  // output:  next mode - needed by csr_nxt_reg

      `ifdef ext_U
      `ifdef ext_N
      .uret(uret),
      `endif
      `endif

      `ifdef ext_S
      .sret(sret),
      `endif

      .mret(mret),

      .trap_pc(trap_pc),                                    // Output:  needed in WB logic
      .ext_irq(ext_irq),                                    // Input:

      .irq_flag(irq_flag),                                  // Output:  needed in EXE logic
      .irq_cause(irq_cause),                                // Output:  needed in EXE logic

      `ifdef ext_U
      `ifdef ext_N
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      `endif
      `endif

      `ifdef ext_S
      .scsr(scsr),                                          // Input:   current register state of all the Supervisor Mode Control & Status Registers
      `endif

      .mcsr(mcsr)                                           // Input:   current register state of all the Machine Mode Control & Status Registers
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

   MCSR             nxt_FWD_mcsr;

   `ifdef ext_S
   SCSR             nxt_FWD_scsr;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   UCSR             nxt_FWD_ucsr;
   `endif
   `endif

   csr_nxt_reg cnr_2 (
      .ext_irq(ext_irq),
      .timer_irq(timer_irq),
      .sw_irq(sw_irq),                                      // captured value of sw_irq in EXE stage (i.e. csr_fu.sv)

      .csr_addr(nxt_csr_wr_addr),                           // Input:   CSR write address
      .csr_wr(nxt_csr_wr),                                  // Input:   CSR write control
      .csr_wr_data(nxt_csr_wr_data),                        // Input:   CSR write data

      .total_retired(total_retired),                        // Input:
      .exception(exception),                                // Input:
      `ifdef use_MHPM
      .hpm_events(hpm_events),                              // Input:   24 different event counts (counts for this clock cycle) that can be used. 1 bit needed per event for this design (1 instruction max per clock cycle)
      `endif

      .mode(mode),
      .nxt_mode(nxt_mode),

      `ifdef ext_U
      `ifdef ext_N
      .uret(uret),                                          // Input:
      .ucsr(ucsr),                                          // Input:   current register state of all the User Mode Control & Status Registers
      .nxt_ucsr(nxt_FWD_ucsr),                              // Output:  next register state of all the User Mode Control & Status Registers
      `endif
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
      `ifdef ext_N
      .ucsr(nxt_FWD_ucsr),                                  // Input:   all of the User Mode Control & Status Registers
      `endif
      `endif

      `ifdef ext_S
      .scsr(nxt_FWD_scsr),                                  // Input:   all of the Supervisor Mode Control & Status Registers
      `endif

      .mcsr(nxt_FWD_mcsr)                                   // Input:   all of the Machine Mode Control & Status Registers
   );


endmodule