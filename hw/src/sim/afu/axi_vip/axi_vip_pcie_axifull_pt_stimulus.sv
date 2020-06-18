/***************************************************************************************************
* Description:
* Considering different user cases, Passthrough VIP can be switched into either run time master
* mode or run time slave mode. When it is in run time slave mode, depends on situations, user may
* want to build their own memory model or using existing memory model.Passthrough VIP has two
* agents: passthrough_agent and passthrough_mem_agent to suit user needs.Passthrough_agent doesn't
* have memory model and user can build their own memory model and fill in write transaction and/or
* read transaction responses in their own way.Passthrough_mem_agent has memory model which user can
* use it directly.
* This file shows how Passthrough VIP switch into run time slave mode with memory model and
* basic features. 
* In order to make Passthrough VIP in run time slave mode with memory model work, user environment
* MUST have the lists of item below and follow this order.
*    1. import two packages.(this information also shows at the xgui of the VIP)
*         import axi_vip_pkg::* 
*         import <component_name>_pkg::*;
*    2. delcare <component_name>_passthrough_mem_t agent
*    3. new agent (passing instance IF correctly)
*    4. switch passthrough VIP into run time slave mode
*    5. start_slave
***************************************************************************************************/

import axi_vip_pkg::*;
import role_region_0_sim_axi_vip_pcie_axifull_pt_0_pkg::*;

module axi_vip_pcie_axifull_pt_stimulus(
  );
 
  /*************************************************************************************************
  * Declare <component_name>_passhthrough_mem_t for passthrough with memory model agent
  * <component_name> can be easily found in vivado bd design: click on the instance, 
  * Then click CONFIG under Properties window and Component_Name will be shown
  * More details please refer PG267 for more details
  *************************************************************************************************/
  role_region_0_sim_axi_vip_pcie_axifull_pt_0_passthrough_mem_t          agent;

  initial begin
    /***********************************************************************************************
    * Before agent is newed, user has to run simulation with an empty testbench to find the
    * hierarchy path of the AXI VIP's instance.Message like
    * "Xilinx AXI VIP Found at Path: my_ip_exdes_tb.DUT.ex_design.axi_vip_mst.inst" will be printed 
    * out. Pass this path to the new function. 
    ***********************************************************************************************/
    agent = new("passthrough vip mem agent",tb.DUT.axi_vip_pcie_axifull_pt.inst.IF);

    /***********************************************************************************************
    *  User has call API from Passthrough VIP's top to switch passthrough VIP into run time slave 
    *  mode. The hierarchy path is the same as shown in new 
    ***********************************************************************************************/
    tb.DUT.axi_vip_pcie_axifull_pt.inst.set_slave_mode(); 

    /***********************************************************************************************
    *  User has call API from Passthrough VIP's agent to start slave
    ***********************************************************************************************/
    agent.start_slave();

  end

 
endmodule

