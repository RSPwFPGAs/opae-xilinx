<span style="display: inline-block;">
    
The original work can be found at [qemu-hdl-cosim](https://github.com/RSPwFPGAs/qemu-hdl-cosim)

# Table of Contents
1. [Overview of qemu-hdl-cosim](#overview)
2. [Install Qemu and Create a VM image](#installhost)
3. [Run Co-Simulation](#runcosim)
    - [Run Vivado XSim in Host Machine](#runxsim)
    - [Run application in Guest Machine](#runapp)
    - [Printout when the driver is loaded](#printoutdriver)

<a name="overview"></a>
Overview
----------------------------
This folder contains the necessary patch to QEMU and script to launch the VM with a FPGA cosim card attached.


Prerequisites
----------------------------
This release has been tested with the following tools:
>
>```
>Ubuntu 18.04.3
>Vivado 2018.3
>QEMU 2.10 rc3
>```

Environment variables to set
----------------------------
>
>```
>COSIM_REPO_HOME -> Root of the source release
>COSIM_PORT -> Any 4-digit number. If you want to run multiple instances on 
>              the same machine, each one needs to have a different number.
>```

<a name="installhost"></a>
# Install Qemu and Create a VM image

Compile QEMU
----------------------------
1. Install Dependencies:
>
>```bash
>    sudo apt update && sudo apt upgrade
>    sudo apt-get install build-essential autoconf libtool python vim 
>    sudo apt-get install libzmq3-dev libczmq-dev libncurses5-dev libncursesw5-dev libsdl2-dev

2. Download QEMU 2.10 rc3

>
>```bash
>    cd $COSIM_REPO_HOME/qemu
>    wget http://download.qemu-project.org/qemu-2.10.0-rc3.tar.xz
>    tar -xJf qemu-2.10.0-rc3.tar.xz

3. Apply the patches

     Apply the patch for HDL based device.
>
>   ```bash
>    patch -s -p0 < qemu-cosim.patch
>   ```

     Apply [another patch for memfd.c](https://git.qemu.org/?p=qemu.git;a=commitdiff;h=75e5b70e6b5dcc4f2219992d7cffa462aa406af0).
>
>   ```bash
>    patch -s -p0 < qemu-memfd.patch
>   ``` 

4. Configure and build

>
>```bash
>    cd qemu-2.10.0-rc3
>    mkdir build
>    cd build
>    ../configure --target-list=x86_64-softmmu --disable-vnc --enable-sdl --enable-curses
>
>    Modify config-host.mak, Add " -lzmq -lczmq" to the end of LIBS
>
>    make -j32

5. Copy the launch script

>
>```bash
>    cp ../../../scripts/launch_fpga.sh .
>    cd ../../

Create a QEMU image
----------------------------
1. Create a QEMU image file called cosim.qcow2 in $COSIM_REPO_HOME/qemu and install Ubuntu 16.04.3.

>
>```bash
>    qemu-2.10.0-rc3/build/qemu-img create -f qcow2 cosim.qcow2 16G
>    sudo qemu-2.10.0-rc3/build/x86_64-softmmu/qemu-system-x86_64 -boot d -cdrom /path/to/ubuntu-16.04.6-server-amd64.iso -smp cpus=2 -accel kvm -m 4096 -hda cosim.qcow2
>    (name: user; passwd: user)

2. Launch QEMU in one terminal

>
>```bash
>    cd $COSIM_REPO_HOME/qemu/qemu-2.10.0-rc3/build
>    ./launch_fpga.sh
>    (sudo -E x86_64-softmmu/qemu-system-x86_64 -m 4G -enable-kvm -cpu host -smp cores=1 -drive file=../../cosim.qcow2,cache=writethrough -device accelerator-pcie -redir tcp:2200::22 -display none)

3. Log in to the VM in another terminal

>
>```bash
>    ssh -p 2200 user@localhost

4. In the VM, Install necessary tools for compiling userspace program and kernel module

>
>```bash
>    sudo apt-get update
>    sudo apt-get upgrade
>    sudo apt-get install build-essential

Copy driver and application to the image
----------------------------
1. Copy opae-intel-fpga-driver to the image.

>
>```bash
>    cd $COSIM_REPO_HOME
>    scp -P 2200 -r ../../OPAE/driver/opae-intel-fpga-driver-1.3.0-2_pcie/ user@localhost:/home/user/.

Shutdown and Backup the image(Optional)
----------------------------
1. In the VM, Shutdown the VM

>
>```bash
>    sudo poweroff

2. In the host, Backup the installed image
>
>```bash
>    cd $COSIM_REPO_HOME/qemu
>    zip cosim.qcow2.zip cosim.qcow2


<a name="runcosim"></a>
# Run co-simulation

<a name="runxsim"></a>
## Run Vivado XSim in Host Machine

1. In the host, Launch Vivado XSim Simulation in the 1st terminal

>
>```bash
>    cd $COSIM_REPO_HOME/../../../hw/prj/fim/
>    make build-cosim

The waveform window will show AXI transactions when the application is launched in the VM.

<a name="runapp"></a>
## Run application in Guest Machine

1. In the host, Launch QEMU with accelerator in the 2nd terminal

>
>```bash
>    cd $COSIM_REPO_HOME/qemu/qemu-2.10.0-rc3/build
>    ./launch_fpga.sh
>    (sudo -E x86_64-softmmu/qemu-system-x86_64 -m 4G -enable-kvm -cpu host -smp cores=1 -drive file=../../cosim.qcow2,cache=writethrough -device accelerator-pcie -redir tcp:2200::22 -display none)

2. In the host, Log in to the VM in the 3rd terminal

>
>```bash
>    ssh -p 2200 user@localhost

3. In the VM, compile and load driver

>
>```bash
>    cd opae-intel-fpga-driver-1.3.0-2_pcie/
>    ./loadRunModule.sh

<a name="printoutdriver"></a>
Printout
----------------------------
The printout will be like this:

>
>```bash
>    user@ubuntu1604-opae-vfpga:~/opae-intel-fpga-driver-1.3.0-2_pcie$ ./loadRunModule.sh 
>    	 Compiling the driver 
>    
>    make -C /lib/modules/4.4.0-142-generic/build M=/home/user/opae-intel-fpga-driver-1.3.0-2_pcie clean
>    make[1]: Entering directory '/usr/src/linux-headers-4.4.0-142-generic'
>      CLEAN   /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/.tmp_versions
>      CLEAN   /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/Module.symvers
>    make[1]: Leaving directory '/usr/src/linux-headers-4.4.0-142-generic'
>    make -C /lib/modules/4.4.0-142-generic/build M=/home/user/opae-intel-fpga-driver-1.3.0-2_pcie modules
>    make[1]: Entering directory '/usr/src/linux-headers-4.4.0-142-generic'
>      CC [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/drivers/fpga/intel/uuid_mod.o
>      CC [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/drivers/fpga/intel/pcie.o
>      CC [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/drivers/fpga/intel/pcie_check.o
>      CC [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/drivers/fpga/intel/feature-dev.o
>      LD [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/intel-fpga-pci.o
>      Building modules, stage 2.
>      MODPOST 1 modules
>      CC      /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/intel-fpga-pci.mod.o
>      LD [M]  /home/user/opae-intel-fpga-driver-1.3.0-2_pcie/intel-fpga-pci.ko
>    make[1]: Leaving directory '/usr/src/linux-headers-4.4.0-142-generic'
>    	 Before loading. 
>    
>    [sudo] password for user: 
>    rmmod: ERROR: Module intel_fpga_pci is not currently loaded
>    
>    	 **** Loading the pcie module 
>    
>    [  225.511563] intel_fpga_pci: loading out-of-tree module taints kernel.
>    [  225.511613] intel_fpga_pci: module verification failed: signature and/or required key missing - tainting kernel
>    [  225.512957] LOG: call_stack: ccidrv_init
>    [  225.512960] Intel(R) FPGA PCIe Driver: Version 0.14.0
>    [  225.512962] LOG: call_stack: fpga_ids_init
>    [  225.513694] LOG: call_stack: cci_pci_probe
>    [  225.513766] intel-fpga-pci 0000:00:04.0: PCIE AER unavailable -5.
>    [  225.514383] LOG: call_stack: create_init_drvdata
>    [  225.514766] LOG: call_stack: alloc_fpga_id
>    [  225.514769] LOG: call_stack: cci_pci_alloc_irq
>    [  225.514770] LOG: call_stack: cci_pci_create_feature_devs
>    [  225.514771] LOG: call_stack: build_info_alloc_and_init
>    [  225.514772] LOG: call_stack: fpga_create_parent_dev
>    [  225.515763] LOG: call_stack: parse_start
>    [  225.515764] LOG: call_stack: parse_start_from
>    [  225.515766] LOG: call_stack: cci_pci_ioremap_bar
>    [  225.515788] LOG: call_stack: parse_feature_list
>    [  225.515789] LOG: call_stack: parse_feature_list, for_loop
>    [  225.515790] LOG: call_stack: parse_feature
>    [  225.515791] LOG: readq: header.csr = readq(hdr);
>    [  225.558231] LOG: call_stack: parse_feature_fiu
>    [  225.558234] LOG: readq: header.csr = readq(hdr);
>    [  225.595050] LOG: call_stack: parse_feature_port
>    [  225.595061] LOG: call_stack: build_info_create_dev
>    [  225.595062] LOG: call_stack: build_info_commit_dev
>    [  225.595497] LOG: call_stack: alloc_fpga_id
>    [  225.595501] LOG: call_stack: create_feature_instance
>    [  225.624598] LOG: call_stack: build_info_add_sub_feature
>    [  225.661200] LOG: call_stack: enable_port_uafu
>    [  225.661203] LOG: readq: capability.csr = readq(&port_hdr->capability);
>    [  225.661204] LOG: readq: control.csr = readq(&port_hdr->control);
>    [  225.976359] LOG: readq: fiu_header.csr = readq(&fiu_hdr->csr);
>    [  226.012213] LOG: readq: header.csr = readq(hdr);
>    [  226.048678] LOG: call_stack: parse_ports_from_fme
>    [  226.048680] LOG: call_stack: build_info_commit_dev
>    [  226.050592] LOG: call_stack: feature_dev_id_type
>    [  226.050594] LOG: call_stack: cci_pci_add_port_dev
>    user@ubuntu1604-opae-vfpga:~/opae-intel-fpga-driver-1.3.0-2_pcie$


