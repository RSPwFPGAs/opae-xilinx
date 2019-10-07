
open_checkpoint ./dcp/shell_role_100.dcp 

read_checkpoint -cell shell_region_i/AFU ./dcp/shell_role_010.dcp
set_property HD.RECONFIGURABLE 1 [get_cells shell_region_i/AFU]

opt_design
place_design
route_design



