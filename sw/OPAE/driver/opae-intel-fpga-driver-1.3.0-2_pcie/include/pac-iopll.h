/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Driver Header file for Intel Programable Acceleration Card I/O PLL
 *
 * Copyright 2018 (C) Intel Corporation, Inc.
 */

#ifndef __INTEL_PAC_IOPLL_H
#define __INTEL_PAC_IOPLL_H

#include <linux/device.h>

#define PAC_IOPLL_DRV_NAME	"intel-pac-iopll"
#define PAC_IOPLL_RESOURCE_SIZE	0x28

struct pac_iopll_plat_data {
	void __iomem *csr_base;
};

#endif /* __INTEL_PAC_IOPLL_H */
