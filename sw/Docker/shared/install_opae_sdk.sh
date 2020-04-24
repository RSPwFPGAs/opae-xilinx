
#### check if host driver is loaded
ls /dev/intel-fpga-port.0 
ls /sys/class/fpga/intel-fpga-dev.0/intel-fpga-port.0/


apt update && apt upgrade -y

#### install sdk
apt install -y libjson0 uuid-dev libjson-c-dev libhwloc-dev python-pip libjson-c-dev libhwloc-dev linux-headers-$(uname -r) libtbb-dev
FILE=opae-1.3.0-2
if [ -d "$FILE" ]; then
    echo "$FILE exsist!"
else
    if [ -f "$FILE.tar.gz" ]; then
        echo "$FILE.tar.gz exist!"
    else
        wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-1.3.0-2.tar.gz
    fi
    tar zxvf opae-1.3.0-2.tar.gz
fi
cd $FILE/usr
rm -rf build
mkdir build && cd build
cmake .. -DBUILD_ASE=0
make clean; sudo make install
cd ../../../

#### run the sample of Xilinx CDMA
patch -s -p0 < hello_fpga.patch
cd opae-1.3.0-2/usr/build
make
sudo sh -c 'echo 20 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'
sudo ./bin/hello_fpga
cd ../../../

###wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-libs-1.3.0-2.x86_64.deb
##dpkg -i opae-libs-1.3.0-2.x86_64.deb 
###wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-devel-1.3.0-2.x86_64.deb
##dpkg -i opae-devel-1.3.0-2.x86_64.deb
###wget  https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae.fpga-1.3.0.tar.gz
##pip install --user pybind11
##pip install --user opae.fpga-1.3.0.tar.gz

