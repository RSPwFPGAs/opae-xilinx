## FPGA project for stand-alone default/customer AFU design.

    To edit an existing AFU design
>
>   ```bash
>    make build-edt AFU_SRC_FILE=../../src/ipi/afu_default.bd.tcl AFU_IP_FILE=./add_afu_ip_path.tcl
>   ```

    Remember to save the modified BD as a Tcl file after validation.
>
>   ```bash
>    write_bd_tcl -f -no_ip_version ../../src/ipi/afu_default.bd.tcl
>   ```


    To customize the base AFU design with new IP
>
>   ```bash
>    make build-edt AFU_SRC_FILE=../../src/ipi/afu_customer.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl
>   ```

    Remember to save the modified BD as a Tcl file after validation.
>
>   ```bash
>    write_bd_tcl -f -no_ip_version ../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl
>   ```
