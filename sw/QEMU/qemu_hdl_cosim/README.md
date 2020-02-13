This folder contains the necessary patch to QEMU and script to launch the VM with a FPGA cosim card attached.

Please follow the instructions in [qemu-hdl-cosim, Install Qemu and Create a VM image](https://github.com/RSPwFPGAs/qemu-hdl-cosim#installhost) to create the VM image. After the VM image is created, copy ./srcipts/launch_fpga.sh to ./qemu/qemu-2.10.0-rc3/build. Source this script to launch the VM with a FPGA cosim card attached.

Please follow the instructions in [qemu-hdl-cosim, Copy driver and application to the image](https://github.com/RSPwFPGAs/qemu-hdl-cosim#copy-driver-and-application-to-the-image) to copy the driver code in ../../OPAE/driver/opae-intel-fpga-driver-1.3.0-2_pcie/ into the VM. After the driver code is copied, follow the instructions in [qemu-hdl-cosim, Run co-simulation](https://github.com/RSPwFPGAs/qemu-hdl-cosim#run-co-simulation) to launch the co-simulation.

