****************************************************************************************

				RisKy1 CPU Core Source Code Files

    RisKy1 CPU - A highly parameterized, 5 stage pipelined CPU based on RISC-V ISA
----------------------------------------------------------------------------------------

      Author: Kirk Weedman (kirk@hdlexpress.com)
    Position: Design/Verification Engineer (Project Owner)
Organization: HDLexpress.com

----------------------------------------------------------------------------------------

Main System Verilog files needed to create an RV32i type cpu core
- Top level module - RisKy1_core.sv
- Main pipeline stages - fetch.sv, decode.sv/decode_core.sv, execute.sv, mem.sv, wb.sv
- The architectural registers (or General Purpose Registers) - gpr.sv
- Core functional units used inside the execute stage - alu_fu.sv, br_fu.sv, csr_fu.sv, ls_fu.sv
- Control & Status Registers support files - csr_lo_cnt.sv, csr_std_wr.sv
- pipelining registers - pipe.sv
- Interrupt logic - irq.sv
- Memory and I/O (internal and external I/O) - mem_io.sv
- Optional functional units - im_fu.sv, idr_fu.sv
- Optional multipliers - 32 x 32 bit Vedic (vedic_mult16x16, vedic_mult32x32), mult_N_by_N.sv
- Optional single precision floating point functional unit (not complete yet) - spfp_fu.sv
 
****************************************************************************************
