
apt update && apt upgrade -y
 
apt install -y wget build-essential cmake linux-headers-4.4.0-142-generic kmod dkms udev sudo
wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-intel-fpga-driver-1.3.0-2.tar.gz
tar zxvf opae-intel-fpga-driver-1.3.0-2.tar.gz
cd opae-intel-fpga-driver-1.3.0-2
make clean; sudo make install
cd .. 

apt install -y libjson0 uuid-dev libjson-c-dev libhwloc-dev python-pip libjson-c-dev libhwloc-dev linux-headers-$(uname -r) libtbb-dev
#wget https://github.com/OPAE/opae-sdk/archive/1.3.0-2.tar.gz
wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-1.3.0-2.tar.gz
tar zxvf opae-1.3.0-2.tar.gz
cd opae-1.3.0-2/usr
mkdir build && cd build
cmake .. -DBUILD_ASE=0
make clean; sudo make install
cd ../../../

wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-libs-1.3.0-2.x86_64.deb
dpkg -i opae-libs-1.3.0-2.x86_64.deb 
wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-devel-1.3.0-2.x86_64.deb
dpkg -i opae-devel-1.3.0-2.x86_64.deb
wget  https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae.fpga-1.3.0.tar.gz
pip install --user pybind11
pip install --user opae.fpga-1.3.0.tar.gz

