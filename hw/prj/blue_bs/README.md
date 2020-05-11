## FPGA project for partial-reconfiguration FIM design, with default AFU. A post-P&R dcp will be exported for green_bs generation.

call stack:
>   ```bash
>    make build-bin -> run_proj.tcl -> ../../src/ipi/pr_setup_flow.tcl -> ../../src/ipi/afu_default.bd.tcl, ../../src/ipi/fim_debug.bd.tcl
>   ```

    To validate a customer AFU design with the FIM design
>
>   ```bash
>    make build-vld AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl
>   ```
    or
>
>   ```bash
>    make build-vld AFU_SRC_FILE=../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl
>   ```

    To generate and export the FIM design as a Blue Bitstream
>
>   ```bash
>    make build-bin
>   ```

    To generate and export the FIM design as a Blue Bitstream for U50 board
>
>   ```bash
>    make build-bin FIM_SRC_FILE=../../src/ipi/fim_debug_u50dd.bd.tcl FIM_BRD_TYPE=u50dd
>   ```
