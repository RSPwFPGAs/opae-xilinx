#Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
	set Page0 [ ipgui::add_page $IPINST  -name "BAR Options" -layout vertical]
	set Component_Name [ ipgui::add_param  $IPINST  -parent  $Page0  -name Component_Name ]
	set tabgroup0 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 0} -layout vertical]
	set BAR0SIZE [ipgui::add_param $IPINST -parent $tabgroup0 -name BAR0SIZE]
	set BAR2AXI0_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup0 -name BAR2AXI0_TRANSLATION]
	set tabgroup1 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 1} -layout vertical]
	set BAR1SIZE [ipgui::add_param $IPINST -parent $tabgroup1 -name BAR1SIZE]
	set BAR2AXI1_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup1 -name BAR2AXI1_TRANSLATION]
	set tabgroup2 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 2} -layout vertical]
	set BAR2SIZE [ipgui::add_param $IPINST -parent $tabgroup2 -name BAR2SIZE]
	set BAR2AXI2_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup2 -name BAR2AXI2_TRANSLATION]
	set tabgroup3 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 3} -layout vertical]
	set BAR3SIZE [ipgui::add_param $IPINST -parent $tabgroup3 -name BAR3SIZE]
	set BAR2AXI3_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup3 -name BAR2AXI3_TRANSLATION]
	set tabgroup4 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 4} -layout vertical]
	set BAR4SIZE [ipgui::add_param $IPINST -parent $tabgroup4 -name BAR4SIZE]
	set BAR2AXI4_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup4 -name BAR2AXI4_TRANSLATION]
	set tabgroup5 [ipgui::add_group $IPINST -parent $Page0 -name {BAR 5} -layout vertical]
	set BAR5SIZE [ipgui::add_param $IPINST -parent $tabgroup5 -name BAR5SIZE]
	set BAR2AXI5_TRANSLATION [ipgui::add_param $IPINST -parent $tabgroup5 -name BAR2AXI5_TRANSLATION]
	set Page1 [ ipgui::add_page $IPINST  -name "Data Width Options" -layout vertical]
	set M_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -parent $Page1 -name M_AXI_ADDR_WIDTH ]
	set AXIS_TDATA_WIDTH [ipgui::add_param $IPINST -parent $Page1 -name AXIS_TDATA_WIDTH -widget comboBox]
	set Page2 [ ipgui::add_page $IPINST  -name "Misc" -layout vertical]
	set ENABLE_CONFIG [ipgui::add_param $IPINST -parent $Page2 -name ENABLE_CONFIG]
	set RELAXED_ORDERING [ipgui::add_param $IPINST -parent $Page2 -name RELAXED_ORDERING]
	set OUTSTANDING_READS [ipgui::add_param $IPINST -parent $Page2 -name OUTSTANDING_READS -widget comboBox]
}

proc update_PARAM_VALUE.BAR0SIZE { PARAM_VALUE.BAR0SIZE } {
	# Procedure called to update BAR0SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR0SIZE { PARAM_VALUE.BAR0SIZE } {
	# Procedure called to validate BAR0SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI0_TRANSLATION { PARAM_VALUE.BAR2AXI0_TRANSLATION } {
	# Procedure called to update BAR2AXI0_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI0_TRANSLATION { PARAM_VALUE.BAR2AXI0_TRANSLATION } {
	# Procedure called to validate BAR2AXI0_TRANSLATION
	return true
}

proc update_PARAM_VALUE.BAR1SIZE { PARAM_VALUE.BAR1SIZE } {
	# Procedure called to update BAR1SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR1SIZE { PARAM_VALUE.BAR1SIZE } {
	# Procedure called to validate BAR1SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI1_TRANSLATION { PARAM_VALUE.BAR2AXI1_TRANSLATION } {
	# Procedure called to update BAR2AXI1_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI1_TRANSLATION { PARAM_VALUE.BAR2AXI1_TRANSLATION } {
	# Procedure called to validate BAR2AXI1_TRANSLATION
	return true
}

proc update_PARAM_VALUE.BAR2SIZE { PARAM_VALUE.BAR2SIZE } {
	# Procedure called to update BAR2SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2SIZE { PARAM_VALUE.BAR2SIZE } {
	# Procedure called to validate BAR2SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI2_TRANSLATION { PARAM_VALUE.BAR2AXI2_TRANSLATION } {
	# Procedure called to update BAR2AXI2_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI2_TRANSLATION { PARAM_VALUE.BAR2AXI2_TRANSLATION } {
	# Procedure called to validate BAR2AXI2_TRANSLATION
	return true
}

proc update_PARAM_VALUE.BAR3SIZE { PARAM_VALUE.BAR3SIZE } {
	# Procedure called to update BAR3SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR3SIZE { PARAM_VALUE.BAR3SIZE } {
	# Procedure called to validate BAR3SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI3_TRANSLATION { PARAM_VALUE.BAR2AXI3_TRANSLATION } {
	# Procedure called to update BAR2AXI3_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI3_TRANSLATION { PARAM_VALUE.BAR2AXI3_TRANSLATION } {
	# Procedure called to validate BAR2AXI3_TRANSLATION
	return true
}

proc update_PARAM_VALUE.BAR4SIZE { PARAM_VALUE.BAR4SIZE } {
	# Procedure called to update BAR4SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR4SIZE { PARAM_VALUE.BAR4SIZE } {
	# Procedure called to validate BAR4SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI4_TRANSLATION { PARAM_VALUE.BAR2AXI4_TRANSLATION } {
	# Procedure called to update BAR2AXI4_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI4_TRANSLATION { PARAM_VALUE.BAR2AXI4_TRANSLATION } {
	# Procedure called to validate BAR2AXI4_TRANSLATION
	return true
}

proc update_PARAM_VALUE.BAR5SIZE { PARAM_VALUE.BAR5SIZE } {
	# Procedure called to update BAR5SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR5SIZE { PARAM_VALUE.BAR5SIZE } {
	# Procedure called to validate BAR5SIZE
	return true
}

proc update_PARAM_VALUE.BAR2AXI5_TRANSLATION { PARAM_VALUE.BAR2AXI5_TRANSLATION } {
	# Procedure called to update BAR2AXI5_TRANSLATION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAR2AXI5_TRANSLATION { PARAM_VALUE.BAR2AXI5_TRANSLATION } {
	# Procedure called to validate BAR2AXI5_TRANSLATION
	return true
}

proc update_PARAM_VALUE.M_AXI_ADDR_WIDTH { PARAM_VALUE.M_AXI_ADDR_WIDTH } {
	# Procedure called to update M_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.M_AXI_ADDR_WIDTH { PARAM_VALUE.M_AXI_ADDR_WIDTH } {
	# Procedure called to validate M_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_TDATA_WIDTH { PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to update AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_TDATA_WIDTH { PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to validate AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.ENABLE_CONFIG { PARAM_VALUE.ENABLE_CONFIG } {
	# Procedure called to update ENABLE_CONFIG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_CONFIG { PARAM_VALUE.ENABLE_CONFIG } {
	# Procedure called to validate ENABLE_CONFIG
	return true
}

proc update_PARAM_VALUE.RELAXED_ORDERING { PARAM_VALUE.RELAXED_ORDERING } {
	# Procedure called to update RELAXED_ORDERING when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RELAXED_ORDERING { PARAM_VALUE.RELAXED_ORDERING } {
	# Procedure called to validate RELAXED_ORDERING
	return true
}

proc update_PARAM_VALUE.OUTSTANDING_READS { PARAM_VALUE.OUTSTANDING_READS } {
	# Procedure called to update OUTSTANDING_READS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUTSTANDING_READS { PARAM_VALUE.OUTSTANDING_READS } {
	# Procedure called to validate OUTSTANDING_READS
	return true
}


proc update_MODELPARAM_VALUE.AXIS_TDATA_WIDTH { MODELPARAM_VALUE.AXIS_TDATA_WIDTH PARAM_VALUE.AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.M_AXI_ADDR_WIDTH { MODELPARAM_VALUE.M_AXI_ADDR_WIDTH PARAM_VALUE.M_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.M_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.M_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.RELAXED_ORDERING { MODELPARAM_VALUE.RELAXED_ORDERING PARAM_VALUE.RELAXED_ORDERING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RELAXED_ORDERING}] ${MODELPARAM_VALUE.RELAXED_ORDERING}
}

proc update_MODELPARAM_VALUE.ENABLE_CONFIG { MODELPARAM_VALUE.ENABLE_CONFIG PARAM_VALUE.ENABLE_CONFIG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_CONFIG}] ${MODELPARAM_VALUE.ENABLE_CONFIG}
}

proc update_MODELPARAM_VALUE.BAR2AXI0_TRANSLATION { MODELPARAM_VALUE.BAR2AXI0_TRANSLATION PARAM_VALUE.BAR2AXI0_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI0_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI0_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR2AXI1_TRANSLATION { MODELPARAM_VALUE.BAR2AXI1_TRANSLATION PARAM_VALUE.BAR2AXI1_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI1_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI1_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR2AXI2_TRANSLATION { MODELPARAM_VALUE.BAR2AXI2_TRANSLATION PARAM_VALUE.BAR2AXI2_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI2_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI2_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR2AXI3_TRANSLATION { MODELPARAM_VALUE.BAR2AXI3_TRANSLATION PARAM_VALUE.BAR2AXI3_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI3_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI3_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR2AXI4_TRANSLATION { MODELPARAM_VALUE.BAR2AXI4_TRANSLATION PARAM_VALUE.BAR2AXI4_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI4_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI4_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR2AXI5_TRANSLATION { MODELPARAM_VALUE.BAR2AXI5_TRANSLATION PARAM_VALUE.BAR2AXI5_TRANSLATION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2AXI5_TRANSLATION}] ${MODELPARAM_VALUE.BAR2AXI5_TRANSLATION}
}

proc update_MODELPARAM_VALUE.BAR0SIZE { MODELPARAM_VALUE.BAR0SIZE PARAM_VALUE.BAR0SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR0SIZE}] ${MODELPARAM_VALUE.BAR0SIZE}
}

proc update_MODELPARAM_VALUE.BAR1SIZE { MODELPARAM_VALUE.BAR1SIZE PARAM_VALUE.BAR1SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR1SIZE}] ${MODELPARAM_VALUE.BAR1SIZE}
}

proc update_MODELPARAM_VALUE.BAR2SIZE { MODELPARAM_VALUE.BAR2SIZE PARAM_VALUE.BAR2SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR2SIZE}] ${MODELPARAM_VALUE.BAR2SIZE}
}

proc update_MODELPARAM_VALUE.BAR3SIZE { MODELPARAM_VALUE.BAR3SIZE PARAM_VALUE.BAR3SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR3SIZE}] ${MODELPARAM_VALUE.BAR3SIZE}
}

proc update_MODELPARAM_VALUE.BAR4SIZE { MODELPARAM_VALUE.BAR4SIZE PARAM_VALUE.BAR4SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR4SIZE}] ${MODELPARAM_VALUE.BAR4SIZE}
}

proc update_MODELPARAM_VALUE.BAR5SIZE { MODELPARAM_VALUE.BAR5SIZE PARAM_VALUE.BAR5SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAR5SIZE}] ${MODELPARAM_VALUE.BAR5SIZE}
}

proc update_MODELPARAM_VALUE.OUTSTANDING_READS { MODELPARAM_VALUE.OUTSTANDING_READS PARAM_VALUE.OUTSTANDING_READS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUTSTANDING_READS}] ${MODELPARAM_VALUE.OUTSTANDING_READS}
}

