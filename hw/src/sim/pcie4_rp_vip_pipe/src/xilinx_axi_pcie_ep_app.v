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
// File       : xilinx_axi_pcie_ep_app.v
// Version    : 4.1
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
module xilinx_axi_pcie_ep_app (
  input [7:0]  s_axi_awlen,
  input [2:0]  s_axi_awsize,
  input [1:0]  s_axi_awburst,
  input        s_axi_awlock,
  input [3:0]  s_axi_awcache,
  input [2:0]  s_axi_awprot,
  input        s_axi_awvalid,
  input [31 :0]  s_axi_wstrb,
  input        s_axi_wlast,
  input        s_axi_wvalid,
  input        s_axi_bready, 
  input [7:0]  s_axi_arlen,
  input [2:0]  s_axi_arsize,
  input [1:0]  s_axi_arburst,
  input        s_axi_arlock,
  input [3:0]  s_axi_arcache,
  input [2:0]  s_axi_arprot, 
  input        s_axi_arvalid,
  input        s_axi_rready,

// Common ports, regardless of $en_axi_master_if
  input [15:0] s_axi_awaddr,
  input [15:0] s_axi_araddr,
  output        s_axi_awready,
  input [255 :0]  s_axi_wdata,
  output        s_axi_wready,  
  output [1:0]  s_axi_bresp,
  output        s_axi_bvalid,
  output        s_axi_arready,
  output [255 :0]  s_axi_rdata,
  output [1:0]  s_axi_rresp,
  output        s_axi_rlast,
  output        s_axi_rvalid,
 
  input        user_lnk_up,
  input [5:0]  cfg_ltssm_state,
  input        s_axi_aclk,
  input        s_axi_aresetn 
);
 
 



  //example design BRAM Controller
  axi_bram_ctrl_0 AXI_BRAM_CTL(
  .s_axi_aclk 	 (s_axi_aclk),
  .s_axi_aresetn (s_axi_aresetn),
  .s_axi_awid 	 (4'b0),
  .s_axi_awaddr	 (s_axi_awaddr),
  .s_axi_awlen 	 (s_axi_awlen),
  .s_axi_awsize	 (s_axi_awsize),
  .s_axi_awburst (s_axi_awburst),
  .s_axi_awlock  (s_axi_awlock),
  .s_axi_awcache (s_axi_awcache),
  .s_axi_awprot  (s_axi_awprot),
  .s_axi_awvalid (s_axi_awvalid),
  .s_axi_awready (s_axi_awready),
  .s_axi_wdata 	 (s_axi_wdata),
  .s_axi_wstrb   (s_axi_wstrb),
  .s_axi_wlast 	 (s_axi_wlast),
  .s_axi_wvalid  (s_axi_wvalid),
  .s_axi_wready  (s_axi_wready),
  .s_axi_bid	 (),
  .s_axi_bresp 	 (s_axi_bresp),
  .s_axi_bvalid	 (s_axi_bvalid),
  .s_axi_bready  (s_axi_bready),
  .s_axi_arid 	 (4'b0),
  .s_axi_araddr  (s_axi_araddr),
  .s_axi_arlen   (s_axi_arlen),
  .s_axi_arsize	 (s_axi_arsize),
  .s_axi_arburst (s_axi_arburst),
  .s_axi_arlock	 (s_axi_arlock),
  .s_axi_arcache (s_axi_arcache),
  .s_axi_arprot	 (s_axi_arprot),
  .s_axi_arvalid (s_axi_arvalid),
  .s_axi_arready (s_axi_arready),
  .s_axi_rid	 (),
  .s_axi_rdata   (s_axi_rdata),
  .s_axi_rresp   (s_axi_rresp),
  .s_axi_rlast   (s_axi_rlast),
  .s_axi_rvalid	 (s_axi_rvalid),
  .s_axi_rready	 (s_axi_rready)

);


endmodule
