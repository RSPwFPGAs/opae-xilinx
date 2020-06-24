# hwicap

Build the application
-----------------------
In order to build this application, run the make command
>
>```bash
> make clean
> make
>

Command to run the utility
-----------------------------
>
>```bash
> ./hwicap -d 0000:03:00.0 -f pr_bin_file.bin
>

To get the BDF Bus no, device no and function no
---------------------------------------------------------
>
>```bash
> lspci | grep "Xilinx"
>
