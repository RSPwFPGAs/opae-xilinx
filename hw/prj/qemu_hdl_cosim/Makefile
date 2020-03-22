.PHONY: all build-cosim

COSIM_SRC_FILE=../../src/ipi/cosim_default.bd.tcl
COSIM_IP_FILE=./add_cosim_ip_path.tcl

all: build-bin

build-cosim: 
	vivado -mode batch -source cosim_proj.tcl -tclargs $(COSIM_SRC_FILE) $(COSIM_IP_FILE) 
	bash cosim_dpi.sh

clean:
	bash cleanup.sh
	#rm vivado* *webtalk* -f
	#rm .Xil proj_* hd_visual output -rf


