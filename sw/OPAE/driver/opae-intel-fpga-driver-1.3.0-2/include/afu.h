/*
 * FPGA Accelerated Function Unit (AFU) Header
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *     Wu Hao <hao.wu@linux.intel.com>
 *     Xiao Guangrong <guangrong.xiao@linux.intel.com>
 *     Joseph Grecco <joe.grecco@intel.com>
 *     Enno Luebbers <enno.luebbers@intel.com>
 *     Tim Whisonant <tim.whisonant@intel.com>
 *     Ananda Ravuri <ananda.ravuri@intel.com>
 *     Mitchel, Henry <henry.mitchel@intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#ifndef __INTEL_AFU_H
#define __INTEL_AFU_H

#include "backport.h"
#include "feature-dev.h"

struct fpga_afu_region {
	u32 index;
	u32 flags;
	u64 size;
	u64 offset;
	u64 phys;
	struct list_head node;
};

struct fpga_afu_dma_region {
	u64 user_addr;
	u64 length;
	u64 iova;
	struct page **pages;
	struct rb_node node;
	bool in_use;
};

struct fpga_afu {
	u64 region_cur_offset;
	u32 capability;
	int num_regions;
	u8 num_umsgs;
	u8 num_uafu_irqs;
	struct list_head regions;
	struct rb_root dma_regions;

	struct feature_platform_data *pdata;
};

void afu_region_init(struct feature_platform_data *pdata);
int afu_region_add(struct feature_platform_data *pdata, u32 region_index,
		   u64 region_size, u64 phys, u32 flags);
void afu_region_destroy(struct feature_platform_data *pdata);
int afu_get_region_by_index(struct feature_platform_data *pdata,
			    u32 region_index, struct fpga_afu_region *pregion);
int afu_get_region_by_offset(struct feature_platform_data *pdata,
			    u64 offset, u64 size,
			    struct fpga_afu_region *pregion);

void afu_dma_region_init(struct feature_platform_data *pdata);
void afu_dma_region_destroy(struct feature_platform_data *pdata);
long afu_dma_map_region(struct feature_platform_data *pdata,
		       u64 user_addr, u64 length, u64 *iova);
long afu_dma_unmap_region(struct feature_platform_data *pdata, u64 iova);
struct fpga_afu_dma_region *afu_dma_region_find(
		struct feature_platform_data *pdata, u64 iova, u64 size);

int port_hdr_test(struct platform_device *pdev, struct feature *feature);
int port_err_test(struct platform_device *pdev, struct feature *feature);
int port_umsg_test(struct platform_device *pdev, struct feature *feature);
int port_stp_test(struct platform_device *pdev, struct feature *feature);

extern struct feature_ops port_err_ops;

#endif
