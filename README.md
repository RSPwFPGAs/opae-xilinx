<span style="display: inline-block;">

# Table of Contents
1. [Overview of opae-xilinx](#overviewopaex)
    - [Directory Structure](#overviewdirstr)
    - [Development Tools](#overviewdevtools)
2. [Getting Started](#gettingstarted)

<a name="overviewopaex"></a>
# Overview of opae-xilinx
The purpose of this project is to port [OPAE](https://opae.github.io/) to Xilinx FPGA devices. 

To be discoverable and managable by the OPAE PCIe driver, the design of FIU(FPGA Interface Unit, the PCIe interface logic) should be compliant with the OPAE specification. So a major design effort is on the FIM(FPGA Interface Manager) part, which is a static 'Shell' that resides persistantly on the FPGA. 

Based on the 'Shell', a design flow of the AFU(Accelerator Function Unit), which is a dynamic 'Role' that can be swapped in and out of the FPGA, is setup to utilize many open-source projects supporting HLS, such as [BISMO](https://github.com/EECS-NTNU/bismo), [VTA](https://github.com/apache/incubator-tvm/tree/master/vta), [HeteroCL](https://github.com/cornell-zhang/heterocl) and [Vitis Library](https://github.com/Xilinx/Vitis_Libraries) L1 modules.

Although the OPAE specification mandates the usage of [CCI-P](https://www.intel.com/content/www/us/en/programmable/documentation/buf1506187769663.html) interface between FIM and AFU when targeting Intel MCP and DCP platforms, this project uses AXI interface instead. The inclusion of an industry standard interface makes the OPAE ecosystem truly [Vendor Neutral](https://github.com/RSPwFPGAs/opae-xilinx/wiki/The-evolution-to-Vendor-Neutral-OPAE) and makes the IPs targeting ASIC designs available to FPGA designs, such as [MatchLib](https://github.com/NVlabs/matchlib).

<a name="overviewdirstr"></a>
## Overview of Directory Structure
```
.
├── doc
│   └── pics
├── hw
│   ├── prj
│   │   ├── afu
│   │   ├── blue_bs
│   │   ├── fim
│   │   └── green_bs
│   └── src
│       ├── afu_customize
│       ├── constraints
│       ├── hdl
│       ├── ip
│       ├── ipi
│       └── sim
└── sw
```

<a name="overviewdevtools"></a>
## Overview of Development Tools
The FPGA projects are designed with 2018.3 release of Vivado and Vivado HLS.
The FPGA target currently supported is the KCU105 development board from Xilinx.

<a name="gettingstarted"></a>
# Getting Started
To get started with the design of FIM and AFU, or the generation of Blue and Green bitstreams, follow the README in corresponding directories in [./hw/prj](./hw/prj/).
