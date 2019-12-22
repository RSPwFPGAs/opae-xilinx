#! /bin/bash

echo -e "\t Compiling the driver \n"
make clean
make
echo -e "\t Before loading. \n"
sudo rmmod intel-fpga-pci
lsmod | grep intel-fpga-pci
echo -e "\n\t **** Loading the pcie module \n"
sudo insmod intel-fpga-pci.ko
lsmod | grep intel-fpga-pci
dmesg | tail -150

