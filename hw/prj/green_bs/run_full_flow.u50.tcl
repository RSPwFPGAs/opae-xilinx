cd ../blue_bs
make clean
make build-bin FIM_SRC_FILE=../../src/ipi/fim_debug_u50dd.bd.tcl FIM_BRD_TYPE=u50dd

cd ../green_bs
make clean
make build-bin AFU_SRC_FILE=../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl FIM_BRD_TYPE=u50dd

