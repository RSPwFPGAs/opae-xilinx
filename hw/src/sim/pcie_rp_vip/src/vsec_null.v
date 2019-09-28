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
// Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
// File       : vsec_null.v
// Version    : 4.4 
//-----------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module vsec_null # (
  // PCIe Extended Capabilty parameters
  // This parameter should be the offset of this capability.
  // The first extended capability should be at offset 12'h400
  parameter [11:0] EXT_CONFIG_BASE_ADDRESS = 12'h400,
  // This parameter is the byte-lenth of the PCIe extended capability
  // and should include the lenght of the header registers
  parameter [11:0] EXT_CONFIG_CAP_LENGTH = 12'h010,
  // This parameter should be 12'h000 to terminate the capability chain or
  // the address of the next capability.
  parameter [11:0] EXT_CONFIG_NEXT_CAP = 12'h000,
  // fields for the PCIE_VSEC_ID and PCIE_VSEC_REV_ID are defined
  // by the vendor and should be qualified by the PCIe-Vendor-ID (Xilinx = 0x10EE),
  // PCIe-Device-ID, PCIe-Revision-ID, PCIe-Subsystem-Vendor-ID, PCIe-Subsystem-ID, 
  // PCIE-Extended Capability-ID (0x000b), and PCIe-Extended-Capability-Revision-ID
  // (0x0) prior to interpretation.
  parameter [15:0] PCIE_VSEC_ID = 16'h0000,
  parameter [3:0] PCIE_VSEC_REV = 4'h0               
)(

  // Control signals
  input wire clk,
  // This module should not be reset by anything other than a through a
  // control regiser within the VSEC.

  // PCIe Extended Capability Interface signals
  input wire read_received,
  input wire write_received,
  input wire [9:0] register_number,
  input wire [7:0] function_number,
  input wire [31:0] write_data,
  input wire [3:0] write_byte_enable,   
  output reg [31:0] read_data = 32'h00000000,
  output reg read_data_valid = 1'b0,

  // IO to and from the user design.
  input wire [31:0] status_reg_in,
  output wire [31:0] control_reg_out
);

  // Register map for this PCIe extended capability
  // PCIe extended capability addresses are given as the word offset from the
  // EXT_CONFIG_BASE_ADDRESS (not byte offset)
  //               <Register name>     <register offset>                   <offest from base address>
  localparam [9:0] PCIE_EXT_CAP_ADDR = EXT_CONFIG_BASE_ADDRESS[11:2] + 0;  // 0x00
  localparam [9:0] PCIE_VSEC_ADDR    = EXT_CONFIG_BASE_ADDRESS[11:2] + 1;  // 0x04
  localparam [9:0] VSEC_STATUS_ADDR  = EXT_CONFIG_BASE_ADDRESS[11:2] + 2;  // 0x08
  localparam [9:0] VSEC_CONTROL_ADDR = EXT_CONFIG_BASE_ADDRESS[11:2] + 3;  // 0x0C

  // fields for the PCIE_EXT_CAP_ADDR register. A PCIe VSEC is specified with an
  // PCIE_EXP_CAP_ID=16'h000B and PCIE_EXT_CAP_VER=4'h1 as per the PCIe specification
  localparam [15:0] PCIE_EXP_CAP_ID = 16'h000B;
  localparam [3:0] PCIE_EXT_CAP_VER = 4'h1;

  // Register/Wire declarations
  // This header field and values are defined by the PCIe specification for a VSEC
  wire [31:0] pcie_ext_cap_header = {EXT_CONFIG_NEXT_CAP, PCIE_EXT_CAP_VER, PCIE_EXP_CAP_ID};
  // This header field is defined by the PCIe specification, but values are defined by
  // the vendor.
  wire [31:0] pcie_vsec_header = {EXT_CONFIG_CAP_LENGTH, PCIE_VSEC_REV, PCIE_VSEC_ID};
  // This register will be read-only and can be used to report system status. For this 
  // case this register reports the value present in the control register.
  reg  [31:0] pcie_status_reg = 32'h00000000;
  // This register is read-write and can be used for controlling the system or status
  // register in this case.
  reg  [31:0] pcie_control_reg = 32'h04030201;

  wire reg_read_enable;
  wire reg_write_enable;

  // Add function_number filtering HERE if desired.
  // Currently this is implemented for all functions.
  // Assign the input and output signals
  assign read_en = read_received;
  assign write_en = write_received;
  assign control_reg_out = pcie_control_reg;
  // register the data on the status register input.
  always @(posedge clk) begin
    pcie_status_reg <= status_reg_in;
  end

  // Register Read logic and output registers.
  always @ (posedge clk) begin
    if (read_en) begin
      case (register_number)
        PCIE_EXT_CAP_ADDR: begin
            read_data <= pcie_ext_cap_header;
            read_data_valid <= 1'b1;
        end
        PCIE_VSEC_ADDR: begin
            read_data <= pcie_vsec_header;
            read_data_valid <= 1'b1;
        end
        VSEC_STATUS_ADDR: begin
            read_data <= pcie_status_reg;
            read_data_valid <= 1'b1;
        end
        VSEC_CONTROL_ADDR: begin
            read_data <= pcie_control_reg;
            read_data_valid <= 1'b1;
        end
        default: begin
            read_data <= 31'b0000000;
            read_data_valid <= 1'b0;
        end             
      endcase
    end else begin
      read_data <= 31'b0000000;
      read_data_valid <= 1'b0;
    end
  end
        
  // Register Write logic
  always @ (posedge clk) begin
    if (write_en) begin
      case (register_number)
        // PCIE_EXT_CAP_ADDR is not writable
        // PCIE_VSEC_ADDR is not writable
        // VSEC_STATUS_ADDR is not writable
        VSEC_CONTROL_ADDR: begin
            pcie_control_reg[7:0]   <= write_byte_enable[0] ? write_data[7:0]   : pcie_control_reg[7:0];
            pcie_control_reg[15:8]  <= write_byte_enable[1] ? write_data[15:8]  : pcie_control_reg[15:8];
            pcie_control_reg[23:16] <= write_byte_enable[2] ? write_data[23:16] : pcie_control_reg[23:16];
            pcie_control_reg[31:24] <= write_byte_enable[3] ? write_data[31:24] : pcie_control_reg[31:24];
        end
        default:
          pcie_control_reg <= pcie_control_reg;
      endcase
    end else
      pcie_control_reg <= pcie_control_reg;
  end

endmodule
