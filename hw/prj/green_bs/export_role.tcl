

add_files {./dcp/role_region_0_wrapper.v}
source ../../src/ipi/afu_customer_1.bd.tcl

set_property top role_rm_0_bb [current_fileset]
update_compile_order -fileset sources_1
generate_target all [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/ipi/role_region_0/role_region_0.bd]
launch_runs synth_1 -jobs 4
wait_on_run synth_1
synth_design -part xcku040-ffva1156-2-e -top role_rm_0_bb -mode out_of_context
write_checkpoint -force ./dcp/shell_role_010.dcp

