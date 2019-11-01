
delete_bd_objs [get_bd_intf_nets AFU/AFU_core/axi_interconnect_0_M01_AXI]
delete_bd_objs [get_bd_nets AFU/AFU_core/axi_aclk_data_port_1]
delete_bd_objs [get_bd_nets AFU/AFU_core/axi_aresetn_data_port_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 AFU/AFU_core/axi_cdma_0
set_property -dict [list CONFIG.C_M_AXI_DATA_WIDTH {512} CONFIG.C_M_AXI_MAX_BURST_LEN {2} CONFIG.C_INCLUDE_SG {0}] [get_bd_cells AFU/AFU_core/axi_cdma_0]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins AFU/AFU_core/axi_interconnect_0/M01_AXI] [get_bd_intf_pins AFU/AFU_core/axi_cdma_0/S_AXI_LITE]
connect_bd_intf_net                      [get_bd_intf_pins AFU/AFU_core/M_AXI_FULL_DATA_PORT]       [get_bd_intf_pins AFU/AFU_core/axi_cdma_0/M_AXI]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aclk_data_port] [get_bd_pins AFU/AFU_core/axi_cdma_0/m_axi_aclk]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aclk_ctrl_port] [get_bd_pins AFU/AFU_core/axi_cdma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aclk_ctrl_port] [get_bd_pins AFU/AFU_core/axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aresetn_ctrl_port] [get_bd_pins AFU/AFU_core/axi_cdma_0/s_axi_lite_aresetn]
connect_bd_net [get_bd_pins AFU/AFU_core/axi_aresetn_ctrl_port] [get_bd_pins AFU/AFU_core/axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_pins AFU/M_USR_IRQ_PORT] [get_bd_pins AFU/AFU_core/axi_cdma_0/cdma_introut]

delete_bd_objs [get_bd_addr_segs S_AXI_LITE_CTRL_PORT/SEG_M_AXI_FULL_DATA_PORT_Reg]
assign_bd_address
set_property offset 0x00030000 [get_bd_addr_segs {S_AXI_LITE_CTRL_PORT/SEG_axi_cdma_0_Reg}]
set_property offset 0x00030000 [get_bd_addr_segs {AFU/axilite_buffer/jtag_axi_0/Data/SEG_axi_cdma_0_Reg}]
set_property offset 0x00000000 [get_bd_addr_segs {AFU/AFU_core/axi_cdma_0/Data/SEG_M_AXI_FULL_DATA_PORT_Reg}]

validate_bd_design
