
# run AFU base design file: .bd.tcl
source [lindex $argv 0]
set_property generate_synth_checkpoint true [get_files role_region_0.bd]
add_files -norecurse [make_wrapper   -files [get_files role_region_0.bd] -top]
set_property top role_region_0_wrapper [current_fileset]
update_compile_order -fileset sources_1

set_property synth_checkpoint_mode Singular [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/bd/role_region_0/role_region_0.bd]
generate_target all                         [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/bd/role_region_0/role_region_0.bd]
export_ip_user_files -of_objects            [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/bd/role_region_0/role_region_0.bd] -no_script -sync -force -quiet
create_ip_run                               [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/bd/role_region_0/role_region_0.bd]

launch_runs role_region_0_synth_1 -jobs 8
wait_on_run role_region_0_synth_1

exec cp ./proj_opae_gbs/proj_opae_gbs.runs/role_region_0_synth_1/role_region_0.dcp ./dcp/shell_role_010.dcp

