****************************************************************************************

				RisKy1 includes Folder

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

- cpu_checks.svh

   uses a generate statement to include some compile time checks to make sure that
   user CPU parameters are within the confines of the ISA and the current design. Users
   can change certain paramters located in the pkg folder in the cpu_params_pkg.sv file
   Notice that this file is included in ../cpu_src/RisKy1_core.sv
         
- csr_checks.sv
   
   uses a generate statement to include some compile time checks to make sure that
   user CSR parameters are within the confines of the ISA and the current design. Users
   can change certain paramters located in the pkg folder in the csru_params_pkg.sv file
   Notice that this file is included in ../cpu_src/RisKy1_core.sv
   
- spfp_instr_cases.svh

   This file is incomplete and not currently used. This is the beginning of code related
   to Single Precision Floating Point (which is also not implemented yet).
   Notice that this file is included in ../cpu_src/wb.sv
****************************************************************************************
