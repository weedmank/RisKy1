****************************************************************************************

				RisKy1 CPU Packages Source Code Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

This folder contains peripherals that can be used for simulation purposes with RisKy1.
They are typically used in the sim folder in testbenches to create a complete system
that can simulate running code on RisKy1.

- L1_dcache.sv    Used in simulation testbenches
- L1_dcache_ff.sv Just experimental for now
- L1_icache.sv    Used in simulation testbenches
- L1_icache_ff.sv Just experimental for now
- cache_arbiter   Simple arbiter to arbitrate between I$ and D$ to/from System Memory
- peripheral_intf.sv Interface definitions

****************************************************************************************
