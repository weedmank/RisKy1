/// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  mult_N_by_N.sv
// Description   :  Calculates unsigned N by N bit integer multiply using the Kirk Weedman method
//               :  Note: not pipelined
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

   
import functions_pkg::*;

module mult_N_by_N  #(parameter N = 8)                               // default is 8 x 8 bit unsigned multiplier
(
   input    logic             clk_in, reset_in,
   input    logic             is_signed,                             // 1 = signed integer divide, 0 = unsigned integer divide
   
   input    logic             start,                                 // must be asserted until $fell(done)
   output   logic             done,                                  // pulses high for 1 clock cycle.  Data must be grabbed at this time
   
   input    logic     [N-1:0] a,                                     // must be held from $rise(start) to $fell(done)
   input    logic     [N-1:0] b,                                     // must be held from $rise(start) to $fell(done)
   output   logic   [2*N-1:0] result                                 // output during done = TRUE
);
   localparam TRUE   = 1'b1;
   localparam FALSE  = 1'b0;

   parameter BN = bit_size(N-1);
   parameter LN = bit_size(2*N-1);
   
   logic                      flg;

   logic [BN:0] j, k;
   logic [LN:0] l;
   logic   [2*N-1:0] x;
   logic   [2*N-1:0] xc;
   
//   change #(2*N) ch1 (x,xc);
   
//   always @* // use this when putting in #0.1 further below for simulation debug purposes
   always_comb
   begin
      done        = FALSE;
      result      = '0;
      flg         = FALSE;
      
      if (start)
      begin
         if ((a == 0) | (b == 0))                                    // special case: at least one of the multipliers is zer0
            done     = TRUE;  
         else  
         begin 
            for (j = 0; j < N; j++)                                  // each bit of "a" multiplier
            begin 
               for (k = 0; k < N; k++)                               // each bit of "b" multiplier
               begin 
                  if (a[j] & b[k])  
                  begin 
                     if (!result[j + k])                             // is this bit in result == 0?
                        result[j + k] = 1'b1;
                     else
                     begin
                        flg = FALSE;
                        
                        for (l = 0; l < 2*N; l++)
                        begin
                           if ((l >= (j+k)) & !flg)
                           begin
                              if (result[l] == 1'b1)
                                 result[l] = 1'b0;
                              else
                              begin
                                 flg = TRUE;
                                 result[l] = 1'b1;
                              end
//                              #0.1;                               // can be used to see results in each loop
                           end
                        end // for (l = 0;...
                     end
                  end // if (a[j] & b[k])
//                  #0.1;                                           // can be used to see results in each loop
               end // for (k ...                                    
            end // for (j ...
            done = TRUE;
         end
         
      end // start
   end

endmodule

// module change #(parameter W = 2*8)
// (
//    input    logic     [W-1:0] x,
//    output   logic     [W-1:0] xc          // x[n] == 0 and xc[n] == 1 means means bit change occured since x[n-1] 
// );
// 
//    parameter XSZ = bit_size(W);
//    
//    logic [XSZ-1:0] n;
//    always_comb
//    begin
//       xc[0] = 1'b0;
//       for (n = 0; n < W; n++)
//          xc[n] = x[n] ^ x[n-1];
//    end
//    
// endmodule
