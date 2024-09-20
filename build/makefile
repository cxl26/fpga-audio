.PHONY: synth sim clean

TESTBENCH_FILE = ../source/fifo/tb/async_fifo_tb.v
TOPLEVEL_FILE  = ../source/fifo/async_fifo.v

synth:
	export TOPLEVEL_FILE=$(TOPLEVEL_FILE)
	yosys -l ../logs/yosys_log.txt -q synth_script.ys
	nextpnr-ice40 -l ../logs/nextpnr_log.txt --hx1k --package tq144 --json fpga-audio.json --pcf constraint.pcf --asc fpga-audio.asc
	icetime -p constraint.pcf -P tq144 -d hx1k -t fpga-audio.asc
	icepack fpga-audio.asc bitstream.bin

sim:
	export TESTBENCH_FILE=$(TESTBENCH_FILE)
	iverilog -o fpga-audio.out -c sim_script.cf
	vvp -l ../logs/iverilog_log.txt fpga-audio.out

clean:
	rm -f *.json *.blif *.asc *.bin
	rm -f *.out *.vcd