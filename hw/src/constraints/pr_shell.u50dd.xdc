
create_pblock pblock_shell
add_cells_to_pblock [get_pblocks pblock_shell] [get_cells -quiet [list shell_region_i/FIM]]
resize_pblock [get_pblocks pblock_shell] -add {CLOCKREGION_X7Y1:CLOCKREGION_X7Y3}
resize_pblock [get_pblocks pblock_shell] -add {CLOCKREGION_X0Y0:CLOCKREGION_X7Y0}
resize_pblock [get_pblocks pblock_shell] -add {IOB_X0Y208:IOB_X0Y259}
resize_pblock [get_pblocks pblock_shell] -add {IOB_X0Y52:IOB_X0Y103}



set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
