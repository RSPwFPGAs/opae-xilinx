cp $1 fpga_top.bit
vivado -mode batch -source u50_mcs.tcl
rm -rf vivado*
rm -rf *.prm
rm -rf fpga_top.bit
mv fpga_top.mcs $2
