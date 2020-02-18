/*
 * Driver for FPGA Partial Reconfiguration
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
 *   Christopher Rauer <christopher.rauer@intel.com>
 *   Mitchel, Henry <henry.mitchel@intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#include <linux/types.h>
#include <linux/device.h>
#include <linux/delay.h>
#include <linux/vmalloc.h>
#include <linux/uaccess.h>
#include <linux/stddef.h> /* offsetofend */
#include <linux/vfio.h> /* offsetofend in pre-4.1.0 kernels */
#include <linux/intel-fpga-mod.h>
#include <linux/fpga/fpga-mgr_mod.h>
#include "backport.h"

#include "feature-dev.h"
#include "fme.h"

#define PR_WAIT_TIMEOUT		8000000

#define PR_HOST_STATUS_IDLE	0

DEFINE_FPGA_PR_ERR_MSG(pr_err_msg);

#if defined(CONFIG_X86) && defined(CONFIG_AS_AVX512)

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,2,0)
#include <asm/i387.h>
#else
#include <asm/fpu/api.h>
#endif

static inline void copy512(void *src, void *dst)
{
	asm volatile("vmovdqu64 (%0), %%zmm0;"
		     "vmovntdq %%zmm0, (%1);"
		     :
		     : "r"(src), "r"(dst));
}
#else
static inline void kernel_fpu_begin(void)
{
}

static inline void kernel_fpu_end(void)
{
}

static inline void copy512(void *src, void *dst)
{
	WARN_ON_ONCE(1);
}
#endif

static ssize_t revision_show(struct device *dev, struct device_attribute *attr,
			     char *buf)
{
	struct feature_fme_pr *fme_pr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_PR_MGMT);
	struct feature_header header;

	header.csr = readq(&fme_pr->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}

static DEVICE_ATTR_RO(revision);

static ssize_t interface_id_show(struct device *dev,
	struct device_attribute *attr, char *buf)
{
	struct feature_fme_pr_key intfc_id_l, intfc_id_h;
	struct feature_fme_pr *fme_pr
		= get_feature_ioaddr_by_index(dev, FME_FEATURE_ID_PR_MGMT);

	intfc_id_l.key = readq(&fme_pr->fme_pr_intfc_id_l);
	intfc_id_h.key = readq(&fme_pr->fme_pr_intfc_id_h);

	return scnprintf(buf, PAGE_SIZE, "%016llx%016llx\n",
			intfc_id_h.key, intfc_id_l.key);
}

static DEVICE_ATTR_RO(interface_id);

static struct attribute *pr_mgmt_attrs[] = {
	&dev_attr_revision.attr,
	&dev_attr_interface_id.attr,
	NULL,
};

struct attribute_group pr_mgmt_attr_group = {
	.attrs	= pr_mgmt_attrs,
	.name	= "pr",
};

static u64
pr_err_handle(struct platform_device *pdev, struct feature_fme_pr *fme_pr)
{
	struct feature_fme_pr_status fme_pr_status;
	unsigned long err_code;
	u64 fme_pr_error;
	int i = 0;

	fme_pr_status.csr = readq(&fme_pr->ccip_fme_pr_status);
	if (!fme_pr_status.pr_status)
		return 0;

	err_code = fme_pr_error = readq(&fme_pr->ccip_fme_pr_err);
	for_each_set_bit(i, &err_code, PR_MAX_ERR_NUM)
		dev_dbg(&pdev->dev, "%s\n", pr_err_msg[i]);
	writeq(fme_pr_error, &fme_pr->ccip_fme_pr_err);
	return fme_pr_error;
}

static int fme_pr_write_init(struct fpga_manager *mgr,
		struct fpga_image_info *info, const char *buf, size_t count)
{
	struct fpga_fme *fme = mgr->priv;
	struct platform_device *pdev;
	struct feature_fme_pr *fme_pr;
	struct feature_fme_pr_ctl fme_pr_ctl;
	struct feature_fme_pr_status fme_pr_status;

	pdev = fme->pdata->dev;
	fme_pr = get_feature_ioaddr_by_index(&pdev->dev,
				FME_FEATURE_ID_PR_MGMT);
	if (!fme_pr)
		return -EINVAL;

	if (WARN_ON(info->flags != FPGA_MGR_PARTIAL_RECONFIG))
		return -EINVAL;

	dev_dbg(&pdev->dev, "resetting PR before initiated PR\n");

	fme_pr_ctl.csr = readq(&fme_pr->ccip_fme_pr_control);
	fme_pr_ctl.pr_reset = 1;
	writeq(fme_pr_ctl.csr, &fme_pr->ccip_fme_pr_control);

	fme_pr_ctl.pr_reset_ack = 1;

	if (fpga_wait_register_field(pr_reset_ack, fme_pr_ctl,
		&fme_pr->ccip_fme_pr_control, PR_WAIT_TIMEOUT, 1)) {
		dev_err(&pdev->dev, "maximum PR timeout\n");
		return -ETIMEDOUT;
	}

	fme_pr_ctl.csr = readq(&fme_pr->ccip_fme_pr_control);
	fme_pr_ctl.pr_reset = 0;
	writeq(fme_pr_ctl.csr, &fme_pr->ccip_fme_pr_control);

	dev_dbg(&pdev->dev,
		"waiting for PR resource in HW to be initialized and ready\n");

	fme_pr_status.pr_host_status = PR_HOST_STATUS_IDLE;

	if (fpga_wait_register_field(pr_host_status, fme_pr_status,
		&fme_pr->ccip_fme_pr_status, PR_WAIT_TIMEOUT, 1)) {
		dev_err(&pdev->dev, "maximum PR timeout\n");
		return -ETIMEDOUT;
	}

	dev_dbg(&pdev->dev, "check if have any previous PR error\n");
	pr_err_handle(pdev, fme_pr);
	return 0;
}

static int fme_pr_write(struct fpga_manager *mgr,
			const char *buf, size_t count)
{
	struct fpga_fme *fme = mgr->priv;
	struct platform_device *pdev;
	struct feature_fme_pr *fme_pr;
	struct feature_fme_pr_ctl fme_pr_ctl;
	struct feature_fme_pr_status fme_pr_status;
	struct feature_fme_pr_data fme_pr_data;
	int ret = 0, delay = 0, pr_credit;

	pdev = fme->pdata->dev;
	fme_pr = get_feature_ioaddr_by_index(&pdev->dev,
				FME_FEATURE_ID_PR_MGMT);

	dev_dbg(&pdev->dev, "set PR port ID and start request\n");

	fme_pr_ctl.csr = readq(&fme_pr->ccip_fme_pr_control);
	fme_pr_ctl.pr_regionid = fme->port_id;
	fme_pr_ctl.pr_start_req = 1;
	writeq(fme_pr_ctl.csr, &fme_pr->ccip_fme_pr_control);

	dev_dbg(&pdev->dev, "pushing data from bitstream to HW\n");

	fme_pr_status.csr = readq(&fme_pr->ccip_fme_pr_status);
	pr_credit = fme_pr_status.pr_credit;

	if (fme->pr_avx512)
		kernel_fpu_begin();

	while (count > 0) {
		while (pr_credit <= 1) {
			if (delay++ > PR_WAIT_TIMEOUT) {
				dev_err(&pdev->dev, "maximum try\n");

				fme->pr_err = pr_err_handle(pdev, fme_pr);
				ret = fme->pr_err ? -EIO : -ETIMEDOUT;
				goto done;
			}
			udelay(1);

			fme_pr_status.csr = readq(&fme_pr->ccip_fme_pr_status);
			pr_credit = fme_pr_status.pr_credit;
		};

		if (count >= fme->pr_bandwidth) {
			switch (fme->pr_bandwidth) {
			case 4:
				fme_pr_data.rsvd = 0;
				fme_pr_data.pr_data_raw = *((u32 *)buf);
				writeq(fme_pr_data.csr,
				       &fme_pr->ccip_fme_pr_data);
				break;
			case 64:
				copy512((void *)buf, &fme_pr->fme_pr_data1);
				break;
			default:
				ret = -EFAULT;
				goto done;
			}

			buf += fme->pr_bandwidth;
			count -= fme->pr_bandwidth;
			pr_credit--;
		} else {
			WARN_ON(1);
			ret = -EINVAL;
			goto done;
		}
	}

done:
	if (fme->pr_avx512)
		kernel_fpu_end();

	return ret;
}

static int fme_pr_write_complete(struct fpga_manager *mgr,
			struct fpga_image_info *info)
{
	struct fpga_fme *fme = mgr->priv;
	struct platform_device *pdev;
	struct feature_fme_pr *fme_pr;
	struct feature_fme_pr_ctl fme_pr_ctl;

	pdev = fme->pdata->dev;
	fme_pr = get_feature_ioaddr_by_index(&pdev->dev,
				FME_FEATURE_ID_PR_MGMT);

	fme_pr_ctl.csr = readq(&fme_pr->ccip_fme_pr_control);
	fme_pr_ctl.pr_push_complete = 1;
	writeq(fme_pr_ctl.csr, &fme_pr->ccip_fme_pr_control);

	dev_dbg(&pdev->dev, "green bitstream push complete\n");
	dev_dbg(&pdev->dev, "waiting for HW to release PR resource\n");

	fme_pr_ctl.pr_start_req = 0;

	if (fpga_wait_register_field(pr_start_req, fme_pr_ctl,
		&fme_pr->ccip_fme_pr_control, PR_WAIT_TIMEOUT, 1)) {
		dev_err(&pdev->dev, "maximum try.\n");
		return -ETIMEDOUT;
	}

	dev_dbg(&pdev->dev, "PR operation complete, checking status\n");
	fme->pr_err = pr_err_handle(pdev, fme_pr);
	if (fme->pr_err)
		return -EIO;

	dev_dbg(&pdev->dev, "PR done successfully\n");
	return 0;
}

static enum fpga_mgr_states fme_pr_state(struct fpga_manager *mgr)
{
	return FPGA_MGR_STATE_UNKNOWN;
}

static const struct fpga_manager_ops fme_pr_ops = {
	.write_init = fme_pr_write_init,
	.write = fme_pr_write,
	.write_complete = fme_pr_write_complete,
	.state = fme_pr_state,
};

static int fme_pr(struct platform_device *pdev, unsigned long arg)
{
	void __user *argp = (void __user *)arg;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;
	struct fpga_manager *mgr;
	struct feature_fme_header *fme_hdr;
	struct feature_fme_capability fme_capability;
	struct fpga_image_info info;
	struct fpga_fme_port_pr port_pr;
	struct platform_device *port;
	unsigned long minsz;
	void *buf = NULL;
	size_t length;
	int ret = 0;

	minsz = offsetofend(struct fpga_fme_port_pr, status);

	if (copy_from_user(&port_pr, argp, minsz))
		return -EFAULT;

	if (port_pr.argsz < minsz || port_pr.flags)
		return -EINVAL;

	/* get fme header region */
	fme_hdr = get_feature_ioaddr_by_index(&pdev->dev,
					FME_FEATURE_ID_HEADER);
	if (WARN_ON(!fme_hdr))
		return -EINVAL;

	/* check port id */
	fme_capability.csr = readq(&fme_hdr->capability);
	if (port_pr.port_id >= fme_capability.num_ports) {
		dev_dbg(&pdev->dev, "port number more than maximum\n");
		return -EINVAL;
	}

	if (!access_ok(VERIFY_READ, port_pr.buffer_address,
				    port_pr.buffer_size))
		return -EFAULT;

	mutex_lock(&pdata->lock);
	fme = fpga_pdata_get_private(pdata);
	/* fme device has been unregistered. */
	if (!fme) {
		ret = -EINVAL;
		goto unlock_exit;
	}

	/*
	 * Padding extra zeros to align PR buffer with PR bandwidth, HW will
	 * ignore these zeros automatically.
	 */
	length = ALIGN(port_pr.buffer_size, fme->pr_bandwidth);

	buf = vzalloc(length);
	if (!buf) {
		ret = -ENOMEM;
		goto unlock_exit;
	}

	if (copy_from_user(buf, (void __user *)port_pr.buffer_address,
					       port_pr.buffer_size)) {
		ret = -EFAULT;
		goto free_exit;
	}

	memset(&info, 0, sizeof(struct fpga_image_info));
	info.flags = FPGA_MGR_PARTIAL_RECONFIG;

	mgr = fpga_mgr_get(&pdev->dev);
	if (IS_ERR(mgr)) {
		ret = PTR_ERR(mgr);
		goto free_exit;
	}

	fme->pr_err = 0;
	fme->port_id = port_pr.port_id;

	/* Find and get port device by index */
	port = pdata->fpga_for_each_port(pdev, &fme->port_id,
					 fpga_port_check_id);
	WARN_ON(!port);

	/* Disable Port before PR */
	fpga_port_disable(port);

	ret = fpga_mgr_buf_load(mgr, &info, buf, length);
	port_pr.status = fme->pr_err;

	/* Re-enable Port after PR finished */
	fpga_port_enable(port);

	put_device(&port->dev);

	fpga_mgr_put(mgr);
free_exit:
	vfree(buf);
unlock_exit:
	mutex_unlock(&pdata->lock);
	if (copy_to_user((void __user *)arg, &port_pr, minsz))
		return -EFAULT;
	return ret;
}

static int fpga_fme_pr_probe(struct platform_device *pdev)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct feature_fme_pr *fme_pr;
	struct feature_header fme_pr_header;
	struct fpga_fme *priv;
	int ret;

	mutex_lock(&pdata->lock);
	priv = fpga_pdata_get_private(pdata);

	fme_pr = get_feature_ioaddr_by_index(&pdev->dev,
				FME_FEATURE_ID_PR_MGMT);

	fme_pr_header.csr = readq(&fme_pr->header);
	if (fme_pr_header.revision == 2) {
		dev_dbg(&pdev->dev, "using 512-bit PR\n");
		priv->pr_bandwidth = 64;
		priv->pr_avx512 = true;
	} else {
		dev_dbg(&pdev->dev, "using 32-bit PR\n");
		priv->pr_bandwidth = 4;
	}

	ret = fpga_mgr_register(&pdata->dev->dev,
		"Intel FPGA Manager", &fme_pr_ops, priv);
	mutex_unlock(&pdata->lock);

	return ret;
}

static int fpga_fme_pr_remove(struct platform_device *pdev)
{
	fpga_mgr_unregister(&pdev->dev);
	return 0;
}

static int pr_mgmt_init(struct platform_device *pdev, struct feature *feature)
{
	int ret;

	ret = fpga_fme_pr_probe(pdev);
	if (ret)
		return ret;

	ret = sysfs_create_group(&pdev->dev.kobj, &pr_mgmt_attr_group);
	if (ret)
		fpga_fme_pr_remove(pdev);

	return ret;
}

static void pr_mgmt_uinit(struct platform_device *pdev, struct feature *feature)
{
	sysfs_remove_group(&pdev->dev.kobj, &pr_mgmt_attr_group);
	fpga_fme_pr_remove(pdev);
}

static long fme_pr_ioctl(struct platform_device *pdev, struct feature *feature,
	unsigned int cmd, unsigned long arg)
{
	long ret;

	switch (cmd) {
	case FPGA_FME_PORT_PR:
		ret = fme_pr(pdev, arg);
		break;
	default:
		ret = -ENODEV;
	}

	return ret;
}

struct feature_ops pr_mgmt_ops = {
	.init = pr_mgmt_init,
	.uinit = pr_mgmt_uinit,
	.ioctl = fme_pr_ioctl,
};
