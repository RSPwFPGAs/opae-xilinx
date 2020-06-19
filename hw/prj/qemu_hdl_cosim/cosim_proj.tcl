close_project -quiet
source create_proj.tcl

source ../../src/ipi/cosim_setup_flow.tcl



# prepare simulation files
make_wrapper -files [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse           ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse                             {../../src/qemu_hdl_cosim/test_top.v}
set_property FILE_TYPE SystemVerilog [get_files                  ../../src/qemu_hdl_cosim/test_top.v]
set_property top test_top [get_filesets sim_1]
add_files -fileset sim_1 -norecurse                             {../../src/qemu_hdl_cosim/axi_vip/axi_vip_0_passthrough_mst_stimulus.sv}
set_property file_type {Verilog Header} [get_files               ../../src/qemu_hdl_cosim/axi_vip/axi_vip_0_passthrough_mst_stimulus.sv]
add_files -fileset sim_1 -norecurse                              ../../src/qemu_hdl_cosim/axi_vip/debug_trace.txt
set_property file_type {Memory Initialization Files} [get_files  ../../src/qemu_hdl_cosim/axi_vip/debug_trace.txt]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
generate_target Simulation [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd]
export_ip_user_files -no_script -force
export_simulation  -force -directory "./" -simulator xsim  -ip_user_files_dir "./proj_opae_fim/proj_opae_fim.ip_user_files" -ipstatic_source_dir "./proj_opae_fim/proj_opae_fim.ip_user_files/ipstatic" -use_ip_compiled_libs


