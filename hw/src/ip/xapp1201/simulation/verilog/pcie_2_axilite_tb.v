`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2013 07:16:07 PM
// Design Name: 
// Module Name: pcie_2_axilite_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcie_2_axilite_tb(

    );

  localparam  C_DATA_WIDTH                        = 256;        // RX/TX interface data width (valid options 64, 128, 256)
  localparam  KEEP_WIDTH                          = C_DATA_WIDTH / 32;
  localparam  TCQ                                 = 1;
  localparam  BAR0AXI                             = 32'h40000000;
  localparam  BAR1AXI                             = 32'h10000000;
  localparam  BAR2AXI                             = 32'h20000000;
  localparam  BAR3AXI                             = 32'h30000000;
  localparam  BAR4AXI                             = 32'h40000000;
  localparam  BAR5AXI                             = 32'h50000000;
  localparam  BAR0SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  BAR1SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  BAR2SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  BAR3SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  BAR4SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  BAR5SIZE                            = 64'hFFFF_FFFF_FFFF_FF80;
  localparam  throttle_percent                    = 50;


  wire [31:0]              m00_axi_awaddr;
  wire                     m00_axi_awvalid;
  wire                     awvalid_throttle;
  wire                     m00_axi_awready;
  wire                     awready_throttle;
  wire [2:0]               m00_axi_awprot;

  
  wire [31:0]              m00_axi_wdata;      // input [31 : 0] s_axi_wdata
  wire [3:0]               m00_axi_wstrb;      // input [3 : 0] s_axi_wstrb
  wire                     m00_axi_wvalid;     // input s_axi_wvalid
  wire                     m00_axi_wready;     // output s_axi_wready
  
  wire [1:0]               m00_axi_bresp;      // output [1 : 0] s_axi_bresp
  wire                     m00_axi_bvalid;     // output s_axi_bvalid
  wire                     m00_axi_bready;    // input s_axi_bready
  
  wire [31:0]              m00_axi_araddr;    // input [31 : 0] s_axi_araddr
  wire                     m00_axi_arvalid;   // input s_axi_arvalid
  wire                     arvalid_throttle;   // input s_axi_arvalid
  wire                     m00_axi_arready;   // output s_axi_arready
  wire                     arready_throttle;   // output s_axi_arready
  wire [2:0]               m00_axi_arprot;    // output m00_axi_arprot
  
  wire [31:0]              m00_axi_rdata;      // output [31 : 0] s_axi_rdata
  wire [1:0]               m00_axi_rresp;      // output [1 : 0] s_axi_rresp
  wire                     m00_axi_rvalid;     // output s_axi_rvalid
  wire                     m00_axi_rready;     // input s_axi_rready

  wire                 [C_DATA_WIDTH-1:0]    m_axis_cq_tdata;
  wire                            [84:0]     m_axis_cq_tuser;
  wire                                       m_axis_cq_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_cq_tkeep;
  wire                                       m_axis_cq_tvalid;
  wire                             [21:0]    m_axis_cq_tready;

  wire                 [C_DATA_WIDTH-1:0]    s_axis_cc_tdata;
  wire                             [32:0]    s_axis_cc_tuser;
  wire                                       s_axis_cc_tlast;
  wire                   [KEEP_WIDTH-1:0]    s_axis_cc_tkeep;
  wire                                       s_axis_cc_tvalid;
  reg                               [3:0]    s_axis_cc_tready;
  
  

  reg  [63:0] tmp_address_rd;
  reg  [63:0] tmp_address_wr;
  wire [63:0] descriptor_cq;
  
  
  wire [2:0] attr = 3'h0;               // Not used by bridge
  wire [2:0] traffic_class = 3'h0;      // Not used by bridge
  wire [5:0] bar_aperature = 6'd0;      // Size of the BAR - Not used by the bridge
  reg  [2:0] bar_id;                    // The BAR Hit
  wire [7:0] target_func = 8'd0;        // Function Number 
  reg  [7:0] tag;                       // TAG of TLP
  wire [15:0] requester_id =  16'h10EE; // Requester ID 
  reg  [3:0] req_type;                  // Request Type: 0 = mem read, 1 = mem write.  Others are not supported.
  reg [10:0] dword_count = 11'd1;      // DWORD Count in TLP fixed to 1
  reg [3:0] first_be = 4'hF;      // DWORD Count in TLP fixed to 1  

  localparam BAR0SIZE_INT                 = get_size( BAR0SIZE );
  localparam BAR1SIZE_INT                 = get_size( BAR1SIZE );
  localparam BAR2SIZE_INT                 = get_size( BAR2SIZE );
  localparam BAR3SIZE_INT                 = get_size( BAR3SIZE );
  localparam BAR4SIZE_INT                 = get_size( BAR4SIZE );
  localparam BAR5SIZE_INT                 = get_size( BAR5SIZE );
  

   parameter PERIOD = 10;
   reg user_clk;
   reg reset_n;
   
   reg [C_DATA_WIDTH-1:0] completion_data [1:0];
   
   always @(posedge user_clk)
     if (s_axis_cc_tvalid & s_axis_cc_tready[0]) begin
      completion_data[0]  <= completion_data[1];
      completion_data[1]  <= s_axis_cc_tdata;
     end

   
   initial begin
     forever begin
       @(posedge user_clk) begin
         if (s_axis_cc_tvalid & s_axis_cc_tready[0] & s_axis_cc_tlast) begin
           if ( C_DATA_WIDTH == 64 ) begin
             #1 $display ("%g Lower Address = %h, Tag = %h, Data = %h", $time, completion_data[0][7:0], completion_data[1][7:0], completion_data[1][63:32] );
           end else if (  C_DATA_WIDTH == 128  ) begin
             #1 $display ("%g Lower Address = %h, Tag = %h, Data = %h", $time, completion_data[1][7:0], completion_data[1][7+64:0+64], completion_data[1][63+64:32+64] );
           end else if (  C_DATA_WIDTH == 256  ) begin
             #1 $display ("%g Lower Address = %h, Tag = %h, Data = %h", $time, completion_data[1][7:0], completion_data[1][7+64:0+64], completion_data[1][63+64:32+64] );
           end
         end        
       end      
     end
   end

   initial begin
      user_clk = 1'b0;
      #(PERIOD/2);
      forever
         #(PERIOD/2) user_clk = ~user_clk;
   end  


      
   initial begin 
     reset_n = 1'b0;
     #(PERIOD * 200);
     reset_n = 1'b1;
     $display("Reset Deasserted");
     forever
         #(PERIOD/2) s_axis_cc_tready = {4{( throttle_percent > ($random %100))}};            
   end

  pcie_2_axilite # (  
    .AXIS_TDATA_WIDTH  (C_DATA_WIDTH), 
  	.M_AXI_TDATA_WIDTH   (32),
  	.RELAXED_ORDERING    ("FALSE"),
  	.BAR2AXI0_TRANSLATION            ( BAR0AXI ),
    .BAR2AXI1_TRANSLATION            ( BAR1AXI ),  
    .BAR2AXI2_TRANSLATION            ( BAR2AXI ),                
    .BAR2AXI3_TRANSLATION            ( BAR3AXI ),      
    .BAR2AXI4_TRANSLATION            ( BAR4AXI ),                   
    .BAR2AXI5_TRANSLATION            ( BAR5AXI ),
    .BAR0SIZE           ( BAR0SIZE ),
    .BAR1SIZE           ( BAR1SIZE ),
    .BAR2SIZE           ( BAR2SIZE ),
    .BAR3SIZE           ( BAR3SIZE ),
    .BAR4SIZE           ( BAR4SIZE ),
    .BAR5SIZE           ( BAR5SIZE )  	 	
  	)  pcie_2_axilite ( 
    
    .axi_clk                                        ( user_clk ),
    .axi_aresetn                                    ( reset_n ),
    
    .s_axis_cq_tdata                                ( m_axis_cq_tdata ),
    .s_axis_cq_tuser                                ( m_axis_cq_tuser ),
    .s_axis_cq_tlast                                ( m_axis_cq_tlast ),
    .s_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
    .s_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
    .s_axis_cq_tready                               ( m_axis_cq_tready ),

    .m_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .m_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .m_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .m_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .m_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .m_axis_cc_tready                               ( s_axis_cc_tready ),
    
    .m_axi_awaddr                                   ( m00_axi_awaddr ),
    .m_axi_awprot                                   ( m00_axi_awprot ),
    .m_axi_awvalid                                  ( m00_axi_awvalid ),
    .m_axi_awready                                  ( m00_axi_awready ),
     
    .m_axi_wdata                                    ( m00_axi_wdata ),
    .m_axi_wstrb                                    ( m00_axi_wstrb ),
    .m_axi_wvalid                                   ( m00_axi_wvalid ),
    .m_axi_wready                                   ( m00_axi_wready ),
    
    .m_axi_bresp                                    ( m00_axi_bresp ),
    .m_axi_bvalid                                   ( m00_axi_bvalid ),
    .m_axi_bready                                   ( m00_axi_bready ),
                                       
    .m_axi_araddr                                   ( m00_axi_araddr ),
    .m_axi_arprot                                   ( m00_axi_arprot ),
    .m_axi_arvalid                                  ( m00_axi_arvalid ),
    .m_axi_arready                                  ( m00_axi_arready ),
                                       
    .m_axi_rdata                                    ( m00_axi_rdata ),
    .m_axi_rresp                                    ( m00_axi_rresp ),
    .m_axi_rvalid                                   ( m00_axi_rvalid ),
    .m_axi_rready                                   ( m00_axi_rready ) 
    );


blk_mem_gen_0 axi_bram (
  .s_aclk(user_clk),                // input s_aclk
  .s_aresetn( reset_n ),          // input s_aresetn
  
  .s_axi_awaddr(m00_axi_awaddr),    // input [31 : 0] s_axi_awaddr
  .s_axi_awvalid(m00_axi_awvalid), // input s_axi_awvalid
  .s_axi_awready(m00_axi_awready),  // output s_axi_awready
  
  .s_axi_wdata(m00_axi_wdata),      // input [31 : 0] s_axi_wdata
  .s_axi_wstrb(m00_axi_wstrb),      // input [3 : 0] s_axi_wstrb
  .s_axi_wvalid(m00_axi_wvalid),    // input s_axi_wvalid
  .s_axi_wready(m00_axi_wready),    // output s_axi_wready
  
  .s_axi_bresp(m00_axi_bresp),      // output [1 : 0] s_axi_bresp
  .s_axi_bvalid(m00_axi_bvalid),    // output s_axi_bvalid
  .s_axi_bready(m00_axi_bready),    // input s_axi_bready
  
  .s_axi_araddr(m00_axi_araddr),    // input [31 : 0] s_axi_araddr
  .s_axi_arvalid(m00_axi_arvalid),  // input s_axi_arvalid
  .s_axi_arready(m00_axi_arready),  // output s_axi_arready
  
  .s_axi_rdata(m00_axi_rdata),      // output [31 : 0] s_axi_rdata
  .s_axi_rresp(m00_axi_rresp),      // output [1 : 0] s_axi_rresp
  .s_axi_rvalid(m00_axi_rvalid),    // output s_axi_rvalid
  .s_axi_rready(m00_axi_rready)    // input s_axi_rready
);
   

  function integer get_size ( [63:0] size );
    integer ii; 
    for ( ii = 5; ii <= 63; ii= ii + 1) begin
       if ( (size[ii] == 1'b1) & (size[ii-1] == 1'b0)) begin 
         get_size = 2; 
       end
    end      
  endfunction
  
  cq_axis_stimulus #(
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .PERIOD(PERIOD),
    .TCQ(TCQ)
  ) cq_axis_stimulus_i (
  .user_clk(user_clk),
  .reset_n(reset_n),
  .m_axis_cq_tdata(m_axis_cq_tdata),
  .m_axis_cq_tuser(m_axis_cq_tuser),
  .m_axis_cq_tlast(m_axis_cq_tlast),
  .m_axis_cq_tkeep(m_axis_cq_tkeep),
  .m_axis_cq_tvalid(m_axis_cq_tvalid),
  .m_axis_cq_tready(m_axis_cq_tready)
    );
   
endmodule
