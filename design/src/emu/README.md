****************************************************************************************

				RisKy1 Emulation Folder

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------
# EMU Folder

RV_EMU_core.sv       - RV32imc cpu emulator. Used for property verification where emulator cpu signals can be used to compare against the RTL RisKy1 cpu core
RV_EMU_params_pkg.sv - supporting package for RV_EMU_core.sv

These files are used in ../sva/RV_EMU_asserts.sv

These files are IP from a non-released Formal Property Verification project I am working on. However I am releasing a portion of the project as
encrypted IP for adaptation and use for debugging this CPU. RV_EMU_core is an Emulation CPU that is used to compare it's information with that
created by the RTL CPU (RisKy1) 
