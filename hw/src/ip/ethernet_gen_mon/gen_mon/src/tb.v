//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
// FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
// IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
// MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
// and (2) Xilinx shall not be liable (whether in contract or tort, including
// negligence, or under any other theory of liability) for any loss or damage
// of any kind or nature related to, arising under or in connection with these
// materials, including for any direct, or any indirect, special, incidental,
// or consequential loss or damage (including loss of data, profits, goodwill,
// or any type of loss or damage suffered as a result of any action brought by
// a third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// CRITICAL APPLICATIONS
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other
// applications that could lead to death, personal injury, or severe property
// or environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.

`timescale 1ps / 1ps

module tb;

parameter AXIS_TDATA_WIDTH =  64;
parameter AXIS_TKEEP_WIDTH =  AXIS_TDATA_WIDTH/8;   

reg       reset;
reg       clk_156;
integer   i;
integer   cnt;

wire [AXIS_TDATA_WIDTH-1:0]     tx_axis_tdata;
wire [AXIS_TKEEP_WIDTH-1:0]     tx_axis_tkeep;
wire                            tx_axis_tvalid;
wire                            tx_axis_tlast;
wire                            tx_axis_tuser;
reg                             tx_axis_tready;

reg  [47:0]                     tg_config;

reg                             data_available;
  axi_stream_gen_mon # (
    .AXIS_TDATA_WIDTH (AXIS_TDATA_WIDTH )
  )  
  axi_stream_gen_mon_i (
     .s_axi_clk          (1'b0            ),
     .s_axi_areset_n     (1'b0            ),
     .s_axi_awaddr       (32'b0           ),
     .s_axi_awready      (                ),
     .s_axi_awvalid      (1'b0            ),
     .s_axi_wdata        (32'b0           ),
     .s_axi_wstrb        (4'b0            ),
     .s_axi_wvalid       (1'b0            ),
     .s_axi_wready       (                ),
     .s_axi_bresp        (                ),
     .s_axi_bvalid       (                ),
     .s_axi_bready       (1'b1            ),
     .s_axi_araddr       (32'b0           ),
     .s_axi_arvalid      (1'b0            ),
     .s_axi_arready      (                ),
     .s_axi_rdata        (                ),
     .s_axi_rresp        (                ),
     .s_axi_rvalid       (                ),
     .s_axi_rready       (1'b1            ),
     .tg_config          (tg_config       ),
     .axis_reset_n       (!reset          ),
     .axis_clk           (clk_156         ),
     .tx_axis_tdata      (tx_axis_tdata   ),
     .tx_axis_tkeep      (tx_axis_tkeep   ),
     .tx_axis_tvalid     (tx_axis_tvalid  ),
     .tx_axis_tlast      (tx_axis_tlast   ),
     .tx_axis_tuser      (tx_axis_tuser   ),
     .tx_axis_tready     (tx_axis_tready  ),
     .rx_axis_tdata      (64'b0           ),
     .rx_axis_tkeep      (8'b0            ),
     .rx_axis_tvalid     (1'b0            ),
     .rx_axis_tlast      (1'b0            ),
     .rx_axis_tuser      (1'b0            ),
     .rx_axis_tready     (                )

  );


 initial 
 begin
   clk_156 = 1'b0;
   forever #(6400/2) clk_156 = ~clk_156;
 end

assign clk_156_p = clk_156;
assign clk_156_n = ~clk_156;
  

initial begin
  $display("[%t] : System Reset Asserted...", $realtime);
  reset = 1'b1;

  for (i = 0; i < 100; i = i + 1) begin
    @(posedge clk_156);
  end

  $display("[%t] : System Reset De-asserted...", $realtime);
  reset = 1'b0;
end


always @ (posedge clk_156) begin
  if (reset == 1'b1 ||  cnt == 16 || cnt == 17 || cnt == 27 || cnt == 32 || cnt == 39 ||cnt == 49 || cnt == 52 || cnt == 75 ||cnt == 76 || cnt == 77)
    tx_axis_tready <= 1'b0;
  else if (data_available)
    tx_axis_tready <= 1'b1;
    
  if (reset == 1'b1)
    data_available <= 1'b0;
  else if (tx_axis_tvalid == 1'b1)
    data_available <= 1'b1;
    
end

always @ (posedge clk_156) begin
  if (reset == 1'b1)
    cnt <= 0;
  else if (cnt == 150)
   $finish;
  else 
    cnt <= cnt + 1;
end

always @ (posedge clk_156) begin
  if (reset == 1'b1 || cnt == 128) begin
    tg_config <= 32'b0;
  end
  else if (cnt == 5) begin 
    tg_config[1]     <= 1'b1;
    tg_config[31:16] <= 64;
    tg_config[47:32] <= 3;
  end  
    
end


endmodule
