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

# Synthesizable options
# base CPU is RV32I - add one or more of the following to +define+ to implement
# ext_A        // RISC-V extension: Atomic operations             - not available yet - some "hooks" have been added to decode_core_RV.sv
# ext_C        // RISC-V extension: Compressed instruction set    - see modules decode_core_RV.sv, csr.sv, fetch.sv
# ext_F        // RISC-V extension: Single Precision FPU          - not available yet - some "hooks" have been added to decode_core_RV.sv
# ext_M        // RISC-V extension: Integer MUL/DIV/REM           - Integer Multiply/Divide/Remainder
# ext_N        // RISC-V extension: User Level Interrupts         - see risv-spec.pdf
# ext_S        // Add Supervisor Mode
# ext_U        // Add User Mode
# ext_ZiF      // Add Fence instructions
# add_DM       // Add Debug Module (includes Debug Registers)     - not available yet - some registers have been added to csr_wr_mach.sv.sv
# use_MHPM     // Add up to 29 MHPM counters to the design.  NUM_MHPM must be also set. See cpu_params_pkg.sv

# Non-synthesizable options
# USE_ASSERTS // Should be defined when needing to bind asssertions to the RisKy1 core - see file top_tb1.sv
# SIM_DEBUG    // SHould be defined when using simulation testbenches so the the sim_stop signal is generated when a write occurs to address Sim_Stop_Addr. see cpu_params_pkg.sv

# NOTE1: If SIM_DEBUG is needed in one group, then it should be used in all groups. Same reasoning goes for use_xxx
# NOTE2: All  +define+SIM_DEBUG +define+FORMAL, +USE_ASSERTS defines should be removed if doing synthesis for FPGA or ASIC

rm -rf work/*
rm -rf tcl_stacktrace.*
rm -rf *.wlf

# Package Folder Files +ext_M +define+SIM_DEBUG +define+FORMAL
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/pkg/logic_params_pkg.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/pkg/functions_pkg.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/pkg/cpu_params_pkg.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/pkg/cpu_structs_pkg.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/pkg/csr_params_pkg.sv

# Interfaces
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/cpu_src/cpu_intf.sv

# Debug Files
vlog  -sv          +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/debug/disasm_RV.sv

# RTL Synthesizable Files
#         +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/alu_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/br_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/csr_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/csr_regs.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/csr_sel_rdata.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/decode.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/decode_core.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/execute.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/fetch.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/fpr.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/gpr.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/idr_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/im_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/irq.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/ls_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/mem.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/mode_irq.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/pipe.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover    +incdir+../../src/includes    ../../src/cpu_src/RisKy1_core.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/sdiv_N_by_N.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/spfp_fu.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/vedic_mult16x16.v
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/vedic_mult32x32.v
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL  +cover                                  ../../src/cpu_src/wb.sv


# no +define+ to be used with caches
# caches are synthesizable but not practical as they produce flip flops for memory - work in progress to change them
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                          ../../src/peripherals/peripheral_intf.sv
vlog  -sv                                                                                                         ../../src/peripherals/L1_dcache.sv
vlog  -sv                                                                                                         ../../src/peripherals/L1_icache.sv
vlog  -sv                                                                                                         ../../src/peripherals/cache_arbiter.sv

# Models - non synthesizable. Note: arb_sysmem_model affectively substitutes for cache_arbiter + sys_mem_model
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL +define+TEST_FILE=\"instr_tests/factorial.rom\"  ../../src/models/sys_mem_model.sv

# Top Level Simulation File - add +USE_ASSERTS if doing assertion testing
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL+USE_ASSERTS                             top_tb1.sv
#vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                        top_tb1.sv

# Questa Formal Properties files - not available to public
 vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/questa_formal/property_checks/RV32imc_params_pkg.sv
 vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/questa_formal/property_checks/RV32imc_model.sv
 vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL   +incdir+../../src/questa_formal/property_checks ../../src/questa_formal/property_checks/RV32imc_asserts.sv
# #vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/questa_formal/property_checks/RV32imc_model.svp
# #vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL   +incdir+../../src/questa_formal/property_checks ../../src/questa_formal/property_checks/RV32imc_asserts.svp

# Assertion/Property Files
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/sva/csr_asserts.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/sva/gpr_asserts.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/sva/mem_asserts.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/sva/wb_asserts.sv
vlog  -sv +define+ext_M +define+ext_C +define+ext_S +define+ext_U +define+ext_N +define+SIM_DEBUG +define+FORMAL                                                   ../../src/sva/pipe_asserts.sv

view assertions
view structure

# For use in Questasim
#vsim -assertdebug -coverage -voptargs=+acc -t 1ps top_tb1
# -c option is for No GUI (i.e. command line)
#vsim -assertdebug -coverage -voptargs="+access=rw+/." -t 1ps top_tb1
vsim -assertdebug -coverage -voptargs="+acc" -t 1ps top_tb1
#toggle add top_tb1:/RK1/*

#For use with free version of Modelsim
#vsim -assertdebug -voptargs=+acc -t 1ps +autofindloop top_tb1
#vsim  -assertdebug -voptargs=+acc -t 1ps top_tb1


do wave_tb1.do
run -all
#coverage save jf_coverage.ucdb
#vcover   report -html jf_coverage.html
coverage report -output jf_coverage.rpt
