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
// File          :  ls_queue.sv
// Description   :  This module contains the Load/Store queue and control logic as well as interfaces
//               :  to MEM and WB stages
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module ls_queue
(
   input    logic                clk_in,
   input    logic                reset_in,

   // Interface to MEM stage (has Load/Store information that needs to be put into queue)
   MEM2LSQ.slave                 MEM_2_LSQ_bus,

   // Interface to WB stage (commit stage)
   WB2LSQ.slave                  WB_2_LSQ_bus,


   // pipeline flush signal

   // System Memory or I/O interface signals
   L1DC.master                   DC_bus
);

   
   // Queue and pointers
   LSQ_Data        [LSQ_NUM-1:0] lsq;                                // queue has LSQ_NUM entries (LSQ_NUM MUST be a power of 2 number for logic to work)
   logic           [LSQ_SZ-1:0]  newest, oldest;                     // newest points to next entry to use, oldest is the oldest entry

   LSQ_Data                      q;
   logic                         q_flag;

   logic                         xfer_in, is_ld, is_st, is_ls;
   logic                         is_full, is_empty, is_completed;

   logic              [LSQ_SZ:0] q_cnt, q_ptr, nxt_q_ptr;
   
   logic                         c_set_flag;
   logic              [LSQ_SZ:0] c_set_ndx;

   logic                         all_prior_stores_completed;
   logic                         matching_store;
   logic                         send_2_dc;

   logic                         ld_data_flag;
   logic               [RSZ-1:0] ld_data;

   enum {IDLE, WAIT_ACK } state, nxt_state;

   // Initialization and update of queue array and pointers
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         lsq <= '{default: '0};

      if (q_flag)
         lsq[newest] <= q;                                           // address, size, zero_ext

      if (c_set_flag)
         lsq[c_set_ndx].completed <= TRUE;

      if (ld_load_flag)
         lsq[newest].data <= ld_data;

      if (reset_in)
         newest <= 0;
      else if (inc_newest)
         newest <= newest + 1;

      if (reset_in)
         oldest <= 0;
      else if (inc_oldest)
         oldest <= oldest + 1;

      if (reset_in)
         q_ptr <= 0;
      else
         q_ptr <= nxt_q_ptr;

      if (reset_in)
         q_cnt <= 0;
      else if (inc_newest & !inc_oldest)
         q_cnt <= q_cnt + 1;

      if (reset_in)
         state <= IDLE;
      else
         state <= nxt_state + 1;

   end

   assign xfer_in          = MEM_2_LSQ_bus.valid & MEM_2_LSQ_bus.rdy;
   assign is_ld            = MEM_2_LSQ_bus.is_ld;
   assign is_st            = MEM_2_LSQ_bus.is_st;
   assign is_ls            = is_ld | is_st;
   assign is_full          = (newest == oldest) & (q_cnt != 0);
   assign is_empty         = (newest == oldest) & (q_cnt == 0);
   assign is_completed     = lsq[oldest].completed;

   // A load should not execute until all prior stores have completed
   assign send_2_dc        = is_st | (is_ld & all_prior_stores_completed)

   // logic to save Load/Store instructions in Queue
   always_comb
   begin
      // default values for all variables being assigned values in this block
      q                    = '{default: '0};
      q_flag               = FALSE;
      inc_newest           = FALSE;
      inc_oldest           = FALSE;
      MEM_2_LSQ_bus.rdy    = !is_full | lsq[newest].completed;
      
      if (xfer_in & is_ls)    // see if this is a load/store instruction to save in the queue
      begin
         q.addr            = MEM_2_LSQ_bus.data.ls_addr;
         q.data            = MEM_2_LSQ_bus.data.st_data;
         q.size            = MEM_2_LSQ_bus.data.size;
         q.zero_ext        = MEM_2_LSQ_bus.data.zero_ext;
         q.is_ld           = MEM_2_LSQ_bus.data.is_ld;
         q.inv_flag        = MEM_2_LSQ_bus.data.inv_flag;
         q.completed       = FALSE;
         q.fault           = FALSE;
         q.mis             = MEM_2_LSQ_bus.data.mis;

         q_flag            = TRUE;                                   // save the info in the LS Queue

         // NOTE: when is_full == 1, newest and oldest are the same value and both pointers will increment and the current entry is overwritten
         inc_newest        = !is_full | is_completed;                // increment newest to next Queue location
         inc_oldest        = is_full & is_completed;                 // if the Queue is full then also increment the oldest if the current entry is completed
      end
   end

   // matching_store: address of a Store matches those of a Load. Also size of Store must be at least as big as that of Load.
   integer i;
   logic done;
   logic    [LSQ_SZ-1:0] mptr;
   always_comb
   begin
      matching_store = FALSE;
      done           = FALSE;
      mptr           = newest;    // start at newest entry

      for (i = 0; i < LSQ_NUM; i++)
      begin
         if (!done & !lsq[mptr].is_ld & (lsq[mptr].addr == lsq[newest].addr) & (lsq[mptr].size >= lsq[newest].size)
         begin
            matching_store = TRUE;
            done = TRUE;
         end
         if (i == q_cnt)         // can't look at unused entries
            done = TRUE;
         mptr = mptr - 1'd1;
      end
   end

   // Logic to send L/S from Queue to L1 D$
   always_comb
   begin
      // default values for all variables being assigned values in this block
      nxt_state            = state;
      c_set_flag           = FALSE;
      c_set_ndx            = 0;
      ld_data_flag         = FALSE;
      ld_data              = '0;
      save_fault           = FALSE[
      DC_bus.req           = FALSE;
      DC_bus.req_data      = '0;
      nxt_q_ptr            = q_ptr;

      case(state)
         IDLE:
         begin
            if (!empty & !lsq[nxt_q_ptr].completed)                     // This L/S has not been processed
            begin
               if (lsq[nxt_q_ptr].is_ld & matching_store)               // Load with Matching previous Store? ...then do Store to Load forwarding
               begin
                  case (lsq[nxt_q_ptr].size)                            // get data from Store and place in Load entry based on size and zero_ext
                     1:
                     begin
                        sb = lsq[matching_ndx].data[7];                // sign bit
                        if lsq[nxt_q_ptr].zero_ext)
                           ld_data           = {24'd0,lsq[matching_ndx].data[7:0]};    // zero extended
                        else
                           ld_data           = {24{sb}},lsq[matching_ndx].data[7:0];   // sign extended
                     end
                     2:
                     begin
                        sb = lsq[matching_ndx].data[15];                // sign bit
                        if lsq[nxt_q_ptr].zero_ext)
                           ld_data           = {16'd0,lsq[matching_ndx].data[15:0]};   // zero extended
                        else
                           ld_data           = {16{sb}},lsq[matching_ndx].data[15:0];  // sign extended
                     end
                     4:
                        ld_data              = lsq[matching_ndx].data;  // save 32-bit matching Store data in current (nxt_q_ptr) entry
                  endcase
                  
                  ld_data_flag               = TRUE;                    // save ld_data into lsq[newest]
                  c_set_flag                 = TRUE;                    // mark Load as completed
                  c_set_ndx                  = nxt_q_ptr;
                  nxt_q_ptr                  = nxt_q_ptr + 1'd1;        // process next Load/Store in queue
               end
               else if (send_2_dc)                                      // Should this be sent to the L1 D$ ?
               begin
                  // send request and info to L1 D$
                  DC_bus.req                 = TRUE;

                  DC_bus.req_data.rd         = lsq[nxt_q_ptr].is_ld;
                  DC_bus.req_data.wr         = lsq[nxt_q_ptr].!is_ld;
                  DC_bus.req_data.rw_addr    = lsq[nxt_q_ptr].addr;
                  DC_bus.req_data.wr_data    = lsq[nxt_q_ptr].data;
                  DC_bus.req_data.size       = lsq[nxt_q_ptr].size;
                  DC_bus.req_data.zero_ext   = lsq[nxt_q_ptr].zero_ext; // 1 = LBU or LHU
                  DC_bus.req_data.inv_flag   = lsq[nxt_q_ptr].inv_flag;

                  nxt_state   = WAIT_ACK;
               end
            end
         end

         WAIT_ACK:
         begin
            // continue sending request and info to L1 D$ until cycle completes
            DC_bus.req                    = TRUE;

            DC_bus.req_data.rd            = lsq[nxt_q_ptr].is_ld;
            DC_bus.req_data.wr            = lsq[nxt_q_ptr].!is_ld;
            DC_bus.req_data.rw_addr       = lsq[nxt_q_ptr].addr;
            DC_bus.req_data.wr_data       = lsq[nxt_q_ptr].data;
            DC_bus.req_data.size          = lsq[nxt_q_ptr].size;
            DC_bus.req_data.zero_ext      = lsq[nxt_q_ptr].zero_ext;    // 1 = LBU or LHU
            DC_bus.req_data.inv_flag      = lsq[nxt_q_ptr].inv_flag;

            // after ack, wait for data to come back
            if (DC_bus.ack)
            begin
               ld_data_flag               = lsq[nxt_q_ptr].is_ld;       // save the ld_data for this Load
               case (lsq[nxt_q_ptr].size)                               // get data from Store and place in Load entry based on size and zero_ext
                  1:
                  begin
                     sb = lsq[matching_ndx].data[7];                    // sign bit
                     if lsq[nxt_q_ptr].zero_ext)
                        ld_data           = {24'd0,lsq[matching_ndx].data[7:0]};    // zero extended
                     else
                        ld_data           = {24{sb}},lsq[matching_ndx].data[7:0];   // sign extended
                  end
                  2:
                  begin
                     sb = lsq[matching_ndx].data[15];                   // sign bit
                     if lsq[nxt_q_ptr].zero_ext)
                        ld_data           = {16'd0,lsq[matching_ndx].data[15:0]};   // zero extended
                     else
                        ld_data           = {16{sb}},lsq[matching_ndx].data[15:0];  // sign extended
                  end
                  4:
                     ld_data              = lsq[matching_ndx].data;     // save 32-bit matching Store data in current (nxt_q_ptr) entry
               endcase

               c_set_flag                 = TRUE;                       // mark Load as completed
               c_set_ndx                  = nxt_q_ptr;

               nxt_q_ptr                  = nxt_q_ptr + 1'd1;

               save_fault                 = TRUE;                       // save the L1 D$ fault flag
               nxt_state                  = IDLE;
            end
         end
      endcase
   end
endmodule