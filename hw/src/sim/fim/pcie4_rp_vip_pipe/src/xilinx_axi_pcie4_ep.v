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
// Project    : The Xilinx PCI Express DMA 
// File       : xilinx_axi_pcie4_ep.v
// Version    : 4.1
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Project    : AXI PCIe example design
// File       : xilinx_axi_pcie4_ep.v
// Version    : 2.2 
// Description : Top-level example file
//
// Hierarchy   : consists of axi_pcie_0_support & axi_pcie_0 if both EXT_CLK< EXT_GT_COOMON are FALSE & axi_bram_ctrl_0
//               |--xilinx_axi_pcie4_ep
//                  |
//                  |--axi_bram_cntrl
//                  |--axi_pcie_0 if PCIE_EXT_CLK & PCIE_EXT_GT_COMMON are FALSE
//						|
//						|--axi_pcie (axi pcie design)
//							|
//							|--<various>
//		    |--axi_pcie_0_support If either of or both PCIE_EXT_CLK & PCIE_EXT_GT_COMMON are TRUE
//						|
//						|--ext_pipe_clk(external pipe clock)
//						|--ext_gt_common(external gt common)
//						|--axi_pcie_0
//							|
//							|--axi_pcie (axi pcie design)
//								|
//								|--<various>
//
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module xilinx_axi_pcie4_ep  #(
  parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
  parameter PCIE_EXT_CLK        = "false",  // Use External Clocking Module
  parameter PCIE_EXT_GT_COMMON  = "false",
  parameter REF_CLK_FREQ        = 0,
  parameter EXT_PIPE_SIM        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
  parameter C_DATA_WIDTH        = 256, // RX/TX interface data width
  parameter KEEP_WIDTH          = C_DATA_WIDTH / 8,
  parameter AXIS_CCIX_RX_TDATA_WIDTH     = 256, 
  parameter AXIS_CCIX_TX_TDATA_WIDTH     = 256,
  parameter AXIS_CCIX_RX_TUSER_WIDTH     = 46,
  parameter AXIS_CCIX_TX_TUSER_WIDTH     = 46
) (

  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,
  // synthesis translate_off
  input   [25:0]                               common_commands_in,
  input   [83:0]                               pipe_rx_0_sigs,
  input   [83:0]                               pipe_rx_1_sigs,
  input   [83:0]                               pipe_rx_2_sigs,
  input   [83:0]                               pipe_rx_3_sigs,
  input   [83:0]                               pipe_rx_4_sigs,
  input   [83:0]                               pipe_rx_5_sigs,
  input   [83:0]                               pipe_rx_6_sigs,
  input   [83:0]                               pipe_rx_7_sigs,
  input   [83:0]                               pipe_rx_8_sigs,
  input   [83:0]                               pipe_rx_9_sigs,
  input   [83:0]                               pipe_rx_10_sigs,
  input   [83:0]                               pipe_rx_11_sigs,
  input   [83:0]                               pipe_rx_12_sigs,
  input   [83:0]                               pipe_rx_13_sigs,
  input   [83:0]                               pipe_rx_14_sigs,
  input   [83:0]                               pipe_rx_15_sigs,
  output  [25:0]                               common_commands_out,
  output  [83:0]                               pipe_tx_0_sigs,
  output  [83:0]                               pipe_tx_1_sigs,
  output  [83:0]                               pipe_tx_2_sigs,
  output  [83:0]                               pipe_tx_3_sigs,
  output  [83:0]                               pipe_tx_4_sigs,
  output  [83:0]                               pipe_tx_5_sigs,
  output  [83:0]                               pipe_tx_6_sigs,
  output  [83:0]                               pipe_tx_7_sigs,
  output  [83:0]                               pipe_tx_8_sigs,
  output  [83:0]                               pipe_tx_9_sigs,
  output  [83:0]                               pipe_tx_10_sigs,
  output  [83:0]                               pipe_tx_11_sigs,
  output  [83:0]                               pipe_tx_12_sigs,
  output  [83:0]                               pipe_tx_13_sigs,
  output  [83:0]                               pipe_tx_14_sigs,
  output  [83:0]                               pipe_tx_15_sigs,
  // synthesis translate_on
  input                                       sys_clk_p,
  input                                       sys_clk_n,
  input                                       sys_rst_n
);

localparam PL_LINK_CAP_MAX_LINK_WIDTH = 8;
localparam ADDR_WIDTH      = 32; // RX/TX interface addr width
localparam C_NUM_USR_IRQ	 = 1;
localparam C_M_AXI_ID_WIDTH = 4;


wire axi_aclk_out;
wire m_axi_awlock;
wire m_axi_awvalid;	
wire m_axi_awready;	
wire m_axi_wlast  ;      
wire m_axi_wvalid ;      
wire m_axi_wready ;      
wire m_axi_bvalid ;      
wire m_axi_bready ;      
wire m_axi_arlock ;      
wire m_axi_arvalid;	
wire m_axi_arready;	
wire m_axi_rlast  ;      
wire m_axi_rvalid ;      
wire m_axi_rready ; 

wire [7 : 0] 	m_axi_awlen;
wire [2 : 0] 	m_axi_awsize;
wire [2 : 0] 	m_axi_awprot;
wire [2 : 0] 	m_axi_arprot;
wire [3 : 0] 	m_axi_awcache;
wire [3 : 0] 	m_axi_arcache;
wire [1 : 0] 	m_axi_awburst;
wire [1 : 0] 	bresp;
wire [1 : 0] 	rresp;
wire [(C_DATA_WIDTH - 1) : 0]	m_axi_wdata;
wire [(C_DATA_WIDTH - 1) : 0]	rdata;
wire [7 : 0] 	m_axi_arlen;
wire [2 : 0] 	m_axi_arsize;
wire [1 : 0] 	m_axi_arburst;
wire [(KEEP_WIDTH -1) : 0]	m_axi_wstrb;

wire [1 : 0] 	m_axi_bresp = bresp[1:0];
wire [1 : 0] 	m_axi_rresp = rresp[1:0];
wire [7 : 0] 	awlen =   m_axi_awlen	[7 : 0] ;
wire [2 : 0] 	awsize= m_axi_awsize	[2 : 0] ;
wire [2 : 0] 	awprot= m_axi_awprot	[2 : 0] ;
wire [2 : 0] 	arprot= m_axi_arprot	[2 : 0] ;
wire [3 : 0] 	awcache= m_axi_awcache	[3 : 0] ;
wire [3 : 0] 	arcache= m_axi_arcache	[3 : 0] ;
wire [1 : 0] 	awburst=m_axi_awburst	[1 : 0] ;
wire [(C_DATA_WIDTH -1) : 0]	wdata=  m_axi_wdata	[(C_DATA_WIDTH -1) : 0];
wire [(C_DATA_WIDTH -1) : 0]	temp_wdata=  0;
wire [(C_DATA_WIDTH -1) : 0]	m_axi_rdata=  rdata	[(C_DATA_WIDTH -1) : 0];
wire [(KEEP_WIDTH -1) : 0]	wstrb=  m_axi_wstrb	[(KEEP_WIDTH -1) : 0];
wire [7 : 0] 	arlen=  m_axi_arlen	[7 : 0] ;
wire [2 : 0] 	arsize= m_axi_arsize	[2 : 0] ;
wire [1 : 0] 	arburst=m_axi_arburst	[1 : 0] ;

wire [(ADDR_WIDTH -1):0]  m_axi_araddr;
wire [(ADDR_WIDTH -1):0]  m_axi_awaddr;
wire [C_M_AXI_ID_WIDTH-1:0]   m_axib_awid;
wire [C_M_AXI_ID_WIDTH-1 : 0] m_axib_arid;
wire       [15:0]    awaddr = m_axi_awaddr[15:0];
wire       [15:0]    araddr = m_axi_araddr[15:0];

wire [3:0]      leds;

  localparam integer USER_CLK_FREQ        = 2;
  localparam integer CORE_CLK_FREQ        = ((4 == 4) ? 5 : 4);
  //-------------------------------------------------------

  wire  [25:0]  common_commands_in_i;
  wire  [83:0]  pipe_rx_0_sigs_i;
  wire  [83:0]  pipe_rx_1_sigs_i;
  wire  [83:0]  pipe_rx_2_sigs_i;
  wire  [83:0]  pipe_rx_3_sigs_i;
  wire  [83:0]  pipe_rx_4_sigs_i;
  wire  [83:0]  pipe_rx_5_sigs_i;
  wire  [83:0]  pipe_rx_6_sigs_i;
  wire  [83:0]  pipe_rx_7_sigs_i;
  wire  [83:0]  pipe_rx_8_sigs_i;
  wire  [83:0]  pipe_rx_9_sigs_i;
  wire  [83:0]  pipe_rx_10_sigs_i;
  wire  [83:0]  pipe_rx_11_sigs_i;
  wire  [83:0]  pipe_rx_12_sigs_i;
  wire  [83:0]  pipe_rx_13_sigs_i;
  wire  [83:0]  pipe_rx_14_sigs_i;
  wire  [83:0]  pipe_rx_15_sigs_i;
  wire  [25:0]  common_commands_out_i;
  wire  [83:0]  pipe_tx_0_sigs_i;
  wire  [83:0]  pipe_tx_1_sigs_i;
  wire  [83:0]  pipe_tx_2_sigs_i;
  wire  [83:0]  pipe_tx_3_sigs_i;
  wire  [83:0]  pipe_tx_4_sigs_i;
  wire  [83:0]  pipe_tx_5_sigs_i;
  wire  [83:0]  pipe_tx_6_sigs_i;
  wire  [83:0]  pipe_tx_7_sigs_i;
  wire  [83:0]  pipe_tx_8_sigs_i;
  wire  [83:0]  pipe_tx_9_sigs_i;
  wire  [83:0]  pipe_tx_10_sigs_i;
  wire  [83:0]  pipe_tx_11_sigs_i;
  wire  [83:0]  pipe_tx_12_sigs_i;
  wire  [83:0]  pipe_tx_13_sigs_i;
  wire  [83:0]  pipe_tx_14_sigs_i;
  wire  [83:0]  pipe_tx_15_sigs_i;


// synthesis translate_off
generate if (EXT_PIPE_SIM == "TRUE") 
begin
  assign common_commands_in_i = common_commands_in;  
  assign pipe_rx_0_sigs_i     = pipe_rx_0_sigs;   
  assign pipe_rx_1_sigs_i     = pipe_rx_1_sigs;   
  assign pipe_rx_2_sigs_i     = pipe_rx_2_sigs;   
  assign pipe_rx_3_sigs_i     = pipe_rx_3_sigs;   
  assign pipe_rx_4_sigs_i     = pipe_rx_4_sigs;   
  assign pipe_rx_5_sigs_i     = pipe_rx_5_sigs;   
  assign pipe_rx_6_sigs_i     = pipe_rx_6_sigs;   
  assign pipe_rx_7_sigs_i     = pipe_rx_7_sigs;
  assign pipe_rx_8_sigs_i     = pipe_rx_8_sigs;   
  assign pipe_rx_9_sigs_i     = pipe_rx_9_sigs;   
  assign pipe_rx_10_sigs_i     = pipe_rx_10_sigs;   
  assign pipe_rx_11_sigs_i     = pipe_rx_11_sigs;   
  assign pipe_rx_12_sigs_i     = pipe_rx_12_sigs;   
  assign pipe_rx_13_sigs_i     = pipe_rx_13_sigs;   
  assign pipe_rx_14_sigs_i     = pipe_rx_14_sigs;   
  assign pipe_rx_15_sigs_i     = pipe_rx_15_sigs;
  assign common_commands_out  = common_commands_out_i; 
  assign pipe_tx_0_sigs       = pipe_tx_0_sigs_i;      
  assign pipe_tx_1_sigs       = pipe_tx_1_sigs_i;      
  assign pipe_tx_2_sigs       = pipe_tx_2_sigs_i;      
  assign pipe_tx_3_sigs       = pipe_tx_3_sigs_i;      
  assign pipe_tx_4_sigs       = pipe_tx_4_sigs_i;      
  assign pipe_tx_5_sigs       = pipe_tx_5_sigs_i;      
  assign pipe_tx_6_sigs       = pipe_tx_6_sigs_i;      
  assign pipe_tx_7_sigs       = pipe_tx_7_sigs_i;
  assign pipe_tx_8_sigs       = pipe_tx_8_sigs_i;      
  assign pipe_tx_9_sigs       = pipe_tx_9_sigs_i;      
  assign pipe_tx_10_sigs       = pipe_tx_10_sigs_i;      
  assign pipe_tx_11_sigs       = pipe_tx_11_sigs_i;      
  assign pipe_tx_12_sigs       = pipe_tx_12_sigs_i;      
  assign pipe_tx_13_sigs       = pipe_tx_13_sigs_i;      
  assign pipe_tx_14_sigs       = pipe_tx_14_sigs_i;      
  assign pipe_tx_15_sigs       = pipe_tx_15_sigs_i;
 end
endgenerate
// synthesis translate_on   
  
generate if (EXT_PIPE_SIM == "FALSE") 
begin
  assign common_commands_in_i = 26'h0;  
  assign pipe_rx_0_sigs_i     = 84'h0;
  assign pipe_rx_1_sigs_i     = 84'h0;
  assign pipe_rx_2_sigs_i     = 84'h0;
  assign pipe_rx_3_sigs_i     = 84'h0;
  assign pipe_rx_4_sigs_i     = 84'h0;
  assign pipe_rx_5_sigs_i     = 84'h0;
  assign pipe_rx_6_sigs_i     = 84'h0;
  assign pipe_rx_7_sigs_i     = 84'h0;
  assign pipe_rx_8_sigs_i     = 84'h0;
  assign pipe_rx_9_sigs_i     = 84'h0;
  assign pipe_rx_10_sigs_i     = 84'h0;
  assign pipe_rx_11_sigs_i     = 84'h0;
  assign pipe_rx_12_sigs_i     = 84'h0;
  assign pipe_rx_13_sigs_i     = 84'h0;
  assign pipe_rx_14_sigs_i     = 84'h0;
  assign pipe_rx_15_sigs_i     = 84'h0;
 end
endgenerate
  //-------------------------------------------------------
  reg pipe_mmcm_rst_n = 1'b1;

  wire sys_rst_n_c;
  wire sys_clk;
  wire sys_clk_gt;
  wire user_lnk_up;
  wire [5:0] cfg_ltssm_state;
  wire axi_aresetn;
  wire axi_ctl_aresetn;

  reg  [C_NUM_USR_IRQ-1:0] 		     usr_irq_req = 0;
  wire [C_NUM_USR_IRQ-1:0] 		     usr_irq_ack;

  // Local Parameters
  localparam                                  TCQ = 1;

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));




//
//

  // Core Top Level Wrapper
  xdma_0 xdma_0_i (
  //---------------------------------------------------------------------------------------//
  //  PCI Express (pci_exp) Interface                                                      //
  //---------------------------------------------------------------------------------------//
  .pci_exp_txp          ( pci_exp_txp ),
  .pci_exp_txn          ( pci_exp_txn ),
  .pci_exp_rxp          ( pci_exp_rxp ),
  .pci_exp_rxn          ( pci_exp_rxn ),

  .user_lnk_up          (user_lnk_up),
  .cfg_ltssm_state      (cfg_ltssm_state),




  .sys_clk_gt            (sys_clk_gt),
  .interrupt_out	(),	
  .s_axib_awid		(4'b0),	
  .s_axib_awaddr	(32'b0),	
  .s_axib_awregion	(4'b0),		
  .s_axib_awlen		(8'b0),	
  .s_axib_awsize	(3'b0),		
  .s_axib_awburst	(2'b0),			
  .s_axib_awvalid	(1'b0),		
  .s_axib_awready	(),		
  .s_axib_wdata		(256'b0),
  .s_axib_wstrb		(32'b0),			
  .s_axib_wlast		(1'b0),		
  .s_axib_wvalid	(1'b0),		
  .s_axib_wready	(),		
  .s_axib_bid		(),	
  .s_axib_bresp		(),	
  .s_axib_bvalid	(),		
  .s_axib_bready	(1'b1),		
  .s_axib_arid		(4'b0),		
  .s_axib_araddr	(32'b0),		
  .s_axib_arregion	(4'b0),		
  .s_axib_arlen		(8'b0),	
  .s_axib_arsize	(3'b0),		
  .s_axib_arburst	(2'b0),
  .s_axib_arvalid	(1'b0),
  .s_axib_arready	(),
  .s_axib_rid		(),
  .s_axib_rdata		(),
	
  .s_axib_rresp		(),
  .s_axib_rlast		(),
  .s_axib_rvalid	(),
  .s_axib_rready	(1'b1),
  .m_axib_bid		(3'b0),
  .m_axib_rid		(3'b0),
  .m_axib_awaddr	(m_axi_awaddr),
  .m_axib_awlen		(m_axi_awlen	),
  .m_axib_awsize	(m_axi_awsize	),
  .m_axib_awburst	(m_axi_awburst),
  .m_axib_awprot	(m_axi_awprot	),
  .m_axib_awvalid	(m_axi_awvalid),
  .m_axib_awready	(m_axi_awready),	
  .m_axib_awlock	(m_axi_awlock	),
  .m_axib_awcache	(m_axi_awcache),
  .m_axib_wdata		(m_axi_wdata	),
  .m_axib_wstrb		(m_axi_wstrb	),
  .m_axib_wlast		(m_axi_wlast	),
  .m_axib_wvalid	(m_axi_wvalid	),
  .m_axib_wready	(m_axi_wready	),
  .m_axib_bresp		(m_axi_bresp	),
  .m_axib_bvalid	(m_axi_bvalid	),
  .m_axib_bready	(m_axi_bready	),
  .m_axib_araddr	(m_axi_araddr	),
  .m_axib_awid          (m_axib_awid),
  .m_axib_arid          (m_axib_arid),
  .m_axib_arlen		(m_axi_arlen	),
  .m_axib_arsize	(m_axi_arsize	),
  .m_axib_arburst	(m_axi_arburst),
  .m_axib_arprot	(m_axi_arprot	),
  .m_axib_arvalid	(m_axi_arvalid),
  .m_axib_arready	(m_axi_arready),
  .m_axib_arlock	(m_axi_arlock	),
  .m_axib_arcache	(m_axi_arcache),       
  .m_axib_rdata		(m_axi_rdata	),
  .m_axib_rresp		(m_axi_rresp	),
  .m_axib_rlast		(m_axi_rlast	),
  .m_axib_rvalid	(m_axi_rvalid	),
  .m_axib_rready	(m_axi_rready	),
  .common_commands_in   (common_commands_in_i ),
  .pipe_rx_0_sigs       (pipe_rx_0_sigs_i     ),
  .pipe_rx_1_sigs       (pipe_rx_1_sigs_i     ),
  .pipe_rx_2_sigs       (pipe_rx_2_sigs_i     ),
  .pipe_rx_3_sigs       (pipe_rx_3_sigs_i     ),
  .pipe_rx_4_sigs       (pipe_rx_4_sigs_i     ),
  .pipe_rx_5_sigs       (pipe_rx_5_sigs_i     ),
  .pipe_rx_6_sigs       (pipe_rx_6_sigs_i     ),
  .pipe_rx_7_sigs       (pipe_rx_7_sigs_i     ),
  .pipe_rx_8_sigs       (pipe_rx_8_sigs_i     ),
  .pipe_rx_9_sigs       (pipe_rx_9_sigs_i     ),
  .pipe_rx_10_sigs      (pipe_rx_10_sigs_i     ),
  .pipe_rx_11_sigs      (pipe_rx_11_sigs_i     ),
  .pipe_rx_12_sigs      (pipe_rx_12_sigs_i     ),
  .pipe_rx_13_sigs      (pipe_rx_13_sigs_i     ),
  .pipe_rx_14_sigs      (pipe_rx_14_sigs_i     ),
  .pipe_rx_15_sigs      (pipe_rx_15_sigs_i     ),
  .common_commands_out  (common_commands_out_i),
  .pipe_tx_0_sigs       (pipe_tx_0_sigs_i     ),
  .pipe_tx_1_sigs       (pipe_tx_1_sigs_i     ),
  .pipe_tx_2_sigs       (pipe_tx_2_sigs_i     ),
  .pipe_tx_3_sigs       (pipe_tx_3_sigs_i     ),
  .pipe_tx_4_sigs       (pipe_tx_4_sigs_i     ),
  .pipe_tx_5_sigs       (pipe_tx_5_sigs_i     ),
  .pipe_tx_6_sigs       (pipe_tx_6_sigs_i     ),
  .pipe_tx_7_sigs       (pipe_tx_7_sigs_i     ),
  .pipe_tx_8_sigs       (pipe_tx_8_sigs_i     ),
  .pipe_tx_9_sigs       (pipe_tx_9_sigs_i     ),
  .pipe_tx_10_sigs      (pipe_tx_10_sigs_i     ),
  .pipe_tx_11_sigs      (pipe_tx_11_sigs_i     ),
  .pipe_tx_12_sigs      (pipe_tx_12_sigs_i     ),
  .pipe_tx_13_sigs      (pipe_tx_13_sigs_i     ),
  .pipe_tx_14_sigs      (pipe_tx_14_sigs_i     ),
  .pipe_tx_15_sigs      (pipe_tx_15_sigs_i     ),









 

   .s_axil_awaddr	(12'b0),
   .s_axil_awvalid	(1'b0),
   .s_axil_awready	(),
   .s_axil_wdata	(32'b0),
   .s_axil_wstrb	(4'b0),
   .s_axil_wvalid	(1'b0),
   .s_axil_wready	(),
   .s_axil_bresp	(),
   .s_axil_bvalid	(),
   .s_axil_bready	(1'b0),
   .s_axil_araddr	(12'b0),
   .s_axil_arvalid	(1'b0),
   .s_axil_arready	(),
   .s_axil_rdata	(),
   .s_axil_rresp	(),
   .s_axil_rvalid	(),
   .s_axil_rready	(1'b0),
   .s_axil_awprot       (3'b0),
   .s_axil_arprot       (3'b0),
   .axi_ctl_aresetn                           (axi_ctl_aresetn),		
   .usr_irq_req         (usr_irq_req ),
   .usr_irq_ack         (usr_irq_ack ),
   .axi_aresetn 	(axi_aresetn),
   .axi_aclk		(axi_aclk_out),
   .sys_rst_n           (sys_rst_n_c),


   .sys_clk         ( sys_clk )
);
     
    //example design BRAM Controller
    xilinx_axi_pcie_ep_app xilinx_axi_pcie_ep_app_i (        
  .s_axi_awaddr         (awaddr),
  .s_axi_awlen          (awlen),
  .s_axi_awsize         (awsize),
  .s_axi_awburst        (awburst),
  .s_axi_awlock         (m_axi_awlock),
  .s_axi_awcache        (awcache),
  .s_axi_awprot         (awprot),
  .s_axi_awvalid        (m_axi_awvalid),
  .s_axi_awready        (m_axi_awready),
  .s_axi_wdata          (wdata),
  .s_axi_wstrb          (wstrb),
  .s_axi_wlast          (m_axi_wlast),
  .s_axi_wvalid         (m_axi_wvalid),
  .s_axi_wready         (m_axi_wready),
  .s_axi_bresp          (bresp),
  .s_axi_bvalid         (m_axi_bvalid),
  .s_axi_bready         (m_axi_bready),
  .s_axi_araddr         (araddr),
  .s_axi_arlen          (arlen),
  .s_axi_arsize         (arsize),
  .s_axi_arburst        (arburst),
  .s_axi_arlock         (m_axi_arlock),
  .s_axi_arcache        (arcache),
  .s_axi_arprot         (arprot),
  .s_axi_arvalid        (m_axi_arvalid),
  .s_axi_arready        (m_axi_arready),
  .s_axi_rdata          (rdata),
  .s_axi_rresp          (rresp),
  .s_axi_rlast          (m_axi_rlast),
  .s_axi_rvalid         (m_axi_rvalid),
  .s_axi_rready         (m_axi_rready),
  
  .user_lnk_up         (user_lnk_up),
  .cfg_ltssm_state     (cfg_ltssm_state),
  .s_axi_aclk          (axi_aclk_out),
  .s_axi_aresetn       (axi_aresetn)
);


endmodule 
