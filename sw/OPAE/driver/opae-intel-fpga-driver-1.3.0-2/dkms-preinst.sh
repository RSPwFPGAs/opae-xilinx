#!/bin/sh
if [ -n "`lsmod | grep fpga`" ]; then
  rmmod intel-fpga-fme
  rmmod intel-fpga
  rmmod fpga-mgr-mod
  rmmod altera-asmip2
  rmmod avmmi-bmc
  rmmod spi-nor-mod
  rmmod intel-fpga-pci
  rmmod intel-fpga-pac-hssi
  rmmod intel-fpga-pac-iopll
fi

if [ -d $DESTDIR/etc/udev/rules.d ]; then
  cp $DESTDIR/usr/src/intel-fpga-1.3.0-2/40-intel-fpga.rules $DESTDIR/etc/udev/rules.d
fi
