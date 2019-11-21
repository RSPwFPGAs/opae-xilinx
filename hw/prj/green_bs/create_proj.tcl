create_project proj_opae_gbs ./proj_opae_gbs -part xcku040-ffva1156-2-e -f
set_property board_part xilinx.com:kcu105:part0:1.5 [current_project]

source [lindex $argv 1]
set_property  ip_repo_paths $AFU_IP_PATH [current_project]
update_ip_catalog

