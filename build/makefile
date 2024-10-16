.PHONY: synth sim clean

TESTBENCH_FILE = ../tests/top_tb.v
TOPLEVEL_FILE  = ../source/top.v

synth:
	yosys \
		-l ../logs/yosys_log.txt \
		-p "read_verilog $(TOPLEVEL_FILE);  hierarchy \
		-libdir ../source/clk  \
		-libdir ../source/dds  \
		-libdir ../source/fifo \
		-libdir ../source/i2s  \
		-libdir ../source/midi  \
		-libdir ../source/ram  \
		-libdir ../source/uart;\
		synth_ice40 -noflatten; \
		write_blif fpga-audio.blif; \
		write_json fpga-audio.json;"
	nextpnr-ice40 -l ../logs/nextpnr_log.txt --hx1k --package tq144 --json fpga-audio.json --pcf constraint.pcf --asc fpga-audio.asc
	icetime -p constraint.pcf -P tq144 -d hx1k -t fpga-audio.asc -r ../logs/icetime_log.txt
	icepack fpga-audio.asc bitstream.bin

sim:
	iverilog \
		-o fpga-audio.out -g2012 \
		-Y .v \
		-y ../source/clk  \
		-y ../source/dds  \
		-y ../source/fifo \
		-y ../source/i2s  \
		-y ../source/midi  \
		-y ../source/ram  \
		-y ../source/uart \
		-y ../source      \
		-l ../source/cells_sim.v \
		$(TESTBENCH_FILE)
	vvp -l ../logs/iverilog_log.txt fpga-audio.out

clean:
	rm -f *.json *.blif *.asc *.bin
	rm -f *.out *.vcd