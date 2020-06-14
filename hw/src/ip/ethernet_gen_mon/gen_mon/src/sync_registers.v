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

//-----------------------------------------------------------------------------
// MODULE 
//-----------------------------------------------------------------------------

module sync_registers 
 (
    input                               s_axi_clk,
    input                               axis_clk,
    
    input  [31:0]                       tx_byte_count,
    input  [31:0]                       rx_byte_count,
    input  [31:0]                       tx_pkt_count,
    input  [31:0]                       rx_pkt_count,
    input  [7:0]                        phy_status,
    input                               lb_dropped_packet,
    input                               enable_loopback,
    input                               enable_gen,
    input  [15:0]                       data_payload,
    input  [15:0]                       packet_count,
    
    output  [31:0]                      tx_byte_count_sync,
    output  [31:0]                      rx_byte_count_sync,
    output  [31:0]                      tx_pkt_count_sync,
    output  [31:0]                      rx_pkt_count_sync,
    output  [7:0]                       phy_status_sync,
    output                              lb_dropped_pkt_sync,
    output                              enable_loopback_sync,
    output                              enable_gen_sync,
    output  [15:0]                      data_payload_sync,
    output  [15:0]                      packet_count_sync

);

  synchronizer_simple # (
    .DATA_WIDTH           (32                     )
  )
  sync_tx_byte_count (
    .data_in               (tx_byte_count          ),
    .new_clk               (s_axi_clk              ),
    .data_out              (tx_byte_count_sync     )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (32                     )
  )
  sync_rx_byte_count (
    .data_in               (rx_byte_count          ),
    .new_clk               (s_axi_clk              ),
    .data_out              (rx_byte_count_sync     )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (32                     )
  )
  sync_tx_pkt_count (
    .data_in               (tx_pkt_count           ),
    .new_clk               (s_axi_clk              ),
    .data_out              (tx_pkt_count_sync      )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (32                     )
  )
  sync_rx_pkt_count (
    .data_in               (rx_pkt_count           ),
    .new_clk               (s_axi_clk              ),
    .data_out              (rx_pkt_count_sync      )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (8                      )
  )
  sync_phy_status (
    .data_in               (phy_status             ),
    .new_clk               (s_axi_clk              ),
    .data_out              (phy_status_sync        )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (1                      )
  )
  sync_lb_dropped_pkt (
    .data_in               (lb_dropped_packet      ),
    .new_clk               (s_axi_clk              ),
    .data_out              (lb_dropped_pkt_sync    )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (1                      )
  )
  sync_enable_loopback (
    .data_in               (enable_loopback        ),
    .new_clk               (axis_clk               ),
    .data_out              (enable_loopback_sync   )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (1                      )
  )
  sync_enable_gen (
    .data_in               (enable_gen             ),
    .new_clk               (axis_clk               ),
    .data_out              (enable_gen_sync        )
  );  

  synchronizer_simple # (
    .DATA_WIDTH           (16                     )
  )
  sync_data_payload (
    .data_in               (data_payload           ),
    .new_clk               (axis_clk               ),
    .data_out              (data_payload_sync      )
  );  
  synchronizer_simple # (
    .DATA_WIDTH           (16                     )
  )
  sync_packet_count (
    .data_in               (packet_count           ),
    .new_clk               (axis_clk               ),
    .data_out              (packet_count_sync      )
  );  
endmodule
