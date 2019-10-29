.PHONY: all build-bin build-syn build-edt build-sim

all: build-bin

build-bin: 
	rm ./dcp -rf
	mkdir dcp
	cp ../blue_bs/export/* ./dcp/.
	
	rm ./output -rf
	mkdir output
	
	vivado -mode batch -source run_proj.tcl

build-syn:

build-edt: 

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual dcp output -rf

