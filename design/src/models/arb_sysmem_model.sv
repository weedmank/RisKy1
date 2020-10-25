// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  arb_sysmem_model.sv
// Description   :  Model of a simple arbiter with system memory
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
//                             |            +---------------+             |
//                clk_in ----->|            | "Instr_Depth" |             |
//                             |            |    Memory     |             |
//              reset_in ----->|            +---------------+             |
//                             |                                          |
//                             +------------------------------------------+
//                                           ARBITER + Sytem Memory
//

module arb_sysmem_model
(
   input    logic                   clk_in, reset_in,

   L1IC_ARB.slave                   IC_arb_bus,
   L1DC_ARB.slave                   DC_arb_bus
);

   //-----------------------------------------------------------------------------
   // Emulated System Memory
   //-----------------------------------------------------------------------------
   logic    [7:0] sys_mem [Phys_Addr_Lo:Phys_Addr_Lo+Instr_Depth-1];                         // System Memory  (used whenever the access address is in Phys_Addr_Lo to Phys_Addr_Hi range)
   logic   [31:0] tmp_mem [Phys_Addr_Lo:Phys_Addr_Lo+(Instr_Depth/4)-1];                     // grab all the data from the file then decide how to put it in sys_mem[]
   logic   [31:0] b4;

   integer k,bp,ndx;
   initial
   begin // see top_tb1.do simulation script (executed in Modelsim)
      $readmemh(`TEST_FILE, tmp_mem); // all hex data must be organized in chunks of 4 bytes and be in proper ENDIAN format

      // transfer instructions to sys_mem[] - all done at simulation time 0 and done in 0 ns (because there are no simulation delays)
      bp = 0;   // which instruction is getting transfered to a cache_line
      for (k = 0; k < (Instr_Depth/4); k++)
      begin
         b4 = tmp_mem[k];  // 4 bytes of data in Big/Little Endian format
         `ifndef BIG_ENDIAN
         for (ndx = 0; ndx < 4; ndx++)    // LITTLE ENDIAN
         `else
         for (ndx = 3; ndx >= 0; ndx--)   // BIG ENDIAN
         `endif
         begin
            sys_mem[bp] = b4[ndx*8 +: 8];
            bp++;
         end
      end
   end

   integer p;
   logic    [CL_LEN*8-1:0] wr_data;                                                          // enough room for 1 cache line of data from sys_mem[]
   logic       [PC_SZ-2:0] b_addr;                                                           // byte_address used as pointer while filling sys_mem[]
   logic                   rw;

   initial                                                                                   // Oh goodie! I get to be the fake System Memory Arbiter :)
   begin
      IC_arb_bus.req_rdy   = FALSE;
      IC_arb_bus.ack_valid = FALSE;

      DC_arb_bus.req_rdy   = FALSE;
      DC_arb_bus.ack_valid = FALSE;
      DC_arb_bus.ack_data  = 'z;                                                             // should not matter until an active req/ack cycle occurs

      #2
      wait (!reset_in);                                                                      // wait for reset_in to go low

      do
      begin
         #1
         rw = 1'bz;                                                                          // easy to see in simulation where it changes and when it's not being used.  changes to Z when not an active req/ack cycle
         wr_data  = 1'bz;                                                                    // this should not affect anything during write or non req/ack cycles
         do @(negedge clk_in); while (!(IC_arb_bus.req_valid | DC_arb_bus.req_valid));       // wait for either rdy_in to go high

         // ---------------------------------------------- Instruction Cache Transfers ------------------------------------------------------
         if (IC_arb_bus.req_valid)                                                           // give priority to instructions
         begin
            // calculate starting byte address of where to get cache line data from sys_mem[]
            b_addr   = (IC_arb_bus.req_addr << CL_SZ) - Phys_Addr_Lo;                        // assume SYSTEM MEMORY starts at Phys_Addr_Lo
            rw       = 1'b1;

            @(posedge clk_in);                                                               // This is a read only request
            @(posedge clk_in);
            @(posedge clk_in);                                                               // delay as though its taking some time to get the data
            #1                                                                               // just some visible simulation delay after the clock edge
            IC_arb_bus.req_rdy = TRUE;                                                       // let L1_icache know the arbiter is ready to accept a request

            for (p = 0; p < CL_LEN; p++)                                                     // each cache line can hold up to CL_LEN bytes
               IC_arb_bus.ack_data[p*8 +: 8] = sys_mem[b_addr + p];

            @(posedge clk_in);
            #1                                                                               // just some visible simulation delay after the clock edge
            IC_arb_bus.req_rdy = FALSE;                                                      // let L1_icache know the arbiter is no lobger ready

            IC_arb_bus.ack_valid = TRUE;                                                     // let L1_icache know that it can take the new data

            do @(negedge clk_in); while (!IC_arb_bus.ack_rdy);                               // wait for rdy_in to go high

            @(posedge clk_in);
            #1
            IC_arb_bus.ack_valid = FALSE;
         end
         // ---------------------------------------------- Data Cache Transfers ------------------------------------------------------
         else if (DC_arb_bus.req_valid)
         begin
            // calculate starting byte address of where to get cache line data from sys_mem[]
            b_addr      = (DC_arb_bus.req_data.rw_addr << CL_SZ) - Phys_Addr_Lo;  // assume SYSTEM MEMORY starts at Phys_Addr_Lo
            rw          = DC_arb_bus.req_data.rw;
            wr_data     = DC_arb_bus.req_data.wr_data;

            @(posedge clk_in);
            @(posedge clk_in);                                                               // delay as though its taking some time to get the data
            #1                                                                               // just some visible simulation delay after the clock edge
            DC_arb_bus.req_rdy = TRUE;                                                       // let L1_dcache know the arbiter is ready to accept a request

            if (rw) // is_ld = 1
            begin
               for (p = 0; p < CL_LEN; p++)                                                  // each cache line can hold up to CL_LEN bytes
                  DC_arb_bus.ack_data[p*8 +: 8] = sys_mem[b_addr + p];

               @(posedge clk_in);
               #1                                                                            // just some visible simulation delay after the clock edge
               DC_arb_bus.req_rdy = FALSE;                                                   // let L1_dcache know the arbiter is no lobger ready

               DC_arb_bus.ack_valid = TRUE;                                                  // let L1_dcache know that it can take the new data

               do @(negedge clk_in); while (!DC_arb_bus.ack_rdy);                            // wait for rdy_in to go high

               @(posedge clk_in);
               #1
               DC_arb_bus.ack_valid = FALSE;
            end
            else                                                                             // write a cache line to System Memory
            begin

               for (p = 0; p < CL_LEN; p++)                                                  // each cache line can hold up to CL_LEN bytes
                  sys_mem[b_addr + p] = wr_data[p*8 +: 8];                                   // wr_data is a cache line of data from L1 D$

               @(posedge clk_in);
               #1                                                                            // just some visible simulation delay after the clock edge
               DC_arb_bus.req_rdy = FALSE;                                                   // let L1_dcache know the arbiter is no lobger ready
            end
         end
      end
      while (1); // do this forever or until simulation stops
   end
endmodule
