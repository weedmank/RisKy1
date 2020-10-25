// ----------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  RisKy1_core.sv
// Description   :  Top level - connects all necessary modules for the CPU core
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

//`define VIVADO // need to figure out how to add these defines into Vivado project - these MUST be commented out if not using Vivado!!!!!
//`define ext_M

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;
//                                                                                                                                                     
//                                          ............................................................................
//                                          :  RisKy1_core                                                             :
//                                          :                                                                          :
//                                          :                                                                          :
//                                          :           +--------------+                                               :
//                                          :           |    FETCH     |                                               :
//    L1 Instruction Cache Interface -------:---------->|              |                                               :
//                                          :           |              |                                               :
//                                          :           +------+-------+                                               :
//                                          :                  |                                                       :
//                                          :                  v                                                       :
//                                          :           +------+-------+                                               :
//                                          :           |              |                                               :
//                                          :           |    DECODE    |                                               :
//                                          :           |              |                                               :
//                                          :           +------+-------+                                               :
//                                          :                  |                                                       :
//                                          :                  v                          +-----------+                :
//                                          :           +------+-------+                  |   IRQ     |                :
//                                          :           |              |   timer_irq      |           |<---------------:------ External Interrupts (optional)
//                                          :       +-->|    EXECUTE   |<-----------------|           |                :
//                                          :       |   |              |   sw_irq         +-----+-----+                :
//                                          :       |   +------+-------+                        ^                      :
//                                          :       |          |                                |                      :
//                                          :       |          v                                v                      :
//                                          :       |   +------+-------+                  +-----+-----+                :
//                                          :       |   |              |                  |   MEM_IO  |<---------------:-----> External I/O interface
//                                          :       |   |     MEM      |<---------------->|           |                :
//                                          :       |   |              |                  |           |<----------+    :
//                                          :       |   +------+-------+                  +-----------+           |    :
//                                          :       |          |                                                  |    :
//                                          :       |          v                          +------------------+    |    :
//                                          :       |   +------+-------+                  |   Architectural  |    |    :
//                                          :       |   |              |----------------->|   Registers      |    |    :
//                                          :       |   |      WB      |                  |   (gpr, fpr)     |    |    :
//                                          :       |   |              |                  +----------+-------+    |    :
//                                          :       |   +--------------+                             |            |    :
//                                          :       |                                                |            |    :
//                                          :       |                                                |            |    :
//                                          :       |                                                |            |    :
//                                          :       +------------------------------------------------+            |    :
//                                          :                                                                     |    :
//         L1 Data Cache Interface <--------:---------------------------------------------------------------------+    :
//                                          :                                                                          :
//                                          :..........................................................................:
//                                                                                                                      
//             
//             
//             
//             
//             
//             
`define VIVADO // WARNING! - These two define's MUST be commented out if not making a Vivado design becuase I have not yet figured out how to globally define them!!!!
`define ext_M
`ifdef VIVADO
module RisKy1_core // Verilog style - for use in Vivado
(
   // This `ifdef VIVADO monkey business is all due to Vivado having a limited System Verilog understanding when instantiating a top level module in Block Design!!!
   // All the interfaces need to be in Verilog style as Vivado can't handle any SystemVerilog in the top level module when placing it in a Block Design. Therefore this
   // module, RisKy1_core.sv, CANNOT be a top level module. This means we need a wrapper module (See RisKy1_RV32i.v). 
   input    wire                       clk_in,
   input    wire                       reset_in,

   // L1 Instruction cache interface signals
   output   wire                       ic_req,                                // Output: Request            - Fetch unit is requesting a cache line of data from the I $
   output   wire           [PC_SZ-1:0] ic_addr,                               // Output: Request address    - Memory address that Fetch unit wants to get a cache line of data from
   output   wire                       ic_flush,                              // Output: signal requesting to flush the Instruction Cache
   input    wire                       ic_ack,                                // Input:  Ackknowledge       - I$ is ackknowledging it has data (ic_rd_data_in) for the Fetch unit
   input    wire        [CL_LEN*8-1:0] ic_ack_data,                           // Input:  Acknowledge data   - this contains CL_LEN bytes of data => CL_LEN/4 instructions

   // L1 Data cache interface signals
   output   wire                       dc_req,                                // Output: Request - must remain high until ack
   output   wire           [PC_SZ-1:0] dc_rw_addr,                            // Output: Request - ls_addr - Load/Store Address
   output   wire                       dc_rd,                                 // Output: Request - is_ld
   output   wire                       dc_wr,                                 // Output: Request - is_st
   output   wire             [RSZ-1:0] dc_wr_data,                            // Output: Request - st_data - Store data
   output   wire                 [2:0] dc_size,                               // Output: Request - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   output   wire                       dc_zero_ext,                           // Output: Request - 1 = Zero Extend
   output   wire                       dc_inv_flag,                           // Output: Request - invalidate flag
   output   wire                       dc_flush,                              // Output: Request - Output: signal requesting to flush the Data Cache
   input    wire                       dc_ack,
   input    wire             [RSZ-1:0] dc_ack_data,

   `ifdef SIM_DEBUG
   output   wire                       sim_stop,
   `endif

   `ifdef ext_N
   input    wire                       ext_irq,                               // Input:  Machine mode External Interrupt
   `endif

   // External I/O accesses
   output   wire                       io_req,                                // Output:  I/O Request
   output   wire           [PC_SZ-1:0] io_addr,                               // Output:  I/O Address
   output   wire                       io_rd,                                 // Output:  I/O Read signal. 1 = read
   output   wire                       io_wr,                                 // Output:  I/O Write signal. 1 = write
   output   wire             [RSZ-1:0] io_wr_data,                            // Output:  I/O Write data that is written when io_wr == 1
   
   input    wire                       io_ack,                                // Input:   I/O Acknowledge
   input    wire                       io_ack_fault,                          // Input:   I/O Acknowledge
   input    wire             [RSZ-1:0] io_rd_data                             // Input:   I/O Read data
);
   // Vivado 2019.2 cannot yet handle System Verilog, thus a wrapper has to be created (i.e. RisKy1_RV32i.v) and individual module port signals created/assigned in Verilog style
   L1IC                         L1IC_intf();   // OK to use this in RisKy1_core outside of module ports for Vivado
   L1DC                         L1DC_intf();

   // ports are/need to be Verilog type for Vivado
   assign ic_req              = L1IC_intf.req;
   assign ic_addr             = L1IC_intf.addr;
   assign L1IC_intf.ack       = ic_ack;
   assign L1IC_intf.ack_data  = ic_ack_data;
   
   
   
   assign dc_req              = L1DC_intf.req;                                // Request           - must remain high until ack
   assign dc_rw_addr          = L1DC_intf.req_data.rw_addr;                   // Request data      - ls_addr - Load/Store Address
   assign dc_rd               = L1DC_intf.req_data.rd;                        // Request data      - is_ld
   assign dc_wr               = L1DC_intf.req_data.wr;                        // Request data      - is_ld
   assign dc_wr_data          = L1DC_intf.req_data.wr_data;                   // Request data      - st_data - Store data
   assign dc_size             = L1DC_intf.req_data.size;                      // Request data      - size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   assign dc_zero_ext         = L1DC_intf.req_data.zero_ext;                  // Request data      - 1 = Zero Extend
   assign dc_inv_flag         = L1DC_intf.req_data.inv_flag;                  // Request data      - invalidate flag
   assign L1DC_intf.ack       = dc_ack;                                       // Acknowledge       - D$ is ackknowledging it has data (dc_ack_data) for the MEM unit
   assign L1DC_intf.ack_data  = dc_ack_data;                                  // Acknowledge data

`else // Normal System Verilog style
module RisKy1_core
(
   input    logic                      clk_in,
   input    logic                      reset_in,

   `ifdef ext_N
   input    logic                      ext_irq,                               // Input:  Machine mode External Interrupt
   `endif

   `ifdef SIM_DEBUG
   output   logic                      sim_stop,
   `endif

   // L1 Instruction cache interface signals
   L1IC.master                         L1IC_intf,
   output   logic                      ic_flush,

   // L1 Data cache interface signals
   L1DC.master                         L1DC_intf,
   output   logic                      dc_flush,

   // External I/O accesses
   output   logic                      io_req,                                // Output:  I/O Request
   output   logic          [PC_SZ-1:0] io_addr,                               // Output:  I/O Address
   output   wire                       io_rd,                                 // Output:  I/O Read signal. 1 = read
   output   wire                       io_wr,                                 // Output:  I/O Write signal. 1 = write
   output   logic            [RSZ-1:0] io_wr_data,                            // Output:  I/O Write data that is written when io_wr == 1
   
   input    logic                      io_ack,                                // Input:   I/O Acknowledge
   input    logic                      io_ack_fault,                          // Input:   I/O Acknowledge
   input    logic            [RSZ-1:0] io_rd_data                             // Input:   I/O Read data
);
`endif // VIVADO

   // check for design parameter ERRORs at compile time - see cpu_params.svh
   `ifdef ext_N
      `ifndef ext_U
         $error ("Must define 'ext_U' in order to use ext_N");
      `endif
   `endif

   `ifdef ext_F
      `ifndef ext_Zicsr
         $error ("The F extension depends on the 'Zicsr' extension for control and status register access."); // The F extension depends on the “Zicsr�? extension for control and status register access.
      `endif
   `endif

   `ifndef VIVADO // silly Vivado 2019.2 is not IEEE1800-2009 compliant and thus can't handle the following compile time checks to make sure design is within bounds
   generate
      `ifdef use_MHPM_CNTRS
      if (NUM_MHPM == 0)                                                         $error ("use_MHPM_CNTRS is defined but NUM_MHPM is still 0. Change NUM_MHPM value in cpu_params.svh");
      `endif
      if (MAX_GPR != 32)                                                         $warning("RISC-V compatible designs should set MAX_GPR = 32. See cpu_params.svh");
      
      if (SET_MCOUNTINHIBIT == 1)                                                $warning("Setting SET_MCOUNTINHIBIT == 1 forces CSR to read a constant value of SET_MCOUNTINHIBIT_BITS. See cpu_params.svh");
      
      if ((Phys_Addr_Lo % 4) != 0)                                               $fatal ("Phys_Addr_Lo must be a multiple of 4. see cpu_params_pkg.sv");
      if ((Phys_Depth % 4) != 0)                                                 $fatal ("Phys_Depth must be a multiple of 4. see cpu_params_pkg.sv");

      if ((L1_IC_Lo % 4) != 0)                                                   $fatal ("L1_IC_Lo must be a multiple of 4. see cpu_params_pkg.sv");
      if ((Instr_Depth % 4) != 0)                                                $fatal ("Instr_Depth must be a multiple of 4. see cpu_params_pkg.sv");

      if (CL_LEN <  4)                                                           $fatal ("Length of input data to CPU should be 4 bytes or more");
      if (XLEN != 32)                                                            $fatal ("XLEN must be 32 for this RV32 CPU");
      if (CI_SZ != 16)                                                           $fatal ("CI_SZ must be 16 for Compressed Instructions");
      if (ASSEMBLY == SEMANTICS)                                                 $fatal ("SEMANTICS value cannot be same as ASSEMBLY");
      if (SET_MCOUNTINHIBIT >= 2)                                                $fatal ("SET_MCOUNTINHIBIT must be 0 or 1");
      if (SET_MCOUNTINHIBIT_BITS < (1<<32))                                      $error ("SET_MCOUNTINHIBIT_BITS should only be 32 bits in width");
      if (NUM_MHPM > 29)                                                         $fatal ("NUM_MHPM must be a value of 29 or less");
      if (MAX_CSR != 4096)                                                       $fatal ("MAX_CSR must be 4096");

      // Internal I/O address range check
      if (Int_IO_Addr_Hi <= Int_IO_Addr_Lo)                                      $fatal ("Int_IO_Addr_Hi must be > Int_IO_Addr_Lo");

      // External I/O address range check
      if (Ext_IO_Addr_Hi <= Ext_IO_Addr_Lo)                                      $fatal ("Ext_IO_Addr_Hi must be > Ext_IO_Addr_Lo");

      // MSIP_Base_Addr related checks
      if (MSIP_Base_Addr[0])                                                     $fatal ("MSIP_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MSIP_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))            $fatal ("MSIP_Base_Addr must be inside Int_IO_Addr address range");
      if (MSIP_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})               $fatal ("MSIP_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MSIP_Base_Addr inside {[MTIME_Base_Addr:MTIME_Base_Addr+7]})           $fatal ("MSIP_Base_Addr must not be inside MTIME_Base_Addr address range");
      if (MSIP_Base_Addr inside {[MTIMECMP_Base_Addr:MTIMECMP_Base_Addr+7]})     $fatal ("MSIP_Base_Addr must not be inside MTIMECMP_Base_Addr address range");

      // MTIME_Base_Addr related checks
      if (MTIME_Base_Addr[0])                                                    $fatal ("MTIME_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MTIME_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))           $fatal ("MTIME_Base_Addr must be inside Int_IO_Addr address range");
      if (MTIME_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})              $fatal ("MTIME_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MTIME_Base_Addr inside {[MSIP_Base_Addr:MSIP_Base_Addr+3]})            $fatal ("MTIME_Base_Addr must not be inside MSIP_Base_Addr address range");
      if (MTIME_Base_Addr inside {[MTIMECMP_Base_Addr:MTIMECMP_Base_Addr+7]})    $fatal ("MTIME_Base_Addr must not be inside MTIMECMP_Base_Addr address range");

      // MTIMECMP_Base_Addr related checks
      if (MTIMECMP_Base_Addr[0])                                                 $fatal ("MTIMECMP_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MTIMECMP_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))        $fatal ("MTIMECMP_Base_Addr must be inside Int_IO_Addr address range");
      if (MTIMECMP_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})           $fatal ("MTIMECMP_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MTIMECMP_Base_Addr inside {[MSIP_Base_Addr:MSIP_Base_Addr+3]})         $fatal ("MTIMECMP_Base_Addr must not be inside MSIP_Base_Addr address range");
      if (MTIMECMP_Base_Addr inside {[MTIME_Base_Addr:MTIME_Base_Addr+7]})       $fatal ("MTIMECMP_Base_Addr must not be inside MTIME_Base_Addr address range");

      // L1 Instruction Cache related checks
      if (L1_IC_Hi <= L1_IC_Lo)                                                  $fatal ("L1_IC_Hi must be > L1_IC_Lo");
      if (!(L1_IC_Lo inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))                      $fatal ("L1_IC_Lo must be inside Phys_Addr address range");
      if (!(L1_IC_Hi inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))                      $fatal ("L1_IC_Hi must be inside Phys_Addr address range");
      if (L1_IC_Lo inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]})                     $fatal ("L1_IC_Lo must not be inside Int_IO_Addr address range");
      if (L1_IC_Lo inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})                     $fatal ("L1_IC_Lo must not be inside Ext_IO_Addr address range");

      // Physical address range check
      if (Phys_Addr_Hi <= Phys_Addr_Lo)                                          $fatal ("Phys_Addr_Hi must be > Phys_Addr_Lo");
      // reset vector related checks
      `ifdef ext_C
      if (RESET_VECTOR_ADDR[0])                                                  $fatal ("RESET_VECTOR_ADDR must be 2 byte aligned. i.e. lower bit = 0");
      `else
      if (RESET_VECTOR_ADDR[1:0])                                                $fatal ("RESET_VECTOR_ADDR must be 4 byte aligned. i.e. lower 2 bits = 2'b00");
      `endif
      if (!(RESET_VECTOR_ADDR inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))             $fatal ("RESET_VECTOR_ADDR must be inside Phys_Addr_Lo address range");
   endgenerate
   `endif

   // misprediction signals that affect Fetch, Decode, Execute stages
   logic                               mem_rld_pc_flag;
   logic                               mem_rld_ic_flag;
   logic                   [PC_SZ-1:0] mem_rld_pc_addr;
   
   logic                               exe_rld_pc_flag;
   logic                   [PC_SZ-1:0] exe_rld_pc_addr;

   // 1st Stage Fetch interface signals
   F2D                                 F2D_bus();

   // 2nd Stage Decode interface signals
   D2E                                 D2E_bus();

   // 3rd Stage Execute interface signals
   E2M                                 E2M_bus();

   // 4th Stage Memory interface signals
   M2W                                 M2W_bus();
   L1DC                                MIO_bus();

   // interface between MEM stage and CSR Functional Unit inside EXE stage
   CSR_MEM                             CSR_MEM_bus();

   // register forwarding signals
   FWD_GPR                             fwd_mem_gpr;
   FWD_GPR                             fwd_wb_gpr;

   `ifdef ext_F
   // register forwarding signals
   FWD_FPR                             fwd_mem_fpr;
   FWD_FPR                             fwd_wb_fpr;
   `endif

   logic                         [1:0] mode;                                  // Current CPU mode: Machine, Supervisor, or User

   logic                               mtime_lo_wr, mtime_hi_wr, mtimecmp_lo_wr, mtimecmp_hi_wr;
   logic                   [2*RSZ-1:0] mtime, mtimecmp;
   logic                     [RSZ-1:0] msip_reg;
   logic                     [RSZ-1:0] mmr_wr_data;

   `ifdef ext_N
   logic                               msip_wr;
   logic                               time_irq, sw_irq;
   `endif

   // GPR signals
   logic       [MAX_GPR-1:0] [RSZ-1:0] gpr;                                   // MAX_GPR General Purpose registers

   RBUS                                gpr_bus();

   `ifdef ext_F
   // FPR signals
   logic      [MAX_FPR-1:0] [FLEN-1:0] fpr;                                   // MAX_FPR Floating Point Registers
   logic                               fpr_Fd_wr;                             // 1 = write to destination register
   logic                 [FPR_ASZ-1:0] fpr_Fd_addr;                           // Destination Register to write
   logic                    [FLEN-1:0] fpr_Fd_data;                           // data that will be written to the destination register
   `endif

   logic                               cpu_halt;
   logic                               pipe_flush_dec, pipe_flush_exe, pipe_flush_mem;
   logic                               pc_reload, ic_reload;
   logic                   [PC_SZ-1:0] pc_reload_addr;
   
   assign ic_flush = FALSE; // WARNING: THESE ARE NOT YET IMPLEMENTED!!!
   assign dc_flush = FALSE;

   // A branch misprediction (exe_rld_pc_flag) only flushes FET, DEC and EXE stages
   assign pipe_flush_dec   = mem_rld_pc_flag | exe_rld_pc_flag;     
   assign pipe_flush_exe   = mem_rld_pc_flag | exe_rld_pc_flag;;     
   assign pipe_flush_mem   = mem_rld_pc_flag;     
   
   assign pc_reload        = mem_rld_pc_flag | exe_rld_pc_flag;
   assign ic_reload        = mem_rld_ic_flag;
   assign pc_reload_addr   = mem_rld_pc_flag ? mem_rld_pc_addr : exe_rld_pc_addr;
   
   // 1st Stage = Fetch Stage
   fetch FET
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   1 = cpu is halted signal

      // Reload teh Fetch PC signals
      .pc_reload(pc_reload),                                                  // Input:   1 = flush & reload PC with mem_rld_pc_addr
      .ic_reload(ic_reload),                                                  // Input:   1 = A STORE to L1 D$ also wrote to L1 I$ address space
      .pc_reload_addr(pc_reload_addr),                                        // Input:   New PC address when mem_rld_pc_flag == 1

      // interface to L1 Instruction Cache
      .L1IC_intf(L1IC_intf),

      // interface to Decode stage
      .F2D_bus(F2D_bus)
   );

   // 2nd Stage = Decode Stage
   decode DEC
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   halt CPU operation if TRUE

      // pipeline flush signal
      .pipe_flush(pipe_flush_dec),                                            // Input:   1 = flush pipeline

      // interface to Fetch stage
      .F2D_bus(F2D_bus),

      // interface to Execute stage
      .D2E_bus(D2E_bus)
   );

   // 3rd Stage = Execute Stage
   execute EXE
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .cpu_halt(cpu_halt),                                                    // Input:   Cause the CPU to stop processing instructions and data
      
      // Time to flush pipeline and reload PC signal
      .pipe_flush(pipe_flush_exe),                                            // Input:   1 = flush pipeline

      .rld_pc_flag(exe_rld_pc_flag),                                          // Output:  Cause the Fetch unit to reload the PC
      .rld_pc_addr(exe_rld_pc_addr),                                          // Output:  PC address that will need to be reloaded

      .mode(mode),                                                            // Output:  Machine, Supervisor or User

      // interface to forwarding signals
      .fwd_mem_gpr(fwd_mem_gpr),                                              // Input:   Mem stage register forwarding info
      .fwd_wb_gpr(fwd_wb_gpr),                                                // Input:   WB stage register forwarding info

      // interface to GPR
      .gpr(gpr),                                                              // Input:   read access to all MAX_GPR General Purpose registers - all registers can be read at anytime

      `ifdef ext_F
      // interface to forwarding signals
      .fwd_mem_fpr(fwd_mem_fpr),                                              // Input:   Mem stage register forwarding info
      .fwd_wb_fpr(fwd_wb_fpr),                                                // Input:   WB stage register forwarding info

      // interface to FPR
      .fpr(fpr),                                                              // Input:   read access to all MAX_FPR single-precision Floating Point registers - all registers can be read at anytime
      `endif

      // interface to Decode stage
      .D2E_bus(D2E_bus),

      // interface to Memory stage
      .E2M_bus(E2M_bus),
      
      // signals shared between CSR functional Unit inside EXE stage and MEM stage
      .CSR_MEM_bus(CSR_MEM_bus)
   );

   // 4th Stage = Memory Stage
   mem MEM
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      `ifdef ext_N
      .ext_irq(ext_irq),                                                      // Input:   External Interrupt
      .time_irq(time_irq),                                                    // Input:   Timer Interrupt from clint.sv
      .sw_irq(sw_irq),                                                        // Input:   Software Interrupt from clint.sv
      `endif
      .mtime(mtime),                                                          // Input:   Memory-mapped mtime register contents
      
      // misprediction signals
      .pipe_flush(pipe_flush_mem),                                            // Input:  1 = flush pipeline
      
      .rld_pc_flag(mem_rld_pc_flag),                                          // Output:  1 = flush pipeline & reload PC with mem_rld_pc_addr
      .rld_ic_flag(mem_rld_ic_flag),                                          // Output:  1 = A STORE to L1 D$ also wrote to L1 I$ address space
      .rld_pc_addr(mem_rld_pc_addr),                                          // Output:  New PC when mem_rld_pc_flag == 1

      .cpu_halt(cpu_halt),                                                    // Output:  halt CPU operation if TRUE

      // forwarding data
      .fwd_mem_gpr(fwd_mem_gpr),                                              // Output:  MEM stage register forwarding info

      `ifdef ext_F
      // forwarding data
      .fwd_mem_fpr(fwd_mem_fpr),                                              // Output:  MEM stage register forwarding info
      `endif

      // Memory and I/O transfers between MEM Stage and MEM_IO - is this Load/Store instruction going to System Memory or I/O?
      .MIO_bus(MIO_bus),

      // interface to Execute stage
      .E2M_bus(E2M_bus),

      // interface to WB stage
      .M2W_bus(M2W_bus),
      
      // signals shared between CSR functional Unit inside EXE stage and MEM stage
      .CSR_MEM_bus(CSR_MEM_bus)
   );

   // 5th Stage = Write Back Stage
   wb WB
   (
      `ifdef SIM_DEBUG
      .clk_in(clk_in),                                                        // Input:  system clock (ONLY needed for assertion testing)
      `endif
      .reset_in(reset_in),                                                    // Input:  system reset

      .cpu_halt(cpu_halt),                                                    // Input:   halt CPU operation if TRUE

      // interface to Memory stage
      .M2W_bus(M2W_bus),

      `ifdef ext_F
      // forwarding data
      .fwd_wb_fpr(fwd_wb_fpr),                                                // Output:  WB stage register forwarding info

      // interface to FPR
      .fpr_Fd_wr(fpr_Fd_wr),                                                  // Output: 1 = write to destination register
      .fpr_Fd_addr(fpr_Fd_addr),                                              // Output: Destination Register to write (i.e 0 - 31)
      .fpr_Fd_data(fpr_Fd_data),                                              // Output: data that will be written to the destination register
      `endif

      // forwarding data
      .fwd_wb_gpr(fwd_wb_gpr),                                                // Output:  WB stage register forwarding info

      // interface to GPR
      .gpr_bus(gpr_bus)
   );

   // General Purpose Registers
   gpr GPR
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .gpr(gpr),                                                              // Output:  MAX_GPR General Purpose registers - all registers can be read at anytime

      .gpr_bus(gpr_bus)
   );

   // NOTE: The following will not currently connect to anything - ext_F is not yet completed as of 6/14/2020
   `ifdef ext_F
   // Single Precision Floating Point Registers
   fpr FPR
   (
      .clk_in(clk_in), .reset_in(reset_in),                                   // Inputs:  system clock and reset

      .fpr(fpr),                                                              // Output:  MAX_FPR General Purpose registers - all registers can be read at anytime
      .fpr_Fd_wr(fpr_Fd_wr),                                                  // Input:   1 = write to destination register
      .fpr_Fd_addr(fpr_Fd_addr),                                              // Input:   Destination Register to write
      .fpr_Fd_data(fpr_Fd_data)                                               // Input:   data that will be written to the destination register
   );
   `endif

   //---------------------------------------------------------------------------
   // MEM_IO: Memory (L1 D$) and I/O (devices/register) Interface
   //---------------------------------------------------------------------------
   mem_io MEM_IO
   (
      .mode(mode),                                                            // Input:   current CPU mode

      // Mmeory and I/O transfers between MEM Stage and MEM_IO
      .MIO_bus(MIO_bus),

      // Interface between MEM_IO and L1 D$
      .L1DC_intf(L1DC_intf),

      // Internal I/O Write Data - in case it's a Store instruction wanting to write to the contents of the following registers
      `ifdef ext_N
      .msip_wr(msip_wr),                                                      // Output:  write to I/O msip register
      `endif
      .mtime_lo_wr(mtime_lo_wr),                                              // Output:  write to I/O mtime_lo register
      .mtime_hi_wr(mtime_hi_wr),                                              // Output:  write to I/O mtime_hi register
      .mtimecmp_lo_wr(mtimecmp_lo_wr),                                        // Output:  write to I/O mtimecmp_lo register
      .mtimecmp_hi_wr(mtimecmp_hi_wr),                                        // Output:  write to I/O mtimecmp_hi register
      .mmr_wr_data(mmr_wr_data),                                              // Output:  write data for above registers

      // Internal I/O Read Data - in case it's a Load instruction wanting to read the contents of the following registers
      .mtime(mtime),                                                          // Input:   contents of mtime register
      .mtimecmp(mtimecmp),                                                    // Input:   contents of mtimecmp register
      .msip_reg(msip_reg),                                                    // Input:   contents of msip_reg register

      `ifdef SIM_DEBUG
      .sim_stop(sim_stop),
      `endif

      // External I/O accesses
      .io_req(io_req),                                                        // Output:  External I/O Request
      .io_addr(io_addr),                                                      // Output   External I/O Address
      .io_rd(io_rd),                                                          // Output:  External I/O Read signal. 1 = read
      .io_wr(io_wr),                                                          // Output:  External I/O Write signal. 1 = write
      .io_wr_data(io_wr_data),                                                // Output:  External I/O data that is written when io_wr == 1

      .io_ack(io_ack),                                                        // Input:   External I/O Acknowledge
      .io_ack_fault(io_ack_fault),                                            // Input:   External I/O Access Fault
      .io_rd_data(io_rd_data)                                                 // Input:   External I/O read data
   );

   //---------------------------------------------------------------------------
   // Interrupt Controller & Memory Mapped Registers
   //---------------------------------------------------------------------------
   // contains memory mapped mtime and mtimecmp registers
   irq IRQ
   ( .clk_in(clk_in), .reset_in(reset_in),

      .mtime_lo_wr(mtime_lo_wr),                                              // Input:  write to I/O mtime_lo register
      .mtime_hi_wr(mtime_hi_wr),                                              // Input:  write to I/O mtime_hi register
      .mtimecmp_lo_wr(mtimecmp_lo_wr),                                        // Input:  write to I/O mtimecmp_lo register
      .mtimecmp_hi_wr(mtimecmp_hi_wr),                                        // Input:  write to I/O mtimecmp_hi register
      .mmr_wr_data(mmr_wr_data),                                              // Input:  write data for above registers

     `ifdef ext_N
     .msip_wr(msip_wr),
     .time_irq(time_irq), .sw_irq(sw_irq),                                    // Outputs: Timer and Software Interrupts (1 bit each)
     `endif

     .mtime(mtime), .mtimecmp(mtimecmp),                                      // Outputs: 64 bit mtime & mtimecmp registers
     .msip_reg(msip_reg)                                                      // Output:  Software Interrupt Pending register (1 bit)
   );

endmodule