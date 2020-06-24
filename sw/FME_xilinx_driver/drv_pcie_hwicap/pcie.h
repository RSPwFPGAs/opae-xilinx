#ifndef _PCIE_H_
#define _PCIE_H_

#include <linux/cdev.h>
#include <linux/list.h>
#include <linux/signal.h>
#include <linux/init_task.h>
#include <linux/mutex.h>
#include <linux/pci.h>
#include <linux/delay.h>
#include <linux/time.h>
#include <linux/types.h>
#include <asm/io.h>

//semaphores
struct semaphore gSem[NUM_SEMS];

#define FME_MGMT_NUM_FIREWALL_IPS 3
//#define AXI_FIREWALL
#define XCLMGMT_MINOR_BASE (0)
#define XCLMGMT_MINOR_COUNT (16)
///* Used for parsing bitstream header */
#define XHI_BIT_HEADER_FAILURE -1
#define XHI_EVEN_MAGIC_BYTE     0x0f
#define XHI_ODD_MAGIC_BYTE      0xf0

#define MGMT_MODULE_VERSION				      \
	__stringify(XCLMGMT_DRIVER_MAJOR) "."		      \
	__stringify(XCLMGMT_DRIVER_MINOR) "."		      \
	__stringify(XCLMGMT_DRIVER_PATCHLEVEL)
// Max DMA Buffer Size

#define BUF_SIZE                  4096
#define DMA_HWICAP_BITFILE_BUFFER_SIZE 1024

//#define PCI_VENDOR_ID_XILINX      0x10ee
//#define PCI_DEVICE_ID_XILINX_PCIE 0x903f
#define PCI_VENDOR_ID_XILINX      0x8086
#define PCI_DEVICE_ID_XILINX_PCIE 0x09c4
#define KINBURN_REGISTER_SIZE     (4*8)    // There are eight registers, and each is 4 bytes wide.
#define HAVE_REGION               0x01     // I/O Memory region
#define HAVE_IRQ                  0x02     // Interupt
#define SUCCESS                   0
#define CRIT_ERR                  -1

//Status Flags: 
//       1 = Resouce successfully acquired
//       0 = Resource not acquired.      
#define HAVE_REGION 0x01               // I/O Memory region
#define HAVE_IRQ    0x02               // Interupt
#define HAVE_KREG   0x04               // Kernel registration
//
/**
 * Bitstream header information.
 */
typedef struct {
	unsigned int HeaderLength;     /* Length of header in 32 bit words */
	unsigned int BitstreamLength;  /* Length of bitstream to read in bytes*/
	unsigned char *DesignName;     /* Design name read from bitstream header */
	unsigned char *PartName;       /* Part name read from bitstream header */
	unsigned char *Date;           /* Date read from bitstream header */
	unsigned char *Time;           /* Bitstream creation time read from header */
	unsigned int MagicLength;      /* Length of the magic numbers in header */
} XHwIcap_Bit_Header;
//
struct xclBin {
	char m_magic[8];                    /* should be xclbin0\0  */
	uint64_t m_length;                  /* total size of the xclbin file */
	uint64_t m_timeStamp;               /* number of seconds since epoch when xclbin was created */
	uint64_t m_version;                 /* tool version used to create xclbin */
	unsigned m_mode;                    /* XCLBIN_MODE */
	char m_nextXclBin[24];              /* Name of next xclbin file in the daisy chain */
	uint64_t m_metadataOffset;          /* file offset of embedded metadata */
	uint64_t m_metadataLength;          /* size of the embedded metdata */
	uint64_t m_primaryFirmwareOffset;   /* file offset of bitstream or emulation archive */
	uint64_t m_primaryFirmwareLength;   /* size of the bistream or emulation archive */
	uint64_t m_secondaryFirmwareOffset; /* file offset of clear bitstream if any */
	uint64_t m_secondaryFirmwareLength; /* size of the clear bitstream */
	uint64_t m_driverOffset;            /* file offset of embedded device driver if any (currently unused) */
	uint64_t m_driverLength;            /* size of the embedded device driver (currently unused) */

	// Extra debug information for hardware and hardware emulation debug

	uint64_t m_dwarfOffset ;
	uint64_t m_dwarfLength ;
	uint64_t m_ipiMappingOffset ;
	uint64_t m_ipiMappingLength ;
};

 //
enum XCLMGMT_IOC_TYPES {
	FME_MGMT_IOC_INFO,
	FME_MGMT_IOC_ICAP_DOWNLOAD,
	FME_MGMT_IOC_FREQ_SCALE,
	FME_MGMT_IOC_OCL_RESET,
	FME_MGMT_IOC_HOT_RESET,
	FME_MGMT_IOC_REBOOT,
	FME_MGMT_IOC_ICAP_DOWNLOAD_AXLF,
	FME_MGMT_IOC_ERR_INFO,
	FME_MGMT_IOC_ICAP_STATUS,
	FME_MGMT_IOC_MAX
};
enum HWICAP_STATUS{
	ICAP_DOWNLOADING = 0,
	ICAP_DOWNLOAD_FINISH,
	ICAP_DOWNLOAD_ERROR
};
struct fme_ioc_bitstream {
	int	  len;
	char  *buff;
};
struct hwicap_status{
	int hw_status;
};
struct fme_ioc_icap_status{
	int  status;
};
//ioctl
#define XCLMGMT_IOC_MAGIC	'X'
#define FME_IOC_ICAP_DOWNLOAD	  _IOW (XCLMGMT_IOC_MAGIC,FME_MGMT_IOC_ICAP_DOWNLOAD,	 struct fme_ioc_bitstream)
#define FME_IOC_ICAP_STATUS	  _IOR (XCLMGMT_IOC_MAGIC,FME_MGMT_IOC_ICAP_STATUS,	 struct fme_ioc_icap_status )

//global 
static int instance = 0;
static struct class *xclmgmt_class;
static struct mgmt_dev *xclmgmt_dev_table[XCLMGMT_MINOR_COUNT];
static dev_t xclmgmt_devnode;

//
enum GLOBAL_BARS {
	PF_MAIN_BAR = 0,
		PF_AX = 1,
	PF_HWICAP_BAR = 0,
	PF_MAX_BAR
};

struct xclmgmt_bitstream_container {
	/* MAGIC_BITSTREAM == 0xBBBBBBBBUL */
	unsigned long magic;
	char *clear_bitstream;
	u32 clear_bitstream_length;
};

struct mgmt_char_dev {
	struct mgmt_dev *lro;
	struct cdev cdev;
	struct device *sys_device;
	int bar;
};

// also saving the task
struct proc_list {

	struct list_head head;
	struct pid 	 *pid;

};

/**/
struct mgmt_dev {
	/* MAGIC_DEVICE == 0xAAAAAAAA */
	unsigned long magic;
	struct pci_dev *pci_dev;
	struct pci_dev *user_pci_dev;
	int instance;
	void *__iomem bar[PF_MAX_BAR];
	resource_size_t bar_map_size[PF_MAX_BAR];
	struct mgmt_char_dev *user_char_dev;
	struct xclmgmt_bitstream_container stash;
	int axi_gate_frozen;
	u64 unique_id_last_bitstream;
#ifdef AXI_FIREWALL
	u32 err_firewall_status[FME_MGMT_NUM_FIREWALL_IPS];
	u64 err_firewall_time[FME_MGMT_NUM_FIREWALL_IPS];
	struct proc_list proc_list;
	struct mutex proc_mutex;
#endif
	struct task_struct *kthread;
	bool busy;
	int hwicap_status;
};

#endif
