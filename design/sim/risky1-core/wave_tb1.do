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
add wave -noupdate -group FET /top_tb1/RK1/FET/ic_reload
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/pc_reload_addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/PC
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qcnt
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip_cnt
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/que
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_que
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_qip
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/qop
add wave -noupdate -group FET /top_tb1/RK1/FET/xfer_out
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_xfer
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/predicted
add wave -noupdate -group FET /top_tb1/RK1/FET/bt
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/addr
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/Next_PC
add wave -noupdate -group FET -radix hexadecimal /top_tb1/RK1/FET/reload_addr
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
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/nxt_ras_ptr
add wave -noupdate -group FET /top_tb1/RK1/FET/ras
add wave -noupdate -group FET /top_tb1/RK1/FET/nxt_ras
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
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/instr_sz
add wave -noupdate -group FET /top_tb1/RK1/FET/is16
add wave -noupdate -group FET /top_tb1/RK1/FET/is32
add wave -noupdate -group FET /top_tb1/RK1/FET/is48
add wave -noupdate -group FET /top_tb1/RK1/FET/lower5
add wave -noupdate -group FET -radix unsigned /top_tb1/RK1/FET/bit_pos
add wave -noupdate -group FET /top_tb1/RK1/FET/cl_valid
add wave -noupdate -group FET /top_tb1/RK1/FET/c
add wave -noupdate -group F2D_bus -radix hexadecimal /top_tb1/RK1/F2D_bus/data
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/valid
add wave -noupdate -group F2D_bus /top_tb1/RK1/F2D_bus/rdy
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/i
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/pc
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/s_imm
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/i_imm
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/b_imm
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/u_imm
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/j_imm
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/shamt
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/csrx
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/Rd_addr
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/Rs1_addr
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/Rs2_addr
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/funct3
add wave -noupdate -group {DEC - old} -group dcore /top_tb1/RK1/DEC/dcore/cntrl_sigs
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/clk_in
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/reset_in
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/cpu_halt
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/full
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/i_str
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/pc_str
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/pipe_flush
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/rd_pipe_in
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/rd_pipe_out
add wave -noupdate -group {DEC - old} /top_tb1/RK1/DEC/wr_pipe_out
add wave -noupdate -group DEC /top_tb1/RK1/DEC/clk_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/reset_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/cpu_halt
add wave -noupdate -group DEC /top_tb1/RK1/DEC/pipe_flush
add wave -noupdate -group DEC /top_tb1/RK1/DEC/rd_pipe_in
add wave -noupdate -group DEC /top_tb1/RK1/DEC/rd_pipe_out
add wave -noupdate -group DEC /top_tb1/RK1/DEC/wr_pipe_out
add wave -noupdate -group DEC /top_tb1/RK1/DEC/full
add wave -noupdate -group DEC -radix hexadecimal -childformat {{/top_tb1/RK1/DEC/dec_out.ipd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.predicted_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs1_rd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs2_rd -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rd_wr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.i_type -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.sel_x -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.sel_y -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.op -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.ci -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.imm -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.funct3 -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs2_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rs1_addr -radix hexadecimal} {/top_tb1/RK1/DEC/dec_out.Rd_addr -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/DEC/dec_out.ipd {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.predicted_addr {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs1_rd {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs2_rd {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rd_wr {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.i_type {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.sel_x {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.sel_y {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.op {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.ci {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.imm {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.funct3 {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs2_addr {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rs1_addr {-radix hexadecimal} /top_tb1/RK1/DEC/dec_out.Rd_addr {-radix hexadecimal}} /top_tb1/RK1/DEC/dec_out
add wave -noupdate -group D2E_bus -radix hexadecimal /top_tb1/RK1/D2E_bus/data
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/valid
add wave -noupdate -group D2E_bus /top_tb1/RK1/D2E_bus/rdy
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/clk_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/reset_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/cpu_halt
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/pipe_flush
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/rld_pc_flag
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/rld_pc_addr
add wave -noupdate -expand -group EXE -radix unsigned /top_tb1/RK1/EXE/mode
add wave -noupdate -expand -group EXE -radix hexadecimal -childformat {{/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr -radix hexadecimal} {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/EXE/fwd_mem_gpr.Rd_addr {-radix hexadecimal} /top_tb1/RK1/EXE/fwd_mem_gpr.Rd_data {-radix hexadecimal}} /top_tb1/RK1/EXE/fwd_mem_gpr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/fwd_wb_gpr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/gpr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/rd_pipe_in
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/rd_pipe_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/wr_pipe_out
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/full
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/exe_dout
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rd_addr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_addr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_addr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rd_wr
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_rd
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs2_rd
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/Rs1_data
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
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/op_type
add wave -noupdate -expand -group EXE -radix hexadecimal /top_tb1/RK1/EXE/predicted_addr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/br_pc
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/mepc
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/sepc
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/uepc
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ill_csr_access
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ill_csr_addr
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/i_type
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/ci
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/mret
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/sret
add wave -noupdate -expand -group EXE /top_tb1/RK1/EXE/uret
add wave -noupdate -group E2M_bus -radix hexadecimal -childformat {{/top_tb1/RK1/E2M_bus/data.ipd -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.ls_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.st_data -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.size -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.zero_ext -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.inv_flag -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.is_ld -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.is_st -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.mis -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.mispre -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.ci -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.predicted_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.br_pc -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.i_type -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.op_type -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_wr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_addr -radix hexadecimal} {/top_tb1/RK1/E2M_bus/data.Rd_data -radix hexadecimal}} -subitemconfig {/top_tb1/RK1/E2M_bus/data.ipd {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.ls_addr {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.st_data {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.size {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.zero_ext {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.inv_flag {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.is_ld {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.is_st {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.mis {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.mispre {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.ci {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.predicted_addr {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.br_pc {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.i_type {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.op_type {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_wr {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_addr {-radix hexadecimal} /top_tb1/RK1/E2M_bus/data.Rd_data {-radix hexadecimal}} /top_tb1/RK1/E2M_bus/data
add wave -noupdate -group E2M_bus -radix hexadecimal /top_tb1/RK1/E2M_bus/valid
add wave -noupdate -group E2M_bus -radix hexadecimal /top_tb1/RK1/E2M_bus/rdy
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/clk_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/reset_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ext_irq
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/time_irq
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/sw_irq
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mtime
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/pipe_flush
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/rld_pc_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/rld_ic_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/rld_pc_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/cpu_halt
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/fwd_mem_gpr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mem_dout
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/rd_pipe_out
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/wr_pipe_out
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/rd_pipe_in
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/full
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_ls
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ls_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/st_data
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/size
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/zero_ext
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/inv_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_ld
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/is_st
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mis
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mispre
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ci
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/br_pc
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/Rd_wr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/Rd_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/Rd_data
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/trigger_wfi
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/i_type
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/op_type
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ipd
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/predicted_addr
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/interrupt_flag
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/interrupt_cause
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/trap_pc
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/ialign
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/mode
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/exception
add wave -noupdate -group MEM -radix hexadecimal /top_tb1/RK1/MEM/current_events
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/data
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/valid
add wave -noupdate -group M2W_bus -radix hexadecimal /top_tb1/RK1/M2W_bus/rdy
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/req
add wave -noupdate -group MIO_bus -radix hexadecimal -childformat {{/top_tb1/RK1/MIO_bus/req_data.rd -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.wr -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr -radix hexadecimal -childformat {{{[31]} -radix hexadecimal} {{[30]} -radix hexadecimal} {{[29]} -radix hexadecimal} {{[28]} -radix hexadecimal} {{[27]} -radix hexadecimal} {{[26]} -radix hexadecimal} {{[25]} -radix hexadecimal} {{[24]} -radix hexadecimal} {{[23]} -radix hexadecimal} {{[22]} -radix hexadecimal} {{[21]} -radix hexadecimal} {{[20]} -radix hexadecimal} {{[19]} -radix hexadecimal} {{[18]} -radix hexadecimal} {{[17]} -radix hexadecimal} {{[16]} -radix hexadecimal} {{[15]} -radix hexadecimal} {{[14]} -radix hexadecimal} {{[13]} -radix hexadecimal} {{[12]} -radix hexadecimal} {{[11]} -radix hexadecimal} {{[10]} -radix hexadecimal} {{[9]} -radix hexadecimal} {{[8]} -radix hexadecimal} {{[7]} -radix hexadecimal} {{[6]} -radix hexadecimal} {{[5]} -radix hexadecimal} {{[4]} -radix hexadecimal} {{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/top_tb1/RK1/MIO_bus/req_data.wr_data -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.size -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.zero_ext -radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.inv_flag -radix hexadecimal}} -expand -subitemconfig {/top_tb1/RK1/MIO_bus/req_data.rd {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.wr {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.rw_addr {-height 15 -radix hexadecimal -childformat {{{[31]} -radix hexadecimal} {{[30]} -radix hexadecimal} {{[29]} -radix hexadecimal} {{[28]} -radix hexadecimal} {{[27]} -radix hexadecimal} {{[26]} -radix hexadecimal} {{[25]} -radix hexadecimal} {{[24]} -radix hexadecimal} {{[23]} -radix hexadecimal} {{[22]} -radix hexadecimal} {{[21]} -radix hexadecimal} {{[20]} -radix hexadecimal} {{[19]} -radix hexadecimal} {{[18]} -radix hexadecimal} {{[17]} -radix hexadecimal} {{[16]} -radix hexadecimal} {{[15]} -radix hexadecimal} {{[14]} -radix hexadecimal} {{[13]} -radix hexadecimal} {{[12]} -radix hexadecimal} {{[11]} -radix hexadecimal} {{[10]} -radix hexadecimal} {{[9]} -radix hexadecimal} {{[8]} -radix hexadecimal} {{[7]} -radix hexadecimal} {{[6]} -radix hexadecimal} {{[5]} -radix hexadecimal} {{[4]} -radix hexadecimal} {{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[31]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[30]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[29]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[28]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[27]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[26]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[25]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[24]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[23]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[22]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[21]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[20]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[19]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[18]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[17]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[16]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[15]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[14]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[13]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[12]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[11]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[10]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[9]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[8]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[7]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[6]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[5]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[4]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[3]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[2]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[1]} {-radix hexadecimal} {/top_tb1/RK1/MIO_bus/req_data.rw_addr[0]} {-radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.wr_data {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.size {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.zero_ext {-height 15 -radix hexadecimal} /top_tb1/RK1/MIO_bus/req_data.inv_flag {-height 15 -radix hexadecimal}} /top_tb1/RK1/MIO_bus/req_data
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/ack
add wave -noupdate -group MIO_bus /top_tb1/RK1/MIO_bus/ack_fault
add wave -noupdate -group MIO_bus -radix hexadecimal -childformat {{{/top_tb1/RK1/MIO_bus/ack_data[31]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[30]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[29]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[28]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[27]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[26]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[25]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[24]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[23]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[22]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[21]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[20]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[19]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[18]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[17]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[16]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[15]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[14]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[13]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[12]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[11]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[10]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[9]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[8]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[7]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[6]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[5]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[4]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[3]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[2]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[1]} -radix hexadecimal} {{/top_tb1/RK1/MIO_bus/ack_data[0]} -radix hexadecimal}} -subitemconfig {{/top_tb1/RK1/MIO_bus/ack_data[31]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[30]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[29]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[28]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[27]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[26]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[25]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[24]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[23]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[22]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[21]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[20]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[19]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[18]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[17]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[16]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[15]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[14]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[13]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[12]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[11]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[10]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[9]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[8]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[7]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[6]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[5]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[4]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[3]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[2]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[1]} {-height 15 -radix hexadecimal} {/top_tb1/RK1/MIO_bus/ack_data[0]} {-height 15 -radix hexadecimal}} /top_tb1/RK1/MIO_bus/ack_data
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/clk_in
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/reset_in
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/cpu_halt
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/fwd_wb_gpr
add wave -noupdate -group WB -radix hexadecimal /top_tb1/RK1/WB/xfer_in
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mode
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/msip_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtime_lo_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtime_hi_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtimecmp_lo_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtimecmp_hi_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mmr_wr_data
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtime
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/mtimecmp
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/msip_reg
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/sim_stop
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_req
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_addr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_rd
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_wr
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_wr_data
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_rd_data
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_ack
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/io_ack_fault
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/is_phy_mem
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/is_int_io
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/is_ext_io
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/access_fault
add wave -noupdate -group MEM_IO -radix hexadecimal /top_tb1/RK1/MEM_IO/is_io_access
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_wr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_addr
add wave -noupdate -group gpr_bus /top_tb1/RK1/gpr_bus/Rd_data
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/clk_in
add wave -noupdate -expand -group GPR /top_tb1/RK1/GPR/reset_in
add wave -noupdate -expand -group GPR -radix unsigned -childformat {{{/top_tb1/RK1/GPR/gpr[31]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[30]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[29]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[28]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[27]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[26]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[25]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[24]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[23]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[22]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[21]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[20]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[19]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[18]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[17]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[16]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[15]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[14]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[13]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[12]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[11]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[10]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[9]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[8]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[7]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[6]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[5]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[4]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[3]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[2]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[1]} -radix unsigned} {{/top_tb1/RK1/GPR/gpr[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb1/RK1/GPR/gpr[31]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[30]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[29]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[28]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[27]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[26]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[25]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[24]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[23]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[22]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[21]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[20]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[19]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[18]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[17]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[16]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[15]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[14]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[13]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[12]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[11]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[10]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[9]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[8]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[7]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[6]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[5]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[4]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[3]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[2]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[1]} {-height 15 -radix unsigned} {/top_tb1/RK1/GPR/gpr[0]} {-height 15 -radix unsigned}} /top_tb1/RK1/GPR/gpr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/clk_in
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/reset_in
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtime_lo_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtime_hi_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtimecmp_lo_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mtimecmp_hi_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/mmr_wr_data
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/msip_wr
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/time_irq
add wave -noupdate -group IRQ -radix hexadecimal /top_tb1/RK1/IRQ/sw_irq
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
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/req_data
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/req_valid
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/req_rdy
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/ack_data
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/ack_valid
add wave -noupdate -expand -group DC_arb_bus /top_tb1/DC_arb_bus/ack_rdy
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/clk_in
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/reset_in
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/arb_state
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/next_arb_state
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/wr_data
add wave -noupdate -expand -group {Cache Arbiter} -radix hexadecimal /top_tb1/carb/rd_data
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/rw_addr
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/rw
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/save_ic_info
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/save_dc_info
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/save_rd_data
add wave -noupdate -expand -group {Cache Arbiter} /top_tb1/carb/is_ic_cycle
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_rw
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_addr
add wave -noupdate -group sysmem_bus -radix hexadecimal /top_tb1/sysmem_bus/req_wr_data
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_valid
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/req_rdy
add wave -noupdate -group sysmem_bus -radix hexadecimal /top_tb1/sysmem_bus/ack_rd_data
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/ack_valid
add wave -noupdate -group sysmem_bus /top_tb1/sysmem_bus/ack_rdy
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/clk_in
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/reset_in
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/sys_mem
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/b4
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/k
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/bp
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/ndx
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/p
add wave -noupdate -expand -group {Sys Mem} /top_tb1/sm/wr_data
add wave -noupdate -expand -group {Sys Mem} -radix hexadecimal /top_tb1/sm/b_addr
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
