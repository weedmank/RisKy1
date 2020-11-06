****************************************************************************************

				RisKy1 CPU Source Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

Main System Verilog folders needed to create an RV32i type cpu core
- cpu_src:     contains the source files needed to create an RV32i type cpu core
- debug:       contains a disassembler that will produce strings that can be used in simulation
               to see a disassembled 32 or 16 bit instruction instead of looking at its 32 bit value
- emu:         This folder contains an Emulation CPU model that can be used to verify the operation
               of the RV32imc RisKy1_core. These files are from a separate project.
- includes:    contains mostly SV code files that are "included" as in-line code in the CSR Functional Unit
               in order to keep the size of the csr_fu.sv file smaller/more readable.  These are not what
               one would think of as "include" files. The other file is an "include" for the single precision
               floating point functional unit to also keep the code size smaller/more readable.
- models:      Two behavioral models. One for simulation purposes of System Memmory and the other for a
               cache arbiter with system memory.
- peripherals: L1 Instruciton and Data Caches and a cache arbiter
- pkg:         Various System Verilog Packages that most src files need
- sva:         A few simple System Verilog Assertion filess that are used in a testbench (see sim folder) and then
               bound to various modules.  Also contains RV_EMU_asserts that creates assertions that use the 
               .../emu/RV_EMU_core.sv CPU model to create hundreds of property assertions based on the design
               options specified in .../pkg/cpu_params_pkg.sv and in any build scripts
- vivado:      Wrappers for use in creating a Vivado Block Design
 
****************************************************************************************
