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
// File          :  mem.sv
// Description   :  This module read/writes to System Memory (Load/Store)
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module mem
(
   input    logic                         clk_in,
   input    logic                         reset_in,

   input    logic                         cpu_halt,                                 // Input:   disable CPU operations by not allowing any more input to this stage

   `ifdef SIM_DEBUG
   output   logic                         sim_stop,
   `endif

   // I/O Write signals to specific RISC-V I/O registers
   output   logic                         msip_wr,                                  // Output:  write to I/O msip register
   output   logic                         mtime_lo_wr,                              // Output:  write to I/O mtime_lo register
   output   logic                         mtime_hi_wr,                              // Output:  write to I/O mtime_hi register
   output   logic                         mtimecmp_lo_wr,                           // Output:  write to I/O mtimecmp_lo register
   output   logic                         mtimecmp_hi_wr,                           // Output:  write to I/O mtimecmp_hi register
   output   logic               [RSZ-1:0] mmr_wr_data,                              // Output:  write data for above registers. see irq.sv

   // I/O Read Data
   input    logic             [2*RSZ-1:0] mtime,                                    // Input:   contents of mtime register
   input    logic             [2*RSZ-1:0] mtimecmp,                                 // Input:   contents of mtimecmp register

   // misprediction signals to other stages
   input    logic                         pipe_flush,                               // Input:   1 = Flush this segment of the pipeline

   `ifdef ext_F
   // interface to forwarding signals
   output   FWD_FPR                       fwd_mem_fpr,
   `endif

   // interface to forwarding signals
   output   FWD_GPR                       fwd_mem_gpr,

   // interface to forwarding signals
   output   FWD_CSR                       fwd_mem_csr,

   // System Memory or I/O interface signals
   L1DC_intf.master                       L1DC_bus,

   // External I/O accesses
   EIO_intf.master                        EIO_bus,                                  // External I/O bus

   // interface to Execute stage
   E2M_intf.slave                         E2M_bus,

   // interface to WB stage
   M2W_intf.master                        M2W_bus
);

   logic                   xfer_out, xfer_in;
   logic                   pipe_full;

   MEM_2_WB                mem_dout;

   // signals from EXE stage that are used in MEM stage
   logic       [PC_SZ-1:0] ls_addr;
   logic         [RSZ-1:0] st_data;
   logic             [2:0] size;
   logic                   zero_ext;                                                // 1 = LBU or LHU
   logic                   inv_flag;
   logic                   is_ld;
   logic                   is_st;

   // signals create here in MEM stage
   logic                   is_ls;                                                   // this is a Load or Store instruction
   logic                   MIO_req, MIO_ack, MIO_ack_fault;
   logic         [RSZ-1:0] MIO_ack_data;
   logic             [1:0] mode;

   // signals used in MEM stage
   assign ls_addr                      = E2M_bus.data.ls_addr;
   assign st_data                      = E2M_bus.data.st_data;
   assign size                         = E2M_bus.data.size;                         // default when not a load or store
   assign zero_ext                     = E2M_bus.data.zero_ext;                     // 1 = LBU or LHU
   assign inv_flag                     = E2M_bus.data.inv_flag;
   assign is_ld                        = E2M_bus.data.is_ld;
   assign is_st                        = E2M_bus.data.is_st;
   assign mode                         = E2M_bus.data.mode;
   `ifdef ext_N
   assign sw_irq                       = E2M_bus.data.sw_irq;                       // msip_reg[3]. see irq.sv
   `endif

   assign is_ls                        = (is_ld | is_st);

   // control logic for interface to Execution Stage
   // NOTE: No Load/Store QUE yet.. Just stalls until Load/Store completes - this will get updated in a future release
   assign E2M_bus.rdy                  = !reset_in & !cpu_halt & (!is_ls | MIO_ack) & (!pipe_full | xfer_out);

   assign xfer_in                      = E2M_bus.valid & E2M_bus.rdy;               // pop data from EXE_PIPE pipeline register..
   assign xfer_out                     = M2W_bus.valid & M2W_bus.rdy;               // pops data from MEM_PIPE registers to next stage

   `ifdef ext_F
   // Forwarding of FPR info
   assign fwd_mem_fpr.valid            = E2M_bus.valid & !reset_in;                 // Load data (MIO_ack_data) not valid until MIO_ack
   assign fwd_mem_fpr.Fd_wr            = E2M_bus.data.Fd_wr;
   assign fwd_mem_fpr.Fd_addr          = E2M_bus.data.Rd_addr;
   assign fwd_mem_fpr.Fd_data          = mem_dout.Rd_data;                          // return data from D$ if FP Load instruction, otherwise uses Rd_data from EXE stage
   `endif

   // Forwarding of GPR info
   assign fwd_mem_gpr.valid            = E2M_bus.valid & !reset_in;                 // Load data (MIO_ack_data) not valid until MIO_ack
   assign fwd_mem_gpr.Rd_wr            = E2M_bus.data.Rd_wr;
   assign fwd_mem_gpr.Rd_addr          = E2M_bus.data.Rd_addr;
   assign fwd_mem_gpr.Rd_data          = mem_dout.Rd_data;                          // return data from D$ if integer Load instruction, otherwise uses Rd_data from EXE stage

   // Forwarding of CSR info
   assign fwd_mem_csr.valid            = E2M_bus.valid & !reset_in;
   assign fwd_mem_csr.csr_wr           = E2M_bus.data.csr_wr;
   assign fwd_mem_csr.csr_addr         = E2M_bus.data.csr_addr;
   assign fwd_mem_csr.csr_data         = E2M_bus.data.csr_fwd_data;


   assign MIO_req                      = E2M_bus.valid & !reset_in & !cpu_halt & is_ls;   // Load/Store request to D$, or external I/O, only if a valid Load or Store instruction

   `ifdef SIM_DEBUG
   string   i_str;                                                                  // Debugging: disassemble instruction in this stage
   string   pc_str;

   disasm mem_dis (ASSEMBLY,E2M_bus.data.ipd,i_str,pc_str);                         // disassemble each instruction
   `endif

   // signals from EXE stage that will be needed in WB stage
   assign mem_dout.ipd                 = E2M_bus.data.ipd;
   assign mem_dout.ls_addr             = E2M_bus.data.ls_addr;
   assign mem_dout.inv_flag            = E2M_bus.data.inv_flag;
   assign mem_dout.instr_err           = E2M_bus.data.instr_err;                    // misaligned, illegal CSR access...
   assign mem_dout.ci                  = E2M_bus.data.ci;
   `ifndef ext_C
   assign mem_dout.br_pc               = E2M_bus.data.br_pc;
   `endif
   assign mem_dout.ig_type             = E2M_bus.data.ig_type;
   assign mem_dout.op_type             = E2M_bus.data.op_type;
   //     mem_dout.mio_ack_fault       is created in always block below
   assign mem_dout.mode                = E2M_bus.data.mode;
   assign mem_dout.trap_pc             = E2M_bus.data.trap_pc;                      // trap_pc, interrupt_flag, interrupt_cause not used in this stage,but needed in WB stage
   `ifdef ext_N
   assign mem_dout.sw_irq              = E2M_bus.data.sw_irq;                       // msip_reg[3]. see irq.sv
   assign mem_dout.interrupt_flag      = E2M_bus.data.interrupt_flag;
   assign mem_dout.interrupt_cause     = E2M_bus.data.interrupt_cause;
   `endif

   `ifdef ext_F
   assign mem_dout.Fd_wr               = E2M_bus.data.Fd_wr;
   `endif
   assign mem_dout.Rd_wr               = E2M_bus.data.Rd_wr;                        // Writeback stage needs to know whether to write to destination register Rd
   assign mem_dout.Rd_addr             = E2M_bus.data.Rd_addr;                      // Address of Rd register
   //     mem_dout.Rd_data             is created in always block below
   assign mem_dout.csr_wr              = E2M_bus.data.csr_wr;
   assign mem_dout.csr_addr            = E2M_bus.data.csr_addr;
   assign mem_dout.csr_wr_data         = E2M_bus.data.csr_wr_data;
   assign mem_dout.csr_fwd_data        = E2M_bus.data.csr_fwd_data;

   always_comb
   begin
      mem_dout.Rd_data                 = E2M_bus.data.Rd_data;
      mem_dout.mio_ack_fault           = FALSE;

      if (E2M_bus.valid)                                                            // should this instruction be processed by this stage?
      begin
         // signals to update Rd/Fd in WB stage
         `ifdef ext_F
         mem_dout.Fd_wr                = E2M_bus.data.Fd_wr;
         `endif

         case(E2M_bus.data.ig_type)                                                 // select which functional unit output data is the appropriate one to process
            LD_INSTR:
            begin
               mem_dout.mio_ack_fault  = MIO_ack_fault;                             // WB stage exception handling will need to know this.
               mem_dout.Rd_data        = MIO_ack_data;                              // value used to update Rd in WB stage
            end

            ST_INSTR:
            begin
               // Store exceptions arer done once Store finishes in this MEM stage
               mem_dout.mio_ack_fault  = MIO_ack_fault;                             // WB stage exception handling will need to know this.
            end

            `ifdef ext_F
            // pass results for Single Precision Floating Point Load/Store

            `endif
         endcase
      end // E2M_bus.valid
   end // always_comb


   ////////////////////////////////////////////
   // Load/Store Memory and I/O access logic //
   ////////////////////////////////////////////
   logic                   is_phy_mem, is_int_io, is_ext_io;

//   assign is_io_access = (is_ld | is_st);

   // Determine what type of memory this Load/Store is accessing - these are mutually exclusive addresses
   assign is_phy_mem                   = (ls_addr >= Phys_Addr_Lo  ) & (ls_addr <= Phys_Addr_Hi  ) & MIO_req;   // Physical System Memory
   assign is_int_io                    = (ls_addr >= Int_IO_Addr_Lo) & (ls_addr <= Int_IO_Addr_Hi) & MIO_req;   // internal I/O
   assign is_ext_io                    = (ls_addr >= Ext_IO_Addr_Lo) & (ls_addr <= Ext_IO_Addr_Hi) & MIO_req;   // external I/O
   assign L1DC_bus.req_data.rd         = is_ld;
   assign L1DC_bus.req_data.wr         = is_st;             // is_st
   assign L1DC_bus.req_data.rw_addr    = ls_addr;           // ls_addr - Load/Store Address
   assign L1DC_bus.req_data.wr_data    = st_data;           // st_data - Store data
   assign L1DC_bus.req_data.size       = size;              // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   assign L1DC_bus.req_data.zero_ext   = zero_ext;          // 1 = Zero Extend
   assign L1DC_bus.req_data.inv_flag   = inv_flag;          // invalidate flag
   assign L1DC_bus.req                 = is_phy_mem;

   assign mtime_lo_wr      = is_int_io & (mode == M_MODE) & (ls_addr ==  MTIME_Base_Addr)       & is_st;
   assign mtime_hi_wr      = is_int_io & (mode == M_MODE) & (ls_addr == (MTIME_Base_Addr+4))    & is_st;
   assign mtimecmp_lo_wr   = is_int_io & (mode == M_MODE) & (ls_addr == MTIMECMP_Base_Addr)     & is_st;
   assign mtimecmp_hi_wr   = is_int_io & (mode == M_MODE) & (ls_addr == (MTIMECMP_Base_Addr+4)) & is_st;
   assign msip_wr          = is_int_io & (mode == M_MODE) & (ls_addr == MSIP_Base_Addr)         & is_st;

   assign mmr_wr_data      = st_data;

   always_comb
   begin
      if (is_ext_io)
      begin
         EIO_bus.req       = TRUE;
         EIO_bus.addr      = ls_addr;
         EIO_bus.rd        = is_ld;
         EIO_bus.wr        = is_st;
         EIO_bus.wr_data   = st_data;
      end
      else
      begin
         EIO_bus.req       = FALSE;
         EIO_bus.addr      = '0;
         EIO_bus.rd        = FALSE;
         EIO_bus.wr        = FALSE;
         EIO_bus.wr_data   = '0;
      end
   end

   `ifdef SIM_DEBUG
   assign sim_stop             = (ls_addr == Sim_Stop_Addr) & MIO_req;
   `endif

   always_comb
   begin
      //------------------------ Memory and I/O access default signals -----------------------------
      MIO_ack              = FALSE;
      MIO_ack_data         = '0;
      MIO_ack_fault        = FALSE;

      // ************************** Physical System Memory (i.e. L1 Data Cache) accesses **************************
      if (is_phy_mem)
      begin
         MIO_ack                 = L1DC_bus.ack;                           // we don't know how long memory accesses take, so we let memory logic tell us
         MIO_ack_data            = L1DC_bus.ack_data;
         MIO_ack_fault           = L1DC_bus.ack_fault;
      end

      // ************************** Special: Simulation Debugging **************************
      `ifdef SIM_DEBUG
      else if ((ls_addr == Sim_Stop_Addr) & MIO_req)
      begin
         MIO_ack                 = TRUE;                                   // this I/O access just takes 1 clock cycle
         MIO_ack_fault           = FALSE;
         if (is_ld)
            MIO_ack_data         = 'habadcafe;
      end
      `endif
      // ************************** Internal I/O accesses **************************
      else if (is_int_io)                                                  // Internal I/O address space
      begin
         if (mode == M_MODE)                                               // These CPU internal I/O accesses can only be done in machine mode.
         begin
            if (ls_addr == MTIME_Base_Addr)
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = FALSE;
               if (is_ld)
                  MIO_ack_data   = mtime[RSZ-1:0];                         // Machine Mode Time Register
            end
            else if (ls_addr == (MTIME_Base_Addr+4))
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = FALSE;
               if (is_ld)
                  MIO_ack_data   = mtime[2*RSZ-1:RSZ];
            end
            else if (ls_addr == MTIMECMP_Base_Addr)
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = FALSE;
               if (is_ld)
                  MIO_ack_data   = mtimecmp[RSZ-1:0];                      // Machine Mode Time Compare Register
            end
            else if (ls_addr == (MTIMECMP_Base_Addr+4))
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = FALSE;
               if (is_ld)
                  MIO_ack_data   = mtimecmp[2*RSZ-1:RSZ];
            end
            `ifdef ext_N
            else if (ls_addr == MSIP_Base_Addr)
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = FALSE;
               if (is_ld)
                  MIO_ack_data   = {28'b0,sw_irq,3'b0};                    // Software Interrupt Pending Register
            end
            `endif
            else // unknown internal I/O
            begin
               MIO_ack           = TRUE;                                   // read or write
               MIO_ack_fault     = TRUE;                                   // no matching Internal I/O address
            end
         end
         else // unknown I/O
         begin
            MIO_ack              = TRUE;                                   // read or write
            MIO_ack_fault        = TRUE;
         end
      end
      // ************************** External I/O accesses **************************
      else if (is_ext_io)
      begin
         MIO_ack                 = EIO_bus.ack;                            // these I/O accesses take N clock cycles determined by external device logic
         MIO_ack_fault           = EIO_bus.ack_fault;
         if (is_ld & !EIO_bus.ack_fault)
            MIO_ack_data         = EIO_bus.ack_data;
      end
      else
      begin
         MIO_ack                 = MIO_req;                                // immedaitely abort Load/Store access cycle
         MIO_ack_fault           = MIO_req;                                // fault if request decodes to this block
      end
   end // always_comb

   // Set of Flip Flops (for pipelining) with control logic ('full' signal) sitting between Memory stage and the WB stage
   pipe #( .T(type(MEM_2_WB)) ) MEM_PIPE
   (
      .clk_in(clk_in),    .reset_in(reset_in | pipe_flush),
      .write_in(xfer_in), .data_in(mem_dout), .full_out(pipe_full),
      .read_in(xfer_out), .data_out(M2W_bus.data)
   );

   assign M2W_bus.valid = pipe_full;

endmodule
