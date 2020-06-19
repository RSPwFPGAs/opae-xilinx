##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : AXI-MM to PCI Express
## File       : xilinx_axi_pcie3_x0y0.xdc
## Version    : $IpVersion 
##-----------------------------------------------------------------------------
###########################################################################
# User Configuration 
# Link Width   - x8
# Link Speed   - gen3
# Family       - kintexu
# Part         - xcku040
# Package      - ffva1156
# Speed grade  - -2
# PCIe Block   - X0Y0
###########################################################################
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -name sys_clk -period 10 [get_ports sys_clk_p]
#
#
set_false_path -through [get_pins axi_pcie3_0_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*]
set_false_path -through [get_nets axi_pcie3_0_i/inst/inst/cfg_max*]


set_false_path -from [get_ports sys_rst_n]

	
###############################################################################
# User Physical Constraints
###############################################################################

###############################################################################
# Pinout and Related I/O Constraints
###############################################################################
##### SYS RESET###########
set_property LOC [get_package_pins -filter {PIN_FUNC == IO_T3U_N12_PERSTN0_65}] [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

##### REFCLK_IBUF###########
set_property LOC AB6 [get_ports sys_clk_p]
##### LED's ###########
set_property PACKAGE_PIN AP8 [get_ports led_0]   
# sys_reset
set_property PACKAGE_PIN H23 [get_ports led_1]   
# user_reset
set_property PACKAGE_PIN P20 [get_ports led_2]   
# user_link_up 
set_property PACKAGE_PIN P21 [get_ports led_3]   
# Clock Up/Heart Beat(HB)

set_property IOSTANDARD LVCMOS18 [get_ports led_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_1]
set_property IOSTANDARD LVCMOS18 [get_ports led_2]
set_property IOSTANDARD LVCMOS18 [get_ports led_3]
###############################################################################
# Flash Programming Settings: Uncomment as required by your design
# Items below between < > must be updated with correct values to work properly.
###############################################################################
# BPI Flash Programming
#set_property CONFIG_MODE BPI16 [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE <disable | Type1 | Type2> [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 9 [current_design]
#set_property CONFIG_VOLTAGE <voltage> [current_design]
#set_property CFGBVS GND [current_design]
# Example PROM Generation command that should be executed from the Tcl Console
#write_cfgmem -format mcs -interface bpix16 -size 128 -loadbit "up 0x0 <inputBitfile.bit>" <outputBitfile.bit>

# SPI Flash Programming
#set_property CONFIG_MODE SPIx4 [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 \[current_design\]"
#set_property CONFIG_VOLTAGE <voltage> [current_design]
#set_property CFGBVS <GND | VCC> [current_design]
# Example PROM Generation command that should be executed from the Tcl Console
#write_cfgmem -format mcs -interface spix4 -size 128 -loadbit "up 0x0 <inputBitfile.bit>" <outputBitfile.bit>
