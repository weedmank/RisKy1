****************************************************************************************

				RisKy1 CPU Packages Source Code Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

System Verilog Packages used as imports into the CPU design files
- cpu_params_pkg.sv

   Contains parameters and localparams. In general localparams are based on parameters and
   shouldn't be changed by the user.  Paameters in this file can typically be changed by
   the user unless noted otherwise.

- cpu_struct_pkg.sv

   Structures that are used throughout the design

- functions.sv:

   compile time functions - currently just 1 function. This is still in use
   from when the design was initially created with no System Verilog
   - bit_size(): Determines the number of bits required to hold a specific value

- logic_params_pkg:

   localparams for TRUE, FALSE, ONE, ZERO

****************************************************************************************
