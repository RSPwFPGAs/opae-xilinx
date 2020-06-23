
current_project project_shell_role_100

#set_property INIT_00 256'h4631333331363930344430423837383533443633323536334245333444344344 [get_cells {shell_region_i/shell/shell_core/pf_ram/blk_mem_gen_0/U0/inst_blk_mem_gen/gnbram.gnative_mem_map_bmg.native_mem_map_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.WITH_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.SERIES8_TDP_SP36_NO_ECC_ATTR.ram}]
#set_property INIT_00 256'h00000000000000000000000000000000000000000000000000000001458B0001 [get_cells {shell_region_i/role_inst_0/role_region_0_i/role_top/axi_bram_ctrl_0_bram/U0/inst_blk_mem_gen/gnbram.gnative_mem_map_bmg.native_mem_map_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.WITH_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.SERIES8_TDP_SP36_NO_ECC_ATTR.ram}]

write_bitstream -force -no_partial_bitfile ./output/shell_region_wrapper.bit
write_bitstream -force -bin_file -cell shell_region_i/AFU ./output/shell_region_i_role_0_role_region_partial
write_debug_probes -force ./output/shell_region_wrapper.ltx

