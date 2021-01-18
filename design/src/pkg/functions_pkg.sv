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
// File          :  functions_pkg.sv
// Description   :  Just 1 function in this file for now
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package functions_pkg;

   // This function takes a 32 bit value and tells you the minimum number of bits it takes to hold
   // this value.
   // bit_size(256) = 9 bits to hold the value, bit_size(255) = 8 bits to hold the value,
   // bit_size(2) = 2 bits, bit_size(1) = 1, bit_size(0) = 1 -> be careful using this one

   function integer bit_size;
   input integer value;
   reg [31:0] shifted;
   integer res;
   begin
      if (value != 0)
      begin
         shifted = value;
         for (res=0; (shifted != 0); res=res+1)
            shifted = shifted >> 1;
         bit_size = res;
      end
      else
         bit_size = 1; // minimum size, even for a value of 0
   end
   endfunction

endpackage