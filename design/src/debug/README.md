****************************************************************************************

				RisKy1 Debug File

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

This folder only contains one file: disasm.sv

- This file is not used when creating a physical CPU. Its purpose is for simulation debugging.
- This module has two inputs as follows
   1. dm: This bit specifies the output format of the two strings that get produced by this module
      A. dm = ASSEMBLY produces a format like this:      lw rd, imm(rs1)
      B. dm = SEMANTICS tends to produce a format like:  R[rd] = i_imm(R[rs1])
   2. ipd: This structure includes both the 32-bit instruction and Program Counter
- This module produces 2 strings. One for the disassembly of the instruction and one for the program counter.
   1. i_str: instruciton disassembly
   2. pc_str: program counter shown in hex format
   
   This file may not be competely accurate yet, but has been very useful in debugging code
   running in simulation. It is much easier to read a disassembly of an instruction than
   to stare and wonder what some 32-bit ASCII Hex value represents.
   
- How this disassembler is used.

   It is currently used in various modules such as decode.sv by instantiating inside an
   `ifdef statement.  This is due to this module is NOT synthesizable and should only be
   included when doing verification/debugging.  BGelow is an example taken from decode.sv
   
   
   //------------------------------- Debugging: disassemble instruction in this stage ------------------------------------
   `ifdef SIM_DEBUG
   string   i_str;
   string   pc_str;

   disasm dec_dis (ASSEMBLY,F2D_bus.data.ipd,i_str,pc_str); // disassemble each instruction
   `endif
   //---------------------------------------------------------------------------------------------------------------------

   In this case, the code is only included if SIM_DEBUG is defined. SIM_DEBUG can be simply defined at
   compile time, such as the following Modelsim/Questasim command line.  Notice that a number does not
   have to be assigned to SIM_DEBUG. Just the "+define+SIM_DEBUG" makes it defined.
   
   vlog  -sv -hazards +define+SIM_DEBUG  ../../src/cpu_src/decode.sv
   
****************************************************************************************
