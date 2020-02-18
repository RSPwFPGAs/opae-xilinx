/*
 * Driver for FPGA Accelerated Function Unit (AFU) Error Handling
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

#include <linux/uaccess.h>
#include "afu.h"

/* Mask / Unmask Port Errors by the Error Mask register. */
static void port_err_mask(struct device *dev, bool mask)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_error *port_err;
	struct feature_port_err_key err_mask;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);

	if (mask)
		err_mask.csr = PORT_ERR_MASK;
	else
		err_mask.csr = 0;

pr_info("LOG: writeq: writeq(err_mask.csr, &port_err->error_mask); ");
	writeq(err_mask.csr, &port_err->error_mask);
}

/* Clear All Port Errors. */
static int port_err_clear(struct device *dev, u64 err)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_header *port_hdr;
	struct feature_port_error *port_err;
	struct feature_port_err_key mask;
	struct feature_port_first_err_key first;
	struct feature_port_status status;
	int ret = 0;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);
	port_hdr = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_HEADER);

	/*
	 * Clear All Port Errors
	 *
	 * - Check for AP6 State
	 * - Halt Port by keeping Port in reset
	 * - Set PORT Error mask to all 1 to mask errors
	 * - Clear all errors
	 * - Set Port mask to all 0 to enable errors
	 * - All errors start capturing new errors
	 * - Enable Port by pulling the port out of reset
	 */

	/* If device is still in AP6 state, can not clear any error.*/
pr_info("LOG: readq: status.csr = readq(&port_hdr->status); ");
	status.csr = readq(&port_hdr->status);
	if (status.power_state == PORT_POWER_STATE_AP6) {
		dev_err(dev, "Could not clear errors, device in AP6 state.\n");
		return -EBUSY;
	}

	/* Halt Port by keeping Port in reset */
	ret = __fpga_port_disable(to_platform_device(dev));
	if (ret)
		return ret;

	/* Mask all errors */
	port_err_mask(dev, true);

	/* Clear errors if err input matches with current port errors.*/
pr_info("LOG: readq: mask.csr = readq(&port_err->port_error); ");
	mask.csr = readq(&port_err->port_error);

	if (mask.csr == err) {
pr_info("LOG: writeq: writeq(mask.csr, &port_err->port_error); ");
		writeq(mask.csr, &port_err->port_error);

pr_info("LOG: readq: first.csr = readq(&port_err->port_first_error); ");
		first.csr = readq(&port_err->port_first_error);
pr_info("LOG: writeq: writeq(first.csr, &port_err->port_first_error); ");
		writeq(first.csr, &port_err->port_first_error);
	} else
		ret = -EBUSY;

	/* Clear mask */
	port_err_mask(dev, false);

	/* Enable the Port by clear the reset */
	__fpga_port_enable(to_platform_device(dev));

	return ret;
}

static ssize_t
revision_show(struct device *dev, struct device_attribute *attr, char *buf)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_error *port_err;
	struct feature_header header;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);

pr_info("LOG: readq: header.csr = readq(&port_err->header); ");
	header.csr = readq(&port_err->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}
static DEVICE_ATTR_RO(revision);

static ssize_t
errors_show(struct device *dev, struct device_attribute *attr, char *buf)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_error *port_err;
	struct feature_port_err_key error;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);

pr_info("LOG: readq: error.csr = readq(&port_err->port_error); ");
	error.csr = readq(&port_err->port_error);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n",
				(unsigned long long)error.csr);
}
static DEVICE_ATTR_RO(errors);

static ssize_t
first_error_show(struct device *dev, struct device_attribute *attr, char *buf)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_error *port_err;
	struct feature_port_first_err_key first_error;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);

pr_info("LOG: readq: first_error.csr = readq(&port_err->port_first_error); ");
	first_error.csr = readq(&port_err->port_first_error);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n",
				(unsigned long long)first_error.csr);
}
static DEVICE_ATTR_RO(first_error);

static ssize_t first_malformed_req_show(struct device *dev,
				struct device_attribute *attr, char *buf)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_error *port_err;
	struct feature_port_malformed_req0 malreq0;
	struct feature_port_malformed_req1 malreq1;

	port_err = get_feature_ioaddr_by_index(dev, PORT_FEATURE_ID_ERROR);

pr_info("LOG: readq: malreq0.header_lsb = readq(&port_err->malreq0); ");
	malreq0.header_lsb = readq(&port_err->malreq0);
pr_info("LOG: readq: malreq1.header_msb = readq(&port_err->malreq1); ");
	malreq1.header_msb = readq(&port_err->malreq1);

	return scnprintf(buf, PAGE_SIZE, "0x%016llx%016llx\n",
				(unsigned long long)malreq1.header_msb,
				(unsigned long long)malreq0.header_lsb);
}
static DEVICE_ATTR_RO(first_malformed_req);

static ssize_t clear_store(struct device *dev,
		struct device_attribute *attr, const char *buff, size_t count)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(dev);
	int ret;
	u64 value;

	if (kstrtou64(buff, 0, &value))
		return -EINVAL;

	WARN_ON(!is_feature_present(dev, PORT_FEATURE_ID_HEADER));

	mutex_lock(&pdata->lock);
	ret = port_err_clear(dev, value);
	mutex_unlock(&pdata->lock);

	if (ret)
		return ret;
	else
		return count;
}
static DEVICE_ATTR_WO(clear);

static struct attribute *port_err_attrs[] = {
	&dev_attr_revision.attr,
	&dev_attr_errors.attr,
	&dev_attr_first_error.attr,
	&dev_attr_first_malformed_req.attr,
	&dev_attr_clear.attr,
	NULL,
};

static struct attribute_group port_err_attr_group = {
	.attrs = port_err_attrs,
	.name = "errors",
};

static int port_err_init(struct platform_device *pdev, struct feature *feature)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_afu *afu;

	dev_info(&pdev->dev, "PORT ERR Init.\n");

	mutex_lock(&pdata->lock);
	port_err_mask(&pdev->dev, false);
	afu = fpga_pdata_get_private(pdata);
	if (feature->ctx_num)
		afu->capability |= FPGA_PORT_CAP_ERR_IRQ;
	mutex_unlock(&pdata->lock);

	return sysfs_create_group(&pdev->dev.kobj, &port_err_attr_group);
}

static void port_err_uinit(struct platform_device *pdev,
					struct feature *feature)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	dev_info(&pdev->dev, "PORT ERR UInit.\n");

	sysfs_remove_group(&pdev->dev.kobj, &port_err_attr_group);
}

static long port_err_set_irq(struct platform_device *pdev,
			     struct feature *feature, unsigned long arg)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_port_err_irq_set hdr;
	struct fpga_afu *afu;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct fpga_port_err_irq_set, evtfd);

	if (copy_from_user(&hdr, (void __user *)arg, minsz))
		return -EFAULT;

	if (hdr.argsz < minsz || hdr.flags)
		return -EINVAL;

	mutex_lock(&pdata->lock);
	afu = fpga_pdata_get_private(pdata);
	if (!(afu->capability & FPGA_PORT_CAP_ERR_IRQ)) {
		mutex_unlock(&pdata->lock);
		return -ENODEV;
	}

	ret = fpga_msix_set_block(feature, 0, 1, &hdr.evtfd);
	mutex_unlock(&pdata->lock);

	return ret;
}

static long
port_err_ioctl(struct platform_device *pdev, struct feature *feature,
	       unsigned int cmd, unsigned long arg)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	long ret;

	switch (cmd) {
	case FPGA_PORT_ERR_SET_IRQ:
		ret = port_err_set_irq(pdev, feature, arg);
		break;
	default:
		dev_info(&pdev->dev, "%x cmd not handled", cmd);
		return -ENODEV;
	}

	return ret;
}

struct feature_ops port_err_ops = {
	.init = port_err_init,
	.uinit = port_err_uinit,
	.ioctl = port_err_ioctl,
	.test = port_err_test,
};
