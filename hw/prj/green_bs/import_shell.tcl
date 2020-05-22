
open_checkpoint ./dcp/shell_role_100.dcp 

read_checkpoint -cell shell_region_i/AFU ./dcp/shell_role_010.dcp
delete_pblock [get_pblocks shell_region_i_AFU_pblock_shell]
delete_pblock [get_pblocks shell_region_i_AFU_pblock_role_0]
set_property HD.RECONFIGURABLE 1 [get_cells shell_region_i/AFU]

opt_design
place_design
route_design



