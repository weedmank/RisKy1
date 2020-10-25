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
# Simulation Files
vlog  -sv          +define+ext_C+ext_M+ext_N+ext_U+SIM_DEBUG                                       +incdir+../../src/includes  gen_rand_instr.sv

#For use with free version of Modelsim
vsim -assertdebug -voptargs=+acc -t 1ps gen_rand_instr

run -all