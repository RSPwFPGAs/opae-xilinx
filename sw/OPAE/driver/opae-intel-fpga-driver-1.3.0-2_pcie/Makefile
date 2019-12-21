KERNELDIR ?= /lib/modules/$(shell uname -r)/build
PWD ?= $(pwd)

cflags-y +=  -Wno-unused-value -Wno-unused-label -I$(PWD)/include -I$(PWD)/include/uapi -I$(PWD)/include/intel
cflags-y += -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include/uapi -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include/intel
cflags-y += -I$(PWD)/build/include -I$(PWD)/build/include/uapi -I$(PWD)/build/include/intel

ccflags-y +=  -Wno-unused-value -Wno-unused-label -I$(PWD)/include -I$(PWD)/include/uapi -I$(PWD)/include/intel
ccflags-y += -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include/uapi -I$(DESTDIR)/usr/src/intel-fpga-1.3.0-2/include/intel
ccflags-y += -I$(PWD)/build/include -I$(PWD)/build/include/uapi -I$(PWD)/build/include/intel
ccflags-y += -DCONFIG_AS_AVX512

obj-m := intel-fpga-pci.o

intel-fpga-pci-y := drivers/fpga/intel/uuid_mod.o
intel-fpga-pci-y += drivers/fpga/intel/pcie.o
intel-fpga-pci-y += drivers/fpga/intel/pcie_check.o
intel-fpga-pci-y += drivers/fpga/intel/feature-dev.o

all:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) clean
