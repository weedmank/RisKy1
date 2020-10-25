
# Simulation Files
vlog  -sv                      +incdir+../../src/includes  sdiv_tb.sv

# RTL Synthesizable Files
vlog  -sv -hazards             +incdir+../../src/includes  ../../src/cpu_src/sdiv_N_by_N.sv


view assertions
view structure

vsim -assertdebug -voptargs=+acc -t 1ps sdiv_tb

do wave_sdiv.do
run -all