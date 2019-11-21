.PHONY: all run-hls run-gui

AFU_HLS_PATH=.

all:

run-hls:
	vivado_hls -f run_hls.ipi.tcl

run-gui: run-hls
	vivado_hls -p hls_prj

clean:
	rm $(AFU_HLS_PATH)/vivado_hls.log -f
	rm $(AFU_HLS_PATH)/hls_prj -rf

