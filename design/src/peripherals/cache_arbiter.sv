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
// File          :  cache_arbiter.sv
// Description   :  Model of a simple arbiter with memory
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

//-------------------------------------------------------------------------------------------------------
// Simple Behavioral Model of an Arbiter that Interfaces to L1 Instruction/Data Caches and System Memory
//-------------------------------------------------------------------------------------------------------
//
//                             +------------------------------------------+
//                             |                                          |
//  DC_arb_bus.req_data  ----->|                                          |<----- IC_arb_bus.req_addr
//                             |  Request from              Request from  |
//  DC_arb_bus.req_valid ----->|     D-cache                   I-cache    |<----- IC_arb_bus.req_valid
//                             |                                          |
//  DC_arb_bus.req_rdy   ------|                                          |-----> IC_arb_bus.req_rdy
//                             |                                          |
//                             |                                          |
//                             |                                          |
//  DC_arb_bus.ack_data  <-----|                                          |-----> IC_arb_bus.ack_data
//         (32 bytes)          |                                          |             (32 bytes)
//  DC_arb_bus.ack_valid <-----|  Response to               Response to   |-----> IC_arb_bus.ack_valid
//                             |    D-cache                   I-cache     |
//  DC_arb_bus.ack_rdy   ----->|                                          |<----- IC_arb_bus.ack_rdy
//                             |                                          |
//                             |                                          |
//                             |                                          |
//                clk_in ----->|                                          |
//                             |                                          |<---> System Memory interface
//              reset_in ----->|                                          |
//                             |                                          |
//                             +------------------------------------------+
//                                           MEMORY ARBITER
//

module cache_arbiter
(
   input    logic                   clk_in, reset_in,

   L1IC_ARB.slave                   IC_arb_bus,
   L1DC_ARB.slave                   DC_arb_bus,

   SysMem.master                    sysmem_bus
);

   enum logic [1:0] {IDLE, SM_REQ, SM_ACK, IC_DC_ACK } arb_state, next_arb_state;

   logic    [CL_LEN*8-1:0] wr_data, rd_data;                                     // enough room for 1 cache line of data from sys_mem[]
   logic       [PC_SZ-1:0] rw_addr;                                              // byte address to access in System Memory
   logic                   rw;
   logic                   save_ic_info, save_dc_info, save_rd_data;
   logic                   is_ic_cycle;

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         arb_state = IDLE;
      else
         arb_state = next_arb_state;

      if (reset_in)
      begin
         rw_addr      <= '0;
         rw          <= 1'b0;
         wr_data     <= '0;
         is_ic_cycle <= FALSE;
      end
      else if (save_ic_info)
      begin
         rw_addr     <= IC_arb_bus.req_addr;
         rw          <= 1'b1; // Read from System Memory
         wr_data     <= '0;
         is_ic_cycle <= TRUE;
      end
      else if (save_dc_info)
      begin
         rw_addr     <= DC_arb_bus.req_data.rw_addr;                             // assume SYSTEM MEMORY starts at Phys_Addr_Lo
         rw          <= DC_arb_bus.req_data.rw;
         wr_data     <= DC_arb_bus.req_data.wr_data;
         is_ic_cycle <= FALSE;
      end

      if (save_rd_data)
         rd_data     <= sysmem_bus.ack_rd_data;
   end

   always_comb
   begin
      next_arb_state          = arb_state;

      save_ic_info            = FALSE;
      save_dc_info            = FALSE;
      save_rd_data            = FALSE;

      sysmem_bus.req_valid    = FALSE;
      sysmem_bus.req_rw       = 1'b0;                                            // Read = 1, Write = 0
      sysmem_bus.req_addr     = '0;                                              // Request address to arbiter
      sysmem_bus.req_wr_data  = '0;                                              // Request write data to arbiter when rw==0

      sysmem_bus.ack_rdy      = FALSE;

      IC_arb_bus.req_rdy      = FALSE;
      IC_arb_bus.ack_valid    = FALSE;

      DC_arb_bus.req_rdy      = FALSE;
      DC_arb_bus.ack_valid    = FALSE;
      DC_arb_bus.ack_data     = '0;

      case(arb_state)
         IDLE:
         begin
            if (IC_arb_bus.req_valid)
            begin
               next_arb_state          = SM_REQ;
               IC_arb_bus.req_rdy      = TRUE;
               save_ic_info            = TRUE;
            end
            else if (DC_arb_bus.req_valid)
            begin
               next_arb_state          = SM_REQ;
               DC_arb_bus.req_rdy      = TRUE;
               save_dc_info            = TRUE;
            end
         end

         SM_REQ:
         begin
            sysmem_bus.req_valid       = TRUE;                                   // start sending a Read Requesting to SysMem
            sysmem_bus.req_rw          = rw;                                     // Read = 1, Write = 0
            sysmem_bus.req_addr        = rw_addr;                                // Request address to arbiter
            sysmem_bus.req_wr_data     = wr_data;                                // Request write data to arbiter when rw==0
            if (sysmem_bus.req_rdy)
               next_arb_state          = SM_ACK;
         end

         SM_ACK:
         begin
            sysmem_bus.ack_rdy         = TRUE;
            if (sysmem_bus.ack_valid)
            begin
               next_arb_state          = IC_DC_ACK;
               if (rw)
                  save_rd_data         = TRUE;
            end
         end

         IC_DC_ACK:
         begin
            if (is_ic_cycle)
            begin
               IC_arb_bus.ack_valid    = TRUE;
               if (IC_arb_bus.ack_rdy)
               begin
                  IC_arb_bus.ack_data  = rd_data;
                  next_arb_state       = IDLE;
               end
            end
            else   // D$ Acknowledge cycle
            begin
               DC_arb_bus.ack_valid    = TRUE;
               if (DC_arb_bus.ack_rdy)
               begin
                  DC_arb_bus.ack_data  = rd_data;
                  next_arb_state       = IDLE;
               end
            end
         end
      endcase
   end

endmodule
