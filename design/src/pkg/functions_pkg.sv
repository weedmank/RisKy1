// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
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