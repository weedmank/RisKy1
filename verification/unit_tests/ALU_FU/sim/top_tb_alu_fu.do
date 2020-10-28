vlog  -sv +incdir+../../src/includes     ../../../../design/src/pkg/logic_params_pkg.sv
vlog  -sv +incdir+../../src/includes     ../../../../design/src/pkg/functions_pkg.sv
vlog  -sv +incdir+../../src/includes     ../../../../design/src/pkg/cpu_params_pkg.sv
vlog  -sv +incdir+../../src/includes     ../../../../design/src/pkg/cpu_structs_pkg.sv
#vlog  -sv +incdir+../../src/includes     ../../../../verification/unit_tests/ALU_FU/AFU_intf.sv
vlog  -sv +incdir+../../src/includes     ../../../../design/src/cpu_src/alu_fu.sv
vlog  -sv +incdir+../../src/includes     ../../../../verification/unit_tests/ALU_FU/TGDMS_afu.sv
vlog  -sv +incdir+../../src/includes     ../../../../verification/unit_tests/ALU_FU/environment.sv
vlog  -sv +incdir+../../src/includes     ../../../../verification/unit_tests/ALU_FU/random_test.sv
vlog  -sv +incdir+../../src/includes     ../../../../verification/unit_tests/ALU_FU/tb_alu_fu.sv

vsim -assertdebug -voptargs=+acc -t 1ps tb_alu_fu

run -all