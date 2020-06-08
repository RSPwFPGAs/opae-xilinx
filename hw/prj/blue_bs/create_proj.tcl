if ({[lindex $argv 3]}=="kcu105") {
  set_param board.repoPaths ../../src/boardrepo/kcu105/
  set devPart "xcku040-ffva1156-2-e"
  set brdPart "xilinx.com:kcu105:part0:1.5"
} 
if ({[lindex $argv 3]}=="u50dd") {
  set_param board.repoPaths ../../src/boardrepo/au50dd/
  set devPart "xcu50-fsvh2104-2L-e"
  set brdPart "xilinx.com:au50dd:part0:1.0"
}

# create project
create_project proj_opae_bbs ./proj_opae_bbs -part $devPart -f
set_property board_part $brdPart [current_project]

# add IP
set_property ip_repo_paths ../../src/ip/xapp1201/pcie2axilite_bridge/ [current_fileset]
update_ip_catalog

add_files {../../src/hdl/pf_csr/pf_csr_v1_0_S00_AXI.v ../../src/hdl/pf_csr/pf_csr_v1_0.v}
update_compile_order -fileset sources_1

source [lindex $argv 1]
set_property  ip_repo_paths $AFU_IP_PATH [current_project]
update_ip_catalog

if ({[lindex $argv 3]}=="kcu105") {
  # adding pblock constraints for shell 
  add_files -fileset constrs_1     ../../src/constraints/pr_shell.xdc 
  set_property target_constrs_file ../../src/constraints/pr_shell.xdc [current_fileset -constrset] 
   
  # adding pblock constraints for role 
  add_files -fileset constrs_1     ../../src/constraints/pr_role.xdc 
  set_property target_constrs_file ../../src/constraints/pr_role.xdc [current_fileset -constrset] 
   
  # adding top-level pin constraints
  add_files -fileset constrs_1 ../../src/constraints/top.xdc
}
if ({[lindex $argv 3]}=="u50dd") {
  # adding pblock constraints for shell 
  add_files -fileset constrs_1     ../../src/constraints/pr_shell.u50dd.xdc 
  set_property target_constrs_file ../../src/constraints/pr_shell.u50dd.xdc [current_fileset -constrset] 
   
  # adding pblock constraints for role 
  add_files -fileset constrs_1     ../../src/constraints/pr_role.u50dd.xdc 
  set_property target_constrs_file ../../src/constraints/pr_role.u50dd.xdc [current_fileset -constrset] 
   
  # adding top-level pin constraints
  add_files -fileset constrs_1 ../../src/constraints/top.u50dd.xdc
}

