close_project -quiet
source create_proj.tcl

source ../../src/ipi/fim_setup_flow.tcl


make_bd_intf_pins_external  [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/*/pcie*_ext_pipe_ep*]
set_property name pcie_ext_pipe_ep [get_bd_intf_ports pcie*_ext_pipe_ep*]

make_wrapper -files [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse           ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v

set_property SOURCE_SET sources_1 [get_filesets sim_1]

if ({[lindex $argv 1]}=="kcu105") {
	set path_to_hdl "../../src/sim/fim/pcie_rp_vip_pipe/src"
}
if ({[lindex $argv 1]}=="u50dd") {
	set path_to_hdl "../../src/sim/fim/pcie4_rp_vip_pipe/src"
}
add_files -fileset sim_1 -norecurse [glob $path_to_hdl/*.v $path_to_hdl/*.vh]

set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property XELAB.MT_LEVEL off [get_filesets sim_1]


generate_target Simulation [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd]
export_ip_user_files -of_objects [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -no_script -sync -force -quiet
export_simulation  -force -directory "./" -simulator xsim  -ip_user_files_dir "./proj_opae_fim/proj_opae_fim.ip_user_files" -ipstatic_source_dir "./proj_opae_fim/proj_opae_fim.ip_user_files/ipstatic" -use_ip_compiled_libs



