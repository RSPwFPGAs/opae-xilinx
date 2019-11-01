.PHONY: all build-bin build-syn build-edt build-sim

AFU_SRC_FILE = ../../src/ipi/afu_customer_1.bd.tcl
AFU_CUS_FILE = ../../src/afu_cusomize/ipi_flow/afu_customize_flow.tcl

all: build-bin

build-bin: 
	rm ./dcp -rf
	mkdir dcp
	cp ../blue_bs/export/* ./dcp/.
	
	rm ./output -rf
	mkdir output
	
	vivado -mode batch -source run_proj.tcl -tclargs $(AFU_SRC_FILE) $(AFU_CUS_FILE)

build-syn:

build-edt: 

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual dcp output -rf

