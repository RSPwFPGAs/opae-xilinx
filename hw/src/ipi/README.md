This folder contains two kinds of Tcl source files: bd.tcl and flow.tcl. The bd.tcl ones are generated from Block Design files and can be used to regenerate the Block Designs, and the flow.tcl ones contain commands to modify or combine the Block Designs.

fim_debug.bd.tcl is the full-feature FIM(Shell) design and is used in /hw/prj/fim and /hw/prj/blue_bs projects.
fim_default.bd.tcl is the minimum FIM(Shell) design that contains only AXI-lite master interface for accessing CSRs in FIM and AFU. Keeping here for area utilization comparison.

afu_default.bd.tcl is a full-feature AFU(Role) design with AXI-lite slave and AXI-full master interfaces and is used in all /hw/prj/ projects as a place holder.
afu_customer.bd.tcl is a template AFU(Role) design with un-connected AXI-lite slave and AXI-full master interfaces and is used only in /hw/prj/afu project for customization.


