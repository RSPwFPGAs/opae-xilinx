HWICAP_HOME := $(shell pwd)

HWICAP_KVER := $(shell uname -r)

obj-m := pcie.o

all:
	make -C /lib/modules/$(HWICAP_KVER)/build M=$(HWICAP_HOME) modules
	g++ test.cpp -o test
	unzip ./bit_file/*.zip -d ./bit_file/
clean:
	make -C /lib/modules/$(HWICAP_KVER)/build M=$(HWICAP_HOME) clean
	rm test
	rm ./bit_file/*.bit
