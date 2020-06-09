
create_pblock pblock_shell
add_cells_to_pblock [get_pblocks pblock_shell] [get_cells -quiet [list shell_region_i/shell]]
resize_pblock [get_pblocks pblock_shell] -add {CLOCKREGION_X3Y0:CLOCKREGION_X3Y2}
#resize_pblock [get_pblocks pblock_shell] -add {CLOCKREGION_X2Y0:CLOCKREGION_X2Y0}
resize_pblock [get_pblocks pblock_shell] -add {IOB_X1Y103:IOB_X1Y103}
#resize_pblock [get_pblocks pblock_shell] -add {SYSMONE1_X0Y0:SYSMONE1_X0Y0}

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
