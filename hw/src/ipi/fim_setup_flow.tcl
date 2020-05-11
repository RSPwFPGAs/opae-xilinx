# create shell bd
source [lindex $argv 0]

current_bd_design [get_bd_designs shell_region]

make_wrapper -files [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v

set_property top shell_region_wrapper [current_fileset]
update_compile_order -fileset sources_1


