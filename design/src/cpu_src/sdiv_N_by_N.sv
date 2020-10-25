/// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  div32x32.sv
// Description   :  Calculates signed or unsigned N by N bit integer division using a new
//               :  algorithm crated by Kirk Weedman
//               :  Note: not pipelined
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps


import functions_pkg::*;

module sdiv_N_by_N  #(parameter N = 32)                            // default is 32 x 32 bit signed or unsigned divider
(
   input    logic          clk_in, reset_in,
   input    logic          is_signed,                             // 1 = signed integer divide, 0 = unsigned integer divide

   input    logic          start,                                 // must be asserted until $fell(done)
   output   logic          done,                                  // pulses high for 1 clock cycle.  Data must be grabbed at this time

   input    logic  [N-1:0] dividend,                              // must be held from $rise(start) to $fell(done)
   input    logic  [N-1:0] divisor,                               // must be held from $rise(start) to $fell(done)
   output   logic  [N-1:0] quotient,                              // output during done = TRUE
   output   logic  [N-1:0] remainder,                             // output during done = TRUE
   output   logic          div_by_0_err,                          // 1 = divide by 0 error
   output   logic          overflow_err                           // 1 = overflow error
);
   localparam TRUE   = 1'b1;
   localparam FALSE  = 1'b0;

   // Problem: dividend/divisor = quotient, remainder
   // Method of solution:
   // 1. Q = quotient
   // 2. D = divisor
   // 3. R = remainder
   // Q * D + R = dividend
   // This method calculates Q as a sum of binary powers of 2
   // Example:  90324/4    Q * 4 + R = 90234
   //                      Q = (2^14 + 2^12 + 2^11 + 2^4 + 2^3 + 2^2 + 2^1), R = 2
   //           90210/234  Q*234 + R = 90210
   //                      Q = (2^8 + 2^7 + 2^0) = 385, R = 120
   // The logic below has a simple algorithm to determine Q and R
   // Much of code below is for special cases involving 0/Y, X/0, X/Y where X < Y, X/Y where Y is onehot, etc.. a priority encoder module and a onehot module
   localparam BN = bit_size(N-1);

   logic             ns, ds;                                      // sign of numerator and denominator (0 = positive, 1 = negative)
   logic             qf, rf;                                      // qf == 1 -> quotient needs negating when done, rf == 1 -> remainder needs negating when done
   logic     [N-1:0] abs_dividend;                                // absolute value of dividend
   logic     [N-1:0] abs_divisor;                                 // absolute value of divisor

   logic             run, nxt_run;
   logic     [N-1:0] q, num, q_sel, num_sel;
   logic     [N-1:0] nxt_q, nxt_num;
   logic     [N-1:0] t1, t2, shift1, shift2;
   logic    [BN-1:0] ms_num, ms_den;
   logic    [BN-1:0] hotbit;
   logic             onehot;
   logic     [N-1:0] hotmask;

   assign   ns = is_signed ? dividend[N-1] : 0;                   // 1 = dividend is negative
   assign   ds = is_signed ? divisor[N-1]  : 0;                   // 1 = divisor  is negative
   assign   abs_dividend   = ns ? -dividend : dividend;           // positive (absolute) value of dividend
   assign   abs_divisor    = ds ? -divisor  : divisor;            // positive (absolute) value of divisor
   assign   qf             = ns ^ ds;                             // quotient flag == 1 -> quotient will be negated when done
   assign   rf             = ns;
   // NOTE: division logic in this module is all done in unsigned ( abs(Q), abs(R), so these flags are needed at the
   //       very end (i.e. done = TRUE) to change Q and R back to signed values if signed divide was requested
   // Examples for is_signed == 1
   //          abs(Q)   abs(R)   ns    ds    qf    rf   Q      R
   // 17/5      3       2        0     0     0     0    3      2
   // 15/-5     3       2        0     1     1     0    -3     2
   // -17/5     3       2        1     0     1     1    -3     -2
   // -17/-5    3       2        1     1     0     1    3      -2
   priority_encoder #(N) pe1 (num_sel, ms_num);                   // ms_num: which is the Most Significant bit = 1 position for num
   onehot #(N) hot1 (abs_divisor, hotbit, hotmask, onehot);       // onehot: 1 = divisor is "onehot" and hotbit = bit number that is hot
   assign ms_den = hotbit;

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
      begin
         num   <= 0;
         q     <= 0;
         run   <= FALSE;
      end
      else
      begin
         num   <= nxt_num;
         q     <= nxt_q;
         run   <= nxt_run;
      end
   end


   always_comb
   begin
      done           = FALSE;

      nxt_num        = num;                                       // hold previous value
      nxt_q          = q;
      nxt_run        = run;

      quotient       = 0;                                         // These will remain 0 until done == TRUE
      remainder      = 0;
      div_by_0_err   = FALSE;
      overflow_err   = FALSE;

      shift1         = ms_num - ms_den;
      shift2         = shift1 - 1;

      t1             = abs_divisor << shift1;                     // two posssible choises. One of these will be <= num
      t2             = abs_divisor << shift2;

      num_sel        = run ? num : abs_dividend;
      q_sel          = run ? q   : '0;

      if (start)
      begin
         if (!run)
         begin
            if (divisor == 0)                                     // divide by 0!
            begin
               quotient       = -1;                               // "The quotient of division by zero has all bits set, and the remainder of division by zero equals the dividend"  see riscv-spec.pdf p 44
               remainder      = dividend;                         // These two values are application specific and can be changed as needed
               div_by_0_err   = TRUE;
               done           = TRUE;
            end
            else if (is_signed & (dividend == (1 << (N-1)) & (divisor == -1))) // Signed division overflow occurs only when the most-negative integer is divided by −1."
            begin
               quotient       = dividend;                         // "The quotient of a signed division with overflow is equal to the dividend, and the remainder is zero"  riscv-spec.pdf p 44
               remainder      = 0;                                // These two values are application specific and can be changed as needed
               overflow_err   = TRUE;                             // N==32: -2^31/-1 = 32'h1000_0000_0000_0000___0000_0000_0000_0000/-1
            end
            else if (abs_dividend == 0)                           // zero divided by a non-zero divisor
            begin
               quotient       = 0;
               remainder      = 0;
               done           = TRUE;
            end
            else if (abs_dividend < abs_divisor)
            begin
               quotient       = 0;
               remainder      = dividend;
               done           = TRUE;
            end
            else if (onehot)                                      // special case: divisor is "onehot"
            begin
               quotient       = qf ? -(abs_dividend >> hotbit) : (abs_dividend >> hotbit);   // divide is by a power of two so quotient can be determined by using certain upper bits
               remainder      = rf ? -(abs_dividend & hotmask) : (abs_dividend & hotmask);   // and remainder can be determined by selecting remaining lower bits
               done           = TRUE;
            end
         end

         if (!done)
         begin
            if (num_sel == abs_divisor)                           // remainder == 0
            begin
               quotient       = qf ? -(q_sel + 1) : (q_sel + 1);  // final quotient value
               remainder      = 0;                                // no remainder
               done           = TRUE;
            end
            else if (num_sel < abs_divisor)                       // remainder can now be determined
            begin
               quotient       = qf ? -q_sel : q_sel;
               remainder      = rf ? -num : num;                  // final remainder value
               done           = TRUE;
            end
            else if (t1 <= num_sel)                               // quotient value updated based on this compare
            begin
               nxt_num = num_sel - t1;                            // each subtraction is subtracting divisor*2^N resulting in a series of divisor*2^x + divisir * 2^y + .... = divisor * (2^x + 2^y + ...)
               q_sel[shift1]  = 1'b1;                             // where Q is the series of (2^x + 2^y + ...).  Setting bit x (or y ...) is the same as adding a 2^N term
               nxt_q          = q_sel;
               if (nxt_num < abs_divisor)                         // reduce overall time by 1 clock cycle with this "if" logic
               begin
                  quotient    = qf ? -nxt_q : nxt_q;
                  remainder   = rf ? -nxt_num : nxt_num;
                  done = TRUE;
               end
            end
            else
            begin
               nxt_num = num_sel - t2;
               q_sel[shift2]  = 1'b1;
               nxt_q          = q_sel;
               if (nxt_num < abs_divisor)                         // reduce overall time by 1 clock cycle with this "if" logic
               begin
                  quotient    = qf ? -nxt_q : nxt_q;
                  remainder   = rf ? -nxt_num : nxt_num;
                  done = TRUE;
               end
            end
         end

         if (!run & !done)
            nxt_run = TRUE;
         else if (done)
            nxt_run = FALSE;

      end // start
   end
endmodule

// Find highest order bit number that is set in num
module priority_encoder #(parameter N = 32, localparam BN = bit_size(N-1))
(
   input    logic     [N-1:0] num,
   output   logic    [BN-1:0] bit_num
);
   integer j;
   always_comb
   begin
      bit_num  = 0;
      for (j = 0; j < N; j++)
      begin
         if (num[j])
            bit_num  = j;                                // bit_num will record the highest bit number that is set, starting at bit 0 and looking through all bits up to N-1
      end
   end
endmodule

// onehot
//
// This module takes an N bit input number and outputs...
//   onehot  = TRUE iff exactly one bit in the number is '1'.
//   hotBit  = 0...(N-1): The number of the leftmost '1' bit. (Output is 0 if none.)
//   hotmask = 00...0011...11, where the rightmost '0' is in the position
//             of the leftmost '1' bit in the input value.
//
module onehot #(parameter N = 32, localparam BN = bit_size(N-1))
(
   input    logic     [N-1:0] num,
   output   logic    [BN-1:0] hotbit,
   output   logic     [N-1:0] hotmask,
   output   logic             onehot                     // 1 = num is onehot
);
   localparam TRUE   = 1'b1;
   localparam FALSE  = 1'b0;

   integer k;
   integer bcnt;
   always_comb
   begin
      hotbit   = 0;
      onehot   = TRUE;
      bcnt     = 0;
      hotmask  = 0;

      for (k = 0; k < N; k++)
      begin
         if (num[k])                                     // is this bit set?
         begin
            hotbit = k;                                  // set hotbit to this bit number
            hotmask  = k ? ({N{1'b1}} >> (N-k)) : 0;     // create the mask
            bcnt++;                                      // count the number of bits that are set
         end
      end
      if (bcnt != 1)                                     // if none or more than 1 bit was set then this is not "onehot"
         onehot = FALSE;
   end
endmodule
