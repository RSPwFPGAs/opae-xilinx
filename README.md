<span style="display: inline-block;">

# Table of Contents
1. [Overview of opae-xilinx](#overviewopaex)
    - [Original OPAE](#overviewopaeorig)
    - [Ported OPAE](#overviewopaeport)
        - [FIM and AFU design](#overviewopaeportfimandafu)
        - [Using AXI instead of CCI-P](#overviewopaeportaxivsccip)
    - [Directory Structure](#overviewdirstr)
    - [Development Tools](#overviewdevtools)
2. [Getting Started](#gettingstarted)

<a name="overviewopaex"></a>
# Overview of opae-xilinx
The purpose of this project is to port [OPAE](https://01.org/opae) to Xilinx FPGA devices. 

<a name="overviewopaeorig"></a>
## The original OPAE and FPGA accelerator:
![Alt text](./doc/pics/OPAE_1.jpg)

<a name="overviewopaeport"></a>
## The ported OPAE and FPGA accelerator:
![Alt text](./doc/pics/OPAE_3.jpg)

<a name="overviewopaeportfimandafu"></a>
### FIM and AFU design
To be discoverable and managable by the OPAE PCIe driver, the design of FIU(FPGA Interface Unit, the PCIe interface logic) should be compliant with the OPAE specification. So a major design effort is put into the FIM(FPGA Interface Manager) part, which is a static 'Shell' that resides persistantly on the FPGA. 

Based on the 'Shell', a design flow of the AFU(Accelerator Function Unit), which is a dynamic 'Role' that can be swapped in and out of the FPGA, is setup to utilize open-source projects supporting HLS, such as [BISMO](https://github.com/EECS-NTNU/bismo), [VTA](https://github.com/apache/incubator-tvm/tree/master/vta), [HeteroCL](https://github.com/cornell-zhang/heterocl) and [Vitis Library](https://github.com/Xilinx/Vitis_Libraries) L1 modules.

<a name="overviewopaeportaxivsccip"></a>
### Using AXI instead of CCI-P
Although the OPAE specification mandates the use of [CCI-P](https://01.org/sites/default/files/downloads/opae/cci-p-mpf-overview.pdf) interface between FIM and AFU when targeting Intel MCP and DCP platforms, this project uses AXI interface instead. The inclusion of an industry standard interface makes the OPAE ecosystem truly [Vendor Neutral](https://github.com/RSPwFPGAs/opae-xilinx/wiki/The-evolution-to-Vendor-Neutral-OPAE) and makes the many IPs targeting ASIC designs available to FPGA designer, such as [MatchLib](https://github.com/NVlabs/matchlib).

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

The FPGA platform currently supported is the [KCU105 development board](https://www.xilinx.com/products/boards-and-kits/kcu105.html) from Xilinx.

<a name="gettingstarted"></a>
# Getting Started
To get started with the design of FIM and AFU, or the generation of Blue and Green bitstreams, follow the README in ecah of the directories under [./hw/prj](./hw/prj/).
