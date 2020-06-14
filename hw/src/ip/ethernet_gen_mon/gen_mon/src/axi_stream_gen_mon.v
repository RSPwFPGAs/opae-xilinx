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

module axi_stream_gen_mon #(
    parameter        AXIS_TDATA_WIDTH    =  64,
    parameter [47:0] XIL_MAC_ID_THIS     =  48'h111100000000, // 00:00:00:00:11:11
    parameter [47:0] XIL_MAC_ID_OTHER    =  48'h222200000000, // 00:00:00:00:22:22
    parameter [47:0] EXT_MAC_ID          =  48'h333300000000, // 00:00:00:00:33:33
    parameter        S_AXI_ADDR_WIDTH    =  32,
    parameter        S_AXI_DATA_WIDTH    =  32,
    parameter [15:0] S_AXI_MIN_SIZE      =  16'hFFFF,
    parameter [31:0] S_AXI_BASE_ADDRESS  =  32'h44A0_0000,
    // Design information
    // 0105 - Targeting KCU105 board
    // 141  - Viavdo 2014.1 
    // 1    - Ethernet Reference Design 1
    parameter [31:0] DESIGN_VERSION      =  32'h0105_1431,
    // one second timer in terms of 156.25 MHz clock
    parameter ONE_SEC_CLOCK_COUNT =  32'h9502F90
)
(
    // Slave AXI-Lite Interface for register
    // reads and writes
    input                             s_axi_clk,
    input                             s_axi_areset_n,
    input  [S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input                             s_axi_awvalid,
    output                            s_axi_awready,
    input  [S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  [(S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                             s_axi_wvalid,
    output                            s_axi_wready,
    output [1:0]                      s_axi_bresp,
    output                            s_axi_bvalid,
    input                             s_axi_bready,
    input  [S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input                             s_axi_arvalid,
    output                            s_axi_arready,
    output [S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output [1:0]                      s_axi_rresp,
    output                            s_axi_rvalid,
    input                             s_axi_rready,
    
    input  [47:0]                     tg_config,

    // AXI Stream Interface
    // Connects to the Ethernet MAC
    input                             axis_reset_n,
    input                             axis_clk,             
   
    input [AXIS_TDATA_WIDTH-1:0]      rx_axis_tdata,
    input [(AXIS_TDATA_WIDTH/8)-1:0]  rx_axis_tkeep,
    input                             rx_axis_tvalid,
    input                             rx_axis_tlast,
    input                             rx_axis_tuser,
    output                            rx_axis_tready,

    output [AXIS_TDATA_WIDTH-1:0]     tx_axis_tdata,
    output [(AXIS_TDATA_WIDTH/8)-1:0]  tx_axis_tkeep,
    output                            tx_axis_tvalid,
    output                            tx_axis_tlast,
    output                            tx_axis_tuser,
    input                             tx_axis_tready,
    
    //Other status signals
    input  [7:0]                      phy_status      


);
    localparam          AXIS_TKEEP_WIDTH    =  AXIS_TDATA_WIDTH/8;   
    localparam [31:0]   S_AXI_HIGH_ADDRESS  =  S_AXI_BASE_ADDRESS + S_AXI_MIN_SIZE;
    
    wire  [AXIS_TDATA_WIDTH-1:0]     tx_axis_tdata_g;
    wire  [AXIS_TKEEP_WIDTH-1:0]     tx_axis_tkeep_g;
    wire                             tx_axis_tvalid_g;
    wire                             tx_axis_tlast_g;
    wire                             tx_axis_tuser_g;
 

    wire  [AXIS_TDATA_WIDTH-1:0]     tx_axis_tdata_lb;
    wire  [AXIS_TKEEP_WIDTH-1:0]     tx_axis_tkeep_lb;
    wire                             tx_axis_tvalid_lb;
    wire                             tx_axis_tlast_lb;
    wire                             tx_axis_tuser_lb;

    wire                             rx_axis_tready_lb;

    wire                             enable_loopback;
    wire                             enable_gen;
    wire  [15:0]                     data_payload;
    wire  [15:0]                     packet_count;
    wire  [31:0]                     tx_byte_count;
    wire  [31:0]                     rx_byte_count;
    wire  [31:0]                     tx_pkt_count;
    wire  [31:0]                     rx_pkt_count;
    wire                             lb_dropped_packet;
    wire                             enable_loopback_sync;
    wire                             enable_gen_sync;
    wire  [15:0]                     data_payload_sync;
    wire  [15:0]                     packet_count_sync;
    wire  [31:0]                     tx_byte_count_sync;
    wire  [31:0]                     rx_byte_count_sync;
    wire  [31:0]                     tx_pkt_count_sync;
    wire  [31:0]                     rx_pkt_count_sync;
    wire                             lb_dropped_pkt_sync;
    wire  [7:0]                      phy_status_sync;
 `ifdef OOB_SIM  
    wire                             enable_loopback_sim;
    wire                             enable_gen_sim;
    wire  [15:0]                     data_payload_sim;
    wire  [15:0]                     packet_count_sim;
 `endif
    
 
 // If running a simulation drive the traffic configuration
 // via the tg_config input signal else drive it via the
 // user_registers_slave block.
 // This is done to speed up simulation, simulating the microblaze
 // subsystem (with the UART) which drives the S_AXI interface
 // will take very long.
 `ifdef OOB_SIM  
    assign  enable_loopback_sim = tg_config[0];
    assign  enable_gen_sim      = tg_config[1];
    assign  data_payload_sim    = tg_config[31:16];
    assign  packet_count_sim    = tg_config[47:32];
 `endif


   // External Traffic generator - looopback on the MAC side
   // Send received data as transmit data
  axi_stream_lb # (
    .AXIS_TDATA_WIDTH     (AXIS_TDATA_WIDTH       ),
    .AXIS_TKEEP_WIDTH     (AXIS_TKEEP_WIDTH       ),
    .XIL_MAC_ID_THIS      (XIL_MAC_ID_THIS        ),
    .EXT_MAC_ID           (EXT_MAC_ID             )
  )  
  axi_stream_lb_i (

     .reset               (!axis_reset_n          ),
     .tx_axis_clk         (axis_clk               ),
     .tx_axis_tdata       (tx_axis_tdata_lb       ),
     .tx_axis_tkeep       (tx_axis_tkeep_lb       ),
     .tx_axis_tvalid      (tx_axis_tvalid_lb      ),
     .tx_axis_tlast       (tx_axis_tlast_lb       ),
     .tx_axis_tuser       (tx_axis_tuser_lb       ),
     .tx_axis_tready      (tx_axis_tready         ),
     .rx_axis_tdata       (rx_axis_tdata          ),
     .rx_axis_tkeep       (rx_axis_tkeep          ),
     .rx_axis_tvalid      (rx_axis_tvalid         ),
     .rx_axis_tlast       (rx_axis_tlast          ),
     .rx_axis_tuser       (rx_axis_tuser          ),
     .rx_axis_tready      (rx_axis_tready_lb      ),
     .lb_dropped_packet   (lb_dropped_packet      ),
   `ifdef OOB_SIM  
     .enable_loopback     (enable_loopback_sim    )
   `else 
    .enable_loopback      (enable_loopback_sync   )
   `endif
  );
    
  // FPGA Traffic generator - looopback on the PHY side
  // Generate transmit data
  axi_stream_gen # (
    .AXIS_TDATA_WIDTH     (AXIS_TDATA_WIDTH       ),
    .AXIS_TKEEP_WIDTH     (AXIS_TKEEP_WIDTH       ),
    .XIL_MAC_ID_THIS      (XIL_MAC_ID_THIS        ),
    .XIL_MAC_ID_OTHER     (XIL_MAC_ID_OTHER       )
  )  
  axi_stream_gen_i (

     .reset               (!axis_reset_n          ),
     .tx_axis_clk         (axis_clk               ),
     .tx_axis_tdata       (tx_axis_tdata_g        ),
     .tx_axis_tkeep       (tx_axis_tkeep_g        ),
     .tx_axis_tvalid      (tx_axis_tvalid_g       ),
     .tx_axis_tlast       (tx_axis_tlast_g        ),
     .tx_axis_tuser       (tx_axis_tuser_g        ),
     .tx_axis_tready      (tx_axis_tready         ),
   `ifdef OOB_SIM  
     .enable_gen          (enable_gen_sim         ),
     .data_payload        (data_payload_sim       ),
     .packet_count        (packet_count_sim       )
   `else 
     .enable_gen          (enable_gen_sync        ),
     .data_payload        (data_payload_sync      ),
     .packet_count        (packet_count_sync      )
   `endif

  );

  // If enable_loopback is asserted, axi_stream_lb drives the transmit data
  // Otherwise axi_stream_gen block drives the transmit data 
   `ifdef OOB_SIM  
      assign tx_axis_tdata  = enable_loopback_sim ?  tx_axis_tdata_lb  : tx_axis_tdata_g;
      assign tx_axis_tkeep  = enable_loopback_sim ?  tx_axis_tkeep_lb  : tx_axis_tkeep_g;
      assign tx_axis_tvalid = enable_loopback_sim ?  tx_axis_tvalid_lb : tx_axis_tvalid_g;
      assign tx_axis_tlast  = enable_loopback_sim ?  tx_axis_tlast_lb  : tx_axis_tlast_g;
      assign tx_axis_tuser  = enable_loopback_sim ?  tx_axis_tuser_lb  : tx_axis_tuser_g;
      assign rx_axis_tready = enable_loopback_sim ?  rx_axis_tready_lb : 1'b1;
   `else 
      assign tx_axis_tdata  = enable_loopback ?  tx_axis_tdata_lb  : tx_axis_tdata_g;
      assign tx_axis_tkeep  = enable_loopback ?  tx_axis_tkeep_lb  : tx_axis_tkeep_g;
      assign tx_axis_tvalid = enable_loopback ?  tx_axis_tvalid_lb : tx_axis_tvalid_g;
      assign tx_axis_tlast  = enable_loopback ?  tx_axis_tlast_lb  : tx_axis_tlast_g;
      assign tx_axis_tuser  = enable_loopback ?  tx_axis_tuser_lb  : tx_axis_tuser_g;
      assign rx_axis_tready = enable_loopback ?  rx_axis_tready_lb : 1'b1;

   `endif


  eth_performance_monitor # (
    .AXIS_TDATA_WIDTH     (AXIS_TDATA_WIDTH       ),
    .AXIS_TKEEP_WIDTH     (AXIS_TKEEP_WIDTH       ),
    .ONE_SEC_CLOCK_COUNT  ('h9502F90              )
  )  
  eth_performance_monitor_i (
     .reset               (!axis_reset_n          ),
     .clk                 (axis_clk               ),
     .s_axis_tx_tdata     (tx_axis_tdata          ),
     .s_axis_tx_tkeep     (tx_axis_tkeep          ),
     .s_axis_tx_tlast     (tx_axis_tlast          ),
     .s_axis_tx_tvalid    (tx_axis_tvalid         ),
     .s_axis_tx_tready    (tx_axis_tready         ),
     .m_axis_rx_tdata     (rx_axis_tdata          ),
     .m_axis_rx_tkeep     (rx_axis_tkeep          ),
     .m_axis_rx_tlast     (rx_axis_tlast          ),
     .m_axis_rx_tvalid    (rx_axis_tvalid         ),
     .m_axis_rx_tready    (rx_axis_tready         ),
     .tx_byte_count       (tx_byte_count          ),
     .rx_byte_count       (rx_byte_count          ),
     .tx_pkt_count        (tx_pkt_count           ),
     .rx_pkt_count        (rx_pkt_count           )
  );



  user_registers_slave # (
    .C_S_AXI_ADDR_WIDTH   (S_AXI_ADDR_WIDTH       ),
    .C_S_AXI_DATA_WIDTH   (S_AXI_DATA_WIDTH       ),
    .C_S_AXI_MIN_SIZE     (S_AXI_MIN_SIZE         ),
    .C_BASE_ADDRESS       (S_AXI_BASE_ADDRESS     ),
    .C_HIGH_ADDRESS       (S_AXI_HIGH_ADDRESS     ),
    .DESIGN_VERSION       (DESIGN_VERSION         )  
  )  
  user_reg_slave_i (
    .s_axi_clk            (s_axi_clk              ),
    .s_axi_areset_n       (s_axi_areset_n         ),
    .s_axi_awaddr         (s_axi_awaddr           ),
    .s_axi_awready        (s_axi_awready          ),
    .s_axi_awvalid        (s_axi_awvalid          ),
    .s_axi_wdata          (s_axi_wdata            ),
    .s_axi_wstrb          (s_axi_wstrb            ),
    .s_axi_wvalid         (s_axi_wvalid           ),
    .s_axi_wready         (s_axi_wready           ),
    .s_axi_bresp          (s_axi_bresp            ),
    .s_axi_bvalid         (s_axi_bvalid           ),
    .s_axi_bready         (s_axi_bready           ),
    .s_axi_araddr         (s_axi_araddr           ),
    .s_axi_arvalid        (s_axi_arvalid          ),
    .s_axi_arready        (s_axi_arready          ),
    .s_axi_rdata          (s_axi_rdata            ),
    .s_axi_rresp          (s_axi_rresp            ),
    .s_axi_rvalid         (s_axi_rvalid           ),
    .s_axi_rready         (s_axi_rready           ),

     //Registers
     // Inputs
    .tx_byte_count        (tx_byte_count_sync     ),
    .rx_byte_count        (rx_byte_count_sync     ),
    .tx_pkt_count         (tx_pkt_count_sync      ),
    .rx_pkt_count         (rx_pkt_count_sync      ),
    .phy_status           (phy_status_sync        ),  
    .lb_dropped_packet    (lb_dropped_pkt_sync    ),
        
    // Outputs
    .enable_loopback      (enable_loopback        ),
    .enable_gen           (enable_gen             ),
    .data_payload         (data_payload           ),
    .packet_count         (packet_count           )

  );


  sync_registers  sync_registers_i
  (

    .s_axi_clk            (s_axi_clk              ),
    .axis_clk             (axis_clk               ),

     // Inputs
    .tx_byte_count        (tx_byte_count          ),
    .rx_byte_count        (rx_byte_count          ),
    .tx_pkt_count         (tx_pkt_count           ),
    .rx_pkt_count         (rx_pkt_count           ),
    .phy_status           (phy_status             ),  
    .lb_dropped_packet    (lb_dropped_packet      ),
    .enable_loopback      (enable_loopback        ),
    .enable_gen           (enable_gen             ),
    .data_payload         (data_payload           ),
    .packet_count         (packet_count           ),
        
    // Outputs
    .tx_byte_count_sync   (tx_byte_count_sync     ),
    .rx_byte_count_sync   (rx_byte_count_sync     ),
    .tx_pkt_count_sync    (tx_pkt_count_sync      ),
    .rx_pkt_count_sync    (rx_pkt_count_sync      ),
    .phy_status_sync      (phy_status_sync        ),  
    .lb_dropped_pkt_sync  (lb_dropped_pkt_sync    ),
    .enable_loopback_sync (enable_loopback_sync   ),
    .enable_gen_sync      (enable_gen_sync        ),
    .data_payload_sync    (data_payload_sync      ),
    .packet_count_sync    (packet_count_sync      )

  );

endmodule
