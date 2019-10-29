.PHONY: all build-bin build-syn build-edt build-sim

all: build-bin

build-bin: 
	rm ./export -rf
	rm ./output -rf
	mkdir export
	mkdir output

	vivado -mode batch -source run_proj.tcl

build-syn:

build-edt: 

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual export output -rf

