/*
 * Driver for FPGA Accelerated Function Unit (AFU) Region Management
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Wu Hao <hao.wu@linux.intel.com>
 *   Xiao Guangrong <guangrong.xiao@linux.intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#include "afu.h"

void afu_region_init(struct feature_platform_data *pdata)
{
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);

	INIT_LIST_HEAD(&afu->regions);
}

#define for_each_region(region, afu)	\
	list_for_each_entry((region), &(afu)->regions, node)
static struct fpga_afu_region *get_region_by_index(struct fpga_afu *afu,
						   u32 region_index)
{
	struct fpga_afu_region *region;

	for_each_region(region, afu)
		if (region->index == region_index)
			return region;

	return NULL;
}

int afu_region_add(struct feature_platform_data *pdata, u32 region_index,
		   u64 region_size, u64 phys, u32 flags)
{
	struct fpga_afu_region *region;
	struct fpga_afu *afu;
	int ret = 0;

	region = devm_kzalloc(&pdata->dev->dev, sizeof(*region), GFP_KERNEL);
	if (!region)
		return -ENOMEM;

	region->index = region_index;
	region->size = region_size;
	region->phys = phys;
	region->flags = flags;

	mutex_lock(&pdata->lock);

	afu = fpga_pdata_get_private(pdata);

	/* check if @index already exists */
	if (get_region_by_index(afu, region_index)) {
		mutex_unlock(&pdata->lock);
		ret = -EEXIST;
		goto exit;
	}

	region_size = PAGE_ALIGN(region_size);
	region->offset = afu->region_cur_offset;
	list_add(&region->node, &afu->regions);

	afu->region_cur_offset += region_size;
	afu->num_regions++;
	mutex_unlock(&pdata->lock);
	return 0;

exit:
	devm_kfree(&pdata->dev->dev, region);
	return ret;
}

void afu_region_destroy(struct feature_platform_data *pdata)
{
	struct fpga_afu_region *tmp, *region;
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);

	list_for_each_entry_safe(region, tmp, &afu->regions, node) {
		list_del(&region->node);
		devm_kfree(&pdata->dev->dev, region);
	}
}

int afu_get_region_by_index(struct feature_platform_data *pdata,
			    u32 region_index, struct fpga_afu_region *pregion)
{
	struct fpga_afu_region *region;
	struct fpga_afu *afu;
	int ret = 0;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	region = get_region_by_index(afu, region_index);
	if (!region) {
		ret = -EINVAL;
		goto exit;
	}
	*pregion = *region;
exit:
	mutex_unlock(&pdata->lock);
	return ret;
}

int afu_get_region_by_offset(struct feature_platform_data *pdata,
			    u64 offset, u64 size,
			    struct fpga_afu_region *pregion)
{
	struct fpga_afu_region *region;
	struct fpga_afu *afu;
	int ret = 0;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	for_each_region(region, afu)
		if (region->offset <= offset &&
		   region->offset + region->size >= offset + size) {
			*pregion = *region;
			goto exit;
		}
	ret = -EINVAL;
exit:
	mutex_unlock(&pdata->lock);
	return ret;
}
