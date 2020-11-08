****************************************************************************************

				RisKy1 System Verilog Assertion Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

This folder contains System Verilog Assertions that can be used to verify the operation of the CPU.
These files are instantiated in the top level testbench file (see RisKy1/design/sim/risky1-core/top_tb1.sv)
and are bound to the RisKy1-core as follows:

   `ifdef BIND_ASSERTS
// Usable in Questasim
// cmd    DUT-module-name   module-name         instance-name ...
   bind   RK1               RV32_EMU_asserts    b1 (.*);
   bind   RK1.GPR           gpr_asserts         b2 (.*);
   bind   RK1.WB            wb_asserts          b3 (.*);
   bind   RK1.MEM           mem_asserts         b4 (.*);
   bind   RK1.EXE.CSRFU     csr_asserts         b5 (.*);
   `endif


- RV_EMU_asserts

   bound to the top level of the design RK1 (RisKy1-core.sv)
   
- gpr_asserts

   bound to RK1.GPR (gpr.sv) which contains the CPU's Architectural Registers (X0-X31)
   
- wb_asserts

   bound to RK1.WB (wb.sv) which is the Write Back Stage of the CPU 
   
- mem_asserts

   bound to RK1.MEM (mem.sv) which is the Memory Stage of the CPU
   
- csr_asserts

   bound to RK1.EXE.CSRFU (csr_fu.sv) which is the Control & Status Register module
   inside the Execute stage (execute.sv)

- pipe_asserts:  not yet added...

Notice that all of these assertions can be turned on/off by whether or not BIND_ASSERTS
is defined.
 
****************************************************************************************
