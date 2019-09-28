
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
set scripts_vivado_version 2018.3
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
   create_project project_1 myproj -part xcku040-ffva1156-2-e
   set_property BOARD_PART xilinx.com:kcu105:part0:1.5 [current_project]
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
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:blk_mem_gen:*\
xilinx.com:ip:debug_bridge:*\
xilinx.com:ip:jtag_axi:*\
xilinx.com:ip:c_shift_ram:*\
xilinx.com:ip:system_ila:*\
xilinx.com:ip:util_vector_logic:*\
xilinx.com:ip:axi_cdma:*\
xilinx.com:ip:smartconnect:*\
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


# Hierarchical cell: role_core
proc create_hier_cell_role_core { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_role_core() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_ROLE_DATA_CDMA
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  # Create pins
  create_bd_pin -dir I -type clk axi_aclk_role_ctrl
  create_bd_pin -dir I -type clk axi_aclk_role_data
  create_bd_pin -dir I -type rst axi_aresetn_role_ctrl
  create_bd_pin -dir I -type rst axi_aresetn_role_data

  # Create instance: axi_bram_ctrl_0_bram1, and set properties
  set axi_bram_ctrl_0_bram1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen axi_bram_ctrl_0_bram1 ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram1

  # Create instance: axi_bram_ctrl_0_bram2, and set properties
  set axi_bram_ctrl_0_bram2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen axi_bram_ctrl_0_bram2 ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram2

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_1 ]

  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_2 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_2

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {64} \
   CONFIG.C_INCLUDE_SG {0} \
   CONFIG.C_M_AXI_DATA_WIDTH {512} \
   CONFIG.C_M_AXI_MAX_BURST_LEN {2} \
 ] $axi_cdma_0

  # Create instance: axi_cdma_1, and set properties
  set axi_cdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_1 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {64} \
   CONFIG.C_INCLUDE_SG {0} \
   CONFIG.C_M_AXI_DATA_WIDTH {512} \
   CONFIG.C_M_AXI_MAX_BURST_LEN {2} \
 ] $axi_cdma_1

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {1} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_0

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_CLKS {1} \
   CONFIG.NUM_MI {2} \
 ] $smartconnect_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram1/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA1 [get_bd_intf_pins axi_bram_ctrl_0_bram2/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0_bram1/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB1 [get_bd_intf_pins axi_bram_ctrl_0_bram2/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_1_M_AXI [get_bd_intf_pins axi_cdma_1/M_AXI] [get_bd_intf_pins smartconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_cdma_1/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins M_AXI_FULL_ROLE_DATA_CDMA] [get_bd_intf_pins smartconnect_0/M01_AXI]

  # Create port connections
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_pins axi_aclk_role_ctrl] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_cdma_1/s_axi_lite_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_pins axi_aclk_role_data] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins axi_cdma_1/m_axi_aclk] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net axi_aresetn_role_ctrl_1 [get_bd_pins axi_aresetn_role_ctrl] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_cdma_1/s_axi_lite_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net axi_aresetn_role_data_1 [get_bd_pins axi_aresetn_role_data] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins smartconnect_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: role_top
proc create_hier_cell_role_top { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_role_top() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_ROLE_DATA_CDMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_qdma:usr_irq_rtl:1.0 M_USR_IRQ
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_ROLE_CTRL
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_SHRL_CTRL

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 I_ROLE_RSTN
  create_bd_pin -dir I -type clk axi_aclk_role_ctrl
  create_bd_pin -dir I -type clk axi_aclk_role_data
  create_bd_pin -dir I axi_aresetn_role_ctrl
  create_bd_pin -dir I axi_aresetn_role_data

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.ECC_TYPE {Hamming} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_interconnect_2, and set properties
  set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_2 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.NUM_SI {2} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_2

  # Create instance: axi_interconnect_3, and set properties
  set axi_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_3 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.STRATEGY {1} \
 ] $axi_interconnect_3

  # Create instance: debug_bridge_0, and set properties
  set debug_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge debug_bridge_0 ]
  set_property -dict [ list \
   CONFIG.C_DESIGN_TYPE {1} \
 ] $debug_bridge_0

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0 ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {2} \
 ] $jtag_axi_0

  # Create instance: reset_buffer_ctrl, and set properties
  set reset_buffer_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram reset_buffer_ctrl ]
  set_property -dict [ list \
   CONFIG.AsyncInitVal {0} \
   CONFIG.DefaultData {0} \
   CONFIG.Depth {2} \
   CONFIG.SyncInitVal {0} \
   CONFIG.Width {1} \
 ] $reset_buffer_ctrl

  # Create instance: reset_buffer_data, and set properties
  set reset_buffer_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram reset_buffer_data ]
  set_property -dict [ list \
   CONFIG.AsyncInitVal {0} \
   CONFIG.DefaultData {0} \
   CONFIG.Depth {2} \
   CONFIG.SyncInitVal {0} \
   CONFIG.Width {1} \
 ] $reset_buffer_data

  # Create instance: role_core
  create_hier_cell_role_core $hier_obj role_core

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila system_ila_0 ]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_1

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE_CTRL_1 [get_bd_intf_pins S_AXI_LITE_ROLE_CTRL] [get_bd_intf_pins axi_interconnect_2/S00_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets S_AXI_LITE_ROLE_CTRL_1] [get_bd_intf_pins S_AXI_LITE_ROLE_CTRL] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_SHRL_CTRL_1 [get_bd_intf_pins S_AXI_LITE_SHRL_CTRL] [get_bd_intf_pins axi_interconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins M_AXI_FULL_ROLE_DATA_CDMA] [get_bd_intf_pins role_core/M_AXI_FULL_ROLE_DATA_CDMA]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins axi_interconnect_3/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_pins axi_interconnect_2/M01_AXI] [get_bd_intf_pins role_core/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_interconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]

  # Create port connections
  connect_bd_net -net I_ROLE_RSTN_1 [get_bd_pins I_ROLE_RSTN] [get_bd_pins util_vector_logic_0/Op2] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_pins axi_aclk_role_ctrl] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/M01_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_interconnect_2/S01_ACLK] [get_bd_pins axi_interconnect_3/ACLK] [get_bd_pins axi_interconnect_3/M00_ACLK] [get_bd_pins axi_interconnect_3/S00_ACLK] [get_bd_pins axi_interconnect_3/S01_ACLK] [get_bd_pins debug_bridge_0/clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins reset_buffer_ctrl/CLK] [get_bd_pins role_core/axi_aclk_role_ctrl] [get_bd_pins system_ila_0/clk]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_pins axi_aclk_role_data] [get_bd_pins reset_buffer_data/CLK] [get_bd_pins role_core/axi_aclk_role_data]
  connect_bd_net -net axi_aresetn_role_ctrl_1 [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/M01_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_interconnect_2/S01_ARESETN] [get_bd_pins axi_interconnect_3/ARESETN] [get_bd_pins axi_interconnect_3/M00_ARESETN] [get_bd_pins axi_interconnect_3/S00_ARESETN] [get_bd_pins axi_interconnect_3/S01_ARESETN] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins reset_buffer_ctrl/Q] [get_bd_pins role_core/axi_aresetn_role_ctrl] [get_bd_pins system_ila_0/resetn]
  connect_bd_net -net axi_aresetn_role_ctrl_2 [get_bd_pins axi_aresetn_role_ctrl] [get_bd_pins reset_buffer_ctrl/D]
  connect_bd_net -net axi_aresetn_role_data_1 [get_bd_pins axi_aresetn_role_data] [get_bd_pins reset_buffer_data/D]
  connect_bd_net -net reset_buffer_ctrl1_Q [get_bd_pins reset_buffer_data/Q] [get_bd_pins role_core/axi_aresetn_role_data]

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
  set M_AXI_FULL_ROLE_DATA_CDMA [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_FULL_ROLE_DATA_CDMA ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $M_AXI_FULL_ROLE_DATA_CDMA
  set M_USR_IRQ [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_qdma:usr_irq_rtl:1.0 M_USR_IRQ ]
  set S_AXI_LITE_ROLE_CTRL [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_ROLE_CTRL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
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
   ] $S_AXI_LITE_ROLE_CTRL
  set S_AXI_LITE_SHRL_CTRL [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_SHRL_CTRL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
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
   ] $S_AXI_LITE_SHRL_CTRL

  # Create ports
  set I_ROLE_RSTN [ create_bd_port -dir I -from 0 -to 0 I_ROLE_RSTN ]
  set axi_aclk_role_ctrl [ create_bd_port -dir I -type clk axi_aclk_role_ctrl ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXI_LITE_SHRL_CTRL:S_AXI_LITE_ROLE_CTRL} \
   CONFIG.ASSOCIATED_RESET {axi_aresetn_role_ctrl} \
   CONFIG.FREQ_HZ {250000000} \
 ] $axi_aclk_role_ctrl
  set axi_aclk_role_data [ create_bd_port -dir I -type clk axi_aclk_role_data ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M_AXI_FULL_ROLE_DATA_CDMA} \
   CONFIG.ASSOCIATED_RESET {axi_aresetn_role_data} \
   CONFIG.FREQ_HZ {250000000} \
 ] $axi_aclk_role_data
  set axi_aresetn_role_ctrl [ create_bd_port -dir I axi_aresetn_role_ctrl ]
  set axi_aresetn_role_data [ create_bd_port -dir I axi_aresetn_role_data ]

  # Create instance: role_top
  create_hier_cell_role_top [current_bd_instance .] role_top

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_ROLE_CTRL_1 [get_bd_intf_ports S_AXI_LITE_ROLE_CTRL] [get_bd_intf_pins role_top/S_AXI_LITE_ROLE_CTRL]
  connect_bd_intf_net -intf_net S_AXI_LITE_SHRL_CTRL_1 [get_bd_intf_ports S_AXI_LITE_SHRL_CTRL] [get_bd_intf_pins role_top/S_AXI_LITE_SHRL_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_ports M_AXI_FULL_ROLE_DATA_CDMA] [get_bd_intf_pins role_top/M_AXI_FULL_ROLE_DATA_CDMA]
  connect_bd_intf_net -intf_net role_top_M_USR_IRQ [get_bd_intf_ports M_USR_IRQ] [get_bd_intf_pins role_top/M_USR_IRQ]

  # Create port connections
  connect_bd_net -net I_ROLE_RSTN_1 [get_bd_ports I_ROLE_RSTN] [get_bd_pins role_top/I_ROLE_RSTN]
  connect_bd_net -net axi_aclk_role_ctrl_1 [get_bd_ports axi_aclk_role_ctrl] [get_bd_pins role_top/axi_aclk_role_ctrl]
  connect_bd_net -net axi_aclk_role_data_1 [get_bd_ports axi_aclk_role_data] [get_bd_pins role_top/axi_aclk_role_data]
  connect_bd_net -net axi_aresetn_role_ctrl_0_1 [get_bd_ports axi_aresetn_role_ctrl] [get_bd_pins role_top/axi_aresetn_role_ctrl]
  connect_bd_net -net axi_aresetn_role_data_0_1 [get_bd_ports axi_aresetn_role_data] [get_bd_pins role_top/axi_aresetn_role_data]

  # Create address segments
  create_bd_addr_seg -range 0x00001000 -offset 0x00010000 [get_bd_addr_spaces role_top/jtag_axi_0/Data] [get_bd_addr_segs role_top/axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00011000 [get_bd_addr_spaces role_top/jtag_axi_0/Data] [get_bd_addr_segs role_top/role_core/axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00012000 [get_bd_addr_spaces role_top/jtag_axi_0/Data] [get_bd_addr_segs role_top/role_core/axi_cdma_0/S_AXI_LITE/Reg] SEG_axi_cdma_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x00013000 [get_bd_addr_spaces role_top/jtag_axi_0/Data] [get_bd_addr_segs role_top/role_core/axi_cdma_1/S_AXI_LITE/Reg] SEG_axi_cdma_1_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces role_top/role_core/axi_cdma_0/Data] [get_bd_addr_segs M_AXI_FULL_ROLE_DATA_CDMA/Reg] SEG_M_AXI_FULL_ROLE_DATA_CDMA_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x000100000000 [get_bd_addr_spaces role_top/role_core/axi_cdma_0/Data] [get_bd_addr_segs role_top/role_core/axi_bram_ctrl_2/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces role_top/role_core/axi_cdma_1/Data] [get_bd_addr_segs M_AXI_FULL_ROLE_DATA_CDMA/Reg] SEG_M_AXI_FULL_ROLE_DATA_CDMA_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x000100000000 [get_bd_addr_spaces role_top/role_core/axi_cdma_1/Data] [get_bd_addr_segs role_top/role_core/axi_bram_ctrl_2/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00010000 [get_bd_addr_spaces S_AXI_LITE_ROLE_CTRL] [get_bd_addr_segs role_top/axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00010000 [get_bd_addr_spaces S_AXI_LITE_SHRL_CTRL] [get_bd_addr_segs role_top/axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00011000 [get_bd_addr_spaces S_AXI_LITE_ROLE_CTRL] [get_bd_addr_segs role_top/role_core/axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00012000 [get_bd_addr_spaces S_AXI_LITE_ROLE_CTRL] [get_bd_addr_segs role_top/role_core/axi_cdma_0/S_AXI_LITE/Reg] SEG_axi_cdma_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x00013000 [get_bd_addr_spaces S_AXI_LITE_ROLE_CTRL] [get_bd_addr_segs role_top/role_core/axi_cdma_1/S_AXI_LITE/Reg] SEG_axi_cdma_1_Reg


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


