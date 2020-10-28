****************************************************************************************

				RisKy1 Design Folders

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

- sim:   Used to hold various simulation tests. Each test has a separate folder such as 
         the risky1-core folder which contains a Modelsim/Questasim project that will run
         a simulation of a small program on the RisKy1 CPU.
         
- src:   contains various RisKy1 CPU design folders, each containing Verilog, System Verilog,
         include, packages, etc. files used to create an RV32i type cpu core.
 
****************************************************************************************
