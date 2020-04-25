
#### install python binding
export LC_ALL=C

FILE=opae-libs-1.3.0-2.x86_64.deb
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-libs-1.3.0-2.x86_64.deb
fi
dpkg -i $FILE 

FILE=opae-devel-1.3.0-2.x86_64.deb
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    wget https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae-devel-1.3.0-2.x86_64.deb
fi
dpkg -i $FILE

FILE=opae.fpga-1.3.0.tar.gz
if [ -f "$FILE" ]; then
    echo "$FILE exsist!"
else
    wget  https://github.com/OPAE/opae-sdk/releases/download/1.3.0-2/opae.fpga-1.3.0.tar.gz
fi

pip install --user pybind11
pip install --user opae.fpga-1.3.0.tar.gz


#### run the Python sample of Xilinx CDMA
export PYTHONPATH=~/.local/lib/python2.7/site-packages/opae/fpga
python ./hello_fpga.py

