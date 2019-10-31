close_project -quiet
source create_proj.tcl

source ../../src/ipi/fim_setup_flow.tcl


make_bd_intf_pins_external  [get_bd_intf_pins FIM/FIU/pcie_axi_bridge/pcie3_ultrascale_0/pcie3_ext_pipe_ep]

make_wrapper -files [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -top
add_files -norecurse           ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/hdl/shell_region_wrapper.v

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {\
../../src/sim/pcie_rp_vip_pipe/src/tests.vh \
../../src/sim/pcie_rp_vip_pipe/src/sample_tests.vh \
../../src/sim/pcie_rp_vip_pipe/src/board_common.vh \
../../src/sim/pcie_rp_vip_pipe/src/pci_exp_expect_tasks.vh}
add_files -fileset sim_1 -norecurse {\
 ../../src/sim/pcie_rp_vip_pipe/src/sys_clk_gen.v \
 ../../src/sim/pcie_rp_vip_pipe/src/axi_pcie3_0_pcie3_7vx_rp_model.v \
 ../../src/sim/pcie_rp_vip_pipe/src/xilinx_pcie_3_0_7vx_rp.v \
 ../../src/sim/pcie_rp_vip_pipe/src/pci_exp_usrapp_com.v \
 ../../src/sim/pcie_rp_vip_pipe/src/pci_exp_usrapp_cfg.v \
 ../../src/sim/pcie_rp_vip_pipe/src/pci_exp_usrapp_tx.v  \
 ../../src/sim/pcie_rp_vip_pipe/src/pci_exp_usrapp_rx.v \
 ../../src/sim/pcie_rp_vip_pipe/src/board.v}
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]


generate_target Simulation [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd]
export_ip_user_files -of_objects [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files ./proj_opae_fim/proj_opae_fim.srcs/sources_1/bd/shell_region/shell_region.bd] -directory ./proj_opae_fim/proj_opae_fim.ip_user_files/sim_scripts -ip_user_files_dir ./proj_opae_fim/proj_opae_fim.ip_user_files -ipstatic_source_dir ./proj_opae_fim/proj_opae_fim.ip_user_files/ipstatic -lib_map_path [list {modelsim=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/modelsim} {questa=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/questa} {ies=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/ies} {xcelium=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/xcelium} {vcs=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/vcs} {riviera=./proj_opae_fim/proj_opae_fim.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet


launch_simulation
restart
restart

open_wave_config {../../src/sim/board_behav.wcfg}


open_vcd
log_vcd -quiet [get_object -r /board/EP/shell_region_i/shell/shell_core/pcie_2_axilite_0/*]
log_vcd -quiet [get_object -r /board/RP/tx_usrapp/*]
log_vcd -quiet [get_object -r /board/RP/pcie3_uscale_rp_top_i/*]
#log_vcd -quiet [get_object /board/EP/*]
#log_vcd -quiet [get_object /board/RP/*]


run 1 ms
close_vcd

