
source create_proj.tcl

source ../../src/ipi/pr_setup_flow.tcl


launch_runs role_rm_0_synth_1 -jobs 4
wait_on_run role_rm_0_synth_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1


create_pr_configuration -name config_1 -partitions [list shell_region_i/AFU:role_rm_0 ]
set_property PR_CONFIGURATION config_1 [get_runs impl_1]


launch_runs impl_1 -jobs 4
wait_on_run impl_1


open_run impl_1

#set_property INIT_00 256'h4631333331363930344430423837383533443633323536334245333444344344 [get_cells {shell_region_i/shell/shell_core/pf_ram/blk_mem_gen_0/U0/inst_blk_mem_gen/gnbram.gnative_mem_map_bmg.native_mem_map_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.WITH_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.SERIES8_TDP_SP36_NO_ECC_ATTR.ram}]
#set_property INIT_00 256'h00000000000000000000000000000000000000000000000000000001458B0001 [get_cells {shell_region_i/role_inst_0/axi_bram_ctrl_0_bram/U0/inst_blk_mem_gen/gnbram.gnative_mem_map_bmg.native_mem_map_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.WITH_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.SERIES8_TDP_SP36_NO_ECC_ATTR.ram}]

write_bitstream -force -no_partial_bitfile ./output/shell_region_wrapper.bit
write_bitstream -force -cell shell_region_i/AFU ./output/shell_region_i_role_0_role_region_partial.bit
write_debug_probes -force ./output/shell_region_wrapper.ltx


update_design -cell [list shell_region_i/AFU ] -black_box
lock_design -level routing
write_checkpoint -force ./export/shell_role_100.dcp


#exec cp ./proj_shell_role/proj_shell_role.srcs/sources_1/bd/role_rm_0/hdl/role_rm_0_wrapper.v ./export/.
#exec sed -i "s/role_rm_0_wrapper/role_rm_0_bb/g" ./export/role_rm_0_wrapper.v

