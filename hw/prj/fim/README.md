## FPGA project for stand-alone FIM design.

call stack:
>   ```bash
>    make build-edt -> edt_proj.tcl -> ../../src/ipi/fim_setup_flow.tcl -> ../../src/ipi/fim_debug.bd.tcl
>   ```

To edit the FIM design
>
>   ```bash
>    make build-edt
>   ```

>To edit the FIM design for U50 board
>
>   ```bash
>    make build-edt FIM_SRC_FILE=../../src/ipi/fim_debug_u50dd.bd.tcl FIM_BRD_TYPE=u50dd
>   ```

Remember to save the modified BD as a Tcl file after validation. In Vivado Tcl console
>
>   ```bash
>    write_bd_tcl -f -no_ip_version ../../src/ipi/fim_debug.bd.tcl
>   ```

To simulate the FIM design
>
>   ```bash
>    make build-sim
>   ```

To simulate the FIM design for U50 board
>
>   ```bash
>    make build-sim FIM_SRC_FILE=../../src/ipi/fim_debug_u50dd.bd.tcl FIM_BRD_TYPE=u50dd
>   ```


