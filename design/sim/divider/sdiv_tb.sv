// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  sdiv_tb.sv - test bench for sdiv_N_by_N.sv
// Description   :  new RV32IM  architect tailored to the RISC_V 32bit ISA
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

module  sdiv_tb();

   parameter N = 32;                   // 32 x 32 bit signed and unsigned divide test
   
   logic             reset;
   logic             clk_100;
   logic             debug;
   integer           clock_cycle;
   logic             start;
   logic             done;
   logic     [N-1:0] dividend;
   logic     [N-1:0] divisor;
   logic     [N-1:0] quotient;
   logic     [N-1:0] remainder;
   logic             div_by_0_err,overflow_err;
   logic             is_signed;
   logic             sstart;
   logic             sdone;
   logic signed     [N-1:0] sdividend;
   logic signed     [N-1:0] sdivisor;
   logic signed     [N-1:0] squotient;
   logic signed     [N-1:0] sremainder;
   logic                    sdiv_by_0_err,soverflow_err;
   
   // N = number of bits for dividend and divisor. Record how many divides take N cycles
   // Example: record_bin[9] will record the number of divides that took 9 clock cycles
   logic    [N-1:0] [31:0] record_bin; 
   
   localparam TRUE = 1'b1;
   localparam FALSE = 1'b0;
   
`define DelayClockCycles(a) \
   repeat (a) @(posedge clk_100)
   
   integer k, num_div;
   
   initial
   begin
      start    = FALSE;
      sstart   = FALSE;
      debug    = FALSE;
      reset    = TRUE;
      dividend = 0;
      divisor  = 0;
      sdividend = $signed(dividend);
      sdivisor  = $signed(divisor);
      
      `DelayClockCycles(50);
      reset    = 1'b0;
      $display("Reset completed, Simulation started.");
      
      @(posedge clk_100);
      @(posedge clk_100);
      
      //-----------------------------------------------------------------------------
      // unsigned division tests
      //-----------------------------------------------------------------------------
      is_signed = FALSE;   // first tests are unsigned 32 x 32 bit divide
      
      num_div = 0;
      
      // initial tests used to check/debug sdiv_N_by_N.sv
      dividend = 0; divisor = 12345678; udiv();                                                     num_div++; // 1 clock cycle
      dividend = 9; divisor = 1; udiv();                                                            num_div++; // 1 clock cycle
      dividend = 9; divisor = 2; udiv();                                                            num_div++; // 1 clock cycle
      dividend = 9; divisor = 3; udiv();                                                            num_div++; // 2 clock cycles
      dividend = 9; divisor = 4; udiv();                                                            num_div++; // 1 clock cycle
      dividend = 90234; divisor = 4; udiv();                                                        num_div++; // 1 clock cycle
      dividend = 90210; divisor = 234; udiv();                                                      num_div++; // 4 clock cycles
      dividend = 1234567890; divisor = 9302; udiv();                                                num_div++; // 7 clock cycles
      dividend = 12; divisor = 3; udiv();                                                           num_div++; // 2 clock cycles
      dividend = 83474; divisor = 173; udiv();                                                      num_div++; // 6 clock cycles
      dividend = 666; divisor = 0; udiv();                                                          num_div++; // 1 clock cycle
      dividend = 1<<31; divisor = 3; udiv();                                                        num_div++; // 16 clock cycles
      dividend = 0; dividend[31] = 1'b1; dividend[29]=1'b1; divisor = 3; udiv();                    num_div++; // 17 clock cycles
      dividend = 0; dividend[31] = 1'b1; dividend[29]=1'b1; dividend[27]=1'b1; divisor = 3; udiv(); num_div++; // 4 clock cycles
      dividend = 0; dividend[31] = 1'b1; dividend[29]=1'b1; dividend[17]=1'b1; divisor = 3; udiv(); num_div++; // 9 clock cycles
      dividend = -1; dividend =  dividend >> 1; divisor = 3; udiv();                                num_div++; // 16 clock cycles
      
      // constrained random test
//      for (k = 0; k < 1000000; k++)
//      begin
//         dividend = $urandom_range(1,(1<<N)-1);
//         divisor  = $urandom_range(1,(1<<N)-1);
//         udiv();
//         num_div++;
//      end
      
      //-----------------------------------------------------------------------------
      // signed division tests
      //-----------------------------------------------------------------------------
      is_signed = TRUE;
      
      sdividend = 17;  sdivisor = 5;  sdiv(); num_div++;
      sdividend = 17;  sdivisor = -5; sdiv(); num_div++;
      sdividend = -17; sdivisor = 5;  sdiv(); num_div++;
      sdividend = -17; sdivisor = -5; sdiv(); num_div++;
      
      // constrained random test
      for (k = 0; k < 10000; k++)
      begin
         sdividend = $signed($urandom_range(1,(1<<N)-1));
         sdivisor  = $signed($urandom_range(1,(1<<N)-1));
         sdiv();
         num_div++;
      end

      //-----------------------------------------------------------------------------
      // display results of non-zero record bins
      //-----------------------------------------------------------------------------
      for (k = 0; k < N; k++)       // k = number of clock cycles the division took to complete
      begin
         if (record_bin[k] != 0)    // record_bin[k] holds total divisions that took k clock cycles to complete
         begin
            if (k == 1)
               $display("%0d of the total number of divisions took 1 clock cycle to complete", record_bin[k]);
            else
               $display("%0d of the total number of divisions took %0d clock cycles to complete", record_bin[k], k);
         end
      end
      $display("There were a total of %0d divisions for this test", num_div);
      
      `DelayClockCycles(5);
      $display("Simulation passed.");
      $stop;
   end // of testbench simulation
   
   
   //-----------------------------------------------------------------------------
   // Generate 100 Mhz clock
   //-----------------------------------------------------------------------------
   
	initial
	begin
		clk_100 = 1'b0;
		#44 // simulate some startup delay
		forever
      begin
			clk_100 = #5 ~clk_100;
      end
	end
   
   always_ff @(posedge clk_100)
   begin
      if (reset)
         clock_cycle <= 0;
      else
         clock_cycle <= clock_cycle + 1;
   end

   //-----------------------------------------------------------------------------
   // task and module instantiation for unsigned division
   //-----------------------------------------------------------------------------
   integer q, r;
   task udiv;   
      start = TRUE;
      do
         @(negedge clk_100);
      while (!done);
      
      // The following displays are for displaying results for each divide - comment out when doing LOTS of divides. Mostly useful when 1 or a few divides are being tested
//      if (quotient == -1) // all bits set? typically returned for divide by 0
//         $display ("%0d/%0d => quotient -1, remainder %0d", dividend,divisor,remainder);
//      else
//         $display ("%0d/%0d => quotient %0d, remainder %0d", dividend,divisor,quotient,remainder); 

      // calculate what the results of this divide SHOULD produce
      if (divisor == 0)
      begin
         q = -1;  // all bits sets - RISCV spec
         r = dividend;
      end
      else
      begin
         q = dividend/divisor;
         r = dividend-(q*divisor);
      end
      
      // Auto check results and display error if mismatches occur
      if (overflow_err)
      begin
         $display("Error: overflow error occured for UNSGINED test. This should never happen. dividend = %0d, divisor = %0d", dividend, divisor);
         $stop;
      end
      else if ((q != quotient) || (r != remainder))
      begin
         if (q == -1)
            $display("Error: results should have been Q = -1, R = %0d", q, r);
         else
            $display("Error: results should have been Q = %0d, R = %0d", q, r);
         $stop;
      end
      
      @(posedge clk_100);
      start = FALSE;          // must remain TRUE until "done"
      @(posedge clk_100);     // couple clocks of delay between divide operations
      @(posedge clk_100);
   endtask
   
   sdiv_N_by_N #(N) div_unsigned (clk_100, reset, is_signed, start, done, dividend,divisor,quotient,remainder,div_by_0_err,overflow_err);
   
   
   //-----------------------------------------------------------------------------
   // task and module instantiation for signed division
   //-----------------------------------------------------------------------------
   integer signed sq, sr;
   task sdiv;   
      sstart = TRUE;
      do
         @(negedge clk_100);
      while (!sdone);
      
      // The following displays are for displaying results for each divide - comment out when doing LOTS of divides. Mostly useful when 1 or a few divides are being tested
//      if (quotient == -1) // all bits set? typically returned for divide by 0
//         $display ("%0d/%0d => quotient -1, remainder %0d", dividend,divisor,remainder);
//      else
//         $display ("%0d/%0d => quotient %0d, remainder %0d", dividend,divisor,quotient,remainder); 

      if (sdivisor == 0)
      begin
         sq = -1;  // all bits sets - RISCV spec
         sr = sdividend;
      end
      else
      begin
         sq = sdividend/sdivisor;
         sr = sdividend-(sq*sdivisor);
      end
      
      // Auto check results and display error if mismatches occur
      if (soverflow_err)
      begin
         $display("Error: overflow error occured for dividend = 0x%0sx, divisor = 0x%0sx", sdividend, sdivisor);
         $stop;
      end
      else if ((sq != squotient) || (sr != sremainder))
      begin
         if (sq == -1)
            $display("Error: results should have been Q = -1, R = %0sd", sq, sr);
         else
            $display("Error: results should have been Q = %0sd, R = %0sd", sq, sr);
         $stop;
      end
      
      @(posedge clk_100);
      sstart = FALSE;         // must remain TRUE until "sdone"
      
      @(posedge clk_100);     // couple clocks of delay between divide operations
      @(posedge clk_100);
   endtask
   
   sdiv_N_by_N #(N) div_signed (clk_100, reset, is_signed, sstart, sdone, sdividend,sdivisor,squotient,sremainder,sdiv_by_0_err,soverflow_err);
   
   //-----------------------------------------------------------------------------
   // Automatic recording of results - how many divisions to N clock cycles
   //-----------------------------------------------------------------------------
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
