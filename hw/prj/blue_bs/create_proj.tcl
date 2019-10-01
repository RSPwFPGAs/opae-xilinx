create_project proj_opae_bbs ./proj_opae_bbs -part xcku040-ffva1156-2-e -f
set_property board_part xilinx.com:kcu105:part0:1.5 [current_project]

set_property ip_repo_paths ../../src/ip/xapp1201/pcie2axilite_bridge/ [current_fileset]
update_ip_catalog

add_files {../../src/hdl/pf_csr/pf_csr_v1_0_S00_AXI.v ../../src/hdl/pf_csr/pf_csr_v1_0.v}
update_compile_order -fileset sources_1

