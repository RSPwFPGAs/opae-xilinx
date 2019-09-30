close_project -quiet
source create_proj.tcl

source ../../src/ipi/afu_setup_flow.tcl

launch_runs synth_1 -jobs 1
wait_on_run synth_1

