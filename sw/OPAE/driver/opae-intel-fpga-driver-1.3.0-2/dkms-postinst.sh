#!/bin/sh
depmod -A
modprobe spi-nor-mod          || modprobe --allow-unsupported spi-nor-mod
modprobe altera-asmip2        || modprobe --allow-unsupported altera-asmip2
modprobe avmmi-bmc            || modprobe --allow-unsupported avmmi-bmc
modprobe fpga-mgr-mod         || modprobe --allow-unsupported fpga-mgr-mod
modprobe intel-fpga-pci       || modprobe --allow-unsupported intel-fpga-pci
modprobe intel-fpga-afu       || modprobe --allow-unsupported intel-fpga-afu
modprobe intel-fpga-fme       || modprobe --allow-unsupported intel-fpga-fme
modprobe intel-fpga-pac-hssi  || modprobe --allow-unsupported intel-fpga-pac-hssi
modprobe intel-fpga-pac-iopll || modprobe --allow-unsupported intel-fpga-pac-iopll

if [ -x /sbin/udevadm ]; then
      /sbin/udevadm control --reload-rules
      /sbin/udevadm trigger
fi
