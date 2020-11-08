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
// File          :  peripheral_intf.sv
// Description   :  peripheral interfaces external to CPU
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

import cpu_params_pkg::*;
import cpu_structs_pkg::*;

// ------------------------ Interfaces between L1 Caches and Cache Arbiter ------------------------

interface L1IC_ARB;
      // L1 Data Cache Requests a cache line read or write from/to the Arbiter/System Memory
      logic    [PC_SZ-CL_SZ-1:0] req_addr;                     // Request address to arbiter.
      logic                      req_valid;                    // Request valid to arbiter
      logic                      req_rdy;                      // Request ready from arbiter
   
      // Arbiter/System Memory Acknowledges and passes a cache line of data to L1 Data Cache - Note: Only use these signals when Reading
      logic       [CL_LEN*8-1:0] ack_data;                     // Acknowledge data from arbiter. will contain a cache line of data if reading, N/A if writing.
      logic                      ack_valid;                    // Acknowledge valid from arbiter
      logic                      ack_rdy;                      // Acknowledge ready to arbiter

      modport master (output req_addr, req_valid, ack_rdy, input  req_rdy, ack_data, ack_valid);
      modport slave  (input  req_addr, req_valid, ack_rdy, output req_rdy, ack_data, ack_valid);

endinterface: L1IC_ARB

interface L1DC_ARB;
   
      // L1 Data Cache Requests a cache line read or write from/to the Arbiter/System Memory
      ARB_Data                   req_data;                     // Request data to arbiter. This should be at least {rw, rw_addr, wr_data}
      logic                      req_valid;                    // Request valid to arbiter
      logic                      req_rdy;                      // Request ready from arbiter
   
      // Arbiter/System Memory Acknowledges and passes a cache line of data to L1 Data Cache - Note: Only use these signals when Reading
      logic       [CL_LEN*8-1:0] ack_data;                     // Acknowledge data from arbiter. will contain a cache line of data if reading, N/A if writing.
      logic                      ack_valid;                    // Acknowledge valid from arbiter
      logic                      ack_rdy;                      // Acknowledge ready to arbiter

      modport master (output req_data, req_valid, ack_rdy, input  req_rdy, ack_data, ack_valid);
      modport slave  (input  req_data, req_valid, ack_rdy, output req_rdy, ack_data, ack_valid);

endinterface: L1DC_ARB

// ------------------------ Interface between Cache Arbiter and System Memory------------------------
// for use with ../models/sys_mem_model.sv
 
interface SysMem;
   
      // Requests a cache line read or write from/to the System Memory
      logic                      req_rw;                       // Read = 1, Write = 0
      logic    [PC_SZ-CL_SZ-1:0] req_addr;                     // Request address to System Memory
      logic       [CL_LEN*8-1:0] req_wr_data;                  // Request write data to System Memory when rw==0
      logic                      req_valid;                    // Request valid to System Memory
      logic                      req_rdy;                      // Request ready from System Memory
   
      // System Memory Acknowledges and passes a cache line of data to the Arbiter
      logic       [CL_LEN*8-1:0] ack_rd_data;                  // Acknowledge read data from System Memory. will contain a cache line of data if reading, N/A if writing.
      logic                      ack_valid;                    // Acknowledge valid from System Memory
      logic                      ack_rdy;                      // Acknowledge ready to System Memory

      modport master (output req_rw, req_addr, req_wr_data, req_valid, ack_rdy, input  req_rdy, ack_rd_data, ack_valid);
      modport slave  (input  req_rw, req_addr, req_wr_data, req_valid, ack_rdy, output req_rdy, ack_rd_data, ack_valid);

endinterface: SysMem