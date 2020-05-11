
################################################################
# This is a generated script based on design: shell_region
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2019.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_msg_id "BD_TCL-1002" "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source shell_region_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# pf_csr_v1_0

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu50-fsvh2104-2L-e
   set_property BOARD_PART xilinx.com:au50dd:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name shell_region

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:jtag_axi:*\
xilinx.com:ip:axi_hwicap:*\
xilinx.com:ip:clk_wiz:*\
xilinx.com:ip:debug_bridge:*\
xilinx.com:ip:axi_quad_spi:*\
xilinx.com:ip:system_management_wiz:*\
xilinx.com:ip:util_vector_logic:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:blk_mem_gen:*\
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:xdma:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:xlslice:*\
xilinx.com:ip:pr_axi_shutdown_manager:*\
xilinx.com:ip:axi_firewall:*\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
pf_csr_v1_0\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: port01_mux_out
proc create_hier_cell_port01_mux_out { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_port01_mux_out() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT0_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT1_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT01_OCTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT0_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT1_CTRL


  # Create pins
  create_bd_pin -dir I -type clk axi_aclk_role_ctrl
  create_bd_pin -dir I -type clk axi_aclk_role_data
  create_bd_pin -dir I -type rst axi_aresetn_role_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_role_data

  # Create instance: axi_firewall_0, and set properties
  set axi_firewall_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_firewall axi_firewall_0 ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
 ] $axi_firewall_0

  # Create instance: axi_firewall_1, and set properties
  set axi_firewall_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_firewall axi_firewall_1 ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
 ] $axi_firewall_1

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {4} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_2, and set properties
  set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_2 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $axi_interconnect_2

  # Create instance: axi_interconnect_3, and set properties
  set axi_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_3 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $axi_interconnect_3

  # Create instance: pr_axi_shutdown_mana_0, and set properties
  set pr_axi_shutdown_mana_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pr_axi_shutdown_manager pr_axi_shutdown_mana_0 ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_RESP {2} \
   CONFIG.DP_PROTOCOL {AXI4LITE} \
   CONFIG.RP_IS_MASTER {false} \
 ] $pr_axi_shutdown_mana_0

  # Create instance: pr_axi_shutdown_mana_1, and set properties
  set pr_axi_shutdown_mana_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pr_axi_shutdown_manager pr_axi_shutdown_mana_1 ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_RESP {2} \
   CONFIG.DP_PROTOCOL {AXI4LITE} \
   CONFIG.RP_IS_MASTER {false} \
 ] $pr_axi_shutdown_mana_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S_AXI_LITE_PORT01_OCTRL] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE0_CTRL_1 [get_bd_intf_pins S_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins axi_interconnect_2/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE1_CTRL_1 [get_bd_intf_pins S_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins axi_interconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net axi_firewall_0_M_AXI [get_bd_intf_pins M_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins axi_firewall_0/M_AXI]
  connect_bd_intf_net -intf_net axi_firewall_1_M_AXI [get_bd_intf_pins M_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins axi_firewall_1/M_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_0/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI1 [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_pins axi_firewall_0/S_AXI_CTL] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_1/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_2_M03_AXI [get_bd_intf_pins axi_firewall_1/S_AXI_CTL] [get_bd_intf_pins axi_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M00_AXI [get_bd_intf_pins axi_interconnect_3/M00_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_1/S_AXI]
  connect_bd_intf_net -intf_net pr_axi_shutdown_mana_0_M_AXI [get_bd_intf_pins axi_firewall_0/S_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_0/M_AXI]
  connect_bd_intf_net -intf_net pr_axi_shutdown_mana_1_M_AXI [get_bd_intf_pins axi_firewall_1/S_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_1/M_AXI]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins axi_aresetn_role_ctrl] [get_bd_pins axi_firewall_0/aresetn] [get_bd_pins axi_firewall_1/aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_3/ARESETN] [get_bd_pins axi_interconnect_3/M00_ARESETN] [get_bd_pins pr_axi_shutdown_mana_0/resetn] [get_bd_pins pr_axi_shutdown_mana_1/resetn]
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_pins axi_aclk_role_ctrl] [get_bd_pins axi_firewall_0/aclk] [get_bd_pins axi_firewall_1/aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_3/ACLK] [get_bd_pins axi_interconnect_3/M00_ACLK] [get_bd_pins pr_axi_shutdown_mana_0/clk] [get_bd_pins pr_axi_shutdown_mana_1/clk]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_pins axi_aclk_role_data] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_interconnect_3/S00_ACLK]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_role_data] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_interconnect_3/S00_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: port01_mux_in
proc create_hier_cell_port01_mux_in { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_port01_mux_in() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_BRIDGE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_PORT0_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_PORT1_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT01_ICTRL


  # Create pins
  create_bd_pin -dir I -type clk axi_aclk_port_ctrl
  create_bd_pin -dir I -type clk axi_aclk_port_data
  create_bd_pin -dir I -type rst axi_aresetn_port_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_port_data

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_1

  # Create instance: pr_axi_shutdown_mana_0, and set properties
  set pr_axi_shutdown_mana_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pr_axi_shutdown_manager pr_axi_shutdown_mana_0 ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_ADDR_WIDTH {64} \
   CONFIG.DP_AXI_DATA_WIDTH {512} \
   CONFIG.DP_AXI_RESP {2} \
   CONFIG.DP_PROTOCOL {AXI4MM} \
 ] $pr_axi_shutdown_mana_0

  # Create instance: pr_axi_shutdown_mana_1, and set properties
  set pr_axi_shutdown_mana_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pr_axi_shutdown_manager pr_axi_shutdown_mana_1 ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_ADDR_WIDTH {64} \
   CONFIG.DP_AXI_DATA_WIDTH {512} \
   CONFIG.DP_AXI_RESP {2} \
   CONFIG.DP_PROTOCOL {AXI4MM} \
 ] $pr_axi_shutdown_mana_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI_FULL_PORT0_DATA] [get_bd_intf_pins pr_axi_shutdown_mana_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI_FULL_PORT1_DATA] [get_bd_intf_pins pr_axi_shutdown_mana_1/S_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S_AXI_LITE_PORT01_ICTRL] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_0/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_1/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins M_AXI_BRIDGE] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net pr_axi_shutdown_mana_1_M_AXI [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_0/M_AXI]
  connect_bd_intf_net -intf_net pr_axi_shutdown_mana_3_M_AXI [get_bd_intf_pins axi_interconnect_1/S01_AXI] [get_bd_intf_pins pr_axi_shutdown_mana_1/M_AXI]

  # Create port connections
  connect_bd_net -net S00_ACLK_1 [get_bd_pins axi_aclk_port_ctrl] [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins axi_aresetn_port_ctrl] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_port_data] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_1/S01_ARESETN] [get_bd_pins pr_axi_shutdown_mana_0/resetn] [get_bd_pins pr_axi_shutdown_mana_1/resetn]
  connect_bd_net -net shell_axi_aclk_role_data [get_bd_pins axi_aclk_port_data] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_1/S01_ACLK] [get_bd_pins pr_axi_shutdown_mana_0/clk] [get_bd_pins pr_axi_shutdown_mana_1/clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pf_csr
proc create_hier_cell_pf_csr { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_pf_csr() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s00_axi


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 O_ROLE_RSTN_0
  create_bd_pin -dir O -from 0 -to 0 O_ROLE_RSTN_1
  create_bd_pin -dir I -type clk axi_aclk_role_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_role_ctrl

  # Create instance: pf_csr_v1_0_0, and set properties
  set block_name pf_csr_v1_0
  set block_cell_name pf_csr_v1_0_0
  if { [catch {set pf_csr_v1_0_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $pf_csr_v1_0_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins s00_axi] [get_bd_intf_pins pf_csr_v1_0_0/s00_axi]

  # Create port connections
  connect_bd_net -net pf_csr_v1_0_0_slv_reg4_out [get_bd_pins pf_csr_v1_0_0/slv_reg4_out] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net qdma_0_axi_aclk [get_bd_pins axi_aclk_role_ctrl] [get_bd_pins pf_csr_v1_0_0/s00_axi_aclk]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_role_ctrl] [get_bd_pins pf_csr_v1_0_0/s00_axi_aresetn]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins O_ROLE_RSTN_0] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins O_ROLE_RSTN_1] [get_bd_pins xlslice_1/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: base_tieoffs
proc create_hier_cell_base_tieoffs { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_base_tieoffs() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O -from 0 -to 0 const_gnd_1_dout

  # Create instance: const_gnd_1, and set properties
  set const_gnd_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_gnd_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $const_gnd_1

  # Create port connections
  connect_bd_net -net const_gnd_1_dout [get_bd_pins const_gnd_1_dout] [get_bd_pins const_gnd_1/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pcie_axi_bridge
proc create_hier_cell_pcie_axi_bridge { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_pcie_axi_bridge() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir O -type clk axi_aclk_port_data
  create_bd_pin -dir O -from 0 -to 0 -type rst axi_aresetn_port_data
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma xdma_0 ]
  set_property -dict [ list \
   CONFIG.PCIE_BOARD_INTERFACE {pci_express_x8} \
   CONFIG.PF0_DEVICE_ID_mqdma {9038} \
   CONFIG.PF2_DEVICE_ID_mqdma {9038} \
   CONFIG.PF3_DEVICE_ID_mqdma {9038} \
   CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn} \
   CONFIG.axi_addr_width {32} \
   CONFIG.axi_data_width {256_bit} \
   CONFIG.bar_indicator {BAR_1:0} \
   CONFIG.c_s_axi_supports_narrow_burst {true} \
   CONFIG.coreclk_freq {500} \
   CONFIG.en_axi_master_if {true} \
   CONFIG.en_axi_slave_if {true} \
   CONFIG.en_gt_selection {true} \
   CONFIG.functional_mode {AXI_Bridge} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.pcie_blk_locn {PCIE4C_X1Y1} \
   CONFIG.pcie_id_if {false} \
   CONFIG.pf0_bar0_64bit {true} \
   CONFIG.pf0_bar0_prefetchable {true} \
   CONFIG.pf0_bar0_size {128} \
   CONFIG.pf0_bar2_64bit {true} \
   CONFIG.pf0_bar2_enabled {true} \
   CONFIG.pf0_bar2_prefetchable {true} \
   CONFIG.pf0_bar2_scale {Megabytes} \
   CONFIG.pf0_bar2_size {64} \
   CONFIG.pf0_base_class_menu {Memory_controller} \
   CONFIG.pf0_class_code {120000} \
   CONFIG.pf0_class_code_base {12} \
   CONFIG.pf0_class_code_interface {00} \
   CONFIG.pf0_class_code_sub {00} \
   CONFIG.pf0_device_id {09c4} \
   CONFIG.pf0_msi_enabled {false} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
   CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
   CONFIG.pf0_sub_class_interface_menu {Other_memory_controller} \
   CONFIG.pf0_subsystem_id {0000} \
   CONFIG.pf0_subsystem_vendor_id {8086} \
   CONFIG.pipe_sim {true} \
   CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X8} \
   CONFIG.plltype {QPLL1} \
   CONFIG.select_quad {GTY_Quad_227} \
   CONFIG.vendor_id {8086} \
   CONFIG.xdma_axilite_slave {true} \
 ] $xdma_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins xdma_0/S_AXI_B]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net xdma_0_M_AXI_B [get_bd_intf_pins M_AXI] [get_bd_intf_pins xdma_0/M_AXI_B]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_pins pci_express] [get_bd_intf_pins xdma_0/pcie_mgt]

  # Create port connections
  connect_bd_net -net pcie_perstn_1 [get_bd_pins pcie_perstn] [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins util_ds_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net xdma_0_axi_aclk [get_bd_pins axi_aclk_port_data] [get_bd_pins xdma_0/axi_aclk]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins axi_aresetn_port_data] [get_bd_pins xdma_0/axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: feature_ram
proc create_hier_cell_feature_ram { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_feature_ram() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI


  # Create pins
  create_bd_pin -dir I -type clk axi_aclk_role_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_role_ctrl

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.ECC_TYPE {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
 ] $axi_bram_ctrl_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

  # Create port connections
  connect_bd_net -net qdma_0_axi_aclk [get_bd_pins axi_aclk_role_ctrl] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_role_ctrl] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PORT01
proc create_hier_cell_PORT01 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_PORT01() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_BRIDGE

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT0_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT1_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_PORT0_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_PORT1_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT01_ICTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT01_OCTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT0_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_PORT1_CTRL


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 M_USR_IRQ
  create_bd_pin -dir I -from 0 -to 0 S_USR_IRQ_PORT0
  create_bd_pin -dir I -from 0 -to 0 S_USR_IRQ_PORT1
  create_bd_pin -dir I -type clk axi_aclk_port_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_port_ctrl

  # Create instance: port01_mux_in
  create_hier_cell_port01_mux_in $hier_obj port01_mux_in

  # Create instance: port01_mux_out
  create_hier_cell_port01_mux_out $hier_obj port01_mux_out

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI_FULL_PORT0_DATA] [get_bd_intf_pins port01_mux_in/S_AXI_FULL_PORT0_DATA]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI_FULL_PORT1_DATA] [get_bd_intf_pins port01_mux_in/S_AXI_FULL_PORT1_DATA]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S_AXI_LITE_PORT01_OCTRL] [get_bd_intf_pins port01_mux_out/S_AXI_LITE_PORT01_OCTRL]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S_AXI_LITE_PORT01_ICTRL] [get_bd_intf_pins port01_mux_in/S_AXI_LITE_PORT01_ICTRL]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins M_AXI_BRIDGE] [get_bd_intf_pins port01_mux_in/M_AXI_BRIDGE]
  connect_bd_intf_net -intf_net shell_core_S_AXI_ROLE0PF_0 [get_bd_intf_pins S_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins port01_mux_out/S_AXI_LITE_PORT0_CTRL]
  connect_bd_intf_net -intf_net shell_core_S_AXI_ROLE1PF_0 [get_bd_intf_pins S_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins port01_mux_out/S_AXI_LITE_PORT1_CTRL]
  connect_bd_intf_net -intf_net shell_mux_out_M_AXI_LITE_ROLE0_CTRL [get_bd_intf_pins M_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins port01_mux_out/M_AXI_LITE_PORT0_CTRL]
  connect_bd_intf_net -intf_net shell_mux_out_M_AXI_LITE_ROLE1_CTRL [get_bd_intf_pins M_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins port01_mux_out/M_AXI_LITE_PORT1_CTRL]

  # Create port connections
  connect_bd_net -net Op1_0_1 [get_bd_pins S_USR_IRQ_PORT0] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net Op2_0_1 [get_bd_pins S_USR_IRQ_PORT1] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net shell_core_axi_aclk [get_bd_pins axi_aclk_port_ctrl] [get_bd_pins port01_mux_in/axi_aclk_port_ctrl] [get_bd_pins port01_mux_in/axi_aclk_port_data] [get_bd_pins port01_mux_out/axi_aclk_role_ctrl] [get_bd_pins port01_mux_out/axi_aclk_role_data]
  connect_bd_net -net shell_core_axi_aresetn [get_bd_pins axi_aresetn_port_ctrl] [get_bd_pins port01_mux_in/axi_aresetn_port_ctrl] [get_bd_pins port01_mux_in/axi_aresetn_port_data] [get_bd_pins port01_mux_out/axi_aresetn_role_ctrl] [get_bd_pins port01_mux_out/axi_aresetn_role_data]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins M_USR_IRQ] [get_bd_pins util_vector_logic_0/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: FME
proc create_hier_cell_FME { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_FME() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT01_ICTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT01_OCTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_FME_CTRL


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 O_RSTN_PORT0
  create_bd_pin -dir O -from 0 -to 0 O_RSTN_PORT1
  create_bd_pin -dir I -type clk axi_aclk_role_data
  create_bd_pin -dir I -type rst axi_aresetn_role_data

  # Create instance: axi_hwicap, and set properties
  set axi_hwicap [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_hwicap axi_hwicap ]
  set_property -dict [ list \
   CONFIG.C_WRITE_FIFO_DEPTH {1024} \
 ] $axi_hwicap

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {5} \
   CONFIG.NUM_SI {1} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_1 ]

  # Create instance: base_tieoffs
  create_hier_cell_base_tieoffs $hier_obj base_tieoffs

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_LOCKED {true} \
 ] $clk_wiz_0

  # Create instance: debug_bridge_0, and set properties
  set debug_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge debug_bridge_0 ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_MODE {7} \
   CONFIG.C_DESIGN_TYPE {0} \
   CONFIG.C_NUM_BS_MASTER {3} \
 ] $debug_bridge_0

  # Create instance: debug_bridge_s0, and set properties
  set debug_bridge_s0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge debug_bridge_s0 ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_MODE {1} \
   CONFIG.C_NUM_BS_MASTER {0} \
 ] $debug_bridge_s0

  # Create instance: flash_programmer, and set properties
  set flash_programmer [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi flash_programmer ]
  set_property -dict [ list \
   CONFIG.C_FIFO_DEPTH {16} \
   CONFIG.C_NUM_SS_BITS {1} \
   CONFIG.C_SCK_RATIO {2} \
   CONFIG.C_SPI_MEMORY {2} \
   CONFIG.C_SPI_MODE {2} \
   CONFIG.C_TYPE_OF_AXI4_INTERFACE {0} \
   CONFIG.C_USE_STARTUP {1} \
   CONFIG.C_USE_STARTUP_INT {1} \
 ] $flash_programmer

  # Create instance: pf_csr
  create_hier_cell_pf_csr $hier_obj pf_csr

  # Create instance: system_management_wiz_0, and set properties
  set system_management_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz system_management_wiz_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXI_LITE_PORT01_ICTRL] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M_AXI_LITE_PORT01_OCTRL] [get_bd_intf_pins axi_interconnect_1/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins system_management_wiz_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_hwicap/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins flash_programmer/AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins pf_csr/s00_axi]
  connect_bd_intf_net -intf_net debug_bridge_0_m0_bscan [get_bd_intf_pins debug_bridge_0/m0_bscan] [get_bd_intf_pins debug_bridge_s0/S_BSCAN]
  connect_bd_intf_net -intf_net pcie_2_axilite_0_m_axi [get_bd_intf_pins S_AXI_LITE_FME_CTRL] [get_bd_intf_pins axi_interconnect_0/S00_AXI]

  # Create port connections
  connect_bd_net -net base_tieoffs_dout [get_bd_pins axi_hwicap/eos_in] [get_bd_pins base_tieoffs/const_gnd_1_dout] [get_bd_pins flash_programmer/usrcclkts]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins axi_hwicap/icap_clk] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins flash_programmer/ext_spi_clk]
  connect_bd_net -net pf_csr_O_ROLE_RSTN_0 [get_bd_pins O_RSTN_PORT0] [get_bd_pins pf_csr/O_ROLE_RSTN_0]
  connect_bd_net -net pf_csr_O_ROLE_RSTN_1 [get_bd_pins O_RSTN_PORT1] [get_bd_pins pf_csr/O_ROLE_RSTN_1]
  connect_bd_net -net qdma_0_axi_aclk [get_bd_pins axi_aclk_role_data] [get_bd_pins axi_hwicap/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins debug_bridge_s0/clk] [get_bd_pins flash_programmer/s_axi_aclk] [get_bd_pins pf_csr/axi_aclk_role_ctrl] [get_bd_pins system_management_wiz_0/s_axi_aclk]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_role_data] [get_bd_pins axi_hwicap/s_axi_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins clk_wiz_0/resetn] [get_bd_pins flash_programmer/s_axi_aresetn] [get_bd_pins pf_csr/axi_aresetn_role_ctrl] [get_bd_pins system_management_wiz_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: FIU
proc create_hier_cell_FIU { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_FIU() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_FME_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT0_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_PORT1_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_BRIDGE

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir O -type clk axi_aclk_port_data
  create_bd_pin -dir O -from 0 -to 0 axi_aresetn_port_data
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {4} \
   CONFIG.NUM_SI {2} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_0

  # Create instance: feature_ram
  create_hier_cell_feature_ram $hier_obj feature_ram

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0 ]

  # Create instance: pcie_axi_bridge
  create_hier_cell_pcie_axi_bridge $hier_obj pcie_axi_bridge

  # Create interface connections
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net S_AXI_BRIDGE_1 [get_bd_intf_pins S_AXI_BRIDGE] [get_bd_intf_pins pcie_axi_bridge/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins feature_ram/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins M_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins M_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins axi_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net pcie3_ultrascale_0_pcie_7x_mgt [get_bd_intf_pins pci_express] [get_bd_intf_pins pcie_axi_bridge/pci_express]
  connect_bd_intf_net -intf_net pcie_2_axilite_0_m_axi [get_bd_intf_pins M_AXI_LITE_FME_CTRL] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net pcie_2_axilite_0_m_axi_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins pcie_axi_bridge/M_AXI]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins pcie_axi_bridge/pcie_refclk]

  # Create port connections
  connect_bd_net -net qdma_0_axi_aclk [get_bd_pins axi_aclk_port_data] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins feature_ram/axi_aclk_role_ctrl] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins pcie_axi_bridge/axi_aclk_port_data]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_aresetn_port_data] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins feature_ram/axi_aresetn_role_ctrl] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins pcie_axi_bridge/axi_aresetn_port_data]
  connect_bd_net -net sys_reset_0_1 [get_bd_pins pcie_perstn] [get_bd_pins pcie_axi_bridge/pcie_perstn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: FIM
proc create_hier_cell_FIM { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_FIM() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_CTRL_PORT0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_CTRL_PORT1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_DATA_PORT0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_FULL_DATA_PORT1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 O_RSTN_PORT0
  create_bd_pin -dir O -from 0 -to 0 O_RSTN_PORT1
  create_bd_pin -dir I -from 0 -to 0 S_USR_IRQ_PORT0
  create_bd_pin -dir I -from 0 -to 0 S_USR_IRQ_PORT1
  create_bd_pin -dir O -type clk axi_aclk_ctrl_port
  create_bd_pin -dir O -type clk axi_aclk_data_port
  create_bd_pin -dir O -from 0 -to 0 -type rst axi_aresetn_ctrl_port
  create_bd_pin -dir O -from 0 -to 0 -type rst axi_aresetn_data_port
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: FIU
  create_hier_cell_FIU $hier_obj FIU

  # Create instance: FME
  create_hier_cell_FME $hier_obj FME

  # Create instance: PORT01
  create_hier_cell_PORT01 $hier_obj PORT01

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI_FULL_DATA_PORT0] [get_bd_intf_pins PORT01/S_AXI_FULL_PORT0_DATA]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI_FULL_DATA_PORT1] [get_bd_intf_pins PORT01/S_AXI_FULL_PORT1_DATA]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins FME/M_AXI_LITE_PORT01_OCTRL] [get_bd_intf_pins PORT01/S_AXI_LITE_PORT01_OCTRL]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins FME/M_AXI_LITE_PORT01_ICTRL] [get_bd_intf_pins PORT01/S_AXI_LITE_PORT01_ICTRL]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins FIU/S_AXI_BRIDGE] [get_bd_intf_pins PORT01/M_AXI_BRIDGE]
  connect_bd_intf_net -intf_net pcie_2_axilite_0_m_axi [get_bd_intf_pins FIU/M_AXI_LITE_FME_CTRL] [get_bd_intf_pins FME/S_AXI_LITE_FME_CTRL]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins FIU/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_pins pci_express] [get_bd_intf_pins FIU/pci_express]
  connect_bd_intf_net -intf_net shell_core_S_AXI_ROLE0PF_0 [get_bd_intf_pins FIU/M_AXI_LITE_PORT0_CTRL] [get_bd_intf_pins PORT01/S_AXI_LITE_PORT0_CTRL]
  connect_bd_intf_net -intf_net shell_core_S_AXI_ROLE1PF_0 [get_bd_intf_pins FIU/M_AXI_LITE_PORT1_CTRL] [get_bd_intf_pins PORT01/S_AXI_LITE_PORT1_CTRL]
  connect_bd_intf_net -intf_net shell_mux_out_M_AXI_LITE_ROLE0_CTRL [get_bd_intf_pins M_AXI_LITE_CTRL_PORT0] [get_bd_intf_pins PORT01/M_AXI_LITE_PORT0_CTRL]
  connect_bd_intf_net -intf_net shell_mux_out_M_AXI_LITE_ROLE1_CTRL [get_bd_intf_pins M_AXI_LITE_CTRL_PORT1] [get_bd_intf_pins PORT01/M_AXI_LITE_PORT1_CTRL]

  # Create port connections
  connect_bd_net -net FME_O_RSTN_PORT0 [get_bd_pins O_RSTN_PORT0] [get_bd_pins FME/O_RSTN_PORT0]
  connect_bd_net -net FME_O_RSTN_PORT1 [get_bd_pins O_RSTN_PORT1] [get_bd_pins FME/O_RSTN_PORT1]
  connect_bd_net -net Op1_0_1 [get_bd_pins S_USR_IRQ_PORT0] [get_bd_pins PORT01/S_USR_IRQ_PORT0]
  connect_bd_net -net Op2_0_1 [get_bd_pins S_USR_IRQ_PORT1] [get_bd_pins PORT01/S_USR_IRQ_PORT1]
  connect_bd_net -net shell_core_axi_aclk [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins axi_aclk_data_port] [get_bd_pins FIU/axi_aclk_port_data] [get_bd_pins FME/axi_aclk_role_data] [get_bd_pins PORT01/axi_aclk_port_ctrl]
  connect_bd_net -net shell_core_axi_aresetn [get_bd_pins axi_aresetn_ctrl_port] [get_bd_pins axi_aresetn_data_port] [get_bd_pins FIU/axi_aresetn_port_data] [get_bd_pins FME/axi_aresetn_role_data] [get_bd_pins PORT01/axi_aresetn_port_ctrl]
  connect_bd_net -net sys_reset_0_1 [get_bd_pins pcie_perstn] [get_bd_pins FIU/pcie_perstn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set pci_express [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk


  # Create ports
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]

  # Create instance: FIM
  create_hier_cell_FIM [current_bd_instance .] FIM

  # Create interface connections
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins FIM/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_ports pci_express] [get_bd_intf_pins FIM/pci_express]

  # Create port connections
  connect_bd_net -net sys_reset_0_1 [get_bd_ports pcie_perstn] [get_bd_pins FIM/pcie_perstn]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/FIU/feature_ram/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00014000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_out/axi_firewall_0/S_AXI_CTL/Control] -force
  assign_bd_address -offset 0x00015000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_out/axi_firewall_1/S_AXI_CTL/Control] -force
  assign_bd_address -offset 0x00012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/FME/axi_hwicap/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00013000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/FME/flash_programmer/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/FME/pf_csr/pf_csr_v1_0_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x00019000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_in/pr_axi_shutdown_mana_0/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x00018000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_out/pr_axi_shutdown_mana_0/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_in/pr_axi_shutdown_mana_1/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/PORT01/port01_mux_out/pr_axi_shutdown_mana_1/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/jtag_axi_0/Data] [get_bd_addr_segs FIM/FME/system_management_wiz_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/FIU/feature_ram/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00014000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_out/axi_firewall_0/S_AXI_CTL/Control] -force
  assign_bd_address -offset 0x00015000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_out/axi_firewall_1/S_AXI_CTL/Control] -force
  assign_bd_address -offset 0x00012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/FME/axi_hwicap/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00013000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/FME/flash_programmer/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/FME/pf_csr/pf_csr_v1_0_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x00019000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_in/pr_axi_shutdown_mana_0/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x00018000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_out/pr_axi_shutdown_mana_0/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_in/pr_axi_shutdown_mana_1/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/PORT01/port01_mux_out/pr_axi_shutdown_mana_1/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x0001E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces FIM/FIU/pcie_axi_bridge/xdma_0/M_AXI_B] [get_bd_addr_segs FIM/FME/system_management_wiz_0/S_AXI_LITE/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


