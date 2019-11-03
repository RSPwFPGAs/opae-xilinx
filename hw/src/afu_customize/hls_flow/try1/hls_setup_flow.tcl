
set_property  ip_repo_paths  [lindex $argv 1]/hls_prj/solution1/impl/ip [current_project]
update_ip_catalog
create_bd_cell -type ip -vlnv xilinx.com:hls:adders:1.0 AFU/AFU_core/adders_0

delete_bd_objs [get_bd_intf_nets AFU/AFU_core/axi_cdma_0_M_AXI] [get_bd_intf_nets AFU/AFU_core/axi_interconnect_0_M01_AXI] [get_bd_nets AFU/AFU_core/axi_aclk_data_port_1] [get_bd_nets AFU/AFU_core/axi_cdma_0_cdma_introut] [get_bd_cells AFU/AFU_core/axi_cdma_0]

connect_bd_intf_net [get_bd_intf_pins AFU/AFU_core/adders_0/s_axi_AXILiteS] -boundary_type upper [get_bd_intf_pins AFU/AFU_core/axi_interconnect_0/M01_AXI]
connect_bd_net [get_bd_pins AFU/AFU_core/M_USR_IRQ_PORT] [get_bd_pins AFU/AFU_core/adders_0/interrupt]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aclk_ctrl_port] [get_bd_pins AFU/AFU_core/adders_0/ap_clk]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aresetn_ctrl_port] [get_bd_pins AFU/AFU_core/adders_0/ap_rst_n]

assign_bd_address
set_property offset 0x00030000 [get_bd_addr_segs {S_AXI_LITE_CTRL_PORT/SEG_adders_0_Reg}]
set_property offset 0x00030000 [get_bd_addr_segs {AFU/axilite_buffer/jtag_axi_0/Data/SEG_adders_0_Reg}]

validate_bd_design


