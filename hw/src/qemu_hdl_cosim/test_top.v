`timescale 1ns / 100ps

//`include "axi_vip_0_exdes_generic.sv"
`include "axi_vip_0_passthrough_mst_stimulus.sv"
//`include "axi_vip_0_slv_basic_stimulus.sv"

module test_top ();

reg  PCIE_CLK_N;
reg  PCIE_CLK_P;
wire [7:0] PCIE_RX_N;
wire [7:0] PCIE_RX_P;
wire [7:0] PCIE_TX_N;
wire [7:0] PCIE_TX_P;
reg  PERSTN;
reg  FPGA_SYSCLK_N;
reg  FPGA_SYSCLK_P;
reg  RESET;
wire  UART_RXD_OUT;
wire  UART_TXD_IN;
shell_region_wrapper DUT (
  .pci_express_rxn (PCIE_RX_N),
  .pci_express_rxp (PCIE_RX_P),
  .pci_express_txn (PCIE_TX_N),
  .pci_express_txp (PCIE_TX_P),
  .pcie_perstn (PERSTN),
  .pcie_refclk_clk_n (PCIE_CLK_N),
  .pcie_refclk_clk_p (PCIE_CLK_P)
);

// instantiate vip master
//  axi_vip_0_exdes_generic  generic_tb();
  axi_vip_0_passthrough_mst_stimulus mst();
//  axi_vip_0_slv_basic_stimulus slv();
    
always
begin
  PCIE_CLK_N = 1;
  #5.0;
  PCIE_CLK_N = 0;
  #5.0;
end
always
begin
  PCIE_CLK_P = 0;
  #5.0;
  PCIE_CLK_P = 1;
  #5.0;
end

always
begin
  FPGA_SYSCLK_N = 0;
  #2.5;
  FPGA_SYSCLK_N = 1;
  #2.5;
end
always
begin
  FPGA_SYSCLK_P = 1;
  #2.5;
  FPGA_SYSCLK_P = 0;
  #2.5;
end

initial
begin
  $display("[%t] : System Reset(test_top/RESET) Is Asserted...", $realtime);
  RESET = 1;
  #5000;
  $display("[%t] : System Reset(test_top/RESET) Is DeAsserted...", $realtime);
  RESET = 0;
end

initial
begin
  $display("[%t] : System Reset(test_top/PERSTN) Is Asserted...", $realtime);
  PERSTN = 0;
  #100;
  $display("[%t] : System Reset(test_top/PERSTN) Is DeAsserted...", $realtime);
  PERSTN = 1;
end

initial begin
  $display("V: testbench init.");
end

endmodule

