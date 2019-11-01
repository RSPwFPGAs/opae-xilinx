# create role bd
source [lindex $argv 0]

current_bd_design [get_bd_designs role_region_0]

make_wrapper -files [get_files ./proj_opae_afu/proj_opae_afu.srcs/sources_1/bd/role_region_0/role_region_0.bd] -top
add_files -norecurse ./proj_opae_afu/proj_opae_afu.srcs/sources_1/bd/role_region_0/hdl/role_region_0_wrapper.v

set_property top role_region_0_wrapper [current_fileset]
update_compile_order -fileset sources_1


