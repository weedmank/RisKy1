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
// File          :  mem_io.sv - determine which Load/Stores are to System Memory and which are to I/O
// Description   :  Instruction Fetch Unit - get instructions from Instruction Cache which returns
//               :  a whole cache line of data for a given address
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module mem_io
(
   input    logic                [1:0] mode,

   // I/O transfers between MEM Stage and MEM_IO
   L1DC_intf.slave                     MIO_bus,

   // Interface between MEM_IO and L1 D$
   L1DC_intf.master                    L1DC_bus,

   // I/O Write signals to specific RISC-V I/O registers
   `ifdef ext_N
   output   logic                      msip_wr,             // Output:  write to I/O msip register
   `endif
   output   logic                      mtime_lo_wr,         // Output:  write to I/O mtime_lo register
   output   logic                      mtime_hi_wr,         // Output:  write to I/O mtime_hi register
   output   logic                      mtimecmp_lo_wr,      // Output:  write to I/O mtimecmp_lo register
   output   logic                      mtimecmp_hi_wr,      // Output:  write to I/O mtimecmp_hi register
   output   logic            [RSZ-1:0] mmr_wr_data,         // Output:  write data for above registers. see irq.sv

   // I/O Read Data
   input    logic          [2*RSZ-1:0] mtime,               // Input:   contents of mtime register
   input    logic          [2*RSZ-1:0] mtimecmp,            // Input:   contents of mtimecmp register
   input    logic            [RSZ-1:0] msip_reg,            // Input:   contents of msip_reg register

   `ifdef SIM_DEBUG
   output   logic                      sim_stop,
   `endif

   // External I/O accesses
   output   logic                      io_req,              // Output:  I/O Request
   output   logic          [PC_SZ-1:0] io_addr,             // Output:  I/O Address
   output   logic                      io_rd,               // Output:  I/O Read signal
   output   logic                      io_wr,               // Output:  I/O Write signal
   output   logic            [RSZ-1:0] io_wr_data,          // Output:  I/O Write data that is written when io_wr == 1

   input    logic            [RSZ-1:0] io_rd_data,          // Input:   I/O Read data
   input    logic                      io_ack,              // Input:   I/O Acknowledge
   input    logic                      io_ack_fault         // Input:   I/O Access Fault occurred
);

   logic is_phy_mem, is_int_io, is_ext_io, access_fault;

   assign is_io_access = (MIO_bus.req_data.rd | MIO_bus.req_data.wr);

   // Determine what type of memory this Load/Store is accessing - these are mutually exclusive addresses
   assign is_phy_mem       = (MIO_bus.req_data.rw_addr >= Phys_Addr_Lo  ) & (MIO_bus.req_data.rw_addr <= Phys_Addr_Hi  ) & MIO_bus.req;   // Physical System Memory
   assign is_int_io        = (MIO_bus.req_data.rw_addr >= Int_IO_Addr_Lo) & (MIO_bus.req_data.rw_addr <= Int_IO_Addr_Hi) & MIO_bus.req;   // internal I/O
   assign is_ext_io        = (MIO_bus.req_data.rw_addr >= Ext_IO_Addr_Lo) & (MIO_bus.req_data.rw_addr <= Ext_IO_Addr_Hi) & MIO_bus.req;   // external I/O

   assign L1DC_bus.req_data  = is_phy_mem ? MIO_bus.req_data : '0;
   assign L1DC_bus.req       = is_phy_mem ? TRUE             : FALSE;

   always_comb
   begin
      access_fault         = is_io_access & MIO_bus.req;                                  // assume access is to an invalid location if reading or writing to Memory or I/O space

      MIO_bus.ack          = FALSE;
      MIO_bus.ack_data     = '0;
      MIO_bus.ack_fault    = FALSE;

      io_req               = FALSE;
      io_addr              = '0;
      io_rd                = FALSE;
      io_wr                = FALSE;
      io_wr_data           = '0;

      `ifdef SIM_DEBUG
      sim_stop             = FALSE;
      `endif

      // write signals for local in core registers
      mtime_lo_wr          = FALSE;
      mtime_hi_wr          = FALSE;
      mtimecmp_lo_wr       = FALSE;
      mtimecmp_hi_wr       = FALSE;
      `ifdef ext_N
      msip_wr              = FALSE;
      `endif
      mmr_wr_data          = '0;

      // ************************** Physical System Memory (i.e. L1 Data Cache) accesses **************************
      if (is_phy_mem)
      begin
         MIO_bus.ack                = L1DC_bus.ack;                                    // we don't know how long memory accesses take, so we let memory logic tell us
         MIO_bus.ack_data           = L1DC_bus.ack_data;
         access_fault               = L1DC_bus.ack_fault;
      end

      // ************************** Special: Simulation Debugging **************************
      `ifdef SIM_DEBUG
      else if ((MIO_bus.req_data.rw_addr == Sim_Stop_Addr) & MIO_bus.req)
      begin
         MIO_bus.ack                = TRUE;                                            // this I/O access just takes 1 clock cycle
         if (MIO_bus.req_data.rd)
            MIO_bus.ack_data        = 'habadcafe;

         sim_stop                   = TRUE;
         access_fault               = FALSE;
      end
      `endif

      // ************************** Internal I/O accesses **************************
      if (is_int_io && (mode == 3))                                                    // These CPU internal I/O accesses can only be done in machine mode.
      begin
         if (MIO_bus.req_data.rw_addr == MTIME_Base_Addr)
         begin
            MIO_bus.ack             = TRUE;                                            // read or write
            if (MIO_bus.req_data.rd)
               MIO_bus.ack_data     = mtime[RSZ-1:0];                                  // Machine Mode Time Register

            mtime_lo_wr             = MIO_bus.req_data.wr;
            mmr_wr_data             = MIO_bus.req_data.wr_data;

            access_fault            = FALSE;
         end
         else if (MIO_bus.req_data.rw_addr == (MTIME_Base_Addr+4))
         begin
            MIO_bus.ack             = TRUE;                                            // read or write
            if (MIO_bus.req_data.rd)
               MIO_bus.ack_data     = mtime[2*RSZ-1:RSZ];

            mtime_hi_wr             = MIO_bus.req_data.wr;
            mmr_wr_data             = MIO_bus.req_data.wr_data;

            access_fault            = FALSE;
         end
         else if (MIO_bus.req_data.rw_addr == MTIMECMP_Base_Addr)
         begin
            MIO_bus.ack             = TRUE;                                            // read or write
            if (MIO_bus.req_data.rd)
               MIO_bus.ack_data     = mtimecmp[RSZ-1:0];                               // Machine Mode Time Compare Register

            mtimecmp_lo_wr          = MIO_bus.req_data.wr;
            mmr_wr_data             = MIO_bus.req_data.wr_data;

            access_fault            = FALSE;
         end
         else if (MIO_bus.req_data.rw_addr == (MTIMECMP_Base_Addr+4))
         begin
            MIO_bus.ack             = TRUE;                                            // read or write
            if (MIO_bus.req_data.rd)
               MIO_bus.ack_data     = mtimecmp[2*RSZ-1:RSZ];

            mtimecmp_hi_wr          = MIO_bus.req_data.wr;
            mmr_wr_data             = MIO_bus.req_data.wr_data;

            access_fault            = FALSE;
         end
         else if (MIO_bus.req_data.rw_addr == MSIP_Base_Addr)
         begin
            MIO_bus.ack             = TRUE;                                            // read or write
            if (MIO_bus.req_data.rd)
               MIO_bus.ack_data     = msip_reg;                                        // Software Interrupt Pending Register

            `ifdef ext_N
            msip_wr                 = MIO_bus.req_data.wr;
            mmr_wr_data             = MIO_bus.req_data.wr_data;
            `endif
            access_fault            = FALSE;
         end
      end

      // ************************** External I/O accesses **************************
      if (is_ext_io)
      begin
         MIO_bus.ack                = io_ack;                                          // these I/O accesses take N clock cycles determined by external device logic
         if (MIO_bus.req_data.rd & !io_ack_fault)
            MIO_bus.ack_data        = io_rd_data;

         io_req                     = TRUE;
         io_addr                    = MIO_bus.req_data.rw_addr;
         io_rd                      = MIO_bus.req_data.rd;
         io_wr                      = MIO_bus.req_data.wr;
         io_wr_data                 = MIO_bus.req_data.wr_data;

         access_fault               = io_ack_fault;                                    // good pin to use an external pullup resistor on...
      end

      // CPU should generate an exception in the execute stage if load/Store address is not in any of the Physical memory space, Internal I/O memory space, or External I/O memory space ranges
      if (access_fault)
      begin
         MIO_bus.ack                = TRUE;                                            // immedaitely abort Load/Store access cycle
         MIO_bus.ack_fault          = TRUE;                                            // these I/O accesses take N clock cycles determined by external device logic
      end
   end
endmodule