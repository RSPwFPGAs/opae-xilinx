
# Set required environment variables and params
set_param project.enablePRFlowIPI 1
set_param project.enablePRFlowIPIOOC 1
set_param chipscope.enablePRFlow 1
set_param bd.skipSupportedIPCheck 1
set_param checkpoint.useBaseFileNamesWhileWritingDCP 1

set_property PR_FLOW 1 [current_project] 
set_param project.enableprflowIPI true


# create shell bd
source ../../src/ipi/shell_region_bd.tcl
current_bd_design [get_bd_designs shell_region]
# add external debug_bridge port
make_bd_intf_pins_external  [get_bd_intf_pins FIM/FME/debug_bridge_0/m1_bscan]
delete_bd_objs [get_bd_intf_nets FIM_m1_bscan_0] [get_bd_intf_ports m1_bscan_0]
set_property name M_BSCAN_PORT0 [get_bd_intf_pins FIM/m1_bscan_0]
make_bd_intf_pins_external  [get_bd_intf_pins FIM/FME/debug_bridge_0/m2_bscan]
delete_bd_objs [get_bd_intf_nets FIM_m2_bscan_0] [get_bd_intf_ports m2_bscan_0]
set_property name M_BSCAN_PORT1 [get_bd_intf_pins FIM/m2_bscan_0]
validate_bd_design
# generate shell wrapper file
make_wrapper -files [get_files ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v
set_property top shell_region_wrapper [current_fileset]
update_compile_order -fileset sources_1


# create role bd
source ../../src/ipi/role_region_0_bd.tcl
current_bd_design [get_bd_designs role_region_0]
# add external debug_bridge port
make_bd_intf_pins_external  [get_bd_intf_pins AFU/debug_bridge_0/S_BSCAN]
delete_bd_objs [get_bd_intf_nets S_BSCAN_0_1] [get_bd_intf_ports S_BSCAN_0]
set_property name S_BSCAN_PORT [get_bd_intf_pins AFU/S_BSCAN_0]
validate_bd_design
# export role wrapper file
make_wrapper -files [get_files ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_region_0/role_region_0.bd] -top
exec cp ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_region_0/hdl/role_region_0_wrapper.v ./export/.
exec sed -i "s/module role_region_0_wrapper/module role_rm_0_bb/g" ./export/role_region_0_wrapper.v
# set role as pr
current_bd_design [get_bd_designs role_region_0]
create_bd_design -cell [get_bd_cells /AFU] role_rm_0
create_partition_def -name role_pd_0 -module role_rm_0
create_reconfig_module -name role_rm_0 -partition_def [get_partition_defs role_pd_0 ]  -define_from role_rm_0
# close role and remove original
close_bd_design [get_bd_designs role_rm_0]
close_bd_design [get_bd_designs role_region_0]
export_ip_user_files -of_objects  [get_files ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_region_0/role_region_0.bd] -no_script -reset -force -quiet
remove_files                                 ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_region_0/role_region_0.bd
file delete -force                           ./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_region_0
# add role as a pr region
current_bd_design [get_bd_designs shell_region]
create_bd_cell -type module -reference role_pd_0 AFU
update_compile_order -fileset sources_1
open_bd_design {./proj_opae_bbs/proj_opae_bbs.srcs/sources_1/bd/role_rm_0/role_rm_0.bd}
close_bd_design [get_bd_designs role_rm_0]
current_bd_design [get_bd_designs shell_region]

# connect role interfaces to shell's
connect_bd_intf_net [get_bd_intf_pins AFU/S_AXI_LITE_CTRL_PORT] -boundary_type upper [get_bd_intf_pins FIM/M_AXI_LITE_CTRL_PORT0]
connect_bd_intf_net [get_bd_intf_pins AFU/M_AXI_FULL_DATA_PORT] -boundary_type upper [get_bd_intf_pins FIM/S_AXI_FULL_DATA_PORT0]
connect_bd_intf_net [get_bd_intf_pins AFU/S_BSCAN_PORT] -boundary_type upper [get_bd_intf_pins FIM/M_BSCAN_PORT0]
connect_bd_net [get_bd_pins AFU/axi_aclk_data_port] [get_bd_pins FIM/axi_aclk_data_port]
connect_bd_net [get_bd_pins AFU/axi_aresetn_data_port] [get_bd_pins FIM/axi_aresetn_data_port]
connect_bd_net [get_bd_pins AFU/I_RSTN_PORT] [get_bd_pins FIM/O_RSTN_PORT0]
connect_bd_net [get_bd_pins AFU/axi_aclk_ctrl_port] [get_bd_pins FIM/axi_aclk_ctrl_port]
connect_bd_net [get_bd_pins AFU/axi_aresetn_ctrl_port] [get_bd_pins FIM/axi_aresetn_ctrl_port]
connect_bd_intf_net [get_bd_intf_pins AFU/M_USR_IRQ_PORT] -boundary_type upper [get_bd_intf_pins FIM/S_USR_IRQ_PORT0]

assign_bd_address
set_property offset 0x0000000000000000 [get_bd_addr_segs {AFU/M_AXI_FULL_DATA_PORT/SEG_axi_bram_ctrl_0_Mem0}]

save_bd_design
validate_bd_design


# adding pblock constraints for shell
add_files -fileset constrs_1 ../../src/constraints/pr_shell.xdc
set_property target_constrs_file ../../src/constraints/pr_shell.xdc [current_fileset -constrset]

# adding pblock constraints for role
add_files -fileset constrs_1 ../../src/constraints/pr_role.xdc
set_property target_constrs_file ../../src/constraints/pr_role.xdc [current_fileset -constrset]

# adding top-level pin constraints
add_files -fileset constrs_1 ../../src/constraints/top.xdc

