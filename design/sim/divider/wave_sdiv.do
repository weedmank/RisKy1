onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /sdiv_tb/reset
add wave -noupdate -group TB /sdiv_tb/clk_100
add wave -noupdate -group TB /sdiv_tb/debug
add wave -noupdate -group TB -radix unsigned /sdiv_tb/clock_cycle
add wave -noupdate -group TB /sdiv_tb/record_bin
add wave -noupdate -group TB /sdiv_tb/start
add wave -noupdate -group TB /sdiv_tb/done
add wave -noupdate -group TB /sdiv_tb/clk_cnt
add wave -noupdate -group TB -radix unsigned /sdiv_tb/dividend
add wave -noupdate -group TB -radix unsigned /sdiv_tb/divisor
add wave -noupdate -group TB -radix unsigned /sdiv_tb/quotient
add wave -noupdate -group TB -radix unsigned /sdiv_tb/remainder
add wave -noupdate -group TB /sdiv_tb/q
add wave -noupdate -group TB /sdiv_tb/r
add wave -noupdate -expand -group divu32x32 /sdiv_tb/sstart
add wave -noupdate -expand -group divu32x32 /sdiv_tb/sdone
add wave -noupdate -expand -group divu32x32 -radix decimal /sdiv_tb/sdividend
add wave -noupdate -expand -group divu32x32 -radix decimal /sdiv_tb/sdivisor
add wave -noupdate -expand -group divu32x32 -radix decimal /sdiv_tb/squotient
add wave -noupdate -expand -group divu32x32 /sdiv_tb/sremainder
add wave -noupdate -expand -group divu32x32 /sdiv_tb/sdone
add wave -noupdate -expand -group divu32x32 /sdiv_tb/div_unsigned/clk_in
add wave -noupdate -expand -group divu32x32 /sdiv_tb/div_unsigned/reset_in
add wave -noupdate -expand -group divu32x32 /sdiv_tb/div_unsigned/start
add wave -noupdate -expand -group divu32x32 /sdiv_tb/div_unsigned/run
add wave -noupdate -expand -group divu32x32 /sdiv_tb/div_unsigned/done
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/dividend
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/divisor
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/quotient
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/remainder
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/nxt_num
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/num
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/num_sel
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/nxt_q
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/q
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/q_sel
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/t1
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/t2
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/shift1
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/shift2
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/ms_num
add wave -noupdate -expand -group divu32x32 -radix hexadecimal /sdiv_tb/div_unsigned/hotmask
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/hotbit
add wave -noupdate -expand -group divu32x32 -radix unsigned /sdiv_tb/div_unsigned/ms_den
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {36329643 ps} 0}
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
WaveRestoreZoom {36240691 ps} {36463641 ps}
