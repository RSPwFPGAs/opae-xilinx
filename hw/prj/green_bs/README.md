## FPGA project for partial-reconfiguration default AFU design, depending on exported PR FIM design.

    To generate a Green Bitstream based on imported Blue Bitstream
>
>   ```bash
>    make build-bin AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl AFU_IP_FILE=./add_afu_ip_path.tcl
>   ```
