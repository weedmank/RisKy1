// ----------------------------------------------------------------------------------------------------
// Project       :  Verification of RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// File          :  random_test.sv
// Description   :  
// Passes the interface signals to the testbench environment class
// Sets the repeat_count which controls the number of test cases.
// Creates the environment handle and runs the class based testbench.
//
// TB Designer      :  Abhishek Yadav
// References : https://verificationguide.com/
// ----------------------------------------------------------------------------------------------------

// Include the environment file which instantiates and runs all the test-bench components
`include "environment.sv"

program test(AFU i_intf);

	//declaring environment instance;
	environment env;

	initial begin
	// creating environment
		env = new(i_intf);

	// setting the repeat count of generator as 4
	// to generate 4 random pockets
		env.gen.repeat_count = 100;

	// calling run task from env
		env.run();

	end


endprogram
