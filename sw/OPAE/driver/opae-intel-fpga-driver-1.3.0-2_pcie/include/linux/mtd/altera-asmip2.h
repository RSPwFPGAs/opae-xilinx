/*
 *
 * Copyright 2017 Intel Corporation, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
#ifndef __ALTERA_QUADSPI_H
#define __ALTERA_QUADSPI_H

#include <linux/device.h>

#define ALTERA_ASMIP2_DRV_NAME "altr-asmip2"
#define ALTERA_ASMIP2_MAX_NUM_FLASH_CHIP 3
#define ALTERA_ASMIP2_RESOURCE_SIZE 0x10

struct altera_asmip2_plat_data {
	void __iomem *csr_base;
	u32 num_chip_sel;
};

#endif
