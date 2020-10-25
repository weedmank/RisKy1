onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb1/clock_cycle
add wave -noupdate -group top_tb1 /top_tb1/reset
add wave -noupdate -group top_tb1 /top_tb1/clk_100
add wave -noupdate -group top_tb1 /top_tb1/debug
add wave -noupdate -group top_tb1 /top_tb1/sim_stop
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_req_addr
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_req_valid
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_req_rdy
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_req_info
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_req_valid
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_req_rdy
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_ack_data
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_ack_valid
add wave -noupdate -group top_tb1 /top_tb1/arb_ic_ack_rdy
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_ack_data
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_ack_valid
add wave -noupdate -group top_tb1 /top_tb1/arb_dc_ack_rdy
add wave -noupdate -group top_tb1 /top_tb1/ic_addr
add wave -noupdate -group top_tb1 /top_tb1/ic_req
add wave -noupdate -group top_tb1 /top_tb1/ic_ack
add wave -noupdate -group top_tb1 /top_tb1/ic_rd_data
add wave -noupdate -group top_tb1 /top_tb1/ic_flush
add wave -noupdate -group top_tb1 /top_tb1/dc_data
add wave -noupdate -group top_tb1 /top_tb1/dc_req
add wave -noupdate -group top_tb1 /top_tb1/dc_ack
add wave -noupdate -group top_tb1 /top_tb1/dc_rd_data
add wave -noupdate -group top_tb1 /top_tb1/dc_flush
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/addr
add wave -noupdate -group FET /top_tb1/RK1/FET/b_imm
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/bit_pos
add wave -noupdate -group FET -radix binary /top_tb1/RK1/FET/bt
add wave -noupdate -group FET /top_tb1/RK1/FET/btype
add wave -noupdate -group FET /top_tb1/RK1/FET/c
add wave -noupdate -group FET /top_tb1/RK1/FET/cc_state
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_valid
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_xfer
add wave -noupdate -group FET /top_tb1/RK1/FET/clk_in
add wave -noupdate -group FET /top_tb1/RK1/FET/clr_rf
add wave -noupdate -group FET /top_tb1/RK1/FET/cpu_halt
add wave -noupdate -group FET /top_tb1/RK1/FET/done
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/flush_reload_addr_in
add wave -noupdate -group FET /top_tb1/RK1/FET/flush_reload_in
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/i
add wave -noupdate -group FET /top_tb1/RK1/FET/i_str
add wave -noupdate -group FET /top_tb1/RK1/FET/ic_ack_in
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/ic_addr_out
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/ic_rd_data_in
add wave -noupdate -group FET /top_tb1/RK1/FET/ic_req_out
add wave -noupdate -group FET /top_tb1/RK1/FET/instr_sz
add wave -noupdate -group FET /top_tb1/RK1/FET/is16
add wave -noupdate -group FET /top_tb1/RK1/FET/is32
add wave -noupdate -group FET /top_tb1/RK1/FET/is48
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/j_imm
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/last_predicted_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rd
add wave -noupdate -group FET /top_tb1/RK1/FET/link_rs1
add wave -noupdate -group FET /top_tb1/RK1/FET/lower5
add wave -noupdate -group FET /top_tb1/RK1/FET/lpa
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/mispredicted_pc
add wave -noupdate -group FET /top_tb1/RK1/FET/mispredicted_pc_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_cc_state
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_ic_req
add wave -noupdate -group FET /top_tb1/RK1/FET/Next_PC
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip_cnt
add wave -noupdate -group FET -radix hexadecimal -childformat {{{/top_tb1/RK1/FET/nxt_que[15]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[14]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[13]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[12]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[11]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[10]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[9]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[8]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[7]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[6]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[5]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[4]} -radix hexadecimal} {{/top_tb1/RK1/FET/nxt_que[3]} -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}}} {{/top_tb1/RK1/FET/nxt_que[2]} -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}}} {{/top_tb1/RK1/FET/nxt_que[1]} -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}}} {{/top_tb1/RK1/FET/nxt_que[0]} -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}}}} -subitemconfig {{/top_tb1/RK1/FET/nxt_que[15]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[14]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[13]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[12]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[11]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[10]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[9]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[8]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[3]} {-height 15 -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}} -expand} {/top_tb1/RK1/FET/nxt_que[3].ipd} {-radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {/top_tb1/RK1/FET/nxt_que[3].ipd.instruction} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[3].ipd.pc} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[3].predicted_addr} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[2]} {-height 15 -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}} -expand} {/top_tb1/RK1/FET/nxt_que[2].ipd} {-radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {/top_tb1/RK1/FET/nxt_que[2].ipd.instruction} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[2].ipd.pc} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[2].predicted_addr} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[1]} {-height 15 -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}} -expand} {/top_tb1/RK1/FET/nxt_que[1].ipd} {-radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {/top_tb1/RK1/FET/nxt_que[1].ipd.instruction} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[1].ipd.pc} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[1].predicted_addr} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[0]} {-height 15 -radix hexadecimal -childformat {{ipd -radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {predicted_addr -radix hexadecimal}} -expand} {/top_tb1/RK1/FET/nxt_que[0].ipd} {-radix hexadecimal -childformat {{instruction -radix hexadecimal} {pc -radix hexadecimal}}} {/top_tb1/RK1/FET/nxt_que[0].ipd.instruction} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[0].ipd.pc} {-radix hexadecimal} {/top_tb1/RK1/FET/nxt_que[0].predicted_addr} {-radix hexadecimal}} /top_tb1/RK1/FET/nxt_que
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/nxt_ras
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_ras_ptr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/PC
add wave -noupdate -group FET /top_tb1/RK1/FET/pc_reload
add wave -noupdate -group FET /top_tb1/RK1/FET/pc_reload_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/pc_str
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/predicted
add wave -noupdate -group FET /top_tb1/RK1/FET/qcnt
add wave -noupdate -group FET /top_tb1/RK1/FET/qfull
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qop
add wave -noupdate -group FET -radix hexadecimal -childformat {{{/top_tb1/RK1/FET/que[15]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[14]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[13]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[12]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[11]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[10]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[9]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[8]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[7]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[6]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[5]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[4]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[3]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[2]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[1]} -radix hexadecimal} {{/top_tb1/RK1/FET/que[0]} -radix hexadecimal}} -subitemconfig {{/top_tb1/RK1/FET/que[15]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[14]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[13]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[12]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[11]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[10]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[9]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[8]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/FET/que[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/FET/que
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/ras
add wave -noupdate -group FET /top_tb1/RK1/FET/ras_ptr
add wave -noupdate -group FET /top_tb1/RK1/FET/rd
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/reload_addr
add wave -noupdate -group FET /top_tb1/RK1/FET/reload_flag
add wave -noupdate -group FET /top_tb1/RK1/FET/reset_in
add wave -noupdate -group FET /top_tb1/RK1/FET/rs1
add wave -noupdate -group FET /top_tb1/RK1/FET/save_lpa
add wave -noupdate -group FET /top_tb1/RK1/FET/xfer_out
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/data
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/valid
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/rdy
add wave -noupdate -group DEC /top_tb1/RK1/DEC/clk_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/reset_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/i_str
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pc_str
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pc_reload
add wave -noupdate -group DEC /top_tb1/RK1/DEC/xfer_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/xfer_out
add wave -noupdate -group DEC /top_tb1/RK1/DEC/full
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/data_in
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/data_out
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/i
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/pc
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/s_imm
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/i_imm
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/b_imm
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/u_imm
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/j_imm
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/shamt
add wave -noupdate -group DEC -group DEC_CORE -radix hexadecimal /top_tb1/RK1/DEC/dcore/csrx
add wave -noupdate -group DEC -group DEC_CORE /top_tb1/RK1/DEC/dcore/cntrl_sigs
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/data
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/valid
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/rdy
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/clk_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/reset_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/i_str
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/pc_str
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/pc_reload
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/pc_reload_addr
add wave -noupdate -expand -group EXE -childformat {{/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr -radix unsigned} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr {-height 15 -radix unsigned} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_mem_gpr
add wave -noupdate -expand -group EXE -childformat {{/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_addr -radix unsigned} {/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_wb_gpr.Rd_addr {-height 15 -radix unsigned} /top_tb1/RK1/EXE/fwd_wb_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/fwd_wb_gpr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/gpr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/alu_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/br_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/csr_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/im_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/idr_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ill_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/sys_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ls_fu_done
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/xfer_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/xfer_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/full
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/Rs1_addr
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/Rs2_addr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/Rs1_rd
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/Rs2_rd
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_data
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_data
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1D
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2D
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/alu_data_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/alu_data_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/br_data_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/br_data_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/im_data_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/im_data_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/idr_data_in
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/idr_data_out.quotient -radix hexadecimal} {/top_tb1/RK1/EXE/idr_data_out.remainder -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/EXE/idr_data_out.quotient {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/idr_data_out.remainder {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/idr_data_out
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/csr_data_in
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/csr_data_out.Rd_data -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.mode -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.trap_pc -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.interrupt_flag -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.interrupt_cause -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.mepc -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.sepc -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.uepc -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.ill_csr_access -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.ill_csr_addr -radix hexadecimal} {/top_tb1/RK1/EXE/csr_data_out.ialign -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/EXE/csr_data_out.Rd_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.mode {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.trap_pc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.interrupt_flag {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.interrupt_cause {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.mepc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.sepc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.uepc {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.ill_csr_access {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.ill_csr_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/csr_data_out.ialign {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/csr_data_out
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/ls_data_in.Rs1_data -radix hexadecimal} {/top_tb1/RK1/EXE/ls_data_in.Rs2_data -radix hexadecimal} {/top_tb1/RK1/EXE/ls_data_in.imm -radix hexadecimal} {/top_tb1/RK1/EXE/ls_data_in.funct3 -radix unsigned}} -subitemconfig {/top_tb1/RK1/EXE/ls_data_in.Rs1_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/ls_data_in.Rs2_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/ls_data_in.imm {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/ls_data_in.funct3 {-height 15 -radix unsigned}} /top_tb1/RK1/EXE/ls_data_in
add wave -noupdate -expand -group EXE -childformat {{/top_tb1/RK1/EXE/ls_data_out.ls_addr -radix unsigned} {/top_tb1/RK1/EXE/ls_data_out.st_data -radix hexadecimal} {/top_tb1/RK1/EXE/ls_data_out.size -radix unsigned}} -expand -subitemconfig {/top_tb1/RK1/EXE/ls_data_out.ls_addr {-height 15 -radix unsigned} /top_tb1/RK1/EXE/ls_data_out.st_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/ls_data_out.size {-height 15 -radix unsigned}} /top_tb1/RK1/EXE/ls_data_out
add wave -noupdate -expand -group EXE -childformat {{/top_tb1/RK1/EXE/exe_dout.ipd -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.ls_addr -radix unsigned} {/top_tb1/RK1/EXE/exe_dout.st_data -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.size -radix unsigned} {/top_tb1/RK1/EXE/exe_dout.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/exe_dout.Rd_data -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/EXE/exe_dout.ipd {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.ls_addr {-height 15 -radix unsigned} /top_tb1/RK1/EXE/exe_dout.st_data {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.size {-height 15 -radix unsigned} /top_tb1/RK1/EXE/exe_dout.Rd_addr {-height 15 -radix hexadecimal} /top_tb1/RK1/EXE/exe_dout.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/exe_dout
add wave -noupdate -group E2M_bus /top_tb1/RK1/E2M_bus/data
add wave -noupdate -group E2M_bus /top_tb1/RK1/E2M_bus/valid
add wave -noupdate -group E2M_bus /top_tb1/RK1/E2M_bus/rdy
add wave -noupdate -group MEM /top_tb1/RK1/MEM/clk_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/reset_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/i_str
add wave -noupdate -group MEM /top_tb1/RK1/MEM/pc_str
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/fwd_mem_gpr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_io_data_out
add wave -noupdate -group MEM /top_tb1/RK1/MEM/mem_io_req_out
add wave -noupdate -group MEM /top_tb1/RK1/MEM/mem_io_ack_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_io_rd_data_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_dout
add wave -noupdate -group MEM /top_tb1/RK1/MEM/xfer_in
add wave -noupdate -group MEM /top_tb1/RK1/MEM/full
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_st
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_ld
add wave -noupdate -group MEM /top_tb1/RK1/MEM/is_ls
add wave -noupdate -group MEM /top_tb1/RK1/MEM/xfer_out
add wave -noupdate -group M2W_bus /top_tb1/RK1/M2W_bus/data
add wave -noupdate -group M2W_bus /top_tb1/RK1/M2W_bus/valid
add wave -noupdate -group M2W_bus /top_tb1/RK1/M2W_bus/rdy
add wave -noupdate -group WB /top_tb1/RK1/WB/clk_in
add wave -noupdate -group WB /top_tb1/RK1/WB/reset_in
add wave -noupdate -group WB /top_tb1/RK1/WB/i_str
add wave -noupdate -group WB /top_tb1/RK1/WB/pc_str
add wave -noupdate -group WB -radix hexadecimal -childformat {{/top_tb1/RK1/WB/fwd_wb_gpr.valid -radix hexadecimal} {/top_tb1/RK1/WB/fwd_wb_gpr.Rd_wr -radix hexadecimal} {/top_tb1/RK1/WB/fwd_wb_gpr.Rd_addr -radix unsigned} {/top_tb1/RK1/WB/fwd_wb_gpr.Rd_data -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/WB/fwd_wb_gpr.valid {-height 15 -radix hexadecimal} /top_tb1/RK1/WB/fwd_wb_gpr.Rd_wr {-height 15 -radix hexadecimal} /top_tb1/RK1/WB/fwd_wb_gpr.Rd_addr {-height 15 -radix unsigned} /top_tb1/RK1/WB/fwd_wb_gpr.Rd_data {-height 15 -radix hexadecimal}} /top_tb1/RK1/WB/fwd_wb_gpr
add wave -noupdate -group WB /top_tb1/RK1/WB/gpr_Rd_wr
add wave -noupdate -group WB -radix unsigned /top_tb1/RK1/WB/gpr_Rd_addr
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/gpr_Rd_data
add wave -noupdate -group WB /top_tb1/RK1/WB/xfer_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/clk_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/reset_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/gpr_Rd_wr
add wave -noupdate -expand -group GPR -radix unsigned /top_tb1/RK1/GPR/gpr_Rd_addr
add wave -noupdate -expand -group GPR -radix unsigned /top_tb1/RK1/GPR/gpr_Rd_data
add wave -noupdate -expand -group GPR -childformat {{{/top_tb1/RK1/GPR/gpr[31]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[30]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[29]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[28]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[27]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[26]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[25]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[24]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[23]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[22]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[21]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[20]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[19]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[18]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[17]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[16]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[15]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[14]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[13]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[12]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[11]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[10]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[9]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[8]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[7]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[6]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[5]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[4]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[3]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[2]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[1]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb1/RK1/GPR/gpr[31]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[30]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[29]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[28]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[27]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[26]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[25]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[24]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[23]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[22]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[21]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[20]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[19]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[18]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[17]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[16]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[15]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[14]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[13]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[12]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[11]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[10]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[9]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[8]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[7]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[6]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[5]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[4]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[3]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[2]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[1]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[0]} {-height 15 -radix unsigned}} /top_tb1/RK1/GPR/gpr
add wave -noupdate -group L1_ic /top_tb1/L1_ic/clk_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/reset_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/cache_mem
add wave -noupdate -group L1_ic /top_tb1/L1_ic/cache_tag
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_req_addr_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_req_valid_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_req_rdy_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_ack_data_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_ack_valid_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_ack_rdy_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_addr_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_req_in
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_ack_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_rd_data_out
add wave -noupdate -group L1_ic /top_tb1/L1_ic/ic_flush
add wave -noupdate -group L1_ic /top_tb1/L1_ic/cache_valid
add wave -noupdate -group L1_ic /top_tb1/L1_ic/lru
add wave -noupdate -group L1_ic /top_tb1/L1_ic/next_lru
add wave -noupdate -group L1_ic -radix hexadecimal /top_tb1/L1_ic/current_cache_line
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
add wave -noupdate -group L1_ic /top_tb1/L1_ic/Next_IC_State
add wave -noupdate -group L1_ic /top_tb1/L1_ic/IC_State
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_ack_xfer
add wave -noupdate -group L1_ic /top_tb1/L1_ic/arb_req_xfer
add wave -noupdate -group L1_ic /top_tb1/L1_ic/h
add wave -noupdate -group L1_ic /top_tb1/L1_ic/n
add wave -noupdate -group L1_ic /top_tb1/L1_ic/l
add wave -noupdate -group L1_ic /top_tb1/L1_ic/p
add wave -noupdate -group L1_ic /top_tb1/L1_ic/val
add wave -noupdate -group L1_ic /top_tb1/L1_ic/update_lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/clk_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/reset_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_mem
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_req_data_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_req_valid_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_req_rdy_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_ack_data_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_ack_valid_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/arb_ack_rdy_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_data_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_req_in
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_ack_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_rd_data_out
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dc_flush
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_valid
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cache_dirty
add wave -noupdate -group L1_dc /top_tb1/L1_dc/lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/next_lru
add wave -noupdate -group L1_dc /top_tb1/L1_dc/current_cache_line
add wave -noupdate -group L1_dc /top_tb1/L1_dc/norm_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/norm_set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set
add wave -noupdate -group L1_dc /top_tb1/L1_dc/way
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set_way
add wave -noupdate -group L1_dc /top_tb1/L1_dc/hit
add wave -noupdate -group L1_dc /top_tb1/L1_dc/ecf
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dcf_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr_cpu_data
add wave -noupdate -group L1_dc /top_tb1/L1_dc/zx
add wave -noupdate -group L1_dc /top_tb1/L1_dc/sz
add wave -noupdate -group L1_dc /top_tb1/L1_dc/set_bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/clr_bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/bc_ff
add wave -noupdate -group L1_dc /top_tb1/L1_dc/dirty
add wave -noupdate -group L1_dc /top_tb1/L1_dc/hit_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/ecf_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/lru_num
add wave -noupdate -group L1_dc /top_tb1/L1_dc/save_info
add wave -noupdate -group L1_dc /top_tb1/L1_dc/wr_arb_data
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tmp_cache_line
add wave -noupdate -group L1_dc /top_tb1/L1_dc/tmp_cache_tag
add wave -noupdate -group L1_dc /top_tb1/L1_dc/save_tmp_cl
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cla
add wave -noupdate -group L1_dc /top_tb1/L1_dc/std
add wave -noupdate -group L1_dc /top_tb1/L1_dc/cm_wr
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
add wave -noupdate -group L1_dc /top_tb1/L1_dc/update_lru
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/clk_in
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/reset_in
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_data_in
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_data_out
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/csr_addr
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_valid
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/Rd_addr
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/Rs1_addr
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/Rs1_data
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_funct
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/current_events
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mret
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/mtime
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ext_irq
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/time_irq
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/sw_irq
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_rd_data
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mode
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/nxt_mode
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/trap_pc
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/interrupt_flag
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mepc
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ill_csr_access
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ialign
add wave -noupdate -group CSR_FU -radix unsigned /top_tb1/RK1/EXE/CFU/imm_data
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_wr_data
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_wr
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_rd
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/sd
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/tsr
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/tw
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/tvm
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mxr
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/sum
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mprv
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/xs
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/fs
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mpp
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/spp
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mpie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/spie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/upie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/sie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/uie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/interrupt_cause
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/usip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/utip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ueip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ssip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/stip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/seip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/msip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mtip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/meip
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/m_irq
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/s_irq
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/u_irq
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/usie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ssie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/msie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/utie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/stie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/mtie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/ueie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/seie
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/meie
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_mtvec
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_mcause
add wave -noupdate -group CSR_FU -radix hexadecimal /top_tb1/RK1/EXE/CFU/csr_mstatus
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/lowest_priv
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/writable
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_avail
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_mcounteren
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_mcountinhibit
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_mhpmevent
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_mcycle_lo
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_mcycle_hi
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/tot_retired
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_minstret_lo
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/csr_minstret_hi
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/events
add wave -noupdate -group CSR_FU -radix hexadecimal -childformat {{{/top_tb1/RK1/EXE/CFU/mhpmcounter[-1]} -radix hexadecimal} {{/top_tb1/RK1/EXE/CFU/mhpmcounter[0]} -radix hexadecimal}} -expand -subitemconfig {{/top_tb1/RK1/EXE/CFU/mhpmcounter[-1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/EXE/CFU/mhpmcounter[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/CFU/mhpmcounter
add wave -noupdate -group CSR_FU -radix hexadecimal -childformat {{{/top_tb1/RK1/EXE/CFU/nxt_mhpmcounter[-1]} -radix hexadecimal} {{/top_tb1/RK1/EXE/CFU/nxt_mhpmcounter[0]} -radix hexadecimal}} -expand -subitemconfig {{/top_tb1/RK1/EXE/CFU/nxt_mhpmcounter[-1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/EXE/CFU/nxt_mhpmcounter[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/EXE/CFU/nxt_mhpmcounter
add wave -noupdate -group CSR_FU /top_tb1/RK1/EXE/CFU/br_retired
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {610044 ps} 0}
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
WaveRestoreZoom {0 ps} {1552950 ps}
