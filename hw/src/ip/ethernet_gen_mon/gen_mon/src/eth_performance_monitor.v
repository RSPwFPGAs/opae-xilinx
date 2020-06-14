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
//
// Monitors the AXI interface to keep track of byte count sent/received during
// a one second time period.  Last two bits of byte count are dropped and replaced
// with a 2-bit sample count indicating that sample period to which the information
// belongs.  Software will read the registers every second, and will group together
// data from the same sample count.
//
`timescale 1ps / 1ps

module eth_performance_monitor #( 
  parameter AXIS_TDATA_WIDTH = 64,
  parameter AXIS_TKEEP_WIDTH = AXIS_TDATA_WIDTH/8,
  parameter ONE_SEC_CLOCK_COUNT = 32'h9502F90
 
 )
 (
   input                          clk,
   input                          reset,
   
   // - Eth-AXI TX interface
   input [AXIS_TDATA_WIDTH-1:0]   s_axis_tx_tdata,
   input [AXIS_TKEEP_WIDTH-1:0]   s_axis_tx_tkeep,
   input                          s_axis_tx_tlast,
   input                          s_axis_tx_tvalid,
   input                          s_axis_tx_tready,

   // - Eth-AXI RX interface
   input [AXIS_TDATA_WIDTH-1:0]   m_axis_rx_tdata,
   input [AXIS_TKEEP_WIDTH-1:0]   m_axis_rx_tkeep,
   input                          m_axis_rx_tlast,
   input                          m_axis_rx_tvalid,
   input                          m_axis_rx_tready,

   output reg  [31:0]             tx_byte_count,
   output reg  [31:0]             rx_byte_count,
   output reg  [31:0]             tx_pkt_count,
   output reg  [31:0]             rx_pkt_count

);

   
   reg [AXIS_TDATA_WIDTH-1:0]   reg_tx_tdata;
   reg [AXIS_TKEEP_WIDTH-1:0]   reg_tx_tkeep;
   reg                          reg_tx_tlast;
   reg                          reg_tx_tvalid;
   reg                          reg_tx_tready;
                        
   reg [AXIS_TDATA_WIDTH-1:0]   reg_rx_tdata;
   reg  [AXIS_TKEEP_WIDTH-1:0]  reg_rx_tkeep;
   reg                          reg_rx_tlast;
   reg                          reg_rx_tvalid;
   reg                          reg_rx_tready;

   reg [31:0]                   tx_byte_count_int;
   reg [31:0]                   rx_byte_count_int;

   reg [31:0]                   tx_pkt_count_int;
   reg [31:0]                   rx_pkt_count_int;

   reg  [1:0]                   sample_cnt;
   
   
   // Timer controls
   reg  [31:0]                  running_test_time;
   wire [31:0]                  one_second_cnt;
   
   wire [AXIS_TKEEP_WIDTH-1:0]  tx_keep_cnt;
   wire [AXIS_TKEEP_WIDTH-1:0]  rx_keep_cnt;

   //  6.4 ns = 1 clock count
   //  1 sec  = 156,250,000 clock counts = 32'h9502F90 clock counts
   assign one_second_cnt = ONE_SEC_CLOCK_COUNT;
   
  
  always @(posedge clk)   
  begin
    if (reset == 1'b1)  begin
      reg_tx_tlast    <= 'b0;
      reg_tx_tvalid   <= 'b0;
      reg_tx_tready   <= 'b0;
      reg_tx_tkeep    <= 'b0;

      reg_rx_tlast    <= 'b0;
      reg_rx_tvalid   <= 'b0;
      reg_rx_tready   <= 'b0;
      reg_rx_tkeep    <= 'b0;
    end else begin
      reg_tx_tdata    <= s_axis_tx_tdata;
      reg_tx_tkeep    <= s_axis_tx_tkeep;
      reg_tx_tlast    <= s_axis_tx_tlast;
      reg_tx_tvalid   <= s_axis_tx_tvalid;
      reg_tx_tready   <= s_axis_tx_tready;

      reg_rx_tdata    <= m_axis_rx_tdata;
      reg_rx_tkeep    <= m_axis_rx_tkeep;
      reg_rx_tlast    <= m_axis_rx_tlast;
      reg_rx_tvalid   <= m_axis_rx_tvalid;
      reg_rx_tready   <= m_axis_rx_tready;
    end
  end

  // destination address     (6 bytes) +
  // source address          (6 bytes) +
  // type/len                (2 bytes) +
  // payload                 (n bytes) +
  // fcs is handled by MAC   (0 bytes)
  // Subtract 14 bytes of header to get payload byte count 
  
  // Logic to calculate tx byte count 
  always @(posedge clk)
  begin
    // Reset byte count every second
    if (reset == 1'b1 || running_test_time == 'h0) 
      tx_byte_count_int     <= 'h0;
    // Count all bytes when a transaction is active
    // At the end of the packet substract the 14 bytes of header
    else  if (reg_tx_tvalid == 1'b1 && reg_tx_tready == 1'b1 && reg_tx_tlast == 1'b1)  
      tx_byte_count_int <= tx_byte_count_int + tx_keep_cnt - 14;
    else if (reg_tx_tvalid == 1'b1 && reg_tx_tready == 1'b1) 
      tx_byte_count_int <= tx_byte_count_int + AXIS_TKEEP_WIDTH;
  end 

  assign tx_keep_cnt = (AXIS_TDATA_WIDTH == 64) ? reg_tx_tkeep[0] +  reg_tx_tkeep[1] + 
                                                  reg_tx_tkeep[2] +  reg_tx_tkeep[3] +
                                                  reg_tx_tkeep[4] +  reg_tx_tkeep[5] + 
                                                  reg_tx_tkeep[6] +  reg_tx_tkeep[7] 
                                                : reg_tx_tkeep[0] +  reg_tx_tkeep[1] +
                                                  reg_tx_tkeep[2] +  reg_tx_tkeep[3] ;

  // Logic to calculate rx byte count 
  always @(posedge clk)
  begin
    // Reset byte count every second
    if (reset == 1'b1 || running_test_time == 'h0) 
      rx_byte_count_int     <= 'h0;
    // Count all bytes when a transaction is active
    // At the end of the packet substract the 14 bytes of header
    else if (reg_rx_tvalid == 1'b1 && reg_rx_tready == 1'b1 && reg_rx_tlast == 1'b1) 
      rx_byte_count_int <= rx_byte_count_int + rx_keep_cnt - 14;
    else if (reg_rx_tvalid == 1'b1 && reg_rx_tready == 1'b1) 
      rx_byte_count_int <= rx_byte_count_int + AXIS_TKEEP_WIDTH;
  end 


  assign rx_keep_cnt = (AXIS_TDATA_WIDTH == 64) ? reg_rx_tkeep[0] +  reg_rx_tkeep[1] + 
                                                  reg_rx_tkeep[2] +  reg_rx_tkeep[3] +
                                                  reg_rx_tkeep[4] +  reg_rx_tkeep[5] + 
                                                  reg_rx_tkeep[6] +  reg_rx_tkeep[7] 
                                                : reg_rx_tkeep[0] +  reg_rx_tkeep[1] +
                                                  reg_rx_tkeep[2] +  reg_rx_tkeep[3] ;
  

  // Logic to calculate tx pkt count 
  always @(posedge clk)
  begin
    // Reset pkt count every second
    if (reset == 1'b1 || running_test_time == 'h0) 
      tx_pkt_count_int     <= 'h0;
    // At the end of the packet increment packet count
    else  if (reg_tx_tvalid == 1'b1 && reg_tx_tready == 1'b1 && reg_tx_tlast == 1'b1)  
      tx_pkt_count_int <= tx_pkt_count_int + 1;
  end 

  // Logic to calculate rx pkt count 
  always @(posedge clk)
  begin
    // Reset pkt count every second
    if (reset == 1'b1 || running_test_time == 'h0) 
      rx_pkt_count_int     <= 'h0;
    // At the end of the packet increment packet count
    else  if (reg_rx_tvalid == 1'b1 && reg_rx_tready == 1'b1 && reg_rx_tlast == 1'b1)  
      rx_pkt_count_int <= rx_pkt_count_int + 1;
  end 


// Keep track of time during test
always @(posedge clk)
begin: TIMER_PROC
   if (reset == 1'b1) begin
       running_test_time <= 'h0;
       sample_cnt <= 'h0;
   end else if (running_test_time == 'h0) begin
       running_test_time <= one_second_cnt;
       sample_cnt <= sample_cnt + 1'b1;
   end else begin
       running_test_time <= running_test_time - 1'b1;
       sample_cnt <= sample_cnt;
   end
end

// Concatenate sample_cnt with byte count/pkt count at end of sample period (1 second)
always @(posedge clk)
begin: COPY_PROC
   if (reset == 1'b1) begin
      tx_byte_count     <= 'h0;
      rx_byte_count     <= 'h0;
      tx_pkt_count      <= 'h0;
      rx_pkt_count      <= 'h0;
   end else if (running_test_time == 'h0) begin
      tx_byte_count     <= {tx_byte_count_int[31:2], sample_cnt};
      rx_byte_count     <= {rx_byte_count_int[31:2], sample_cnt};
      tx_pkt_count      <= {tx_pkt_count_int[31:2], sample_cnt};
      rx_pkt_count      <= {rx_pkt_count_int[31:2], sample_cnt};
   end
end


endmodule

