// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  logic_params_pkg.sv
// Description   :  Simple definitions of TRUE, FALSE, ONE and ZERO
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package logic_params_pkg;

   localparam TRUE   = 1'b1;  // Boolean True
   localparam FALSE  = 1'b0;  // Boolean False
   localparam ONE    = 1'b1;  // Binary 1
   localparam ZERO   = 1'b0;  // Binary 0

endpackage