.PHONY: all build-bin build-syn build-edt build-sim

AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl
AFU_IP_FILE=./add_afu_ip_path.tcl

all: build-bin

build-bin: 
	rm ./dcp -rf
	mkdir dcp
	cp ../blue_bs/export/* ./dcp/.
	
	rm ./output -rf
	mkdir output
	
	vivado -mode batch -source run_proj.tcl -tclargs $(AFU_SRC_FILE) $(AFU_IP_FILE)

build-syn:

build-edt: 

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual dcp output -r
