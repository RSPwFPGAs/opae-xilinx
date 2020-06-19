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
## Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
## File       : xilinx_pcie3_uscale_ep_x8g3.xdc
## Version    : 4.4 
##-----------------------------------------------------------------------------
#
# User Configuration 
# Link Width   - x8
# Link Speed   - Gen3
# Family       - kintexu
# Part         - xcku040
# Package      - ffva1156
# Speed grade  - -2
# PCIe Block   - X0Y0
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -name sys_clk -period 10 [get_ports sys_clk_p]


set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

#
#

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
set_property PACKAGE_PIN N22 [get_ports led_4]   
# link_speed[0] Gen2; Gen3; - HB
set_property PACKAGE_PIN M22 [get_ports led_5]   
# link_speed[1] Gen1; Gen3; - HB
set_property PACKAGE_PIN R23 [get_ports led_6]   
# link_width[0] x8; x4; x1=1'b0; - HB
set_property PACKAGE_PIN P23 [get_ports led_7]   
# link_width[1] x8; x2; x1=HB;   - HB

set_property IOSTANDARD LVCMOS18 [get_ports led_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_1]
set_property IOSTANDARD LVCMOS18 [get_ports led_2]
set_property IOSTANDARD LVCMOS18 [get_ports led_3]
set_property IOSTANDARD LVCMOS18 [get_ports led_4]
set_property IOSTANDARD LVCMOS18 [get_ports led_5]
set_property IOSTANDARD LVCMOS18 [get_ports led_6]
set_property IOSTANDARD LVCMOS18 [get_ports led_7]
#
set_false_path -to [get_ports -filter {NAME=~led_*}]

###############################################################################
# Flash Programming Settings: Uncomment as required by your design
# Items below between < > must be updated with correct values to work properly.
###############################################################################
# SPI Flash Programming
#set_property CONFIG_MODE SPIx8 [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#set_property CONFIG_VOLTAGE 1.8 [current_design]
#set_property CFGBVS GND [current_design]
# Example PROM Generation command that should be executed from the Tcl Console
#write_cfgmem -format mcs -interface spix8 -size 256 -loadbit "up 0x0 <inputBitfile.bit>" <outputBitfile.mcs>
