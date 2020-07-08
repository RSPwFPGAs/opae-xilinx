
#### check if host driver is loaded
ls /dev/intel-fpga-port.0 
ls /sys/class/fpga/intel-fpga-dev.0/intel-fpga-port.0/


#### get sdk source
apt install -y uuid-dev libjson-c-dev libjson-c3 libhwloc-dev python-pip libhwloc-dev linux-headers-$(uname -r) libtbb-dev
FILE=opae-1.4.0-1
if [ -f "$FILE.tar.gz" ]; then
    echo "$FILE.tar.gz exist!"
else
    wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae-1.4.0-1.tar.gz
fi
rm -rf $FILE
tar zxvf $FILE.tar.gz

#### patch for Ubuntu1804
sed -i 's/libjson0/libjson-c3/g' $FILE/usr/CMakeLists.txt

#### build and innstall sdk
cd $FILE/usr
rm -rf build
mkdir build && cd build
cmake .. -DBUILD_ASE=0
make clean; make; sudo make install
cd ../../../

#### build DEB packages
cd $FILE/usr
cd build
cmake .. -DBUILD_ASE=0 -DCPACK_GENERATOR=DEB
make package_deb
cd ../../../



