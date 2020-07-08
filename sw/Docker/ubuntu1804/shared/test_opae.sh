#### run the C sample of Xilinx CDMA
cp hello_fpga.c opae-1.4.0-1/usr/samples/hello_fpga.c
cd opae-1.4.0-1/usr/build/
make
sudo sh -c 'echo 20 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'
sudo ./bin/hello_fpga
cd ../../../

#### run the Python sample of Xilinx CDMA
export PYTHONPATH=~/.local/lib/python2.7/site-packages/opae/fpga
export LC_ALL=C
python ./hello_fpga.py


