// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  mult_tb.sv - test bench for mult_N_by_N.sv
// Description   :  new RV32IMC  architect tailored to the RISC_V 32bit ISA
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

module  mult_tb();

   parameter N = 32;             // 32 x 32 bit unsigned multiply
   
   logic             reset;
   logic             clk_100;
   logic             debug;
   integer           clock_cycle;
   logic             start;
   logic             done;
   logic     [N-1:0] a;
   logic     [N-1:0] b;
   logic   [2*N-1:0] result;
   logic   [2*N-1:0] r;
   logic             is_signed;
   logic             sstart;
   logic             sdone;
   logic signed     [N-1:0] sa;
   logic signed     [N-1:0] sb;
   logic signed   [2*N-1:0] sresult;
   logic signed   [2*N-1:0] sr;
   
   // N = number of bits for a and b. Record how many divides take N cycles
   // Example: record_bin[9] will record the number of divides that took 9 clock cycles
   logic    [N-1:0] [31:0] record_bin; 
   
   localparam TRUE = 1'b1;
   localparam FALSE = 1'b0;
   
`define DelayClockCycles(a) \
   repeat (a) @(posedge clk_100)
   integer k;
   
   initial
   begin
      start    = FALSE;
      sstart   = FALSE;
      debug    = FALSE;
      reset    = TRUE;
      is_signed = FALSE;   // first tests are unsigned 32 x 32 bit divide
      k        = 0;
      
      r  = 0;
      a  = 0;
      b  = 0;
      sr = 0;
      sa = $signed(a);
      sb = $signed(b);
      
      `DelayClockCycles(50);
      reset    = 1'b0;
      $display("Reset completed, Simulation started.");
      
      @(posedge clk_100);
      @(posedge clk_100);
      
      
      // initial tests used to check/debug mult32x32.sv
      a = 0; b = 12345678; mult();                                                        // 1 clock cycle
      a = 9; b = 1; mult();                                                               // 1 clock cycle
      a = 9; b = 2; mult();                                                               // 1 clock cycle
      a = 9; b = 3; mult();                                                               // 1 clock cycles
      a = 9; b = 4; mult();                                                               // 1 clock cycle
      a = 12; b = 3; mult();                                                              // 1 clock cycles
      a = 90234; b = 4; mult();                                                           // 1 clock cycle
      a = 90210; b = 234; mult();                                                         // 2 clock cycles
      a = 32'h35; b = 32'h52; mult();                                                     // 2 clock cycles
      a = 32'h135; b = 32'h52; mult();                                                    // 3 clock cycles
      a = 32'h85; b = 32'h53; mult();                                                     // 1 clock cycles
      a = 32'hc35; b = 32'h152; mult();                                                   // 2 clock cycles
      a = 32'he35; b = 32'h352; mult();                                                   // 4 clock cycles
      a = 12345; b = 6789; mult();                                                        // 3 clock cycles
      a = 83474; b = 173; mult();                                                         // 2 clock cycles
      a = 666; b = 0; mult();                                                             // 1 clock cycle
      a = 666; b = 777; mult();                                                           // 2 clock cycle
      
      // now do some constrained random test
      for (k = 0; k < 1000; k++)
      begin
         a = $urandom_range(1,(1<<N)-1);
         b = $urandom_range(1,(1<<N)-1);
         mult();
      end
      
//      is_signed = TRUE;
//      sa = 17;  sb = 5;  smult;
//      sa = 17;  sb = -5; smult;
//      sa = -17; sb = 5;  smult;
//      sa = -17; sb = -5; smult;
//      
//      // constrained random test
//      for (k = 0; k < 10000; k++)
//      begin
//         sa = $signed($urandom_range(1,(1<<N)-1));
//         sb  = $signed($urandom_range(1,(1<<N)-1));
//         smult();
//      end

      // display results of non-zero bins
      for (k = 1; k < N; k++)
      begin
         if (record_bin[k] != 0)
            $display("clock cycles[%0d]  : %0d multiply operations", k, record_bin[k]);
      end
      $display("Note: Any unlisted clock cycles[N] had NO multiply operations. N = %0d", N);
       
      `DelayClockCycles(5);
      $display("Simulation passed.");
      $stop;
   end
   
   //---------------------------------------------------------------------------------------------
   // Generate 1 Mhz clock - doesn't really matter for simulation since RTL logic models no delays
   //---------------------------------------------------------------------------------------------
   
	initial
	begin
		clk_100 = 1'b0;
		#44 // simulate some startup delay
		forever
      begin
			clk_100 = #500 ~clk_100;
      end
	end
   
   always_ff @(posedge clk_100)
   begin
      if (reset)
         clock_cycle <= 0;
      else
         clock_cycle <= clock_cycle + 1;
   end

   task mult;   
      start = TRUE;
      do
         @(negedge clk_100);
      while (!done);
      
       r = a*b;
      
      // Auto check results and display error if mismatches occur
      if (r != result)
      begin
         $display("Error: Multiply: a = %0d, b = %0d, result was %0d, but should have been %0d", a, b, result, r);
         $stop;
      end
      
      @(posedge clk_100);
      start = FALSE;          // must remain TRUE until "done"
      @(posedge clk_100);     // couple clocks of delay between divide operations
      @(posedge clk_100);
   endtask
   
   mult_N_by_N #(N) mult1 (clk_100, reset, is_signed, start, done, a,b,result);
   
   
   
   task smult;   
      sstart = TRUE;
      do
         @(negedge clk_100);
      while (!sdone);
      

      sr = sa*sb;
      // Auto check results and display error if mismatches occur
      if (sr != sresult)
      begin
         $display("Error: Multiply: a = %0d, b = %0d, result was %0d, but should have been %0d", a, b, sresult, sr);
         $stop;
      end
      
      @(posedge clk_100);
      sstart = FALSE;         // must remain TRUE until "sdone"
      @(posedge clk_100);     // couple clocks of delay between divide operations
      @(posedge clk_100);
   endtask
   
   mult_N_by_N #(N) mult2 (clk_100, reset, is_signed, sstart, sdone, sa,sb,sresult);
   
   integer clk_cnt;
   always
   begin
      if (reset)
      begin
         clk_cnt     = 0;
         record_bin  = '{default: '0};
      end
      
      @ (negedge clk_100);
      if ((start & !is_signed) | (sstart & is_signed))
      begin
         clk_cnt++;
         if ((done & !is_signed) | (sdone & is_signed))
            record_bin[clk_cnt] += 1;  // took clk_cnt cycles. so increment record_bin[clk_cnt]
      end
      else
         clk_cnt = 0;
   end
endmodule
