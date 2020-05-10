.PHONY: all build-bin build-syn build-edt build-sim

FIM_SRC_FILE=../../src/ipi/fim_debug.bd.tcl
FIM_BRD_TYPE=kcu105

all: build-bin

build-bin:
	rm ./output -rf
	mkdir output
	vivado -mode batch -source run_proj.tcl -tclargs $(FIM_SRC_FILE) $(FIM_BRD_TYPE)

build-syn:
	vivado -mode batch -source syn_proj.tcl -tclargs $(FIM_SRC_FILE) $(FIM_BRD_TYPE)

build-edt: 
	vivado -mode gui   -source edt_proj.tcl -tclargs $(FIM_SRC_FILE) $(FIM_BRD_TYPE)

build-sim: 
	vivado -mode batch -source sim_proj.tcl -tclargs $(FIM_SRC_FILE) $(FIM_BRD_TYPE)
	bash sim_fim.sh $(FIM_SRC_FILE)

clean:
	bash cleanup.sh
	#rm vivado* *webtalk* -f
	#rm .Xil proj_* hd_visual output -rf


