FPGA project for stand-alone FIM design.

To edit the FIM design
    make build-edt

Remember to save the modified BD as a Tcl file after validation.
    write_bd_tcl -f -no_ip_version ../../src/ipi/fim_debug.bd.tcl


To simulate the FIM design
    make build-sim
