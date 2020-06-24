# xflash

Build the application
-----------------------
In order to build this application run the make command

make clean
make

Command to run the utility
-----------------------------

./xbflash -d 0000:02:00.0 -m xilinx_vcu1525_dynamic_5_1.mcs
---------------------------------------------------------

Output of this command
lspci | grep "Xilinx"
will give the BDF Busno,device no and function no
Example : 0000:02:00.0

run the xbflash and provide -d option with 0000:02:00.0

with -m option , provide the MCS file
The xbflash utility will flash the MCS file





Note that the updated mcs is created at an offset address which is now fixed to 

BITSTREAM_START_LOC = 0x01002000; for U200 Board


Now, which generating the golden mcs for fallback in vivado, you have to specify the offset address of the updated mcs 

And while creating the updated MCS, specify the same offset and make sure that xspi.cpp knows about this in this macro 
BITSTREAM_START_LOC 




