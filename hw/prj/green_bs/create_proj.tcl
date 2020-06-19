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

# create project
create_project proj_opae_gbs ./proj_opae_gbs -part $devPart -f
set_property board_part $brdPart [current_project]

# add IP
source [lindex $argv 1]
set_property ip_repo_paths [lappend AFU_IP_PATH [get_property ip_repo_paths [current_fileset]]] [current_project]
update_ip_catalog

if ({[lindex $argv 2]}=="kcu105") {
  # adding pblock constraints for shell
  add_files -fileset constrs_1     ../../src/constraints/pr_shell.xdc
  set_property target_constrs_file ../../src/constraints/pr_shell.xdc [current_fileset -constrset]
  
  # adding pblock constraints for role
  add_files -fileset constrs_1     ../../src/constraints/pr_role.xdc
  set_property target_constrs_file ../../src/constraints/pr_role.xdc [current_fileset -constrset]
  
  # adding top-level pin constraints
  add_files -fileset constrs_1 ../../src/constraints/top.xdc
}
if ({[lindex $argv 2]}=="u50dd") {
   # adding pblock constraints for shell
  add_files -fileset constrs_1     ../../src/constraints/pr_shell.u50dd.xdc
  set_property target_constrs_file ../../src/constraints/pr_shell.u50dd.xdc [current_fileset -constrset]
  
  # adding pblock constraints for role
  add_files -fileset constrs_1     ../../src/constraints/pr_role.u50dd.xdc
  set_property target_constrs_file ../../src/constraints/pr_role.u50dd.xdc [current_fileset -constrset]
  
  # adding top-level pin constraints
  add_files -fileset constrs_1 ../../src/constraints/top.u50dd.xdc
}

