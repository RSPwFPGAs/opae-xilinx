/*
 * Driver for FPGA Accelerated Function Unit (AFU) DMA Region Management
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

#include "backport.h"
#include <linux/uaccess.h>

#include "afu.h"

static void put_all_pages(struct page **pages, int npages)
{
	int i;

	for (i = 0; i < npages; i++)
		if (pages[i] != NULL)
			put_page(pages[i]);
}

void afu_dma_region_init(struct feature_platform_data *pdata)
{
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);

	afu->dma_regions = RB_ROOT;
}

static long afu_dma_adjust_locked_vm(struct device *dev, long npages, bool incr)
{
	unsigned long locked, lock_limit;
	int ret = 0;

	/* the task is exiting. */
	if (!current->mm)
		return 0;

	down_write(&current->mm->mmap_sem);

	if (incr) {
		locked = current->mm->locked_vm + npages;
		lock_limit = rlimit(RLIMIT_MEMLOCK) >> PAGE_SHIFT;

		if (locked > lock_limit && !capable(CAP_IPC_LOCK))
			ret = -ENOMEM;
		else
			current->mm->locked_vm += npages;
	} else {

		if (WARN_ON_ONCE(npages > current->mm->locked_vm))
			npages = current->mm->locked_vm;
		current->mm->locked_vm -= npages;
	}

	dev_dbg(dev, "[%d] RLIMIT_MEMLOCK %c%ld %ld/%ld%s\n", current->pid,
				incr ? '+' : '-',
				npages << PAGE_SHIFT,
				current->mm->locked_vm << PAGE_SHIFT,
				rlimit(RLIMIT_MEMLOCK),
				ret ? "- execeeded" : "");

	up_write(&current->mm->mmap_sem);

	return ret;
}

static long afu_dma_pin_pages(struct feature_platform_data *pdata,
				struct fpga_afu_dma_region *region)
{
	long npages = region->length >> PAGE_SHIFT;
	struct device *dev = &pdata->dev->dev;
	long ret, pinned;

	ret = afu_dma_adjust_locked_vm(dev, npages, true);
	if (ret)
		return ret;

	region->pages = kcalloc(npages, sizeof(struct page *), GFP_KERNEL);
	if (!region->pages) {
		afu_dma_adjust_locked_vm(dev, npages, false);
		return -ENOMEM;
	}

	pinned = get_user_pages_fast(region->user_addr, npages, 1,
					region->pages);
	if (pinned < 0) {
		ret = pinned;
		goto err_put_pages;
	} else if (pinned != npages) {
		ret = -EFAULT;
		goto err;
	}

	dev_dbg(dev, "%ld pages pinned\n", pinned);

	return 0;

err_put_pages:
	put_all_pages(region->pages, pinned);
err:
	kfree(region->pages);
	afu_dma_adjust_locked_vm(dev, npages, false);
	return ret;
}

static void afu_dma_unpin_pages(struct feature_platform_data *pdata,
				struct fpga_afu_dma_region *region)
{
	long npages = region->length >> PAGE_SHIFT;
	struct device *dev = &pdata->dev->dev;

	put_all_pages(region->pages, npages);
	kfree(region->pages);
	afu_dma_adjust_locked_vm(dev, npages, false);

	dev_dbg(dev, "%ld pages unpinned\n", npages);
}

static bool afu_dma_check_continuous_pages(struct fpga_afu_dma_region *region)
{
	int npages = region->length >> PAGE_SHIFT;
	int i;

	for (i = 0; i < npages - 1; i++)
		if (page_to_pfn(region->pages[i]) + 1 !=
					page_to_pfn(region->pages[i+1]))
			return false;

	return true;
}

static bool dma_region_check_iova(struct fpga_afu_dma_region *region,
				  u64 iova, u64 size)
{
	if (!size && region->iova != iova)
		return false;

	return (region->iova <= iova) &&
		(region->length + region->iova >= iova + size);
}

/* Need to be called with pdata->lock held */
static int afu_dma_region_add(struct feature_platform_data *pdata,
					struct fpga_afu_dma_region *region)
{
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);
	struct rb_node **new, *parent = NULL;

	dev_dbg(&pdata->dev->dev, "add region (iova = %llx)\n",
					(unsigned long long)region->iova);

	new = &(afu->dma_regions.rb_node);

	while (*new) {
		struct fpga_afu_dma_region *this;

		this = container_of(*new, struct fpga_afu_dma_region, node);

		parent = *new;

		if (dma_region_check_iova(this, region->iova, region->length))
			return -EEXIST;

		if (region->iova < this->iova)
			new = &((*new)->rb_left);
		else if (region->iova > this->iova)
			new = &((*new)->rb_right);
		else
			return -EEXIST;
	}

	rb_link_node(&region->node, parent, new);
	rb_insert_color(&region->node, &afu->dma_regions);

	return 0;
}

/* Need to be called with pdata->lock held */
static void afu_dma_region_remove(struct feature_platform_data *pdata,
					struct fpga_afu_dma_region *region)
{
	struct fpga_afu *afu;

	dev_dbg(&pdata->dev->dev, "del region (iova = %llx)\n",
					(unsigned long long)region->iova);

	afu = fpga_pdata_get_private(pdata);
	rb_erase(&region->node, &afu->dma_regions);
}

/* Need to be called with pdata->lock held */
void afu_dma_region_destroy(struct feature_platform_data *pdata)
{
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);
	struct rb_node *node = rb_first(&afu->dma_regions);
	struct fpga_afu_dma_region *region;

	while (node) {
		region = container_of(node, struct fpga_afu_dma_region, node);

		dev_dbg(&pdata->dev->dev, "del region (iova = %llx)\n",
					(unsigned long long)region->iova);

		rb_erase(node, &afu->dma_regions);

		if (region->iova)
			dma_unmap_page(fpga_pdata_to_pcidev(pdata),
					region->iova, region->length,
					DMA_BIDIRECTIONAL);

		if (region->pages)
			afu_dma_unpin_pages(pdata, region);

		node = rb_next(node);
		kfree(region);
	}
}

/*
 * It finds the dma region from the rbtree based on @iova and @size:
 * - if @size == 0, it finds the dma region which starts from @iova
 * - otherwise, it finds the dma region which fully contains
 *   [@iova, @iova+size)
 * If nothing is matched returns NULL.
 *
 * Need to be called with pdata->lock held.
 */
struct fpga_afu_dma_region *
afu_dma_region_find(struct feature_platform_data *pdata, u64 iova, u64 size)
{
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);
	struct rb_node *node = afu->dma_regions.rb_node;
	struct device *dev = &pdata->dev->dev;

	while (node) {
		struct fpga_afu_dma_region *region;

		region = container_of(node, struct fpga_afu_dma_region, node);

		if (dma_region_check_iova(region, iova, size)) {
			dev_dbg(dev, "find region (iova = %llx)\n",
				(unsigned long long)region->iova);
			return region;
		}

		if (iova < region->iova)
			node = node->rb_left;
		else if (iova > region->iova)
			node = node->rb_right;
		else
			/* the iova region is not fully covered. */
			break;
	}

	dev_dbg(dev, "region with iova %llx and size %llx is not found\n",
		(unsigned long long)iova, (unsigned long long)size);
	return NULL;
}

static struct fpga_afu_dma_region *
afu_dma_region_find_iova(struct feature_platform_data *pdata, u64 iova)
{
	return afu_dma_region_find(pdata, iova, 0);
}

long afu_dma_map_region(struct feature_platform_data *pdata,
		       u64 user_addr, u64 length, u64 *iova)
{
	struct fpga_afu_dma_region *region;
	int ret;

	/*
	 * Check Inputs, only accept page-aligned user memory region with
	 * valid length.
	 */
	if (!PAGE_ALIGNED(user_addr) || !PAGE_ALIGNED(length) || !length)
		return -EINVAL;

	/* Check overflow */
	if (user_addr + length < user_addr)
		return -EINVAL;

	if (!access_ok(VERIFY_WRITE, user_addr, length))
		return -EINVAL;

	region = kzalloc(sizeof(*region), GFP_KERNEL);
	if (!region)
		return -ENOMEM;

	region->user_addr = user_addr;
	region->length = length;

	/* Pin the user memory region */
	ret = afu_dma_pin_pages(pdata, region);
	if (ret) {
		dev_err(&pdata->dev->dev, "fail to pin memory region\n");
		goto free_region;
	}

	/* Only accept continuous pages, return error if no */
	if (!afu_dma_check_continuous_pages(region)) {
		dev_err(&pdata->dev->dev, "pages are not continuous\n");
		ret = -EINVAL;
		goto unpin_pages;
	}

	/* As pages are continuous then start to do DMA mapping */
	region->iova = dma_map_page(fpga_pdata_to_pcidev(pdata),
				    region->pages[0], 0,
				    region->length,
				    DMA_BIDIRECTIONAL);
	if (dma_mapping_error(&pdata->dev->dev, region->iova)) {
		dev_err(&pdata->dev->dev, "fail to map dma mapping\n");
		ret = -EFAULT;
		goto unpin_pages;
	}

	*iova = region->iova;

	mutex_lock(&pdata->lock);
	ret = afu_dma_region_add(pdata, region);
	mutex_unlock(&pdata->lock);
	if (ret) {
		dev_err(&pdata->dev->dev, "fail to add dma region\n");
		goto unmap_dma;
	}

	return 0;

unmap_dma:
	dma_unmap_page(fpga_pdata_to_pcidev(pdata),
		       region->iova, region->length, DMA_BIDIRECTIONAL);
unpin_pages:
	afu_dma_unpin_pages(pdata, region);
free_region:
	kfree(region);
	return ret;
}

long afu_dma_unmap_region(struct feature_platform_data *pdata, u64 iova)
{
	struct fpga_afu_dma_region *region;

	mutex_lock(&pdata->lock);
	region = afu_dma_region_find_iova(pdata, iova);
	if (!region) {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	}

	if (region->in_use) {
		mutex_unlock(&pdata->lock);
		return -EBUSY;
	}

	afu_dma_region_remove(pdata, region);
	mutex_unlock(&pdata->lock);

	dma_unmap_page(fpga_pdata_to_pcidev(pdata),
		       region->iova, region->length, DMA_BIDIRECTIONAL);
	afu_dma_unpin_pages(pdata, region);
	kfree(region);

	return 0;
}
