xvlog --prj source.prj
xelab --debug all -L blk_mem_gen_v8_0 -L unisims_ver -L work -s run_pcie_sim work.pcie_2_axilite_tb 
xsim -gui -t run_time.tcl run_pcie_sim -view xsim_test.wcfg -wdb xsim_test.wdb 
