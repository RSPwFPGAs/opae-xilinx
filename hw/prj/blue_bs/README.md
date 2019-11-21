FPGA project for partial-reconfiguration FIM design, with default AFU.
A post-P&R dcp will be exported for green_bs generation.

To validate a customer AFU design with the FIM design
    make build-vld AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl
or
    make build-vld AFU_SRC_FILE=../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl

To generate and export the FIM design as a Blue Bitstream
    make build-bin

