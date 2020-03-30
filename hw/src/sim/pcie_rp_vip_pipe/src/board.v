//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : AXI-MM to PCI Express
// File       : board.v
// Version    : $IpVersion 
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
`timescale 1ns/1ns

`include "board_common.vh"

`define SIMULATION

module board;

  parameter REF_CLK_FREQ        = 0;
  localparam REF_CLK_HALF_CYCLE    = (REF_CLK_FREQ == 0) ? 5000 :
                                     (REF_CLK_FREQ == 1) ? 4000 :
                                     (REF_CLK_FREQ == 2) ? 2000 : 0;
  localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;

  localparam   [4:0]  LINK_WIDTH = 5'd8;
  localparam   [2:0]  LINK_SPEED = 3'h4;
  localparam   [15:0] EP_DEV_ID  = 16'h09c4;//16'h8038;

  localparam integer USER_CLK_RP_FREQ  = ((LINK_SPEED == 3'h4) ? 5 : 4);
  localparam integer USER_CLK_EP_FREQ  = 5;
  localparam integer USER_CLK2_FREQ = 3 + 1;
  // USER_CLK2_FREQ = AXI Interface Frequency
  //   0: Disable User Clock
  //   1: 31.25 MHz
  //   2: 62.50 MHz  (default)
  //   3: 125.00 MHz
  //   4: 250.00 MHz
  //   5: 500.00 MHz
  //
localparam EXT_PIPE_SIM = "TRUE";
  defparam board.EP.shell_region_i.FIM.FIU.pcie_axi_bridge.`PCIE_INST.inst.EXT_PIPE_SIM = EXT_PIPE_SIM;
  defparam board.EP.shell_region_i.FIM.FIU.pcie_axi_bridge.`PCIE_INST.inst.PL_EQ_BYPASS_PHASE23 = "TRUE";


  // System-level clock and reset
  wire               sys_clk;
  reg                sys_rst_n;
  // Xilinx Pipe Interface
  wire  [25:0]  common_commands_out;
  wire  [83:0]  xil_tx0_sigs_ep;
  wire  [83:0]  xil_tx1_sigs_ep;
  wire  [83:0]  xil_tx2_sigs_ep;
  wire  [83:0]  xil_tx3_sigs_ep;
  wire  [83:0]  xil_tx4_sigs_ep;
  wire  [83:0]  xil_tx5_sigs_ep;
  wire  [83:0]  xil_tx6_sigs_ep;
  wire  [83:0]  xil_tx7_sigs_ep;

  wire  [83:0]  xil_rx0_sigs_ep;
  wire  [83:0]  xil_rx1_sigs_ep;
  wire  [83:0]  xil_rx2_sigs_ep;
  wire  [83:0]  xil_rx3_sigs_ep;
  wire  [83:0]  xil_rx4_sigs_ep;
  wire  [83:0]  xil_rx5_sigs_ep;
  wire  [83:0]  xil_rx6_sigs_ep;
  wire  [83:0]  xil_rx7_sigs_ep;

  wire  [83:0]  xil_tx0_sigs_rp;
  wire  [83:0]  xil_tx1_sigs_rp;
  wire  [83:0]  xil_tx2_sigs_rp;
  wire  [83:0]  xil_tx3_sigs_rp;
  wire  [83:0]  xil_tx4_sigs_rp;
  wire  [83:0]  xil_tx5_sigs_rp;
  wire  [83:0]  xil_tx6_sigs_rp;
  wire  [83:0]  xil_tx7_sigs_rp;

  

  wire led_0;
  wire led_1;
  wire led_2;
  wire led_3;
  //------------------------------------------------------------------------------//
  // Generate system clock
  //------------------------------------------------------------------------------// 
  sys_clk_gen #(
    .halfcycle (REF_CLK_HALF_CYCLE),
    .offset    (0)
  ) CLK_GEN (
    .sys_clk (sys_clk)
  );

 //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  initial begin
    $display("[%t] : System Reset Is Asserted...", $realtime);
    sys_rst_n = 1'b0;
    repeat (500) @(posedge sys_clk);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    sys_rst_n = 1'b1;
  end
  
  //------------------------------------------------------------------------------//
  // EndPoint CSL Instance
  //------------------------------------------------------------------------------//
//      xilinx_axi_pcie3_ep
//	#(
//   .EXT_PIPE_SIM       (EXT_PIPE_SIM),
//   .REF_CLK_FREQ       (REF_CLK_FREQ)
//	)
//       AXI_PCIE3_EP (
//        // PCI-Express Interface
//        .sys_rst_n          (sys_rst_n),
//        .sys_clk_p          (sys_clk),
//        .sys_clk_n          (~sys_clk),    
//        // Misc signals
//        .led_0(led_0),
//        .led_1(led_1),
//        .led_2(led_2),
//        .led_3(led_3),


//        .common_commands_in (26'b0 ),
//        .pipe_rx_0_sigs     (xil_rx0_sigs_ep),
//        .pipe_rx_1_sigs     (xil_rx1_sigs_ep),
//        .pipe_rx_2_sigs     (xil_rx2_sigs_ep),
//        .pipe_rx_3_sigs     (xil_rx3_sigs_ep),
//        .pipe_rx_4_sigs     (xil_rx4_sigs_ep),
//        .pipe_rx_5_sigs     (xil_rx5_sigs_ep),
//        .pipe_rx_6_sigs     (xil_rx6_sigs_ep),
//        .pipe_rx_7_sigs     (xil_rx7_sigs_ep),
//        .common_commands_out(common_commands_out),  //[0] - pipe_clk out
//        .pipe_tx_0_sigs     (xil_tx0_sigs_ep),
//        .pipe_tx_1_sigs     (xil_tx1_sigs_ep),
//        .pipe_tx_2_sigs     (xil_tx2_sigs_ep),
//        .pipe_tx_3_sigs     (xil_tx3_sigs_ep),
//        .pipe_tx_4_sigs     (xil_tx4_sigs_ep),
//        .pipe_tx_5_sigs     (xil_tx5_sigs_ep),
//        .pipe_tx_6_sigs     (xil_tx6_sigs_ep),
//        .pipe_tx_7_sigs     (xil_tx7_sigs_ep),

//        // Tie-offs
//        .pci_exp_rxp        ('b0),
//        .pci_exp_rxn        ('b0));
    shell_region_wrapper
       EP (
        // PCI-Express Interface
    .pci_express_rxn('b0),
    .pci_express_rxp('b0),
    .pci_express_txn(),
    .pci_express_txp(),
    
    .pcie3_ext_pipe_ep_0_commands_out (26'b0 )         ,
    .pcie3_ext_pipe_ep_0_tx_0         (xil_rx0_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_1         (xil_rx1_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_2         (xil_rx2_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_3         (xil_rx3_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_4         (xil_rx4_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_5         (xil_rx5_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_6         (xil_rx6_sigs_ep),
    .pcie3_ext_pipe_ep_0_tx_7         (xil_rx7_sigs_ep),
    .pcie3_ext_pipe_ep_0_commands_in  (common_commands_out),
    .pcie3_ext_pipe_ep_0_rx_0         (xil_tx0_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_1         (xil_tx1_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_2         (xil_tx2_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_3         (xil_tx3_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_4         (xil_tx4_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_5         (xil_tx5_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_6         (xil_tx6_sigs_ep),    
    .pcie3_ext_pipe_ep_0_rx_7         (xil_tx7_sigs_ep),    
    .pcie_perstn       (sys_rst_n),
    .pcie_refclk_clk_n (~sys_clk),  
    .pcie_refclk_clk_p (sys_clk)
    );
        

//------------------------------------------------------------------------------//
  initial begin
    #2500000;  // 2.5ms timeout
    $display("[%t] : Simulation timeout. TEST FAILED", $realtime);
    #100;
    $finish;
  end
  //------------------------------------------------------------------------------//

  //------------------------------------------------------------------------------//
  // PCI-Express Root Port FPGA Instantiation
  //(comment out the Simulation Root Port Model to interface with BFM)
  //------------------------------------------------------------------------------//
  xilinx_pcie_3_0_7vx_rp
  #(
     .PL_LINK_CAP_MAX_LINK_WIDTH(LINK_WIDTH),
     .PL_LINK_CAP_MAX_LINK_SPEED(LINK_SPEED),
     .EP_DEV_ID                 (EP_DEV_ID),
     .USER_CLK2_FREQ            (USER_CLK2_FREQ),
     .PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE),
     .PIPE_SIM_MODE             (EXT_PIPE_SIM),
     .EXT_PIPE_SIM              (EXT_PIPE_SIM),
     .REF_CLK_FREQ              (REF_CLK_FREQ)
  ) RP (
    // SYS Inteface
    .sys_clk_n(~sys_clk),
    .sys_clk_p(sys_clk),
    .sys_rst_n                  ( sys_rst_n ),
    .common_commands_in ({25'b0,common_commands_out[0]} ), // pipe_clk from EP
    .pipe_rx_0_sigs     ({45'b0,xil_tx0_sigs_ep[38:0]}),
    .pipe_rx_1_sigs     ({45'b0,xil_tx1_sigs_ep[38:0]}),
    .pipe_rx_2_sigs     ({45'b0,xil_tx2_sigs_ep[38:0]}),
    .pipe_rx_3_sigs     ({45'b0,xil_tx3_sigs_ep[38:0]}),
    .pipe_rx_4_sigs     ({45'b0,xil_tx4_sigs_ep[38:0]}),
    .pipe_rx_5_sigs     ({45'b0,xil_tx5_sigs_ep[38:0]}),
    .pipe_rx_6_sigs     ({45'b0,xil_tx6_sigs_ep[38:0]}),
    .pipe_rx_7_sigs     ({45'b0,xil_tx7_sigs_ep[38:0]}),
    .common_commands_out(),
    .pipe_tx_0_sigs     (xil_tx0_sigs_rp),
    .pipe_tx_1_sigs     (xil_tx1_sigs_rp),
    .pipe_tx_2_sigs     (xil_tx2_sigs_rp),
    .pipe_tx_3_sigs     (xil_tx3_sigs_rp),
    .pipe_tx_4_sigs     (xil_tx4_sigs_rp),
    .pipe_tx_5_sigs     (xil_tx5_sigs_rp),
    .pipe_tx_6_sigs     (xil_tx6_sigs_rp),
    .pipe_tx_7_sigs     (xil_tx7_sigs_rp),

     // Tie-offs
    .pci_exp_rxp        ('b0),
    .pci_exp_rxn        ('b0));    
      
     assign xil_rx0_sigs_ep  = {45'b0,xil_tx0_sigs_rp[38:0]};
     assign xil_rx1_sigs_ep  = {45'b0,xil_tx1_sigs_rp[38:0]};
     assign xil_rx2_sigs_ep  = {45'b0,xil_tx2_sigs_rp[38:0]};
     assign xil_rx3_sigs_ep  = {45'b0,xil_tx3_sigs_rp[38:0]};
     assign xil_rx4_sigs_ep  = {45'b0,xil_tx4_sigs_rp[38:0]};
     assign xil_rx5_sigs_ep  = {45'b0,xil_tx5_sigs_rp[38:0]};
     assign xil_rx6_sigs_ep  = {45'b0,xil_tx6_sigs_rp[38:0]};
     assign xil_rx7_sigs_ep  = {45'b0,xil_tx7_sigs_rp[38:0]};
     
  //------------------------------------------------------------------------------//
  // Simulation with BFM (comment out the Simulation Root Port Model)
  //------------------------------------------------------------------------------//
  //
  // PCI-Express use case with BFM Instance
  //
  //-----------------------------------------------------------------------------
  //-- Description:  Pipe Mode Interface
  //-- 16bit data for Gen1 rate @ Pipe Clk 125 
  //-- 16bit data for Gen2 rate @ Pipe Clk 250
  //-- 32bit data for Gen3 rate @ Pipe Clk 250  
  //-- For Gen1/Gen2 use case, tie-off rx*_start_block, rx*_data_valid, rx*_syncheader & rx*_data[31:16]
  //-- Pipe Clk is provided as output of this module - All pipe signals need to be aligned to provided Pipe Clk
  //-- pipe_tx_rate (00 - Gen1, 01 -Gen2 & 10- Gen3)
  //-- Rcvr Detect is handled internally by the core (Rcvr Detect Bypassed)
  //-- RX Status and PHY Status are handled internally (speed change & rcvr detect )
  //-- Phase2/3 needs to be disabled 
  //-- LF & FS values are 40 & 12 decimal
  //-- RP should provide TX preset hint of 5 (in EQ TS2's before changing rate to Gen3)
  //-----------------------------------------------------------------------------
  /*
   xil_sig2pipe xil_dut_pipe (
 
     .xil_rx0_sigs(xil_rx0_sigs_ep),
     .xil_rx1_sigs(xil_rx1_sigs_ep),
     .xil_rx2_sigs(xil_rx2_sigs_ep),
     .xil_rx3_sigs(xil_rx3_sigs_ep),
     .xil_rx4_sigs(xil_rx4_sigs_ep),
     .xil_rx5_sigs(xil_rx5_sigs_ep),
     .xil_rx6_sigs(xil_rx6_sigs_ep),
     .xil_rx7_sigs(xil_rx7_sigs_ep),
     .xil_common_commands(common_commands_out),
     .xil_tx0_sigs(xil_tx0_sigs_ep),
     .xil_tx1_sigs(xil_tx1_sigs_ep),
     .xil_tx2_sigs(xil_tx2_sigs_ep),
     .xil_tx3_sigs(xil_tx3_sigs_ep),
     .xil_tx4_sigs(xil_tx4_sigs_ep),
     .xil_tx5_sigs(xil_tx5_sigs_ep),
     .xil_tx6_sigs(xil_tx6_sigs_ep),
     .xil_tx7_sigs(xil_tx7_sigs_ep),
      ///////////// do not modify above this line //////////
      //////////Connect the following pipe ports to BFM///////////////
     .pipe_clk(),               // input to BFM  (pipe clock output)                 
     .pipe_tx_rate(),           // input to BFM  (rate)
     .pipe_tx_detect_rx(),      // input to BFM  (Receiver Detect)  
     .pipe_tx_powerdown(),      // input to BFM  (Powerdown)  
      // Pipe TX Interface
     .pipe_tx0_data(),          // input to BFM
     .pipe_tx1_data(),          // input to BFM
     .pipe_tx2_data(),          // input to BFM
     .pipe_tx3_data(),          // input to BFM
     .pipe_tx4_data(),          // input to BFM
     .pipe_tx5_data(),          // input to BFM
     .pipe_tx6_data(),          // input to BFM
     .pipe_tx7_data(),          // input to BFM
     .pipe_tx0_char_is_k(),     // input to BFM
     .pipe_tx1_char_is_k(),     // input to BFM
     .pipe_tx2_char_is_k(),     // input to BFM
     .pipe_tx3_char_is_k(),     // input to BFM
     .pipe_tx4_char_is_k(),     // input to BFM
     .pipe_tx5_char_is_k(),     // input to BFM
     .pipe_tx6_char_is_k(),     // input to BFM
     .pipe_tx7_char_is_k(),     // input to BFM
     .pipe_tx0_elec_idle(),     // input to BFM
     .pipe_tx1_elec_idle(),     // input to BFM
     .pipe_tx2_elec_idle(),     // input to BFM
     .pipe_tx3_elec_idle(),     // input to BFM
     .pipe_tx4_elec_idle(),     // input to BFM
     .pipe_tx5_elec_idle(),     // input to BFM
     .pipe_tx6_elec_idle(),     // input to BFM
     .pipe_tx7_elec_idle(),     // input to BFM
     .pipe_tx0_start_block(),   // input to BFM
     .pipe_tx1_start_block(),   // input to BFM
     .pipe_tx2_start_block(),   // input to BFM
     .pipe_tx3_start_block(),   // input to BFM
     .pipe_tx4_start_block(),   // input to BFM
     .pipe_tx5_start_block(),   // input to BFM
     .pipe_tx6_start_block(),   // input to BFM
     .pipe_tx7_start_block(),   // input to BFM
     .pipe_tx0_syncheader(),    // input to BFM
     .pipe_tx1_syncheader(),    // input to BFM
     .pipe_tx2_syncheader(),    // input to BFM
     .pipe_tx3_syncheader(),    // input to BFM
     .pipe_tx4_syncheader(),    // input to BFM
     .pipe_tx5_syncheader(),    // input to BFM
     .pipe_tx6_syncheader(),    // input to BFM
     .pipe_tx7_syncheader(),    // input to BFM
     .pipe_tx0_data_valid(),    // input to BFM
     .pipe_tx1_data_valid(),    // input to BFM
     .pipe_tx2_data_valid(),    // input to BFM
     .pipe_tx3_data_valid(),    // input to BFM
     .pipe_tx4_data_valid(),    // input to BFM
     .pipe_tx5_data_valid(),    // input to BFM
     .pipe_tx6_data_valid(),    // input to BFM
     .pipe_tx7_data_valid(),    // input to BFM
     // Pipe RX Interface
     .pipe_rx0_data(),          // output of BFM
     .pipe_rx1_data(),          // output of BFM
     .pipe_rx2_data(),          // output of BFM
     .pipe_rx3_data(),          // output of BFM
     .pipe_rx4_data(),          // output of BFM
     .pipe_rx5_data(),          // output of BFM
     .pipe_rx6_data(),          // output of BFM
     .pipe_rx7_data(),          // output of BFM
     .pipe_rx0_char_is_k(),     // output of BFM
     .pipe_rx1_char_is_k(),     // output of BFM
     .pipe_rx2_char_is_k(),     // output of BFM
     .pipe_rx3_char_is_k(),     // output of BFM
     .pipe_rx4_char_is_k(),     // output of BFM
     .pipe_rx5_char_is_k(),     // output of BFM
     .pipe_rx6_char_is_k(),     // output of BFM
     .pipe_rx7_char_is_k(),     // output of BFM
     .pipe_rx0_elec_idle(),     // output of BFM
     .pipe_rx1_elec_idle(),     // output of BFM
     .pipe_rx2_elec_idle(),     // output of BFM
     .pipe_rx3_elec_idle(),     // output of BFM
     .pipe_rx4_elec_idle(),     // output of BFM
     .pipe_rx5_elec_idle(),     // output of BFM
     .pipe_rx6_elec_idle(),     // output of BFM
     .pipe_rx7_elec_idle(),     // output of BFM
     .pipe_rx0_start_block(),   // output of BFM
     .pipe_rx1_start_block(),   // output of BFM
     .pipe_rx2_start_block(),   // output of BFM
     .pipe_rx3_start_block(),   // output of BFM
     .pipe_rx4_start_block(),   // output of BFM
     .pipe_rx5_start_block(),   // output of BFM
     .pipe_rx6_start_block(),   // output of BFM
     .pipe_rx7_start_block(),   // output of BFM
     .pipe_rx0_syncheader(),    // output of BFM
     .pipe_rx1_syncheader(),    // output of BFM
     .pipe_rx2_syncheader(),    // output of BFM
     .pipe_rx3_syncheader(),    // output of BFM
     .pipe_rx4_syncheader(),    // output of BFM
     .pipe_rx5_syncheader(),    // output of BFM
     .pipe_rx6_syncheader(),    // output of BFM
     .pipe_rx7_syncheader(),    // output of BFM
     .pipe_rx0_data_valid(),    // output of BFM
     .pipe_rx1_data_valid(),    // output of BFM
     .pipe_rx2_data_valid(),    // output of BFM
     .pipe_rx3_data_valid(),    // output of BFM
     .pipe_rx4_data_valid(),    // output of BFM
     .pipe_rx5_data_valid(),    // output of BFM
     .pipe_rx6_data_valid(),    // output of BFM
     .pipe_rx7_data_valid()     // output of BFM
);
*/
 
endmodule // BOARD
