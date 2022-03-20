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
// File          :  RisKy1_core.sv
// Description   :  Top level - connects all necessary modules for the CPU core
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;
import csr_params_pkg::*;
//
//                                          ............................................................................
//                                          :  RisKy1_core                                                             :
//                                          :                                                                          :
//                                          :           +--------------+                                               :
//                                          :           |    FETCH     |                                               :
//                                          :           |              |                                               :
//    L1 Instruction Cache Interface -------:---------->|              |                                               :
//                                          :           +------+-------+                  +-----------+                :
//                                          :                  |               +--------->|           |<---------------:<----- External Interrupts (optional)
//                                          :                  v               |          |           |                :
//                                          :           +------+-------+       |  +------>|    CSR    |                :
//                                          :           |              |       |  |       |           |<--------+      :
//                                          :           |    DECODE    |       |  |   +-->|           |         |      :
//                                          :           |              |       |  |   |   +-----------+         |      :
//                                          :           +------+-------+       |  |   |                         |      :
//                                          :                  |               |  |   | timer_irq               |      :
//                                          :                  v               |  |   |   +-----------+         |      :
//                                          :           +------+-------+       |  |   |   |    MMR    |         |      : (MMR = Memory Managed Registers)
//                                          :    +----->|              |<------+  |   +---|     &     |         |      :
//                                          :    |      |    EXECUTE   |          |       |  SW IRQ   |         |      :
//                                          :    |  +-->|              |<---------|-------|           |         |      :
//                                          :    |  |   +------+-------+ sw_irq   |       +-----------+         |      :
//                                          :    |  |          |                  |                             |      :
//                                          :    |  |          v                  |                             |      :
//                                          :    |  |   +------+-------+          |                             |      :
//                                          :    |  |   |              |----------|-----------------------------|----->:-----> External I/O interface
//                                          :    |  |   |     MEM      |          |                             |      :
//                                          :    |  |   |              |<---------|-----------------------------|----->:<----> L1 Data Cache interface
//                                          :    |  |   +------+-------+          |                             |      :
//                                          :    |  |          |                  |                             |      :
//                                          :    |  |          v                  |                             |      :
//                                          :    |  |   +------+-------+          |       +------------------+  |      :
//                                          :    |  |   |              |----------+       |   Architectural  |  |      :
//                                          :    |  |   |      WB      |                  |   Registers      |  |      :
//                                          :    |  |   |              |----------------->|   (gpr, fpr)     |  |      :
//                                          :    |  |   +--------------+                  +---------+--------+  |      :
//                                          :    |  |                                               |           |      :
//                                          :    |  +-----------------------------------------------+           |      :
//                                          :    |                                                              |      :
//                                          :    |                                        +----------------+    |      :
//                                          :    |                                        |   mode_irq     |    |      :
//                                          :    |                                        |                |    |      :
//                                          :    +----------------------------------------| mode  nxt_mode |----+      :
//                                          :                                             |                |           :
//                                          :                                             |                |<----------:<----- External IRQ
//                                          :                                             +----------------+           :
//                                          :                                                                          :
//                                          :..........................................................................:
//
//
//
//
//
//
//
`ifdef VIVADO
// Verilog style - for use in Vivado when instantiating in a Block Design.
// Vivado CANNOT handle SystemVerilog syntax for top level Block Design instantiations (at least up through ver. 2019.2)
// Thus a "wrapper" is created that will instantiate this RisK1_core module which has ONLY Verilog syntax in the module port
module RisKy1_core
(
   // This `ifdef VIVADO monkey business is all due to Vivado having a limited System Verilog understanding when instantiating a top level module in Block Design!!!
   // All the interfaces need to be in Verilog style as Vivado can't handle any SystemVerilog in the top level module when placing it in a Block Design. Therefore this
   // module, RisKy1_core.sv, CANNOT be a top level module. This means we need a wrapper module (See RisKy1_RV32i.v).
   input    wire                       clk_in,
   input    wire                       reset_in,

   input    wire                       ext_irq,                               // Input:  Machine mode External Interrupt

   // L1 Instruction cache interface signals
   output   wire                       ic_req,                                // Output: Request            - Fetch unit is requesting a cache line of data from the I $
   output   wire           [PC_SZ-1:0] ic_addr,                               // Output: Request address    - Memory address that Fetch unit wants to get a cache line of data from
   input    wire                       ic_ack,                                // Input:  Ackknowledge       - I$ is ackknowledging it has data (ic_rd_data_in) for the Fetch unit
   input    wire        [CL_LEN*8-1:0] ic_ack_data,                           // Input:  Acknowledge data   - this contains CL_LEN bytes of data => CL_LEN/4 instructions

   output   wire                       ic_flush,                              // Output: signal requesting to flush the Instruction Cache

   // L1 Data cache interface signals
   output   wire                       dc_req,                                // Output: Request - must remain high until ack
   output   wire           [PC_SZ-1:0] dc_rw_addr,                            // Output: Request - ls_addr - Load/Store Address
   output   wire                       dc_rd,                                 // Output: Request - is_ld
   output   wire                       dc_wr,                                 // Output: Request - is_st
   output   wire             [RSZ-1:0] dc_wr_data,                            // Output: Request - st_data - Store data
   output   wire                 [2:0] dc_size,                               // Output: Request - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   output   wire                       dc_zero_ext,                           // Output: Request - 1 = Zero Extend
   output   wire                       dc_inv_flag,                           // Output: Request - invalidate flag
   input    wire                       dc_ack,
   input    wire             [RSZ-1:0] dc_ack_data,

   output   wire                       dc_flush,                              // Output: Request - Output: signal requesting to flush the Data Cache

   `ifdef SIM_DEBUG
   output   wire                       sim_stop,
   `endif

   // External I/O accesses
   output   wire                       io_req,                                // Output:  I/O Request
   output   wire           [PC_SZ-1:0] io_addr,                               // Output:  I/O Address
   output   wire                       io_rd,                                 // Output:  I/O Read signal. 1 = read
   output   wire                       io_wr,                                 // Output:  I/O Write signal. 1 = write
   output   wire             [RSZ-1:0] io_wr_data,                            // Output:  I/O Write data that is written when io_wr == 1

   input    wire                       io_ack,                                // Input:   I/O Acknowledge
   input    wire                       io_ack_fault,                          // Input:   I/O Acknowledge
   input    wire             [RSZ-1:0] io_ack_data                            // Input:   I/O Read data
);
   // Vivado 2019.2 cannot yet handle System Verilog, thus a wrapper has to be created (i.e. RisKy1_RV32i.v) and individual module port signals created/assigned in Verilog style
   L1IC_intf                  L1IC_bus();                                     // OK to use this in RisKy1_core outside of module ports for Vivado
   L1DC_intf                  L1DC_bus();
   EIO_intf                   EIO_bus();

   // ports are/need to be Verilog type for Vivado
   assign ic_req                 = L1IC_bus.req;
   assign ic_addr                = L1IC_bus.addr;
   assign L1IC_bus.ack           = ic_ack;
   assign L1IC_bus.ack_data      = ic_ack_data;

   assign dc_req                 = L1DC_bus.req;                              // Request           - must remain high until ack
   assign dc_rw_addr             = L1DC_bus.req_data.rw_addr;                 // Request data      - ls_addr - Load/Store Address
   assign dc_rd                  = L1DC_bus.req_data.rd;                      // Request data      - is_ld
   assign dc_wr                  = L1DC_bus.req_data.wr;                      // Request data      - is_ld
   assign dc_wr_data             = L1DC_bus.req_data.wr_data;                 // Request data      - st_data - Store data
   assign dc_size                = L1DC_bus.req_data.size;                    // Request data      - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   assign dc_zero_ext            = L1DC_bus.req_data.zero_ext;                // Request data      - 1 = Zero Extend
   assign dc_inv_flag            = L1DC_bus.req_data.inv_flag;                // Request data      - invalidate flag
   assign L1DC_bus.ack           = dc_ack;                                    // Acknowledge       - D$ is ackknowledging it has data (dc_ack_data) for the MEM unit
   assign L1DC_bus.ack_data      = dc_ack_data;                               // Acknowledge data

   assign io_req                 = EIO_bus.req;                               // Output:  I/O Request
   assign io_addr                = EIO_bus.addr;                              // Output:  I/O Address
   assign io_rd                  = EIO_bus.rd;                                // Output:  I/O Read signal. 1 = read
   assign io_wr                  = EIO_bus.wr;                                // Output:  I/O Write signal. 1 = write
   assign io_wr_data             = EIO_bus.wr_data;                           // Output:  I/O Write data that is written when io_wr == 1

   assign EIO_bus.ack            = io_ack;                                    // Input:   I/O Acknowledge
   assign EIO_bus.ack_fault      = io_ack_fault;                              // Input:   I/O Acknowledge
   assign EIO_bus.ack_data        = io_ack_data;                               // Input:   I/O Read data
`else // Normal System Verilog style
module RisKy1_core
(
   input    logic                      clk_in,
   input    logic                      reset_in,

   input    logic                      ext_irq,                               // Input:  Machine mode External Interrupt

   `ifdef SIM_DEBUG
   output   logic                      sim_stop,
   `endif

   // L1 Instruction cache interface signals
   L1IC_intf.master                    L1IC_bus,
   output   logic                      ic_flush,

   // L1 Data cache interface signals
   L1DC_intf.master                    L1DC_bus,
   output   logic                      dc_flush,

   // External I/O accesses
   EIO_intf.master                     EIO_bus                                // External I/O bus
);
`endif // VIVADO

   // check for design parameter ERRORs at compile time - see cpu_params.svh

   `ifndef VIVADO // Unfortunately Vivado 2019.2 is not IEEE1800-2009 compliant and thus can't handle the following compile time checks to make sure the design is within bounds
      `include "../includes/csr_checks.svh";
      `include "../includes/cpu_checks.svh";
   `endif

   // misprediction signals that affect Fetch, Decode, Execute stages
   logic                               wb_rld_pc_flag;
   logic                               wb_rld_ic_flag;
   logic                   [PC_SZ-1:0] wb_rld_pc_addr;

   logic                               exe_rld_pc_flag;
   logic                   [PC_SZ-1:0] exe_rld_pc_addr;

   // 1st Stage Fetch interface signals
   F2D_intf                            F2D_bus();

   // 2nd Stage Decode interface signals
   D2E_intf                            D2E_bus();

   // 3rd Stage Execute interface signals
   E2M_intf                            E2M_bus();

   // 4th Stage Memory interface signals
   M2W_intf                            M2W_bus();

   EPC_bus_intf                        epc_bus();

   // interface between WB stage and CSR Functional Unit inside EXE stage
   CSR_WR_intf                         csr_wr_bus();  // master <- outputs: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret);

   // All CSR registers shared between CSREGS and CSR Functional Unit inside EXE stage
   CSR_RD_intf                         csr_rd_bus();  // master: outputs: csr_rd_addr, input  csr_rd_avail, csr_rd_data, csr_fwd_data

   CSR_REG_intf                        csr_reg_bus(); // master: outputs: Ucsr, Scsr, Mcsr

   TRAP_intf                           trap_bus();    // master: outputs: trap_pc, irq, irq_cause

   // register forwarding signals
   FWD_CSR                             fwd_mem_csr;
   FWD_CSR                             fwd_wb_csr;

   FWD_GPR                             fwd_mem_gpr;
   FWD_GPR                             fwd_wb_gpr;

   `ifdef ext_F
   // register forwarding signals
   FWD_FPR                             fwd_mem_fpr;
   FWD_FPR                             fwd_wb_fpr;
   `endif

   logic                               mtime_lo_wr, mtime_hi_wr, mtimecmp_lo_wr, mtimecmp_hi_wr;
   logic                   [2*RSZ-1:0] mtime, mtimecmp;
   logic                     [RSZ-1:0] mmr_wr_data;

   logic                               msip_wr;
   logic                               timer_irq;
   logic                               sw_irq;

   logic                         [1:0] mode;
   logic                         [1:0] nxt_mode;

   GPR_RD_intf                         gpr_rd_bus();
   GPR_WR_intf                         gpr_wr_bus();

   `ifdef ext_F
   // FPR signals
   FP_RD_intf                          fpr_rd_bus();
   FP_WR_intf                          fpr_wr_bus();
   `endif

   logic                               cpu_halt;
   logic                               pipe_flush_dec, pipe_flush_exe, pipe_flush_mem;
   logic                               pc_reload, ic_reload;
   logic                   [PC_SZ-1:0] pc_reload_addr;

   assign ic_flush = FALSE; // WARNING: THESE ARE NOT YET IMPLEMENTED!!!
   assign dc_flush = FALSE;

   // A branch misprediction (exe_rld_pc_flag) only flushes FET, DEC and EXE stages
   assign pipe_flush_dec   = wb_rld_pc_flag | exe_rld_pc_flag;
   assign pipe_flush_exe   = wb_rld_pc_flag | exe_rld_pc_flag;
   assign pipe_flush_mem   = wb_rld_pc_flag;

   assign pc_reload        = wb_rld_pc_flag | exe_rld_pc_flag;
   assign ic_reload        = wb_rld_ic_flag;
   assign pc_reload_addr   = wb_rld_pc_flag ? wb_rld_pc_addr : exe_rld_pc_addr;

   //---------------------------------------------------------------------------
   // 1st Stage = Fetch Stage
   //---------------------------------------------------------------------------
   fetch FET
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   1 = cpu is halted signal

      // Reload teh Fetch PC signals
      .pc_reload(pc_reload),                                                  // Input:   1 = flush & reload PC with mem_rld_pc_addr
      .ic_reload(ic_reload),                                                  // Input:   1 = A STORE to L1 D$ also wrote to L1 I$ address space
      .pc_reload_addr(pc_reload_addr),                                        // Input:   New PC address when wb_rld_pc_flag == 1

      // interface to L1 Instruction Cache
      .L1IC_bus(L1IC_bus),

      // interface to Decode stage
      .F2D_bus(F2D_bus.master)
   );

   //---------------------------------------------------------------------------
   // 2nd Stage = Decode Stage
   //---------------------------------------------------------------------------
   decode DEC
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   halt CPU operation if TRUE

      // pipeline flush signal
      .pipe_flush(pipe_flush_dec),                                            // Input:   1 = flush pipeline

      // interface to Fetch stage
      .F2D_bus(F2D_bus.slave),

      // interface to Execute stage
      .D2E_bus(D2E_bus.master)
   );

   //---------------------------------------------------------------------------
   // 3rd Stage = Execute Stage
   //---------------------------------------------------------------------------
   execute EXE
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   Cause the CPU to stop processing instructions and data
      .sw_irq(sw_irq),                                                        // Input:   Software Interrupt Pending. used in csr_fu.sv. then passed on to MEM and WB/CSR

      .mode(mode),                                                            // Input:   from mode_irq() - mode follows instruction

      // All CSR registers shared between CSREGS and CSR Functional Unit inside EXE stage
      .csr_rd_bus(csr_rd_bus.master),                                         // master <- outputs: csr_rd_addr, inputs: csr_rd_avail, csr_rd_data, csr_fwd_data
      .trap_bus(trap_bus.slave),                                              // slave <- inputs: trap_pc, irq_flag, irq_cause

      // Time to flush pipeline and reload PC signal
      .pipe_flush(pipe_flush_exe),                                            // Input:   1 = flush pipeline

      .rld_pc_flag(exe_rld_pc_flag),                                          // Output:  Cause the Fetch unit to reload the PC
      .rld_pc_addr(exe_rld_pc_addr),                                          // Output:  PC address that will need to be reloaded

      .epc_bus(epc_bus.slave),                                                // slave:   inputs: mepc, sepc, uepc

      // interface to forwarding signals
      .fwd_mem_csr(fwd_mem_csr),                                              // Input:   Mem stage CSR forwarding info
      .fwd_mem_gpr(fwd_mem_gpr),                                              // Input:   Mem stage register forwarding info
      .fwd_wb_csr(fwd_wb_csr),                                                // Input:   WB stage CSR forwarding info
      .fwd_wb_gpr(fwd_wb_gpr),                                                // Input:   WB stage register forwarding info

      // interface to GPR
      .gpr_rd_bus(gpr_rd_bus.master),                                         // master:   read access to all MAX_GPR General Purpose registers

      `ifdef ext_F
      // interface to forwarding signals
      .fwd_mem_fpr(fwd_mem_fpr),                                              // Input:   Mem stage register forwarding info
      .fwd_wb_fpr(fwd_wb_fpr),                                                // Input:   WB stage register forwarding info

      // interface to FPR
      .fpr_rd_bus(fpr_rd_bus.master),                                         // Master:   read access to all MAX_FPR single-precision Floating Point registers - all registers can be read at anytime
      `endif

      // interface to Decode stage
      .D2E_bus(D2E_bus.slave),                                                // slave:

      // interface to Memory stage
      .E2M_bus(E2M_bus.master)                                                // master:
   );

   //---------------------------------------------------------------------------
   // 4th Stage = Memory Stage
   //---------------------------------------------------------------------------
   mem MEM
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   halt CPU operation if TRUE

      `ifdef SIM_DEBUG
      .sim_stop(sim_stop),
      `endif

      // Internal I/O Write Data - in case it's a Store instruction wanting to write to the contents of the following registers
      .msip_wr(msip_wr),                                                      // Output:  write to I/O msip register
      .mtime_lo_wr(mtime_lo_wr),                                              // Output:  write to I/O mtime_lo register
      .mtime_hi_wr(mtime_hi_wr),                                              // Output:  write to I/O mtime_hi register
      .mtimecmp_lo_wr(mtimecmp_lo_wr),                                        // Output:  write to I/O mtimecmp_lo register
      .mtimecmp_hi_wr(mtimecmp_hi_wr),                                        // Output:  write to I/O mtimecmp_hi register
      .mmr_wr_data(mmr_wr_data),                                              // Output:  write data for above registers

      // Internal I/O Read Data - in case it's a Load instruction wanting to read the contents of the following registers
      .mtime(mtime),                                                          // Input:   contents of mtime register
      .mtimecmp(mtimecmp),                                                    // Input:   contents of mtimecmp register

      // misprediction signals
      .pipe_flush(pipe_flush_mem),                                            // Input:   1 = flush pipeline

      // forwarding data
      .fwd_mem_csr(fwd_mem_csr),                                              // Output:  Mem stage CSR forwarding info
      .fwd_mem_gpr(fwd_mem_gpr),                                              // Output:  MEM stage register forwarding info
      `ifdef ext_F
      // forwarding data
      .fwd_mem_fpr(fwd_mem_fpr),                                              // Output:  MEM stage register forwarding info
      `endif

      // Interface between MEM_IO and L1 D$
      .L1DC_bus(L1DC_bus.master),                                             // master:

      // External I/O accesses
      .EIO_bus(EIO_bus.master),                                               // master:

      // interface to Execute stage
      .E2M_bus(E2M_bus.slave),                                                // slave:

      // interface to WB stage
      .M2W_bus(M2W_bus)
   );

   //---------------------------------------------------------------------------
   // 5th Stage = Write Back Stage
   //---------------------------------------------------------------------------
   logic             trigger_wfi;

   wb WB
   (
      .reset_in(reset_in),                                                    // Input:  system reset

      .cpu_halt(cpu_halt),                                                    // Input:   halt CPU operation if TRUE

      .trigger_wfi(trigger_wfi),                                              // Output:  Trigger a CPU halt

      // flush pipeline/reload PC signals
      .rld_pc_flag(wb_rld_pc_flag),                                           // Output:  1 = flush pipeline & reload PC with mem_rld_pc_addr
      .rld_ic_flag(wb_rld_ic_flag),                                           // Output:  1 = A STORE to L1 D$ also wrote to L1 I$ address space
      .rld_pc_addr(wb_rld_pc_addr),                                           // Output:  New PC when wb_rld_pc_flag == 1

      // interface to Memory stage
      .M2W_bus(M2W_bus.slave),

      // GPR forwarding data
      .fwd_wb_gpr(fwd_wb_gpr),                                                // Output:  WB stage register forwarding for GPR info
      .fwd_wb_csr(fwd_wb_csr),                                                // Output:  WB stage CSR forwarding info
      `ifdef ext_F
      // FPR forwarding data
      .fwd_wb_fpr(fwd_wb_fpr),                                                // Output:  WB stage register forwarding for FPR info

      // interface to FPR
      .fpr_wr_bus(fpr_wr_bus.master)
      `endif

      // interface to GPR
      .gpr_wr_bus(gpr_wr_bus.master),                                         // writes data to a specific architectural register

      // signals from WB stage
      .csr_wr_bus(csr_wr_bus.master)                                          // master -> output: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret
   );

   //---------------------------------------------------------------------------
   // Architectural CSR Registers
   //---------------------------------------------------------------------------
   csr_regs CSREGS
   (
      .clk_in(clk_in),
      .reset_in(reset_in),

      .mtime(mtime),                                                          // Input:

      .mode(mode),                                                            // Input:   current instruction mode needed by EXE stage
      .nxt_mode(nxt_mode),                                                    // Input:   next instruction mode

      .ext_irq(ext_irq),                                                      // Input:   External Interrupt
      .timer_irq(timer_irq),                                                  // Input:   Timer & Software Interrupt from clint.sv

      .epc_bus(epc_bus.master),                                               // master:  outputs: mepc, sepc, uepc

      .csr_reg_bus(csr_reg_bus.master),                                       // master:  outputs: Ucsr, Scsr, Mcsr

      .csr_rd_bus(csr_rd_bus.slave),                                          // slave:   inputs: csr_rd_addr, outputs: csr_rd_avail, csr_rd_data, csr_fwd_data

      .csr_wr_bus(csr_wr_bus.slave)                                           // slave:   inputs: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret
   );

   //---------------------------------------------------------------------------
   // Produces signals: mode, trap_pc, irq_flag, and irq_cause based on related
   //                   signal inputs irq_cause, sw_irq, ....
   //---------------------------------------------------------------------------
   mode_irq MIRQ
   (
      .clk_in(clk_in),                                                        // Input:
      .reset_in(reset_in),                                                    // Input:

      .ext_irq(ext_irq),                                                      // Input:

      .mode(mode),                                                            // Output:  to EXE stage - mode follows instruction
      .nxt_mode(nxt_mode),                                                    // Output:  next instruction mode used by csr_regs.sv

      .csr_reg_bus(csr_reg_bus.slave),                                        // slave:   inputs: Ucsr, Scsr, Mcsr

      .csr_wr_bus(csr_wr_bus.slave),                                          // slave:   input: csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, uret, sret, mret

      .trap_bus(trap_bus.master)                                              // master:  output: trap_pc, irq_flag, irq_cause
   );

   //---------------------------------------------------------------------------
   // General Purpose Registers - 32 x 32 bits for RV32i
   //---------------------------------------------------------------------------
   gpr GPR
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .gpr_rd_bus(gpr_rd_bus.slave),

      .gpr_wr_bus(gpr_wr_bus.slave)
   );

   //---------------------------------------------------------------------------
   // Single Precision Floating Point Registers
   // NOTE: DO NOT USE ext_F. It is not yet completed
   //---------------------------------------------------------------------------
   `ifdef ext_F
   fpr FPR
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .fpr_rd_bus(fpr_rd_bus.slave),                                          // slave: read from MAX_FPR General Purpose registers

      .fpr_wr_bus(fpr_wr_bus.slave)
   );
   `endif

   //---------------------------------------------------------------------------
   // Interrupt Controller & Memory Mapped Registers
   //---------------------------------------------------------------------------
   // contains memory mapped mtime and mtimecmp registers
   irq IRQ
   ( .clk_in(clk_in), .reset_in(reset_in),

      .mtime_lo_wr(mtime_lo_wr),                                              // Input:   write to I/O mtime_lo register
      .mtime_hi_wr(mtime_hi_wr),                                              // Input:   write to I/O mtime_hi register
      .mtimecmp_lo_wr(mtimecmp_lo_wr),                                        // Input:   write to I/O mtimecmp_lo register
      .mtimecmp_hi_wr(mtimecmp_hi_wr),                                        // Input:   write to I/O mtimecmp_hi register
      .msip_wr(msip_wr),                                                      // Input:   write to I/O msip register
      .mmr_wr_data(mmr_wr_data),                                              // Input:   write data for above registers
      .sw_irq(sw_irq),                                                        // Output:  Software Interrupt (1 bit each)
      .timer_irq(timer_irq),                                                  // Output:  Timer Interrupts (1 bit each)
      .mtime(mtime), .mtimecmp(mtimecmp)                                      // Outputs: 64 bit mtime & mtimecmp registers
   );

   //---------------------------------------------------------------------------
   // CPU Halt Logic
   //---------------------------------------------------------------------------
   // Putting CPU to sleep and waking it up
   always_ff @(posedge clk_in)
   begin
      if (reset_in || ext_irq)
         cpu_halt <= FALSE;
      else if (trigger_wfi)  // This code is not reachable until trigger_wfi is not a 0 constant in wb.sv
         cpu_halt <= TRUE;
   end

endmodule