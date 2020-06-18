close_project -quiet
source create_proj.tcl

source ../../src/ipi/afu_setup_flow.tcl

remove_files       ./proj_opae_afu/proj_opae_afu.srcs/sources_1/bd/role_region_0_sim/role_region_0_sim.bd
file delete -force ./proj_opae_afu/proj_opae_afu.srcs/sources_1/bd/role_region_0_sim
create_bd_design "role_region_0_sim"
source [lindex $argv 0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_pcie_axilite_pt
delete_bd_objs [get_bd_intf_nets S_AXI_LITE_ROLE_CTRL_1]
connect_bd_intf_net [get_bd_intf_ports S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins axi_vip_pcie_axilite_pt/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_vip_pcie_axilite_pt/M_AXI] -boundary_type upper [get_bd_intf_pins AFU/S_AXI_LITE_CTRL_PORT]
connect_bd_net [get_bd_ports axi_aclk_ctrl_port] [get_bd_pins axi_vip_pcie_axilite_pt/aclk]
connect_bd_net [get_bd_ports axi_aresetn_ctrl_port] [get_bd_pins axi_vip_pcie_axilite_pt/aresetn]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_pcie_axifull_pt
delete_bd_objs [get_bd_intf_nets axi_interconnect_1_M00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins AFU/M_AXI_FULL_DATA_PORT] [get_bd_intf_pins axi_vip_pcie_axifull_pt/S_AXI]
connect_bd_intf_net [get_bd_intf_ports M_AXI_FULL_DATA_PORT] [get_bd_intf_pins axi_vip_pcie_axifull_pt/M_AXI]
connect_bd_net [get_bd_ports axi_aclk_data_port] [get_bd_pins axi_vip_pcie_axifull_pt/aclk]
connect_bd_net [get_bd_ports axi_aresetn_data_port] [get_bd_pins axi_vip_pcie_axifull_pt/aresetn]

save_bd_design
validate_bd_design


# prepare simulation files
set_property SOURCE_SET sources_1 [get_filesets sim_1]

add_files -fileset sim_1 -norecurse            {../../src/sim/afu/tb.v}
set_property FILE_TYPE SystemVerilog [get_files ../../src/sim/afu/tb.v]
set_property top tb [get_filesets sim_1]

add_files -fileset sim_1 -norecurse                {../../src/sim/afu/axi_vip/axi_vip_pcie_axilite_pt_stimulus.sv}
set_property file_type {Verilog Header} [get_files  ../../src/sim/afu/axi_vip/axi_vip_pcie_axilite_pt_stimulus.sv]

add_files -fileset sim_1 -norecurse                {../../src/sim/afu/axi_vip/axi_vip_pcie_axifull_pt_stimulus.sv}
set_property file_type {Verilog Header} [get_files  ../../src/sim/afu/axi_vip/axi_vip_pcie_axifull_pt_stimulus.sv]

add_files -fileset sim_1 -norecurse                             {../../src/sim/afu/axi_vip/pcie_axilite_pt_trace.txt}
set_property file_type {Memory Initialization Files} [get_files  ../../src/sim/afu/axi_vip/pcie_axilite_pt_trace.txt]

set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sources_1

generate_target Simulation [get_files role_region_0_sim.bd]
export_ip_user_files -no_script -force
export_simulation  -force -directory "./" -simulator xsim  -ip_user_files_dir "./proj_opae_afu/proj_opae_afu.ip_user_files" -ipstatic_source_dir "./proj_opae_afu/proj_opae_afu.ip_user_files/ipstatic" -use_ip_compiled_libs



