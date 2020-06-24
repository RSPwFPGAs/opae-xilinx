#ifndef _REG_H_
#define _REG_H_

#define DRV_NAME "xilinx_hwicap"

static const struct pci_device_id pci_ids[] = {
//    { PCI_DEVICE(0x10ee, 0x903F), },
    { PCI_DEVICE(0x8086, 0x09c4), },
    { 0, }
};

/**
 * ICAP Register definition
 */

#define  HWICAP_BASE  0x00012000

#define XHWICAP_GIER            HWICAP_BASE+0x1c
#define XHWICAP_ISR             HWICAP_BASE+0x20
#define XHWICAP_IER             HWICAP_BASE+0x28
#define XHWICAP_WF              HWICAP_BASE+0x100
#define XHWICAP_RF              HWICAP_BASE+0x104
#define XHWICAP_SZ              HWICAP_BASE+0x108
#define XHWICAP_CR              HWICAP_BASE+0x10c
#define XHWICAP_SR              HWICAP_BASE+0x110
#define XHWICAP_WFV             HWICAP_BASE+0x114
#define XHWICAP_RFO             HWICAP_BASE+0x118
#define XHWICAP_ASR             HWICAP_BASE+0x11c

//

#define   AXI_GATE_OFFSET1 		0x00014000
#define   AXI_GATE_OFFSET2 		0x00015000


// semaphores
enum  {
        SEM_READ,
        SEM_WRITE,
        SEM_WRITEREG,
        SEM_READREG,
        SEM_WAITFOR,
        SEM_DMA,
        NUM_SEMS
};
#endif
		
