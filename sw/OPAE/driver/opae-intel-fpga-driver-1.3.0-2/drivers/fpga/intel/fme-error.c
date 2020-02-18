/*
 * Driver for FPGA Management Engine Error Management
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Kang Luwei <luwei.kang@intel.com>
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
#include <linux/stddef.h>
#include <linux/errno.h>
#include <linux/uaccess.h>
#include <linux/fpga/fpga-mgr_mod.h>

#include "feature-dev.h"
#include "fme.h"

static ssize_t errors_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_error0 fme_error0;

	fme_error0.csr = readq(&fme_err->fme_err);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", fme_error0.csr);
}

static DEVICE_ATTR_RO(errors);

static ssize_t first_error_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_first_error fme_first_err;

	fme_first_err.csr = readq(&fme_err->fme_first_err);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n",
			(unsigned long long)fme_first_err.err_reg_status);
}

static DEVICE_ATTR_RO(first_error);

static ssize_t next_error_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_next_error fme_next_err;

	fme_next_err.csr = readq(&fme_err->fme_next_err);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n",
			(unsigned long long)fme_next_err.err_reg_status);
}

static DEVICE_ATTR_RO(next_error);

static ssize_t clear_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev->parent);
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_error0 fme_error0;
	struct feature_fme_first_error fme_first_err;
	struct feature_fme_next_error fme_next_err;
	u64 val;

	if (kstrtou64(buf, 0, &val))
		return -EINVAL;

	mutex_lock(&pdata->lock);
	writeq(FME_ERROR0_MASK, &fme_err->fme_err_mask);

	fme_error0.csr = readq(&fme_err->fme_err);
	if (val != fme_error0.csr) {
		count = -EBUSY;
		goto exit;
	}

	fme_first_err.csr = readq(&fme_err->fme_first_err);
	fme_next_err.csr = readq(&fme_err->fme_next_err);

	writeq(fme_error0.csr & FME_ERROR0_MASK, &fme_err->fme_err);
	writeq(fme_first_err.csr & FME_FIRST_ERROR_MASK,
		&fme_err->fme_first_err);
	writeq(fme_next_err.csr & FME_NEXT_ERROR_MASK,
		&fme_err->fme_next_err);

exit:
	writeq(FME_ERROR0_MASK_DEFAULT, &fme_err->fme_err_mask);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR_WO(clear);

static ssize_t revision_show(struct device *dev, struct device_attribute *attr,
			     char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_header header;

	header.csr = readq(&fme_err->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static DEVICE_ATTR_RO(revision);

static ssize_t pcie0_errors_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_pcie0_error pcie0_err;

	pcie0_err.csr = readq(&fme_err->pcie0_err);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", pcie0_err.csr);
}

static ssize_t pcie0_errors_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev->parent);
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_pcie0_error pcie0_err;
	u64 val;

	if (kstrtou64(buf, 0, &val))
		return -EINVAL;

	mutex_lock(&pdata->lock);
	writeq(FME_PCIE0_ERROR_MASK, &fme_err->pcie0_err_mask);

	pcie0_err.csr = readq(&fme_err->pcie0_err);
	if (val != pcie0_err.csr)
		count = -EBUSY;
	else
		writeq(pcie0_err.csr & FME_PCIE0_ERROR_MASK,
				&fme_err->pcie0_err);

	writeq(0UL, &fme_err->pcie0_err_mask);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR_RW(pcie0_errors);

static ssize_t pcie1_errors_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_pcie1_error pcie1_err;

	pcie1_err.csr = readq(&fme_err->pcie1_err);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", pcie1_err.csr);
}

static ssize_t pcie1_errors_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev->parent);
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_pcie1_error pcie1_err;
	u64 val;

	if (kstrtou64(buf, 0, &val))
		return -EINVAL;

	mutex_lock(&pdata->lock);
	writeq(FME_PCIE1_ERROR_MASK, &fme_err->pcie1_err_mask);

	pcie1_err.csr = readq(&fme_err->pcie1_err);
	if (val != pcie1_err.csr)
		count = -EBUSY;
	else
		writeq(pcie1_err.csr & FME_PCIE1_ERROR_MASK,
				&fme_err->pcie1_err);

	writeq(0UL, &fme_err->pcie1_err_mask);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR_RW(pcie1_errors);

static ssize_t nonfatal_errors_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_ras_nonfaterror ras_nonfaterr;

	ras_nonfaterr.csr = readq(&fme_err->ras_nonfaterr);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", ras_nonfaterr.csr);
}

static DEVICE_ATTR_RO(nonfatal_errors);

static ssize_t catfatal_errors_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_ras_catfaterror ras_catfaterr;

	ras_catfaterr.csr = readq(&fme_err->ras_catfaterr);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", ras_catfaterr.csr);
}

static DEVICE_ATTR_RO(catfatal_errors);

static ssize_t inject_error_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_ras_error_inj ras_error_inj;

	ras_error_inj.csr = readq(&fme_err->ras_error_inj);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n",
			ras_error_inj.csr & FME_RAS_ERROR_INJ_MASK);
}

static ssize_t inject_error_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev->parent);
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(dev->parent,
				FME_FEATURE_ID_GLOBAL_ERR);
	struct feature_fme_ras_error_inj ras_error_inj;
	int err;
	u8 data;

	mutex_lock(&pdata->lock);
	ras_error_inj.csr = readq(&fme_err->ras_error_inj);

	err = kstrtou8(buf, 0, &data);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	if (data <= FME_RAS_ERROR_INJ_MASK)
		ras_error_inj.csr = data;
	else {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	}

	writeq(ras_error_inj.csr, &fme_err->ras_error_inj);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR_RW(inject_error);

static struct attribute *fme_errors_attrs[] = {
	&dev_attr_errors.attr,
	&dev_attr_first_error.attr,
	&dev_attr_next_error.attr,
	&dev_attr_clear.attr,
	NULL,
};

struct attribute_group fme_errors_attr_group = {
	.attrs	= fme_errors_attrs,
	.name	= "fme-errors",
};

static struct attribute *errors_attrs[] = {
	&dev_attr_revision.attr,
	&dev_attr_pcie0_errors.attr,
	&dev_attr_pcie1_errors.attr,
	&dev_attr_nonfatal_errors.attr,
	&dev_attr_catfatal_errors.attr,
	&dev_attr_inject_error.attr,
	NULL,
};

struct attribute_group errors_attr_group = {
	.attrs	= errors_attrs,
};

static const struct attribute_group *error_groups[] = {
	&fme_errors_attr_group,
	&errors_attr_group,
	NULL
};

static void fme_error_enable(struct platform_device *pdev)
{
	struct feature_fme_err *fme_err
		= get_feature_ioaddr_by_index(&pdev->dev,
			FME_FEATURE_ID_GLOBAL_ERR);

	writeq(FME_ERROR0_MASK_DEFAULT, &fme_err->fme_err_mask);
	writeq(0UL, &fme_err->pcie0_err_mask);
	writeq(0UL, &fme_err->pcie1_err_mask);
	writeq(0UL, &fme_err->ras_nonfat_mask);
	writeq(0UL, &fme_err->ras_catfat_mask);
}

static int global_error_init(struct platform_device *pdev,
		struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;
	struct device *dev;
	int ret = 0;

	dev = kzalloc(sizeof(struct device), GFP_KERNEL);
	if (!dev)
		return -ENOMEM;

	dev->parent = &pdev->dev;
	dev->release = (void (*)(struct device *))kfree;
	dev_set_name(dev, "errors");

	fme_error_enable(pdev);

	ret = device_register(dev);
	if (ret) {
		put_device(dev);
		return ret;
	}

	ret = sysfs_create_groups(&dev->kobj, error_groups);
	if (ret) {
		device_unregister(dev);
		return ret;
	}

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	fme->dev_err = dev;
	if (feature->ctx_num)
		fme->capability |= FPGA_FME_CAP_ERR_IRQ;
	mutex_unlock(&pdata->lock);

	return ret;
}

static void global_error_uinit(struct platform_device *pdev,
		struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	sysfs_remove_groups(&fme->dev_err->kobj, error_groups);
	device_unregister(fme->dev_err);
	fme->dev_err = NULL;
	mutex_unlock(&pdata->lock);
}

static long fme_err_set_irq(struct platform_device *pdev,
			struct feature *feature, unsigned long arg)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme_err_irq_set hdr;
	struct fpga_fme *fme;
	unsigned long minsz;
	long ret = 0;

	minsz = offsetofend(struct fpga_fme_err_irq_set, evtfd);

	if (copy_from_user(&hdr, (void __user *)arg, minsz))
		return -EFAULT;

	if (hdr.argsz < minsz || hdr.flags)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	if (!(fme->capability & FPGA_FME_CAP_ERR_IRQ)) {
		mutex_unlock(&pdata->lock);
		return -ENODEV;
	}
	ret = fpga_msix_set_block(feature, 0, 1, &hdr.evtfd);
	mutex_unlock(&pdata->lock);

	return ret;
}

static long
global_error_ioctl(struct platform_device *pdev, struct feature *feature,
		   unsigned int cmd, unsigned long arg)
{
	long ret;

	switch (cmd) {
	case FPGA_FME_ERR_SET_IRQ:
		ret = fme_err_set_irq(pdev, feature, arg);
		break;
	default:
		dev_dbg(&pdev->dev, "%x cmd not handled", cmd);
		ret = -ENODEV;
	}

	return ret;
}

struct feature_ops global_error_ops = {
	.init = global_error_init,
	.uinit = global_error_uinit,
	.ioctl = global_error_ioctl,
};
