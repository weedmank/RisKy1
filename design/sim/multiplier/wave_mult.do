onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /mult_tb/reset
add wave -noupdate -group TB /mult_tb/clk_100
add wave -noupdate -group TB /mult_tb/debug
add wave -noupdate -group TB /mult_tb/clock_cycle
add wave -noupdate -group TB /mult_tb/start
add wave -noupdate -group TB /mult_tb/done
add wave -noupdate -group TB /mult_tb/a
add wave -noupdate -group TB /mult_tb/b
add wave -noupdate -group TB /mult_tb/result
add wave -noupdate -group TB /mult_tb/is_signed
add wave -noupdate -group TB /mult_tb/sstart
add wave -noupdate -group TB /mult_tb/sdone
add wave -noupdate -group TB /mult_tb/sa
add wave -noupdate -group TB /mult_tb/sb
add wave -noupdate -group TB /mult_tb/sresult
add wave -noupdate -group TB /mult_tb/record_bin
add wave -noupdate -group TB /mult_tb/k
add wave -noupdate -group TB /mult_tb/r
add wave -noupdate -group TB /mult_tb/sr
add wave -noupdate -group TB /mult_tb/clk_cnt
add wave -noupdate /mult_tb/clock_cycle
add wave -noupdate -expand -group {mult1 (unsigned)} /mult_tb/mult1/clk_in
add wave -noupdate -expand -group {mult1 (unsigned)} /mult_tb/mult1/reset_in
add wave -noupdate -expand -group {mult1 (unsigned)} /mult_tb/mult1/is_signed
add wave -noupdate -expand -group {mult1 (unsigned)} /mult_tb/mult1/start
add wave -noupdate -expand -group {mult1 (unsigned)} /mult_tb/mult1/done
add wave -noupdate -expand -group {mult1 (unsigned)} -radix unsigned /mult_tb/mult1/a
add wave -noupdate -expand -group {mult1 (unsigned)} -radix unsigned /mult_tb/mult1/b
add wave -noupdate -expand -group {mult1 (unsigned)} -radix unsigned /mult_tb/mult1/result
add wave -noupdate -expand -group {mult1 (unsigned)} -radix unsigned /mult_tb/mult1/j
add wave -noupdate -expand -group {mult1 (unsigned)} -radix unsigned /mult_tb/mult1/k
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/clk_in
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/reset_in
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/is_signed
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/start
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/done
add wave -noupdate -group {mult2 (signed)} -radix decimal /mult_tb/mult2/a
add wave -noupdate -group {mult2 (signed)} -radix decimal /mult_tb/mult2/b
add wave -noupdate -group {mult2 (signed)} -radix decimal /mult_tb/mult2/result
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/flg
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/j
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/k
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/l
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/x
add wave -noupdate -group {mult2 (signed)} /mult_tb/mult2/xc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {54971732 ps} 0}
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
WaveRestoreZoom {47236196 ps} {57152732 ps}
