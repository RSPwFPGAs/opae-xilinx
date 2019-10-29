.PHONY: all build-bin build-syn build-edt build-sim

all: build-syn

build-bin: 

build-syn:
	vivado -mode batch -source syn_proj.tcl

build-edt: 
	vivado -mode gui   -source edt_proj.tcl

build-sim: 

clean:
	rm vivado* *webtalk* -f
	rm .Xil proj_* hd_visual -rf

