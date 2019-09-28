// (c) Copyright 1995-2013 Xilinx, Inc. All rights reserved.
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
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:blk_mem_gen:8.0
// IP Revision: 2

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module blk_mem_gen_0 (
  s_aclk,
  s_aresetn,
  s_axi_awaddr,
  s_axi_awvalid,
  s_axi_awready,
  s_axi_wdata,
  s_axi_wstrb,
  s_axi_wvalid,
  s_axi_wready,
  s_axi_bresp,
  s_axi_bvalid,
  s_axi_bready,
  s_axi_araddr,
  s_axi_arvalid,
  s_axi_arready,
  s_axi_rdata,
  s_axi_rresp,
  s_axi_rvalid,
  s_axi_rready
);

(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.ACLK CLK" *)
input s_aclk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.ARESETN RST" *)
input s_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI AWADDR" *)
input [31 : 0] s_axi_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI AWVALID" *)
input s_axi_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI AWREADY" *)
output s_axi_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI WDATA" *)
input [31 : 0] s_axi_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI WSTRB" *)
input [3 : 0] s_axi_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI WVALID" *)
input s_axi_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI WREADY" *)
output s_axi_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI BRESP" *)
output [1 : 0] s_axi_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI BVALID" *)
output s_axi_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI BREADY" *)
input s_axi_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI ARADDR" *)
input [31 : 0] s_axi_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI ARVALID" *)
input s_axi_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI ARREADY" *)
output s_axi_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI RDATA" *)
output [31 : 0] s_axi_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI RRESP" *)
output [1 : 0] s_axi_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI RVALID" *)
output s_axi_rvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXILite_SLAVE_S_AXI RREADY" *)
input s_axi_rready;

  blk_mem_gen_v8_0 #(
    .C_FAMILY("virtex7"),
    .C_XDEVICEFAMILY("virtex7"),
    .C_ELABORATION_DIR("./"),
    .C_INTERFACE_TYPE(1),
    .C_AXI_TYPE(0),
    .C_AXI_SLAVE_TYPE(0),
    .C_HAS_AXI_ID(0),
    .C_AXI_ID_WIDTH(5),
    .C_MEM_TYPE(1),
    .C_BYTE_SIZE(8),
    .C_ALGORITHM(1),
    .C_PRIM_TYPE(1),
    .C_LOAD_INIT_FILE(0),
    .C_INIT_FILE_NAME("no_coe_file_loaded"),
    .C_INIT_FILE("blk_mem_gen_0.mem"),
    .C_USE_DEFAULT_DATA(0),
    .C_DEFAULT_DATA("0"),
    .C_RST_TYPE("ASYNC"),
    .C_HAS_RSTA(0),
    .C_RST_PRIORITY_A("CE"),
    .C_RSTRAM_A(0),
    .C_INITA_VAL("0"),
    .C_HAS_ENA(1),
    .C_HAS_REGCEA(0),
    .C_USE_BYTE_WEA(1),
    .C_WEA_WIDTH(4),
    .C_WRITE_MODE_A("READ_FIRST"),
    .C_WRITE_WIDTH_A(32),
    .C_READ_WIDTH_A(32),
    .C_WRITE_DEPTH_A(1024),
    .C_READ_DEPTH_A(1024),
    .C_ADDRA_WIDTH(10),
    .C_HAS_RSTB(1),
    .C_RST_PRIORITY_B("CE"),
    .C_RSTRAM_B(0),
    .C_INITB_VAL("0"),
    .C_HAS_ENB(1),
    .C_HAS_REGCEB(0),
    .C_USE_BYTE_WEB(1),
    .C_WEB_WIDTH(4),
    .C_WRITE_MODE_B("READ_FIRST"),
    .C_WRITE_WIDTH_B(32),
    .C_READ_WIDTH_B(32),
    .C_WRITE_DEPTH_B(1024),
    .C_READ_DEPTH_B(1024),
    .C_ADDRB_WIDTH(10),
    .C_HAS_MEM_OUTPUT_REGS_A(0),
    .C_HAS_MEM_OUTPUT_REGS_B(0),
    .C_HAS_MUX_OUTPUT_REGS_A(0),
    .C_HAS_MUX_OUTPUT_REGS_B(0),
    .C_MUX_PIPELINE_STAGES(0),
    .C_HAS_SOFTECC_INPUT_REGS_A(0),
    .C_HAS_SOFTECC_OUTPUT_REGS_B(0),
    .C_USE_SOFTECC(0),
    .C_USE_ECC(0),
    .C_HAS_INJECTERR(0),
    .C_SIM_COLLISION_CHECK("ALL"),
    .C_COMMON_CLK(1),
    .C_ENABLE_32BIT_ADDRESS(0),
    .C_DISABLE_WARN_BHV_COLL(0),
    .C_DISABLE_WARN_BHV_RANGE(0),
    .C_USE_BRAM_BLOCK(0),
    .C_CTRL_ECC_ALGO("NONE")
  ) inst (
    .clka(1'B0),
    .rsta(1'B0),
    .ena(1'B0),
    .regcea(1'B0),
    .wea(4'B0),
    .addra(10'B0),
    .dina(32'B0),
    .douta(),
    .clkb(1'B0),
    .rstb(1'B0),
    .enb(1'B0),
    .regceb(1'B0),
    .web(4'B0),
    .addrb(10'B0),
    .dinb(32'B0),
    .doutb(),
    .injectsbiterr(1'B0),
    .injectdbiterr(1'B0),
    .sbiterr(),
    .dbiterr(),
    .rdaddrecc(),
    .s_aclk(s_aclk),
    .s_aresetn(s_aresetn),
    .s_axi_awid(5'B0),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awlen(8'B0),
    .s_axi_awsize(3'B0),
    .s_axi_awburst(2'B0),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wlast(1'B0),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bid(),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_arid(5'B0),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arlen(8'B0),
    .s_axi_arsize(3'B0),
    .s_axi_arburst(2'B0),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .s_axi_injectsbiterr(1'B0),
    .s_axi_injectdbiterr(1'B0),
    .s_axi_sbiterr(),
    .s_axi_dbiterr(),
    .s_axi_rdaddrecc()
  );
endmodule
