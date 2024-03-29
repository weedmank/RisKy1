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
add wave -noupdate -group FET /top_tb1/RK1/FET/ic_reload
add wave -noupdate -group FET /top_tb1/RK1/FET/pc_reload
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/pc_reload_addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/Next_PC
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/PC
add wave -noupdate -group FET /top_tb1/RK1/FET/nq
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip_cnt
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qip
add wave -noupdate -group FET -radix unsigned -childformat {{{/top_tb1/RK1/FET/nxt_qop[5]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_qop[4]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_qop[3]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_qop[2]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_qop[1]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_qop[0]} -radix hexadecimal}} -subitemconfig {{/top_tb1/RK1/FET/nxt_qop[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_qop[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_qop[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_qop[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_qop[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_qop[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/FET/nxt_qop
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qop
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qcnt
add wave -noupdate -group FET /top_tb1/RK1/FET/qfull
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_que
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/que
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_xfer
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/predicted
add wave -noupdate -group FET /top_tb1/RK1/FET/bt
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/reload_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/reload_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/clr_overlap_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/clr_rf
add wave -noupdate -group FET /top_tb1/RK1/FET/save_lpa
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_ic_req
add wave -noupdate -group FET /top_tb1/RK1/FET/cc_state
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_cc_state
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/last_predicted_addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/lpa
add wave -noupdate -group FET /top_tb1/RK1/FET/nxt_ras
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_ras_ptr
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/ras_ptr
add wave -noupdate -group FET /top_tb1/RK1/FET/ras
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/b_imm
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/j_imm
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/i_imm
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/i
add wave -noupdate -group FET /top_tb1/RK1/FET/btype
add wave -noupdate -group FET /top_tb1/RK1/FET/done
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/rd
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/rs1
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rd
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rs1
add wave -noupdate -group FET -radix unsigned -childformat {{{/top_tb1/RK1/FET/instr_sz[15]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[14]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[13]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[12]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[11]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[10]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[9]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[8]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[7]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[6]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[5]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[4]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[3]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[2]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[1]} -radix unsigned} {{/top_tb1/RK1/FET/instr_sz[0]} -radix unsigned}} -subitemconfig {{/top_tb1/RK1/FET/instr_sz[15]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[14]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[13]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[12]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[11]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[10]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[9]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[8]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[7]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[6]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[5]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[4]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[3]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[2]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[1]} {-height 15 -radix unsigned} {/top_tb1/RK1/FET/instr_sz[0]} {-height 15 -radix unsigned}} /top_tb1/RK1/FET/instr_sz
add wave -noupdate -group FET /top_tb1/RK1/FET/is16
add wave -noupdate -group FET /top_tb1/RK1/FET/is32
add wave -noupdate -group FET /top_tb1/RK1/FET/is48
add wave -noupdate -group FET /top_tb1/RK1/FET/isoverlap
add wave -noupdate -group FET /top_tb1/RK1/FET/set_overlap_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/overlap_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/overlap_instr
add wave -noupdate -group FET /top_tb1/RK1/FET/overlap_pc
add wave -noupdate -group FET /top_tb1/RK1/FET/ov_instr
add wave -noupdate -group FET /top_tb1/RK1/FET/lower5
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/bit_pos
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_valid
add wave -noupdate -group FET /top_tb1/RK1/FET/xfer_out
add wave -noupdate -group FET /top_tb1/RK1/FET/c
add wave -noupdate -group F2D_bus -radix hexadecimal /top_tb1/RK1/F2D_bus/data
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/valid
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/rdy
add wave -noupdate -group DEC /top_tb1/RK1/DEC/clk_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/reset_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/xfer_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/cpu_halt
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pipe_flush
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pipe_full
add wave -noupdate -group DEC /top_tb1/RK1/DEC/xfer_out
add wave -noupdate -group DEC -radix hexadecimal -childformat {{/top_tb1/RK1/DEC/dec_out.ipd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.predicted_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs1_rd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs2_rd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rd_wr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.ig_type -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.sel_x -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.sel_y -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.op -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.ci -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.imm -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.funct3 -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs2_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs1_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rd_addr -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/DEC/dec_out.ipd {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.predicted_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs1_rd {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs2_rd {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.ig_type {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.sel_x {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.sel_y {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.op {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.ci {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.imm {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.funct3 {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs2_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs1_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rd_addr {-height 15 -radix hexadecimal}} /top_tb1/RK1/DEC/dec_out
add wave -noupdate -group D2E_bus -radix hexadecimal /top_tb1/RK1/D2E_bus/data
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/valid
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/rdy
add wave -noupdate -group EXE /top_tb1/RK1/EXE/clk_in
add wave -noupdate -group EXE /top_tb1/RK1/EXE/reset_in
add wave -noupdate -group EXE /top_tb1/RK1/EXE/cpu_halt
add wave -noupdate -group EXE /top_tb1/RK1/EXE/pipe_flush
add wave -noupdate -group EXE /top_tb1/RK1/EXE/i_str
add wave -noupdate -group EXE /top_tb1/RK1/EXE/pc_str
add wave -noupdate -group EXE /top_tb1/RK1/EXE/rld_pc_flag
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/rld_pc_addr
add wave -noupdate -group EXE -radix unsigned /top_tb1/RK1/EXE/mode
add wave -noupdate -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/fwd_mem_gpr.valid -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_wr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_mem_gpr.valid {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_mem_gpr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/fwd_wb_gpr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/gpr
add wave -noupdate -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/exe_dout.ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {/top_tb1/RK1/EXE/exe_dout.ls_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.st_data -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.size -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.zero_ext -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.inv_flag -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.is_ld -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.is_st -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.instr_err -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.mispre -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.ci -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.ig_type -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.op_type -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.mode -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.trap_pc -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_wr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_data -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.csr_wr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.csr_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.csr_wr_data -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.csr_fwd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/exe_dout.ipd {-height 15 -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} /top_tb1/RK1/EXE/exe_dout.ipd.instruction {-radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ipd.pc {-radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ls_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.st_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.size {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.inv_flag {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.is_ld {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.is_st {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.instr_err {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.mispre {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ci {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ig_type {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.op_type {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.mode {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.trap_pc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.csr_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.csr_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.csr_wr_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.csr_fwd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/exe_dout
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rd_addr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_addr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_addr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rd_wr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_rd
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_rd
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_data
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_data
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1D
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2D
add wave -noupdate -group EXE /top_tb1/RK1/EXE/alu_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/br_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/im_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/idr_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/csr_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/ls_fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/hint_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/sys_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/ill_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/fu_done
add wave -noupdate -group EXE /top_tb1/RK1/EXE/op_type
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/predicted_addr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/mepc
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/uepc
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_valid
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_addr
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_avail
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_rd_data
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rd_addr
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rs1_addr
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rs1_data
add wave -noupdate -group EXE -group csrfu_bus -radix unsigned /top_tb1/RK1/EXE/csrfu_bus/funct3
add wave -noupdate -group EXE -group csrfu_bus -radix unsigned /top_tb1/RK1/EXE/csrfu_bus/mode
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_wr
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_rd
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/Rd_data
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/csr_wr_data
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/nxt_csr_rd_data
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ill_csr_access
add wave -noupdate -group EXE -group csrfu_bus /top_tb1/RK1/EXE/csrfu_bus/ill_csr_addr
add wave -noupdate -group EXE -group csr_nxt_bus /top_tb1/RK1/EXE/csr_nxt_bus/nxt_csr_wr
add wave -noupdate -group EXE -group csr_nxt_bus /top_tb1/RK1/EXE/csr_nxt_bus/nxt_csr_wr_addr
add wave -noupdate -group EXE -group csr_nxt_bus /top_tb1/RK1/EXE/csr_nxt_bus/nxt_csr_wr_data
add wave -noupdate -group EXE -group csr_nxt_bus /top_tb1/RK1/EXE/csr_nxt_bus/nxt_csr_rd_data
add wave -noupdate -group EXE -group csr_rd_bus /top_tb1/RK1/EXE/csr_rd_bus/csr_rd_addr
add wave -noupdate -group EXE -group csr_rd_bus /top_tb1/RK1/EXE/csr_rd_bus/csr_rd_data
add wave -noupdate -group EXE -group csr_rd_bus /top_tb1/RK1/EXE/csr_rd_bus/csr_rd_avail
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/CSD
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/csr_addr
add wave -noupdate -group EXE /top_tb1/RK1/EXE/csr_avail
add wave -noupdate -group EXE /top_tb1/RK1/EXE/csr_rd
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/csr_Rd_data
add wave -noupdate -group EXE /top_tb1/RK1/EXE/csr_wr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/csr_wr_data
add wave -noupdate -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/fwd_mem_csr.valid -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_csr.csr_wr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_csr.csr_addr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_csr.csr_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_mem_csr.valid {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_csr.csr_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_csr.csr_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_csr.csr_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_mem_csr
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/fwd_wb_csr
add wave -noupdate -group EXE /top_tb1/RK1/EXE/ill_csr_access
add wave -noupdate -group EXE -radix hexadecimal /top_tb1/RK1/EXE/ill_csr_addr
add wave -noupdate -group EXE /top_tb1/RK1/EXE/ci
add wave -noupdate -group EXE /top_tb1/RK1/EXE/mret
add wave -noupdate -group EXE /top_tb1/RK1/EXE/uret
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/clk_in
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/reset_in
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/mtime
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_ucsr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/ucsr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_mcsr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/mcsr
add wave -noupdate -group CSREGS -radix unsigned /top_tb1/RK1/CSREGS/mode
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_mode
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/exception
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/current_events
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/tot_retired
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_csr_wr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_csr_wr_addr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_csr_wr_data
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_csr_rd_data
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_wr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_wr_addr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_wr_data
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_rd_addr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_rd_data
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/csr_rd_avail
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/trap_pc
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/mret
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/uret
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_FWD_mcsr
add wave -noupdate -group CSREGS /top_tb1/RK1/CSREGS/nxt_FWD_ucsr
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/csr_valid
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/csr_addr
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/Rd_addr
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/Rs1_addr
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/Rs1_data
add wave -noupdate -group CSRFU -radix unsigned /top_tb1/RK1/EXE/CSRFU/funct3
add wave -noupdate -group CSRFU -radix unsigned /top_tb1/RK1/EXE/CSRFU/mode
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/csr_wr
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/csr_rd
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/csr_avail
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/csr_rd_data
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/Rd_data
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/csr_wr_data
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/nxt_csr_rd_data
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/ill_csr_access
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/ill_csr_addr
add wave -noupdate -group CSRFU -radix hexadecimal /top_tb1/RK1/EXE/CSRFU/imm_data
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/lowest_priv
add wave -noupdate -group CSRFU /top_tb1/RK1/EXE/CSRFU/writable
add wave -noupdate -group E2M_bus -radix hexadecimal -childformat {{/top_tb1/RK1/E2M_bus/data.ipd -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.ls_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.st_data -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.size -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.zero_ext -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.inv_flag -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.is_ld -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.is_st -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.instr_err -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.mispre -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.ci -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.ig_type -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.op_type -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.mode -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.trap_pc -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_wr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_data -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.csr_wr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.csr_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.csr_wr_data -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.csr_fwd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/E2M_bus/data.ipd {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.ls_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.st_data {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.size {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.inv_flag {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.is_ld {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.is_st {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.instr_err {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.mispre {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.ci {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.ig_type {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.op_type {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.mode {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.trap_pc {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_data {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.csr_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.csr_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.csr_wr_data {-height 15 -radix hexadecimal} /top_tb1/RK1/E2M_bus/data.csr_fwd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/E2M_bus/data
add wave -noupdate -group E2M_bus -radix hexadecimal /top_tb1/RK1/E2M_bus/valid
add wave -noupdate -group E2M_bus -radix hexadecimal /top_tb1/RK1/E2M_bus/rdy
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/clk_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/reset_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mtime
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/pipe_flush
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/cpu_halt
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/fwd_mem_gpr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_dout
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_ls
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ls_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/st_data
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/size
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/zero_ext
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/inv_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_ld
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_st
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mode
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/data
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/valid
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/rdy
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/reset_in
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/cpu_halt
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/rld_pc_flag
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/rld_ic_flag
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/rld_pc_addr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/fwd_wb_csr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/fwd_wb_gpr
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/ipd
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/ls_addr
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/inv_flag
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/instr_err
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/mispre
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/ci
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/ig_type
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/op_type
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/mio_ack_fault
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/wb_Rd_wr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/wb_Rd_addr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/wb_Rd_data
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/wb_csr_wr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/wb_csr_addr
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/wb_csr_wr_data
add wave -noupdate -expand -group WB -radix hexadecimal /top_tb1/RK1/WB/wb_csr_fwd_data
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/xfer_in
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/mode
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/trap_pc
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/exception
add wave -noupdate -expand -group WB /top_tb1/RK1/WB/current_events
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_wr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_addr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_data
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/clk_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/reset_in
add wave -noupdate -expand -group GPR -radix hexadecimal -childformat {{{/top_tb1/RK1/GPR/gpr[31]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[30]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[29]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[28]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[27]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[26]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[25]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[24]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[23]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[22]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[21]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[20]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[19]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[18]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[17]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[16]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[15]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[14]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[13]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[12]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[11]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[10]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[9]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[8]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[7]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[6]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[5]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[4]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[3]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[2]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[1]} -radix hexadecimal} {{/top_tb1/RK1/GPR/gpr[0]} -radix hexadecimal}} -expand -subitemconfig {{/top_tb1/RK1/GPR/gpr[31]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[30]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[29]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[28]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[27]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[26]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[25]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[24]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[23]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[22]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[21]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[20]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[19]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[18]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[17]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[16]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[15]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[14]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[13]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[12]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[11]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[10]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[9]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[8]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/GPR/gpr[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/GPR/gpr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/clk_in
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/reset_in
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtime_lo_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtime_hi_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtimecmp_lo_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtimecmp_hi_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mmr_wr_data
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtime
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtimecmp
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/msip_reg
add wave -noupdate -group L1IC_bus -radix hexadecimal /top_tb1/RK1/L1IC_bus/req
add wave -noupdate -group L1IC_bus -radix hexadecimal /top_tb1/RK1/L1IC_bus/addr
add wave -noupdate -group L1IC_bus -radix hexadecimal /top_tb1/RK1/L1IC_bus/ack
add wave -noupdate -group L1IC_bus -radix hexadecimal /top_tb1/RK1/L1IC_bus/ack_data
add wave -noupdate -group L1IC_bus -radix hexadecimal /top_tb1/RK1/L1IC_bus/ack_fault
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/clk_in
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/reset_in
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/ic_flush
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/inv_req_in
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/inv_addr_in
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/inv_ack_out
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/cache_valid
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/lru
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/next_lru
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/current_cache_line
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/tag
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/set
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/way
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/hit
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/ecf
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/icf_ff
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/clr_all_valid
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/hit_num
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/ecf_num
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/lru_num
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/save_arb_cl
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/arb_ack_xfer
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/arb_req_xfer
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/Next_IC_State
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/IC_State
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/h
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/n
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/l
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/p
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/val
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/update_lru
add wave -noupdate -group L1DC_bus -radix hexadecimal /top_tb1/RK1/L1DC_bus/req
add wave -noupdate -group L1DC_bus -radix hexadecimal /top_tb1/RK1/L1DC_bus/req_data
add wave -noupdate -group L1DC_bus -radix hexadecimal /top_tb1/RK1/L1DC_bus/ack
add wave -noupdate -group L1DC_bus -radix hexadecimal /top_tb1/RK1/L1DC_bus/ack_data
add wave -noupdate -group L1DC_bus -radix hexadecimal /top_tb1/RK1/L1DC_bus/ack_fault
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/clk_in
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/reset_in
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/dc_flush
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/inv_req_out
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/inv_addr_out
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/inv_ack_in
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/cache_valid
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/cache_dirty
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/lru
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/next_lru
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/current_cache_line
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/ccl
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/norm_ccl
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/bc_addr
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/set
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/norm_set
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/bc_set
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/way
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/tag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/norm_tag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/bc_tag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/hit
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/hit_num
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/rd
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/wr
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/zx
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/sz
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/set_way
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/cla
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/std
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/ecf
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/ecf_num
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/lru_num
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/dirty
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/update_lru
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/wr_cpu_data
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/save_info
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/tmp_cache_line
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/tmp_cache_tag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/save_tmp_cl
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/wr_arb_data
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/cm_wr
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/bc_flag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/set_bc_ff
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/clr_bc_ff
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/dcf_ff
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/bc_ff
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/inv_flag
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/clr_dirty
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/Next_DC_State
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/DC_State
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/arb_ack_xfer
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/arb_req_xfer
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/h
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/hw
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/l
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/lw
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/p
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/pw
add wave -noupdate -group L1_dc -radix hexadecimal /top_tb1/L1_dc/val
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
WaveRestoreCursors {{Cursor 1} {705748 ps} 0}
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
WaveRestoreZoom {622661 ps} {789081 ps}
