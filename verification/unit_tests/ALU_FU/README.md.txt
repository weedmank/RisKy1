****************************************************************************************

				VERIFICATION EFFORT

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Abhishek Yadav (ya.abhishek@gmail.com)
    Position: Design Verification Engineer (Volunteer)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

Unit tests for "alu_fu" unit in design/src/cpu_src

Testbench features
- Object oriented based testbench creation
- UVM style testbench components - Transaction, Generator, Driver, Monitor, Scoreboard
- Random tests based on constrained randomization.
- Functional coverage manually created by implementing counters. 
- Parameteriezed to add more random test cases.
- Coverage report provides the testbench results.
 
****************************************************************************************

FILE ORGANIZATION:

1. DUT and includes, packages:
Design Under Test   : \design\src\cpu_src\alu_fu.sv
Packages            : \design\src\pkg\cpu_params_pkg.sv
Packages            : \design\src\pkg\cpu_structs_pkg.sv
Packages            : \design\src\pkg\functions_pkg.sv
Packages            : \design\src\pkg\logic_params_pkg.sv

2. Testbench components, environment and top level files:
Top level testbench : \verification\unit_tests\ALU_FU\tb_alu_fu.sv
Random tests        : \verification\unit_tests\ALU_FU\randon_test.sv
Test Environment    : \verification\unit_tests\ALU_FU\environment.sv
Test Interface      : \verification\unit_tests\ALU_FU\AFU_intf.sv
Test Components     : \verification\unit_tests\ALU_FU\TGDMS_afu.sv

3. Simulation related files:
.do file for simulation run : \verification\unit_tests\ALU_FU\sim\top_tb_alu_fu.do
Test transcript		    : \verification\unit_tests\ALU_FU\sim\AFU_Unit_test_transcript.txt
Questasim Project file      : \verification\unit_tests\ALU_FU\sim\AFU_Unit_test.mpf



