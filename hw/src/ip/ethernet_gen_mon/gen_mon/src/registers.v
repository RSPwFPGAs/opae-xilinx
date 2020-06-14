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

module registers #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32
) (
    //-IPIC Interface

  input      [ADDR_WIDTH-1:0]   Bus2IP_Addr,
  input                         Bus2IP_RNW,
  input                         Bus2IP_CS,
  input      [DATA_WIDTH-1:0]   Bus2IP_Data,
  output reg [DATA_WIDTH-1:0]   IP2Bus_Data,
  output reg                    IP2Bus_WrAck,
  output reg                    IP2Bus_RdAck,
  output                        IP2Bus_Error,
    //- User registers
  input      [31:0]             reg_00,
  input      [31:0]             reg_04,
  input      [31:0]             reg_08,
  input      [31:0]             reg_0C,
  input      [31:0]             reg_10,
  output reg [31:0]             reg_14 = 32'h007D_0000,
  input      [31:0]             reg_18,
  output reg [31:0]             reg_1C = 32'h0000_0000,

    //- System signals
  input                         Clk,
  input                         Resetn
);

  //- Address offset definitions
  localparam [15:0] 
      ADDR_reg_00           = 16'h0000,
      ADDR_reg_04           = 16'h0004,
      ADDR_reg_08           = 16'h0008,
      ADDR_reg_0C           = 16'h000C,
      ADDR_reg_10           = 16'h0010,
      ADDR_reg_14           = 16'h0014,
      ADDR_reg_18           = 16'h0018,
      ADDR_reg_1C           = 16'h001C;

  assign IP2Bus_Error = 1'b0;

 /*                                                          
  * On the assertion of CS, RNW port is checked for read or a write
  * transaction. 
  * In case of a write transaction, the relevant register is written to and
  * WrAck generated.
  * In case of reads, the read data along with RdAck is generated.
  */
 
  always @(posedge Clk)
    if (Resetn == 1'b0) 
    begin
      IP2Bus_WrAck  <= 1'b0;
      IP2Bus_RdAck  <= 1'b0;
    end
    else
    begin
        //- Write transaction
      if (Bus2IP_CS & ~Bus2IP_RNW)
      begin
          case (Bus2IP_Addr[15:0])
            ADDR_reg_14   : reg_14 <= Bus2IP_Data;
            ADDR_reg_1C   : reg_1C <= Bus2IP_Data;
          endcase
          IP2Bus_WrAck  <= 1'b1;
          IP2Bus_Data   <= 32'd0;
          IP2Bus_RdAck  <= 1'b0;  
      end
        //- Read transaction
      else if (Bus2IP_CS & Bus2IP_RNW)
      begin
          case (Bus2IP_Addr[15:0])
            ADDR_reg_00  : IP2Bus_Data <= reg_00;
            ADDR_reg_04  : IP2Bus_Data <= reg_04;
            ADDR_reg_08  : IP2Bus_Data <= reg_08;
            ADDR_reg_0C  : IP2Bus_Data <= reg_0C;
            ADDR_reg_10  : IP2Bus_Data <= reg_10;
            ADDR_reg_14  : IP2Bus_Data <= reg_14;
            ADDR_reg_18  : IP2Bus_Data <= reg_18;
            ADDR_reg_1C  : IP2Bus_Data <= reg_1C;
            default      : IP2Bus_Data <= 32'b0;
          endcase
          IP2Bus_RdAck  <= 1'b1;
          IP2Bus_WrAck  <= 1'b0;
      end
      else
      begin
        IP2Bus_Data   <= 32'd0;
        IP2Bus_WrAck  <= 1'b0;
        IP2Bus_RdAck  <= 1'b0;
      end
    end
  
endmodule
