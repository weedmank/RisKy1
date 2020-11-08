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
// File          :  L1_icache.sv - Level 1 Data Cache, 8-way set associative with
// Description   :  32 byte cache line, 32Kbyte cache. LRU replacement policy
//               :  This version does not instantiate RAM, therefore if synthesized it produces lots of flip flops!
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


// Example: NUM_WAYS = 4
//                       +------------------------+
//                     +------------------------+ |
//                   +------------------------+ |-+
//                 +------------------------+ |-+
//                 |                        |-+
//                 +------------------------+   Each cache line is CL_LEN bytes
//                  .
//                  .
//   multiple SETS  .
//                  .
//                  .    +------------------------+
//                  .  +------------------------+ |
//                  .+------------------------+ |-+
//                 +------------------------+ |-+
//                 |                        |-+
//                 +------------------------+
//
//                        +------------------------------------------+
//                        |                                          |
// ic_addr_in       ----->+                                          +-----> arb_req_addr_out
//                        |                          Request to Arb  |
// ic_req_in        ----->+                                          +-----> arb_req_valid_out
//                        | Req/Ack with CPU                         |
// ic_ack_out       <-----+                                          +<----- arb_req_rdy_in
//                        |                                          |
// ic_rd_data_out   <-----+                                          |
//                        |                                          +<----- arb_ack_data_in
//                        |                    Acknowledge from Arb  |
//                        |                                          +<----- arb_ack_valid_in
//                        |                                          |
//                        |                                          +-----> arb_ack_rdy_out
//                        |                                          |
//                        |                                          |
//                        |                                          +<----- inv_req_in
//                        |                         Invalidate       |
//                        |                         Cache Line       +<----- inv_addr_in
//                        |                        from D-cache      |
//                        |                                          +-----> inv_ack_out
//                        |                                          |
//                        +------------------------------------------+

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module L1_icache
   #(
      // parameters that can be changed/overridden by the user
      parameter   IC_Size     = 32*1024,                    // 32KB Data Cache - must be a power of 2 value
      parameter   NUM_WAYS    = 8,                          // Number of WAYS
      parameter   A_SZ        = 32,                         // 32 bit Address
      parameter   CL_LEN      = 32                          // 32 bytes
   )
(
   input    logic                   clk_in,
   input    logic                   reset_in,

   // Invalidate Cache Line request
   input    logic                   inv_req_in,             // Write to L1 D$ caused an invalidate requesdt to L1 I$
   input    logic        [A_SZ-1:0] inv_addr_in,            // which cache line address to invalidate
   output   logic                   inv_ack_out,            // L1 I$ acknowledge if invalidate

   // L1 Instruction Cache Requests a cache line read from the Arbiter/System Memory
   output   logic [PC_SZ-CL_SZ-1:0] arb_req_addr_out,       // Instruction Cache Line Address to Arbiter/System Memory
   output   logic                   arb_req_valid_out,      // valid output to arbiter
   input    logic                   arb_req_rdy_in,         // ready input from arbiter

   // Arbiter/System Memory Acknowledges and passes a cache line of data to L1 Instruction Cache - Note: Only use these signals when Reading
   input    logic    [CL_LEN*8-1:0] arb_ack_data_in,        // data input from arbiter. will contain a cache line of data if reading, N/A if writing.
   input    logic                   arb_ack_valid_in,       // valid input from arbiter
   output   logic                   arb_ack_rdy_out,        // ready output to arbiter

   // Interface signals to CPU
   input    logic        [A_SZ-1:0] ic_addr_in,             // Address from CPU specifying which cache line to get
   input    logic                   ic_req_in,
   output   logic                   ic_ack_out,
   output   L1_ICache_Data          ic_rd_data_out,         // CL_LEN bytes of data (cache line) from cache to Fetch stage
   input    logic                   ic_flush
);
   // parameters that CANNOT be changed by the user
   localparam  NUM_CL   = IC_Size/CL_LEN;                   // number of cache lines = total Instruction Cache size / length of cache line
   localparam  NUM_SETS = NUM_CL/NUM_WAYS;                  // i.e. 1024 cache lines /4 ways = 256 sets

   //             +----------------+----------+---------+
   //             |      T_SZ      |  SET_SZ  |  CL_SZ  |
   //             +----------------+----------+---------+
   // example:            20            7          5
//   localparam  CL_SZ    = bit_size(CL_LEN-1); see cpu_params.h
   localparam  SET_SZ   = bit_size(NUM_SETS-1);             // i.e. if NUM_SETS = 128 then SET_SZ = 7 bits
   localparam  T_SZ     = A_SZ - SET_SZ - CL_SZ;            // Tag size = A_SZ - SET_SZ - CL_SZ

   localparam  WAY_SZ   = bit_size(NUM_WAYS-1);             // i.e. if NUM_WAYS = 8 then WAY_SZ = 3 bits

   // signals and memory for the cache
   logic   [NUM_SETS-1:0] [NUM_WAYS-1:0] [CL_LEN*8-1:0] cache_mem;

   logic   [NUM_SETS-1:0] [NUM_WAYS-1:0]                cache_valid;             // valid data in cache line
   logic   [NUM_SETS-1:0] [NUM_WAYS-1:0]     [T_SZ-1:0] cache_tag;

   logic   [NUM_SETS-1:0] [NUM_WAYS-1:0]   [WAY_SZ-1:0] lru;                     // Example: NUM_WAYS = 8, WAY_SZ = 3 bits
   logic                  [NUM_WAYS-1:0]   [WAY_SZ-1:0] next_lru;

   logic                                 [CL_LEN*8-1:0] current_cache_line;
   logic        [T_SZ-1:0] tag;
   logic      [SET_SZ-1:0] set;
   logic      [WAY_SZ-1:0] way;

   logic                   hit;           // hit

   logic                   ecf;           // empty cache found

   logic                   icf_ff, clr_all_valid;

   logic      [WAY_SZ-1:0] hit_num, ecf_num, lru_num;

   logic                   save_arb_cl;

   logic                   arb_ack_xfer;
   logic                   arb_req_xfer;

   enum logic [2:0] {IC_IDLE, REQ_CL_FROM_ARB, WR_ARB_CL_2_CL, CL_2_CPU, IC_INV_CL} Next_IC_State, IC_State;

   assign arb_ack_xfer  = arb_ack_valid_in  & arb_ack_rdy_out;
   assign arb_req_xfer  = arb_req_valid_out & arb_req_rdy_in;

   assign set           = (IC_State == IC_INV_CL) ? inv_addr_in[CL_SZ        +: SET_SZ] : ic_addr_in[CL_SZ        +: SET_SZ];            // current working set
   assign tag           = (IC_State == IC_INV_CL) ? inv_addr_in[CL_SZ+SET_SZ +: T_SZ]   : ic_addr_in[CL_SZ+SET_SZ +: T_SZ];
   assign clr_all_valid = (IC_State == IC_IDLE) & icf_ff;            // when its OK to clear all the cache_valid bits

   assign arb_req_addr_out = {tag,set};                              // pass the cache line address to the Arbiter/System Memory

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         IC_State <= IC_IDLE;
      else
         IC_State <= Next_IC_State;

      if (reset_in | clr_all_valid)
         icf_ff <= FALSE;
      else if (ic_flush)
         icf_ff <= TRUE;                                             // capture the ic_flush pulse from the CPU

      if (reset_in | clr_all_valid)
         cache_valid <= '{default: FALSE};                           // clear all bits. Total flags = NUM_SETS * NUM_WAYS
      else if (save_arb_cl)                                          // only set valid bit when data from Arbiter/System Memory is first loaded into a cache lilne
         cache_valid [set] [way] <= TRUE;                            // set a specific bit for a WAY in a particular SET - i.e. current cache line
      else if (hit && (IC_State == IC_INV_CL))                       // invalidate a specific cache line if there's a hit
         cache_valid [set] [way] <= FALSE;

      if (save_arb_cl)	// occurs due to cache miss
      begin
         cache_mem [set] [way] <= arb_ack_data_in;
         cache_tag [set] [way] <= tag;
      end
   end

   assign current_cache_line  = cache_mem [set] [way];               // current cache line

   // Determine if we have a cache hit in the current working set (set)
   integer h;
   always_comb
   begin
      hit      = FALSE;                                              // set default values
      hit_num  = 1'd0;                                               // not used if hit == FALSE

      for (h = 0; h < NUM_WAYS; h++)                                 // look at each WAY
      begin
         if (cache_valid [set] [h] && cache_tag [set] [h] == tag)
         begin
            hit = TRUE;                                              // cache hit - hit is only valid, and only used, during IC_IDLE state because tag is only valid then
            hit_num = h;
         end
      end // for loop
   end

   // Determine if we have an empty (unused) cache in the current working set (set)
   integer n;
   always_comb
   begin
      ecf      = FALSE;                                              // empty cache flag = FALSE
      ecf_num  = 1'd0;                                               // ecf_num not used if ecf == FALSE

      for (n = 0; n < NUM_WAYS; n++)
      begin
         if (!cache_valid [set] [n])                                 // This WAY has never been used
         begin
            ecf      = TRUE;
            ecf_num  = n;                                            // choose any unused WAY
         end
      end // for loop
   end

   // Determine which WAY is the LRU in the current working set (set)
   integer l;
   always_comb
   begin
      lru_num  = 1'd0;                                               // not used if ecf == FALSE

      for (l = 0; l < NUM_WAYS; l++)
      begin
         if (lru [set] [l] == 1'd0)                                  // 0 signifies the Least Recently Used one
            lru_num   = l;
      end // for loop
   end

   // Determine which WAY to use (way is saved at end of IC_State == IC_IDLE)
   always_comb
   begin
      if (hit)                                                       // highest priority is to use the "hit" WAY
         way = hit_num;
      else if (ecf)                                                  // then pick an unused WAY
         way = ecf_num;
      else                                                           // and finally pick the WAY with lru number 0
         way = lru_num;
   end


   // Calculate the next LRU entries for the current working set
   integer p;
   logic [WAY_SZ-1:0] val;
   always_comb
   begin
      val = lru [set] [way];                                         // priority value of the current cache line

      for (p = 0; p < NUM_WAYS; p++)
      begin
         if (lru [set] [p] > val)
            next_lru[p] = lru [set] [p] - 1'd1;                      // Any WAY with a priority higher than val will be decremented
         else if (lru [set] [p] == val)
            next_lru[p] = NUM_WAYS-1;                                // The WAY that holds val will become the MRU
         else
            next_lru[p] = lru [set] [p];                             // Otherwise WAYS with priority less than val wil not change
      end
   end

   logic update_lru;

   genvar s,w;
   generate
      for (s = 0; s < NUM_SETS; s++)
      begin
         for (w = 0; w < NUM_WAYS; w++)
         begin
            always_ff @(posedge clk_in)
            begin
               if (reset_in)
                  lru [s] [w] <= w;                                  // each SET of WAYS initializes with values from 0 to NUM_WAYS-1
               else if (update_lru && (s == set))                    // update LRU values for each WAY in the current working set (set)
                  lru [s] [w] <= next_lru[w];                        // see above logic for next_lru[]
            end
         end
      end
   endgenerate

   // NOTE: CPU is required to only change ic_req_in on the posedge of clk_in
   //       Once ic_req_in is asserted it must remain asserted until req_ack_out is asserted - it may then be de-asserted on the next posedge of clk_in
   //       CPU must capture any ic_rd_data_out when ic_ack_out is asserted at the posedge of clk_in
   always_comb
   begin
      ic_ack_out           = FALSE;                                  // L1 Data Cache is now ready to accept a request from the L/S Process block
      ic_rd_data_out       = '{default: 'd0};
      Next_IC_State        = IC_State;                               // default value

      arb_req_valid_out    = FALSE;

      inv_ack_out          = FALSE;

      arb_ack_rdy_out      = FALSE;

      save_arb_cl          = FALSE;

      update_lru           = FALSE;

      if (!reset_in)
      begin
         unique case(IC_State)
            IC_IDLE:
            begin
               if (inv_req_in)                                       // Is L1 D$ snooping and requesting to Invalidate a Cache Line?
                  Next_IC_State           = IC_INV_CL;
               else if (ic_req_in)                                   // request from Fetch for a cache line of data
               begin
                  if (hit)
                  begin
                     ic_ack_out           = TRUE;
                     ic_rd_data_out       = current_cache_line;
                     update_lru           = TRUE;
                  end
                  else                                               // Cache Miss occurred - pass R/W info to the Arbiter/System Memory
                     Next_IC_State        = REQ_CL_FROM_ARB;         // READ MISS:
               end
            end

            IC_INV_CL:
            begin
               inv_ack_out                = TRUE;
               Next_IC_State              = IC_IDLE;
            end

            REQ_CL_FROM_ARB:                                         // READ MISS: Read Cache Line Request to Arbiter/System Memory
            begin
               arb_req_valid_out          = TRUE;

               if (arb_req_xfer)                                     // Wait for handshake from Arbiter/System Memory
                  Next_IC_State           = WR_ARB_CL_2_CL;
            end

            WR_ARB_CL_2_CL:                                          // READ MISS: Arbiter/System Memory Acknowledge of Read Cache Line request
            begin
               arb_ack_rdy_out            = TRUE;
               if (arb_ack_xfer)
               begin
                  save_arb_cl             = TRUE;                    // write the Arbiter returned cache line to the current CL.

                  Next_IC_State           = CL_2_CPU;                // RD MISS: now return read data to the CPU
               end
            end

            CL_2_CPU:                                                // RD MISS
            begin
               ic_ack_out                 = TRUE;                    // CPU required to take data when this goes high
               ic_rd_data_out             = current_cache_line;
               update_lru                 = TRUE;
               Next_IC_State              = IC_IDLE;
            end
         endcase
      end
   end
endmodule
