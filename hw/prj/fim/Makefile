.PHONY: all build-bin build-syn build-edt build-sim

FIM_SRC_FILE=../../src/ipi/fim_debug.bd.tcl

all: build-bin

build-bin:
	rm ./output -rf
	mkdir output
	vivado -mode batch -source run_proj.tcl -tclargs $(FIM_SRC_FILE)

build-syn:
	vivado -mode batch -source syn_proj.tcl -tclargs $(FIM_SRC_FILE)

build-edt: 
	vivado -mode gui   -source edt_proj.tcl -tclargs $(FIM_SRC_FILE)

build-sim: 
	vivado -mode batch -source sim_proj.tcl -tclargs $(FIM_SRC_FILE)
	bash sim_fim.sh $(FIM_SRC_FILE)

lean:
	bash cleanup.sh
	#rm vivado* *webtalk* -f
	#rm .Xil proj_* hd_visual output -rf


