
set_property PACKAGE_PIN K22 [get_ports pcie_perstn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_perstn]
set_property PULLUP true [get_ports pcie_perstn]
set_property PACKAGE_PIN AB5 [get_ports pcie_refclk_clk_n]

create_clock -period 10.000 -name refclk_100 [get_ports pcie_refclk_clk_p]
set_false_path -to [get_cells {*/gt_top_i/phy_rst_i/sync_phystatus/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -to [get_cells {*/gt_top_i/phy_rst_i/sync_rxresetdone/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -to [get_cells {*/gt_top_i/phy_rst_i/sync_txresetdone/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -from [get_pins */gt_top_i/phy_rst_i/idle_reg/C] -to [get_pins {*/pcie3_uscale_top_inst/init_ctrl_inst/reg_reset_timer_reg[*]/CLR}]
set_false_path -from [get_pins */gt_top_i/phy_rst_i/idle_reg/C] -to [get_pins {*/pcie3_uscale_top_inst/init_ctrl_inst/reg_phy_rdy_reg[*]/PRE}]
