
#### install python binding
FILE=opae-libs-1.4.0-1.x86_64.deb
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    #wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae-libs-1.4.0-1.x86_64.deb
    cp ./opae-1.4.0-1/usr/build/$FILE .
fi
dpkg -i $FILE 

FILE=opae-devel-1.4.0-1.x86_64.deb
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    #wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae-devel-1.4.0-1.x86_64.deb
    cp ./opae-1.4.0-1/usr/build/$FILE .
fi
dpkg -i $FILE

FILE=opae.fpga-1.4.0.tar.gz
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    wget https://github.com/OPAE/opae-sdk/releases/download/1.4.0-1/opae.fpga-1.4.0.tar.gz
fi

pip install --user pybind11
pip install --user opae.fpga-1.4.0.tar.gz


