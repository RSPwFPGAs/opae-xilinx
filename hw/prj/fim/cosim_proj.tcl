close_project -quiet
source create_proj.tcl

source ../../src/ipi/fim_setup_flow.tcl


# replace synthesis IP with simulation IP for PCIe 
create_bd_cell -type ip -vlnv COMPAS:COMPAS:QEMUPCIeBridge:1.0.0 FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0

delete_bd_objs [get_bd_intf_nets FIM/FIU/pcie_axi_bridge/axi_pcie3_0_M_AXI] [get_bd_intf_nets FIM/FIU/pcie_axi_bridge/S_AXI_1] [get_bd_nets FIM/FIU/pcie_axi_bridge/util_ds_buf_IBUF_OUT] [get_bd_nets FIM/FIU/pcie_axi_bridge/pcie_perstn_1] [get_bd_nets FIM/FIU/pcie_axi_bridge/util_ds_buf_IBUF_DS_ODIV2] [get_bd_nets FIM/FIU/pcie_axi_bridge/axi_pcie3_0_axi_aclk] [get_bd_nets FIM/FIU/pcie_axi_bridge/axi_pcie3_0_axi_aresetn] [get_bd_intf_nets FIM/FIU/pcie_axi_bridge/axi_pcie3_0_pcie_7x_mgt] [get_bd_cells FIM/FIU/pcie_axi_bridge/axi_pcie3_0]

connect_bd_intf_net [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/M_AXI] [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/M_AXI]
connect_bd_intf_net [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/pci_express] [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/pcie_7x_mgt]
connect_bd_net [get_bd_pins FIM/FIU/pcie_axi_bridge/axi_aclk_port_data] [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/o_axi_aclk]
connect_bd_net [get_bd_pins FIM/FIU/pcie_axi_bridge/axi_aresetn_port_data] [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/o_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/S_AXI] [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/S_AXI]
connect_bd_net [get_bd_pins FIM/FIU/pcie_axi_bridge/pcie_perstn] [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/i_sys_rst_n]
connect_bd_net [get_bd_pins FIM/FIU/pcie_axi_bridge/util_ds_buf/IBUF_DS_ODIV2] [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/i_refclk]
connect_bd_net [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/i_axi_ctl_aclk] [get_bd_pins FIM/FIU/pcie_axi_bridge/QEMUPCIeBridge_0/o_axi_aclk]

assign_bd_address


# add axi_vip
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 FIM/FIU/axi_vip_0
delete_bd_objs [get_bd_intf_nets FIM/FIU/S01_AXI_1]
connect_bd_intf_net [get_bd_intf_pins FIM/FIU/jtag_axi_0/M_AXI] [get_bd_intf_pins FIM/FIU/axi_vip_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins FIM/FIU/axi_vip_0/M_AXI] -boundary_type upper [get_bd_intf_pins FIM/FIU/axi_interconnect_0/S01_AXI]
connect_bd_net [get_bd_pins FIM/FIU/axi_vip_0/aclk] [get_bd_pins FIM/FIU/pcie_axi_bridge/axi_aclk_port_data]
connect_bd_net [get_bd_pins FIM/FIU/axi_vip_0/aresetn] [get_bd_pins FIM/FIU/pcie_axi_bridge/axi_aresetn_port_data]

save_bd_design
validate_bd_design


# prepare simulation files
make_wrapper -files [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse           ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {../../src/qemu_hdl_cosim/test_top.v}
set_property FILE_TYPE SystemVerilog [get_files ../../src/qemu_hdl_cosim/test_top.v]
set_property top test_top [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {../../src/sim/axi_vip/axi_vip_0_passthrough_mst_stimulus.sv}
set_property file_type {Verilog Header} [get_files  ../../src/sim/axi_vip/axi_vip_0_passthrough_mst_stimulus.sv]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
generate_target Simulation [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd]
export_ip_user_files -no_script -force
export_simulation  -force -directory "./" -simulator xsim  -ip_user_files_dir "./proj_opae_fim/proj_opae_fim.ip_user_files" -ipstatic_source_dir "./proj_opae_fim/proj_opae_fim.ip_user_files/ipstatic" -use_ip_compiled_libs


