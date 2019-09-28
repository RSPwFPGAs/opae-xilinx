# creat project
source creat_project.tcl

# add files
add_files -norecurse ../pf_demux.v
update_compile_order -fileset sources_1

# creat block design
source pf_demux_bd.tcl
make_wrapper -files [get_files ../pf_demux_sim/pf_demux_sim.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ../pf_demux_sim/pf_demux_sim.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
update_compile_order -fileset sources_1

# run simulation
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse sim_src/tb_design_1_wrapper.sv
update_compile_order -fileset sim_1
update_compile_order -fileset sim_1
generate_target Simulation [get_files ../pf_demux_sim/pf_demux_sim.srcs/sources_1/bd/design_1/design_1.bd]
export_ip_user_files -of_objects [get_files ../pf_demux_sim/pf_demux_sim.srcs/sources_1/bd/design_1/design_1.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files ../pf_demux_sim/pf_demux_sim.srcs/sources_1/bd/design_1/design_1.bd] -directory ../pf_demux_sim/pf_demux_sim.ip_user_files/sim_scripts -ip_user_files_dir ../pf_demux_sim/pf_demux_sim.ip_user_files -ipstatic_source_dir ../pf_demux_sim/pf_demux_sim.ip_user_files/ipstatic -lib_map_path [list {modelsim=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/modelsim} {questa=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/questa} {ies=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/ies} {xcelium=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/xcelium} {vcs=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/vcs} {riviera=../pf_demux_sim/pf_demux_sim.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
launch_simulation
#source tb_design_1_wrapper.tcl
open_wave_config {sim_src/tb_design_1_wrapper_behav.wcfg}
restart
run all


