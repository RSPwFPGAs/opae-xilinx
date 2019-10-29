.PHONY: all build-bin build-syn build-edt build-sim

all: build-bin

build-bin:
	rm ./output -rf
	mkdir output
	vivado -mode batch -source run_proj.tcl

build-syn:
	vivado -mode batch -source syn_proj.tcl

build-edt: 
	vivado -mode gui   -source edt_proj.tcl

build-sim: 
	vivado -mode batch -source sim_proj.tcl

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual output -rf

