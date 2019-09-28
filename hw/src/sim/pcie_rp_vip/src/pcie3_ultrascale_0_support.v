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
// File       : pcie3_ultrascale_0_support.v
// Version    : 4.4 
//-----------------------------------------------------------------------------
//--
//-- Description:  PCI Express Endpoint Shared Logic Wrapper
//--
//------------------------------------------------------------------------------

`timescale 1ps / 1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie3_ultrascale_0_support # (
  parameter PL_LINK_CAP_MAX_LINK_WIDTH = 8,  // 1- X1, 2 - X2, 4 - X4, 8 - X8
  parameter PCIE_REFCLK_FREQ           = 0,   // PCIe Reference Clock Frequency
  parameter C_DATA_WIDTH               = 256, // RX/TX interface data width
  parameter PL_UPSTREAM_FACING         = "TRUE",
  parameter DIS_GT_WIZARD              = "TRUE",
  parameter integer SHARED_LOGIC       = 0,
  parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
) (
  // Tx
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,

  // Rx
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,


  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1lock_out,
  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1outclk_out,
  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1outrefclk_out,

  output                                          user_clk,
  output                                          user_reset,
  output                                          user_lnk_up,
  output                                          phy_rdy_out,

  input   [C_DATA_WIDTH-1:0]                      s_axis_rq_tdata,
  input   [KEEP_WIDTH-1:0]                        s_axis_rq_tkeep,
  input                                           s_axis_rq_tlast,
  output    [3:0]                                 s_axis_rq_tready,
  input    [59:0]                                 s_axis_rq_tuser,
  input                                           s_axis_rq_tvalid,

  output  [C_DATA_WIDTH-1:0]                      m_axis_rc_tdata,
  output  [KEEP_WIDTH-1:0]                        m_axis_rc_tkeep,
  output                                          m_axis_rc_tlast,
  input                                           m_axis_rc_tready,
  output   [74:0]                                 m_axis_rc_tuser,
  output                                          m_axis_rc_tvalid,

  output  [C_DATA_WIDTH-1:0]                      m_axis_cq_tdata,
  output  [KEEP_WIDTH-1:0]                        m_axis_cq_tkeep,
  output                                          m_axis_cq_tlast,
  input                                           m_axis_cq_tready,
  output   [84:0]                                 m_axis_cq_tuser,
  output                                          m_axis_cq_tvalid,

  input   [C_DATA_WIDTH-1:0]                      s_axis_cc_tdata,
  input   [KEEP_WIDTH-1:0]                        s_axis_cc_tkeep,
  input                                           s_axis_cc_tlast,
  output    [3:0]                                 s_axis_cc_tready,
  input    [32:0]                                 s_axis_cc_tuser,
  input                                           s_axis_cc_tvalid,


  output    [1:0]                                 pcie_tfc_nph_av,
  output    [1:0]                                 pcie_tfc_npd_av,

  output    [3:0]                                 pcie_rq_seq_num,
  output                                          pcie_rq_seq_num_vld,
  output    [5:0]                                 pcie_rq_tag,
  output    [1:0]                                 pcie_rq_tag_av,
  output                                          pcie_rq_tag_vld,

  input                                           pcie_cq_np_req,
  output    [5:0]                                 pcie_cq_np_req_count,

  output                                          cfg_phy_link_down,
  output    [1:0]                                 cfg_phy_link_status,
  output    [3:0]                                 cfg_negotiated_width,
  output    [2:0]                                 cfg_current_speed,
  output    [2:0]                                 cfg_max_payload,
  output    [2:0]                                 cfg_max_read_req,
  output   [15:0]                                 cfg_function_status,
  output   [11:0]                                 cfg_function_power_state,
  output   [15:0]                                 cfg_vf_status,
  output   [23:0]                                 cfg_vf_power_state,
  output    [1:0]                                 cfg_link_power_state,

  // Error Reporting Interface
  output                                          cfg_err_cor_out,
  output                                          cfg_err_nonfatal_out,
  output                                          cfg_err_fatal_out,

  output                                          cfg_ltr_enable,
  output    [5:0]                                 cfg_ltssm_state,
  output    [3:0]                                 cfg_rcb_status,
  output    [3:0]                                 cfg_dpa_substate_change,
  output    [1:0]                                 cfg_obff_enable,
  output                                          cfg_pl_status_change,

  output    [3:0]                                 cfg_tph_requester_enable,
  output   [11:0]                                 cfg_tph_st_mode,
  output    [7:0]                                 cfg_vf_tph_requester_enable,
  output   [23:0]                                 cfg_vf_tph_st_mode,

  input    [18:0]                                 cfg_mgmt_addr,
  input                                           cfg_mgmt_write,
  input    [31:0]                                 cfg_mgmt_write_data,
  input     [3:0]                                 cfg_mgmt_byte_enable,
  input                                           cfg_mgmt_read,
  output   [31:0]                                 cfg_mgmt_read_data,
  output                                          cfg_mgmt_read_write_done,
  input                                           cfg_mgmt_type1_cfg_reg_access,

  output                                          cfg_msg_received,
  output    [7:0]                                 cfg_msg_received_data,
  output    [4:0]                                 cfg_msg_received_type,

  input                                           cfg_msg_transmit,
  input     [2:0]                                 cfg_msg_transmit_type,
  input    [31:0]                                 cfg_msg_transmit_data,
  output                                          cfg_msg_transmit_done,

  output    [7:0]                                 cfg_fc_ph,
  output   [11:0]                                 cfg_fc_pd,
  output    [7:0]                                 cfg_fc_nph,
  output   [11:0]                                 cfg_fc_npd,
  output    [7:0]                                 cfg_fc_cplh,
  output   [11:0]                                 cfg_fc_cpld,
  input     [2:0]                                 cfg_fc_sel,

  input     [2:0]                                 cfg_per_func_status_control,
  output   [15:0]                                 cfg_per_func_status_data,
  input     [3:0]                                 cfg_per_function_number,
  input                                           cfg_per_function_output_request,
  output                                          cfg_per_function_update_done,

  output                                          cfg_hot_reset_out,
  input                                           cfg_config_space_enable,
  input                                           cfg_req_pm_transition_l23_ready,
  input                                           cfg_hot_reset_in,
  input     [7:0]                                 cfg_ds_port_number,
  input     [7:0]                                 cfg_ds_bus_number,
  input     [4:0]                                 cfg_ds_device_number,
  input     [2:0]                                 cfg_ds_function_number,
  input    [63:0]                                 cfg_dsn,
  output                                          cfg_power_state_change_interrupt,
  input                                           cfg_power_state_change_ack,
  input                                           cfg_err_cor_in,
  input                                           cfg_err_uncor_in,
  output    [3:0]                                 cfg_flr_in_process,
  input     [3:0]                                 cfg_flr_done,
  output    [7:0]                                 cfg_vf_flr_in_process,
  input     [7:0]                                 cfg_vf_flr_done,
  output                                          cfg_local_error,
  input                                           cfg_link_training_enable,
  input     [3:0]                                 cfg_interrupt_int,
  input     [3:0]                                 cfg_interrupt_pending,
  output                                          cfg_interrupt_sent,

  output    [3:0]                                 cfg_interrupt_msi_enable,
  output    [7:0]                                 cfg_interrupt_msi_vf_enable,
  output   [11:0]                                 cfg_interrupt_msi_mmenable,
  output                                          cfg_interrupt_msi_mask_update,
  output   [31:0]                                 cfg_interrupt_msi_data,
  input     [3:0]                                 cfg_interrupt_msi_select,
  input    [31:0]                                 cfg_interrupt_msi_int,
  input    [31:0]                                 cfg_interrupt_msi_pending_status,
  input                                           cfg_interrupt_msi_pending_status_data_enable,
  input     [3:0]                                 cfg_interrupt_msi_pending_status_function_num,
  output                                          cfg_interrupt_msi_sent,
  output                                          cfg_interrupt_msi_fail,
  input     [2:0]                                 cfg_interrupt_msi_attr,
  input                                           cfg_interrupt_msi_tph_present,
  input     [1:0]                                 cfg_interrupt_msi_tph_type,
  input     [8:0]                                 cfg_interrupt_msi_tph_st_tag,
  input     [3:0]                                 cfg_interrupt_msi_function_number,



//  input    [15:0]                                  cfg_vend_id,
//  input    [15:0]                                  cfg_dev_id,
//  input     [7:0]                                  cfg_rev_id,
//  input    [15:0]                                  cfg_subsys_id,
  input    [15:0]                                  cfg_subsys_vend_id,

  //--------------------------------------------------------------------------------------//
  // Reset Pass Through Signals
  //  - Only used for PCIe_X0Y0
  //--------------------------------------------------------------------------------------//
  output                                           pcie_perstn0_out,
  input                                            pcie_perstn1_in,
  output                                           pcie_perstn1_out,




  input                                            sys_clk,
  input                                            sys_clk_gt,
  input                                            sys_reset
);

  // Local Parameters derived from user selection
  localparam        TCQ = 1;


    wire         cfg_ext_read_received;
    wire         cfg_ext_write_received;
    wire   [9:0] cfg_ext_register_number;
    wire   [7:0] cfg_ext_function_number;
    wire  [31:0] cfg_ext_write_data;
    wire   [3:0] cfg_ext_write_byte_enable;
    wire  [31:0] cfg_ext_read_data;
    wire         cfg_ext_read_data_valid;

  
// Core Top Level Wrapper
 pcie3_ultrascale_0  pcie3_ultrascale_0_i (

    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//

    // Tx
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),

    //---------------------------------------------------------------------------------------//
    //  AXI Interface                                                                        //
    //---------------------------------------------------------------------------------------//


    .user_clk                                       ( user_clk ),
    .user_reset                                     ( user_reset ),
    .user_lnk_up                                    ( user_lnk_up ),
    .phy_rdy_out                                    ( phy_rdy_out ),
  
    .s_axis_rq_tlast                                ( s_axis_rq_tlast ),
    .s_axis_rq_tdata                                ( s_axis_rq_tdata ),
    .s_axis_rq_tuser                                ( s_axis_rq_tuser ),
    .s_axis_rq_tkeep                                ( s_axis_rq_tkeep ),
    .s_axis_rq_tready                               ( s_axis_rq_tready ),
    .s_axis_rq_tvalid                               ( s_axis_rq_tvalid ),

    .m_axis_rc_tdata                                ( m_axis_rc_tdata ),
    .m_axis_rc_tuser                                ( m_axis_rc_tuser ),
    .m_axis_rc_tlast                                ( m_axis_rc_tlast ),
    .m_axis_rc_tkeep                                ( m_axis_rc_tkeep ),
    .m_axis_rc_tvalid                               ( m_axis_rc_tvalid ),
    .m_axis_rc_tready                               ( m_axis_rc_tready ),

    .m_axis_cq_tdata                                ( m_axis_cq_tdata ),
    .m_axis_cq_tuser                                ( m_axis_cq_tuser ),
    .m_axis_cq_tlast                                ( m_axis_cq_tlast ),
    .m_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
    .m_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
    .m_axis_cq_tready                               ( m_axis_cq_tready ),

    .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                               ( s_axis_cc_tready ),
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av ),
    .pcie_rq_seq_num                                ( pcie_rq_seq_num ),
    .pcie_rq_seq_num_vld                            ( pcie_rq_seq_num_vld ),
    .pcie_rq_tag                                    ( pcie_rq_tag ),
    .pcie_rq_tag_vld                                ( pcie_rq_tag_vld ),
    .pcie_rq_tag_av                                 ( pcie_rq_tag_av ),

    .pcie_cq_np_req                                 ( pcie_cq_np_req ),
    .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),

    //---------------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                        //
    //---------------------------------------------------------------------------------------//

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( cfg_phy_link_status ),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( cfg_function_power_state ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_vf_power_state                             ( cfg_vf_power_state ),
    .cfg_link_power_state                           ( cfg_link_power_state ),

    // Error Reporting Interface
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),

    .cfg_ltr_enable                                 ( cfg_ltr_enable ),
    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rcb_status                                 ( cfg_rcb_status ),
    .cfg_dpa_substate_change                        ( cfg_dpa_substate_change ),
    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),

    .cfg_tph_requester_enable                       ( cfg_tph_requester_enable ),
    .cfg_tph_st_mode                                ( cfg_tph_st_mode ),
    .cfg_vf_tph_requester_enable                    ( cfg_vf_tph_requester_enable ),
    .cfg_vf_tph_st_mode                             ( cfg_vf_tph_st_mode ),

    // Management Interface
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( cfg_mgmt_read_data ),
    .cfg_mgmt_read_write_done                       ( cfg_mgmt_read_write_done ),
    .cfg_mgmt_type1_cfg_reg_access                  ( cfg_mgmt_type1_cfg_reg_access ),

    .cfg_msg_received                               ( cfg_msg_received ),
    .cfg_msg_received_data                          ( cfg_msg_received_data ),
    .cfg_msg_received_type                          ( cfg_msg_received_type ),

    .cfg_msg_transmit                               ( cfg_msg_transmit ),
    .cfg_msg_transmit_type                          ( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( cfg_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( cfg_msg_transmit_done ),

    .cfg_fc_ph                                      ( cfg_fc_ph ),
    .cfg_fc_pd                                      ( cfg_fc_pd ),
    .cfg_fc_nph                                     ( cfg_fc_nph ),
    .cfg_fc_npd                                     ( cfg_fc_npd ),
    .cfg_fc_cplh                                    ( cfg_fc_cplh ),
    .cfg_fc_cpld                                    ( cfg_fc_cpld ),
    .cfg_fc_sel                                     ( cfg_fc_sel ),

    .cfg_per_func_status_control                    ( cfg_per_func_status_control ),
    .cfg_per_func_status_data                       ( cfg_per_func_status_data ),
    .cfg_per_function_number                        ( cfg_per_function_number ),
    .cfg_per_function_output_request                ( cfg_per_function_output_request ),
    .cfg_per_function_update_done                   ( cfg_per_function_update_done ),

  // EP only
    .cfg_hot_reset_out                              ( cfg_hot_reset_out ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),

  // RP only
    .cfg_hot_reset_in                               ( cfg_hot_reset_in ),

    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_function_number                         ( cfg_ds_function_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),
    .cfg_flr_in_process                             ( cfg_flr_in_process ),
    .cfg_flr_done                                   ( cfg_flr_done ),
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done ),
    .cfg_local_error                                ( cfg_local_error ),
    .cfg_link_training_enable                       ( cfg_link_training_enable ),

    .cfg_ext_read_received                          ( cfg_ext_read_received ),
    .cfg_ext_write_received                         ( cfg_ext_write_received ),
    .cfg_ext_register_number                        ( cfg_ext_register_number ),
    .cfg_ext_function_number                        ( cfg_ext_function_number ),
    .cfg_ext_write_data                             ( cfg_ext_write_data ),
    .cfg_ext_write_byte_enable                      ( cfg_ext_write_byte_enable ),
    .cfg_ext_read_data                              ( cfg_ext_read_data ),
    .cfg_ext_read_data_valid                        ( cfg_ext_read_data_valid ),
    //-------------------------------------------------------------------------------//
    // EP Only                                                                       //
    //-------------------------------------------------------------------------------//

    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( cfg_interrupt_int ),
    .cfg_interrupt_pending                          ( cfg_interrupt_pending ),
    .cfg_interrupt_sent                             ( cfg_interrupt_sent ),

    .cfg_interrupt_msi_enable                       ( cfg_interrupt_msi_enable ),
    .cfg_interrupt_msi_vf_enable                    ( cfg_interrupt_msi_vf_enable ),
    .cfg_interrupt_msi_mmenable                     ( cfg_interrupt_msi_mmenable ),
    .cfg_interrupt_msi_mask_update                  ( cfg_interrupt_msi_mask_update ),
    .cfg_interrupt_msi_data                         ( cfg_interrupt_msi_data ),
    .cfg_interrupt_msi_select                       ( cfg_interrupt_msi_select ),
    .cfg_interrupt_msi_int                          ( cfg_interrupt_msi_int ),
    .cfg_interrupt_msi_pending_status               ( cfg_interrupt_msi_pending_status ),
    .cfg_interrupt_msi_pending_status_function_num  ( cfg_interrupt_msi_pending_status_function_num ),
    .cfg_interrupt_msi_pending_status_data_enable   ( cfg_interrupt_msi_pending_status_data_enable ),
    .cfg_interrupt_msi_sent                         ( cfg_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail                         ( cfg_interrupt_msi_fail ),
    .cfg_interrupt_msi_attr                         ( cfg_interrupt_msi_attr ),
    .cfg_interrupt_msi_tph_present                  ( cfg_interrupt_msi_tph_present ),
    .cfg_interrupt_msi_tph_type                     ( cfg_interrupt_msi_tph_type ),
    .cfg_interrupt_msi_tph_st_tag                   ( cfg_interrupt_msi_tph_st_tag ),
    .cfg_interrupt_msi_function_number              ( cfg_interrupt_msi_function_number ),

  
//    .cfg_vend_id                                    ( cfg_vend_id ),
//    .cfg_dev_id                                     ( cfg_dev_id ),
//    .cfg_rev_id                                     ( cfg_rev_id ),
//    .cfg_subsys_id                                  ( cfg_subsys_id ),
    .cfg_subsys_vend_id                             ( cfg_subsys_vend_id ),

    //--------------------------------------------------------------------------------------//
    // Reset Pass Through Signals
    //  - Only used for PCIe_X0Y0
    //--------------------------------------------------------------------------------------//
    .pcie_perstn0_out                               ( pcie_perstn0_out ),
    .pcie_perstn1_in                                ( pcie_perstn1_in ),
    .pcie_perstn1_out                               ( pcie_perstn1_out ),


   //---------- Shared Logic Internal -------------------------
    .int_qpll1lock_out                              (int_qpll1lock_out),   
    .int_qpll1outrefclk_out                         (int_qpll1outrefclk_out),
    .int_qpll1outclk_out                            (int_qpll1outclk_out),





    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//
    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_reset )

  );


 //--------------------------------------------------------------------------------------//
 // Add Demonstration VSEC to the PCIe Example design.
 // This is provided as a demonstration VSEC and should be replaced by the desired
 // user extended capabiilties.
 //--------------------------------------------------------------------------------------//
 wire [31:0] pcie_vsec_loopback;
 vsec_null #(
    .EXT_CONFIG_BASE_ADDRESS(12'h480),
    .EXT_CONFIG_CAP_LENGTH(12'h010),
    .EXT_CONFIG_NEXT_CAP(12'h000),
    .PCIE_VSEC_ID(16'h0000),
    .PCIE_VSEC_REV(4'h0)
 ) vsec_null_i (
    // Control signals
    .clk(user_clk),
    // PCIe Extended Capability Interface signals
    .read_received(cfg_ext_read_received),
    .write_received(cfg_ext_write_received),
    .register_number(cfg_ext_register_number),
    .function_number(cfg_ext_function_number),
    .write_data(cfg_ext_write_data),
    .write_byte_enable(cfg_ext_write_byte_enable),
    .read_data(cfg_ext_read_data),
    .read_data_valid(cfg_ext_read_data_valid),
    // IO to and from the user design.
    .status_reg_in(pcie_vsec_loopback),
    .control_reg_out(pcie_vsec_loopback)
 );



endmodule


