<span style="display: inline-block;">

# Table of Contents
1. [Overview of opae-xilinx](#overviewopaex)
    - [Original OPAE](#overviewopaeorig)
    - [Ported OPAE](#overviewopaeport)
        - [FIM and AFU design](#overviewopaeportfimandafu)
        - [Using AXI instead of CCI-P](#overviewopaeportaxivsccip)
    - [Demo: Full-System Simulation with QEMU](#overviewqemusim)
    - [Sample Applications: Xilinx CDMA](#samplexilinxcdma)
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
To be discoverable and managable by the OPAE PCIe driver, the design of FIU(FPGA Interface Unit, the PCIe interface logic) should be compliant with the OPAE specification. So a major design effort is put into the FIM(FPGA Interface Manager) part, which is a static 'Shell' that resides persistantly in the FPGA. 

Based on the 'Shell', a design flow of the AFU(Accelerator Function Unit) part, which is a dynamic 'Role' that can be swapped in and out of the FPGA, is setup to utilize open-source projects supporting HLS, such as [FINN-HLS](https://github.com/xilinx/finn-hlslib), [GEMM_HLS](https://github.com/spcl/gemm_hls), [hlslib](https://github.com/definelicht/hlslib), [BISMO](https://github.com/EECS-NTNU/bismo), [VTA](https://github.com/apache/incubator-tvm/tree/master/vta), [HeteroCL](https://github.com/cornell-zhang/heterocl) and [Vitis Library](https://github.com/Xilinx/Vitis_Libraries) L1 modules.

<a name="overviewopaeportaxivsccip"></a>
### Using AXI instead of CCI-P
Although the OPAE specification mandates the use of [CCI-P](https://01.org/sites/default/files/downloads/opae/cci-p-mpf-overview.pdf) interface between FIM and AFU when targeting Intel MCP and DCP platforms, this project uses AXI interface instead. The inclusion of an industry standard interface makes the OPAE ecosystem truly [Vendor Neutral](https://github.com/RSPwFPGAs/opae-xilinx/wiki/The-evolution-to-Vendor-Neutral-OPAE) and makes the many IPs targeting ASIC designs available to FPGA designers, such as [MatchLib](https://github.com/NVlabs/matchlib) and [HLSLibs](https://github.com/hlslibs).

<a name="overviewqemusim"></a>
## Demo: Full-System Simulation with QEMU
A full-system simulation, which involves application/driver software code and FIM/AFU hardware logic, not only speeds up the development and debugging process of the SW/HW interface, but also enables the evaluation of this full-stack solution without a physical FPGA acceleration card. Please take a look at the [README](./sw/QEMU/qemu_hdl_cosim/) for details.

### OPAE-scan results in QEMU-HDL co-simulation:
![Alt text](./doc/pics/opae_scan_cmd_list.png)

### OPAE-scan AXI-bus transaction waveform in QEMU-HDL co-simulation:
![Alt text](./doc/pics/opae_scan_sim_wave.png)

<a name="samplexilinxcdma"></a>
## OPAE Sample Applications: Hello_FPGA with Xilinx CDMA
[Application of Xilinx CDMA IP in C.](./sw/OPAE/sdk/opae-sdk-1.3.0-2/samples)

[Application of Xilinx CDMA IP in Python.](./sw/OPAE/sdk/opae-sdk-1.3.0-2/pyopae/samples)

The above sample applications have been validated in the QEMU-HDL co-simulation environment.

### Docker script to setup an OPAE run-time environment
[Build OPAE on Ubuntu 16.04 from source code](./sw/Docker/shared/install_opae_src.sh).

[The original script is here](https://github.com/akirajoeshoji/docker-intel-pac-rte). Thank you so much akirajoeshoji, for the inspiration!

<a name="overviewdirstr"></a>
## Directory Structure
```
.
├── doc
│   ├── dmesg
│   └── pics
├── hw
│   ├── prj
│   │   ├── afu
│   │   ├── blue_bs
│   │   ├── fim
│   │   ├── green_bs
│   │   └── qemu_hdl_cosim
│   └── src
│       ├── afu_customize
│       ├── constraints
│       ├── hdl
│       ├── ip
│       ├── ipi
│       ├── qemu_hdl_cosim
│       └── sim
└── sw
    ├── Docker
    ├── OPAE
    │   ├── driver
    │   └── sdk
    │       └── opae-sdk-1.3.0-2
    │           ├── pyopae
    │           │   └── samples
    │           └── samples
    └── QEMU
        └── qemu_hdl_cosim
```

<a name="overviewdevtools"></a>
## Development Tools
The FPGA projects are designed with 2018.3 release of Vivado and Vivado HLS.

The FPGA platform currently supported is the [KCU105 development board](https://www.xilinx.com/products/boards-and-kits/kcu105.html) from Xilinx.

<a name="gettingstarted"></a>
# Getting Started
To get started with the design of FIM and AFU, or the generation of Blue and Green bitstreams, follow the README in ecah of the directories under [./hw/prj](./hw/prj/).

# ToDo List
01. [Done] Add Container scripts to install OPAE driver/sdk/pyopae - Clean environment.
02. Use Verilator/GtkWave in the QEMU-HDL cosimulation - Truely open source tools based; Mixed C/Verilog simulation.
03. Port Xilinx PR driver to OPAE - FME functionality enhancement.
04. Add Ethernet interface to the FIM - FIM functionality enhancement/AFU BBB optional component logic.
05. Add DDR interface to the FIM - FIM functionality enhancement/AFU BBB optional component logic.
06. Add AFU BBB logic components and compilation flow scripts - A synthesis flow for automatic HLS IP integration.
07. Optimize FIM pyhsical constraints - Available area estimation for AFU.

# Wish List
01. Support SR-IOV.
02. Support dual PF.
03. Add AFU BBB logic components for supporting OpenCL/SyCL/oneAPI - ?.
04. PYNQ/XRT compliant - ?.
05. VirtIO NIC compatible with [ixy](https://github.com/emmericp/ixy) user space driver - Network attached accelerator (SmartNIC).
06. Add a [RISC-V Core](https://github.com/SpinalHDL/VexRiscv) as an AXI-Lite master in the FIM - Autonomous task scheduling and hardware microservice.
