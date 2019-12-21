/*
 * check the pcie parsed header with the default value in SAS spec
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Zhang Yi <Yi.Z.Zhang@intel.com>
 *   Xiao Guangrong <guangrong.xiao@linux.intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 */

#include <linux/pci.h>
#include <linux/kdev_t.h>
#include <linux/stddef.h>
#include "feature-dev.h"

#define DFH_CCI_VERSION				0x1
#define DFH_TYPE_PRIVATE			0x3
#define DFH_TYPE_AFU				0x1
#define DFH_TYPE_FIU				0x4
#define DFH_TYPE_FIU_ID_FME			0x0
#define DFH_TYPE_FIU_ID_PORT			0x1

#define FME_FEATURE_HEADER_TYPE			DFH_TYPE_FIU
#define FME_FEATURE_HEADER_NEXT_OFFSET		0x1000
#define FME_FEATURE_HEADER_ID			DFH_TYPE_FIU_ID_FME
#define FME_FEATURE_HEADER_VERSION		0x1

#define FME_FEATURE_THERMAL_MGMT_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_THERMAL_MGMT_NEXT_OFFSET	0x1000
#define FME_FEATURE_THERMAL_MGMT_ID		0x1
#define FME_FEATURE_THERMAL_MGMT_VERSION	0x0

#define FME_FEATURE_POWER_MGMT_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_POWER_MGMT_NEXT_OFFSET	0x1000
#define FME_FEATURE_POWER_MGMT_ID		0x2
#define FME_FEATURE_POWER_MGMT_VERSION		0x1

#define FME_FEATURE_GLOBAL_IPERF_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_GLOBAL_IPERF_NEXT_OFFSET	0x1000
#define FME_FEATURE_GLOBAL_IPERF_ID		0x3
#define FME_FEATURE_GLOBAL_IPERF_VERSION	0x1

#define FME_FEATURE_GLOBAL_ERR_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_GLOBAL_ERR_NEXT_OFFSET	0x1000
#define FME_FEATURE_GLOBAL_ERR_ID		0x4
#define FME_FEATURE_GLOBAL_ERR_VERSION		0x1

#define FME_FEATURE_PR_MGMT_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_PR_MGMT_NEXT_OFFSET		0x1000
#define FME_FEATURE_PR_MGMT_ID			0x5
#define FME_FEATURE_PR_MGMT_VERSION		0x2

#define FME_FEATURE_HSSI_ETH_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_HSSI_ETH_NEXT_OFFSET	0x1000
#define FME_FEATURE_HSSI_ETH_ID			0x6
#define FME_FEATURE_HSSI_ETH_VERSION		0x0

#define FME_FEATURE_GLOBAL_DPERF_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_GLOBAL_DPERF_NEXT_OFFSET	0x0
#define FME_FEATURE_GLOBAL_DPERF_ID		0x7
#define FME_FEATURE_GLOBAL_DPERF_VERSION	0x0

#define FME_FEATURE_QSPI_FLASH_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_QSPI_FLASH_NEXT_OFFSET	0x2000
#define FME_FEATURE_QSPI_FLASH_ID		FME_FEATURE_ID_QSPI_FLASH
#define FME_FEATURE_QSPI_FLASH_VERSION		FME_QSPI_REVISION

#define PORT_FEATURE_HEADER_TYPE		DFH_TYPE_FIU
#define PORT_FEATURE_HEADER_NEXT_OFFSET		0x1000
#define PORT_FEATURE_HEADER_ID			DFH_TYPE_FIU_ID_PORT
#define PORT_FEATURE_HEADER_VERSION		0x0

#define FME_FEATURE_EMIF_MGMT_TYPE		DFH_TYPE_PRIVATE
#define FME_FEATURE_EMIF_MGMT_NEXT_OFFSET	0x1000
#define FME_FEATURE_EMIF_MGMT_ID		FME_FEATURE_ID_EMIF_MGMT
#define FME_FEATURE_EMIF_MGMT_VERSION		0x0

#define PORT_FEATURE_ERR_TYPE			DFH_TYPE_PRIVATE
#define PORT_FEATURE_ERR_NEXT_OFFSET		0x1000
#define PORT_FEATURE_ERR_ID			0x10
#define PORT_FEATURE_ERR_VERSION		0x1

#define PORT_FEATURE_UMSG_TYPE			DFH_TYPE_PRIVATE
#define PORT_FEATURE_UMSG_NEXT_OFFSET		0x2000
#define PORT_FEATURE_UMSG_ID			0x11
#define PORT_FEATURE_UMSG_VERSION		0x0

#define PORT_FEATURE_STP_TYPE			DFH_TYPE_PRIVATE
#define PORT_FEATURE_STP_NEXT_OFFSET		0x1000
#define PORT_FEATURE_STP_ID			0x13
#define PORT_FEATURE_STP_VERSION		0x1

#define PORT_FEATURE_IOPLL_TYPE			DFH_TYPE_PRIVATE
#define PORT_FEATURE_IOPLL_NEXT_OFFSET		0
#define PORT_FEATURE_IOPLL_ID			0x14
#define PORT_FEATURE_IOPLL_VERSION		0x0

#define DEFAULT_REG(name)	{.id = name##_ID, .revision = name##_VERSION,\
				.next_header_offset = name##_NEXT_OFFSET,\
				.type = name##_TYPE,}

static struct feature_header default_port_feature_hdr[] = {
	DEFAULT_REG(PORT_FEATURE_HEADER),
	DEFAULT_REG(PORT_FEATURE_ERR),
	DEFAULT_REG(PORT_FEATURE_UMSG),
	{.csr = 0,},
	DEFAULT_REG(PORT_FEATURE_STP),
	DEFAULT_REG(PORT_FEATURE_IOPLL),
	{.csr = 0,},
};

static struct feature_header default_fme_feature_hdr[] = {
	DEFAULT_REG(FME_FEATURE_HEADER),
	DEFAULT_REG(FME_FEATURE_THERMAL_MGMT),
	DEFAULT_REG(FME_FEATURE_POWER_MGMT),
	DEFAULT_REG(FME_FEATURE_GLOBAL_IPERF),
	DEFAULT_REG(FME_FEATURE_GLOBAL_ERR),
	DEFAULT_REG(FME_FEATURE_PR_MGMT),
	DEFAULT_REG(FME_FEATURE_HSSI_ETH),
	DEFAULT_REG(FME_FEATURE_GLOBAL_DPERF),
	DEFAULT_REG(FME_FEATURE_QSPI_FLASH),
	DEFAULT_REG(FME_FEATURE_EMIF_MGMT),
};

void check_features_header(struct pci_dev *pdev, struct feature_header *hdr,
			   enum fpga_devt_type type, int id)
{
	struct feature_header *default_header, header;

	if (type == FPGA_DEVT_FME) {
		default_header = default_fme_feature_hdr;
		if (id >= ARRAY_SIZE(default_fme_feature_hdr)) {
			dev_dbg(&pdev->dev, "unknown fme feature\n");
			return;
		}
	} else if (type == FPGA_DEVT_PORT) {
		default_header = default_port_feature_hdr;
		if (id >= ARRAY_SIZE(default_port_feature_hdr)) {
			dev_dbg(&pdev->dev, "unknown port feature\n");
			return;
		}
	} else {
		dev_dbg(&pdev->dev, "unknown devt type\n");
		return;
	}

	header.csr = readq(hdr);

	if (memcmp(&header, default_header + id, sizeof(header)))
		dev_dbg(&pdev->dev,
			"check header failed. current hdr:%llx - default_value:%llx.\n",
			header.csr, *(u64 *)(default_header + id));
	else
		dev_dbg(&pdev->dev,
			"check header pass.\n");
}
