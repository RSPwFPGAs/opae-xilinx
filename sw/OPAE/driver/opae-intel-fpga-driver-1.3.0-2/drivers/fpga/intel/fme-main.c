/*
 * Driver for FPGA Management Engine which implements all FPGA platform
 * level management features.
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

#include <linux/avmmi-bmc.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/stddef.h>
#include <linux/errno.h>
#include <linux/delay.h>
#include <linux/uaccess.h>
#include <linux/intel-fpga-mod.h>

#include "backport.h"
#include <linux/fpga/fpga-mgr_mod.h>
#include <linux/mtd/altera-asmip2.h>

#include "pac-hssi.h"
#include "feature-dev.h"
#include "fme.h"

#define PWR_THRESHOLD_MAX       0x7F

#define FME_DEV_ATTR(_name, _filename, _mode, _show, _store)	\
struct device_attribute dev_attr_##_name =			\
	__ATTR(_filename, _mode, _show, _store)

static ssize_t revision_show(struct device *dev, struct device_attribute *attr,
			     char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_header header;

	header.csr = readq(&fme_hdr->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static DEVICE_ATTR_RO(revision);

static ssize_t ports_num_show(struct device *dev, struct device_attribute *attr,
			char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_capability fme_capability;

	fme_capability.csr = readq(&fme_hdr->capability);

	return scnprintf(buf, PAGE_SIZE, "%d\n", fme_capability.num_ports);
}

static DEVICE_ATTR_RO(ports_num);

static ssize_t cache_size_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_capability fme_capability;

	fme_capability.csr = readq(&fme_hdr->capability);

	return scnprintf(buf, PAGE_SIZE, "%d\n", fme_capability.cache_size);
}

static DEVICE_ATTR_RO(cache_size);

static ssize_t version_show(struct device *dev, struct device_attribute *attr,
			char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_capability fme_capability;

	fme_capability.csr = readq(&fme_hdr->capability);

	return scnprintf(buf, PAGE_SIZE, "%d\n", fme_capability.fabric_verid);
}

static DEVICE_ATTR_RO(version);

static ssize_t socket_id_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_capability fme_capability;

	fme_capability.csr = readq(&fme_hdr->capability);

	return scnprintf(buf, PAGE_SIZE, "%d\n", fme_capability.socket_id);
}

static DEVICE_ATTR_RO(socket_id);

static ssize_t bitstream_id_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	u64 bitstream_id = readq(&fme_hdr->bitstream_id);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", bitstream_id);
}

static DEVICE_ATTR_RO(bitstream_id);

static ssize_t bitstream_metadata_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	u64 bitstream_md = readq(&fme_hdr->bitstream_md);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", bitstream_md);
}

static DEVICE_ATTR_RO(bitstream_metadata);

static const struct attribute *fme_hdr_attrs[] = {
	&dev_attr_revision.attr,
	&dev_attr_ports_num.attr,
	&dev_attr_cache_size.attr,
	&dev_attr_version.attr,
	&dev_attr_socket_id.attr,
	&dev_attr_bitstream_id.attr,
	&dev_attr_bitstream_metadata.attr,
	NULL,
};

static int fme_hdr_init(struct platform_device *pdev, struct feature *feature)
{
	int ret;
	struct feature_fme_header *fme_hdr = feature->ioaddr;

	dev_dbg(&pdev->dev, "FME HDR Init.\n");
	dev_dbg(&pdev->dev, "FME cap %llx.\n", fme_hdr->capability.csr);

	ret = sysfs_create_files(&pdev->dev.kobj, fme_hdr_attrs);
	if (ret)
		return ret;

	return 0;
}

static void fme_hdr_uinit(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME HDR UInit.\n");
	sysfs_remove_files(&pdev->dev.kobj, fme_hdr_attrs);
}

static struct feature_ops fme_hdr_ops = {
	.init = fme_hdr_init,
	.uinit = fme_hdr_uinit,
};

static ssize_t thermal_revision_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_header header;

	header.csr = readq(&fme_thermal->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static FME_DEV_ATTR(thermal_revision, revision, 0444,
		    thermal_revision_show, NULL);

static ssize_t thermal_threshold1_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n", tmp_threshold.tmp_thshold1);
}

static ssize_t thermal_threshold1_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_tmp_threshold tmp_threshold;
	struct feature_fme_capability fme_capability;
	int err;
	u8 tmp_threshold1;

	mutex_lock(&pdata->lock);
	tmp_threshold.csr = readq(&fme_thermal->threshold);

	err = kstrtou8(buf, 0, &tmp_threshold1);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	fme_capability.csr = readq(&fme_hdr->capability);

	if (fme_capability.lock_bit == 1) {
		mutex_unlock(&pdata->lock);
		return -EBUSY;
	} else if (tmp_threshold1 > 100) {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	} else if (tmp_threshold1 == 0) {
		tmp_threshold.tmp_thshold1_enable = 0;
		tmp_threshold.tmp_thshold1 = tmp_threshold1;
	} else {
		tmp_threshold.tmp_thshold1_enable = 1;
		tmp_threshold.tmp_thshold1 = tmp_threshold1;
	}

	writeq(tmp_threshold.csr, &fme_thermal->threshold);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR(threshold1, 0644,
	thermal_threshold1_show, thermal_threshold1_store);

static ssize_t thermal_threshold2_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n", tmp_threshold.tmp_thshold2);
}

static ssize_t thermal_threshold2_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_header *fme_hdr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_HEADER);
	struct feature_fme_tmp_threshold tmp_threshold;
	struct feature_fme_capability fme_capability;
	int err;
	u8 tmp_threshold2;

	mutex_lock(&pdata->lock);
	tmp_threshold.csr = readq(&fme_thermal->threshold);

	err = kstrtou8(buf, 0, &tmp_threshold2);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	fme_capability.csr = readq(&fme_hdr->capability);

	if (fme_capability.lock_bit == 1) {
		mutex_unlock(&pdata->lock);
		return -EBUSY;
	} else if (tmp_threshold2 > 100) {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	} else if (tmp_threshold2 == 0) {
		tmp_threshold.tmp_thshold2_enable = 0;
		tmp_threshold.tmp_thshold2 = tmp_threshold2;
	} else {
		tmp_threshold.tmp_thshold2_enable = 1;
		tmp_threshold.tmp_thshold2 = tmp_threshold2;
	}

	writeq(tmp_threshold.csr, &fme_thermal->threshold);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR(threshold2, 0644,
	thermal_threshold2_show, thermal_threshold2_store);

static ssize_t thermal_threshold_trip_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n",
				tmp_threshold.therm_trip_thshold);
}

static DEVICE_ATTR(threshold_trip, 0444, thermal_threshold_trip_show, NULL);

static ssize_t thermal_threshold1_reached_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n",
				tmp_threshold.thshold1_status);
}

static DEVICE_ATTR(threshold1_reached, 0444,
	thermal_threshold1_reached_show, NULL);

static ssize_t thermal_threshold2_reached_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n",
				tmp_threshold.thshold2_status);
}

static DEVICE_ATTR(threshold2_reached, 0444,
	thermal_threshold2_reached_show, NULL);

static ssize_t thermal_threshold1_policy_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;

	tmp_threshold.csr = readq(&fme_thermal->threshold);

	return scnprintf(buf, PAGE_SIZE, "%d\n",
				tmp_threshold.thshold_policy);
}

static ssize_t thermal_threshold1_policy_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_tmp_threshold tmp_threshold;
	int err;
	u8 thshold_policy;

	mutex_lock(&pdata->lock);
	tmp_threshold.csr = readq(&fme_thermal->threshold);

	err = kstrtou8(buf, 0, &thshold_policy);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	if (thshold_policy == 0)
		tmp_threshold.thshold_policy = 0;
	else if (thshold_policy == 1)
		tmp_threshold.thshold_policy = 1;
	else {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	}

	writeq(tmp_threshold.csr, &fme_thermal->threshold);
	mutex_unlock(&pdata->lock);

	return count;
}

static DEVICE_ATTR(threshold1_policy, 0644,
	thermal_threshold1_policy_show, thermal_threshold1_policy_store);

static ssize_t thermal_temperature_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_thermal *fme_thermal
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_THERMAL_MGMT);
	struct feature_fme_temp_rdsensor_fmt1 temp_rdsensor_fmt1;

	temp_rdsensor_fmt1.csr = readq(&fme_thermal->rdsensor_fm1);

	return scnprintf(buf, PAGE_SIZE, "%d\n",
				temp_rdsensor_fmt1.fpga_temp);
}

static DEVICE_ATTR(temperature, 0444, thermal_temperature_show, NULL);

static struct attribute *thermal_mgmt_attrs[] = {
	&dev_attr_thermal_revision.attr,
	&dev_attr_temperature.attr,
	NULL,
};

static struct attribute_group thermal_mgmt_attr_group = {
	.name   = "thermal_mgmt",
	.attrs	= thermal_mgmt_attrs,
};

static struct attribute *thermal_threshold_attrs[] = {
	&dev_attr_threshold1.attr,
	&dev_attr_threshold2.attr,
	&dev_attr_threshold_trip.attr,
	&dev_attr_threshold1_reached.attr,
	&dev_attr_threshold2_reached.attr,
	&dev_attr_threshold1_policy.attr,
	NULL,
};

static struct attribute_group thermal_threshold_attr_group = {
	.name   = "thermal_mgmt",
	.attrs	= thermal_threshold_attrs,
};

static int thermal_mgmt_init(struct platform_device *pdev,
			     struct feature *feature)
{
	struct feature_fme_thermal *fme_thermal;
	struct feature_fme_tmp_threshold_cap thermal_cap;
	int ret;

	fme_thermal = get_feature_ioaddr_by_index(&pdev->dev,
						  FME_FEATURE_ID_THERMAL_MGMT);
	thermal_cap.csr = readq(&fme_thermal->threshold_cap);

	ret = sysfs_create_group(&pdev->dev.kobj, &thermal_mgmt_attr_group);
	if (ret)
		return ret;

	if (thermal_cap.tmp_thshold_disabled)
		return 0;

	ret = sysfs_merge_group(&pdev->dev.kobj, &thermal_threshold_attr_group);
	if (ret) {
		sysfs_remove_group(&pdev->dev.kobj, &thermal_mgmt_attr_group);
		return ret;
	}

	return 0;
}

static void thermal_mgmt_uinit(struct platform_device *pdev,
				struct feature *feature)
{
	sysfs_unmerge_group(&pdev->dev.kobj, &thermal_threshold_attr_group);
	sysfs_remove_group(&pdev->dev.kobj, &thermal_mgmt_attr_group);
}

static struct feature_ops thermal_mgmt_ops = {
	.init = thermal_mgmt_init,
	.uinit = thermal_mgmt_uinit,
};

static ssize_t pwr_revision_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_header header;

	header.csr = readq(&fme_power->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static FME_DEV_ATTR(pwr_revision, revision, 0444, pwr_revision_show, NULL);

static ssize_t consumed_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_status pm_status;

	pm_status.csr = readq(&fme_power->status);

	return scnprintf(buf, PAGE_SIZE, "0x%x\n", pm_status.pwr_consumed);
}

static DEVICE_ATTR_RO(consumed);

static ssize_t pwr_threshold1_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;

	pm_ap_threshold.csr = readq(&fme_power->threshold);

	return scnprintf(buf, PAGE_SIZE, "0x%x\n", pm_ap_threshold.threshold1);
}

static ssize_t pwr_threshold1_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;
	u8 threshold;
	int err;

	mutex_lock(&pdata->lock);
	pm_ap_threshold.csr = readq(&fme_power->threshold);

	err = kstrtou8(buf, 0, &threshold);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	if (threshold <= PWR_THRESHOLD_MAX)
		pm_ap_threshold.threshold1 = threshold;
	else {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	}

	writeq(pm_ap_threshold.csr, &fme_power->threshold);
	mutex_unlock(&pdata->lock);

	return count;
}

static FME_DEV_ATTR(pwr_threshold1, threshold1, 0644, pwr_threshold1_show,
		    pwr_threshold1_store);

static ssize_t pwr_threshold2_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;

	pm_ap_threshold.csr = readq(&fme_power->threshold);

	return scnprintf(buf, PAGE_SIZE, "0x%x\n",
				pm_ap_threshold.threshold2);
}

static ssize_t pwr_threshold2_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;
	u8 threshold;
	int err;

	mutex_lock(&pdata->lock);
	pm_ap_threshold.csr = readq(&fme_power->threshold);

	err = kstrtou8(buf, 0, &threshold);
	if (err) {
		mutex_unlock(&pdata->lock);
		return err;
	}

	if (threshold <= PWR_THRESHOLD_MAX)
		pm_ap_threshold.threshold2 = threshold;
	else {
		mutex_unlock(&pdata->lock);
		return -EINVAL;
	}

	writeq(pm_ap_threshold.csr, &fme_power->threshold);
	mutex_unlock(&pdata->lock);

	return count;
}

static FME_DEV_ATTR(pwr_threshold2, threshold2, 0644, pwr_threshold2_show,
		    pwr_threshold2_store);

static ssize_t threshold1_status_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;

	pm_ap_threshold.csr = readq(&fme_power->threshold);

	return scnprintf(buf, PAGE_SIZE, "%u\n",
				pm_ap_threshold.threshold1_status);
}

static DEVICE_ATTR_RO(threshold1_status);

static ssize_t threshold2_status_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_ap_threshold pm_ap_threshold;

	pm_ap_threshold.csr = readq(&fme_power->threshold);

	return scnprintf(buf, PAGE_SIZE, "%u\n",
				pm_ap_threshold.threshold2_status);
}
static DEVICE_ATTR_RO(threshold2_status);

static ssize_t rtl_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_status pm_status;

	pm_status.csr = readq(&fme_power->status);

	return scnprintf(buf, PAGE_SIZE, "%u\n",
				pm_status.fpga_latency_report);
}

static DEVICE_ATTR_RO(rtl);

static ssize_t xeon_limit_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_xeon_limit xeon_limit;

	xeon_limit.csr = readq(&fme_power->xeon_limit);

	if (!xeon_limit.enable)
		xeon_limit.pwr_limit = 0;

	return scnprintf(buf, PAGE_SIZE, "%u\n", xeon_limit.pwr_limit);
}
static DEVICE_ATTR_RO(xeon_limit);

static ssize_t fpga_limit_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_power *fme_power
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_POWER_MGMT);
	struct feature_fme_pm_fpga_limit fpga_limit;

	fpga_limit.csr = readq(&fme_power->fpga_limit);

	if (!fpga_limit.enable)
		fpga_limit.pwr_limit = 0;

	return scnprintf(buf, PAGE_SIZE, "%u\n", fpga_limit.pwr_limit);
}
static DEVICE_ATTR_RO(fpga_limit);

static struct attribute *power_mgmt_attrs[] = {
	&dev_attr_pwr_revision.attr,
	&dev_attr_consumed.attr,
	&dev_attr_pwr_threshold1.attr,
	&dev_attr_pwr_threshold2.attr,
	&dev_attr_threshold1_status.attr,
	&dev_attr_threshold2_status.attr,
	&dev_attr_xeon_limit.attr,
	&dev_attr_fpga_limit.attr,
	&dev_attr_rtl.attr,
	NULL,
};

static struct attribute_group power_mgmt_attr_group = {
	.attrs	= power_mgmt_attrs,
	.name	= "power_mgmt",
};

static int power_mgmt_init(struct platform_device *pdev,
				struct feature *feature)
{
	int ret;

	ret = sysfs_create_group(&pdev->dev.kobj, &power_mgmt_attr_group);
	if (ret)
		return ret;

	return 0;
}

static void power_mgmt_uinit(struct platform_device *pdev,
				struct feature *feature)
{
	sysfs_remove_group(&pdev->dev.kobj, &power_mgmt_attr_group);
}

static struct feature_ops power_mgmt_ops = {
	.init = power_mgmt_init,
	.uinit = power_mgmt_uinit,
};

static int hssi_mgmt_init(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME HSSI Init.\n");
	return 0;
}

static void hssi_mgmt_uinit(struct platform_device *pdev,
				struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME HSSI UInit.\n");
}

static struct feature_ops hssi_mgmt_ops = {
	.init = hssi_mgmt_init,
	.uinit = hssi_mgmt_uinit,
};

#define FLASH_CAP_OFT 8

static int qspi_flash_init(struct platform_device *pdev,
			   struct feature *feature)
{
	struct altera_asmip2_plat_data qdata;
	struct platform_device *subdev;

	dev_dbg(&pdev->dev, "FME QSPI FLASH Init\n");
	dev_dbg(&pdev->dev, "index %d flash cap 0x%llx\n",
		feature->resource_index,
		(unsigned long long)readq(feature->ioaddr + FLASH_CAP_OFT));

	memset(&qdata, 0, sizeof(qdata));
	qdata.csr_base = feature->ioaddr + FLASH_CAP_OFT;
	qdata.num_chip_sel = 1;

	subdev = feature_create_subdev(pdev, ALTERA_ASMIP2_DRV_NAME,
				       &qdata, sizeof(qdata));
	if (IS_ERR(subdev))
		return PTR_ERR(subdev);

	feature_set_priv(feature, subdev);
	return 0;
}

static void qspi_flash_uinit(struct platform_device *pdev,
			     struct feature *feature)
{
	struct platform_device *subdev = feature_get_priv(feature);

	dev_dbg(&pdev->dev, "FME QSPI FLASH UInit\n");

	feature_destroy_subdev(subdev);
	feature_set_priv(feature, NULL);
}

static struct feature_ops qspi_flash_ops = {
	.init = qspi_flash_init,
	.uinit = qspi_flash_uinit,
};

static ssize_t emif_active_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct feature_fme_emif *fme_emif
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_EMIF_MGMT);
	struct feature_fme_emif_status emif_status;

	emif_status.csr = readq(&fme_emif->status);

	return scnprintf(buf, PAGE_SIZE, "%d\n", emif_status.active);
}

static FME_DEV_ATTR(emif_active, active, 0444, emif_active_show, NULL);

static ssize_t emif_cal_fail_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct feature_fme_emif *fme_emif
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_EMIF_MGMT);
	struct feature_fme_emif_status emif_status;

	emif_status.csr = readq(&fme_emif->status);

	return scnprintf(buf, PAGE_SIZE, "%d\n", emif_status.cal_failure);
}

static FME_DEV_ATTR(emif_cal_fail, calibration_failure, 0444,
			emif_cal_fail_show, NULL);

static ssize_t emif_complete_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct feature_fme_emif *fme_emif
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_EMIF_MGMT);
	struct feature_fme_emif_status emif_status;

	emif_status.csr = readq(&fme_emif->status);

	return scnprintf(buf, PAGE_SIZE, "%d\n", emif_status.complete);
}

static FME_DEV_ATTR(emif_complete, complete, 0444, emif_complete_show, NULL);

static ssize_t emif_clear_store(struct device *dev,
	struct device_attribute *attr, const char *buf, size_t count)
{
	struct feature_fme_emif *fme_emif
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_EMIF_MGMT);
	struct feature_fme_emif_control emif_control = { { 0 } };
	u8 clear_bits;
	int err;

	err = kstrtou8(buf, 0, &clear_bits);
	if (err)
		return err;

	if (clear_bits & ~EMIF_CLEAR_MASK)
		return -EINVAL;

	emif_control.clear = clear_bits;
	writeq(emif_control.csr, &fme_emif->control);

	return count;
}

static FME_DEV_ATTR(emif_clear, clear, 0200, NULL, emif_clear_store);

static struct attribute *emif_attrs[] = {
	&dev_attr_emif_active.attr,
	&dev_attr_emif_cal_fail.attr,
	&dev_attr_emif_complete.attr,
	&dev_attr_emif_clear.attr,
	NULL,
};

static struct attribute_group emif_attr_group = {
	.name	= "emif_mgmt",
	.attrs	= emif_attrs,
};

static int emif_init(struct platform_device *pdev,
				struct feature *feature)
{
	return sysfs_create_group(&pdev->dev.kobj, &emif_attr_group);
}

static void emif_uinit(struct platform_device *pdev,
				struct feature *feature)
{
	sysfs_remove_group(&pdev->dev.kobj, &emif_attr_group);
}

static struct feature_ops emif_ops = {
	.init = emif_init,
	.uinit = emif_uinit,
};

static int pac_hssi_mgmt_init(struct platform_device *pdev,
			      struct feature *feature)
{
	struct pac_hssi_plat_data hdata;
	struct platform_device *subdev;

	dev_dbg(&pdev->dev, "FME PAC HSSI MGMT Init\n");

	memset(&hdata, 0, sizeof(hdata));
	hdata.csr_base = feature->ioaddr + sizeof(struct feature_header);

	subdev = feature_create_subdev(pdev, PAC_HSSI_DRV_NAME, &hdata,
				       sizeof(hdata));
	if (IS_ERR(subdev))
		return PTR_ERR(subdev);

	feature_set_priv(feature, subdev);
	return 0;
}

static void pac_hssi_mgmt_uinit(struct platform_device *pdev,
				struct feature *feature)
{
	struct platform_device *subdev = feature_get_priv(feature);

	dev_dbg(&pdev->dev, "FME PAC HSSI MGMT UInit\n");

	feature_destroy_subdev(subdev);
	feature_set_priv(feature, NULL);
}

static struct feature_ops pac_hssi_mgmt_ops = {
	.init = pac_hssi_mgmt_init,
	.uinit = pac_hssi_mgmt_uinit,
};

static int s10_sdm_init(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME S10 SDM Init\n");
	return 0;
}

static void s10_sdm_uinit(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME S10 SDM UInit\n");
}

static struct feature_ops s10_sdm_mgmt_ops = {
	.init = s10_sdm_init,
	.uinit = s10_sdm_uinit,
};

static int avmmi_bmc_init(struct platform_device *pdev,
			  struct feature *feature)
{
	struct avmmi_plat_data qdata;
	struct platform_device *subdev;

	dev_dbg(&pdev->dev, "FME AVMMI_BMC Init\n");

	memset(&qdata, 0, sizeof(qdata));

	qdata.csr_base = feature->ioaddr;

	subdev = feature_create_subdev(pdev, AVMMI_BMC_DRV_NAME,
				       &qdata, sizeof(qdata));
	if (IS_ERR(subdev))
		return PTR_ERR(subdev);

	feature_set_priv(feature, subdev);
	return 0;
}

static void avmmi_bmc_uinit(struct platform_device *pdev,
			    struct feature *feature)
{
	struct platform_device *subdev = feature_get_priv(feature);

	dev_dbg(&pdev->dev, "FME AVMMI_BMC UInit\n");

	feature_destroy_subdev(subdev);
	feature_set_priv(feature, NULL);
}

static struct feature_ops avmmi_bmc_ops = {
	.init = avmmi_bmc_init,
	.uinit = avmmi_bmc_uinit,
};

static int ehip_init(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME EHIP Init\n");

	return 0;
}

static void ehip_uinit(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME EHIP UInit\n");
}

static struct feature_ops ehip_ops = {
	.init = ehip_init,
	.uinit = ehip_uinit,
};

static int max10_spi_init(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME MAX10 SPI Init\n");

	return 0;
}

static void max10_spi_uinit(struct platform_device *pdev,
			    struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME MAX10 SPI UInit\n");
}

static struct feature_ops max10_spi_ops = {
	.init = max10_spi_init,
	.uinit = max10_spi_uinit,
};

static int mac_rom_i2c_init(struct platform_device *pdev,
			    struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME MAC ROM I2C Init\n");

	return 0;
}

static void mac_rom_i2c_uinit(struct platform_device *pdev,
			      struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME MAC ROM I2C UInit\n");
}

static struct feature_ops mac_rom_i2c_ops = {
	.init = mac_rom_i2c_init,
	.uinit = mac_rom_i2c_uinit,
};

static int phy_group_init(struct platform_device *pdev, struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME PHY GROUP Init\n");

	return 0;
}

static void phy_group_uinit(struct platform_device *pdev,
			    struct feature *feature)
{
	dev_dbg(&pdev->dev, "FME PHY GROUP UInit\n");
}

static struct feature_ops phy_group_ops = {
	.init = phy_group_init,
	.uinit = phy_group_uinit,
};

static struct feature_driver fme_feature_drvs[] = {
	{FEATURE_DRV(FME_FEATURE_HEADER, &fme_hdr_ops),},
	{FEATURE_DRV(FME_FEATURE_THERMAL_MGMT, &thermal_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_POWER_MGMT, &power_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_GLOBAL_ERR, &global_error_ops),},
	{FEATURE_DRV(FME_FEATURE_PR_MGMT, &pr_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_GLOBAL_IPERF, &global_iperf_ops),},
	{FEATURE_DRV(FME_FEATURE_HSSI_ETH, &hssi_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_GLOBAL_DPERF, &global_dperf_ops),},
	{FEATURE_DRV(FME_FEATURE_QSPI_FLASH, &qspi_flash_ops),},
	{FEATURE_DRV(FME_FEATURE_EMIF_MGMT, &emif_ops),},
	{FEATURE_DRV(FME_FEATURE_PAC_HSSI_ETH, &pac_hssi_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_S10_SDM_MB, &s10_sdm_mgmt_ops),},
	{FEATURE_DRV(FME_FEATURE_AVMMI_BMC, &avmmi_bmc_ops),},
	{FEATURE_DRV(FME_FEATURE_100G_EHIP, &ehip_ops),},
	{FEATURE_DRV(FME_FEATURE_MAX10_SPI, &max10_spi_ops),},
	{FEATURE_DRV(FME_FEATURE_MAC_ROM_I2C, &mac_rom_i2c_ops),},
	{FEATURE_DRV(FME_FEATURE_PHY_GROUP, &phy_group_ops),},
	{0, 0,}
};

static long fme_ioctl_check_extension(struct feature_platform_data *pdata,
				     unsigned long arg)
{
	/* No extension support for now */
	return 0;
}

static long
fme_ioctl_get_info(struct feature_platform_data *pdata, void __user *arg)
{
	struct fpga_fme_info info;
	struct fpga_fme *fme;
	unsigned long minsz;

	minsz = offsetofend(struct fpga_fme_info, capability);

	if (copy_from_user(&info, arg, minsz))
		return -EFAULT;

	if (info.argsz < minsz)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	info.flags = 0;
	info.capability = fme->capability;
	mutex_unlock(&pdata->lock);

	if (copy_to_user(arg, &info, sizeof(info)))
		return -EFAULT;

	return 0;
}

static int fme_ioctl_config_port(struct feature_platform_data *pdata,
				 u32 port_id, u32 flags, bool is_release)
{
	struct platform_device *fme_pdev = pdata->dev;
	struct feature_fme_header *fme_hdr;
	struct feature_fme_capability capability;

	if (flags)
		return -EINVAL;

	fme_hdr = get_feature_ioaddr_by_index(
		&fme_pdev->dev, FME_FEATURE_ID_HEADER);
	capability.csr = readq(&fme_hdr->capability);

	if (port_id >= capability.num_ports)
		return -EINVAL;

	return pdata->config_port(fme_pdev, port_id, is_release);
}

static long fme_ioctl_release_port(struct feature_platform_data *pdata,
				   void __user *arg)
{
	struct fpga_fme_port_release release;
	unsigned long minsz;

	minsz = offsetofend(struct fpga_fme_port_release, port_id);

	if (copy_from_user(&release, arg, minsz))
		return -EFAULT;

	if (release.argsz < minsz)
		return -EINVAL;

	return fme_ioctl_config_port(pdata, release.port_id,
				     release.flags, true);
}

static long fme_ioctl_assign_port(struct feature_platform_data *pdata,
				  void __user *arg)
{
	struct fpga_fme_port_assign assign;
	unsigned long minsz;

	minsz = offsetofend(struct fpga_fme_port_assign, port_id);

	if (copy_from_user(&assign, arg, minsz))
		return -EFAULT;

	if (assign.argsz < minsz)
		return -EINVAL;

	return fme_ioctl_config_port(pdata, assign.port_id,
				     assign.flags, false);
}

static int fme_open(struct inode *inode, struct file *filp)
{
	struct platform_device *fdev = fpga_inode_to_feature_dev(inode);
	struct feature_platform_data *pdata = dev_get_platdata(&fdev->dev);
	int ret;

	if (WARN_ON(!pdata))
		return -ENODEV;

	if (filp->f_flags & O_EXCL)
		ret = feature_dev_use_excl_begin(pdata);
	else
		ret = feature_dev_use_begin(pdata);

	if (ret)
		return ret;

	dev_dbg(&fdev->dev, "Device File Opened %d Times\n", pdata->open_count);
	filp->private_data = pdata;
	return 0;
}

static int fme_release(struct inode *inode, struct file *filp)
{
	struct feature_platform_data *pdata = filp->private_data;
	struct platform_device *pdev = pdata->dev;

	dev_dbg(&pdev->dev, "Device File Release\n");
	mutex_lock(&pdata->lock);
	__feature_dev_use_end(pdata);

	if (!pdata->open_count)
		fpga_msix_set_block(&pdata->features[FME_FEATURE_ID_GLOBAL_ERR],
			0, pdata->features[FME_FEATURE_ID_GLOBAL_ERR].ctx_num,
			NULL);
	mutex_unlock(&pdata->lock);

	return 0;
}

static long fme_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	struct feature_platform_data *pdata = filp->private_data;
	struct platform_device *pdev = pdata->dev;
	struct feature *f;
	long ret;

	dev_dbg(&pdev->dev, "%s cmd 0x%x\n", __func__, cmd);

	switch (cmd) {
	case FPGA_GET_API_VERSION:
		return FPGA_API_VERSION;
	case FPGA_CHECK_EXTENSION:
		return fme_ioctl_check_extension(pdata, arg);
	case FPGA_FME_GET_INFO:
		return fme_ioctl_get_info(pdata, (void __user *)arg);
	case FPGA_FME_PORT_RELEASE:
		return fme_ioctl_release_port(pdata, (void __user *)arg);
	case FPGA_FME_PORT_ASSIGN:
		return fme_ioctl_assign_port(pdata, (void __user *)arg);
	default:
		/*
		 * Let sub-feature's ioctl function to handle the cmd
		 * Sub-feature's ioctl returns -ENODEV when cmd is not
		 * handled in this sub feature, and returns 0 and other
		 * error code if cmd is handled.
		 */
		fpga_dev_for_each_feature(pdata, f) {
			if (f->ops && f->ops->ioctl) {
				ret = f->ops->ioctl(pdev, f, cmd, arg);
				if (ret == -ENODEV)
					continue;
				else
					return ret;
			}
		}
	}

	return -EINVAL;
}

static const struct file_operations fme_fops = {
	.owner		= THIS_MODULE,
	.open		= fme_open,
	.release	= fme_release,
	.unlocked_ioctl = fme_ioctl,
};

static int fme_dev_init(struct platform_device *pdev)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;

	fme = devm_kzalloc(&pdev->dev, sizeof(*fme), GFP_KERNEL);
	if (!fme)
		return -ENOMEM;

	fme->pdata = pdata;

	mutex_lock(&pdata->lock);
	fpga_pdata_set_private(pdata, fme);
	mutex_unlock(&pdata->lock);
	return 0;
}

static void fme_dev_destroy(struct platform_device *pdev)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	fpga_pdata_set_private(pdata, NULL);
	mutex_unlock(&pdata->lock);

	devm_kfree(&pdev->dev, fme);
}

static int fme_probe(struct platform_device *pdev)
{
	int ret;

	ret = fme_dev_init(pdev);
	if (ret)
		goto exit;

	ret = fpga_dev_feature_init(pdev, fme_feature_drvs);
	if (ret)
		goto dev_destroy;

	ret = fpga_register_dev_ops(pdev, &fme_fops, THIS_MODULE);
	if (ret)
		goto feature_uinit;

	return 0;

feature_uinit:
	fpga_dev_feature_uinit(pdev);
dev_destroy:
	fme_dev_destroy(pdev);
exit:
	return ret;
}

static int fme_remove(struct platform_device *pdev)
{
	fpga_dev_feature_uinit(pdev);
	fpga_unregister_dev_ops(pdev);
	fme_dev_destroy(pdev);
	return 0;
}

static struct platform_driver fme_driver = {
	.driver	= {
		.name    = FPGA_FEATURE_DEV_FME,
	},
	.probe   = fme_probe,
	.remove  = fme_remove,
};

module_platform_driver(fme_driver);

MODULE_DESCRIPTION("FPGA Management Engine driver");
MODULE_AUTHOR("Intel Corporation");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:intel-fpga-fme");
