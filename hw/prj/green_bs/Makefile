.PHONY: all build-bin build-syn build-edt build-sim

AFU_SRC_FILE = ../../src/ipi/afu_customer_1.bd.tcl
AFU_HLS_PATH = ../../src/afu_customize/hls_flow/try1

all: build-bin

build-bin: build-hls-ip 
	rm ./dcp -rf
	mkdir dcp
	cp ../blue_bs/export/* ./dcp/.
	
	rm ./output -rf
	mkdir output
	
	vivado -mode batch -source run_proj.tcl -tclargs $(AFU_SRC_FILE) $(AFU_HLS_PATH)

build-syn:

build-edt: 

build-sim: 

build-hls-ip:
	cd $(AFU_HLS_PATH); \
	vivado_hls -f run_hls.ipi.tcl

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual dcp output -r
