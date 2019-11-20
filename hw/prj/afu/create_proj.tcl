create_project proj_opae_afu ./proj_opae_afu -part xcku040-ffva1156-2-e -f
set_property board_part xilinx.com:kcu105:part0:1.5 [current_project]

set_property  ip_repo_paths [lindex $argv 1] [current_project]
update_ip_catalog

