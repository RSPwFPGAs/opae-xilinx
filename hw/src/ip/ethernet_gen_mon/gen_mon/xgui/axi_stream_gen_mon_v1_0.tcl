# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  #Adding Page
  set Page_0  [  ipgui::add_page $IPINST -name "Page 0" -display_name {Page 0}]
  set_property tooltip {Page 0} ${Page_0}
  set Component_Name  [  ipgui::add_param $IPINST -name "Component_Name" -parent ${Page_0} -display_name {Component Name}]
  set_property tooltip {Component Name} ${Component_Name}
  #Adding Group
  set AXI_Stream_Parameters  [  ipgui::add_group $IPINST -name "AXI Stream Parameters" -parent ${Page_0} -display_name {AXI Stream Parameters}]
  set_property tooltip {AXI Stream Parameters} ${AXI_Stream_Parameters}
  set AXIS_TDATA_WIDTH  [  ipgui::add_param $IPINST -name "AXIS_TDATA_WIDTH" -parent ${AXI_Stream_Parameters} -display_name {AXIS_TDATA_WIDTH}]
  set_property tooltip {Axis Tdata Width} ${AXIS_TDATA_WIDTH}

  #Adding Group
  set AXI_Lite_Parameters  [  ipgui::add_group $IPINST -name "AXI Lite Parameters" -parent ${Page_0} -display_name {AXI Lite Parameters}]
  set_property tooltip {AXI Lite Parameters} ${AXI_Lite_Parameters}
  set S_AXI_DATA_WIDTH  [  ipgui::add_param $IPINST -name "S_AXI_DATA_WIDTH" -parent ${AXI_Lite_Parameters} -display_name {S_AXI_DATA_WIDTH}]
  set_property tooltip {S Axi Data Width} ${S_AXI_DATA_WIDTH}
  set S_AXI_ADDR_WIDTH  [  ipgui::add_param $IPINST -name "S_AXI_ADDR_WIDTH" -parent ${AXI_Lite_Parameters} -display_name {S_AXI_ADDR_WIDTH}]
  set_property tooltip {S Axi Addr Width} ${S_AXI_ADDR_WIDTH}
  set S_AXI_BASE_ADDRESS  [  ipgui::add_param $IPINST -name "S_AXI_BASE_ADDRESS" -parent ${AXI_Lite_Parameters} -display_name {S_AXI_BASE_ADDRESS}]
  set_property tooltip {S Axi Base Address} ${S_AXI_BASE_ADDRESS}
  set S_AXI_MIN_SIZE  [  ipgui::add_param $IPINST -name "S_AXI_MIN_SIZE" -parent ${AXI_Lite_Parameters} -display_name {S_AXI_MIN_SIZE}]
  set_property tooltip {S Axi Min Size} ${S_AXI_MIN_SIZE}

  #Adding Group
  set MAC_IDs  [  ipgui::add_group $IPINST -name "MAC IDs" -parent ${Page_0} -display_name {MAC IDs}]
  set_property tooltip {MAC IDs} ${MAC_IDs}
  set XIL_MAC_ID_THIS  [  ipgui::add_param $IPINST -name "XIL_MAC_ID_THIS" -parent ${MAC_IDs} -display_name {XIL_MAC_ID_THIS}]
  set_property tooltip {Xil Mac Id This} ${XIL_MAC_ID_THIS}
  set XIL_MAC_ID_OTHER  [  ipgui::add_param $IPINST -name "XIL_MAC_ID_OTHER" -parent ${MAC_IDs} -display_name {XIL_MAC_ID_OTHER}]
  set_property tooltip {Xil Mac Id Other} ${XIL_MAC_ID_OTHER}
  set EXT_MAC_ID  [  ipgui::add_param $IPINST -name "EXT_MAC_ID" -parent ${MAC_IDs} -display_name {EXT_MAC_ID}]
  set_property tooltip {Ext Mac Id} ${EXT_MAC_ID}

  #Adding Group
  set Sample_Interval  [  ipgui::add_group $IPINST -name "Sample Interval" -parent ${Page_0} -display_name {Sample Interval}]
  set_property tooltip {Sample Interval} ${Sample_Interval}
  set ONE_SEC_CLOCK_COUNT  [  ipgui::add_param $IPINST -name "ONE_SEC_CLOCK_COUNT" -parent ${Sample_Interval} -display_name {ONE_SEC_CLOCK_COUNT}]
  set_property tooltip {One Sec Clock Count in terms of 156.25 MHz clock} ${ONE_SEC_CLOCK_COUNT}

  #Adding Group
  set Target_Board,_Target_Vivado_version,_Target_Design  [  ipgui::add_group $IPINST -name "Target Board, Target Vivado version, Target Design" -parent ${Page_0} -display_name {Target Board, Target Vivado version, Target Design}]
  set_property tooltip {Target Board, Target Vivado version, Target Design} ${Target_Board,_Target_Vivado_version,_Target_Design}
  set DESIGN_VERSION  [  ipgui::add_param $IPINST -name "DESIGN_VERSION" -parent ${Target_Board,_Target_Vivado_version,_Target_Design} -display_name {DESIGN_VERSION}]
  set_property tooltip {Design Version} ${DESIGN_VERSION}



}

proc update_PARAM_VALUE.ONE_SEC_CLOCK_COUNT { PARAM_VALUE.ONE_SEC_CLOCK_COUNT } {
	# Procedure called to update ONE_SEC_CLOCK_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ONE_SEC_CLOCK_COUNT { PARAM_VALUE.ONE_SEC_CLOCK_COUNT } {
	# Procedure called to validate ONE_SEC_CLOCK_COUNT
	return true
}

proc update_PARAM_VALUE.DESIGN_VERSION { PARAM_VALUE.DESIGN_VERSION } {
	# Procedure called to update DESIGN_VERSION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DESIGN_VERSION { PARAM_VALUE.DESIGN_VERSION } {
	# Procedure called to validate DESIGN_VERSION
	return true
}

proc update_PARAM_VALUE.S_AXI_BASE_ADDRESS { PARAM_VALUE.S_AXI_BASE_ADDRESS } {
	# Procedure called to update S_AXI_BASE_ADDRESS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.S_AXI_BASE_ADDRESS { PARAM_VALUE.S_AXI_BASE_ADDRESS } {
	# Procedure called to validate S_AXI_BASE_ADDRESS
	return true
}

proc update_PARAM_VALUE.S_AXI_MIN_SIZE { PARAM_VALUE.S_AXI_MIN_SIZE } {
	# Procedure called to update S_AXI_MIN_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.S_AXI_MIN_SIZE { PARAM_VALUE.S_AXI_MIN_SIZE } {
	# Procedure called to validate S_AXI_MIN_SIZE
	return true
}

proc update_PARAM_VALUE.S_AXI_DATA_WIDTH { PARAM_VALUE.S_AXI_DATA_WIDTH } {
	# Procedure called to update S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.S_AXI_DATA_WIDTH { PARAM_VALUE.S_AXI_DATA_WIDTH } {
	# Procedure called to validate S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.S_AXI_ADDR_WIDTH { PARAM_VALUE.S_AXI_ADDR_WIDTH } {
	# Procedure called to update S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.S_AXI_ADDR_WIDTH { PARAM_VALUE.S_AXI_ADDR_WIDTH } {
	# Procedure called to validate S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.EXT_MAC_ID { PARAM_VALUE.EXT_MAC_ID } {
	# Procedure called to update EXT_MAC_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EXT_MAC_ID { PARAM_VALUE.EXT_MAC_ID } {
	# Procedure called to validate EXT_MAC_ID
	return true
}

proc update_PARAM_VALUE.XIL_MAC_ID_OTHER { PARAM_VALUE.XIL_MAC_ID_OTHER } {
	# Procedure called to update XIL_MAC_ID_OTHER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.XIL_MAC_ID_OTHER { PARAM_VALUE.XIL_MAC_ID_OTHER } {
	# Procedure called to validate XIL_MAC_ID_OTHER
	return true
}

proc update_PARAM_VALUE.XIL_MAC_ID_THIS { PARAM_VALUE.XIL_MAC_ID_THIS } {
	# Procedure called to update XIL_MAC_ID_THIS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.XIL_MAC_ID_THIS { PARAM_VALUE.XIL_MAC_ID_THIS } {
	# Procedure called to validate XIL_MAC_ID_THIS
	return true
}

proc update_PARAM_VALUE.AXIS_TDATA_WIDTH { PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to update AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_TDATA_WIDTH { PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to validate AXIS_TDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.AXIS_TDATA_WIDTH { MODELPARAM_VALUE.AXIS_TDATA_WIDTH PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.XIL_MAC_ID_THIS { MODELPARAM_VALUE.XIL_MAC_ID_THIS PARAM_VALUE.XIL_MAC_ID_THIS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.XIL_MAC_ID_THIS}] ${MODELPARAM_VALUE.XIL_MAC_ID_THIS}
}

proc update_MODELPARAM_VALUE.XIL_MAC_ID_OTHER { MODELPARAM_VALUE.XIL_MAC_ID_OTHER PARAM_VALUE.XIL_MAC_ID_OTHER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.XIL_MAC_ID_OTHER}] ${MODELPARAM_VALUE.XIL_MAC_ID_OTHER}
}

proc update_MODELPARAM_VALUE.EXT_MAC_ID { MODELPARAM_VALUE.EXT_MAC_ID PARAM_VALUE.EXT_MAC_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EXT_MAC_ID}] ${MODELPARAM_VALUE.EXT_MAC_ID}
}

proc update_MODELPARAM_VALUE.S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.S_AXI_ADDR_WIDTH PARAM_VALUE.S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.S_AXI_DATA_WIDTH { MODELPARAM_VALUE.S_AXI_DATA_WIDTH PARAM_VALUE.S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.S_AXI_MIN_SIZE { MODELPARAM_VALUE.S_AXI_MIN_SIZE PARAM_VALUE.S_AXI_MIN_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_AXI_MIN_SIZE}] ${MODELPARAM_VALUE.S_AXI_MIN_SIZE}
}

proc update_MODELPARAM_VALUE.S_AXI_BASE_ADDRESS { MODELPARAM_VALUE.S_AXI_BASE_ADDRESS PARAM_VALUE.S_AXI_BASE_ADDRESS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_AXI_BASE_ADDRESS}] ${MODELPARAM_VALUE.S_AXI_BASE_ADDRESS}
}

proc update_MODELPARAM_VALUE.DESIGN_VERSION { MODELPARAM_VALUE.DESIGN_VERSION PARAM_VALUE.DESIGN_VERSION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DESIGN_VERSION}] ${MODELPARAM_VALUE.DESIGN_VERSION}
}

proc update_MODELPARAM_VALUE.ONE_SEC_CLOCK_COUNT { MODELPARAM_VALUE.ONE_SEC_CLOCK_COUNT PARAM_VALUE.ONE_SEC_CLOCK_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ONE_SEC_CLOCK_COUNT}] ${MODELPARAM_VALUE.ONE_SEC_CLOCK_COUNT}
}

