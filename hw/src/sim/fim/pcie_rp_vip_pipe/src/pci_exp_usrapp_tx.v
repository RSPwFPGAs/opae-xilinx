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
// Project    : AXI-MM to PCI Express
// File       : pci_exp_usrapp_tx.v
// Version    : $IpVersion 
//-----------------------------------------------------------------------------
//--------------------------------------------------------------------------------

`include "board_common.vh"

module pci_exp_usrapp_tx #(
  parameter        ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter        ATTR_AXISTEN_IF_RQ_PARITY_CHECK   = 0,
  parameter        ATTR_AXISTEN_IF_CC_PARITY_CHECK   = 0,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE      = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE      = "FALSE",

  parameter        DEV_CAP_MAX_PAYLOAD_SUPPORTED     = 1,
  parameter        C_DATA_WIDTH                      = 256,
  parameter        KEEP_WIDTH                        = C_DATA_WIDTH / 32,
  parameter        STRB_WIDTH                        = C_DATA_WIDTH / 8,
  parameter        [3:0]  LINK_CAP_MAX_LINK_WIDTH_EP = 4'h8,
  parameter        [2:0]  LINK_CAP_MAX_LINK_SPEED_EP = 3'h2,
  parameter        EP_DEV_ID                         = 16'h09c4,//16'h7700,
  parameter        REM_WIDTH                         = ((C_DATA_WIDTH == 256) ? 3 : ((C_DATA_WIDTH == 128) ? 2 : 1))
)
(
  output reg                                 s_axis_rq_tlast,
  output reg      [C_DATA_WIDTH-1:0]         s_axis_rq_tdata,
  output reg      [59:0]                     s_axis_rq_tuser,
  output reg      [KEEP_WIDTH-1:0]           s_axis_rq_tkeep,
  input                                      s_axis_rq_tready,
  output reg                                 s_axis_rq_tvalid,

  output reg      [C_DATA_WIDTH-1:0]         s_axis_cc_tdata,
  output reg      [32:0]                     s_axis_cc_tuser,
  output reg                                 s_axis_cc_tlast,
  output reg      [KEEP_WIDTH-1:0]           s_axis_cc_tkeep,
  output reg                                 s_axis_cc_tvalid,
  input                                      s_axis_cc_tready,

  input           [3:0]                      pcie_rq_seq_num,
  input                                      pcie_rq_seq_num_vld,
  input           [5:0]                      pcie_rq_tag,
  input                                      pcie_rq_tag_vld,

  input           [1:0]                      pcie_tfc_nph_av,
  input           [1:0]                      pcie_tfc_npd_av,
//\\------------------------------------------------------
  input                                      speed_change_done_n,
//\\------------------------------------------------------
  input                                      user_clk,
  input                                      reset,
  input                                      user_lnk_up
);

parameter    Tcq = 1;

                               
localparam   [3:0] MAX_LINK_SPEED = (LINK_CAP_MAX_LINK_SPEED_EP==3'h4) ? 4'h3 : ((LINK_CAP_MAX_LINK_SPEED_EP==3'h2) ? 4'h2 : 4'h1);


reg        [(C_DATA_WIDTH - 1):0]            pcie_tlp_data;
reg        [(REM_WIDTH - 1):0]               pcie_tlp_rem;


/* Local Variables */

integer                         i, j, k;
reg     [7:0]                   DATA_STORE [4095:0];
reg     [31:0]                  ADDRESS_32_L;
reg     [31:0]                  ADDRESS_32_H;
reg     [63:0]                  ADDRESS_64;
reg     [15:0]                  EP_BUS_DEV_FNS;
reg     [15:0]                  RP_BUS_DEV_FNS;
reg     [2:0]                   DEFAULT_TC;
reg     [9:0]                   DEFAULT_LENGTH;
reg     [3:0]                   DEFAULT_BE_LAST_DW;
reg     [3:0]                   DEFAULT_BE_FIRST_DW;
reg     [1:0]                   DEFAULT_ATTR;
reg     [7:0]                   DEFAULT_TAG;
reg     [3:0]                   DEFAULT_COMP;
reg     [11:0]                  EXT_REG_ADDR;
reg                             TD;
reg                             EP;
reg     [15:0]                  VENDOR_ID;
reg     [9:0]                   LENGTH;         // For 1DW config and IO transactions
reg     [9:0]                   CFG_DWADDR;

event                           test_begin;

reg     [31:0]                  P_ADDRESS_MASK;
reg     [31:0]                  P_READ_DATA;      // will store the 1st DW (lo) of a PCIE read completion
reg     [31:0]                  P_READ_DATA_2;    // will store the 2nd DW (hi) of a PCIE read completion
reg                             P_READ_DATA_VALID;
reg     [31:0]                  P_WRITE_DATA;
reg     [31:0]                  data;

reg                             error_check;
reg                             set_malformed;

// BAR Init variables
reg     [32:0]                  BAR_INIT_P_BAR[6:0];           // 6 corresponds to Expansion ROM
                                                               // note that bit 32 is for overflow checking
reg     [31:0]                  BAR_INIT_P_BAR_RANGE[6:0];     // 6 corresponds to Expansion ROM
reg     [1:0]                   BAR_INIT_P_BAR_ENABLED[6:0];   // 6 corresponds to Expansion ROM
//                              0 = disabled;  1 = io mapped;  2 = mem32 mapped;  3 = mem64 mapped

reg     [31:0]                  BAR_INIT_P_MEM64_HI_START;     // start address for hi memory space
reg     [31:0]                  BAR_INIT_P_MEM64_LO_START;     // start address for hi memory space
reg     [32:0]                  BAR_INIT_P_MEM32_START;        // start address for low memory space
                                                               // top bit used for overflow indicator
reg     [32:0]                  BAR_INIT_P_IO_START;           // start address for io space
reg     [100:0]                 BAR_INIT_MESSAGE[3:0];         // to be used to display info to user

reg     [32:0]                  BAR_INIT_TEMP;

reg                             OUT_OF_LO_MEM;                 // flags to indicate out of mem, mem64, and io
reg                             OUT_OF_IO;
reg                             OUT_OF_HI_MEM;

integer                         NUMBER_OF_IO_BARS;
integer                         NUMBER_OF_MEM32_BARS;          // Not counting the Mem32 EROM space
integer                         NUMBER_OF_MEM64_BARS;

reg     [3:0]                   ii;
integer                         jj;

reg     [31:0]                  DEV_VEN_ID;                    // holds device and vendor id
integer                         PIO_MAX_NUM_BLOCK_RAMS;        // holds the max number of block RAMS
reg     [31:0]                  PIO_MAX_MEMORY;

reg                             pio_check_design; // boolean value to check PCI Express BAR configuration against
                                                  // limitations of PIO design. Setting this to true will cause the
                                                  // testbench to check if the core has been configured for more than
                                                  // one IO space, one general purpose Mem32 space (not counting
                                                  // the Mem32 EROM space), and one Mem64 space.

reg                             cpld_to;          // boolean value to indicate if time out has occured while waiting for cpld
reg                             cpld_to_finish;   // boolean value to indicate to $finish on cpld_to

reg                             verbose;          // boolean value to display additional info to stdout

wire                            user_lnk_up_n;
wire    [31:0]                  s_axis_cc_tparity;
wire    [31:0]                  s_axis_rq_tparity;

reg     [255:0]                 testname;
integer                         test_vars [31:0];
reg     [7:0]                   exp_tag;
reg     [7:0]                   expect_cpld_payload [4095:0];
reg     [7:0]                   expect_msgd_payload [4095:0];
reg     [7:0]                   expect_memwr_payload [4095:0];
reg     [7:0]                   expect_memwr64_payload [4095:0];
reg     [7:0]                   expect_cfgwr_payload [3:0];
reg                             expect_status;
reg                             expect_finish_check;
reg                             testError;

assign user_lnk_up_n = ~user_lnk_up;

/************************************************************
 Initial Statements
*************************************************************/
initial begin

  s_axis_rq_tlast   = 0;
  s_axis_rq_tdata   = 0;
  s_axis_rq_tuser   = 0;
  s_axis_rq_tkeep   = 0;
  s_axis_rq_tvalid  = 0;

  s_axis_cc_tdata   = 0;
  s_axis_cc_tuser   = 0;
  s_axis_cc_tlast   = 0;
  s_axis_cc_tkeep   = 0;
  s_axis_cc_tvalid  = 0;

  ADDRESS_32_L         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
  ADDRESS_32_H         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
  ADDRESS_64           = { ADDRESS_32_H, ADDRESS_32_L };
  EP_BUS_DEV_FNS       = 16'b0000_0001_1010_0000;
  RP_BUS_DEV_FNS       = 16'b0000_0000_1010_1111;
  DEFAULT_TC           = 3'b000;
  DEFAULT_LENGTH       = 10'h000;
  DEFAULT_BE_LAST_DW   = 4'h0;
  DEFAULT_BE_FIRST_DW  = 4'h0;
  DEFAULT_ATTR         = 2'b01;
  DEFAULT_TAG          = 8'h00;
  DEFAULT_COMP         = 4'h0;
  EXT_REG_ADDR         = 12'h000;
  TD                   = 0;
  EP                   = 0;
  VENDOR_ID            = 16'h10ee;
  LENGTH               = 10'b00_0000_0001;

  set_malformed        = 1'b0;

end
//-----------------------------------------------------------------------\\
// Pre-BAR initialization
initial begin

  BAR_INIT_MESSAGE[0] = "DISABLED";
  BAR_INIT_MESSAGE[1] = "IO MAPPED";
  BAR_INIT_MESSAGE[2] = "MEM32 MAPPED";
  BAR_INIT_MESSAGE[3] = "MEM64 MAPPED";

  OUT_OF_LO_MEM       = 1'b0;
  OUT_OF_IO           = 1'b0;
  OUT_OF_HI_MEM       = 1'b0;

  // Disable variables to start
  for (ii = 0; ii <= 6; ii = ii + 1) begin

      BAR_INIT_P_BAR[ii]         = 33'h00000_0000;
      BAR_INIT_P_BAR_RANGE[ii]   = 32'h0000_0000;
      BAR_INIT_P_BAR_ENABLED[ii] = 2'b00;

  end

  BAR_INIT_P_MEM64_HI_START =  32'h0000_0001;  // hi 32 bit start of 64bit memory
  BAR_INIT_P_MEM64_LO_START =  32'h0000_0000;  // low 32 bit start of 64bit memory
  BAR_INIT_P_MEM32_START    =  33'h00000_0000; // start of 32bit memory
  BAR_INIT_P_IO_START       =  33'h00000_0000; // start of 32bit io

  DEV_VEN_ID                = (EP_DEV_ID << 16) | (32'h8086);//(32'h10EE);
  PIO_MAX_MEMORY            = 8192;            // PIO has max of 8Kbytes of memory
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test
  PIO_MAX_MEMORY            = 2048;            // PIO has 4 memory regions with 2 Kbytes of memory per region, ie 8 Kbytes
  PIO_MAX_NUM_BLOCK_RAMS    = 4;               // PIO has four block RAMS to test

  pio_check_design          = 1;               // By default check to make sure the core has been configured
                                               // appropriately for the PIO design
  cpld_to                   = 0;               // By default time out has not occured
  cpld_to_finish            = 1;               // By default end simulation on time out

  verbose                   = 0;               // turned off by default

  NUMBER_OF_IO_BARS         = 0;
  NUMBER_OF_MEM32_BARS      = 0;
  NUMBER_OF_MEM64_BARS      = 0;

end
//-----------------------------------------------------------------------\\
initial begin
  if ($value$plusargs("TESTNAME=%s", testname))
      $display("Running test {%0s}......", testname);
  else begin
      // $display("[%t] %m: No TESTNAME specified!", $realtime);
      // $finish(2);
      testname = "pio_writeReadBack_test0";
      $display("Running default test {%0s}......", testname);
  end

  expect_status       = 0;
  expect_finish_check = 0;
  testError           = 1'b0;
  // Tx transaction interface signal initialization.
  pcie_tlp_data       = 0;
  pcie_tlp_rem        = 0;

  // Payload data initialization.
  TSK_USR_DATA_SETUP_SEQ;

  //Test starts here
  if (testname == "dummy_test") begin
      $display("[%t] %m: Invalid TESTNAME: %0s", $realtime, testname);
      $finish(2);
  end
  `include "tests.vh"
  else begin
      $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
      $finish(2);
  end
end
//-----------------------------------------------------------------------\\

    /************************************************************
      Logic to Compute the Parity of the CC and the RQ Channel
    *************************************************************/

    generate
      if(ATTR_AXISTEN_IF_RQ_PARITY_CHECK == 1) begin

          genvar a;

          for(a=0; a< STRB_WIDTH; a = a + 1) // Parity needs to be computed for every byte of data
          begin : parity_assign
              assign s_axis_rq_tparity[a] = !(  s_axis_rq_tdata[(8*a)+ 0] ^ s_axis_rq_tdata[(8*a)+ 1]
                                              ^ s_axis_rq_tdata[(8*a)+ 2] ^ s_axis_rq_tdata[(8*a)+ 3]
                                              ^ s_axis_rq_tdata[(8*a)+ 4] ^ s_axis_rq_tdata[(8*a)+ 5]
                                              ^ s_axis_rq_tdata[(8*a)+ 6] ^ s_axis_rq_tdata[(8*a)+ 7]);

              assign s_axis_cc_tparity[a] = !(  s_axis_cc_tdata[(8*a)+ 0] ^ s_axis_cc_tdata[(8*a)+ 1]
                                              ^ s_axis_cc_tdata[(8*a)+ 2] ^ s_axis_cc_tdata[(8*a)+ 3]
                                              ^ s_axis_cc_tdata[(8*a)+ 4] ^ s_axis_cc_tdata[(8*a)+ 5]
                                              ^ s_axis_cc_tdata[(8*a)+ 6] ^ s_axis_cc_tdata[(8*a)+ 7]);
          end
      end
    endgenerate

    /************************************************************
    Task : TSK_SYSTEM_INITIALIZATION
    Inputs : None
    Outputs : None
    Description : Waits for Transaction Interface Reset and Link-Up
    *************************************************************/

    task TSK_SYSTEM_INITIALIZATION;
        begin

        //--------------------------------------------------------------------------
        // Event # 1: Wait for Transaction reset to be de-asserted...
        //--------------------------------------------------------------------------
        wait (reset == 0);
        $display("[%t] : Transaction Reset Is De-asserted...", $realtime);

        //--------------------------------------------------------------------------
        // Event # 2: Wait for Transaction link to be asserted...
        //--------------------------------------------------------------------------
        board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h01, 32'h00000007, 4'h1);

        board.RP.cfg_usrapp.cfg_mgmt_byte_enable = 4'hF;
        // CFG_WRITE : Description : Write Configuration Space MI decode error, Disabling LFSR update from SKP. CR# 
        // CFG_DWADDR = 32'h40082; //32'h40082
        board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h40082);
        board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h40082, {board.RP.cfg_usrapp.cfg_mgmt_read_data[31:28],1'b1,board.RP.cfg_usrapp.cfg_mgmt_read_data[26:0]}, 4'hF);
        board.RP.cfg_usrapp.cfg_mgmt_byte_enable = 4'h0;

        if (LINK_CAP_MAX_LINK_SPEED_EP>1) begin
            wait(board.RP.rport.cfg_ltssm_state == 6'h0B);
            wait(board.RP.rport.cfg_ltssm_state == 6'h10);
        end

    wait (board.RP.rport.user_lnk_up == 1);
        board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);

        $display("[%t] : Transaction Link Is Up...", $realtime);

        TSK_SYSTEM_CONFIGURATION_CHECK;

        end
    endtask

    /************************************************************
    Task : TSK_SYSTEM_CONFIGURATION_CHECK
    Inputs : None
    Outputs : None
    Description : Check that options selected from Coregen GUI are
                  set correctly.
                  Checks - Max Link Speed/Width, Device/Vendor ID, CMPS
    *************************************************************/

    task TSK_SYSTEM_CONFIGURATION_CHECK;
        begin

        error_check = 0;

        // Check Link Speed/Width
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'hD0, 4'hF);
        TSK_WAIT_FOR_READ_DATA;

        if  (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
            if (P_READ_DATA[19:16] == 1)
                $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
            else if(P_READ_DATA[19:16] == 2)
                $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
            else if(P_READ_DATA[19:16] == 3)
                $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
        end else begin
            $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
        end

        if  (P_READ_DATA[23:20] == LINK_CAP_MAX_LINK_WIDTH_EP)
              $display("[%t] :    Check Negotiated Link Width = %x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH_EP);
        else
              $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, LINK_CAP_MAX_LINK_WIDTH_EP, P_READ_DATA[23:20]);

        // Check Device/Vendor ID
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
        TSK_WAIT_FOR_READ_DATA;

        if  (P_READ_DATA[31:16] != EP_DEV_ID) begin
            $display("[%t] :    Check Device/Vendor ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime, EP_DEV_ID, P_READ_DATA);

            error_check = 1;
        end else begin
            $display("[%t] :    Check Device/Vendor ID - PASSED", $realtime);
        end

        // Check CMPS
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'hC4, 4'hF);
        TSK_WAIT_FOR_READ_DATA;

        if (P_READ_DATA[2:0] != DEV_CAP_MAX_PAYLOAD_SUPPORTED) begin
            $display("[%t] :    Check CMPS ID - FAILED", $realtime);
            $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read data %x", $realtime, DEV_CAP_MAX_PAYLOAD_SUPPORTED, P_READ_DATA);

            error_check = 1;
        end else begin
            $display("[%t] :    Check CMPS ID - PASSED", $realtime);
        end


        if (error_check == 0) begin
            $display("[%t] :    SYSTEM CHECK PASSED", $realtime);
        end else begin
            $display("[%t] :    SYSTEM CHECK FAILED", $realtime);
            $finish;
        end

        end
    endtask

    /************************************************************
    Task : TSK_RESET
    Inputs : Reset
    Outputs : PERSTn
    Description : Initiates PERSTn
    *************************************************************/

    task TSK_RESET;
        input reset_;

        board.sys_rst_n = reset_;

    endtask

    /************************************************************
    Task : TSK_MALFORMED
    Inputs : Malformed Type
    Outputs : Transaction Tx Interface Signaling
    Description : Generates Malformed TLPs
    *************************************************************/

    task TSK_MALFORMED;
        input type_;
        reg [31:0] mem32_base;
        reg        mem32_base_enabled;
        reg [63:0] mem64_base;
        reg        mem64_base_enabled;
        reg [31:0] io_base;
        reg        io_base_enabled;
        
        begin

            for (board.RP.tx_usrapp.ii = 0; board.RP.tx_usrapp.ii <= 6; board.RP.tx_usrapp.ii =
                board.RP.tx_usrapp.ii + 1) begin
                if (board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b10) begin
                    mem32_base = board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0];
                    mem32_base_enabled = 1'b1; end

                else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b11) begin
                    mem64_base =  {board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii+1][31:0],
                                   board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0]};
                    mem64_base_enabled = 1'b1; end

                else if(board.RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[board.RP.tx_usrapp.ii] == 2'b01) begin
                    io_base =  board.RP.tx_usrapp.BAR_INIT_P_BAR[board.RP.tx_usrapp.ii][31:0];
                    io_base_enabled = 1'b1; end

            end

            set_malformed = 1'b1;

            case(type_)
            8'h01: begin
                if(mem32_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                              board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                              mem32_base+8'h10, 4'h0, 4'hF, set_malformed);
                end
                else if(mem64_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_WRITE_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                              board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                              mem64_base+8'h10, 4'h0, 4'hF, set_malformed);
                end
            end
            8'h02: begin
                if(mem32_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_READ_32(board.RP.tx_usrapp.DEFAULT_TAG,
                                                             board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                             mem32_base+8'h10, 4'h0, 4'h0);
                 end
                 else if(mem64_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_MEMORY_READ_64(board.RP.tx_usrapp.DEFAULT_TAG,
                                                             board.RP.tx_usrapp.DEFAULT_TC, 10'd1,
                                                             mem64_base+8'h10, 4'h0, 4'h0);
                end
            end
            8'h04: begin
                if(io_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_IO_WRITE(board.RP.tx_usrapp.DEFAULT_TAG,
                                                       io_base, 4'hF, 32'hdead_beef);
                end
            end
            8'h08: begin
                if(io_base_enabled) begin
                    board.RP.tx_usrapp.TSK_TX_IO_READ(board.RP.tx_usrapp.DEFAULT_TAG,
                                                      io_base, 4'hF);
                end
            end
            8'h10: begin
                TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'hC4, 32'h0, 4'hF);
            end
            8'h20: begin
                TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'hC4, 4'hF);
            end
            8'h40: begin
                TSK_TX_MESSAGE(DEFAULT_TAG,3'b0,11'b0,64'b0, 3'b011,8'h0);
            end
            endcase
            
        end
    endtask

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_READ;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;            // 2DW Descriptor
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,         // Seq Number
                                                8'h00,           // TPH Steering Tag
                                                1'b0,            // TPH indirect Tag Enable
                                                2'b0,            // TPH Type
                                                1'b0,            // TPH Present
                                                1'b0,            // Discontinue
                                                3'b000,          // Byte Lane number in case of Address Aligned mode
                                                4'b0000,         // Last BE of the Read Data
                                                first_dw_be_ };  // First BE of the Read Data
                                                 
            s_axis_rq_tdata          <= #(Tcq) {128'b0,          // 4DW unused             //256
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1000,         // Req Type for TYPE0 CFG READ Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       // 64
                                                16'b0,           // Address *unused*       // 32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,          // Fmt for Type 0 Configuration Read Req 
                                                5'b00100,        // Type for Type 0 Configuration Read Req
                                                1'b0,            // *reserved*
                                                3'b000,          // Traffic Class
                                                1'b0,            // *reserved*
                                                1'b0,            // Attributes {ID Based Ordering}
                                                1'b0,            // *reserved*
                                                1'b0,            // TLP Processing Hints
                                                1'b0,            // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,           // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,           // Address Translation
                                                10'b0000000001,  // DWORD Count            //32
                                                RP_BUS_DEV_FNS,  // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0000,         // Last DW Byte Enable
                                                first_dw_be_,    // First DW Byte Enable   //64
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                4'b0000,         // *reserved*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00,           // *reserved*             //96
                                                32'b0 ,          // *unused*               //128
                                                128'b0           // *unused*               //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_READ;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- CFG TYPE-0 Read Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;            // 2DW Descriptor
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,         // Seq Number
                                                8'h00,           // TPH Steering Tag
                                                1'b0,            // TPH indirect Tag Enable
                                                2'b0,            // TPH Type
                                                1'b0,            // TPH Present
                                                1'b0,            // Discontinue
                                                3'b000,          // Byte Lane number in case of Address Aligned mode
                                                4'b0000,         // Last BE of the Read Data
                                                first_dw_be_ };  // First BE of the Read Data
                                                
            s_axis_rq_tdata          <= #(Tcq) {128'b0,          // 4DW unused             //256
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID           //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1001,         // Req Type for TYPE1 CFG READ Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       //64
                                                16'b0,           // Address *unused*       //32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,          // Fmt for Type 1 Configuration Read Req
                                                5'b00101,        // Type for Type 1 Configuration Read Req
                                                1'b0,            // *reserved*
                                                3'b000,          // Traffic Class
                                                1'b0,            // *reserved*
                                                1'b0,            // Attributes {ID Based Ordering}
                                                1'b0,            // *reserved*
                                                1'b0,            // TLP Processing Hints
                                                1'b0,            // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,           // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,           // Address Translation
                                                10'b0000000001,  // DWORD Count            //32
                                                RP_BUS_DEV_FNS,  // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0000,         // Last DW Byte Enable
                                                first_dw_be_,    // First DW Byte Enable   //64
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                4'b0000,         // *reserved*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00,           // *reserved*             //96
                                                32'b0,           // *unused*               //128
                                                128'b0           // *unused*               //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_WRITE;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  8'hFF : 8'h1F;       // 2DW Descriptor
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,         // Seq Number
                                                8'h00,           // TPH Steering Tag
                                                1'b0,            // TPH indirect Tag Enable
                                                2'b0,            // TPH Type
                                                1'b0,            // TPH Present
                                                1'b0,            // Discontinue
                                                3'b000,          // Byte Lane number in case of Address Aligned mode (always 0 for Config packets)
                                                4'b0000,         // Last BE of the Write Data
                                                first_dw_be_ };  // First BE of the Write Data
                                                
            s_axis_rq_tdata          <= #(Tcq) {96'b0,           // 3 DW unused            //256
                                                ((AXISTEN_IF_RQ_ALIGNMENT_MODE=="FALSE")? {reg_data_[31:24], reg_data_[23:16], reg_data_[15:8], reg_data_[7:0]} : 32'h0), // Data
                                                1'b0,            // Force ECRC             //128
                                                3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,          // Traffic Class
                                                1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,  // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,  // Requester ID           //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1010,         // Req Type for TYPE0 CFG Write Req
                                                11'b00000000001, // DWORD Count
                                                32'b0,           // Address *unused*       //64
                                                16'b0,           // Address *unused*       //32
                                                4'b0,            // Address *unused*
                                                reg_addr_[11:2], // Extended + Base Register Number
                                                2'b00};          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,           // Fmt for Type 0 Configuration Write Req
                                                5'b00100,         // Type for Type 0 Configuration Write Req
                                                1'b0,             // *reserved*
                                                3'b000,           // Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                10'b0000000001,   // DWORD Count           //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0000,          // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable  //64
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                4'b0000,          // *reserved*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00,            // *reserved*            //96
                                                reg_data_[7:0],   // Data
                                                reg_data_[15:8],  // Data
                                                reg_data_[23:16], // Data
                                                reg_data_[31:24], // Data                  //128
                                                128'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 8'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {128'b0,
                                                32'b0,            // *unused* //128
                                                32'b0,            // *unused* //96
                                                32'b0,            // *unused* //64
                                                reg_data_[31:24],             //32
                                                reg_data_[23:16],
                                                reg_data_[15:8],
                                                reg_data_[7:0]
                                               };

               // Just call TSK_TX_SYNCHRONIZE to wait for tready but don't log anything, because
               // the pcie_tlp_data has complete in the previous clock cycle
               TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_WRITE;
        input    [7:0]    tag_;         // Tag
        input    [11:0]   reg_addr_;    // Register Number
        input    [31:0]   reg_data_;    // Data
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- TYPE-0 CFG Write Transaction :                     -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  1'b0 : 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) (AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") ?  8'hFF : 8'h1F;       // 2DW Descriptor
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,          // Seq Number
                                                8'h00,            // TPH Steering Tag
                                                1'b0,             // TPH indirect Tag Enable
                                                2'b0,             // TPH Type
                                                1'b0,             // TPH Present
                                                1'b0,             // Discontinue
                                                3'b000,           // Byte Lane number in case of Address Aligned mode (always 0 for Config packets)
                                                4'b0000,          // Last BE of the Write Data
                                                first_dw_be_ };   // First BE of the Write Data
                                                
            s_axis_rq_tdata          <= #(Tcq) {96'b0,            // 3 DW unused            //256
                                                ((AXISTEN_IF_RQ_ALIGNMENT_MODE=="FALSE")? {reg_data_[31:24], reg_data_[23:16], reg_data_[15:8], reg_data_[7:0]} : 32'h0), // Data
                                                1'b0,             // Force ECRC            //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,           // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID          //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1011,          // Req Type for TYPE0 CFG Write Req
                                                11'b00000000001,  // DWORD Count
                                                32'b0,            // Address *unused*      //64
                                                16'b0,            // Address *unused*      //32
                                                4'b0,             // Address *unused*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00 };          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,           // Fmt for Type 1 Configuration Write Req
                                                5'b00101,         // Type for Type 1 Configuration Write Req
                                                1'b0,             // *reserved*
                                                3'b000,           // Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                10'b0000000001,   // DWORD Count           // 32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0000,          // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable  //64
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                4'b0000,          // *reserved*
                                                reg_addr_[11:2],  // Extended + Base Register Number
                                                2'b00,            // *reserved*            //96
                                                reg_data_[7:0],   // Data
                                                reg_data_[15:8],  // Data
                                                reg_data_[23:16], // Data
                                                reg_data_[31:24], // Data                  //128
                                                128'b0            // *unused*              //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;

            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
               s_axis_rq_tvalid      <= #(Tcq) 1'b1;
               s_axis_rq_tlast       <= #(Tcq) 1'b1;
               s_axis_rq_tkeep       <= #(Tcq) 8'h01;             // 2DW Descriptor

               s_axis_rq_tdata       <= #(Tcq) {128'b0,
                                                32'b0,            // *unused* //128
                                                32'b0,            // *unused* //96
                                                32'b0,            // *unused* //64
                                                reg_data_[31:24],             //32
                                                reg_data_[23:16],
                                                reg_data_[15:8],
                                                reg_data_[7:0]
                                               };

               // Just call TSK_TX_SYNCHRONIZE to wait for tready but don't log anything, because
               // the pcie_tlp_data has complete in the previous clock cycle
               TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_MEMORY_READ_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_32;
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [31:0]   addr_;        // Address
        input    [3:0]    last_dw_be_;  // Last DW Byte Enable
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,          // Seq Number
                                                8'h00,            // TPH Steering Tag
                                                1'b0,             // TPH indirect Tag Enable
                                                2'b0,             // TPH Type
                                                1'b0,             // TPH Present
                                                1'b0,             // Discontinue
                                                3'b000,           // Byte Lane number in case of Address Aligned mode
                                                last_dw_be_,      // Last BE of the Read Data
                                                first_dw_be_ };   // First BE of the Read Data
                                                
            s_axis_rq_tdata          <= #(Tcq) {128'b0,           // 4 DW unused                                    //256
                                                1'b0,             // Force ECRC                                     //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,              // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0000,          // Req Type for MRd Req
                                                len_ ,            // DWORD Count
                                                32'b0,            // 32-bit Addressing. So, bits[63:32] = 0         //64
                                                addr_[31:2],      // Memory read address 32-bits                    //32
                                                2'b00};           // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,           // Fmt for 32-bit MRd Req
                                                5'b00000,         // Type for 32-bit Mrd Req
                                                1'b0,             // *reserved*
                                                tc_,              // 3-bit Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                len_[9:0],        // DWORD Count                                    //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                last_dw_be_,      // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable                           //64
                                                addr_[31:2],      // Address
                                                2'b00,            // *reserved*                                     //96
                                                32'b0,            // *unused*                                       //128
                                                128'b0            // *unused*                                       //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_32

    /************************************************************
    Task : TSK_TX_MEMORY_READ_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_64;
        input    [7:0]    tag_;         // Tag
        input    [2:0]    tc_;          // Traffic Class
        input    [10:0]   len_;         // Length (in DW)
        input    [63:0]   addr_;        // Address
        input    [3:0]    last_dw_be_;  // Last DW Byte Enable
        input    [3:0]    first_dw_be_; // First DW Byte Enable
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;             // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,          // Seq Number
                                                8'h00,            // TPH Steering Tag
                                                1'b0,             // TPH indirect Tag Enable
                                                2'b0,             // TPH Type
                                                1'b0,             // TPH Present
                                                1'b0,             // Discontinue
                                                3'b000,           // Byte Lane number in case of Address Aligned mode
                                                last_dw_be_,      // Last BE of the Read Data
                                                first_dw_be_ };   // First BE of the Read Data
                                                  
            s_axis_rq_tdata          <= #(Tcq) {128'b0,           // 4 DW unused                                    //256
                                                1'b0,             // Force ECRC                                     //128
                                                3'b000,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,              // Traffic Class
                                                1'b1,             // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1  //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0000,          // Req Type for MRd Req
                                                len_ ,            // DWORD Count
                                                addr_[63:2],      // Memory read address 64-bits                    //64
                                                2'b00};           // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b001,           // Fmt for 64-bit MRd Req
                                                5'b00000,         // Type for 64-bit Mrd Req
                                                1'b0,             // *reserved*
                                                tc_,              // 3-bit Traffic Class
                                                1'b0,             // *reserved*
                                                1'b0,             // Attributes {ID Based Ordering}
                                                1'b0,             // *reserved*
                                                1'b0,             // TLP Processing Hints
                                                1'b0,             // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,            // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,            // Address Translation
                                                len_[9:0],        // DWORD Count                                    //32
                                                RP_BUS_DEV_FNS,   // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                last_dw_be_,      // Last DW Byte Enable
                                                first_dw_be_,     // First DW Byte Enable                           //64
                                                addr_[63:2],      // Address
                                                2'b00,            // *reserved*                                     //128
                                                128'b0            // *unused*                                       //256
                                               };
                                                
            pcie_tlp_rem             <= #(Tcq)  3'b100;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_READ_64

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_32;
        input  [7:0]    tag_;         // Tag
        input  [2:0]    tc_;          // Traffic Class
        input  [10:0]   len_;         // Length (in DW)
        input  [31:0]   addr_;        // Address
        input  [3:0]    last_dw_be_;  // Last DW Byte Enable
        input  [3:0]    first_dw_be_; // First DW Byte Enable
        input           ep_;          // Poisoned Data: Payload is invalid if set
        reg    [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg    [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg    [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg    [255:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg    [127:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg    [159:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        integer         _j;           // Byte Index
        integer         start_addr;   // Start Location for Payload DW0

        begin
            //-----------------------------------------------------------------------\\            
            if(AXISTEN_IF_RQ_ALIGNMENT_MODE=="TRUE")begin
                start_addr  = 0;
                aa_dw       = addr_[4:2];
            end else begin
                start_addr  = 16;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   DATA_STORE[7],
                                   DATA_STORE[6],
                                   DATA_STORE[5],
                                   DATA_STORE[4],
                                   DATA_STORE[3],
                                   DATA_STORE[2],
                                   DATA_STORE[1],
                                   DATA_STORE[0]
                                  };

            s_axis_rq_tuser   <= #(Tcq) {
                                         (ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                         4'b1010,        // Seq Number
                                         8'h00,          // TPH Steering Tag
                                         1'b0,           // TPH indirect Tag Enable
                                         2'b0,           // TPH Type
                                         1'b0,           // TPH Present
                                         1'b0,           // Discontinue
                                         aa_dw,          // Byte Lane number in case of Address Aligned mode
                                         last_dw_be_,    // Last BE of the Write Data
                                         first_dw_be_    // First BE of the Write Data
                                        };

            s_axis_rq_tdata   <= #(Tcq) { //256
                                         ((AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE" ) ?  data_axis_i : 128'h0), // 128-bit write data
                                          //128
                                         1'b0,          // Force ECRC
                                         3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,           // Traffic Class
                                         1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                         EP_BUS_DEV_FNS,   // Completer ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                          //96
                                         RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1
                                         ep_,           // Poisoned Req
                                         4'b0001,       // Req Type for MWr Req
                                         (set_malformed ? (len_ + 11'h4) : len_), // DWORD Count - length does not include padded zeros
                                          //64
                                         32'b0,         // High Address *unused*
                                         addr_[31:2],   // Memory Write address 32-bits
                                         2'b00          // AT -> 00 : Untranslated Address
                                        };
            //-----------------------------------------------------------------------\\
            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15],
                                   DATA_STORE[16],
                                   DATA_STORE[17],
                                   DATA_STORE[18],
                                   DATA_STORE[19]
                                  };

            pcie_tlp_data     <= #(Tcq) {
                                         3'b010,        // Fmt for 32-bit MWr Req
                                         5'b00000,      // Type for 32-bit MWr Req
                                         1'b0,          // *reserved*
                                         tc_,           // 3-bit Traffic Class
                                         1'b0,          // *reserved*
                                         1'b0,          // Attributes {ID Based Ordering}
                                         1'b0,          // *reserved*
                                         1'b0,          // TLP Processing Hints
                                         1'b0,          // TLP Digest Present
                                         ep_,           // Poisoned Req
                                         2'b00,         // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,         // Address Translation
                                         (set_malformed ? (len_[9:0] + 10'h4) : len_[9:0]),  // DWORD Count
                                          //32
                                         RP_BUS_DEV_FNS,   // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                         last_dw_be_,   // Last DW Byte Enable
                                         first_dw_be_,  // First DW Byte Enable
                                          //64
                                         addr_[31:2],   // Memory Write address 32-bits
                                         2'b00,         // *reserved* or Processing Hint
                                          //96
                                         data_pcie_i    // Payload Data
                                          //256
                                        };
                                          
            pcie_tlp_rem      <= #(Tcq) (_len > 4) ? 3'b000 : (5-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 4) ? (_len - 11'h5) : 11'b0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;

                len_i                     = (AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE") ? (len_i - 4) : len_i; // Don't subtract 4 in Address Aligned because
                                                                                                             // it's always padded with zeros on first beat

                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS RQ interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);

            end else begin
                if (len_i == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;

                s_axis_rq_tlast          <= #(Tcq) 1'b1;

                len_i                     = 0;
                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                fork

                begin // Sequential group 1 - AXIS RQ
                    for (_j = start_addr; len_i != 0; _j = _j + 32) begin
                        if(_j==start_addr) begin 
                            aa_data = {
                                       DATA_STORE[_j + 31],
                                       DATA_STORE[_j + 30],
                                       DATA_STORE[_j + 29],
                                       DATA_STORE[_j + 28],
                                       DATA_STORE[_j + 27],
                                       DATA_STORE[_j + 26],
                                       DATA_STORE[_j + 25],
                                       DATA_STORE[_j + 24],
                                       DATA_STORE[_j + 23],
                                       DATA_STORE[_j + 22],
                                       DATA_STORE[_j + 21],
                                       DATA_STORE[_j + 20],
                                       DATA_STORE[_j + 19],
                                       DATA_STORE[_j + 18],
                                       DATA_STORE[_j + 17],
                                       DATA_STORE[_j + 16],
                                       DATA_STORE[_j + 15],
                                       DATA_STORE[_j + 14],
                                       DATA_STORE[_j + 13],
                                       DATA_STORE[_j + 12],
                                       DATA_STORE[_j + 11],
                                       DATA_STORE[_j + 10],
                                       DATA_STORE[_j +  9],
                                       DATA_STORE[_j +  8],
                                       DATA_STORE[_j +  7],
                                       DATA_STORE[_j +  6],
                                       DATA_STORE[_j +  5],
                                       DATA_STORE[_j +  4],
                                       DATA_STORE[_j +  3],
                                       DATA_STORE[_j +  2],
                                       DATA_STORE[_j +  1],
                                       DATA_STORE[_j +  0]
                                      } << (aa_dw*4*8);
                        end else begin 
                            aa_data = {
                                       DATA_STORE[_j + 31 - (aa_dw*4)],
                                       DATA_STORE[_j + 30 - (aa_dw*4)],
                                       DATA_STORE[_j + 29 - (aa_dw*4)],
                                       DATA_STORE[_j + 28 - (aa_dw*4)],
                                       DATA_STORE[_j + 27 - (aa_dw*4)],
                                       DATA_STORE[_j + 26 - (aa_dw*4)],
                                       DATA_STORE[_j + 25 - (aa_dw*4)],
                                       DATA_STORE[_j + 24 - (aa_dw*4)],
                                       DATA_STORE[_j + 23 - (aa_dw*4)],
                                       DATA_STORE[_j + 22 - (aa_dw*4)],
                                       DATA_STORE[_j + 21 - (aa_dw*4)],
                                       DATA_STORE[_j + 20 - (aa_dw*4)],
                                       DATA_STORE[_j + 19 - (aa_dw*4)],
                                       DATA_STORE[_j + 18 - (aa_dw*4)],
                                       DATA_STORE[_j + 17 - (aa_dw*4)],
                                       DATA_STORE[_j + 16 - (aa_dw*4)],
                                       DATA_STORE[_j + 15 - (aa_dw*4)],
                                       DATA_STORE[_j + 14 - (aa_dw*4)],
                                       DATA_STORE[_j + 13 - (aa_dw*4)],
                                       DATA_STORE[_j + 12 - (aa_dw*4)],
                                       DATA_STORE[_j + 11 - (aa_dw*4)],
                                       DATA_STORE[_j + 10 - (aa_dw*4)],
                                       DATA_STORE[_j +  9 - (aa_dw*4)],
                                       DATA_STORE[_j +  8 - (aa_dw*4)],
                                       DATA_STORE[_j +  7 - (aa_dw*4)],
                                       DATA_STORE[_j +  6 - (aa_dw*4)],
                                       DATA_STORE[_j +  5 - (aa_dw*4)],
                                       DATA_STORE[_j +  4 - (aa_dw*4)],
                                       DATA_STORE[_j +  3 - (aa_dw*4)],
                                       DATA_STORE[_j +  2 - (aa_dw*4)],
                                       DATA_STORE[_j +  1 - (aa_dw*4)],
                                       DATA_STORE[_j +  0 - (aa_dw*4)]
                                      };
                        end

                        s_axis_rq_tdata   <= #(Tcq) aa_data;

                        if((len_i/8) == 0) begin
                            case (len_i % 8)
                                1 : begin len_i = len_i - 1; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------------------
                                2 : begin len_i = len_i - 2; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1------------------
                                3 : begin len_i = len_i - 3; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2---------------
                                4 : begin len_i = len_i - 4; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------------
                                5 : begin len_i = len_i - 5; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4---------
                                6 : begin len_i = len_i - 6; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin len_i = len_i - 7; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin len_i = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            len_i               = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF;      // D0-D1-D2-D3-D4-D5-D6-D7
                        end

                        if (len_i == 0)
                            s_axis_rq_tlast        <= #(Tcq) 1'b1;
                        else
                            s_axis_rq_tlast        <= #(Tcq) 1'b0;

                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS RQ
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS RQ interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);

                    end // for loop
                end // End sequential group 1 - AXIS RQ

                begin // Sequential group 2 - pcie_tlp
                    for (_j = 20; _len != 0; _j = _j + 32) begin
                        pcie_tlp_data <= #(Tcq)    {
                                                    DATA_STORE[_j + 0],
                                                    DATA_STORE[_j + 1],
                                                    DATA_STORE[_j + 2],
                                                    DATA_STORE[_j + 3],
                                                    DATA_STORE[_j + 4],
                                                    DATA_STORE[_j + 5],
                                                    DATA_STORE[_j + 6],
                                                    DATA_STORE[_j + 7],
                                                    DATA_STORE[_j + 8],
                                                    DATA_STORE[_j + 9],
                                                    DATA_STORE[_j + 10],
                                                    DATA_STORE[_j + 11],
                                                    DATA_STORE[_j + 12],
                                                    DATA_STORE[_j + 13],
                                                    DATA_STORE[_j + 14],
                                                    DATA_STORE[_j + 15],
                                                    DATA_STORE[_j + 16],
                                                    DATA_STORE[_j + 17],
                                                    DATA_STORE[_j + 18],
                                                    DATA_STORE[_j + 19],
                                                    DATA_STORE[_j + 20],
                                                    DATA_STORE[_j + 21],
                                                    DATA_STORE[_j + 22],
                                                    DATA_STORE[_j + 23],
                                                    DATA_STORE[_j + 24],
                                                    DATA_STORE[_j + 25],
                                                    DATA_STORE[_j + 26],
                                                    DATA_STORE[_j + 27],
                                                    DATA_STORE[_j + 28],
                                                    DATA_STORE[_j + 29],
                                                    DATA_STORE[_j + 30],
                                                    DATA_STORE[_j + 31]
                                                   };

                        if ((_len/8) == 0) begin
                            case (_len % 8)
                                1 : begin _len = _len - 1; pcie_tlp_rem  <= #(Tcq) 3'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem  <= #(Tcq) 3'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem  <= #(Tcq) 3'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem  <= #(Tcq) 3'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem  <= #(Tcq) 3'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem  <= #(Tcq) 3'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem  <= #(Tcq) 3'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem  <= #(Tcq) 3'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem   <= #(Tcq) 3'b000;     // D0-D1-D2-D3-D4-D5-D6-D7
                        end

                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_RQ_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp

                join
            end  // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_32

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_64;
        input  [7:0]    tag_;         // Tag
        input  [2:0]    tc_;          // Traffic Class
        input  [10:0]   len_;         // Length (in DW)
        input  [63:0]   addr_;        // Address
        input  [3:0]    last_dw_be_;  // Last DW Byte Enable
        input  [3:0]    first_dw_be_; // First DW Byte Enable
        input           ep_;          // Poisoned Data: Payload is invalid if set
        reg    [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg    [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg    [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg    [255:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg    [127:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg    [127:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        integer         _j;           // Byte Index
        integer         start_addr;   // Start Location for Payload DW0

        begin
            //-----------------------------------------------------------------------\\
            if (AXISTEN_IF_RQ_ALIGNMENT_MODE=="TRUE") begin
                start_addr  = 0;
                aa_dw       = addr_[4:2];
            end else begin
                start_addr  = 16;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   DATA_STORE[7],
                                   DATA_STORE[6],
                                   DATA_STORE[5],
                                   DATA_STORE[4],
                                   DATA_STORE[3],
                                   DATA_STORE[2],
                                   DATA_STORE[1],
                                   DATA_STORE[0]
                                  };

            s_axis_rq_tuser   <= #(Tcq) {
                                         (ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                         4'b1010,        // Seq Number
                                         8'h00,          // TPH Steering Tag
                                         1'b0,           // TPH indirect Tag Enable
                                         2'b0,           // TPH Type
                                         1'b0,           // TPH Present
                                         1'b0,           // Discontinue
                                         aa_dw,          // Byte Lane number in case of Address Aligned mode
                                         last_dw_be_,    // Last BE of the Write Data
                                         first_dw_be_    // First BE of the Write Data
                                        };

            s_axis_rq_tdata   <= #(Tcq) { //256
                                         ((AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE" ) ?  data_axis_i : 128'h0), // 128-bit write data
                                          //128
                                         1'b0,        // Force ECRC
                                         3'b000,      // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,         // Traffic Class
                                         1'b1,        // RID Enable to use the Client supplied Bus/Device/Func No
                                         EP_BUS_DEV_FNS,   // Completer ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                          //96
                                         RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1
                                         ep_,         // Poisoned Req
                                         4'b0001,     // Req Type for MWr Req
                                         (set_malformed ? (len_ + 11'h4) : len_),  // DWORD Count
                                          //64
                                         addr_[63:2], // Memory Write address 64-bits
                                         2'b00        // AT -> 00 : Untranslated Address
                                        };
            //-----------------------------------------------------------------------\\
            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15]
                                  };

            pcie_tlp_data     <= #(Tcq) {
                                         3'b011,      // Fmt for 64-bit MWr Req
                                         5'b00000,    // Type for 64-bit MWr Req
                                         1'b0,        // *reserved*
                                         tc_,         // 3-bit Traffic Class
                                         1'b0,        // *reserved*
                                         1'b0,        // Attributes {ID Based Ordering}
                                         1'b0,        // *reserved*
                                         1'b0,        // TLP Processing Hints
                                         1'b0,        // TLP Digest Present
                                         ep_,         // Poisoned Req
                                         2'b00,       // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,       // Address Translation
                                         (set_malformed ? (len_[9:0] + 10'h4) : len_[9:0]),  // DWORD Count
                                         RP_BUS_DEV_FNS,   // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                         last_dw_be_,   // Last DW Byte Enable
                                         first_dw_be_,  // First DW Byte Enable
                                          //64
                                         addr_[63:2],   // Memory Write address 64-bits
                                         2'b00,         // *reserved*
                                          //128
                                         data_pcie_i    // Payload Data
                                          //256
                                        };
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 3) ? 3'b000 : (4-_len);
            set_malformed     <= #(Tcq) 1'b0;
            _len               = (_len > 3) ? (_len - 11'h4) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            if (len_i > 4 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;

                len_i                     = (AXISTEN_IF_RQ_ALIGNMENT_MODE == "FALSE") ? (len_i - 4) : len_i; // Don't subtract 4 in Address Aligned because
                                                                                                             // it's always padded with zeros on first beat

                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS RQ interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);

            end else begin
                if (len_i == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (len_i == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (len_i == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else // len_i == 4
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;
                
                s_axis_rq_tlast          <= #(Tcq) 1'b1;
                
                len_i                     = 0;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_RQ_ALIGNMENT_MODE == "TRUE") begin
                fork 
                
                begin // Sequential group 1 - AXIS RQ
                    for (_j = start_addr; len_i != 0; _j = _j + 32) begin
                        if(_j == start_addr) begin 
                            aa_data = {
                                       DATA_STORE[_j + 31],
                                       DATA_STORE[_j + 30],
                                       DATA_STORE[_j + 29],
                                       DATA_STORE[_j + 28],
                                       DATA_STORE[_j + 27],
                                       DATA_STORE[_j + 26],
                                       DATA_STORE[_j + 25],
                                       DATA_STORE[_j + 24],
                                       DATA_STORE[_j + 23],
                                       DATA_STORE[_j + 22],
                                       DATA_STORE[_j + 21],
                                       DATA_STORE[_j + 20],
                                       DATA_STORE[_j + 19],
                                       DATA_STORE[_j + 18],
                                       DATA_STORE[_j + 17],
                                       DATA_STORE[_j + 16],
                                       DATA_STORE[_j + 15],
                                       DATA_STORE[_j + 14],
                                       DATA_STORE[_j + 13],
                                       DATA_STORE[_j + 12],
                                       DATA_STORE[_j + 11],
                                       DATA_STORE[_j + 10],
                                       DATA_STORE[_j +  9],
                                       DATA_STORE[_j +  8],
                                       DATA_STORE[_j +  7],
                                       DATA_STORE[_j +  6],
                                       DATA_STORE[_j +  5],
                                       DATA_STORE[_j +  4],
                                       DATA_STORE[_j +  3],
                                       DATA_STORE[_j +  2],
                                       DATA_STORE[_j +  1],
                                       DATA_STORE[_j +  0]
                                       } << (aa_dw*4*8);
                        end else begin 
                            aa_data = {
                                       DATA_STORE[_j + 31 - (aa_dw*4)],
                                       DATA_STORE[_j + 30 - (aa_dw*4)],
                                       DATA_STORE[_j + 29 - (aa_dw*4)],
                                       DATA_STORE[_j + 28 - (aa_dw*4)],
                                       DATA_STORE[_j + 27 - (aa_dw*4)],
                                       DATA_STORE[_j + 26 - (aa_dw*4)],
                                       DATA_STORE[_j + 25 - (aa_dw*4)],
                                       DATA_STORE[_j + 24 - (aa_dw*4)],
                                       DATA_STORE[_j + 23 - (aa_dw*4)],
                                       DATA_STORE[_j + 22 - (aa_dw*4)],
                                       DATA_STORE[_j + 21 - (aa_dw*4)],
                                       DATA_STORE[_j + 20 - (aa_dw*4)],
                                       DATA_STORE[_j + 19 - (aa_dw*4)],
                                       DATA_STORE[_j + 18 - (aa_dw*4)],
                                       DATA_STORE[_j + 17 - (aa_dw*4)],
                                       DATA_STORE[_j + 16 - (aa_dw*4)],
                                       DATA_STORE[_j + 15 - (aa_dw*4)],
                                       DATA_STORE[_j + 14 - (aa_dw*4)],
                                       DATA_STORE[_j + 13 - (aa_dw*4)],
                                       DATA_STORE[_j + 12 - (aa_dw*4)],
                                       DATA_STORE[_j + 11 - (aa_dw*4)],
                                       DATA_STORE[_j + 10 - (aa_dw*4)],
                                       DATA_STORE[_j +  9 - (aa_dw*4)],
                                       DATA_STORE[_j +  8 - (aa_dw*4)],
                                       DATA_STORE[_j +  7 - (aa_dw*4)],
                                       DATA_STORE[_j +  6 - (aa_dw*4)],
                                       DATA_STORE[_j +  5 - (aa_dw*4)],
                                       DATA_STORE[_j +  4 - (aa_dw*4)],
                                       DATA_STORE[_j +  3 - (aa_dw*4)],
                                       DATA_STORE[_j +  2 - (aa_dw*4)],
                                       DATA_STORE[_j +  1 - (aa_dw*4)],
                                       DATA_STORE[_j +  0 - (aa_dw*4)]
                                       };
                        end

                        s_axis_rq_tdata           <= #(Tcq) aa_data;
                        
                        if((len_i)/8 == 0) begin
                            case ((len_i) % 8)
                                1 : begin len_i = len_i - 1; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------------------
                                2 : begin len_i = len_i - 2; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1------------------
                                3 : begin len_i = len_i - 3; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2---------------
                                4 : begin len_i = len_i - 4; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------------
                                5 : begin len_i = len_i - 5; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4---------
                                6 : begin len_i = len_i - 6; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin len_i = len_i - 7; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin len_i = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            len_i               = len_i - 8; s_axis_rq_tkeep <= #(Tcq) 8'hFF;      // D0-D1-D2-D3-D4-D5-D6-D7
                        end
                        
                        if (len_i == 0)
                            s_axis_rq_tlast        <= #(Tcq) 1'b1;
                        else
                            s_axis_rq_tlast        <= #(Tcq) 1'b0;

                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS RQ
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS RQ interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
                            
                    end // for loop
                end // End sequential group 1 - AXIS RQ
                
                begin // Sequential group 2 - pcie_tlp
                    for (_j = 16; _len != 0; _j = _j + 32) begin
                        pcie_tlp_data <= #(Tcq) {
                                                DATA_STORE[_j + 0],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 31]
                                                };
                        
                        if ((_len)/8 == 0) begin
                            case ((_len) % 8)
                                1 : begin _len = _len - 1; pcie_tlp_rem <= #(Tcq) 3'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem <= #(Tcq) 3'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem <= #(Tcq) 3'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem <= #(Tcq) 3'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem <= #(Tcq) 3'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem <= #(Tcq) 3'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem <= #(Tcq) 3'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem <= #(Tcq) 3'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem <= #(Tcq) 3'b000; // D0-D1-D2-D3-D4-D5-D6-D7
                        end
                        
                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_RQ_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp
                             
                join
            end // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MEMORY_WRITE_64

    /************************************************************
    Task : TSK_TX_COMPLETION
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION;
        input    [15:0]   req_id_;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [10:0]   len_;
        input    [2:0]    comp_status_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b1;
            s_axis_cc_tlast          <= #(Tcq) 1'b1;
            s_axis_cc_tkeep          <= #(Tcq) 8'h07;
            s_axis_cc_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0),1'b0};

            s_axis_cc_tdata          <= #(Tcq) {128'b0,         // *unused*
                                                 //128
                                                32'b0,          // *unused*
                                                 //96
                                                1'b0,           // Force ECRC
                                                3'b0,           // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,            // 3-bit Traffic Class
                                                1'b1,           // Completer ID to Control Selection of Client
                                                RP_BUS_DEV_FNS, // Completer ID
                                                tag_,           // Tag
                                                 //64
                                                req_id_,        // Requester ID
                                                1'b0,           // *reserved*
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Completion
                                                comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                                len_,           // DWORD Count
                                                 //32
                                                2'b0,           // *reserved*
                                                1'b0,           // Locked Read Completion
                                                13'h0004,       // Byte Count
                                                6'b0,           // *reserved*
                                                2'b0,           // Address Type
                                                1'b0,           // *reserved*
                                                7'b0            // Starting Address of the Completion Data Byte *not used*
                                               };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,         // Fmt for Completion w/o Data
                                                5'b01010,       // Type for Completion w/o Data
                                                1'b0,           // *reserved*
                                                tc_,            // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                len_[9:0],      // DWORD Count
                                                 //32
                                                RP_BUS_DEV_FNS, // Completer ID
                                                comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                                1'b0,           // Byte Count Modified (only used in PCI-X)
                                                12'b0,          // Byte Count
                                                 //64
                                                req_id_,        // Requester ID
                                                tag_,           // Tag
                                                1'b0,           // *reserved
                                                7'b00,          // Starting Address of the Completion Data Byte *not used*
                                                32'b0,          // *unused*
                                                 //128
                                                128'b0          // *unused*
                                                 //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b101;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid         <= #(Tcq) 1'b0;
            s_axis_cc_tlast          <= #(Tcq) 1'b0;
            s_axis_cc_tkeep          <= #(Tcq) 8'h00;
            s_axis_cc_tuser          <= #(Tcq) 60'b0;
            s_axis_cc_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_COMPLETION

    /************************************************************
    Task : TSK_TX_COMPLETION_DATA
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION_DATA;
        input   [15:0]   req_id_;      // Requester ID
        input   [7:0]    tag_;         // Tag
        input   [2:0]    tc_;          // Traffic Class
        input   [10:0]   len_;         // Length (in DW)
        input   [11:0]   byte_count_;  // Length (in bytes)
        input   [6:0]    lower_addr_;  // Lower 7-bits of Address of first valid data
        input   [2:0]    comp_status_; // Completion Status. 'b000: Success; 'b001: Unsupported Request; 'b010: Config Request Retry Status;'b100: Completer Abort
        input            ep_;          // Poisoned Data: Payload is invalid if set
        reg     [10:0]   _len;         // Length Info on pcie_tlp_data -- Used to count how many times to loop
        reg     [10:0]   len_i;        // Length Info on s_axis_rq_tdata -- Used to count how many times to loop
        reg     [2:0]    aa_dw;        // Adjusted DW Count for Address Aligned Mode
        reg     [255:0]  aa_data;      // Adjusted Data for Address Aligned Mode
        reg     [159:0]  data_axis_i;  // Data Info for s_axis_rq_tdata
        reg     [159:0]  data_pcie_i;  // Data Info for pcie_tlp_data
        integer          _j;           // Byte Index
        integer          start_addr;   // Start Location for Payload DW0
        
        begin
            //-----------------------------------------------------------------------\\
            if (AXISTEN_IF_CC_ALIGNMENT_MODE=="TRUE") begin
                start_addr  = 0;
                aa_dw       = lower_addr_[4:2];
            end else begin
                start_addr  = 20;
                aa_dw       = 3'b000;
            end
            
            len_i           = len_ + aa_dw;
            _len            = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
            //-----------------------------------------------------------------------\\
            // Start of First Data Beat
            data_axis_i        =  {
                                   DATA_STORE[19],
                                   DATA_STORE[18],
                                   DATA_STORE[17],
                                   DATA_STORE[16],
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   DATA_STORE[7],
                                   DATA_STORE[6],
                                   DATA_STORE[5],
                                   DATA_STORE[4],
                                   DATA_STORE[3],
                                   DATA_STORE[2],
                                   DATA_STORE[1],
                                   DATA_STORE[0]
                                  };

            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15],
                                   DATA_STORE[16],
                                   DATA_STORE[17],
                                   DATA_STORE[18],
                                   DATA_STORE[19]
                                  };

            s_axis_cc_tuser   <= #(Tcq) {(ATTR_AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0),1'b0};
            s_axis_cc_tdata   <= #(Tcq) {
                                         ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? data_axis_i : 160'h0), // 160-bit completion data
                                         1'b0,        // Force ECRC                                  //96
                                         3'b0,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,         // Traffic Class
                                         1'b1,        // Completer ID to Control Selection of Client
                                         RP_BUS_DEV_FNS, // Completer ID
                                         tag_ ,          // Tag
                                         req_id_,        // Requester ID                             //64
                                         1'b0,           // *reserved*
                                         (set_malformed ? 1'b1 : 1'b0), // Posioned Completion
                                         comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                         len_,           // DWORD Count
                                         2'b0,           // *reserved*                               //32
                                         1'b0,           // Locked Read Completion
                                         1'b0,           // Byte Count MSB
                                         byte_count_,    // Byte Count
                                         6'b0,           // *reserved*
                                         2'b0,           // Address Type
                                         1'b0,           // *reserved*
                                         lower_addr_ };  // Starting Address of the Completion Data Byte
            //-----------------------------------------------------------------------\\
            pcie_tlp_data     <= #(Tcq) {
                                         3'b010,         // Fmt for Completion with Data
                                         5'b01010,       // Type for Completion with Data
                                         1'b0,           // *reserved*
                                         tc_,            // 3-bit Traffic Class
                                         1'b0,           // *reserved*
                                         1'b0,           // Attributes {ID Based Ordering}
                                         1'b0,           // *reserved*
                                         1'b0,           // TLP Processing Hints
                                         1'b0,           // TLP Digest Present
                                         (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                         2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,          // Address Translation
                                         len_[9:0],      // DWORD Count                                            //32
                                         RP_BUS_DEV_FNS, // Completer ID
                                         comp_status_,   // Completion Status {0= SC, 1= UR, 2= CRS, 4= CA}
                                         1'b0,           // Byte Count Modified (only used in PCI-X)
                                         byte_count_,    // Byte Count                                             //64
                                         req_id_,        // Requester ID
                                         tag_,           // Tag
                                         1'b0,           // *reserved
                                         lower_addr_,    // Starting Address of the Completion Data Byte           //96
                                         data_pcie_i };  // 160-bit completion data                                //256
                                         
            pcie_tlp_rem      <= #(Tcq) (_len > 4) ? 3'b000 : (5-_len);
            _len               = (_len > 4) ? (_len - 11'h5) : 11'h0;
            //-----------------------------------------------------------------------\\
            s_axis_cc_tvalid  <= #(Tcq) 1'b1;
            
            if (len_i > 5 || AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE") begin
                s_axis_cc_tlast          <= #(Tcq) 1'b0;
                s_axis_cc_tkeep          <= #(Tcq) 8'hFF;
                
                len_i = (AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") ? (len_i - 11'h5) : len_i; // Don't subtract 5 in Address Aligned because
                                                                                             // it's always padded with zeros on first beat
                
                // pcie_tlp_data doesn't append zero even in Address Aligned mode, so it should mark this cycle as the last beat if it has no more payload to log.
                // The AXIS CC interface will need to execute the next cycle, but we're just not going to log that data beat in pcie_tlp_data
                if (_len == 0)
                    TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
                else
                    TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_CC_RDY);
                
            end else begin
                if (len_i == 1)
                    s_axis_cc_tkeep      <= #(Tcq) 8'h0F;
                else if (len_i == 2)
                    s_axis_cc_tkeep      <= #(Tcq) 8'h1F;
                else if (len_i == 3)
                    s_axis_cc_tkeep      <= #(Tcq) 8'h3F;
                else if (len_i == 4)
                    s_axis_cc_tkeep      <= #(Tcq) 8'h7F;
                else // len_i == 5
                    s_axis_cc_tkeep      <= #(Tcq) 8'hFF;
                    
                s_axis_cc_tlast          <= #(Tcq) 1'b1;
                    
                len_i                    = 0;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_CC_RDY);
            end
            // End of First Data Beat
            //-----------------------------------------------------------------------\\
            // Start of Second and Subsequent Data Beat
            if (len_i != 0 || AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE") begin
                fork 
                
                begin // Sequential group 1 - AXIS CC
                    for (_j = start_addr; len_i != 0; _j = _j + 32) begin
                        if(_j == start_addr) begin 
                            aa_data = {
                                       DATA_STORE[_j + 31],
                                       DATA_STORE[_j + 30],
                                       DATA_STORE[_j + 29],
                                       DATA_STORE[_j + 28],
                                       DATA_STORE[_j + 27],
                                       DATA_STORE[_j + 26],
                                       DATA_STORE[_j + 25],
                                       DATA_STORE[_j + 24],
                                       DATA_STORE[_j + 23],
                                       DATA_STORE[_j + 22],
                                       DATA_STORE[_j + 21],
                                       DATA_STORE[_j + 20],
                                       DATA_STORE[_j + 19],
                                       DATA_STORE[_j + 18],
                                       DATA_STORE[_j + 17],
                                       DATA_STORE[_j + 16],
                                       DATA_STORE[_j + 15],
                                       DATA_STORE[_j + 14],
                                       DATA_STORE[_j + 13],
                                       DATA_STORE[_j + 12],
                                       DATA_STORE[_j + 11],
                                       DATA_STORE[_j + 10],
                                       DATA_STORE[_j + 9],
                                       DATA_STORE[_j + 8],
                                       DATA_STORE[_j + 7],
                                       DATA_STORE[_j + 6],
                                       DATA_STORE[_j + 5],
                                       DATA_STORE[_j + 4],
                                       DATA_STORE[_j + 3],
                                       DATA_STORE[_j + 2],
                                       DATA_STORE[_j + 1],
                                       DATA_STORE[_j + 0]
                                      } << (aa_dw*4*8);
                        end else begin
                            aa_data = {
                                       DATA_STORE[_j + 31 - (aa_dw*4)],
                                       DATA_STORE[_j + 30 - (aa_dw*4)],
                                       DATA_STORE[_j + 29 - (aa_dw*4)],
                                       DATA_STORE[_j + 28 - (aa_dw*4)],
                                       DATA_STORE[_j + 27 - (aa_dw*4)],
                                       DATA_STORE[_j + 26 - (aa_dw*4)],
                                       DATA_STORE[_j + 25 - (aa_dw*4)],
                                       DATA_STORE[_j + 24 - (aa_dw*4)],
                                       DATA_STORE[_j + 23 - (aa_dw*4)],
                                       DATA_STORE[_j + 22 - (aa_dw*4)],
                                       DATA_STORE[_j + 21 - (aa_dw*4)],
                                       DATA_STORE[_j + 20 - (aa_dw*4)],
                                       DATA_STORE[_j + 19 - (aa_dw*4)],
                                       DATA_STORE[_j + 18 - (aa_dw*4)],
                                       DATA_STORE[_j + 17 - (aa_dw*4)],
                                       DATA_STORE[_j + 16 - (aa_dw*4)],
                                       DATA_STORE[_j + 15 - (aa_dw*4)],
                                       DATA_STORE[_j + 14 - (aa_dw*4)],
                                       DATA_STORE[_j + 13 - (aa_dw*4)],
                                       DATA_STORE[_j + 12 - (aa_dw*4)],
                                       DATA_STORE[_j + 11 - (aa_dw*4)],
                                       DATA_STORE[_j + 10 - (aa_dw*4)],
                                       DATA_STORE[_j +  9 - (aa_dw*4)],
                                       DATA_STORE[_j +  8 - (aa_dw*4)],
                                       DATA_STORE[_j +  7 - (aa_dw*4)],
                                       DATA_STORE[_j +  6 - (aa_dw*4)],
                                       DATA_STORE[_j +  5 - (aa_dw*4)],
                                       DATA_STORE[_j +  4 - (aa_dw*4)],
                                       DATA_STORE[_j +  3 - (aa_dw*4)],
                                       DATA_STORE[_j +  2 - (aa_dw*4)],
                                       DATA_STORE[_j +  1 - (aa_dw*4)],
                                       DATA_STORE[_j +  0 - (aa_dw*4)]
                                      };
                        end
                                               
                        s_axis_cc_tdata           <= #(Tcq) aa_data;

                        if ((len_i)/8 == 0) begin
                            case (len_i % 8)
                              1 : begin len_i = len_i - 1; s_axis_cc_tkeep <= #(Tcq) 8'h01; end  // D0---------------------
                              2 : begin len_i = len_i - 2; s_axis_cc_tkeep <= #(Tcq) 8'h03; end  // D0-D1------------------
                              3 : begin len_i = len_i - 3; s_axis_cc_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2---------------
                              4 : begin len_i = len_i - 4; s_axis_cc_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------------
                              5 : begin len_i = len_i - 5; s_axis_cc_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4---------
                              6 : begin len_i = len_i - 6; s_axis_cc_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5------
                              7 : begin len_i = len_i - 7; s_axis_cc_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6---
                              0 : begin len_i = len_i - 8; s_axis_cc_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase
                        end else begin
                            len_i             = len_i - 8; s_axis_cc_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7

                        if (len_i == 0)
                            s_axis_cc_tlast          <= #(Tcq) 1'b1;
                        else
                            s_axis_cc_tlast          <= #(Tcq) 1'b0;
                            
                        // Call this just to check for the tready, but don't log anything. That's the job for pcie_tlp_data
                        // The reason for splitting the TSK_TX_SYNCHRONIZE task and distribute them in both sequential group
                        // is that in address aligned mode, it's possible that the additional padded zeros cause the AXIS CC
                        // to be one beat longer than the actual PCIe TLP. When it happens do not log the last clock beat
                        // but just send the packet on AXIS CC interface
                        TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_CC_RDY);
                    
                    end // for loop
                end // End sequential group 1 - AXIS CC
                
                begin // Sequential group 2 - pcie_tlp
                    for (_j = 20; _len != 0; _j = _j + 32) begin
                        pcie_tlp_data <= #(Tcq)    {
                                                    DATA_STORE[_j + 0],
                                                    DATA_STORE[_j + 1],
                                                    DATA_STORE[_j + 2],
                                                    DATA_STORE[_j + 3],
                                                    DATA_STORE[_j + 4],
                                                    DATA_STORE[_j + 5],
                                                    DATA_STORE[_j + 6],
                                                    DATA_STORE[_j + 7],
                                                    DATA_STORE[_j + 8],
                                                    DATA_STORE[_j + 9],
                                                    DATA_STORE[_j + 10],
                                                    DATA_STORE[_j + 11],
                                                    DATA_STORE[_j + 12],
                                                    DATA_STORE[_j + 13],
                                                    DATA_STORE[_j + 14],
                                                    DATA_STORE[_j + 15],
                                                    DATA_STORE[_j + 16],
                                                    DATA_STORE[_j + 17],
                                                    DATA_STORE[_j + 18],
                                                    DATA_STORE[_j + 19],
                                                    DATA_STORE[_j + 20],
                                                    DATA_STORE[_j + 21],
                                                    DATA_STORE[_j + 22],
                                                    DATA_STORE[_j + 23],
                                                    DATA_STORE[_j + 24],
                                                    DATA_STORE[_j + 25],
                                                    DATA_STORE[_j + 26],
                                                    DATA_STORE[_j + 27],
                                                    DATA_STORE[_j + 28],
                                                    DATA_STORE[_j + 29],
                                                    DATA_STORE[_j + 30],
                                                    DATA_STORE[_j + 31]
                                                   };
                                                   
                        if ((_len/8) == 0) begin
                            case (_len % 8)
                                1 : begin _len = _len - 1; pcie_tlp_rem  <= #(Tcq) 3'b111; end  // D0---------------------
                                2 : begin _len = _len - 2; pcie_tlp_rem  <= #(Tcq) 3'b110; end  // D0-D1------------------
                                3 : begin _len = _len - 3; pcie_tlp_rem  <= #(Tcq) 3'b101; end  // D0-D1-D2---------------
                                4 : begin _len = _len - 4; pcie_tlp_rem  <= #(Tcq) 3'b100; end  // D0-D1-D2-D3------------
                                5 : begin _len = _len - 5; pcie_tlp_rem  <= #(Tcq) 3'b011; end  // D0-D1-D2-D3-D4---------
                                6 : begin _len = _len - 6; pcie_tlp_rem  <= #(Tcq) 3'b010; end  // D0-D1-D2-D3-D4-D5------
                                7 : begin _len = _len - 7; pcie_tlp_rem  <= #(Tcq) 3'b001; end  // D0-D1-D2-D3-D4-D5-D6---
                                0 : begin _len = _len - 8; pcie_tlp_rem  <= #(Tcq) 3'b000; end  // D0-D1-D2-D3-D4-D5-D6-D7
                            endcase 
                        end else begin
                            _len               = _len - 8; pcie_tlp_rem   <= #(Tcq) 3'b000;     // D0-D1-D2-D3-D4-D5-D6-D7
                        end
                        
                        if (_len == 0)
                            TSK_TX_SYNCHRONIZE(0, 1, 1, `SYNC_CC_RDY);
                        else
                            TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_CC_RDY);
                    end // for loop
                end // End sequential group 2 - pcie_tlp

                join
            end  // if
            // End of Second and Subsequent Data Beat
            //-----------------------------------------------------------------------\\
            // Packet Complete - Drive 0s
            s_axis_cc_tvalid         <= #(Tcq) 1'b0;
            s_axis_cc_tlast          <= #(Tcq) 1'b0;
            s_axis_cc_tkeep          <= #(Tcq) 8'h00;
            s_axis_cc_tuser          <= #(Tcq) 60'b0;
            s_axis_cc_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b0;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_COMPLETION_DATA

    /************************************************************
    Task : TSK_TX_MESSAGE
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message TLP
    *************************************************************/

    task TSK_TX_MESSAGE;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [10:0]   len_;
        input    [63:0]   data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //--------- Tx Message Transaction :                          -----------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;          // 2DW Descriptor
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,       // Seq Number
                                                8'h00,         // TPH Steering Tag
                                                1'b0,          // TPH indirect Tag Enable
                                                2'b0,          // TPH Type
                                                1'b0,          // TPH Present
                                                1'b0,          // Discontinue
                                                3'b000,        // Byte Lane number in case of Address Aligned mode
                                                4'b0000,       // Last BE of the Read Data
                                                4'b0000 };     // First BE of the Read Data

            s_axis_rq_tdata          <= #(Tcq) {128'b0,        // 4DW unused
                                                1'b0,          // Force ECRC
                                                3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                tc_,           // Traffic Class
                                                1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                                5'b0,          // *reserved*
                                                message_rtg_,  // Message Routing
                                                message_code_, // Message Code
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b1100,       // Request Type for Message
                                                len_ ,         // DWORD Count
                                                data_[63:32],  // Vendor Defined Header Bytes
                                                data_[15: 0],  // Vendor ID
                                                data_[31:16]   // Destination ID
                                               };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b001,         // Fmt for Message w/o Data
                                                {{2'b10}, {message_rtg_}}, // Type for Message w/o Data
                                                1'b0,           // *reserved*
                                                tc_,            // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b0,          // DWORD Count                                     //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                message_code_,  // Message Code                                    //64
                                                data_[63:32],   // Vendor Defined Header Bytes
                                                data_[31:16],   // Destination ID
                                                data_[15: 0],   // Vendor ID
                                                128'b0          // *unused*
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MESSAGE

    /************************************************************
    Task : TSK_TX_MESSAGE_DATA
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message Data TLP
    *************************************************************/

    task TSK_TX_MESSAGE_DATA;
        input  [7:0]    tag_;
        input  [2:0]    tc_;
        input  [10:0]   len_;
        input  [63:0]   data_;
        input  [2:0]    message_rtg_;
        input  [7:0]    message_code_;
        reg    [127:0]  data_axis_i;
        reg    [127:0]  data_pcie_i;
        reg    [10:0]   _len;
        reg    [10:0]   len_i;
        integer         _j;
        begin
            //-----------------------------------------------------------------------\\
            data_axis_i = 0;
            data_pcie_i = 0;
            _len = len_;
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid  <= #(Tcq) 1'b1;

            data_axis_i        =  {
                                   DATA_STORE[15],
                                   DATA_STORE[14],
                                   DATA_STORE[13],
                                   DATA_STORE[12],
                                   DATA_STORE[11],
                                   DATA_STORE[10],
                                   DATA_STORE[9],
                                   DATA_STORE[8],
                                   data_
                                  };

            data_pcie_i        =  {
                                   DATA_STORE[0],
                                   DATA_STORE[1],
                                   DATA_STORE[2],
                                   DATA_STORE[3],
                                   DATA_STORE[4],
                                   DATA_STORE[5],
                                   DATA_STORE[6],
                                   DATA_STORE[7],
                                   DATA_STORE[8],
                                   DATA_STORE[9],
                                   DATA_STORE[10],
                                   DATA_STORE[11],
                                   DATA_STORE[12],
                                   DATA_STORE[13],
                                   DATA_STORE[14],
                                   DATA_STORE[15]
                                  };

            s_axis_rq_tuser   <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                         4'b1010,       // Seq Number
                                         8'h00,         // TPH Steering Tag
                                         1'b0,          // TPH indirect Tag Enable
                                         2'b0,          // TPH Type
                                         1'b0,          // TPH Present
                                         1'b0,          // Discontinue
                                         3'b000,        // Byte Lane number in case of Address Aligned mode
                                         4'b0000,       // Last BE of the Read Data
                                         4'b0000 };     // First BE of the Read Data

            s_axis_rq_tdata   <= #(Tcq) {data_axis_i,
                                         1'b0,          // Force ECRC
                                         3'b000,        // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                         tc_,           // Traffic Class
                                         1'b1,          // RID Enable to use the Client supplied Bus/Device/Func No
                                         5'b0,          // *reserved*
                                         message_rtg_,  // Message Routing
                                         message_code_, // Message Code
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                         RP_BUS_DEV_FNS, // Requester ID
                                         (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                         4'b1100,       // Request Type for Message
                                         len_ ,         // DWORD Count
                                         64'h0          // *unused*
                                        };
            //-----------------------------------------------------------------------\\
            pcie_tlp_data     <= #(Tcq) {
                                         3'b011,        // Fmt for Message with Data
                                         {{2'b10}, {message_rtg_}}, // Type for Message with Data
                                         1'b0,          // *reserved*
                                         tc_,           // 3-bit Traffic Class
                                         1'b0,           // *reserved*
                                         1'b0,           // Attributes {ID Based Ordering}
                                         1'b0,           // *reserved*
                                         1'b0,           // TLP Processing Hints
                                         1'b0,           // TLP Digest Present
                                         (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                         2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                         2'b00,          // Address Translation
                                         len_[9:0],      // DWORD Count                                            //32
                                         RP_BUS_DEV_FNS, // Requester ID
                                         (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                         message_code_,  // Message Code                                           //64
                                         data_,          // Message Data
                                         data_pcie_i
                                        };
            pcie_tlp_rem      <= #(Tcq)  3'b000;
            set_malformed     <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            if (_len > 4)
            begin
                len_i = len_ - 11'h4;
                s_axis_rq_tlast          <= #(Tcq) 1'b0;
                s_axis_rq_tkeep          <= #(Tcq) 8'hFF;
                TSK_TX_SYNCHRONIZE(1, 1, 0, `SYNC_RQ_RDY);
            end
            else
            begin
                len_i = len_;
                s_axis_rq_tlast          <= #(Tcq) 1'b1;

                if (_len == 1)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h1F;
                else if (_len == 2)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h3F;
                else if (_len == 3)
                    s_axis_rq_tkeep      <= #(Tcq) 8'h7F;
                else
                    s_axis_rq_tkeep      <= #(Tcq) 8'hFF;

                TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            end
            //-----------------------------------------------------------------------\\
            if (_len > 4) begin
                for (_j = 16; _j < (_len * 4); _j = _j + 32) begin

                    s_axis_rq_tdata   <= #(Tcq){
                                                DATA_STORE[_j + 31],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 0]
                                               };

                    pcie_tlp_data <= #(Tcq)    {
                                                DATA_STORE[_j + 0],
                                                DATA_STORE[_j + 1],
                                                DATA_STORE[_j + 2],
                                                DATA_STORE[_j + 3],
                                                DATA_STORE[_j + 4],
                                                DATA_STORE[_j + 5],
                                                DATA_STORE[_j + 6],
                                                DATA_STORE[_j + 7],
                                                DATA_STORE[_j + 8],
                                                DATA_STORE[_j + 9],
                                                DATA_STORE[_j + 10],
                                                DATA_STORE[_j + 11],
                                                DATA_STORE[_j + 12],
                                                DATA_STORE[_j + 13],
                                                DATA_STORE[_j + 14],
                                                DATA_STORE[_j + 15],
                                                DATA_STORE[_j + 16],
                                                DATA_STORE[_j + 17],
                                                DATA_STORE[_j + 18],
                                                DATA_STORE[_j + 19],
                                                DATA_STORE[_j + 20],
                                                DATA_STORE[_j + 21],
                                                DATA_STORE[_j + 22],
                                                DATA_STORE[_j + 23],
                                                DATA_STORE[_j + 24],
                                                DATA_STORE[_j + 25],
                                                DATA_STORE[_j + 26],
                                                DATA_STORE[_j + 27],
                                                DATA_STORE[_j + 28],
                                                DATA_STORE[_j + 29],
                                                DATA_STORE[_j + 30],
                                                DATA_STORE[_j + 31]
                                               };

                    if ((_j + 31)  >=  (_len * 4 - 1)) begin
                        case (((_len - 11'h4)) % 8)
                          1 : begin len_i = len_i - 1; pcie_tlp_rem  <= #(Tcq) 3'b111; s_axis_rq_tkeep <= #(Tcq) 8'h01; end  // D0---------
                          2 : begin len_i = len_i - 2; pcie_tlp_rem  <= #(Tcq) 3'b110; s_axis_rq_tkeep <= #(Tcq) 8'h03; end  // D0-D1--------
                          3 : begin len_i = len_i - 3; pcie_tlp_rem  <= #(Tcq) 3'b101; s_axis_rq_tkeep <= #(Tcq) 8'h07; end  // D0-D1-D2-------
                          4 : begin len_i = len_i - 4; pcie_tlp_rem  <= #(Tcq) 3'b100; s_axis_rq_tkeep <= #(Tcq) 8'h0F; end  // D0-D1-D2-D3------
                          5 : begin len_i = len_i - 5; pcie_tlp_rem  <= #(Tcq) 3'b011; s_axis_rq_tkeep <= #(Tcq) 8'h1F; end  // D0-D1-D2-D3-D4-----
                          6 : begin len_i = len_i - 6; pcie_tlp_rem  <= #(Tcq) 3'b010; s_axis_rq_tkeep <= #(Tcq) 8'h3F; end  // D0-D1-D2-D3-D4-D5--
                          7 : begin len_i = len_i - 7; pcie_tlp_rem  <= #(Tcq) 3'b001; s_axis_rq_tkeep <= #(Tcq) 8'h7F; end  // D0-D1-D2-D3-D4-D5-D6
                          0 : begin len_i = len_i - 8; pcie_tlp_rem  <= #(Tcq) 3'b000; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7----
                        endcase end
                    else begin len_i = len_i - 8; pcie_tlp_rem   <= #(Tcq) 3'b000; s_axis_rq_tkeep <= #(Tcq) 8'hFF; end  // D0-D1-D2-D3-D4-D5-D6-D7--

                    if (len_i == 0) begin
                        s_axis_rq_tlast          <= #(Tcq) 1'b1;
                        TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY); end
                    else
                        TSK_TX_SYNCHRONIZE(0, 1, 0, `SYNC_RQ_RDY);
                end // for
            end  // if
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_MESSAGE_DATA


    /************************************************************
    Task : TSK_TX_IO_READ
    Inputs : Tag, Address
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Read TLP
    *************************************************************/

    task TSK_TX_IO_READ;
        input    [7:0]    tag_;
        input    [31:0]   addr_;
        input    [3:0]    first_dw_be_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h0F;
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,        // Seq Number
                                                8'h00,          // TPH Steering Tag
                                                1'b0,           // TPH indirect Tag Enable
                                                2'b0,           // TPH Type
                                                1'b0,           // TPH Present
                                                1'b0,           // Discontinue
                                                3'b000,         // Byte Lane number in case of Address Aligned mode
                                                4'b0000,        // Last BE of the Read Data
                                                first_dw_be_ }; // First BE of the Read Data

            s_axis_rq_tdata          <= #(Tcq) {128'b0,         // *unused*                                           //256
                                                1'b0,           // Force ECRC                                         //128
                                                3'b000,         // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,         // Traffic Class
                                                1'b1,           // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS,   // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS,   // Requester ID -- Used only when RID enable = 1    //96
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                4'b0010,        // Req Type for IORd Req
                                                11'b1,          // DWORD Count
                                                32'b0,          // 32-bit Addressing. So, bits[63:32] = 0             //64
                                                addr_[31:2],    // IO read address 32-bits                            //32
                                                2'b00};         // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b000,         // Fmt for IO Read Req
                                                5'b00010,       // Type for IO Read Req
                                                1'b0,           // *reserved*
                                                3'b000,         // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b1,          // DWORD Count                                        //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0,           // Last DW Byte Enable
                                                first_dw_be_,   // First DW Byte Enable                               //64
                                                addr_[31:2],    // Address
                                                2'b00,          // *reserved*                                         //96
                                                32'b0,          // *unused*                                           //128
                                                128'b0          // *unused*                                           //256
                                               };
                                               
            pcie_tlp_rem             <= #(Tcq)  3'b101;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_IO_READ

    /************************************************************
    Task : TSK_TX_IO_WRITE
    Inputs : Tag, Address, Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Write TLP
    *************************************************************/

    task TSK_TX_IO_WRITE;
        input    [7:0]    tag_;
        input    [31:0]   addr_;
        input    [3:0]    first_dw_be_;
        input    [31:0]   data_;
        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(0, 0, 0, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b1;
            s_axis_rq_tlast          <= #(Tcq) 1'b1;
            s_axis_rq_tkeep          <= #(Tcq) 8'h1F;           // 2DW Descriptor for Memory Transactions alone
            s_axis_rq_tuser          <= #(Tcq) {(ATTR_AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 32'b0), // Parity
                                                4'b1010,        // Seq Number
                                                8'h00,          // TPH Steering Tag
                                                1'b0,           // TPH indirect Tag Enable
                                                2'b0,           // TPH Type
                                                1'b0,           // TPH Present
                                                1'b0,           // Discontinue
                                                3'b000,         // Byte Lane number in case of Address Aligned mode
                                                4'b0000,        // Last BE of the Read Data
                                                first_dw_be_ }; // First BE of the Read Data

            s_axis_rq_tdata          <= #(Tcq) {32'b0,          // *unused*
                                                32'b0,          // *unused*
                                                32'b0,          // *unused*
                                                data_,          // IO Write data on 5th DW
                                                1'b0,           // Force ECRC                                         //128
                                                3'b000,         // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                                3'b000,         // Traffic Class
                                                1'b1,           // RID Enable to use the Client supplied Bus/Device/Func No
                                                EP_BUS_DEV_FNS, // Completer ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                RP_BUS_DEV_FNS, // Requester ID -- Used only when RID enable = 1      //96
                                                (set_malformed ? 1'b1 : 1'b0),       // Poisoned Req
                                                4'b0011,        // Req Type for IOWr Req
                                                11'b1 ,         // DWORD Count
                                                32'b0,          // 32-bit Addressing. So, bits[63:32] = 0             //64
                                                addr_[31:2],    // IO Write address 32-bits                           //32
                                                2'b00};         // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tlp_data            <= #(Tcq) {
                                                3'b010,         // Fmt for IO Write Req
                                                5'b00010,       // Type for IO Write Req
                                                1'b0,           // *reserved*
                                                3'b000,         // 3-bit Traffic Class
                                                1'b0,           // *reserved*
                                                1'b0,           // Attributes {ID Based Ordering}
                                                1'b0,           // *reserved*
                                                1'b0,           // TLP Processing Hints
                                                1'b0,           // TLP Digest Present
                                                (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                                2'b00,          // Attributes {Relaxed Ordering, No Snoop}
                                                2'b00,          // Address Translation
                                                10'b1,          // DWORD Count                                        //32
                                                RP_BUS_DEV_FNS, // Requester ID
                                                (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? tag_ : 8'hCC), // Tag
                                                4'b0,           // last DW Byte Enable
                                                first_dw_be_,   // First DW Byte Enable                               //64
                                                addr_[31:2],    // Address
                                                2'b00,          // *reserved*                                         //96
                                                data_[7:0],     // IO Write Data
                                                data_[15:8],    // IO Write Data
                                                data_[23:16],   // IO Write Data
                                                data_[31:24],   // IO Write Data                                      //128
                                                128'b0          // *unused*                                           //256
                                               };

            pcie_tlp_rem             <= #(Tcq)  3'b100;
            set_malformed            <= #(Tcq)  1'b0;
            //-----------------------------------------------------------------------\\
            TSK_TX_SYNCHRONIZE(1, 1, 1, `SYNC_RQ_RDY);
            //-----------------------------------------------------------------------\\
            s_axis_rq_tvalid         <= #(Tcq) 1'b0;
            s_axis_rq_tlast          <= #(Tcq) 1'b0;
            s_axis_rq_tkeep          <= #(Tcq) 8'h00;
            s_axis_rq_tuser          <= #(Tcq) 60'b0;
            s_axis_rq_tdata          <= #(Tcq) 256'b0;
            //-----------------------------------------------------------------------\\
            pcie_tlp_rem             <= #(Tcq) 3'b000;
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_IO_WRITE

    /************************************************************
    Task : TSK_TX_SYNCHRONIZE
    Inputs : None
    Outputs : None
    Description : Synchronize with tx clock and handshake signals
    *************************************************************/

    task TSK_TX_SYNCHRONIZE;
        input        first_;        // effectively sof
        input        active_;       // in pkt -- for pcie_tlp_data signaling only
        input        last_call_;    // eof
        input        tready_sw_;    // A switch to select CC or RQ tready

        begin
            //-----------------------------------------------------------------------\\
            if (user_lnk_up_n) begin
                $display("[%t] :  interface is MIA", $realtime);
                $finish(1);
            end
            //-----------------------------------------------------------------------\\

            @(posedge user_clk);
            if (tready_sw_ == `SYNC_CC_RDY) begin
                while (s_axis_cc_tready == 1'b0) begin
                    @(posedge user_clk);
                end
            end else begin // tready_sw_ == `SYNC_RQ_RDY
                while (s_axis_rq_tready == 1'b0) begin
                    @(posedge user_clk);
                end
            end
            //-----------------------------------------------------------------------\\
            if (active_ == 1'b1) begin
                // read data driven into memory
                board.RP.com_usrapp.TSK_READ_DATA_256(first_, last_call_,`TX_LOG,pcie_tlp_data,pcie_tlp_rem);
            end
            //-----------------------------------------------------------------------\\
            if (last_call_)
                 board.RP.com_usrapp.TSK_PARSE_FRAME(`TX_LOG);
            //-----------------------------------------------------------------------\\
        end
    endtask // TSK_TX_SYNCHRONIZE

    /************************************************************
    Task : TSK_TX_BAR_READ
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32,64 or IO Read TLP
                  requesting 1 dword
    *************************************************************/

    task TSK_TX_BAR_READ;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;


        begin


          case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin
              if (verbose) $display("[%t] : IOREAD, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));

                          TSK_TX_IO_READ(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF);
                end

        2'b10 : // MEM 32 SPACE
            begin

  if (verbose) $display("[%t] : MEMREAD32, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
                           TSK_TX_MEMORY_READ_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF);
                end
        2'b11 : // MEM 64 SPACE
                begin
                   if (verbose) $display("[%t] : MEMREAD64, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
               TSK_TX_MEMORY_READ_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[ii+1][31:0],
                                    BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF);


                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_READ");
                  end
      endcase

        end
    endtask // TSK_TX_BAR_READ



    /************************************************************
    Task : TSK_TX_BAR_WRITE
    Inputs : Bar Index, Byte Offset, Tag, Tc, 32 bit Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32, 64, IO TLP with
                  32 bit data
    *************************************************************/

    task TSK_TX_BAR_WRITE;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [31:0]   data_;

        begin

        case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin

              if (verbose) $display("[%t] : IOWRITE, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                          TSK_TX_IO_WRITE(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF, data_);

                end

        2'b10 : // MEM 32 SPACE
            begin

               DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
               if (verbose) $display("[%t] : MEMWRITE32, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF, 1'b0);

                end
        2'b11 : // MEM 64 SPACE
                begin

                   DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
                   if (verbose) $display("[%t] : MEMWRITE64, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[bar_index+1][31:0],
                                      BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF, 1'b0);



                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_WRITE");
                  end
    endcase


        end
    endtask // TSK_TX_BAR_WRITE

    /************************************************************
    Task : TSK_USR_DATA_SETUP_SEQ
    Inputs : None
    Outputs : None
    Description : Populates scratch pad data area with known good data.
    *************************************************************/

    task TSK_USR_DATA_SETUP_SEQ;
        integer        i_;
        begin
            for (i_ = 0; i_ <= 4095; i_ = i_ + 1) begin
                DATA_STORE[i_] = i_;
            end
        end
    endtask // TSK_USR_DATA_SETUP_SEQ

    /************************************************************
    Task : TSK_TX_CLK_EAT
    Inputs : None
    Outputs : None
    Description : Consume clocks.
    *************************************************************/

    task TSK_TX_CLK_EAT;
        input    [31:0]            clock_count;
        integer            i_;
        begin
            for (i_ = 0; i_ < clock_count; i_ = i_ + 1) begin

                @(posedge user_clk);

            end
        end
    endtask // TSK_TX_CLK_EAT

  /************************************************************
  Task: TSK_SIMULATION_TIMEOUT
  Description: Set simulation timeout value
  *************************************************************/
  task TSK_SIMULATION_TIMEOUT;
    input [31:0] timeout;
    begin
      force board.RP.rx_usrapp.sim_timeout = timeout;
    end
  endtask

    /************************************************************
    Task : TSK_SET_READ_DATA
    Inputs : Data
    Outputs : None
    Description : Called from common app. Common app hands read
                  data to usrapp_tx.
    *************************************************************/

    task TSK_SET_READ_DATA;

        input   [3:0]   be_;   // not implementing be's yet
        input   [63:0]  data_; // might need to change this to byte
        begin

          P_READ_DATA   = data_[31:0];
          P_READ_DATA_2 = data_[63:32];
          P_READ_DATA_VALID = 1;

        end
    endtask // TSK_SET_READ_DATA

    /************************************************************
    Task : TSK_WAIT_FOR_READ_DATA
    Inputs : None
    Outputs : Read data P_READ_DATA will be valid
    Description : Called from tx app. Common app hands read
                  data to usrapp_tx. This task must be executed
                  immediately following a call to
                  TSK_TX_TYPE0_CONFIGURATION_READ in order for the
                  read process to function correctly. Otherwise
                  there is a potential race condition with
                  P_READ_DATA_VALID.
    *************************************************************/

    task TSK_WAIT_FOR_READ_DATA;

                integer j;

        begin
                  j = 30;
                  P_READ_DATA_VALID = 0;
                  fork
                   while ((!P_READ_DATA_VALID) && (cpld_to == 0)) @(posedge user_clk);
                   begin // second process
                     while ((j > 0) && (!P_READ_DATA_VALID))
                       begin
                         TSK_TX_CLK_EAT(500);
                         j = j - 1;
                       end
                       if (!P_READ_DATA_VALID) begin
                        cpld_to = 1;
                        if (cpld_to_finish == 1) begin
                            $display("TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");
                            $finish;
                          end
                        else
                            $display("TIMEOUT WARNING in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");

                     end
                   end

          join

        end
    endtask // TSK_WAIT_FOR_READ_DATA

    /************************************************************
    Function : TSK_DISPLAY_PCIE_MAP
    Inputs : none
    Outputs : none
    Description : Displays the Memory Manager's P_MAP calculations
                  based on range values read from PCI_E device.
    *************************************************************/

        task TSK_DISPLAY_PCIE_MAP;

           reg[2:0] ii;

           begin

             for (ii=0; ii <= 6; ii = ii + 1) begin
                 if (ii !=6) begin

                   $display("\tBAR %x: VALUE = %x RANGE = %x TYPE = %s", ii, BAR_INIT_P_BAR[ii][31:0],
                     BAR_INIT_P_BAR_RANGE[ii], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[ii]]);

                 end
                 else begin

                   $display("\tEROM : VALUE = %x RANGE = %x TYPE = %s", BAR_INIT_P_BAR[6][31:0],
                     BAR_INIT_P_BAR_RANGE[6], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[6]]);

                 end
             end

           end

        endtask

    /************************************************************
    Task : TSK_BUILD_PCIE_MAP
    Inputs :
    Outputs :
    Description : Looks at range values read from config space and
                  builds corresponding mem/io map
    *************************************************************/

    task TSK_BUILD_PCIE_MAP;

                integer ii;

        begin

                  $display("[%t] PCI EXPRESS BAR MEMORY/IO MAPPING PROCESS BEGUN...",$realtime);

              // handle bars 0-6 (including erom)
              for (ii = 0; ii <= 6; ii = ii + 1) begin

                  if (BAR_INIT_P_BAR_RANGE[ii] != 32'h0000_0000) begin

                     if ((ii != 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) begin // if not erom and io bit set

                        // bar is io mapped
                        NUMBER_OF_IO_BARS = NUMBER_OF_IO_BARS + 1;

                        if (pio_check_design && (NUMBER_OF_IO_BARS > 1)) begin

                          $display("[%t] Warning: PIO design only supports 1 IO BAR. Testbench will disable BAR %x",$realtime, ii);
                          BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                        end

                        else BAR_INIT_P_BAR_ENABLED[ii] = 2'h1;

                        if (!OUT_OF_IO) begin

                           // We need to calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_IO_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                  if (BAR_INIT_TEMP < BAR_INIT_P_IO_START) begin
                                     // Current BAR_INIT_P_IO_START is NOT correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                      BAR_INIT_P_IO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current BAR_INIT_P_IO_START is correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_P_IO_START;
                                      BAR_INIT_P_IO_START = BAR_INIT_P_IO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                                  OUT_OF_IO = BAR_INIT_P_BAR[ii][32];

                              if (OUT_OF_IO) begin

                                 $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                              end

                        end
                          else begin

                               $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                          end



                     end // bar is io mapped

                     else begin

                        // bar is mem mapped
                        if ((ii != 5) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0004)) begin

                           // bar is mem64 mapped - memManager is not handling out of 64bit memory
                               NUMBER_OF_MEM64_BARS = NUMBER_OF_MEM64_BARS + 1;

                               if (pio_check_design && (NUMBER_OF_MEM64_BARS > 1)) begin

                              $display("[%t] Warning: PIO design only supports 1 MEM64 BAR. Testbench will disable BAR %x",$realtime, ii);
                              BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                           end

                           else BAR_INIT_P_BAR_ENABLED[ii] = 2'h3; // bar is mem64 mapped


                           if ( (BAR_INIT_P_BAR_RANGE[ii] & 32'hFFFF_FFF0) == 32'h0000_0000) begin

                              // Mem64 space has range larger than 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_HI_START & BAR_INIT_P_BAR_RANGE[ii+1];

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_HI_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_BAR[ii+1] + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_MEM64_LO_START = 32'h0000_0000;

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_MEM64_HI_START + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);

                                  end

                           end
                           else begin

                              // Mem64 space has range less than/equal 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_LO_START & (BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0);

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_LO_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_P_MEM64_LO_START;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_MEM64_LO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                           end

                              // skip over the next bar since it is being used by the 64bit bar
                              ii = ii + 1;

                        end
                        else begin

                           if ( (ii != 6) || ((ii == 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) ) begin
                              // handling general mem32 case and erom case

                              // bar is mem32 mapped
                              if (ii != 6) begin

                                 NUMBER_OF_MEM32_BARS = NUMBER_OF_MEM32_BARS + 1; // not counting erom space

                                 if (pio_check_design && (NUMBER_OF_MEM32_BARS > 1)) begin

                                    // PIO design only supports 1 general purpose MEM32 BAR (not including EROM).
                                    $display("[%t] Warning: PIO design only supports 1 MEM32 BAR. Testbench will disable BAR %x",$realtime, ii);
                                    BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                                 end

                                 else  BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // bar is mem32 mapped

                              end

                              else BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // erom bar is mem32 mapped

                              if (!OUT_OF_LO_MEM) begin

                                     // We need to calculate where the next BAR should start based on the BAR's range
                                     BAR_INIT_TEMP = BAR_INIT_P_MEM32_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                     if (BAR_INIT_TEMP < BAR_INIT_P_MEM32_START) begin

                                         // Current MEM32_START is NOT correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end
                                     else begin

                                         // Initial BAR case and Current MEM32_START is correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_P_MEM32_START;
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_MEM32_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end


     if (ii == 6) begin

        // make sure to set enable bit if we are mapping the erom space

        BAR_INIT_P_BAR[ii] = BAR_INIT_P_BAR[ii] | 33'h1;


     end


                                 OUT_OF_LO_MEM = BAR_INIT_P_BAR[ii][32];

                                 if (OUT_OF_LO_MEM) begin

                                    $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                                 end

                              end
                              else begin

                                     $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                              end

                           end

                        end

                     end

                  end

              end


                  if ( (OUT_OF_IO) | (OUT_OF_LO_MEM) | (OUT_OF_HI_MEM)) begin
                     TSK_DISPLAY_PCIE_MAP;
                     $display("ERROR: Ending simulation: Memory Manager is out of memory/IO to allocate to PCI Express device");
                     $finish;

                  end


        end

    endtask // TSK_BUILD_PCIE_MAP


   /************************************************************
        Task : TSK_BAR_SCAN
        Inputs : None
        Outputs : None
        Description : Scans PCI core's configuration registers.
   *************************************************************/

    task TSK_BAR_SCAN;
       begin

        //--------------------------------------------------------------------------
        // Write PCI_MASK to bar's space via PCIe fabric interface to find range
        //--------------------------------------------------------------------------

        P_ADDRESS_MASK          = 32'hffff_ffff;
    DEFAULT_TAG         = 0;
    DEFAULT_TC          = 0;


        $display("[%t] : Inspecting Core Configuration Space...", $realtime);

    // Determine Range for BAR0

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR0 Range

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[0] = P_READ_DATA;


    // Determine Range for BAR1

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR1 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[1] = P_READ_DATA;


    // Determine Range for BAR2

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);


    // Read BAR2 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[2] = P_READ_DATA;


    // Determine Range for BAR3

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR3 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[3] = P_READ_DATA;


    // Determine Range for BAR4

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR4 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[4] = P_READ_DATA;


    // Determine Range for BAR5

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR5 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[5] = P_READ_DATA;


    // Determine Range for Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;
        BAR_INIT_P_BAR_RANGE[6] = P_READ_DATA;

       end
    endtask // TSK_BAR_SCAN


   /************************************************************
        Task : TSK_BAR_PROGRAM
        Inputs : None
        Outputs : None
        Description : Program's PCI core's configuration registers.
   *************************************************************/

    task TSK_BAR_PROGRAM;
       begin

        //--------------------------------------------------------------------------
        // Write core configuration space via PCIe fabric interface
        //--------------------------------------------------------------------------

        DEFAULT_TAG     = 0;

        $display("[%t] : Setting Core Configuration Space...", $realtime);

    // Program BAR0

    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, BAR_INIT_P_BAR[0][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR1

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, BAR_INIT_P_BAR[1][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR2

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, BAR_INIT_P_BAR[2][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR3

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, BAR_INIT_P_BAR[3][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR4

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, BAR_INIT_P_BAR[4][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program BAR5

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, BAR_INIT_P_BAR[5][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, BAR_INIT_P_BAR[6][31:0], 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program PCI Command Register

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h04, 32'h00000003, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Program PCIe Device Control Register

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'hC8, 32'h0000005f, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(1000);

       end
    endtask // TSK_BAR_PROGRAM


   /************************************************************
        Task : TSK_BAR_INIT
        Inputs : None
        Outputs : None
        Description : Initialize PCI core based on core's configuration.
   *************************************************************/

    task TSK_BAR_INIT;
       begin

        TSK_BAR_SCAN;

        TSK_BUILD_PCIE_MAP;

        TSK_DISPLAY_PCIE_MAP;

        TSK_BAR_PROGRAM;

       end
    endtask // TSK_BAR_INIT



   /************************************************************
        Task : TSK_TX_READBACK_CONFIG
        Inputs : None
        Outputs : None
        Description : Read core configuration space via PCIe fabric interface
   *************************************************************/

    task TSK_TX_READBACK_CONFIG;
       begin


        //--------------------------------------------------------------------------
        // Read core configuration space via PCIe fabric interface
        //--------------------------------------------------------------------------

        $display("[%t] : Reading Core Configuration Space...", $realtime);

    // Read BAR0

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR1

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR2

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR3

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR4

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read BAR5

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read PCI Command Register

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h04, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

    // Read PCIe Device Control Register

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'hC8, 4'h1);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(1000);

      end
    endtask // TSK_TX_READBACK_CONFIG


   /************************************************************
        Task : TSK_CFG_READBACK_CONFIG
        Inputs : None
        Outputs : None
        Description : Read core configuration space via CFG interface
   *************************************************************/

    task TSK_CFG_READBACK_CONFIG;
       begin


    //--------------------------------------------------------------------------
    // Read core configuration space via configuration (host) interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading Local Configuration Space via CFG interface...", $realtime);

    CFG_DWADDR = 10'h0;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h4;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h5;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h6;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h7;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h8;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h9;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'hc;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h17;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h18;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h19;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h1a;
    board.RP.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

      end
    endtask // TSK_CFG_READBACK_CONFIG



/************************************************************
        Task : TSK_MEM_TEST_DATA_BUS
        Inputs : bar_index
        Outputs : None
        Description : Test the data bus wiring in a specific memory
               by executing a walking 1's test at a set address
               within that region.
*************************************************************/

task TSK_MEM_TEST_DATA_BUS;
   input [2:0]  bar_index;
   reg [31:0] pattern;
   reg success;
   begin

    $display("[%t] : Performing Memory data test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    // Perform a walking 1's test at the given address.
    for (pattern = 1; pattern != 0; pattern = pattern << 1)
      begin
        // Write the test pattern. *address = pattern;pio_memTestAddrBus_test1

        TSK_TX_BAR_WRITE(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC, pattern);
        TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);


        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Data Error Mismatch, Address: %x Write Data %x != Read Data %x", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], pattern, P_READ_DATA);
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Address: %x Write Data: %x successfully received", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end  // for loop
    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DATA_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DATA_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DATA_BUS



/************************************************************
        Task : TSK_MEM_TEST_ADDR_BUS
        Inputs : bar_index, nBytes
        Outputs : None
        Description : Test the address bus wiring in a specific memory by
               performing a walking 1's test on the relevant bits
               of the address and checking for multiple writes/aliasing.
               This test will find single-bit address failures such as stuck
               -high, stuck-low, and shorted pins.

*************************************************************/

task TSK_MEM_TEST_ADDR_BUS;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] addressMask;
   reg [31:0] offset;
   reg [31:0] testOffset;
   reg success;
   reg stuckHi_success;
   reg stuckLo_success;
   begin

    $display("[%t] : Performing Memory address test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    stuckHi_success = 1;
    stuckLo_success = 1;

    pattern =     32'hAAAAAAAA;
    antipattern = 32'h55555555;

    // divide by 4 because the block RAMS we are testing are 32bit wide
    // and therefore the low two bits are not meaningful for addressing purposes
    // for this test.
    addressMask = (nBytes/4 - 1);

    $display("[%t] : Checking for address bits stuck high", $realtime);
    // Write the default pattern at each of the power-of-two offsets.
    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin

        verbose = 1;

        // baseAddress[offset] = pattern
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
      end



    // Check for address bits stuck high.
    // It should be noted that since the write address and read address pins are different
    // for the block RAMs used in the PIO design, the stuck high test will only catch an error if both
    // read and write addresses are both stuck hi. Otherwise the remaining portion of the tests
    // will catch if only one of the addresses are stuck hi.

    testOffset = 0;

    // baseAddress[testOffset] = antipattern;
    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;


    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                     $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
             stuckHi_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

     end


    if (stuckHi_success == 1)
        $display("[%t] : Stuck Hi Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Hi Address Test failed", $realtime);


    $display("[%t] : Checking for address bits stuck low or shorted", $realtime);

    //baseAddress[testOffset] = pattern;

    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;

    // Check for address bits stuck low or shorted.
    for (testOffset = 1; (testOffset & addressMask) != 0; testOffset = testOffset << 1)
      begin

        //baseAddress[testOffset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)      // if (baseAddress[0] != pattern)

           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*0), pattern, P_READ_DATA);
             stuckLo_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


        for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
           begin

             TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

             TSK_WAIT_FOR_READ_DATA;
             // if ((baseAddress[offset] != pattern) && (offset != testOffset))
             if  ((P_READ_DATA != pattern) && (offset != testOffset))
                begin
                  $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                                 pattern, P_READ_DATA);
                  stuckLo_success = 0;
                  success = 0;
                  $finish;
                end
             else
                begin
                  $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                                              $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                              P_READ_DATA);
                end
             TSK_TX_CLK_EAT(10);
             DEFAULT_TAG = DEFAULT_TAG + 1;

          end

        // baseAddress[testOffset] = pattern;


        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end

    if (stuckLo_success == 1)
        $display("[%t] : Stuck Low Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Low Address Test failed", $realtime);


    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_ADDR_BUS



/************************************************************
        Task : TSK_MEM_TEST_DEVICE
        Inputs : bar_index, nBytes
        Outputs : None
 *      Description: Test the integrity of a physical memory device by
 *              performing an increment/decrement test over the
 *              entire region.  In the process every storage bit
 *              in the device is tested as a zero and a one.  The
 *              bar_index and the size of the region are
 *              selected by the caller.
*************************************************************/

task TSK_MEM_TEST_DEVICE;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] offset;
   reg [31:0] nWords;
   reg success;
   begin

    $display("[%t] : Performing Memory device test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success

    nWords = nBytes / 4;

    pattern = 1;
    // Fill memory with a known pattern.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin

        verbose = 1;

        //baseAddress[offset] = pattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        pattern = pattern + 1;
    end


   pattern = 1;
    // Check each location and invert it for the second pass.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != pattern)
        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end


        antipattern = ~pattern;

        //baseAddress[offset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


       pattern = pattern + 1;
    end

    pattern = 1;
    // Check each location for the inverted pattern
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin
        antipattern = ~pattern;

        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != antipattern)

        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end
        pattern = pattern + 1;
    end

     if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DEVICE successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DEVICE completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DEVICE




        /************************************************************
    Function : FNC_CONVERT_RANGE_TO_SIZE_32
    Inputs : BAR index for 32 bit BAR
    Outputs : 32 bit BAR size
    Description : Called from tx app. Note that the smallest range
                  supported by this function is 16 bytes.
    *************************************************************/

    function [31:0] FNC_CONVERT_RANGE_TO_SIZE_32;
                input [31:0] bar_index;
                reg   [32:0] return_value;
        begin
                  case (BAR_INIT_P_BAR_RANGE[bar_index] & 32'hFFFF_FFF0) // AND off control bits
                    32'hFFFF_FFF0 : return_value = 33'h0000_0010;
                    32'hFFFF_FFE0 : return_value = 33'h0000_0020;
                    32'hFFFF_FFC0 : return_value = 33'h0000_0040;
                    32'hFFFF_FF80 : return_value = 33'h0000_0080;
                    32'hFFFF_FF00 : return_value = 33'h0000_0100;
                    32'hFFFF_FE00 : return_value = 33'h0000_0200;
                    32'hFFFF_FC00 : return_value = 33'h0000_0400;
                    32'hFFFF_F800 : return_value = 33'h0000_0800;
                    32'hFFFF_F000 : return_value = 33'h0000_1000;
                    32'hFFFF_E000 : return_value = 33'h0000_2000;
                    32'hFFFF_C000 : return_value = 33'h0000_4000;
                    32'hFFFF_8000 : return_value = 33'h0000_8000;
                    32'hFFFF_0000 : return_value = 33'h0001_0000;
                    32'hFFFE_0000 : return_value = 33'h0002_0000;
                    32'hFFFC_0000 : return_value = 33'h0004_0000;
                    32'hFFF8_0000 : return_value = 33'h0008_0000;
                    32'hFFF0_0000 : return_value = 33'h0010_0000;
                    32'hFFE0_0000 : return_value = 33'h0020_0000;
                    32'hFFC0_0000 : return_value = 33'h0040_0000;
                    32'hFF80_0000 : return_value = 33'h0080_0000;
                    32'hFF00_0000 : return_value = 33'h0100_0000;
                    32'hFE00_0000 : return_value = 33'h0200_0000;
                    32'hFC00_0000 : return_value = 33'h0400_0000;
                    32'hF800_0000 : return_value = 33'h0800_0000;
                    32'hF000_0000 : return_value = 33'h1000_0000;
                    32'hE000_0000 : return_value = 33'h2000_0000;
                    32'hC000_0000 : return_value = 33'h4000_0000;
                    32'h8000_0000 : return_value = 33'h8000_0000;
                    default :      return_value = 33'h0000_0000;
                  endcase

                  FNC_CONVERT_RANGE_TO_SIZE_32 = return_value;
        end
    endfunction // FNC_CONVERT_RANGE_TO_SIZE_32



    /************************************************************
    Function : FNC_CONVERT_RANGE_TO_SIZE_HI32
    Inputs : BAR index for upper 32 bit BAR of 64 bit address
    Outputs : upper 32 bit BAR size
    Description : Called from tx app.
    *************************************************************/

    function [31:0] FNC_CONVERT_RANGE_TO_SIZE_HI32;
                input [31:0] bar_index;
                reg   [32:0] return_value;
        begin
                  case (BAR_INIT_P_BAR_RANGE[bar_index])
                    32'hFFFF_FFFF : return_value = 33'h00000_0001;
                    32'hFFFF_FFFE : return_value = 33'h00000_0002;
                    32'hFFFF_FFFC : return_value = 33'h00000_0004;
                    32'hFFFF_FFF8 : return_value = 33'h00000_0008;
                    32'hFFFF_FFF0 : return_value = 33'h00000_0010;
                    32'hFFFF_FFE0 : return_value = 33'h00000_0020;
                    32'hFFFF_FFC0 : return_value = 33'h00000_0040;
                    32'hFFFF_FF80 : return_value = 33'h00000_0080;
                    32'hFFFF_FF00 : return_value = 33'h00000_0100;
                    32'hFFFF_FE00 : return_value = 33'h00000_0200;
                    32'hFFFF_FC00 : return_value = 33'h00000_0400;
                    32'hFFFF_F800 : return_value = 33'h00000_0800;
                    32'hFFFF_F000 : return_value = 33'h00000_1000;
                    32'hFFFF_E000 : return_value = 33'h00000_2000;
                    32'hFFFF_C000 : return_value = 33'h00000_4000;
                    32'hFFFF_8000 : return_value = 33'h00000_8000;
                    32'hFFFF_0000 : return_value = 33'h00001_0000;
                    32'hFFFE_0000 : return_value = 33'h00002_0000;
                    32'hFFFC_0000 : return_value = 33'h00004_0000;
                    32'hFFF8_0000 : return_value = 33'h00008_0000;
                    32'hFFF0_0000 : return_value = 33'h00010_0000;
                    32'hFFE0_0000 : return_value = 33'h00020_0000;
                    32'hFFC0_0000 : return_value = 33'h00040_0000;
                    32'hFF80_0000 : return_value = 33'h00080_0000;
                    32'hFF00_0000 : return_value = 33'h00100_0000;
                    32'hFE00_0000 : return_value = 33'h00200_0000;
                    32'hFC00_0000 : return_value = 33'h00400_0000;
                    32'hF800_0000 : return_value = 33'h00800_0000;
                    32'hF000_0000 : return_value = 33'h01000_0000;
                    32'hE000_0000 : return_value = 33'h02000_0000;
                    32'hC000_0000 : return_value = 33'h04000_0000;
                    32'h8000_0000 : return_value = 33'h08000_0000;
                    default :      return_value = 33'h00000_0000;
                  endcase

                  FNC_CONVERT_RANGE_TO_SIZE_HI32 = return_value;
        end
    endfunction // FNC_CONVERT_RANGE_TO_SIZE_HI32




endmodule // pci_exp_usrapp_tx
