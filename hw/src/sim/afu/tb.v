//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
//Date        : Mon Jun  1 17:06:26 2020
//Host        : user-HP-Z840-Workstation running 64-bit Ubuntu 18.04.4 LTS
//Command     : generate_target pfm_dynamic_wrapper.bd
//Design      : pfm_dynamic_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ns / 1 ns

`include "axi_vip_pcie_axilite_pt_stimulus.sv"
`include "axi_vip_pcie_axifull_pt_stimulus.sv"

module tb ();

reg sys_clk_ctrl_port;
reg sys_clk_data_port;
reg sys_resetn_ctrl_port;
reg sys_resetn_data_port;
role_region_0_sim DUT (
.axi_aclk_ctrl_port(sys_clk_ctrl_port),
.axi_aclk_data_port(sys_clk_data_port),
.axi_aresetn_ctrl_port(sys_resetn_ctrl_port),
.axi_aresetn_data_port(sys_resetn_data_port)
);

// instantiate vip master
axi_vip_pcie_axilite_pt_stimulus mst_pcie();
// instantiate vip slave
axi_vip_pcie_axifull_pt_stimulus slv_pcie();

reg start_test;

initial begin
        sys_clk_ctrl_port = 0;
        #(0);
        forever #(5) sys_clk_ctrl_port = ~sys_clk_ctrl_port;
end
initial begin
        sys_clk_data_port = 0;
        #(0);
        forever #(2) sys_clk_data_port = ~sys_clk_data_port;
end
initial begin
        $display("[%t] : System CTRL Reset Is Asserted...", $realtime);
        sys_resetn_ctrl_port = 1'b0;
        repeat (32) @(posedge sys_clk_ctrl_port);
        $display("[%t] : System CTRL Reset Is De-asserted...", $realtime);
        sys_resetn_ctrl_port = 1'b1;
end
initial begin
        $display("[%t] : System DATA Reset Is Asserted...", $realtime);
        sys_resetn_data_port = 1'b0;
        repeat (32) @(posedge sys_clk_data_port);
        $display("[%t] : System DATA Reset Is De-asserted...", $realtime);
        sys_resetn_data_port = 1'b1;
end


initial begin
 
    /////////////////////////////////////
    // wait for slowest reset
    start_test = 0;
    @(posedge sys_resetn_ctrl_port);
    @(posedge sys_clk_ctrl_port);
    start_test = 1;
 
end
        
endmodule
