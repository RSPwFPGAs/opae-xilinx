.PHONY: all build-bin build-syn build-edt build-sim

AFU_SRC_FILE = ../../src/ipi/afu_customer_1.bd.tcl
AFU_HLS_PATH = ../../src/afu_customize/hls_flow/try1

all: build-syn

build-bin: 

build-syn:
	vivado -mode batch -source syn_proj.tcl -tclargs $(AFU_SRC_FILE)

build-edt: 
	vivado -mode gui   -source edt_proj.tcl -tclargs $(AFU_SRC_FILE)

build-sim: 

build-hls-ip:
	cd $(AFU_HLS_PATH); \
	vivado_hls -f run_hls.ipi.tcl

build-hls: build-hls-ip
	vivado -mode gui   -source edt_proj.tcl -source hls_proj.tcl -tclargs $(AFU_SRC_FILE) $(AFU_HLS_PATH) 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual -rf
	rm $(AFU_HLS_PATH)/vivado_hls.log -f
	rm $(AFU_HLS_PATH)/adders_prj -rf

