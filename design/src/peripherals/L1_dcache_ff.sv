// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  L1_dcache.sv - Level 1 Data Cache, 8-way set associative with
// Description   :  32 byte cache line, 32Kbyte cache. LRU replacement policy. Cache size, number of
//               :  ways, cache line length (CL_LEN) and size of address can be changed
//               :  This version does not instantiate RAM, therefore if synthesized it produces lots of flip flops!
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps
      //!!!!!!!!!!!! LOGIC FOR dc_flush STILL NEEDS TO BE IMPLEMENTED !!!!!!!!!!!!!!  Also see dcf_ff further below

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

//                        +------------------------------------------+
//                        |                                          |
// dc_data_in       ----->+                                          +-----> arb_req_data_out
//                        |                          Request to Arb  |
// dc_req_in        ----->+                                          +-----> arb_req_valid_out
//                        | Req/Ack with CPU                         |
// dc_ack_out       <-----+                                          +<----- arb_req_rdy_in
//                        |                                          |
// dc_rd_data_out   <-----+                                          |
//                        |                                          +<----- arb_ack_data_in
//                        |                    Acknowledge from Arb  |
//                        |                                          +<----- arb_ack_valid_in
//                        |                                          |
//                        |                                          +-----> arb_ack_rdy_out
//                        |                                          |
// inv_req_out      <-----+                                          |
//                        |                                          |
// inv_addr_out     <-----+                                          |
//                        |                                          |
// inv_ack_in       ----->+                                          |
//                        |                                          |
//                        +------------------------------------------+

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module L1_dcache
   #(
      // parameters that can be changed/overridden by the user
      parameter   DC_Size     = 32*1024,                             // 32KB Data Cache - must be a power of 2 value
      parameter   NUM_WAYS    = 8,                                   // Number of WAYS
      parameter   A_SZ        = 32,                                  // 32 bit Address
      parameter   DSZ         = 32,                                  // max Load/Store Data Size (width in bits)
      parameter   CL_LEN      = 32                                   // 32 bytes
   )
(
   input    logic                   clk_in,
   input    logic                   reset_in,

   // If a Load/Store to the L1 D$ occurs in Instruction Space then the L1 I$ needs to be notified
   // To know when to do this, the inv_flag (set to TRUE) is passed to the L1 D$ through the CPU core dc_data_in.  The CPU core should flag when this Load/Store is occuring in instruction space
   output   logic                   inv_req_out,                     // request for invalidation of a cache line to the L1 I$
   output   logic        [A_SZ-1:0] inv_addr_out,                    // Cache Line Address to invalidate if it exists
   input    logic                   inv_ack_in,                      // ack from L1 I$

   // L1 Data Cache Requests a cache line read or write from/to the Arbiter/System Memory
   output   ARB_Data                arb_req_data_out,                // data output to arbiter. This should be at least {rw, rw_addr, wr_data}
   output   logic                   arb_req_valid_out,               // valid output to arbiter
   input    logic                   arb_req_rdy_in,                  // ready input from arbiter

   // Arbiter/System Memory Acknowledges and passes a cache line of data to L1 Data Cache - Note: Only use these signals when Reading
   input    logic    [CL_LEN*8-1:0] arb_ack_data_in,                 // data input from arbiter. will contain a cache line of data if reading, N/A if writing.
   input    logic                   arb_ack_valid_in,                // valid input from arbiter
   output   logic                   arb_ack_rdy_out,                 // ready output to arbiter

   // Interface signals to CPU
   input    L1DC_DIN                dc_data_in,                      // Address from CPU specifying which cache line to get
   input    logic                   dc_req_in,                       //
   output   logic                   dc_ack_out,                      //
   output   logic         [DSZ-1:0] dc_rd_data_out,                  // CL_LEN bytes of data (cache line) from cache to Fetch stage plus branch information
   input    logic                   dc_flush
);

   // parameters that CANNOT be changed by the user
   localparam  NUM_CL   = DC_Size/CL_LEN;                            // number of cache lines = total Data Cache size / length of cache line
   localparam  NUM_SETS = NUM_CL/NUM_WAYS;                           // i.e. 1024 cache lines /4 ways = 256 sets

   //             +----------------+----------+---------+
   //             |      T_SZ      |  SET_SZ  |  CL_SZ  |
   //             +----------------+----------+---------+
   // example:            20            7          5
   localparam CL_SZ     = bit_size(CL_LEN-1);
   localparam SET_SZ    = bit_size(NUM_SETS-1);                      // i.e. if NUM_SETS = 128 then SET_SZ = 7 bits
   localparam T_SZ      = A_SZ - SET_SZ - CL_SZ;                     // Tag size = A_SZ - SET_SZ - CL_SZ

   localparam WAY_SZ    = bit_size(NUM_WAYS-1);                      // i.e. if NUM_WAYS = 8 then WAY_SZ = 3 bits

   localparam NUM_SW    = NUM_SETS * NUM_WAYS;
   localparam SW_SZ     = SET_SZ + WAY_SZ;

`pragma protect begin
   logic   [NUM_SW-1:0] [CL_LEN*8-1:0] cache_mem;
   logic   [NUM_SW-1:0]                cache_valid;                  // valid data in cache line
   logic   [NUM_SW-1:0]                cache_dirty;                  // dirty - cache line has been updated (written to)
   logic   [NUM_SW-1:0]     [T_SZ-1:0] cache_tag;

   logic   [NUM_SW-1:0]   [WAY_SZ-1:0] lru;                          // Example: NUM_WAYS = 8, WAY_SZ = 3 bits
   logic [NUM_WAYS-1:0]   [WAY_SZ-1:0] next_lru;

   logic               [CL_LEN*16-1:0] current_cache_line, ccl;
   logic                [CL_LEN*8-1:0] norm_ccl;

   logic                    [A_SZ-1:0] bc_addr;                      // boundary crossing address of next cache line

   logic                  [SET_SZ-1:0] set, norm_set, bc_set;

   logic                  [WAY_SZ-1:0] way;

   logic                    [T_SZ-1:0] tag, norm_tag, bc_tag;

   logic                               hit;                          // hit
   logic                  [WAY_SZ-1:0] hit_num;

   logic                               wr;                           // write flag

   logic                               zx;                           // zero_extend flag : 0 = sign extend for 8 and 16 bit Loads, 1 = zero extend

   logic                         [2:0] sz;                           // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store

   logic                   [SW_SZ-1:0] set_way;                      // address = {set,way}

   logic                     [CL_SZ:0] cla;                          // big enough to access 2 cache lines in width (due to boundary crossing)

   logic                     [DSZ-1:0] std;                          // store data

   logic                               ecf;                          // empty cache found
   logic                  [WAY_SZ-1:0] ecf_num;

   logic                  [WAY_SZ-1:0] lru_num;

   logic                               dirty;
   logic                               update_lru;
   logic                               wr_cpu_data;

   logic                               save_info;
   logic                [CL_LEN*8-1:0] tmp_cache_line;
   logic                    [T_SZ-1:0] tmp_cache_tag;
   logic                               save_tmp_cl;

   logic                               wr_arb_data;
   logic                               cm_wr;                        // cache memory write
   logic                               bc_flag;                      // boundary crossing flag
   logic                               set_bc_ff, clr_bc_ff;

   logic                               dcf_ff, bc_ff;

   logic                               inv_flag;
   logic                               clr_dirty;


   enum logic [3:0] {DC_IDLE, DC_BC, DC_NORM, WR_TMP_CL_2_ARB, REQ_CL_FROM_ARB, WR_ARB_CL_2_CL, CPU_DATA_2_CL, CL_2_CPU, REQ_CL_CHK, WR_INV_CL_2_ARB, DC_INV_IC} Next_DC_State, DC_State;

   // L1 Data Cache port transfer signals
   assign arb_ack_xfer = arb_ack_valid_in  & arb_ack_rdy_out;
   assign arb_req_xfer = arb_req_valid_out & arb_req_rdy_in;

   // Determine some of the initial data that will need to be used.  dc_data_in must be
   // valid the entire req/ack cycle
   assign norm_set   = dc_data_in.rw_addr[CL_SZ        +: SET_SZ];   // current working set
   assign norm_tag   = dc_data_in.rw_addr[CL_SZ+SET_SZ +: T_SZ];
   assign bc_addr    = dc_data_in.rw_addr + CL_LEN;                  // address within next cache line
   assign bc_set     = bc_addr[CL_SZ        +: SET_SZ];
   assign bc_tag     = bc_addr[CL_SZ+SET_SZ +: T_SZ];
   assign set        = bc_ff ? bc_set : norm_set;
   assign tag        = bc_ff ? bc_tag : norm_tag;

   assign wr         = !dc_data_in.rw;
   assign zx         = dc_data_in.zero_ext;
   assign sz         = dc_data_in.size;                              // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
   assign cla        = dc_data_in.rw_addr[CL_SZ-1:0];
   assign std        = dc_data_in.wr_data;
   assign bc_flag    = (dc_data_in.rw_addr[CL_SZ-1:0] > (CL_LEN - sz)) & dc_req_in; // check for access crossing a cache line boundary
   assign inv_flag   = dc_data_in.inv_flag;                          // 1 = A store to L1 D$ also wrote to L1 I$ address space

   assign set_way    = {set,way};
   assign dirty      = cache_dirty [set_way];                        // dirty bit status of current cache line

   assign inv_addr_out = dc_data_in.rw_addr;


   // Sequential logic elements - many are values that need to be saved (save_info) while in DC_IDLE state to be used later in other states
   always_ff @(posedge clk_in)
   begin
      if (reset_in)
         norm_ccl <= 'd0;
      else if (save_info)                                            // see state DC_IDLE
         norm_ccl <= cache_mem [set_way];

      if (reset_in)
         DC_State <= DC_IDLE;
      else
         DC_State <= Next_DC_State;

      if (reset_in)
         dcf_ff      <= FALSE;
      else if (save_info)                                            // see state DC_IDLE
         dcf_ff      <= dc_flush;

      if (reset_in | clr_bc_ff)
         bc_ff       <= FALSE;
      else if (set_bc_ff)                                            // see state DC_IDLE
         bc_ff       <= TRUE;

      if (save_tmp_cl)
      begin
         tmp_cache_line <= cache_mem [set_way];                      // save current cache line if needed for later use
         tmp_cache_tag  <= cache_tag [set_way];                      // save tag that corresponds to tmp_cache_line
      end

      // OK not to include the reset_in logic if SRAM automatically gets cleared on power-up
      // if SRAM doesn't get cleared, add a powerup state and address counter and clear all memory
      if (reset_in)
      begin
         cache_dirty <= '{default: FALSE};
         cache_valid <= '{default: FALSE};                           // clear all bits. Total flags = NUM_SETS * NUM_WAYS
      end
      else if (cm_wr)
      begin
         // wr_cpu_data: set dirty bit - CPU is writing to the current cache line
         // wr_arb_data: clear dirty bit - we just wrote the whole cache line to the Arbiter/System Memory
         // wr_cpu_data and wr_arb_data should be mutually exclusive - make an assertion to test this
         cache_dirty [set_way] <= wr_cpu_data;
         // only set the valid bit when data from Arbiter/System Memory is first loaded into a cache line
         cache_valid [set_way] <= wr_arb_data ? TRUE : cache_valid [set_way]; // set a specific bit for a WAY in a particular SET - i.e. current cache line
      end
      else if (clr_dirty)
         cache_dirty [set_way] <= FALSE;

      // Not necessary to reset cache memory because valid & dirty bits will control how it gets used - BUT IT WOULD NOT HURT OR MATTER!!! COMBINE MEM & TAG WITH DIRTY & VALID BITS!!!
      if (cm_wr)
      begin
         cache_tag [set_way] <= tag;
         cache_mem [set_way] <= wr_arb_data ? arb_ack_data_in : (bc_ff ? current_cache_line[CL_LEN*16-1:CL_LEN*8] : current_cache_line[CL_LEN*8-1:0]);
      end
   end

   assign cm_wr = wr_arb_data | wr_cpu_data;                         // wr_arb_data occurs due to cache miss : wr_cpu_data occurs during DC_IDLE and other states

   always_comb                                                       // Determine what pat of a cache line will get changed
   begin
      ccl  = bc_ff ?  {cache_mem [set_way],norm_ccl} : cache_mem [set_way]; // when bc_ff == TRUE, R/W data will straddle two cache lines
      // now check to see if data needs to be written into this ccl
      if (wr_cpu_data)
      begin
         case (sz)                                                   // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
            1: ccl [cla*8 +:  8] = std[7:0];
            2: ccl [cla*8 +: 16] = std[15:0];
            4: ccl [cla*8 +: 32] = std[31:0];
         endcase
      end
      current_cache_line = ccl;
   end


   // Determine if we have a cache hit in the current working set (set)
   integer h;
   logic [WAY_SZ-1:0] hw;
   always_comb
   begin
      ecf      = FALSE;                                              // empty cache flag = FALSE
      ecf_num  = 1'd0;                                               // ecf_num not used if ecf == FALSE

      hit      = FALSE;                                              // set default values
      hit_num  = 1'd0;                                               // not used if hit == FALSE

      for (h = 0; h < NUM_WAYS; h++)                                 // look at each WAY
      begin
         hw = h;
         if (!cache_valid [{set,hw}])                                // This WAY has never been used
         begin
            ecf      = TRUE;
            ecf_num  = h;                                            // choose any unused WAY
         end
         else if (cache_tag [{set,hw}] == tag)
         begin
            hit      = TRUE;                                         // cache hit - hit is only valid, and only used, during DC_IDLE state because tag is only valid then
            hit_num  = h;
         end
      end // for loop
   end

   // Determine which WAY is the Least Recently Used one in the current working set (set)
   integer l;
   logic [WAY_SZ-1:0] lw;
   always_comb
   begin
      lru_num  = 1'd0;                                               // not used if ecf == FALSE

      for (l = 0; l < NUM_WAYS; l++)
      begin
         lw = l;
         if (lru [{set,lw}] == 1'd0)                                 // 0 signifies the Least Recently Used one
            lru_num   = l;
      end // for loop
   end

   // Determine which WAY to use (way is saved at end of DC_State == DC_IDLE)
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
   logic [WAY_SZ-1:0] pw;
   logic [WAY_SZ-1:0] val;
   always_comb
   begin
      val = lru [set_way];                                           // priority value of the current cache line - set_way = {set,way}

      for (p = 0; p < NUM_WAYS; p++)
      begin
         pw = p;
         if (lru [{set,pw}] > val)
            next_lru[p] = lru [{set,pw}] - 1'd1;                     // Any WAY with a priority higher than val will be decremented
         else if (lru [{set,pw}] == val)
            next_lru[p] = NUM_WAYS-1;                                // The WAY that holds val will become the MRU
         else
            next_lru[p] = lru [{set,pw}];                            // Otherwise WAYS with priority less than val wil not change
      end
   end

   // LRUs
   genvar s,w;
   generate
      for (s = 0; s < NUM_SETS; s++)
      begin
         for (w = 0; w < NUM_WAYS; w++)
         begin
            always_ff @(posedge clk_in)
            begin
               if (reset_in)
                  lru [s*NUM_WAYS + w] <= w;                         // each SET of WAYS initializes with values from 0 to NUM_WAYS-1
               else if (update_lru && (s == set))                    // update LRU values for each WAY in the current working set (set)
                  lru [s*NUM_WAYS + w] <= next_lru[w];               // see above logic for next_lru[]
               else
                  lru [s*NUM_WAYS + w] <= lru [s*NUM_WAYS + w];      // default is no change
            end
         end
      end
   endgenerate

   // Cache FSM control logic
   always_comb
   begin
      dc_ack_out           = FALSE;
      dc_rd_data_out       = '0;

      Next_DC_State        = DC_State;                               // default value
      save_info            = FALSE;

      arb_req_data_out     = '{default: 'd0};
      arb_req_valid_out    = FALSE;

      arb_ack_rdy_out      = FALSE;

      wr_arb_data          = FALSE;
      wr_cpu_data          = FALSE;

      update_lru           = FALSE;

      save_tmp_cl          = FALSE;

      inv_req_out          = FALSE;
      clr_dirty            = FALSE;

      set_bc_ff            = FALSE;
      clr_bc_ff            = FALSE;

      if (!reset_in)
      begin
         case(DC_State)
            DC_IDLE:                                                       // bc_ff MUST be FALSE in this state
            begin
               if (dc_req_in)                                              // request from L/S Process block for a cache line of data AND INV_state has recovered from any I$ Invalidation request
               begin
                  save_info   = TRUE;                                      // set, way, etc.. need to be updated
                  if (inv_flag)                                            // hold off read/write access if an invalidate is occurring
                      Next_DC_State  = WR_INV_CL_2_ARB;                    // WRITE HIT: need to write cache line out to System Memory & notify L1 I$
                  else if (hit)                                            // did this R/W request result in a hit (data valid bit set and tag match) or a miss
                  begin
                     update_lru  = TRUE;                                   // update lru for read/write hit access
                     if (!wr)                                              // Read Hit
                     begin
                        if (!bc_flag)                                      // check for access crossing a cache line boundary
                        begin
                           dc_ack_out  = TRUE;                             // no boundary crossing for this READ HIT so send data out
                           case (sz)                                       // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
                              1: dc_rd_data_out = zx ? {{24{1'b0}},current_cache_line[cla*8 +: 8]}  : {{24{current_cache_line[cla*8 + 7]}}, current_cache_line[cla*8 +: 8]};
                              2: dc_rd_data_out = zx ? {{16{1'b0}},current_cache_line[cla*8 +: 16]} : {{16{current_cache_line[cla*8 + 15]}},current_cache_line[cla*8 +: 16]};
                              4: dc_rd_data_out = current_cache_line[cla*8 +: 32];
                           endcase                                         //!!! WARNING: cla*8 +: N could wrap into another cache_line !!!
                        end
                        else
                        begin
                           set_bc_ff      = TRUE;                          // next state will have set,tag = bc_set,bc_tag
                           Next_DC_State  = DC_BC;                         // RD HIT with Boundary crossing: read the 2nd cache line needed due to boundary crossing
                        end
                     end
                     else                                                  // Write Hit
                     begin
                        wr_cpu_data       = TRUE;                          // write CPU data into current cache line (i.e. cache_mem[set_way])
                        if (!bc_flag)
                           dc_ack_out     = TRUE;                          // WR HIT: remain in IDLE and acknowledge access
                        else
                        begin
                           set_bc_ff      = TRUE;                          // next state will have set,tag = bc_set,bc_tag
                           Next_DC_State  = DC_BC;                         // WR HIT: write to next cache line due to boundary crossing
                        end
                     end
                  end
                  else                                                     // Cache Miss occurred - pass R/W info to the Arbiter/System Memory
                     Next_DC_State        = REQ_CL_FROM_ARB;               // READ MISS: WR MISS:
               end
            end

            WR_INV_CL_2_ARB:                                               // WR HIT: WR MISS: Write cache line to Arbiter/System Memory
            begin
               arb_req_data_out.rw        = 1'b0;                          // This is a write to the Arbiter/System Memory
               arb_req_data_out.rw_addr   = {tag,set};                     // pass address where the cache line goes in the Arbiter/System Memory. This is a cache line address
               arb_req_data_out.wr_data   = cache_mem [set_way];           // pass the currently found(determined by "hit") cache line to the Arbiter/System Memory
               arb_req_valid_out          = TRUE;
               // clear dirty bit when cache line is written to System Memory
               if (arb_req_xfer)                                           // Wait for Arbiter/System Memory to accept the Write request
               begin
                  clr_dirty               = TRUE;
                  Next_DC_State           = DC_INV_IC;
               end
            end

            DC_INV_IC:                                                     // let L1 I$ know to reload the cache line located at byte address "inv_addr_out"
            begin
               inv_req_out = TRUE;
               if (inv_ack_in)
               begin
                  dc_ack_out              = TRUE;                          // Let CPU know the invalidate request cycle process is completed
                  Next_DC_State           = DC_IDLE;
               end
            end

            DC_BC:                                                         // Read or Write hit occured for normal (1st) cache line, but cache line boundary was crossed
            begin
               // set,tag = bc_set, bc_tag - bc_ff MUST be TRUE during this state

               if (hit)                                                    // may not be a hit for the 2nd cache line
               begin
                  clr_bc_ff         = TRUE;                                // In next state the set,tag will be from norm_set, norm_tag
                  if (!wr)                                                 // RD Hit can complete
                  begin
                     case (sz)                                             // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
                        1: dc_rd_data_out = zx ? {{24{1'b0}},current_cache_line[cla*8 +:  8]} : {{24{current_cache_line[cla*8 +  7]}}, current_cache_line[cla*8 +: 8]};
                        2: dc_rd_data_out = zx ? {{16{1'b0}},current_cache_line[cla*8 +: 16]} : {{16{current_cache_line[cla*8 + 15]}}, current_cache_line[cla*8 +: 16]};
                        4: dc_rd_data_out = current_cache_line[cla*8 +: 32];
                     endcase
                     dc_ack_out     = TRUE;                                // WR Hits are acknowledged
                     update_lru     = TRUE;                                // WR access to current cache line
                     Next_DC_State  = DC_IDLE;                             // WR HIT: return to IDLE
                  end
                  else                                                     // WR Hit can complete
                  begin
                     wr_cpu_data    = TRUE;                                // Write boundary crossing cache line
                     Next_DC_State  = DC_NORM;                             // WR HIT: both cache lines need to be written to cache mem
                  end
               end
               else                                                        // RD/WR Miss: 2nd cache line wasn't a hit - must get it from memory
                  Next_DC_State     = REQ_CL_FROM_ARB;                     // READ MISS: WR MISS: for 2nd cache line (boundary crossing cache line)
            end

            DC_NORM:                                                       // bc_ff MUST be FALSE during this state
            begin
               wr_cpu_data    = TRUE;                                      // This will write normal (1st) cache line to cache mem because bc_ff is FALSE in this state
               update_lru     = TRUE;                                      // WR access to current cache line

               Next_DC_State  = DC_IDLE;                                   // WR HIT: return to IDLE
            end

            REQ_CL_FROM_ARB:                                               // READ MISS: WR MISS: Read Cache Line Request to Arbiter/System Memory
            begin
               arb_req_data_out.rw        = 1'b1;                          // This must be a read
               arb_req_data_out.rw_addr   = {tag,set};                     // pass cache line address to the Arbiter/System Memory
               arb_req_valid_out          = TRUE;

               if (arb_req_xfer)                                           // Wait for acknowledge from Arbiter/System Memory
               begin
                  save_tmp_cl             = TRUE;
                  Next_DC_State           = WR_ARB_CL_2_CL;
               end
            end

            WR_ARB_CL_2_CL:                                                // READ MISS: WR MISS: Arbiter/System Memory Acknowledge of Read Cache Line request
            begin
               arb_ack_rdy_out            = TRUE;
               if (arb_ack_xfer)
               begin
                  wr_arb_data             = TRUE;                          // this will write data from arbiter into cache
//                  update_lru  = TRUE;  will be done on a state after this one
                  if (wr)                                                  // was the original cpu request a write to cache?
                  begin
                     if (dirty)                                            // is current cache line dirty?
                        Next_DC_State     = WR_TMP_CL_2_ARB;               // WR MISS DIRTY: ...then write the tmp_cache_line to Arbiter/System Memory.
                     else
                        Next_DC_State     = CPU_DATA_2_CL;                 // WR MISS CLEAN: .. next write cpu data into new cache line
                  end
                  else // READ MISS
                     Next_DC_State        = CL_2_CPU;                      // RD MISS DIRTY: RD MISS CLEAN: now return read data to the CPU
               end
            end

//- this state could be eliminated if the cpu write data could be merged with the new arb data and the result written to the current cache line during state WR_ARB_CL_2_CL
            CPU_DATA_2_CL:                                                 // WR MISS CLEAN: System Memory placed into unused cache memory can now be updated with CPU data
            begin
               wr_cpu_data                = TRUE;                          // save cpu data into current cache line and also set the cache dirty bit (if this was a cpu write)
               update_lru                 = TRUE;

               if (bc_flag & !bc_ff)
               begin
                  set_bc_ff               = TRUE;                          // need 2nd cache line because WRITE access straddles cache lines
                  Next_DC_State           = REQ_CL_FROM_ARB;
               end
               else // (!bc_flag | bc_ff)
               begin
                  dc_ack_out              = !inv_flag;
                  clr_bc_ff               = TRUE;                          // In next state the set,tag will be from norm_set, norm_tag
                  if (inv_flag)
                     Next_DC_State        = WR_INV_CL_2_ARB;               // WR MISS CLEAN: need to write cache line out to System Memory & notify L1 I$
                  else
                     Next_DC_State        = DC_IDLE;                       // WR MISS CLEAN: return to IDLE
               end
            end

            WR_TMP_CL_2_ARB:                                               // WR MISS DIRTY: RD MISS DIRTY: Write tmp_cache_line to Arbiter/System Memory
            begin
               arb_req_data_out.rw        = 1'b0;                          // This is a write to the Arbiter/System Memory
               arb_req_data_out.rw_addr   = {tmp_cache_tag,set};           // pass address where tmp_cache_line goes in the Arbiter/System Memory
               arb_req_data_out.wr_data   = tmp_cache_line;                // pass tmp_cache_line to the Arbiter/System Memory
               arb_req_valid_out          = TRUE;

               if (arb_req_xfer)                                           // Wait for Arbiter/System Memory to accept the R/W transfer request
               begin
                  wr_cpu_data             = wr;                            // Also, IF this is a cpu write access then save cpu data into current cache line and also set the cache dirty bit
                  update_lru              = wr;

                  dc_ack_out              = wr;                            // Only set if this was from a WR MISS DIRTY. dc_ack_out = TRUE in state CL_2_CPU in a RD MISS DIRTY just prior to this state
                  if (inv_flag & wr)
                     Next_DC_State        = WR_INV_CL_2_ARB;               // WR MISS DIRTY: need to write cache line out to System Memory & notify L1 I$
                  else
                     Next_DC_State        = DC_IDLE;                       // done
               end
            end

            // This state must have !wr (READ) and hit == FALSE (i.e. MISS)
            CL_2_CPU:                                                      // RD MISS CLEAN: RD MISS DIRTY:
            begin    
               update_lru  = TRUE;                                         // update lru
               if (dirty)     
                  Next_DC_State           = WR_TMP_CL_2_ARB;               // RD MISS DIRTY: now save tmp_cache_line
               else if (bc_flag & !bc_ff)    
               begin    
                  set_bc_ff               = TRUE;     
                  Next_DC_State           = REQ_CL_CHK;                    // RD MISS CLEAN: need 2nd cache line
               end      
               else // !bc_flag | bc_ff -  time to finish      
               begin    
                  clr_bc_ff               = TRUE;                          // In next state the set,tag will be from norm_set, norm_tag
                  dc_ack_out              = TRUE;                          // dc_req_out is already TRUE in order to get here.  CPU required to take data on THIS clock cycle if it wants it
                  case (sz)                                                // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
                     1: dc_rd_data_out = zx ? {{24{1'b0}},current_cache_line[cla*8 +: 8]}  : {{24{current_cache_line[cla*8 + 7]}}, current_cache_line[cla*8 +: 8]};
                     2: dc_rd_data_out = zx ? {{16{1'b0}},current_cache_line[cla*8 +: 16]} : {{16{current_cache_line[cla*8 + 15]}},current_cache_line[cla*8 +: 16]};
                     4: dc_rd_data_out = current_cache_line[cla*8 +: 32];
                  endcase                                                  //!!! WARNING: cla*8 +: N could wrap into another cache_line !!!
                  Next_DC_State           = DC_IDLE;                       // RD MISS CLEAN: return to IDLE
               end      
            end      
      
            REQ_CL_CHK: // is 2nd cache line a hit ?     
            begin       // bc_ff == TRUE     
               if (hit)    
                  Next_DC_State           = CL_2_CPU;                      // bc_ff == TRUE so CL_2_CPU will finish access
               else // miss
                  Next_DC_State           = REQ_CL_FROM_ARB;
            end
         endcase
      end
   end
/*
   READ HIT CLEAN & DIRTY
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - hit determined (address matches and valid data in current cache line)
   CL_2_CPU          - update_lru = T, return of current cache line data as selected by size and zero extension

   READ MISS CLEAN
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - miss determined
   REQ_CL_FROM_ARB   - ask Arbiter for data (read req), save_tmp_cl
   WR_ARB_CL_2_CL    - update_lru = T, wr_arb_data = T               Updates LRU and saves arbiter data & associated tag in cache
   CL_2_CPU          - update_lru = T,                               Updates LRU
                       return of current cache line data to CPU
                       as selected by size and zero extension

   READ MISS DIRTY
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - miss determined
   REQ_CL_FROM_ARB   - ask Arbiter for data (read req), save_tmp_cl
   WR_ARB_CL_2_CL    - update_lru = T, wr_arb_data = T               Updates LRU and saves arbiter data & associated tag in cache
   CL_2_CPU          - update_lru = T,                               Updates LRU
                       return of current cache line data to CPU
                       as selected by size and zero extension
   WR_TMP_CL_2_ARB   - update_lru = wr, wr_cpu_data = wr,            DOES NOT update LRU or save cpu data & associated tag in cache because this is a cpu RD
                       save temp cache line to ARB (write req)


   WR HIT CLEAN & DIRTY
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - hit determined (address matches and valid data in current cache line)
                     - update_lru = T, wr_cpu_data = T               Saves cpu data and associated tag and updates LRU.

   WR MISS CLEAN     current_cache_line has data from address 1000, but CPU requests data from address 1234
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - miss determined
   REQ_CL_FROM_ARB   - ask Arbiter for data (read req), save_tmp_cl
   WR_ARB_CL_2_CL    - update_lru = T, wr_arb_data = T               Updates LRU and saves arbiter data & associated tag in cache (i.e. from addr 1234, not 1000)
   CPU_DATA_2_CL     - update_lru = T, wr_cpu_data = T               Updates LRU and saves arbiter data & associated tag in cache
                                                                     CPU_DATA_2_CL state added because previous state wrote arbiter data to cache,
                                                                     thus wait till this clock cycle to write cpu data into cache. Can't
                                                                     write both arbiter and cpu data during WR_ARB_CL_2CL

   WR MISS DIRTY     (current cache line has updated data from address 5678 - needs to be written to ARB before replaced)
   ---------------------------------------------------------------------------------------------------------------------
   DC_IDLE           - miss determined   (CPU wants to write to address 1234, current cache line has address 5678)
   REQ_CL_FROM_ARB   - ask Arbiter for data (read req from address 1234), save_tmp_cl
   WR_ARB_CL_2_CL    - update_lru = T, wr_arb_data = T               Updates LRU and saves arbiter data & associated tag
   WR_TMP_CL_2_ARB   - update_lru = wr, wr_cpu_data = wr,            Updates LRU and saves cpu data & associated tag in cache because this is a cpu WR
                       save temp cache line to ARB (write req)
*/
`pragma protect end
endmodule
