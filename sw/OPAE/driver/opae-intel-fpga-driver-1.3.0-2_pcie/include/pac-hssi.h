/*
 *
 * Copyright 2018 Intel Corporation, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
#ifndef __INTEL_PAC_HSSI_H
#define __INTEL_PAC_HSSI_H

#include <linux/device.h>

#define PAC_HSSI_DRV_NAME	"intel-pac-hssi"
#define PAC_HSSI_RESOURCE_SIZE	0x18

struct pac_hssi_plat_data {
	void __iomem *csr_base;
};

#endif /* __INTEL_PAC_HSSI_H */
