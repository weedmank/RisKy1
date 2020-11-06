****************************************************************************************

				RisKy1 CPU Core Source Code Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

Main System Verilog files needed to create an RV32i type cpu core
- Top level module
   - RisKy1_core.sv: Top level of RisKy1 CPU core.  Interfaces for interrupts, L1D$, L1I$ and external I/O space
- Main pipeline stages
   - fetch.sv: Fetch stage of pipeline
   - decode.sv/decode_core.sv: Decode stage of pipeline
   - execute.sv: Execute stage of pipeline
   - mem.sv: Memory stage of pipeline
   - wb.sv: Write Back stage of pipeline
- The architectural registers (or General Purpose Registers)
   - gpr.sv: 32x32 Architectural Registers
- Core functional units used inside the execute stage
   - alu_fu.sv: ALU Functional Unit
   - br_fu.sv: Branch/Jump Functional Unit
   - csr_fu.sv: Control & Status Registers Functional Unit
   - ls_fu.sv: Load/Store Functioal Unit
- Control & Status Registers support files
   - csr_lo_cnt.sv: Control & Status Registers - Privileged read access counter. Resets to an INIT_VALUE and then begins counting by 1 every clock cycle. 
   - csr_std_wr.sv: Control & Status Registers - Size definable. Privileged Write access register. Resets to an INIT_VALUE. Each bit is maskable.
- pipelining registers
   - pipe.sv:  Used as pipeline registers between various stages
- Interrupt logic
   - irq.sv: External interrupt Pending signal input
- Memory and I/O (internal and external I/O)
   - mem_io.sv
- Other files
   - cpu_intf.sv: SV Interface Definitions used throughout the design
- Optional functional units
   - im_fu.sv: Integer 32x32 Multiplier Functional Unit (vedic_mult16x16.v, vedic_mult32x32.v, or mult_N_by_N.sv)
   - idr_fu.sv: Integer 32x32 Divide and Remainder functional Unit
   - spfp_fu.sv: Single Precision Floating Point Functional Unit (future)
 
****************************************************************************************
