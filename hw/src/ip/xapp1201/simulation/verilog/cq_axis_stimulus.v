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


module cq_axis_stimulus# (
  parameter  C_DATA_WIDTH                        = 64,        // RX/TX interface data width 
  parameter  KEEP_WIDTH                          = C_DATA_WIDTH / 32,
  parameter  PERIOD                              = 10, 
  parameter  TCQ                                 = 1         
    )(
  input                                         user_clk,
  input                                         reset_n,
  output reg                 [C_DATA_WIDTH-1:0] m_axis_cq_tdata,
  output                              [84:0]    m_axis_cq_tuser,
  output reg                                    m_axis_cq_tlast,
  output reg                   [KEEP_WIDTH-1:0] m_axis_cq_tkeep,
  output reg                                    m_axis_cq_tvalid,
  input                               [21:0]    m_axis_cq_tready
    );

  localparam throttle_percent = 50;


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
  reg [10:0] dword_count = 11'd1;       // DWORD Count in TLP fixed to 1
  reg [3:0] first_be = 4'hF;            // DWORD Count in TLP fixed to 1
  reg [3:0] last_be  = 4'h0;            // DWORD Count in TLP fixed to 1
  reg [31:0] byte_en = 32'd0;
  reg sop = 1'b0;
  
  
   
  assign descriptor_cq = {1'b0, attr, traffic_class, bar_aperature, bar_id, target_func, tag, requester_id, 1'b0, req_type, dword_count};
  assign m_axis_cq_tuser = { 43'd0, sop, byte_en, last_be, first_be};

      

   
   
  task write_byte_enable_test;
    input integer count;
    input [63:0] base_address;
    input [63:0] base_data;
    
      integer cnt;
      reg [ 63:0 ] address;
      reg [ 63:0 ] data;
    begin  
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        data = base_data + cnt;
        pcie_write( address , data, cnt[3:0] , C_DATA_WIDTH );
      end
      $display("Byte Enable Test Completed");      
    end
  endtask

  task write_bad;
    input integer count;
    input [63:0] base_address;
    input [63:0] base_data;
    
      integer cnt;
      reg [ 63:0 ] address;
      reg [ 63:0 ] data;
    begin 
      dword_count <= 11'd2; 
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        data = base_data + cnt;
        pcie_write( address , data, 4'hF, C_DATA_WIDTH);
      end 
      dword_count <= 11'd1;      
    end
  endtask

  task write_seq;
    input integer count;
    input [63:0] base_address;
    input [63:0] base_data;
    
      integer cnt;
      reg [ 63:0 ] address;
      reg [ 63:0 ] data;
    begin  
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        data = base_data + cnt;
        pcie_write( address , data, 4'hF, C_DATA_WIDTH);
      end      
    end
  endtask

  task read_seq;
    input integer count;
    input [63:0] base_address;
    
      integer cnt;
      reg [ 63:0 ] address;
    begin  
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        pcie_read( address , C_DATA_WIDTH );
        repeat(10) @(posedge user_clk);
      end      
    end
  endtask

  task read_bad;
    input integer count;
    input [63:0] base_address;
    
      integer cnt;
      reg [ 63:0 ] address;
    begin  
      dword_count <= 11'd2; 
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        pcie_read( address , C_DATA_WIDTH );
      end 
      dword_count <= 11'd1;      
    end
  endtask

  task read_write_interleave;
    input integer count;
    input [63:0] base_address;
    input [63:0] base_data;
    
      integer cnt;
      reg [ 63:0 ] data;
      reg [ 63:0 ] address;
    begin  
      for ( cnt = 0 ; cnt < count ; cnt = cnt + 1) begin
        address = base_address + 4*cnt;
        data = base_data + cnt;
        pcie_write( address, data, 4'hF , C_DATA_WIDTH  );
        pcie_read( address,  C_DATA_WIDTH );       
      end      
    end
  endtask

  task pcie_read;      
    //TLP Data
    input [63:0] address;
    input integer axis_datawidth;
    reg throttle;
     
    begin 
      $display ("%g CPU Read  task with address : %h on CQ interface", $time, address);
      
      if ( axis_datawidth == 64 ) begin
        req_type <= #TCQ 3'd0;
        sop      <= #TCQ 1'b1;
        @ (negedge user_clk);
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ address;
        m_axis_cq_tkeep  <=  #TCQ 2'b11;
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end      
        while ( !m_axis_cq_tready ) begin        
          @ (posedge user_clk);
        end 
        

        throttle <=  ( throttle_percent > ($random %100));
        while (throttle) begin
          m_axis_cq_tvalid <= #TCQ 1'b0; 
          @ (posedge user_clk);    
          throttle <=  ( throttle_percent > ($random %100));
        end
              
        m_axis_cq_tdata  <=  #TCQ descriptor_cq;
        m_axis_cq_tkeep  <=  #TCQ 2'b11;
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        sop              <=  #TCQ 1'b0;
        @ (negedge user_clk);
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end 
        while ( !m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end 
        
        //@ (posedge user_clk); 
        m_axis_cq_tvalid <=  #TCQ 1'b0;
        m_axis_cq_tlast  <=  #TCQ 1'b0;  
        tag              <=  #TCQ tag + 1;
        m_axis_cq_tkeep  <=  #TCQ 2'b00;
        
      end else if ( axis_datawidth == 128 ) begin
        req_type <= 3'd0;
        @ (negedge user_clk);
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ {descriptor_cq, address} ;
        m_axis_cq_tkeep  <=  #TCQ 4'hF;
        sop              <=  #TCQ 1'b1;
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end      
        while ( !m_axis_cq_tready ) begin        
          @ (posedge user_clk);
        end 
        
        m_axis_cq_tvalid <=  #TCQ 1'b0;
        m_axis_cq_tlast  <=  #TCQ 1'b0;  
        tag              <=  #TCQ tag + 1;
        sop              <=  #TCQ 1'b0;
        m_axis_cq_tkeep  <=  #TCQ 4'h0;
        
              
      end else if ( axis_datawidth == 256 ) begin
        req_type <= 3'd0;
        @ (negedge user_clk);
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ {128'd0, descriptor_cq, address} ;
        m_axis_cq_tkeep  <=  #TCQ 8'h0F;
        sop              <=  #TCQ 1'b1;
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end      
        while ( !m_axis_cq_tready ) begin        
          @ (posedge user_clk);
        end 
        
        //@ (posedge user_clk); 
        m_axis_cq_tvalid <=  #TCQ 1'b0;
        m_axis_cq_tlast  <=  #TCQ 1'b0;  
        tag              <=  #TCQ tag + 1;
        sop              <=  #TCQ 1'b0;
        m_axis_cq_tkeep  <=  #TCQ 8'h00;
      end              
    end    
  endtask

  task pcie_write;      
    //TLP Data
    input [63:0] address;
    input [63:0] payload;
    input [3:0]  first_be_i;
    input integer axis_datawidth;
    
    reg throttle;
     
    begin 
      $display ("%g CPU Write Data: %h  to address : %h on CQ interface", $time, payload, address);
      
      if ( axis_datawidth == 64 ) begin
        req_type <= 3'd1;
        @ (negedge user_clk);

        first_be         <=  #TCQ first_be_i;
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ address; 
        m_axis_cq_tkeep  <=  #TCQ 2'b11; 
        sop              <=  #TCQ 1'b1;   
        //@ (negedge user_clk); 
        if ( m_axis_cq_tready[0] ) begin
          @ (posedge user_clk);
        end       
        while ( !m_axis_cq_tready[0] ) begin        
          @ (posedge user_clk);        
        end 
        

        throttle <=  ( throttle_percent > ($random %100));
        while (throttle) begin
          m_axis_cq_tvalid <= #TCQ 1'b0; 
          @ (posedge user_clk);    
          throttle <=  ( throttle_percent > ($random %100));
        end
                    
        m_axis_cq_tdata  <=  #TCQ descriptor_cq;
        m_axis_cq_tkeep  <=  #TCQ 2'b11;
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        sop              <=  #TCQ 1'b0; 
        @ (negedge user_clk); 
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end    
        while ( !m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end 


        throttle <=  ( throttle_percent > ($random %100));
        while (throttle) begin
          m_axis_cq_tvalid <= #TCQ 1'b0; 
          @ (posedge user_clk);    
          throttle <=  ( throttle_percent > ($random %100));
        end        
         
        m_axis_cq_tdata  <=  #TCQ payload;
        m_axis_cq_tkeep  <=  #TCQ 2'b01;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        m_axis_cq_tvalid <=  #TCQ 1'b1;  
        @ (negedge user_clk); 
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end    
        while ( !m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end 
        m_axis_cq_tvalid <=  #TCQ 1'b0; 
        m_axis_cq_tkeep  <=  #TCQ 2'b00;
        m_axis_cq_tlast  <=  #TCQ 1'b0;
        tag              <=  #TCQ tag + 1; 
                        
      end else if ( axis_datawidth == 128 ) begin
        req_type <= 3'd1;
        @ (negedge user_clk);
        first_be         <=  #TCQ first_be_i;
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ {descriptor_cq, address};
        m_axis_cq_tkeep  <=  #TCQ 4'hF; 
        sop              <=  #TCQ 1'b1;    
        //@ (negedge user_clk); 
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end       
        while ( !m_axis_cq_tready ) begin        
          @ (posedge user_clk);        
        end    
             

        throttle <=  ( 50 > ($random %100));
        while (throttle) begin
          m_axis_cq_tvalid <= #TCQ 1'b0; 
          @ (posedge user_clk);    
          throttle <=  ( 50 > ($random %100));
        end
                 
        m_axis_cq_tdata  <=  #TCQ {96'h00000000, payload[31:0]};
        m_axis_cq_tkeep  <=  #TCQ 4'h1;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        m_axis_cq_tvalid <=  #TCQ 1'b1;  
        sop              <=  #TCQ 1'b1;
        @ (negedge user_clk); 
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end    
        while ( !m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end 
        m_axis_cq_tvalid <=  #TCQ 1'b0; 
        m_axis_cq_tlast  <=  #TCQ 1'b0;
        tag              <=  #TCQ tag + 1; 
        sop              <=  #TCQ 1'b0;
        m_axis_cq_tkeep  <=  #TCQ 0;
      
      end else if ( axis_datawidth == 256 ) begin
        req_type <= 3'd1;
        @ (negedge user_clk);
        first_be         <=  #TCQ first_be_i;
        m_axis_cq_tvalid <=  #TCQ 1'b1;
        m_axis_cq_tlast  <=  #TCQ 1'b1;
        m_axis_cq_tdata  <=  #TCQ { 64'd0, payload[63:0], descriptor_cq, address};
        m_axis_cq_tkeep  <=  #TCQ 8'h1F;
        sop              <=  #TCQ 1'b1;     
        //@ (negedge user_clk); 
        if ( m_axis_cq_tready ) begin
          @ (posedge user_clk);
        end       
        while ( !m_axis_cq_tready ) begin        
          @ (posedge user_clk);        
        end         
          
        m_axis_cq_tvalid <=  #TCQ 1'b0; 
        m_axis_cq_tlast  <=  #TCQ 1'b0;
        m_axis_cq_tkeep  <=  #TCQ 0;
        tag              <=  #TCQ tag + 1;
        sop              <=  #TCQ 1'b0; 
      end               
    
    end    
  endtask 





  initial begin 
     
     m_axis_cq_tvalid <= 0;
     m_axis_cq_tkeep  <= 0;
     m_axis_cq_tlast  <= 0;
     m_axis_cq_tdata  <= 0;
     tmp_address_wr   <= 64'h0000000000000000;
     tmp_address_rd   <= 64'h0000000000000000;
     bar_id           <= 3'b000;
     tag              <= 8'd0;
     dword_count      <= 11'd1;
     
     @(posedge reset_n) ; 
     // write, read 1DW
     #(PERIOD * 200);
     first_be <= 4'hF;
     last_be  <= 4'h0;
     dword_count      <= 11'd1;
     write_seq ( 5, tmp_address_wr, 64'h00000000_00000000 );
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'h0;
     dword_count      <= 11'd1;
     read_seq ( 5, tmp_address_rd );
     #(PERIOD * 20);
     
     //write, read 2DW
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'hF;
     dword_count      <= 11'd2;
     write_seq ( 5, tmp_address_wr, 64'h11223344_01020304 );
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'hF;
     dword_count      <= 11'd2;
     read_seq ( 5, tmp_address_rd );
     #(PERIOD * 20);
     // read 1DW
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'h0;
     dword_count      <= 11'd1;
     read_seq ( 5, tmp_address_rd );
     #(PERIOD * 20);
     // read 2DW
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'hF;
     dword_count      <= 11'd2;
     read_seq ( 5, tmp_address_rd );
     #(PERIOD * 20);
     
     //read_write_interleave (100, tmp_address_wr, 64'h00000000_01000000 );
     #(PERIOD * 20);
     first_be <= 4'hF;
     last_be  <= 4'h0;
     dword_count      <= 11'd1;
     write_byte_enable_test ( 5, tmp_address_wr, 64'h00000000_12345678 );
     //read_seq ( 20, tmp_address_rd );
     
   end
   
endmodule
