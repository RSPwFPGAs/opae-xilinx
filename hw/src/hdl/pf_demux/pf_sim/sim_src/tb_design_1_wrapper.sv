
`timescale 1ps/1ps

module tb_design_1_wrapper (); /* this is automatically generated */


	// (*NOTE*) replace reset, clock, others
    import axi_vip_pkg::*;
    import design_1_axi_vip_0_0_pkg::*;

	logic        aclk_0;
	logic        aresetn_0;
	logic [29:0] S_AXI_LITE_awuser_0;
	logic [29:0] S_AXI_LITE_aruser_0;

    // ID value for WRITE/READ_BURST transaction
    xil_axi_uint                            mtestID;
    // ADDR value for WRITE/READ_BURST transaction
    xil_axi_ulong                           mtestADDR;
    // Burst Length value for WRITE/READ_BURST transaction
    xil_axi_len_t                           mtestBurstLength;
    // SIZE value for WRITE/READ_BURST transaction
    xil_axi_size_t                          mtestDataSize; 
    // Burst Type value for WRITE/READ_BURST transaction
    xil_axi_burst_t                         mtestBurstType; 
    // LOCK value for WRITE/READ_BURST transaction
    xil_axi_lock_t                          mtestLOCK;
    // Cache Type value for WRITE/READ_BURST transaction
    xil_axi_cache_t                         mtestCacheType = 0;
    // Protection Type value for WRITE/READ_BURST transaction
    xil_axi_prot_t                          mtestProtectionType = 3'b000;
    // Region value for WRITE/READ_BURST transaction
    xil_axi_region_t                        mtestRegion = 4'b000;
    // QOS value for WRITE/READ_BURST transaction
    xil_axi_qos_t                           mtestQOS = 4'b000;
    // Data beat value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       dbeat;
    // User beat value for WRITE/READ_BURST transaction
    xil_axi_user_beat                       usrbeat;
    // Wuser value for WRITE/READ_BURST transaction
    xil_axi_data_beat [255:0]               mtestWUSER; 
    // Awuser value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       mtestAWUSER = 'h0;
    // Aruser value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       mtestARUSER = 0;
    // Ruser value for WRITE/READ_BURST transaction
    xil_axi_data_beat [255:0]               mtestRUSER;    
    // Buser value for WRITE/READ_BURST transaction
    xil_axi_uint                            mtestBUSER = 0;
    // Bresp value for WRITE/READ_BURST transaction
    xil_axi_resp_t                          mtestBresp;
    // Rresp value for WRITE/READ_BURST transaction
    xil_axi_resp_t[255:0]                   mtestRresp;

  //----------------------------------------------------------------------------------------------
  // no burst for AXI4LITE and maximum data bits is 64
  // Write Data Value for WRITE_BURST transaction
  // Read Data Value for READ_BURST transaction
  //----------------------------------------------------------------------------------------------
  bit [63:0]                              mtestWData;
  bit [63:0]                              mtestRData;

  //----------------------------------------------------------------------------------------------
  // associated array for read data 
  // read data channel uses data_mem[addr] if it exist, otherwise, it generates randomized data
  // fill in data_mem and send it to read data transaction
  //----------------------------------------------------------------------------------------------
  xil_axi_payload_byte                    data_mem[xil_axi_ulong];

    //----------------------------------------------------------------------------------------------
    // verbosity level which specifies how much debug information to produce
    // 0       - No information will be printed out.
    // 400      - All information will be printed out.
    // master VIP agent verbosity level
    //----------------------------------------------------------------------------------------------
    xil_axi_uint                           mst_agent_verbosity = 0;
    // slave VIP agent verbosity level
   // xil_axi_uint                           slv_agent_verbosity = 0;
  //----------------------------------------------------------------------------------------------
    // Parameterized agents which customer needs to declare according to AXI VIP configuration
    // If AXI VIP is being configured in master mode, axi_mst_agent has to declared 
    // If AXI VIP is being configured in slave mode, axi_slv_agent has to be declared 
    // If AXI VIP is being configured in pass-through mode, axi_passthrough_agent has to be declared
    // "component_name"_mst_t for master agent
    // "component_name"_slv_t for slave agent
    // "component_name"_passthrough_t for passthrough agent
    // "component_name can be easily found in vivado bd design: click on the instance, 
    // then click CONFIG under Properties window and Component_Name will be shown
    // more details please refer PG267 for more details
    //----------------------------------------------------------------------------------------------
    design_1_axi_vip_0_0_mst_t                  mst_agent;
   //design_1_axi_vip_1_0_slv_t                  slv_agent;
   //design_1_axi_vip_1_1_slv_t                  slv_agent1;
   //design_1_axi_vip_1_2_slv_t                  slv_agent2;    
  //----------------------------------------------------------------------------------------------
    // the following monitor transactions are for simple scoreboards doing self-checking
    // two Scoreboards are built here
    // one scoreboard checks master vip against passthrough VIP (scoreboard 1)
    // the other one checks passthrough VIP against slave VIP (scoreboard 2)
    // monitor transaction from master VIP
    //----------------------------------------------------------------------------------------------    
    axi_monitor_transaction                     mst_monitor_transaction;
   // monitor transaction for slave VIP
   // axi_monitor_transaction                     slv_monitor_transaction;   
    
    //
    
	design_1_wrapper inst
       (.aclk_0(aclk_0),
         .aresetn_0(aresetn_0),
         .S_AXI_LITE_awuser_0(S_AXI_LITE_awuser_0),
         .S_AXI_LITE_aruser_0(S_AXI_LITE_aruser_0)
         );    


    initial begin
        mst_monitor_transaction = new("master monitor transaction");
        mst_agent               = new("master vip agent",inst.design_1_i.axi_vip_0.inst.IF);
        mst_agent.set_agent_tag("Master VIP");
        mst_agent.set_verbosity(mst_agent_verbosity);
        mst_agent.start_master();

       //--------------------------write--
       //user = 0 
        S_AXI_LITE_awuser_0 = 'h0;
        
        mtestID = 0;
        mtestADDR = 'h0000_0001;
        mtestBurstLength = 0;
        mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
        mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
        mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
        mtestProtectionType = 0; 
        mtestRegion = 0;
        mtestQOS = 0;
        mtestWData = 'h5a5a5a5a;

        mst_agent.AXI4LITE_WRITE_BURST(
          mtestADDR,
          mtestProtectionType,
          mtestWData,
          mtestBresp
        );
        
         //
         //user = 1 
         S_AXI_LITE_awuser_0 = 'h1;
                  
         mtestID = 0;
         mtestADDR = 'h0000_0010;
         mtestBurstLength = 0;
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
         mtestProtectionType = 0; 
         mtestRegion = 0;
         mtestQOS = 0;
         mtestWData = 'ha5a5a5a5;
  
         mst_agent.AXI4LITE_WRITE_BURST(
           mtestADDR,
           mtestProtectionType,
           mtestWData,
           mtestBresp
         );

        //
        //user = 2 
         S_AXI_LITE_awuser_0 = 'h2;
         
         mtestID = 0;
         mtestADDR = 'h0000_0100;
         mtestBurstLength = 0;
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
         mtestProtectionType = 0; 
         mtestRegion = 0;
         mtestQOS = 0;
         mtestWData = 'h5555aaaa;
  
         mst_agent.AXI4LITE_WRITE_BURST(
           mtestADDR,
           mtestProtectionType,
           mtestWData,
           mtestBresp
         );


         //----------------------read--
         //user =0 
         S_AXI_LITE_aruser_0 = 'h0;
         
         mtestID = 0;
         mtestADDR = 'h0000_0001;
         mtestBurstLength = 0;
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
         mtestProtectionType = 0; 
         mtestRegion = 0;
         mtestQOS = 0;
         mtestWData = 'h0;
         
         mst_agent.AXI4LITE_READ_BURST(
             mtestADDR,
             mtestProtectionType,
             mtestRData,
             mtestRresp
           ); 

         //user =1
         S_AXI_LITE_aruser_0 = 'h1;
         
         mtestID = 0;
         mtestADDR = 'h0000_0010;
         mtestBurstLength = 0;
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
         mtestProtectionType = 0; 
         mtestRegion = 0;
         mtestQOS = 0;
         mtestWData = 'h0;
         
         mst_agent.AXI4LITE_READ_BURST(
             mtestADDR,
             mtestProtectionType,
             mtestRData,
             mtestRresp
           ); 

         //user =2
         S_AXI_LITE_aruser_0 = 'h2;
         
         mtestID = 0;
         mtestADDR = 'h0000_0100;
         mtestBurstLength = 0;
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK; 
         mtestProtectionType = 0; 
         mtestRegion = 0;
         mtestQOS = 0;
         mtestWData = 'h0;
         
         mst_agent.AXI4LITE_READ_BURST(
             mtestADDR,
             mtestProtectionType,
             mtestRData,
             mtestRresp
           ); 
 
 
        #300000;//wait 1us
 
        $finish; 

    end // initial  
    
      

	initial begin
	    aresetn_0 <= 1'b1;
	end		
	

    initial
    begin
        aclk_0 =0;
        forever #5000   aclk_0 = ~ aclk_0;
    end
 


endmodule
