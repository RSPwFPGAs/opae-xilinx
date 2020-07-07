
#### check if host driver is loaded
ls /dev/intel-fpga-port.0 
ls /sys/class/fpga/intel-fpga-dev.0/intel-fpga-port.0/


#### install sdk
apt install -y uuid-dev libjson-c-dev libjson-c3 libhwloc-dev python-pip libhwloc-dev linux-headers-$(uname -r) libtbb-dev
FILE=opae-1.4.0-1
if [ -d "$FILE" ]; then
    echo "$FILE exsist!"
else
    if [ -f "$FILE.tar.gz" ]; then
        echo "$FILE.tar.gz exist!"
    else
        wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae-1.4.0-1.tar.gz
    fi
    tar zxvf $FILE.tar.gz
fi
cd $FILE/usr
rm -rf build
mkdir build && cd build
cmake .. -DBUILD_ASE=0
make clean; sudo make install
cd ../../../

#### build DEB packages
cd $FILE/usr
cd build
cmake .. -DBUILD_ASE=0 -DCPACK_GENERATOR=DEB
make package_deb
cd ../../../

#### run the C sample of Xilinx CDMA
cp hello_fpga.c opae-1.4.0-1/usr/samples/hello_fpga.c
cd opae-1.4.0-1/usr/build/
make
sudo sh -c 'echo 20 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'
sudo ./bin/hello_fpga
cd ../../../


