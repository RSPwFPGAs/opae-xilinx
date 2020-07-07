
apt update && apt upgrade -y

#### install dirvers 
apt install -y wget build-essential cmake linux-headers-4.4.0-142-generic kmod dkms udev sudo
FILE=opae-intel-fpga-driver-1.3.0-2
if [ -d "$FILE" ]; then
    echo "$FILE exsist!"
else
    if [ -f "$FILE.tar.gz" ]; then
        echo "$FILE.tar.gz exist!"
    else
        wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-intel-fpga-driver-1.3.0-2.tar.gz
    fi
    tar zxvf opae-intel-fpga-driver-1.3.0-2.tar.gz
fi
cd $FILE
make clean; sudo make install
cd .. 


