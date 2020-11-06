****************************************************************************************

				RisKy1 VIVADO Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

Files that can be used to create a Vivado Block design. (work in progress...)

Due to Vivado (2019.2 and older, maybe even newest version) CANNOT instantiate a top level
module with System Verilog syntax, a wrapper file must be create that is in pure Verilog code. :(

- RisKy1_RV32im.v

   This is the "wrapper" file that has just Verilog syntax so that this module can be instantiated
   in a Vivado Block Design.
   
- vivado_global_macros.h

   This file must be declared as a global file as it contains definitions for the compiling of
   RisKy1_core.sv. Currently it just contains the following to produce and RV32im type cpu
   
   `define VIVADO=1
   `define ext_M=1
   
   The VIVADO definition controls the format of the module port definitions in RisKy1_core.sv
   so that the interface will contain ONLY Verilog syntax, which is then used in the "wrapper".
   
   Other definitions such as the following can be used in the future once this is ready.
   
   `define ext_S=1
   `define ext_U=1
   `define ext_C=1
   ...etc..

****************************************************************************************
