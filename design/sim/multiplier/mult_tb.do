
# Simulation Files
vlog  -sv                      +incdir+../../src/includes  mult_tb.sv

# RTL Synthesizable Files
vlog  -sv -hazards             +incdir+../../src/includes  ../../src/cpu_src/mult_N_by_N.sv


view assertions
view structure

vsim -assertdebug -voptargs=+acc -t 1ps mult_tb

do wave_mult.do
run -all