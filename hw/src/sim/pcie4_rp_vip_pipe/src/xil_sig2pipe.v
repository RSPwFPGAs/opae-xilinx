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
// File       : xil_sig2pipe.v
// Version    : 4.1
//-----------------------------------------------------------------------------
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
  //-- LF & FS values are 40 & 15 decimal
  //-- RP should provide TX preset hint of 5 (in EQ TS2's before changing rate to Gen3)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module xil_sig2pipe
(
 
  output [83:0]  xil_rx0_sigs,
  output [83:0]  xil_rx1_sigs,
  output [83:0]  xil_rx2_sigs,
  output [83:0]  xil_rx3_sigs,
  output [83:0]  xil_rx4_sigs,
  output [83:0]  xil_rx5_sigs,
  output [83:0]  xil_rx6_sigs,
  output [83:0]  xil_rx7_sigs,
  input  [16:0]  xil_common_commands,
  input  [69:0]  xil_tx0_sigs,
  input  [69:0]  xil_tx1_sigs,
  input  [69:0]  xil_tx2_sigs,
  input  [69:0]  xil_tx3_sigs,
  input  [69:0]  xil_tx4_sigs,
  input  [69:0]  xil_tx5_sigs,
  input  [69:0]  xil_tx6_sigs,
  input  [69:0]  xil_tx7_sigs,
  
  // Pipe Interface - Common
  
  output         pipe_clk,
  output [1:0]   pipe_tx_rate,
  output         pipe_tx_detect_rx,
  output [15:0]  pipe_tx_powerdown,
  
  // Pipe Interface - TX
 
  output [31:0]  pipe_tx0_data,
  output [31:0]  pipe_tx1_data,
  output [31:0]  pipe_tx2_data,
  output [31:0]  pipe_tx3_data,
  output [31:0]  pipe_tx4_data,
  output [31:0]  pipe_tx5_data,
  output [31:0]  pipe_tx6_data,
  output [31:0]  pipe_tx7_data,
  
  output  [1:0]  pipe_tx0_char_is_k,
  output  [1:0]  pipe_tx1_char_is_k,
  output  [1:0]  pipe_tx2_char_is_k,
  output  [1:0]  pipe_tx3_char_is_k,
  output  [1:0]  pipe_tx4_char_is_k,
  output  [1:0]  pipe_tx5_char_is_k,
  output  [1:0]  pipe_tx6_char_is_k,
  output  [1:0]  pipe_tx7_char_is_k,
  
  output         pipe_tx0_elec_idle,
  output         pipe_tx1_elec_idle,
  output         pipe_tx2_elec_idle,
  output         pipe_tx3_elec_idle,
  output         pipe_tx4_elec_idle,
  output         pipe_tx5_elec_idle,
  output         pipe_tx6_elec_idle,
  output         pipe_tx7_elec_idle,
  
  output         pipe_tx0_start_block,
  output         pipe_tx1_start_block,
  output         pipe_tx2_start_block,
  output         pipe_tx3_start_block,
  output         pipe_tx4_start_block,
  output         pipe_tx5_start_block,
  output         pipe_tx6_start_block,
  output         pipe_tx7_start_block,
  
  output  [1:0]  pipe_tx0_syncheader,
  output  [1:0]  pipe_tx1_syncheader,
  output  [1:0]  pipe_tx2_syncheader,
  output  [1:0]  pipe_tx3_syncheader,
  output  [1:0]  pipe_tx4_syncheader,
  output  [1:0]  pipe_tx5_syncheader,
  output  [1:0]  pipe_tx6_syncheader,
  output  [1:0]  pipe_tx7_syncheader,
  
  output         pipe_tx0_data_valid,
  output         pipe_tx1_data_valid,
  output         pipe_tx2_data_valid,
  output         pipe_tx3_data_valid,
  output         pipe_tx4_data_valid,
  output         pipe_tx5_data_valid,
  output         pipe_tx6_data_valid,
  output         pipe_tx7_data_valid,

  // Pipe Interface - RX
  
  input  [31:0]  pipe_rx0_data,
  input  [31:0]  pipe_rx1_data,
  input  [31:0]  pipe_rx2_data,
  input  [31:0]  pipe_rx3_data,
  input  [31:0]  pipe_rx4_data,
  input  [31:0]  pipe_rx5_data,
  input  [31:0]  pipe_rx6_data,
  input  [31:0]  pipe_rx7_data,
  
  input   [1:0]  pipe_rx0_char_is_k,
  input   [1:0]  pipe_rx1_char_is_k,
  input   [1:0]  pipe_rx2_char_is_k,
  input   [1:0]  pipe_rx3_char_is_k,
  input   [1:0]  pipe_rx4_char_is_k,
  input   [1:0]  pipe_rx5_char_is_k,
  input   [1:0]  pipe_rx6_char_is_k,
  input   [1:0]  pipe_rx7_char_is_k,
  
  input          pipe_rx0_elec_idle,
  input          pipe_rx1_elec_idle,
  input          pipe_rx2_elec_idle,
  input          pipe_rx3_elec_idle,
  input          pipe_rx4_elec_idle,
  input          pipe_rx5_elec_idle,
  input          pipe_rx6_elec_idle,
  input          pipe_rx7_elec_idle,

  input          pipe_rx0_start_block,
  input          pipe_rx1_start_block,
  input          pipe_rx2_start_block,
  input          pipe_rx3_start_block,
  input          pipe_rx4_start_block,
  input          pipe_rx5_start_block,
  input          pipe_rx6_start_block,
  input          pipe_rx7_start_block,
  
  input   [1:0]  pipe_rx0_syncheader,
  input   [1:0]  pipe_rx1_syncheader,
  input   [1:0]  pipe_rx2_syncheader,
  input   [1:0]  pipe_rx3_syncheader,
  input   [1:0]  pipe_rx4_syncheader,
  input   [1:0]  pipe_rx5_syncheader,
  input   [1:0]  pipe_rx6_syncheader,
  input   [1:0]  pipe_rx7_syncheader,
      
  input          pipe_rx0_data_valid,
  input          pipe_rx1_data_valid,
  input          pipe_rx2_data_valid,
  input          pipe_rx3_data_valid,
  input          pipe_rx4_data_valid,
  input          pipe_rx5_data_valid,
  input          pipe_rx6_data_valid,
  input          pipe_rx7_data_valid
);

   assign pipe_clk          = xil_common_commands[0];
   assign pipe_tx_rate      = xil_common_commands[2:1];
   assign pipe_tx_detect_rx = xil_common_commands[3];
   assign pipe_tx_powerdown = {xil_tx7_sigs[41:40],xil_tx6_sigs[41:40],xil_tx5_sigs[41:40],xil_tx4_sigs[41:40],
                               xil_tx3_sigs[41:40],xil_tx2_sigs[41:40],xil_tx1_sigs[41:40],xil_tx0_sigs[41:40]};
   
  //------------------------------------------------------------------------------//
  // RX PIPE to RX INT BUS 
  //------------------------------------------------------------------------------//

   assign xil_rx0_sigs = {45'b0,pipe_rx0_syncheader,pipe_rx0_start_block,
                            pipe_rx0_data_valid,pipe_rx0_elec_idle,pipe_rx0_char_is_k,pipe_rx0_data}; 
                            
   assign xil_rx1_sigs = {45'b0,pipe_rx1_syncheader,pipe_rx1_start_block,
                            pipe_rx1_data_valid,pipe_rx1_elec_idle,pipe_rx1_char_is_k,pipe_rx1_data}; 
                            
   assign xil_rx2_sigs = {45'b0,pipe_rx2_syncheader,pipe_rx2_start_block,
                            pipe_rx2_data_valid,pipe_rx2_elec_idle,pipe_rx2_char_is_k,pipe_rx2_data}; 
                            
   assign xil_rx3_sigs = {45'b0,pipe_rx3_syncheader,pipe_rx3_start_block,
                            pipe_rx3_data_valid,pipe_rx3_elec_idle,pipe_rx3_char_is_k,pipe_rx3_data}; 
                            
   assign xil_rx4_sigs = {45'b0,pipe_rx4_syncheader,pipe_rx4_start_block,
                            pipe_rx4_data_valid,pipe_rx4_elec_idle,pipe_rx4_char_is_k,pipe_rx4_data}; 
                            
   assign xil_rx5_sigs = {45'b0,pipe_rx5_syncheader,pipe_rx5_start_block,
                            pipe_rx5_data_valid,pipe_rx5_elec_idle,pipe_rx5_char_is_k,pipe_rx5_data}; 
                            
   assign xil_rx6_sigs = {45'b0,pipe_rx6_syncheader,pipe_rx6_start_block,
                            pipe_rx6_data_valid,pipe_rx6_elec_idle,pipe_rx6_char_is_k,pipe_rx6_data}; 
                            
   assign xil_rx7_sigs = {45'b0,pipe_rx7_syncheader,pipe_rx7_start_block,
                            pipe_rx7_data_valid,pipe_rx7_elec_idle,pipe_rx7_char_is_k,pipe_rx7_data}; 
  //------------------------------------------------------------------------------//
  // TX INT BUS to TX PIPE 
  //------------------------------------------------------------------------------//
   assign pipe_tx0_data        = xil_tx0_sigs[31: 0] ; 
   assign pipe_tx0_char_is_k   = xil_tx0_sigs[33:32] ;
   assign pipe_tx0_elec_idle   = xil_tx0_sigs[34]    ; 
   assign pipe_tx0_data_valid  = xil_tx0_sigs[35] ; 
   assign pipe_tx0_start_block = xil_tx0_sigs[36] ; 
   assign pipe_tx0_syncheader  = xil_tx0_sigs[38:37] ; 
   
   assign pipe_tx1_data        = xil_tx1_sigs[31: 0] ; 
   assign pipe_tx1_char_is_k   = xil_tx1_sigs[33:32] ;
   assign pipe_tx1_elec_idle   = xil_tx1_sigs[34]    ; 
   assign pipe_tx1_data_valid  = xil_tx1_sigs[35] ; 
   assign pipe_tx1_start_block = xil_tx1_sigs[36] ; 
   assign pipe_tx1_syncheader  = xil_tx1_sigs[38:37] ;

   assign pipe_tx2_data        = xil_tx2_sigs[31: 0] ; 
   assign pipe_tx2_char_is_k   = xil_tx2_sigs[33:32] ;
   assign pipe_tx2_elec_idle   = xil_tx2_sigs[34]    ; 
   assign pipe_tx2_data_valid  = xil_tx2_sigs[35] ; 
   assign pipe_tx2_start_block = xil_tx2_sigs[36] ; 
   assign pipe_tx2_syncheader  = xil_tx2_sigs[38:37] ; 
   
   assign pipe_tx3_data        = xil_tx3_sigs[31: 0] ; 
   assign pipe_tx3_char_is_k   = xil_tx3_sigs[33:32] ;
   assign pipe_tx3_elec_idle   = xil_tx3_sigs[34]    ; 
   assign pipe_tx3_data_valid  = xil_tx3_sigs[35] ; 
   assign pipe_tx3_start_block = xil_tx3_sigs[36] ; 
   assign pipe_tx3_syncheader  = xil_tx3_sigs[38:37] ;
   
   assign pipe_tx4_data        = xil_tx4_sigs[31: 0] ; 
   assign pipe_tx4_char_is_k   = xil_tx4_sigs[33:32] ;
   assign pipe_tx4_elec_idle   = xil_tx4_sigs[34]    ; 
   assign pipe_tx4_data_valid  = xil_tx4_sigs[35] ; 
   assign pipe_tx4_start_block = xil_tx4_sigs[36] ; 
   assign pipe_tx4_syncheader  = xil_tx4_sigs[38:37] ; 
   
   assign pipe_tx5_data        = xil_tx5_sigs[31: 0] ; 
   assign pipe_tx5_char_is_k   = xil_tx5_sigs[33:32] ;
   assign pipe_tx5_elec_idle   = xil_tx5_sigs[34]    ; 
   assign pipe_tx5_data_valid  = xil_tx5_sigs[35] ; 
   assign pipe_tx5_start_block = xil_tx5_sigs[36] ; 
   assign pipe_tx5_syncheader  = xil_tx5_sigs[38:37] ;   
   
   assign pipe_tx6_data        = xil_tx6_sigs[31: 0] ; 
   assign pipe_tx6_char_is_k   = xil_tx6_sigs[33:32] ;
   assign pipe_tx6_elec_idle   = xil_tx6_sigs[34]    ; 
   assign pipe_tx6_data_valid  = xil_tx6_sigs[35] ; 
   assign pipe_tx6_start_block = xil_tx6_sigs[36] ; 
   assign pipe_tx6_syncheader  = xil_tx6_sigs[38:37] ; 
   
   assign pipe_tx7_data        = xil_tx7_sigs[31: 0] ; 
   assign pipe_tx7_char_is_k   = xil_tx7_sigs[33:32] ;
   assign pipe_tx7_elec_idle   = xil_tx7_sigs[34]    ; 
   assign pipe_tx7_data_valid  = xil_tx7_sigs[35] ; 
   assign pipe_tx7_start_block = xil_tx7_sigs[36] ; 
   assign pipe_tx7_syncheader  = xil_tx7_sigs[38:37] ; 

endmodule

   
