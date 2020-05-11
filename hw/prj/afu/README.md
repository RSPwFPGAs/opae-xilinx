## FPGA project for stand-alone default/customer AFU design.

call stack:
>   ```bash
>    make build-edt -> syn_proj.tcl -> ../../src/ipi/afu_setup_flow.tcl -> ../../src/ipi/afu_default.bd.tcl
>   ```

To edit an existing AFU design
>
>   ```bash
>    make build-edt AFU_SRC_FILE=../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl
>   ```

>Remember to save the modified BD as a Tcl file after validation. In Vivado Tcl console
>
>   ```bash
>    write_bd_tcl -f -no_ip_version ../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl
>   ```


To customize the base AFU design with user desinged IP
>
>   ```bash
>    make build-edt AFU_SRC_FILE=../../src/ipi/afu_customer.bd.tcl AFU_IP_FILE=../../src/afu_customize/hls_ip/adder_axilite/add_afu_ip_path.tcl
>   ```
In the GUI of IPI, manually connect the AXI-lite or AXI-full ports between the base AFU design and the user designed IP.

>Remember to save the modified BD as a Tcl file after validation. In Vivado Tcl console
>
>   ```bash
>    write_bd_tcl -f -no_ip_version ../../src/afu_customize/hls_ip/adder_axilite/afu_example.bd.tcl
>   ```
>This BD file can be used as AFU_SRC_FILE in [../green_bs](../green_bs) project, to generate a Green Bitstream.


To target the U50 board, add "AFU_BRD_TYPE=u50dd" to the above make commands.
