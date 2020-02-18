/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Driver Header for Avalon Memory Mapped Interface to BMC
 *
 * Copyright (C) 2018 Intel Corporation. All rights reserved.
 */

#ifndef __AVMMI_BMC_H__
#define __AVMMI_BMC_H__

#include <linux/platform_device.h>

#define AVMMI_BMC_DRV_NAME "avmmi-bmc"

struct avmmi_plat_data {
	void __iomem *csr_base;
};

#endif
