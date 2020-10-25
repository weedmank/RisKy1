onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb1/clock_cycle
add wave -noupdate -expand -group top_tb1 /top_tb1/reset
add wave -noupdate -expand -group top_tb1 /top_tb1/clk_100
add wave -noupdate -expand -group top_tb1 /top_tb1/debug
add wave -noupdate -expand -group top_tb1 /top_tb1/sim_stop
add wave -noupdate -expand -group top_tb1 /top_tb1/ic_flush
add wave -noupdate -expand -group top_tb1 /top_tb1/dc_flush
add wave -noupdate -group FET /top_tb1/RK1/FET/clk_in
add wave -noupdate -group FET /top_tb1/RK1/FET/reset_in
add wave -noupdate -group FET /top_tb1/RK1/FET/cpu_halt
add wave -noupdate -group FET /top_tb1/RK1/FET/pc_reload
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/pc_reload_addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/PC
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qcnt
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip_cnt
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/que
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/nxt_que
add wave -noupdate -group FET /top_tb1/RK1/FET/qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qop
add wave -noupdate -group FET /top_tb1/RK1/FET/xfer_out
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_xfer
add wave -noupdate -group FET -radix hexadecimal -childformat {{{/top_tb1/RK1/FET/predicted[7]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[6]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[5]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[4]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[3]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[2]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[1]} -radix hexadecimal} {{/top_tb1/RK1/FET/predicted[0]} -radix hexadecimal -childformat {{addr -radix hexadecimal} {is_br -radix hexadecimal}}}} -subitemconfig {{/top_tb1/RK1/FET/predicted[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/predicted[0]} {-height 15 -radix hexadecimal -childformat {{addr -radix hexadecimal} {is_br -radix hexadecimal}}} {/top_tb1/RK1/FET/predicted[0].addr} {-radix hexadecimal} {/top_tb1/RK1/FET/predicted[0].is_br} {-radix hexadecimal}} /top_tb1/RK1/FET/predicted
add wave -noupdate -group FET -radix binary /top_tb1/RK1/FET/bt
add wave -noupdate -group FET /top_tb1/RK1/FET/addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/Next_PC
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/reload_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/reload_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/clr_rf
add wave -noupdate -group FET /top_tb1/RK1/FET/save_lpa
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_ic_req
add wave -noupdate -group FET /top_tb1/RK1/FET/qfull
add wave -noupdate -group FET /top_tb1/RK1/FET/cc_state
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_cc_state
add wave -noupdate -group FET /top_tb1/RK1/FET/last_predicted_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/lpa
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/ras_ptr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/nxt_ras_ptr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/ras
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/nxt_ras
add wave -noupdate -group FET -radix decimal /top_tb1/RK1/FET/b_imm
add wave -noupdate -group FET -radix decimal /top_tb1/RK1/FET/j_imm
add wave -noupdate -group FET -radix decimal /top_tb1/RK1/FET/i_imm
add wave -noupdate -group FET /top_tb1/RK1/FET/i
add wave -noupdate -group FET /top_tb1/RK1/FET/btype
add wave -noupdate -group FET /top_tb1/RK1/FET/done
add wave -noupdate -group FET /top_tb1/RK1/FET/rd
add wave -noupdate -group FET /top_tb1/RK1/FET/rs1
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rd
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rs1
add wave -noupdate -group FET /top_tb1/RK1/FET/instr_sz
add wave -noupdate -group FET /top_tb1/RK1/FET/is16
add wave -noupdate -group FET /top_tb1/RK1/FET/is32
add wave -noupdate -group FET /top_tb1/RK1/FET/is48
add wave -noupdate -group FET /top_tb1/RK1/FET/lower5
add wave -noupdate -group FET /top_tb1/RK1/FET/bit_pos
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_valid
add wave -noupdate -group FET /top_tb1/RK1/FET/c
add wave -noupdate -group F2D_bus -radix hexadecimal /top_tb1/RK1/F2D_bus/data
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/valid
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/rdy
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/i
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/pc
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/s_imm
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/i_imm
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/b_imm
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/u_imm
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/j_imm
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/shamt
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/csrx
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/Rd_addr
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/Rs1_addr
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/Rs2_addr
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/funct3
add wave -noupdate -group DEC -group dcore /top_tb1/RK1/DEC/dcore/cntrl_sigs
add wave -noupdate -group DEC /top_tb1/RK1/DEC/clk_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/reset_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/cpu_halt
add wave -noupdate -group DEC /top_tb1/RK1/DEC/full
add wave -noupdate -group DEC /top_tb1/RK1/DEC/i_str
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pc_str
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pipe_flush
add wave -noupdate -group DEC /top_tb1/RK1/DEC/rd_pipe_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/rd_pipe_out
add wave -noupdate -group DEC /top_tb1/RK1/DEC/wr_pipe_out
add wave -noupdate -group D2E_bus -radix hexadecimal /top_tb1/RK1/D2E_bus/data
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/valid
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/rdy
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/clk_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/reset_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/rd_pipe_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/rd_pipe_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/wr_pipe_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/i_str
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/pc_str
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/mode
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/cpu_halt
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/fwd_mem_gpr.valid -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_wr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_mem_gpr.valid {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_mem_gpr
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/fwd_wb_gpr.valid -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_wr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_wb_gpr.valid {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_wb_gpr.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_wb_gpr.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_wb_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_wb_gpr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/gpr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/full
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/exe_dout.ipd -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.ls_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.st_data -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.size -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.zero_ext -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.inv_flag -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.is_ld -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.is_st -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.mis -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.mispre -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.ci -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.predicted_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.br_pc -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.i_type -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.op_type -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_wr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_addr -radix unsigned} {/top_tb1/RK1/EXE/exe_dout.Rd_data -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/EXE/exe_dout.ipd {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ls_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.st_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.size {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.inv_flag {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.is_ld {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.is_st {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.mis {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.mispre {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ci {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.predicted_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.br_pc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.i_type {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.op_type {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_addr {-height 15 -radix unsigned} /top_tb1/RK1/EXE/exe_dout.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/exe_dout
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/Rd_wr
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/Rd_addr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/Rs1_rd
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/Rs1_addr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_data
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/Rs2_rd
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/Rs2_addr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_data
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1D
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2D
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/alu_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/br_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/im_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/idr_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/csr_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ls_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/hint_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/sys_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ill_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/fu_done
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/Rs2_data
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/pc
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/imm
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/sel_x
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/sel_y
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/op
add wave -noupdate -expand -group EXE -group afu_bus /top_tb1/RK1/EXE/afu_bus/Rd_data
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/mux_x
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/mux_y
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/Rs1_data
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/Rs2_data
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/imm
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/sel_x
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/sel_y
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/op
add wave -noupdate -expand -group EXE -group AFU /top_tb1/RK1/EXE/AFU/pc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/Rs2_data
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/pc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/imm
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/funct3
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/ci
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/sel_x
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/sel_y
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/op
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/mepc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/sepc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/uepc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/no_br_pc
add wave -noupdate -expand -group EXE -group brfu_bus -radix hexadecimal /top_tb1/RK1/EXE/brfu_bus/br_pc
add wave -noupdate -expand -group EXE -group brfu_bus /top_tb1/RK1/EXE/brfu_bus/mis
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/mux_x
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/mux_y
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/Rs1_data
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/Rs2_data
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/pc
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/imm
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/funct3
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/ci
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/sel_x
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/sel_y
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/op
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/mepc
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/sepc
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/uepc
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/no_br_pc
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/branch_taken
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/addxy
add wave -noupdate -expand -group EXE -group BFU /top_tb1/RK1/EXE/BFU/br_pc
add wave -noupdate -expand -group EXE -group imfu_bus /top_tb1/RK1/EXE/imfu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group imfu_bus /top_tb1/RK1/EXE/imfu_bus/Rs2_data
add wave -noupdate -expand -group EXE -group imfu_bus /top_tb1/RK1/EXE/imfu_bus/op
add wave -noupdate -expand -group EXE -group imfu_bus /top_tb1/RK1/EXE/imfu_bus/Rd_data
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/Rs1_data
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/Rs2_data
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/op
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/m1Data
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/m2Data
add wave -noupdate -expand -group EXE -group MFU /top_tb1/RK1/EXE/MFU/mulx
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/Rs2_data
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/op
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/start
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/quotient
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/remainder
add wave -noupdate -expand -group EXE -group idrfu_bus /top_tb1/RK1/EXE/idrfu_bus/done
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/clk_in
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/reset_in
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/dividend
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/divisor
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/quotient
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/remainder
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/div_by_0_err
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/overflow_err
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/start
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/done
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/op
add wave -noupdate -expand -group EXE -group IDRFU /top_tb1/RK1/EXE/idrfu/is_signed
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_addr
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_valid
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rd_addr
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rs1_addr
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/funct3
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/current_events
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/mret
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/sret
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/uret
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/mtime
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ext_irq
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/time_irq
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/sw_irq
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/exception
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rd_data
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/mode
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/trap_pc
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/interrupt_flag
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/interrupt_cause
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/mepc
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/sepc
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/uepc
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ill_csr_access
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ill_csr_addr
add wave -noupdate -expand -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ialign
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/clk_in
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/reset_in
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mstatus
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_misa
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_medeleg
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mideleg
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mtvec
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mcounteren
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mcountinhibit
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mscratch
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mcause
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mtval
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mcycle_lo
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_minstret_lo
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mcycle_hi
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_minstret_hi
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mvendorid
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_marchid
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mimpid
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_mhartid
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sstatus
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sedeleg
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sideleg
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_stvec
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_scounteren
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sscratch
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_scause
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_stval
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_sip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_satp
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_ustatus
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_uie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_utvec
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_uscratch
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_uepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_ucause
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_utval
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_uip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_addr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_valid
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/Rd_addr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/Rs1_addr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/Rs1_data
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_funct
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/current_events
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mret
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sret
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/uret
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/uepc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mtime
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ext_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/time_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sw_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/exception
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_rd_data
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mode
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/nxt_mode
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/trap_pc
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/interrupt_cause
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/interrupt_flag
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ill_csr_access
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ill_csr_addr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ialign
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/imm_data
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_wr_data
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_wr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_rd
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/lowest_priv
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/writable
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_avail
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/csr_rdata
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sd
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/tsr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/tw
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/tvm
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mxr
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sum
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mprv
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/xs
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/fs
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mpp
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mpie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/spp
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/spie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/sie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/upie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/uie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/msip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mtip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/meip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ssip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/stip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/seip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/usip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/utip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ueip
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/m_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/s_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/u_irq
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/usie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ssie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/msie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/utie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/stie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/mtie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/ueie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/seie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/meie
add wave -noupdate -expand -group EXE -group CSRFU /top_tb1/RK1/EXE/CFU/tot_retired
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/Rs1_data
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/Rs2_data
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/imm
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/funct3
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/ls_addr
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/st_data
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/size
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/zero_ext
add wave -noupdate -expand -group EXE -group lsfu_bus /top_tb1/RK1/EXE/lsfu_bus/mis
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/clk_in
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/reset_in
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/write_in
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/data_in
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/full_out
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/read_in
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/data_out
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/valid_out
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/empty
add wave -noupdate -expand -group EXE -group EXE_PIPE /top_tb1/RK1/EXE/EXE_PIPE/full
add wave -noupdate -group E2M_bus -childformat {{/top_tb1/RK1/E2M_bus/data.predicted_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.op_type -radix unsigned} {/top_tb1/RK1/E2M_bus/data.Rd_data -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/E2M_bus/data.predicted_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.op_type {-height 15 -radix unsigned} /top_tb1/RK1/E2M_bus/data.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/E2M_bus/data
add wave -noupdate -group E2M_bus /top_tb1/RK1/E2M_bus/valid
add wave -noupdate -group E2M_bus /top_tb1/RK1/E2M_bus/rdy
add wave -noupdate -group MEM /top_tb1/RK1/MEM/clk_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/reset_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/ext_irq
add wave -noupdate -group MEM /top_tb1/RK1/MEM/time_irq
add wave -noupdate -group MEM /top_tb1/RK1/MEM/sw_irq
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mtime
add wave -noupdate -group MEM /top_tb1/RK1/MEM/pipe_flush
add wave -noupdate -group MEM /top_tb1/RK1/MEM/cpu_halt
add wave -noupdate -group MEM /top_tb1/RK1/MEM/fwd_mem_gpr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_dout
add wave -noupdate -group MEM /top_tb1/RK1/MEM/rd_pipe_out
add wave -noupdate -group MEM /top_tb1/RK1/MEM/wr_pipe_out
add wave -noupdate -group MEM /top_tb1/RK1/MEM/rd_pipe_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/full
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_ls
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ls_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/st_data
add wave -noupdate -group MEM /top_tb1/RK1/MEM/size
add wave -noupdate -group MEM /top_tb1/RK1/MEM/zero_ext
add wave -noupdate -group MEM /top_tb1/RK1/MEM/inv_flag
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_ld
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_st
add wave -noupdate -group MEM /top_tb1/RK1/MEM/mis
add wave -noupdate -group MEM /top_tb1/RK1/MEM/ci
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/br_pc
add wave -noupdate -group MEM /top_tb1/RK1/MEM/trigger_wfi
add wave -noupdate -group MEM /top_tb1/RK1/MEM/i_type
add wave -noupdate -group MEM /top_tb1/RK1/MEM/op_type
add wave -noupdate -group MEM /top_tb1/RK1/MEM/Rd_wr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/Rd_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/Rd_data
add wave -noupdate -group MEM -radix hexadecimal -childformat {{/top_tb1/RK1/MEM/ipd.instruction -radix hexadecimal} {/top_tb1/RK1/MEM/ipd.pc -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/MEM/ipd.instruction {-height 15 -radix hexadecimal} /top_tb1/RK1/MEM/ipd.pc {-height 15 -radix hexadecimal}} /top_tb1/RK1/MEM/ipd
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/predicted_addr
add wave -noupdate -group MEM /top_tb1/RK1/MEM/interrupt_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/interrupt_cause
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/trap_pc
add wave -noupdate -group MEM /top_tb1/RK1/MEM/ill_csr_access
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ill_csr_addr
add wave -noupdate -group MEM /top_tb1/RK1/MEM/ialign
add wave -noupdate -group MEM /top_tb1/RK1/MEM/mode
add wave -noupdate -group MEM /top_tb1/RK1/MEM/exception
add wave -noupdate -group MEM /top_tb1/RK1/MEM/current_events
add wave -noupdate -group MEM /top_tb1/RK1/MEM/rld_pc_flag
add wave -noupdate -group MEM /top_tb1/RK1/MEM/rld_ic_flag
add wave -noupdate -group MEM /top_tb1/RK1/MEM/rld_pc_addr
add wave -noupdate -group M2W_bus -expand /top_tb1/RK1/M2W_bus/data
add wave -noupdate -group M2W_bus /top_tb1/RK1/M2W_bus/valid
add wave -noupdate -group M2W_bus /top_tb1/RK1/M2W_bus/rdy
add wave -noupdate -group WB /top_tb1/RK1/WB/clk_in
add wave -noupdate -group WB /top_tb1/RK1/WB/reset_in
add wave -noupdate -group WB /top_tb1/RK1/WB/i_str
add wave -noupdate -group WB /top_tb1/RK1/WB/pc_str
add wave -noupdate -group WB /top_tb1/RK1/WB/cpu_halt
add wave -noupdate -group WB /top_tb1/RK1/WB/fwd_wb_gpr
add wave -noupdate -group WB /top_tb1/RK1/WB/xfer_in
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/req
add wave -noupdate -group MIO_bus -radix hexadecimal -childformat {{/top_tb1/RK1/MIO_bus/req_data.rd -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.wr -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr -radix hexadecimal -childformat {{{[31]} -radix hexadecimal} {{[30]} -radix hexadecimal} {{[29]} -radix hexadecimal} {{[28]} -radix hexadecimal} {{[27]} -radix hexadecimal} {{[26]} -radix hexadecimal} {{[25]} -radix hexadecimal} {{[24]} -radix hexadecimal} {{[23]} -radix hexadecimal} {{[22]} -radix hexadecimal} {{[21]} -radix hexadecimal} {{[20]} -radix hexadecimal} {{[19]} -radix hexadecimal} {{[18]} -radix hexadecimal} {{[17]} -radix hexadecimal} {{[16]} -radix hexadecimal} {{[15]} -radix hexadecimal} {{[14]} -radix hexadecimal} {{[13]} -radix hexadecimal} {{[12]} -radix hexadecimal} {{[11]} -radix hexadecimal} {{[10]} -radix hexadecimal} {{[9]} -radix hexadecimal} {{[8]} -radix hexadecimal} {{[7]} -radix hexadecimal} {{[6]} -radix hexadecimal} {{[5]} -radix hexadecimal} {{[4]} -radix hexadecimal} {{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/top_tb1/RK1/MIO_bus/req_data.wr_data -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.size -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.zero_ext -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.inv_flag -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/MIO_bus/req_data.rd {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.wr {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.rw_addr {-height 15 -radix hexadecimal -childformat {{{[31]} -radix hexadecimal} {{[30]} -radix hexadecimal} {{[29]} -radix hexadecimal} {{[28]} -radix hexadecimal} {{[27]} -radix hexadecimal} {{[26]} -radix hexadecimal} {{[25]} -radix hexadecimal} {{[24]} -radix hexadecimal} {{[23]} -radix hexadecimal} {{[22]} -radix hexadecimal} {{[21]} -radix hexadecimal} {{[20]} -radix hexadecimal} {{[19]} -radix hexadecimal} {{[18]} -radix hexadecimal} {{[17]} -radix hexadecimal} {{[16]} -radix hexadecimal} {{[15]} -radix hexadecimal} {{[14]} -radix hexadecimal} {{[13]} -radix hexadecimal} {{[12]} -radix hexadecimal} {{[11]} -radix hexadecimal} {{[10]} -radix hexadecimal} {{[9]} -radix hexadecimal} {{[8]} -radix hexadecimal} {{[7]} -radix hexadecimal} {{[6]} -radix hexadecimal} {{[5]} -radix hexadecimal} {{[4]} -radix hexadecimal} {{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[31]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[30]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[29]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[28]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[27]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[26]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[25]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[24]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[23]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[22]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[21]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[20]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[19]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[18]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[17]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[16]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[15]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[14]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[13]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[12]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[11]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[10]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[9]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[8]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[7]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[6]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[5]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[4]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[3]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[2]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[1]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[0]} {-radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.wr_data {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.size {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.inv_flag {-height 15 -radix hexadecimal}} /top_tb1/RK1/MIO_bus/req_data
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/ack
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/ack_fault
add wave -noupdate -group MIO_bus -radix hexadecimal -childformat {{{/top_tb1/RK1/MIO_bus/ack_data[31]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[30]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[29]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[28]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[27]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[26]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[25]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[24]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[23]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[22]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[21]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[20]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[19]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[18]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[17]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[16]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[15]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[14]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[13]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[12]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[11]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[10]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[9]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[8]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[7]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[6]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[5]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[4]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[3]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[2]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[1]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[0]} -radix hexadecimal}} -subitemconfig {{/top_tb1/RK1/MIO_bus/ack_data[31]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[30]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[29]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[28]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[27]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[26]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[25]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[24]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[23]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[22]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[21]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[20]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[19]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[18]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[17]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[16]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[15]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[14]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[13]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[12]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[11]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[10]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[9]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[8]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/MIO_bus/ack_data
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM/i_str
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM/pc_str
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/access_fault
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/mode
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/msip_wr
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/mtime_lo_wr
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/mtime_hi_wr
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/mtimecmp_lo_wr
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/mtimecmp_hi_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mmr_wr_data
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtime
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtimecmp
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/msip_reg
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/sim_stop
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/io_req
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/io_ack
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/io_ack_fault
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_addr
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/io_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_wr_data
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_rd_data
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/is_phy_mem
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/is_int_io
add wave -noupdate -group MEM_IO /top_tb1/RK1/MEM_IO/is_ext_io
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_wr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_addr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_data
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/clk_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/reset_in
add wave -noupdate -expand -group GPR -radix unsigned -childformat {{{/top_tb1/RK1/GPR/gpr[31]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[30]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[29]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[28]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[27]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[26]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[25]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[24]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[23]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[22]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[21]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[20]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[19]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[18]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[17]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[16]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[15]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[14]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[13]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[12]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[11]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[10]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[9]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[8]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[7]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[6]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[5]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[4]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[3]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[2]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[1]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb1/RK1/GPR/gpr[31]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[30]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[29]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[28]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[27]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[26]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[25]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[24]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[23]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[22]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[21]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[20]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[19]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[18]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[17]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[16]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[15]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[14]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[13]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[12]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[11]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[10]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[9]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[8]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[7]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[6]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[5]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[4]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[3]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[2]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[1]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[0]} {-height 15 -radix unsigned}} /top_tb1/RK1/GPR/gpr
add wave -noupdate -group L1IC_intf /top_tb1/RK1/L1IC_intf/addr
add wave -noupdate -group L1IC_intf /top_tb1/RK1/L1IC_intf/req
add wave -noupdate -group L1IC_intf /top_tb1/RK1/L1IC_intf/ack
add wave -noupdate -group L1_ic /top_tb1/L1_ic/clk_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/reset_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/inv_req_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/inv_addr_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/inv_ack_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_flush
add wave -noupdate -group L1_ic /top_tb1/L1_ic/cache_valid
add wave -noupdate -group L1_ic /top_tb1/L1_ic/lru
add wave -noupdate -group L1_ic /top_tb1/L1_ic/next_lru
add wave -noupdate -group L1_ic /top_tb1/L1_ic/current_cache_line
add wave -noupdate -group L1_ic /top_tb1/L1_ic/tag
add wave -noupdate -group L1_ic /top_tb1/L1_ic/set
add wave -noupdate -group L1_ic /top_tb1/L1_ic/way
add wave -noupdate -group L1_ic /top_tb1/L1_ic/hit
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ecf
add wave -noupdate -group L1_ic /top_tb1/L1_ic/icf_ff
add wave -noupdate -group L1_ic /top_tb1/L1_ic/clr_all_valid
add wave -noupdate -group L1_ic /top_tb1/L1_ic/hit_num
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ecf_num
add wave -noupdate -group L1_ic /top_tb1/L1_ic/lru_num
add wave -noupdate -group L1_ic /top_tb1/L1_ic/save_arb_cl
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_ack_xfer
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_req_xfer
add wave -noupdate -group L1_ic /top_tb1/L1_ic/Next_IC_State
add wave -noupdate -group L1_ic /top_tb1/L1_ic/IC_State
add wave -noupdate -group L1_ic /top_tb1/L1_ic/h
add wave -noupdate -group L1_ic /top_tb1/L1_ic/n
add wave -noupdate -group L1_ic /top_tb1/L1_ic/l
add wave -noupdate -group L1_ic /top_tb1/L1_ic/p
add wave -noupdate -group L1_ic /top_tb1/L1_ic/val
add wave -noupdate -group L1_ic /top_tb1/L1_ic/update_lru
add wave -noupdate -group L1DC_intf /top_tb1/RK1/L1DC_intf/req
add wave -noupdate -group L1DC_intf -radix hexadecimal -childformat {{/top_tb1/RK1/L1DC_intf/req_data.rd -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.wr -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.rw_addr -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.wr_data -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.size -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.zero_ext -radix hexadecimal} {/top_tb1/RK1/L1DC_intf/req_data.inv_flag -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/L1DC_intf/req_data.rd {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.wr {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.rw_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.wr_data {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.size {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/L1DC_intf/req_data.inv_flag {-height 15 -radix hexadecimal}} /top_tb1/RK1/L1DC_intf/req_data
add wave -noupdate -group L1DC_intf /top_tb1/RK1/L1DC_intf/ack
add wave -noupdate -group L1DC_intf /top_tb1/RK1/L1DC_intf/ack_data
add wave -noupdate -group L1_dc /top_tb1/L1_dc/clk_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/reset_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/inv_req_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/inv_addr_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/inv_ack_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_flush
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_valid
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_dirty
add wave -noupdate -group L1_dc /top_tb1/L1_dc/lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/next_lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/current_cache_line
add wave -noupdate -group L1_dc /top_tb1/L1_dc/ccl
add wave -noupdate -group L1_dc /top_tb1/L1_dc/norm_ccl
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_addr
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/norm_set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/way
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/norm_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/hit
add wave -noupdate -group L1_dc /top_tb1/L1_dc/hit_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr
add wave -noupdate -group L1_dc /top_tb1/L1_dc/zx
add wave -noupdate -group L1_dc /top_tb1/L1_dc/sz
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set_way
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cla
add wave -noupdate -group L1_dc /top_tb1/L1_dc/std
add wave -noupdate -group L1_dc /top_tb1/L1_dc/ecf
add wave -noupdate -group L1_dc /top_tb1/L1_dc/ecf_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/lru_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dirty
add wave -noupdate -group L1_dc /top_tb1/L1_dc/update_lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr_cpu_data
add wave -noupdate -group L1_dc /top_tb1/L1_dc/save_info
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tmp_cache_line
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tmp_cache_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/save_tmp_cl
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr_arb_data
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cm_wr
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_flag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set_bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/clr_bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dcf_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/inv_flag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/clr_dirty
add wave -noupdate -group L1_dc /top_tb1/L1_dc/Next_DC_State
add wave -noupdate -group L1_dc /top_tb1/L1_dc/DC_State
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_ack_xfer
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_req_xfer
add wave -noupdate -group L1_dc /top_tb1/L1_dc/h
add wave -noupdate -group L1_dc /top_tb1/L1_dc/hw
add wave -noupdate -group L1_dc /top_tb1/L1_dc/l
add wave -noupdate -group L1_dc /top_tb1/L1_dc/lw
add wave -noupdate -group L1_dc /top_tb1/L1_dc/p
add wave -noupdate -group L1_dc /top_tb1/L1_dc/pw
add wave -noupdate -group L1_dc /top_tb1/L1_dc/val
add wave -noupdate -group IC_arb_bus -radix hexadecimal /top_tb1/IC_arb_bus/req_addr
add wave -noupdate -group IC_arb_bus /top_tb1/IC_arb_bus/req_valid
add wave -noupdate -group IC_arb_bus /top_tb1/IC_arb_bus/req_rdy
add wave -noupdate -group IC_arb_bus -radix hexadecimal /top_tb1/IC_arb_bus/ack_data
add wave -noupdate -group IC_arb_bus /top_tb1/IC_arb_bus/ack_valid
add wave -noupdate -group IC_arb_bus /top_tb1/IC_arb_bus/ack_rdy
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/req_data
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/req_valid
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/req_rdy
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/ack_data
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/ack_valid
add wave -noupdate -group DC_arb_bus /top_tb1/DC_arb_bus/ack_rdy
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/clk_in
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/reset_in
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/arb_state
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/next_arb_state
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/wr_data
add wave -noupdate -group {Cache Arbiter} -radix hexadecimal /top_tb1/carb/rd_data
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/rw_addr
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/rw
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/save_ic_info
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/save_dc_info
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/save_rd_data
add wave -noupdate -group {Cache Arbiter} /top_tb1/carb/is_ic_cycle
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_rw
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_addr
add wave -noupdate -group sysmem_bus -radix hexadecimal /top_tb1/sysmem_bus/req_wr_data
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_valid
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_rdy
add wave -noupdate -group sysmem_bus -radix hexadecimal /top_tb1/sysmem_bus/ack_rd_data
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/ack_valid
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/ack_rdy
add wave -noupdate -group {Sys Mem} /top_tb1/sm/clk_in
add wave -noupdate -group {Sys Mem} /top_tb1/sm/reset_in
add wave -noupdate -group {Sys Mem} /top_tb1/sm/sys_mem
add wave -noupdate -group {Sys Mem} /top_tb1/sm/b4
add wave -noupdate -group {Sys Mem} /top_tb1/sm/k
add wave -noupdate -group {Sys Mem} /top_tb1/sm/bp
add wave -noupdate -group {Sys Mem} /top_tb1/sm/ndx
add wave -noupdate -group {Sys Mem} /top_tb1/sm/p
add wave -noupdate -group {Sys Mem} /top_tb1/sm/wr_data
add wave -noupdate -group {Sys Mem} -radix hexadecimal /top_tb1/sm/b_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1485514 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 159
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1563450 ps}
