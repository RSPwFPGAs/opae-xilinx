

add_files {./dcp/role_region_0_wrapper.v}
# run AFU base design file: .bd.tcl
source [lindex $argv 0]
set_property top role_rm_0_bb [current_fileset]
update_compile_order -fileset sources_1

generate_target all [get_files ./proj_opae_gbs/proj_opae_gbs.srcs/sources_1/bd/role_region_0/role_region_0.bd]
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if ({[lindex $argv 2]}=="kcu105") {
  set devPart "xcku040-ffva1156-2-e"
  set brdPart "xilinx.com:kcu105:part0:1.5"
} 
if ({[lindex $argv 2]}=="u50dd") {
  set_param board.repoPaths ../../src/boardrepo/au50dd/
  set devPart "xcu50-fsvh2104-2L-e"
  set brdPart "xilinx.com:au50dd:part0:1.0"
}
synth_design -part $devPart -top role_rm_0_bb -mode out_of_context
write_checkpoint -force ./dcp/shell_role_010.dcp

