
set_property PACKAGE_PIN AW27    [get_ports pcie_perstn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_perstn]
set_property PULLUP true         [get_ports pcie_perstn]
set_property PACKAGE_PIN AF8     [get_ports pcie_refclk_clk_n]
set_property PACKAGE_PIN AF9     [get_ports pcie_refclk_clk_p]
set_property IOSTANDARD LVDS     [get_ports pcie_refclk_clk_n]
set_property IOSTANDARD LVDS     [get_ports pcie_refclk_clk_p]

create_clock -period 10.000 -name refclk_100 [get_ports pcie_refclk_clk_p]
