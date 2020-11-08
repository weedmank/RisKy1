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
// File          :  sys_mem_model.sv 
// Description   :  Model of a System Memory
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;

module sys_mem_model
(
   input    logic                   clk_in, reset_in,

   SysMem.slave                     sysmem_bus
);

   //-----------------------------------------------------------------------------
   // Emulated System Memory
   //-----------------------------------------------------------------------------
   logic    [7:0] sys_mem [Phys_Addr_Lo:Phys_Addr_Hi];                  // System Memory  (used whenever the access address is in Phys_Addr_Lo to Phys_Addr_Hi range)
   logic   [31:0] tmp_mem [Phys_Addr_Lo:(Phys_Addr_Lo+Phys_Depth)/4-1]; // grab all the data from the file then decide how to put it in sys_mem[]
   logic   [31:0] b4;

   integer k,bp,ndx;
   initial // Note: Yoiu will not see anything in simulation becuase there are no time delays in this logic.  Everything is loaded in 0 simulation time @ time = 0
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

   integer                 p;
   logic    [CL_LEN*8-1:0] wr_data;                                                          // enough room for 1 cache line of data from sys_mem[]
   logic       [PC_SZ-1:0] b_addr;                                                           // byte_address used as pointer while filling sys_mem[]

   initial
   begin
      #3
      wr_data              = '0;                                                             // this should not affect anything during write or non req/ack cycles
      b_addr               = 'z;
      sysmem_bus.req_rdy   = FALSE;
      sysmem_bus.ack_valid = FALSE;
      wait (!reset_in);                                                                      // wait for reset_in to go low

      do
      begin
         @(posedge clk_in);
         #1
         sysmem_bus.req_rdy      = TRUE;                                                     // SysMem is ready to accept a request from an arbiter
         sysmem_bus.ack_valid    = FALSE;
         sysmem_bus.ack_rd_data  = 1'bz;
         
         do @(negedge clk_in); while (!sysmem_bus.req_valid);                                // sample in middle of clock cycle and wait for req_valid to go high
         b_addr = sysmem_bus.req_addr << CL_SZ;
         
         if (sysmem_bus.req_rw)  // read request
         begin
            @(posedge clk_in);
            @(posedge clk_in);
            #1                                                                               // just some visible simulation delay after the clock edge
            for (p = 0; p < CL_LEN; p++)                                                     // each cache line can hold up to CL_LEN bytes
               sysmem_bus.ack_rd_data[p*8 +: 8] = sys_mem[b_addr + p];
               
            // acknowledge the transfer
            sysmem_bus.ack_valid = TRUE;
         end
         else // write_request
         begin
            wr_data  = sysmem_bus.req_wr_data;
            @(posedge clk_in);
            @(posedge clk_in);
            #1                                                                               // just some visible simulation delay after the clock edge
            for (p = 0; p < CL_LEN; p++)                                                     // each cache line can hold up to CL_LEN bytes
               sys_mem[b_addr + p] = wr_data[p*8 +: 8];                                      // wr_data is a cache line of data from L1 D$
               
            // acknowledge the transfer
            sysmem_bus.ack_valid = TRUE;
         end
      end
      while (1); // do this forever or until simulation stops
   end
endmodule