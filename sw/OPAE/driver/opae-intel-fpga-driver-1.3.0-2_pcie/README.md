This folder contains the pcie driver for OPAE compilant FPGA add-on cards.

The content of ./drivers/fpga/intel/pcie.c has been modified to print out the callstack and hardware accesses.

Source the loadRunModule.sh script on a physical machine with an OPAE compilant FPGA add-on card attached, or inside a virtual machine on QEMU with PCIe-HDL-cosim ability enabled.

Please follow the [README](../../../QEMU/qemu_hdl_cosim/) in ../../../QEMU/qemu_hdl_cosim/ on how to launch the virtual machine.
