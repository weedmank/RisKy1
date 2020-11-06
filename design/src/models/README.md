****************************************************************************************

				RisKy1 Models Folder

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

FOLDER ORGANIZATION:

- arb_sysmem_model.sv

   Currently not being used but contains a model for System Memory and a simple arbiter.
   
         
- sys_mem_model.sv
   
   This is a model (behavioral code and thus not synthesizable) of System Memory that is
   currently used in the RisKy1/design/sim/risky1-core testbench top_tb1.sv.  It interfaces
   to RisKy1/design/src/peripherals/cache_arbiter.sv which is a simple module that
   arbitrates bewteen an L1 Data Cache (RisKy1/design/src/peripherals/L1_dcache.sv) and
   an L1 Instruction Cache (RisKy1/design/src/peripherals/L1_dcache.sv).  The L1 caches
   also connect to the RisKy1_core.sv to create an entire system capable of running
   software simulation tests.  Notice that this "System Memory" can be preloaded at simulation
   time 0 with the contents of the program to run by use of the following line in this module.
   
   $readmemh(`TEST_FILE, tmp_mem); // all hex data must be organized in chunks of 4 bytes and be in proper ENDIAN format

   `TEST_FILE is a macro and that macro is defined by the user setting this to the correct file
   containing 32-bit ascii hex instrcutions. For the RisKy1/design/sim/risky1-core testbench,
   this will be found in top_tb1.do
   
   vlog  -sv -hazards +define+TEST_FILE=\"instr_tests/factorial.rom\"        ../../src/models/sys_mem_model.sv
   
   
   In the above example, it will load the contents of RisKy1/design/sim/risky1-core/instr_tests/factorial.rom
   
   
   NOTE: depending on the size of a program, more memory space may need to be allocated.
   This can be done by changeing the following in RisKy1/design/src/pkg/cpu_params_pkg.sv
   
   Phys_Depth = 8192;
   
   In the risky1-core testbench simulation, the code being run in simulation sets the stack
   pointer to the end of the System Memory block (highest address) and the code is placed
   starting at address 0 (lowest address)
   
   If the code and stack pointer collide...well.. you know the story...

****************************************************************************************
