
apt update && apt upgrade -y

#### compile dirvers 
apt install -y wget build-essential cmake linux-headers-$(uname -r) kmod dkms udev sudo cpio rpm2cpio
FILE=opae-intel-fpga-driver-2.0.4-2
if [ -f "$FILE.x86_64.rpm" ]; then
    echo "$FILE.x86_64.rpm exist!"
else
    wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae-intel-fpga-driver-2.0.4-2.x86_64.rpm
fi

rm -rf $FILE

mkdir $FILE
cd $FILE
rpm2cpio ../$FILE.x86_64.rpm  | cpio -idmv
cd ..

cd $FILE/usr/src/$FILE
make clean; make

#### uninstall DFL drivers
sudo rmmod dfl_pci
sudo rmmod dfl_afu
sudo rmmod dfl
sudo rmmod fpga_region
sudo rmmod fpga_mgr
sudo rmmod fpga_bridge

#### install Intel FPGA drivers
sudo insmod fpga-mgr-mod.ko
sudo insmod intel-fpga-pci.ko
sudo insmod intel-fpga-fme.ko
sudo insmod intel-fpga-afu.ko

cd ../../../../ 

#### check if host driver is loaded
ls /dev/intel-fpga-port.0
ls /sys/class/fpga/intel-fpga-dev.0/intel-fpga-port.0/


