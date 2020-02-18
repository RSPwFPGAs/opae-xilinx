/*
 * Driver for FPGA Accelerated Function Unit (AFU)
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Wu Hao <hao.wu@linux.intel.com>
 *   Xiao Guangrong <guangrong.xiao@linux.intel.com>
 *   Joseph Grecco <joe.grecco@intel.com>
 *   Enno Luebbers <enno.luebbers@intel.com>
 *   Tim Whisonant <tim.whisonant@intel.com>
 *   Ananda Ravuri <ananda.ravuri@intel.com>
 *   Mitchel, Henry <henry.mitchel@intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/uaccess.h>
#include <linux/stddef.h>
#include <linux/errno.h>
#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/dma-mapping.h>
#include <linux/intel-fpga-mod.h>

#include "pac-iopll.h"
#include "afu.h"

/* sysfs attributes for port_hdr feature */
static ssize_t
revision_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct feature_port_header *port_hdr
		= get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);
	struct feature_header header;

	header.csr = readq(&port_hdr->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static DEVICE_ATTR_RO(revision);

static ssize_t
id_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	int id = fpga_port_id(to_platform_device(dev));

	return scnprintf(buf, PAGE_SIZE, "%d\n", id);
}
static DEVICE_ATTR_RO(id);

static ssize_t
ltr_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct feature_port_header *port_hdr;
	struct feature_port_control control;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	control.csr = readq(&port_hdr->control);

	return scnprintf(buf, PAGE_SIZE, "%d\n", control.latency_tolerance);
}
static DEVICE_ATTR_RO(ltr);

static ssize_t
ap1_event_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	struct feature_port_status status;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	status.csr = readq(&port_hdr->status);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "%d\n", status.ap1_event);
}

static ssize_t
ap1_event_store(struct device *dev, struct device_attribute *attr,
		const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	struct feature_port_status status;
	u8 ap1_event;
	int err;

	err = kstrtou8(buf, 0, &ap1_event);
	if (err)
		return err;

	if (ap1_event != 1)
		return -EINVAL;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	status.csr = readq(&port_hdr->status);
	status.ap1_event = ap1_event;
	writeq(status.csr, &port_hdr->status);
	mutex_unlock(&pdata->lock);

	return count;
}
static DEVICE_ATTR_RW(ap1_event);

static ssize_t
ap2_event_show(struct device *dev, struct device_attribute *attr,
	       char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	struct feature_port_status status;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	status.csr = readq(&port_hdr->status);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "%d\n", status.ap2_event);
}

static ssize_t
ap2_event_store(struct device *dev, struct device_attribute *attr,
		const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	struct feature_port_status status;
	u8 ap2_event;
	int err;

	err = kstrtou8(buf, 0, &ap2_event);
	if (err)
		return err;

	if (ap2_event != 1)
		return -EINVAL;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	status.csr = readq(&port_hdr->status);
	status.ap2_event = ap2_event;
	writeq(status.csr, &port_hdr->status);
	mutex_unlock(&pdata->lock);

	return count;
}
static DEVICE_ATTR_RW(ap2_event);

static ssize_t
power_state_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	struct feature_port_status status;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	status.csr = readq(&port_hdr->status);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "0x%x\n", status.power_state);
}
static DEVICE_ATTR_RO(power_state);

static ssize_t
userclk_freqcmd_show(struct device *dev, struct device_attribute *attr,
		     char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	u64 userclk_freq_cmd;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	userclk_freq_cmd = readq(&port_hdr->user_clk_freq_cmd0);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", userclk_freq_cmd);
}

static ssize_t
userclk_freqcmd_store(struct device *dev, struct device_attribute *attr,
		      const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	u64 userclk_freq_cmd;
	int err;

	err = kstrtou64(buf, 0, &userclk_freq_cmd);
	if (err)
		return err;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	writeq(userclk_freq_cmd, &port_hdr->user_clk_freq_cmd0);
	mutex_unlock(&pdata->lock);

	return count;
}
static DEVICE_ATTR_RW(userclk_freqcmd);

static ssize_t
userclk_freqcntrcmd_show(struct device *dev, struct device_attribute *attr,
			 char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	u64 userclk_freqcntr_cmd;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	userclk_freqcntr_cmd = readq(&port_hdr->user_clk_freq_cmd1);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", userclk_freqcntr_cmd);
}

static ssize_t
userclk_freqcntrcmd_store(struct device *dev, struct device_attribute *attr,
			  const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_port_header *port_hdr;
	u64 userclk_freqcntr_cmd;
	int err;

	err = kstrtou64(buf, 0, &userclk_freqcntr_cmd);
	if (err)
		return err;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	mutex_lock(&pdata->lock);
	writeq(userclk_freqcntr_cmd, &port_hdr->user_clk_freq_cmd1);
	mutex_unlock(&pdata->lock);

	return count;
}
static DEVICE_ATTR_RW(userclk_freqcntrcmd);

static ssize_t
userclk_freqsts_show(struct device *dev, struct device_attribute *attr,
		     char *buf)
{
	struct feature_port_header *port_hdr;
	u64 userclk_freq_sts;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	userclk_freq_sts = readq(&port_hdr->user_clk_freq_sts0);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", userclk_freq_sts);
}
static DEVICE_ATTR_RO(userclk_freqsts);

static ssize_t
userclk_freqcntrsts_show(struct device *dev, struct device_attribute *attr,
			 char *buf)
{
	struct feature_port_header *port_hdr;
	u64 userclk_freqcntr_sts;

	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	userclk_freqcntr_sts = readq(&port_hdr->user_clk_freq_sts1);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", userclk_freqcntr_sts);
}
static DEVICE_ATTR_RO(userclk_freqcntrsts);

static const struct attribute *port_hdr_attrs[] = {
	&dev_attr_revision.attr,
	&dev_attr_id.attr,
	&dev_attr_ltr.attr,
	&dev_attr_ap1_event.attr,
	&dev_attr_ap2_event.attr,
	&dev_attr_power_state.attr,
	NULL,
};

static const struct attribute *port_hdr_userclk_attrs[] = {
	&dev_attr_userclk_freqcmd.attr,
	&dev_attr_userclk_freqcntrcmd.attr,
	&dev_attr_userclk_freqsts.attr,
	&dev_attr_userclk_freqcntrsts.attr,
	NULL,
};

static int port_hdr_init(struct platform_device *pdev, struct feature *feature)
{
	struct feature_port_header *port_hdr =
		get_feature_ioaddr_by_index(&pdev->dev, PORT_FEATURE_ID_HEADER);
	struct feature_header header;
	int ret;

	dev_dbg(&pdev->dev, "PORT HDR Init.\n");

	fpga_port_reset(pdev);

	ret = sysfs_create_files(&pdev->dev.kobj, port_hdr_attrs);
	if (ret)
		return ret;

	header.csr = readq(&port_hdr->header);
	if (header.revision > 0)
		return 0;

	ret = sysfs_create_files(&pdev->dev.kobj, port_hdr_userclk_attrs);
	if (ret)
		sysfs_remove_files(&pdev->dev.kobj, port_hdr_attrs);

	return ret;
}

static void port_hdr_uinit(struct platform_device *pdev,
					struct feature *feature)
{
	dev_dbg(&pdev->dev, "PORT HDR UInit.\n");

	sysfs_remove_files(&pdev->dev.kobj, port_hdr_userclk_attrs);
	sysfs_remove_files(&pdev->dev.kobj, port_hdr_attrs);
}

static long
port_hdr_ioctl(struct platform_device *pdev, struct feature *feature,
					unsigned int cmd, unsigned long arg)
{
	long ret;

	switch (cmd) {
	case FPGA_PORT_RESET:
		if (!arg)
			ret = fpga_port_reset(pdev);
		else
			ret = -EINVAL;
		break;
	default:
		dev_dbg(&pdev->dev, "%x cmd not handled", cmd);
		ret = -ENODEV;
	}

	return ret;
}

static struct feature_ops port_hdr_ops = {
	.init = port_hdr_init,
	.uinit = port_hdr_uinit,
	.ioctl = port_hdr_ioctl,
	.test = port_hdr_test,
};

/* sysfs attributes for port_uafu feature */
static ssize_t
afu_id_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_header *hdr =
			get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UAFU);
	struct feature_afu_header *afu_hdr =
			(struct feature_afu_header *)(hdr + 1);
	u64 guidl;
	u64 guidh;

	mutex_lock(&pdata->lock);
	if (pdata->disable_count) {
		mutex_unlock(&pdata->lock);
		return -EBUSY;
	}

	guidl = readq(&afu_hdr->guid.b[0]);
	guidh = readq(&afu_hdr->guid.b[8]);
	mutex_unlock(&pdata->lock);

	return scnprintf(buf, PAGE_SIZE, "%016llx%016llx\n", guidh, guidl);
}
static DEVICE_ATTR_RO(afu_id);

static const struct attribute *port_uafu_attrs[] = {
	&dev_attr_afu_id.attr,
	NULL
};

static int port_afu_init(struct platform_device *pdev, struct feature *feature)
{
	struct resource *res = &pdev->resource[feature->resource_index];
	u32 flags = FPGA_REGION_READ | FPGA_REGION_WRITE | FPGA_REGION_MMAP;
	int ret;

	dev_dbg(&pdev->dev, "PORT AFU Init.\n");

	ret = afu_region_add(dev_get_platdata(&pdev->dev),
			     FPGA_PORT_INDEX_UAFU, resource_size(res),
			     res->start, flags);
	if (ret)
		return ret;

	return sysfs_create_files(&pdev->dev.kobj, port_uafu_attrs);
}

static void port_afu_uinit(struct platform_device *pdev,
					struct feature *feature)
{
	dev_dbg(&pdev->dev, "PORT AFU UInit.\n");

	sysfs_remove_files(&pdev->dev.kobj, port_uafu_attrs);
}

static long port_afu_set_irq(struct platform_device *pdev,
			struct feature *feature, unsigned long arg)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_port_uafu_irq_set hdr;
	struct fpga_afu *afu;
	unsigned long minsz;
	int32_t *fds = NULL;
	long ret = 0;

	minsz = offsetofend(struct fpga_port_uafu_irq_set, count);

	if (copy_from_user(&hdr, (void __user *)arg, minsz))
		return -EFAULT;

	if (hdr.argsz < minsz || hdr.flags)
		return -EINVAL;

	if ((hdr.start + hdr.count > feature->ctx_num) ||
		(hdr.start + hdr.count < hdr.start) || !hdr.count)
		return -EINVAL;

	fds = memdup_user((void __user *)(arg + minsz),
			  hdr.count * sizeof(int32_t));
	if (IS_ERR(fds))
		return PTR_ERR(fds);

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	if (!(afu->capability & FPGA_PORT_CAP_UAFU_IRQ)) {
		mutex_unlock(&pdata->lock);
		kfree(fds);
		return -ENODEV;
	}
	ret = fpga_msix_set_block(feature, hdr.start, hdr.count, fds);
	mutex_unlock(&pdata->lock);

	kfree(fds);
	return ret;
}

static struct feature_ops port_afu_ops = {
	.init = port_afu_init,
	.uinit = port_afu_uinit,
};

static u8 port_umsg_get_num(struct device *dev)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_cap capability;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	capability.csr = readq(&port_umsg->capability);

	return capability.umsg_allocated;
}

#define UMSG_EN_POLL_INVL 10 /* us */
#define UMSG_EN_POLL_TIMEOUT 1000 /* us */

static int port_umsg_enable(struct device *dev, bool enable)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_cap capability;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	capability.csr = readq(&port_umsg->capability);

	/* Return directly if UMSG is already enabled/disabled */
	if ((enable && capability.umsg_enable) ||
			!(enable || capability.umsg_enable))
		return 0;

	capability.umsg_enable = enable;
	writeq(capability.csr, &port_umsg->capability);

	/*
	 * Each time umsg engine enabled/disabled, driver polls the
	 * init_complete bit for confirmation.
	 */
	capability.umsg_init_complete = !!enable;

	if (fpga_wait_register_field(umsg_init_complete, capability,
				     &port_umsg->capability,
				     UMSG_EN_POLL_TIMEOUT, UMSG_EN_POLL_INVL)) {
		dev_err(dev, "timeout, fail to %s umsg\n",
					enable ? "enable" : "disable");
		return -ETIMEDOUT;
	}

	return 0;
}

static bool port_umsg_is_enabled(struct device *dev)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_cap capability;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	capability.csr = readq(&port_umsg->capability);

	return capability.umsg_enable;
}

static void port_umsg_set_mode(struct device *dev, u32 mode)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_mode umode;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	umode.csr = readq(&port_umsg->mode);
	umode.umsg_hint_enable = mode;
	writeq(umode.csr, &port_umsg->mode);
}

static u64 port_umsg_get_addr(struct device *dev)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_baseaddr baseaddr;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	baseaddr.csr = readq(&port_umsg->baseaddr);

	return baseaddr.base_addr;
}

static void port_umsg_set_addr(struct device *dev, u64 iova)
{
	struct feature_port_umsg *port_umsg;
	struct feature_port_umsg_baseaddr baseaddr;

	port_umsg = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_UMSG);

	baseaddr.csr = readq(&port_umsg->baseaddr);
	baseaddr.base_addr = iova;
	writeq(baseaddr.csr, &port_umsg->baseaddr);
}

static int afu_port_umsg_enable(struct device *dev, bool enable)
{
	if (enable && !port_umsg_get_addr(dev)) {
		dev_dbg(dev, "umsg base addr is not configured\n");
		return -EIO;
	}

	return port_umsg_enable(dev, enable);
}

static int afu_port_umsg_set_addr(struct device *dev, u64 iova)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);
	struct fpga_afu_dma_region *dma_region;
	u64 size = afu->num_umsgs * PAGE_SIZE;

	/* Make sure base addr is configured only when umsg is disabled */
	if (port_umsg_is_enabled(dev)) {
		dev_dbg(dev, "umsg is still enabled\n");
		return -EIO;
	}

	if (iova) {
		/* Check input, only accept page-aligned region for umsg */
		if (!PAGE_ALIGNED(iova))
			return -EINVAL;

		/* Check overflow */
		if (iova + size < iova)
			return -EINVAL;

		/* Check if any dma region matches with iova for umsg */
		dma_region = afu_dma_region_find(pdata, iova, size);
		if (!dma_region) {
			dev_dbg(dev, "dma region not found for umsg\n");
			return -EINVAL;
		}

		port_umsg_set_addr(dev, iova);

		/* Mark the region to prevent it from unexpected unmapping */
		dma_region->in_use = true;
	} else {
		/* Read current iova from hardware */
		iova = port_umsg_get_addr(dev);
		if (!iova)
			return 0;

		/* Check overflow */
		if (WARN_ON(iova + size < iova))
			return -EINVAL;

		/* Check if any dma region matches with iova for umsg */
		dma_region = afu_dma_region_find(pdata, iova, size);
		if (WARN_ON(!dma_region))
			return -ENODEV;

		port_umsg_set_addr(dev, 0);

		/* Unmark the region */
		dma_region->in_use = false;
	}

	return 0;
}

static int afu_port_umsg_set_mode(struct device *dev, u32 mode)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct fpga_afu *afu = fpga_pdata_get_private(pdata);

	if (mode >> afu->num_umsgs) {
		dev_dbg(dev, "invaild UMsg config hint_bitmap\n");
		return -EINVAL;
	}

	port_umsg_set_mode(dev, mode);

	return 0;
}

static void afu_port_umsg_halt(struct device *dev)
{
	if (is_feature_present(dev, PORT_FEATURE_ID_UMSG)) {
		afu_port_umsg_enable(dev, false);
		afu_port_umsg_set_addr(dev, 0);
		afu_port_umsg_set_mode(dev, 0);
	}
}

static long afu_umsg_ioctl_enable(struct feature_platform_data *pdata,
				  bool enable, unsigned long arg)
{
	long ret;

	if (arg)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	ret = afu_port_umsg_enable(&pdata->dev->dev, enable);
	mutex_unlock(&pdata->lock);

	return ret;
}

static long
afu_umsg_ioctl_set_mode(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_port_umsg_cfg uconfig;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct fpga_port_umsg_cfg, hint_bitmap);

	if (copy_from_user(&uconfig, arg, minsz))
		return -EFAULT;

	if (uconfig.argsz < minsz || uconfig.flags)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	ret = afu_port_umsg_set_mode(&pdata->dev->dev, uconfig.hint_bitmap);
	mutex_unlock(&pdata->lock);

	return ret;
}

static long afu_umsg_ioctl_set_base_addr(struct feature_platform_data *pdata,
						void __user *arg)
{
	struct fpga_port_umsg_base_addr baseaddr;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct fpga_port_umsg_base_addr, iova);

	if (copy_from_user(&baseaddr, arg, minsz))
		return -EFAULT;

	if (baseaddr.argsz < minsz || baseaddr.flags)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	ret = afu_port_umsg_set_addr(&pdata->dev->dev, baseaddr.iova);
	mutex_unlock(&pdata->lock);

	return ret;
}

static int port_umsg_init(struct platform_device *pdev, struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_afu *afu;

	dev_dbg(&pdev->dev, "PORT UMSG Init.\n");

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	afu->num_umsgs = port_umsg_get_num(&pdev->dev);
	WARN_ON(!afu->num_umsgs || afu->num_umsgs > MAX_PORT_UMSG_NUM);
	mutex_unlock(&pdata->lock);

	return 0;
}

static void port_umsg_uinit(struct platform_device *pdev,
					struct feature *feature)
{
	dev_dbg(&pdev->dev, "PORT UMSG UInit.\n");
}

static long
port_umsg_ioctl(struct platform_device *pdev, struct feature *feature,
					unsigned int cmd, unsigned long arg)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	long ret;

	switch (cmd) {
	case FPGA_PORT_UMSG_ENABLE:
		return afu_umsg_ioctl_enable(pdata, true, arg);
	case FPGA_PORT_UMSG_DISABLE:
		return afu_umsg_ioctl_enable(pdata, false, arg);
	case FPGA_PORT_UMSG_SET_MODE:
		return afu_umsg_ioctl_set_mode(pdata, (void __user *)arg);
	case FPGA_PORT_UMSG_SET_BASE_ADDR:
		return afu_umsg_ioctl_set_base_addr(pdata, (void __user *)arg);
	default:
		dev_dbg(&pdev->dev, "%x cmd not handled", cmd);
		ret = -ENODEV;
	}

	return ret;
}

static struct feature_ops port_umsg_ops = {
	.init = port_umsg_init,
	.uinit = port_umsg_uinit,
	.test = port_umsg_test,
	.ioctl = port_umsg_ioctl,
};

static int port_uint_init(struct platform_device *pdev, struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_afu *afu;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	if (feature->ctx_num) {
		afu->capability |= FPGA_PORT_CAP_UAFU_IRQ;
		afu->num_uafu_irqs = feature->ctx_num;
	}
	mutex_unlock(&pdata->lock);

	return 0;
}

static void port_uint_uinit(struct platform_device *pdev,
			    struct feature *feature)
{
	dev_dbg(&pdev->dev, "PORT UINT UInit.\n");
}

static long
port_uint_ioctl(struct platform_device *pdev, struct feature *feature,
		unsigned int cmd, unsigned long arg)
{
	long ret;

	switch (cmd) {
	case FPGA_PORT_UAFU_SET_IRQ:
		ret = port_afu_set_irq(pdev, feature, arg);
		break;
	default:
		dev_dbg(&pdev->dev, "%x cmd not handled", cmd);
		return -ENODEV;
	}
	return ret;
}

static struct feature_ops port_uint_ops = {
	.init = port_uint_init,
	.uinit = port_uint_uinit,
	.ioctl = port_uint_ioctl,
};

static int port_stp_init(struct platform_device *pdev, struct feature *feature)
{
	struct resource *res = &pdev->resource[feature->resource_index];
	u32 flags = FPGA_REGION_READ | FPGA_REGION_WRITE | FPGA_REGION_MMAP;

	dev_dbg(&pdev->dev, "PORT STP Init.\n");

	return afu_region_add(dev_get_platdata(&pdev->dev),
			      FPGA_PORT_INDEX_STP, resource_size(res),
			      res->start, flags);
}

static void port_stp_uinit(struct platform_device *pdev,
			   struct feature *feature)
{
	dev_dbg(&pdev->dev, "PORT STP UInit.\n");
}

static struct feature_ops port_stp_ops = {
	.init = port_stp_init,
	.uinit = port_stp_uinit,
	.test = port_stp_test,
};

static int port_iopll_init(struct platform_device *pdev,
			   struct feature *feature)
{
	struct pac_iopll_plat_data iopll_data;
	struct platform_device *subdev;

	dev_dbg(&pdev->dev, "PORT IOPLL Init.\n");

	memset(&iopll_data, 0, sizeof(iopll_data));
	iopll_data.csr_base = feature->ioaddr + sizeof(struct feature_header);

	subdev = feature_create_subdev(pdev, PAC_IOPLL_DRV_NAME, &iopll_data,
				       sizeof(iopll_data));
	if (IS_ERR(subdev))
		return PTR_ERR(subdev);

	feature_set_priv(feature, subdev);
	return 0;
}

static void port_iopll_uinit(struct platform_device *pdev,
			     struct feature *feature)
{
	struct platform_device *subdev = feature_get_priv(feature);

	dev_dbg(&pdev->dev, "PORT IOPLL UInit.\n");

	feature_destroy_subdev(subdev);
	feature_set_priv(feature, NULL);
}

static struct feature_ops port_iopll_ops = {
	.init = port_iopll_init,
	.uinit = port_iopll_uinit,
};

static struct feature_driver port_feature_drvs[] = {
	{FEATURE_DRV(PORT_FEATURE_HEADER, &port_hdr_ops),},
	{FEATURE_DRV(PORT_FEATURE_UAFU, &port_afu_ops),},
	{FEATURE_DRV(PORT_FEATURE_ERR, &port_err_ops),},
	{FEATURE_DRV(PORT_FEATURE_UMSG, &port_umsg_ops),},
	{FEATURE_DRV(PORT_FEATURE_UINT, &port_uint_ops),},
	{FEATURE_DRV(PORT_FEATURE_STP, &port_stp_ops),},
	{FEATURE_DRV(PORT_FEATURE_IOPLL, &port_iopll_ops),},
	{0, 0,}
};

static int afu_open(struct inode *inode, struct file *filp)
{
	struct platform_device *fdev = fpga_inode_to_feature_dev(inode);
	struct feature_platform_data *pdata;
	struct pid_info *pid_info, *ptmp;
	struct pid *pid;
	int ret;

	pdata = dev_get_platdata(&fdev->dev);
	if (WARN_ON(!pdata))
		return -ENODEV;

	if (filp->f_flags & O_EXCL)
		ret = feature_dev_use_excl_begin(pdata);
	else
		ret = feature_dev_use_begin(pdata);

	if (ret)
		return ret;

	mutex_lock(&pdata->lock);
	pid = get_pid(task_pid(current));
	list_for_each_entry(ptmp, &pdata->pid_list, node) {
		if (ptmp->pid == pid) {
			ptmp->count++;
			goto unlock;
		}
	}
	pid_info = devm_kzalloc(&fdev->dev, sizeof(*pid_info),
				GFP_KERNEL);
	if (!pid_info) {
		put_pid(pid);
		__feature_dev_use_end(pdata);
		mutex_unlock(&pdata->lock);
		return -ENOMEM;
	}
	pid_info->pid = pid;
	pid_info->count = 1;
	list_add(&pid_info->node, &pdata->pid_list);

unlock:
	mutex_unlock(&pdata->lock);
	dev_dbg(&fdev->dev, "Device File Opened %d Times\n", pdata->open_count);
	filp->private_data = fdev;

	return 0;
}

static int afu_release(struct inode *inode, struct file *filp)
{
	struct platform_device *pdev = filp->private_data;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct pid_info *pid_info, *ptmp;
	struct pid *pid;

	dev_dbg(&pdev->dev, "Device File Release\n");
	mutex_lock(&pdata->lock);
	__feature_dev_use_end(pdata);

	pid = get_pid(task_pid(current));

	list_for_each_entry_safe(pid_info, ptmp, &pdata->pid_list, node)
		if (pid_info->pid == pid) {
			put_pid(pid_info->pid);
			pid_info->count--;
			if (!pid_info->count) {
				list_del(&pid_info->node);
				devm_kfree(&pdev->dev, pid_info);
			}
		}

	put_pid(pid);

	if (!pdata->open_count) {
		fpga_msix_set_block(&pdata->features[PORT_FEATURE_ID_ERROR], 0,
			pdata->features[PORT_FEATURE_ID_ERROR].ctx_num, NULL);
		fpga_msix_set_block(&pdata->features[PORT_FEATURE_ID_UINT], 0,
			pdata->features[PORT_FEATURE_ID_UINT].ctx_num, NULL);
		afu_port_umsg_halt(&pdata->dev->dev);
		__fpga_port_reset(pdev);
		afu_dma_region_destroy(pdata);
	}
	mutex_unlock(&pdata->lock);
	return 0;
}

static long afu_ioctl_check_extension(struct feature_platform_data *pdata,
				     unsigned long arg)
{
	/* No extension support for now */
	return 0;
}

static long
afu_ioctl_get_info(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_port_info info;
	struct fpga_afu *afu;
	unsigned long minsz;

	minsz = offsetofend(struct fpga_port_info, num_uafu_irqs);

	if (copy_from_user(&info, arg, minsz))
		return -EFAULT;

	if (info.argsz < minsz)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	info.flags = 0;
	info.capability = afu->capability;
	info.num_regions = afu->num_regions;
	info.num_umsgs = afu->num_umsgs;
	info.num_uafu_irqs = afu->num_uafu_irqs;
	mutex_unlock(&pdata->lock);

	if (copy_to_user(arg, &info, sizeof(info)))
		return -EFAULT;

	return 0;
}

static long
afu_ioctl_get_region_info(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_port_region_info rinfo;
	struct fpga_afu_region region;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct fpga_port_region_info, offset);

	if (copy_from_user(&rinfo, arg, minsz))
		return -EFAULT;

	if (rinfo.argsz < minsz || rinfo.padding)
		return -EINVAL;

	ret = afu_get_region_by_index(pdata, rinfo.index, &region);
	if (ret)
		return ret;

	rinfo.flags = region.flags;
	rinfo.size = region.size;
	rinfo.offset = region.offset;

	if (copy_to_user(arg, &rinfo, sizeof(rinfo)))
		return -EFAULT;

	return 0;
}

static long
afu_ioctl_dma_map(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_port_dma_map map;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct fpga_port_dma_map, iova);

	if (copy_from_user(&map, arg, minsz))
		return -EFAULT;

	if (map.argsz < minsz || map.flags)
		return -EINVAL;

	ret = afu_dma_map_region(pdata, map.user_addr, map.length, &map.iova);
	if (ret)
		return ret;

	if (copy_to_user(arg, &map, sizeof(map))) {
		afu_dma_unmap_region(pdata, map.iova);
		return -EFAULT;
	}

	dev_dbg(&pdata->dev->dev, "dma map: ua=%llx, len=%llx, iova=%llx\n",
				(unsigned long long)map.user_addr,
				(unsigned long long)map.length,
				(unsigned long long)map.iova);

	return 0;
}

static long
afu_ioctl_dma_unmap(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_port_dma_unmap unmap;
	unsigned long minsz;

	minsz = offsetofend(struct fpga_port_dma_unmap, iova);

	if (copy_from_user(&unmap, arg, minsz))
		return -EFAULT;

	if (unmap.argsz < minsz || unmap.flags)
		return -EINVAL;

	return afu_dma_unmap_region(pdata, unmap.iova);
}

static long afu_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	struct platform_device *pdev = filp->private_data;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct feature *f;
	long ret;

	dev_dbg(&pdev->dev, "%s cmd 0x%x\n", __func__, cmd);

	switch (cmd) {
	case FPGA_GET_API_VERSION:
		return FPGA_API_VERSION;
	case FPGA_CHECK_EXTENSION:
		return afu_ioctl_check_extension(pdata, arg);
	case FPGA_PORT_GET_INFO:
		return afu_ioctl_get_info(pdata, (void __user *)arg);
	case FPGA_PORT_GET_REGION_INFO:
		return afu_ioctl_get_region_info(pdata, (void __user *)arg);
	case FPGA_PORT_DMA_MAP:
		return afu_ioctl_dma_map(pdata, (void __user *)arg);
	case FPGA_PORT_DMA_UNMAP:
		return afu_ioctl_dma_unmap(pdata, (void __user *)arg);
	default:
		/*
		 * Let sub-feature's ioctl function to handle the cmd
		 * Sub-feature's ioctl returns -ENODEV when cmd is not
		 * handled in this sub feature, and returns 0 and other
		 * error code if cmd is handled.
		 */
		fpga_dev_for_each_feature(pdata, f)
			if (f->ops && f->ops->ioctl) {
				ret = f->ops->ioctl(pdev, f, cmd, arg);
				if (ret == -ENODEV)
					continue;
				else
					return ret;
			}
	}

	return -EINVAL;
}

static int afu_mmap(struct file *filp, struct vm_area_struct *vma)
{
	struct fpga_afu_region region;
	struct platform_device *pdev = filp->private_data;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	u64 size = vma->vm_end - vma->vm_start;
	u64 offset;
	int ret;

	if (!(vma->vm_flags & VM_SHARED) && (vma->vm_flags & VM_WRITE))
		return -EINVAL;

	offset = vma->vm_pgoff << PAGE_SHIFT;
	ret = afu_get_region_by_offset(pdata, offset, size, &region);
	if (ret)
		return ret;

	if (!(region.flags & FPGA_REGION_MMAP))
		return -EINVAL;

	if ((vma->vm_flags & VM_READ) && !(region.flags & FPGA_REGION_READ))
		return -EPERM;

	if ((vma->vm_flags & VM_WRITE) && !(region.flags & FPGA_REGION_WRITE))
		return -EPERM;

	vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
	return remap_pfn_range(vma, vma->vm_start,
			(region.phys + (offset - region.offset)) >> PAGE_SHIFT,
			size, vma->vm_page_prot);
}

static const struct file_operations afu_fops = {
	.owner = THIS_MODULE,
	.open = afu_open,
	.release = afu_release,
	.unlocked_ioctl = afu_ioctl,
	.mmap = afu_mmap,
};

static int afu_dev_init(struct platform_device *pdev)
{
	struct fpga_afu *afu;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);

	afu = devm_kzalloc(&pdev->dev, sizeof(*afu), GFP_KERNEL);
	if (!afu)
		return -ENOMEM;

	afu->pdata = pdata;

	mutex_lock(&pdata->lock);
	fpga_pdata_set_private(pdata, afu);
	afu_region_init(pdata);
	afu_dma_region_init(pdata);
	mutex_unlock(&pdata->lock);
	return 0;
}

static int afu_dev_destroy(struct platform_device *pdev)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_afu *afu;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	afu_region_destroy(pdata);
	afu_dma_region_destroy(pdata);
	fpga_pdata_set_private(pdata, NULL);
	mutex_unlock(&pdata->lock);

	devm_kfree(&pdev->dev, afu);
	return 0;
}

static int afu_probe(struct platform_device *pdev)
{
	int ret;

	dev_dbg(&pdev->dev, "%s\n", __func__);

	ret = afu_dev_init(pdev);
	if (ret)
		goto exit;

	ret = fpga_dev_feature_init(pdev, port_feature_drvs);
	if (ret)
		goto dev_destroy;

	ret = fpga_register_dev_ops(pdev, &afu_fops, THIS_MODULE);
	if (ret) {
		fpga_dev_feature_uinit(pdev);
		goto dev_destroy;
	}

	return 0;

dev_destroy:
	afu_dev_destroy(pdev);
exit:
	return ret;
}

static int afu_remove(struct platform_device *pdev)
{
	dev_dbg(&pdev->dev, "%s\n", __func__);

	fpga_dev_feature_uinit(pdev);
	fpga_unregister_dev_ops(pdev);
	afu_dev_destroy(pdev);
	return 0;
}

static struct platform_driver afu_driver = {
	.driver	= {
		.name    = "intel-fpga-port",
	},
	.probe   = afu_probe,
	.remove  = afu_remove,
};

module_platform_driver(afu_driver);

MODULE_DESCRIPTION("FPGA Accelerated Function Unit driver");
MODULE_AUTHOR("Intel Corporation");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:intel-fpga-port");
