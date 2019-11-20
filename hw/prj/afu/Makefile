.PHONY: all build-bin build-syn build-edt build-sim

AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl
AFU_IP_PATH=

all: build-syn

build-bin: 

build-syn:
	vivado -mode batch -source syn_proj.tcl -tclargs $(AFU_SRC_FILE)

build-edt: 
	vivado -mode gui   -source edt_proj.tcl -tclargs $(AFU_SRC_FILE) $(AFU_IP_PATH)

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual -rf

