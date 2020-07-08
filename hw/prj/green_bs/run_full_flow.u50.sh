cd ../blue_bs
make clean
make build-bin AFU_SRC_FILE=../../src/ipi/afu_default.u50dd.bd.tcl FIM_SRC_FILE=../../src/ipi/fim_debug.u50dd.bd.tcl FIM_BRD_TYPE=u50dd

cd ../green_bs
make clean
make build-bin AFU_SRC_FILE=../../src/ipi/afu_debug.u50dd.bd.tcl FIM_BRD_TYPE=u50dd

