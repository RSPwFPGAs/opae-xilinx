close_project -quiet
source create_proj.tcl

source ../../src/ipi/fim_setup_flow.tcl


launch_runs impl_1 -jobs 4
wait_on_run impl_1


open_run impl_1

#set_property INIT_00 256'h4631333331363930344430423837383533443633323536334245333444344344 [get_cells {shell_region_i/shell/shell_core/pf_ram/blk_mem_gen_0/U0/inst_blk_mem_gen/gnbram.gnative_mem_map_bmg.native_mem_map_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.WITH_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.SERIES8_TDP_SP36_NO_ECC_ATTR.ram}]

write_bitstream -force -no_partial_bitfile ./output/shell_region_wrapper.bit
write_debug_probes -force ./output/shell_region_wrapper.ltx


