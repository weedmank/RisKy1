# ----------------------------------------------------------------------------------------------------
# Creative Commons - Attribution - ShareAlike 3.0
# Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
# Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
# see http://creativecommons.org/licenses/by/3.0/
# ----------------------------------------------------------------------------------------------------
# Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
# Editor        :  Notepad++
# File          :  top_tb1.do - Top Level RisKy1 build for Modelsim
# Description   :  new RV32IM  architect tailored to the RISC_V 32bit ISA
#               :
# Designer      :  Kirk Weedman - kirk@hdlexpress.com
# ----------------------------------------------------------------------------------------------------
# Note: Even though ext_C is used in the compile below, it has NOT been tested yet.

# base CPU is RV32I - add one or more of the following to +define+ to implement
# ext_A        // RISC-V extension: Atomic operations             - not available yet - some "hooks" have been added to decode_core_RV.sv
# ext_C        // RISC-V extension: Compressed instruction set    - see modules decode_core_RV.sv, csr.sv, fetch.sv
# ext_F        // RISC-V extension: Single Precision FPU          - not available yet - some "hooks" have been added to decode_core_RV.sv
# ext_M        // RISC-V extension: Integer MUL/DIV/REM           - Integer Multiply/Divide/Remainder
# ext_N        // RISC-V extension: User Level Interrupts         - see Ch.18 risv-spec-v2.2
#                                                                 - see modules cpu_params_RV.svh, kpu_core.sv, rs.sv, csr.sv,decode_core_RV.sv
# ext_S        // Add Supervisor Mode
# ext_U        // Add User Mode
# ext_ZiF      // Add Fence instructions
# add_DMR      // Add Debug Mode Registers                        - Debug mode registers
# BIND_ASSERTS // Should be defined when needing to bind asssertions to the RisKy1 core - see file top_tb1.sv

# NOTE1: If SIM_DEBUG is needed in one group, then it should be used in all groups. Same reasoning goes for use_xxx
# NOTE2: All +SIM_DEBUG, +BIND_ASSERTS defines should be removed if doing synthesis for FPGA or ASIC

# Package Files
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/pkg/functions_pkg.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/pkg/logic_params_pkg.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/pkg/cpu_params_pkg.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/pkg/cpu_structs_pkg.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/pkg/cpu_intf_pkg.sv

# Assertion/Property Files
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/sva/csr_asserts.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/sva/gpr_asserts.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/sva/mem_asserts.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/sva/wb_asserts.sv

# Debug Files
vlog  -sv          +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                ../../src/debug/disasm_RV.sv

# RTL Synthesizable Files
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/alu_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/br_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_av_rdata.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_ff.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_lo_cnt.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_nxt_reg.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/csr_regs.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/decode.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/decode_core.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/execute.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/fetch.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/fpr.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/gpr.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/idr_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/im_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/irq.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/ls_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/mem.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/mem_io.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/pipe.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/RisKy1_core.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/sdiv_N_by_N.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/spfp_fu.sv
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/vedic_mult16x16.v
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/vedic_mult32x32.v
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG  +cover                                        ../../src/cpu_src/wb.sv


# Model files (caches are synthesizable but not practical as they produce flip flops)
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG+TEST_FILE=\"instr_tests/factorial.rom\"        ../../src/models/mem_arb_model.sv
#vlog  -sv          +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG+TEST_FILE=\"instr_tests/rand.rom\"             ../../src/models/mem_arb_model.sv

# no +define+ to be used with caches
vlog  -sv -hazards                                                                                           ../../src/models/L1_dcache.sv
vlog  -sv -hazards                                                                                           ../../src/models/L1_icache.sv

# Top Level Simulation File - add +BIND_ASSERTS if doing assertion testing
vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG+BIND_ASSERTS                                   top_tb1.sv
#vlog  -sv -hazards +define+ext_M+ext_N+ext_S+ext_U+SIM_DEBUG                                                 top_tb1.sv

view assertions
view structure

# For use in Questasim
#vsim -assertdebug -coverage -voptargs=+acc -t 1ps top_tb1
# -c option is for No GUI (i.e. command line)
vsim -assertdebug -coverage -voptargs=+acc -t 1ps top_tb1
#toggle add top_tb1:/RK1/*

#For use with free version of Modelsim
#vsim -assertdebug -voptargs=+acc -t 1ps top_tb1


do wave_tb1.do
run -all