if ({[lindex $argv 2]}=="kcu105") {
  set_param board.repoPaths ../../src/boardrepo/kcu105/
  set devPart "xcku040-ffva1156-2-e"
  set brdPart "xilinx.com:kcu105:part0:1.5"
} 
if ({[lindex $argv 2]}=="u50dd") {
  set_param board.repoPaths ../../src/boardrepo/au50dd/
  set devPart "xcu50-fsvh2104-2L-e"
  set brdPart "xilinx.com:au50dd:part0:1.0"
}

create_project proj_opae_afu ./proj_opae_afu -part $devPart -f
set_property board_part $brdPart [current_project]

source [lindex $argv 1]
set_property ip_repo_paths [lappend AFU_IP_PATH [get_property ip_repo_paths [current_fileset]]] [current_project]
update_ip_catalog

