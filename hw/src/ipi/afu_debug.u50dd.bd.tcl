
################################################################
# This is a generated script based on design: role_region_0
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
# source role_region_0_script.tcl

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
set design_name role_region_0

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
xilinx.com:ip:system_ila:*\
xilinx.com:ip:axi_cdma:*\
xilinx.com:ip:debug_bridge:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:util_reduced_logic:*\
xilinx.com:ip:xlconcat:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:blk_mem_gen:*\
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

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


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
  create_bd_pin -dir I -type clk axi_aclk_ctrl_port
  create_bd_pin -dir I -type rst axi_aresetn_ctrl_port

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.ECC_TYPE {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Enable_B {Always_Enabled} \
   CONFIG.Memory_Type {Single_Port_RAM} \
   CONFIG.Port_B_Clock {0} \
   CONFIG.Port_B_Enable_Rate {0} \
   CONFIG.Port_B_Write_Rate {0} \
   CONFIG.Use_RSTB_Pin {false} \
 ] $blk_mem_gen_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

  # Create port connections
  connect_bd_net -net axi_aclk_ctrl_port_1 [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net axi_aresetn_ctrl_port_1 [get_bd_pins axi_aresetn_ctrl_port] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: reset_buffer
proc create_hier_cell_reset_buffer { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_reset_buffer() - Empty argument(s)!"}
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
  create_bd_pin -dir I -from 0 -to 0 I_RSTN_PORT
  create_bd_pin -dir I -type clk axi_aclk_ctrl_port
  create_bd_pin -dir I -type clk axi_aclk_data_port
  create_bd_pin -dir I -from 0 -to 0 -type data axi_aresetn_ctrl_port
  create_bd_pin -dir O -from 0 -to 0 -type data axi_aresetn_ctrl_port_buffer
  create_bd_pin -dir I -from 0 -to 0 -type data axi_aresetn_data_port
  create_bd_pin -dir O -from 0 -to 0 -type data axi_aresetn_data_port_buffer

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

  # Create instance: util_reduced_logic_0, and set properties
  set util_reduced_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {2} \
 ] $util_reduced_logic_0

  # Create instance: util_reduced_logic_1, and set properties
  set util_reduced_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {2} \
 ] $util_reduced_logic_1

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]

  # Create port connections
  connect_bd_net -net I_RSTN_PORT_1 [get_bd_pins I_RSTN_PORT] [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net axi_aclk_ctrl_port_1 [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net axi_aclk_data_port_1 [get_bd_pins axi_aclk_data_port] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
  connect_bd_net -net axi_aresetn_ctrl_port_1 [get_bd_pins axi_aresetn_ctrl_port] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net axi_aresetn_data_port_1 [get_bd_pins axi_aresetn_data_port] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_aresetn_ctrl_port_buffer] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins axi_aresetn_data_port_buffer] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
  connect_bd_net -net util_reduced_logic_0_Res [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins util_reduced_logic_0/Res]
  connect_bd_net -net util_reduced_logic_1_Res [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins util_reduced_logic_1/Res]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins util_reduced_logic_0/Op1] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins util_reduced_logic_1/Op1] [get_bd_pins xlconcat_1/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axilite_buffer
proc create_hier_cell_axilite_buffer { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_axilite_buffer() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE_CTRL_PORT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_CTRL_PORT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bscan_rtl:1.0 S_BSCAN_PORT


  # Create pins
  create_bd_pin -dir I -type clk axi_aclk_ctrl_port
  create_bd_pin -dir I -type rst axi_aresetn_ctrl_port

  # Create instance: debug_bridge_0, and set properties
  set debug_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge debug_bridge_0 ]
  set_property -dict [ list \
   CONFIG.C_DESIGN_TYPE {1} \
 ] $debug_bridge_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_BSCAN_PORT] [get_bd_intf_pins debug_bridge_0/S_BSCAN]
  connect_bd_intf_net -intf_net S_AXI_LITE_CTRL_PORT_1 [get_bd_intf_pins M_AXI_LITE_CTRL_PORT] [get_bd_intf_pins S_AXI_LITE_CTRL_PORT]

  # Create port connections
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins debug_bridge_0/clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: AFU_core
proc create_hier_cell_AFU_core { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_AFU_core() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_DATA_PORT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_CTRL_PORT


  # Create pins
  create_bd_pin -dir O -type intr M_USR_IRQ_PORT
  create_bd_pin -dir I -type clk axi_aclk_ctrl_port
  create_bd_pin -dir I -type clk axi_aclk_data_port
  create_bd_pin -dir I -type rst axi_aresetn_ctrl_port
  create_bd_pin -dir I -type rst axi_aresetn_data_port

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {64} \
   CONFIG.C_INCLUDE_SG {0} \
   CONFIG.C_M_AXI_DATA_WIDTH {512} \
   CONFIG.C_M_AXI_MAX_BURST_LEN {2} \
 ] $axi_cdma_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_0

  # Create instance: feature_ram
  create_hier_cell_feature_ram $hier_obj feature_ram

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {6} \
   CONFIG.C_NUM_MONITOR_SLOTS {3} \
   CONFIG.C_SLOT {2} \
 ] $system_ila_0

  # Create instance: system_ila_1, and set properties
  set system_ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila system_ila_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_CTRL_PORT_1 [get_bd_intf_pins S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets S_AXI_LITE_CTRL_PORT_1] [get_bd_intf_pins S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins M_AXI_FULL_DATA_PORT] [get_bd_intf_pins axi_cdma_0/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_cdma_0_M_AXI] [get_bd_intf_pins M_AXI_FULL_DATA_PORT] [get_bd_intf_pins system_ila_1/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins feature_ram/S_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_interconnect_0_M00_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins system_ila_0/SLOT_1_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_interconnect_0_M01_AXI] [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins system_ila_0/SLOT_2_AXI]

  # Create port connections
  connect_bd_net -net axi_aclk_ctrl_port_1 [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins feature_ram/axi_aclk_ctrl_port] [get_bd_pins system_ila_0/clk]
  connect_bd_net -net axi_aclk_data_port_1 [get_bd_pins axi_aclk_data_port] [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins system_ila_1/clk]
  connect_bd_net -net axi_aresetn_ctrl_port_1 [get_bd_pins axi_aresetn_ctrl_port] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins feature_ram/axi_aresetn_ctrl_port] [get_bd_pins system_ila_0/resetn]
  connect_bd_net -net axi_aresetn_data_port_1 [get_bd_pins axi_aresetn_data_port] [get_bd_pins system_ila_1/resetn]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins M_USR_IRQ_PORT] [get_bd_pins axi_cdma_0/cdma_introut]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: AFU
proc create_hier_cell_AFU { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_AFU() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_DATA_PORT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_CTRL_PORT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bscan_rtl:1.0 S_BSCAN_PORT


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 I_RSTN_PORT
  create_bd_pin -dir O -from 0 -to 0 M_USR_IRQ_PORT
  create_bd_pin -dir I -type clk axi_aclk_ctrl_port
  create_bd_pin -dir I -type clk axi_aclk_data_port
  create_bd_pin -dir I axi_aresetn_ctrl_port
  create_bd_pin -dir I axi_aresetn_data_port

  # Create instance: AFU_core
  create_hier_cell_AFU_core $hier_obj AFU_core

  # Create instance: axilite_buffer
  create_hier_cell_axilite_buffer $hier_obj axilite_buffer

  # Create instance: reset_buffer
  create_hier_cell_reset_buffer $hier_obj reset_buffer

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila system_ila_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_BSCAN_PORT] [get_bd_intf_pins axilite_buffer/S_BSCAN_PORT]
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE_CTRL_1 [get_bd_intf_pins S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins axilite_buffer/S_AXI_LITE_CTRL_PORT]
  connect_bd_intf_net -intf_net [get_bd_intf_nets S_AXI_LITE_ROLE_CTRL_1] [get_bd_intf_pins S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins M_AXI_FULL_DATA_PORT] [get_bd_intf_pins AFU_core/M_AXI_FULL_DATA_PORT]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins AFU_core/S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins axilite_buffer/M_AXI_LITE_CTRL_PORT]

  # Create port connections
  connect_bd_net -net AFU_core_M_USR_IRQ_PORT [get_bd_pins M_USR_IRQ_PORT] [get_bd_pins AFU_core/M_USR_IRQ_PORT]
  connect_bd_net -net I_RSTN_PORT_1 [get_bd_pins I_RSTN_PORT] [get_bd_pins reset_buffer/I_RSTN_PORT]
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_pins axi_aclk_ctrl_port] [get_bd_pins AFU_core/axi_aclk_ctrl_port] [get_bd_pins axilite_buffer/axi_aclk_ctrl_port] [get_bd_pins reset_buffer/axi_aclk_ctrl_port] [get_bd_pins system_ila_0/clk]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_pins axi_aclk_data_port] [get_bd_pins AFU_core/axi_aclk_data_port] [get_bd_pins reset_buffer/axi_aclk_data_port]
  connect_bd_net -net axi_aresetn_role_ctrl_1 [get_bd_pins AFU_core/axi_aresetn_ctrl_port] [get_bd_pins axilite_buffer/axi_aresetn_ctrl_port] [get_bd_pins reset_buffer/axi_aresetn_ctrl_port_buffer]
  connect_bd_net -net axi_aresetn_role_ctrl_2 [get_bd_pins axi_aresetn_ctrl_port] [get_bd_pins reset_buffer/axi_aresetn_ctrl_port]
  connect_bd_net -net axi_aresetn_role_data_1 [get_bd_pins axi_aresetn_data_port] [get_bd_pins reset_buffer/axi_aresetn_data_port]
  connect_bd_net -net reset_buffer_ctrl1_Q [get_bd_pins AFU_core/axi_aresetn_data_port] [get_bd_pins reset_buffer/axi_aresetn_data_port_buffer] [get_bd_pins system_ila_0/resetn]

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
  set M_AXI_FULL_DATA_PORT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_DATA_PORT ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $M_AXI_FULL_DATA_PORT

  set S_AXI_LITE_CTRL_PORT [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_CTRL_PORT ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI_LITE_CTRL_PORT

  set S_BSCAN_PORT [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:bscan_rtl:1.0 S_BSCAN_PORT ]


  # Create ports
  set I_RSTN_PORT [ create_bd_port -dir I -from 0 -to 0 I_RSTN_PORT ]
  set M_USR_IRQ_PORT [ create_bd_port -dir O -from 0 -to 0 -type intr M_USR_IRQ_PORT ]
  set axi_aclk_ctrl_port [ create_bd_port -dir I -type clk -freq_hz 100000000 axi_aclk_ctrl_port ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXI_LITE_CTRL_PORT} \
   CONFIG.ASSOCIATED_RESET {axi_aresetn_role_ctrl:axi_aresetn_ctrl_port} \
 ] $axi_aclk_ctrl_port
  set axi_aclk_data_port [ create_bd_port -dir I -type clk -freq_hz 250000000 axi_aclk_data_port ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M_AXI_FULL_DATA_PORT} \
   CONFIG.ASSOCIATED_RESET {axi_aresetn_role_data} \
 ] $axi_aclk_data_port
  set axi_aresetn_ctrl_port [ create_bd_port -dir I axi_aresetn_ctrl_port ]
  set axi_aresetn_data_port [ create_bd_port -dir I axi_aresetn_data_port ]

  # Create instance: AFU
  create_hier_cell_AFU [current_bd_instance .] AFU

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE_CTRL_1 [get_bd_intf_ports S_AXI_LITE_CTRL_PORT] [get_bd_intf_pins AFU/S_AXI_LITE_CTRL_PORT]
  connect_bd_intf_net -intf_net S_BSCAN_0_1 [get_bd_intf_ports S_BSCAN_PORT] [get_bd_intf_pins AFU/S_BSCAN_PORT]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_ports M_AXI_FULL_DATA_PORT] [get_bd_intf_pins AFU/M_AXI_FULL_DATA_PORT]

  # Create port connections
  connect_bd_net -net AFU_Res_0 [get_bd_ports M_USR_IRQ_PORT] [get_bd_pins AFU/M_USR_IRQ_PORT]
  connect_bd_net -net I_ROLE_RSTN_1 [get_bd_ports I_RSTN_PORT] [get_bd_pins AFU/I_RSTN_PORT]
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_ports axi_aclk_ctrl_port] [get_bd_pins AFU/axi_aclk_ctrl_port]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_ports axi_aclk_data_port] [get_bd_pins AFU/axi_aclk_data_port]
  connect_bd_net -net axi_aresetn_role_ctrl_0_1 [get_bd_ports axi_aresetn_ctrl_port] [get_bd_pins AFU/axi_aresetn_ctrl_port]
  connect_bd_net -net axi_aresetn_role_data_0_1 [get_bd_ports axi_aresetn_data_port] [get_bd_pins AFU/axi_aresetn_data_port]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00010000000000000000 -target_address_space [get_bd_addr_spaces AFU/AFU_core/axi_cdma_0/Data] [get_bd_addr_segs M_AXI_FULL_DATA_PORT/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_LITE_CTRL_PORT] [get_bd_addr_segs AFU/AFU_core/feature_ram/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xA0030000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_LITE_CTRL_PORT] [get_bd_addr_segs AFU/AFU_core/axi_cdma_0/S_AXI_LITE/Reg] -force


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


