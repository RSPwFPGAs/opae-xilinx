/*
 * Intel FPGA Feature Device Framework Header
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Kang Luwei <luwei.kang@intel.com>
 *   Zhang Yi <Yi.Z.Zhang@intel.com>
 *   Wu Hao <hao.wu@linux.intel.com>
 *   Xiao Guangrong <guangrong.xiao@linux.intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#include <linux/fs.h>

#include "feature-dev.h"

void feature_platform_data_add(struct feature_platform_data *pdata,
			       int index, const char *name,
			       int resource_index, void __iomem *ioaddr,
			       struct feature_irq_ctx *ctx,
			       unsigned int ctx_num)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	WARN_ON(index >= pdata->num);
	WARN_ON(ctx_num && !ctx);

	pdata->features[index].name = name;
	pdata->features[index].resource_index = resource_index;
	pdata->features[index].ioaddr = ioaddr;
	pdata->features[index].ctx = ctx;
	pdata->features[index].ctx_num = ctx_num;
}

int feature_platform_data_size(int num)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	return sizeof(struct feature_platform_data) +
		num * sizeof(struct feature);
}

struct feature_platform_data *
feature_platform_data_alloc_and_init(struct platform_device *dev, int num)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata;

	pdata = kzalloc(feature_platform_data_size(num), GFP_KERNEL);
	if (pdata) {
		pdata->dev = dev;
		pdata->num = num;
		mutex_init(&pdata->lock);
		INIT_LIST_HEAD(&pdata->pid_list);
	}

	return pdata;
}

int fme_feature_num(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	return FME_FEATURE_ID_MAX;
}

int port_feature_num(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	return PORT_FEATURE_ID_MAX;
}

int fme_feature_to_resource_index(int feature_id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	WARN_ON(feature_id >= FME_FEATURE_ID_MAX);
	return feature_id;
}

void fpga_dev_feature_uinit(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature *feature;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);

	fpga_dev_for_each_feature(pdata, feature)
		if (feature->ops) {
			feature->ops->uinit(pdev, feature);
			feature->ops = NULL;
		}
}
EXPORT_SYMBOL_GPL(fpga_dev_feature_uinit);

static int
feature_instance_init(struct platform_device *pdev,
		      struct feature_platform_data *pdata,
		      struct feature *feature, struct feature_driver *drv)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;

	WARN_ON(!feature->ioaddr);

	if (drv->ops->test) {
		ret = drv->ops->test(pdev, feature);
		if (ret)
			return ret;
	}

	ret = drv->ops->init(pdev, feature);
	if (ret)
		return ret;

	feature->ops = drv->ops;
	return ret;
}

int fpga_dev_feature_init(struct platform_device *pdev,
			  struct feature_driver *feature_drvs)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature *feature;
	struct feature_driver *drv = feature_drvs;
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	int ret;

	while (drv->ops) {
		fpga_dev_for_each_feature(pdata, feature) {
			/* skip the feature which is not initialized. */
			if (!feature->name)
				continue;

			if (!strcmp(drv->name, feature->name)) {
				ret = feature_instance_init(pdev, pdata,
							    feature, drv);
				if (ret)
					goto exit;
			}
		}
		drv++;
	}
	return 0;
exit:
	fpga_dev_feature_uinit(pdev);
	return ret;
}
EXPORT_SYMBOL_GPL(fpga_dev_feature_init);

struct fpga_chardev_info {
	const char *name;
	dev_t devt;
};

/* indexe by enum fpga_devt_type */
struct fpga_chardev_info fpga_chrdevs[] = {
	{.name = FPGA_FEATURE_DEV_FME},		/* FPGA_DEVT_FME */
	{.name = FPGA_FEATURE_DEV_PORT},	/* FPGA_DEVT_AFU */
};

void fpga_chardev_uinit(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int i;

	for (i = 0; i < FPGA_DEVT_MAX; i++)
		if (MAJOR(fpga_chrdevs[i].devt)) {
			unregister_chrdev_region(fpga_chrdevs[i].devt,
						 MINORMASK);
			fpga_chrdevs[i].devt = MKDEV(0, 0);
		}
}

int fpga_chardev_init(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int i, ret;

	for (i = 0; i < FPGA_DEVT_MAX; i++) {
		ret = alloc_chrdev_region(&fpga_chrdevs[i].devt, 0, MINORMASK,
					  fpga_chrdevs[i].name);
		if (ret)
			goto exit;
	}

	return 0;

exit:
	fpga_chardev_uinit();
	return ret;
}

dev_t fpga_get_devt(enum fpga_devt_type type, int id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	WARN_ON(type >= FPGA_DEVT_MAX);

	return MKDEV(MAJOR(fpga_chrdevs[type].devt), id);
}

int fpga_register_dev_ops(struct platform_device *pdev,
			  const struct file_operations *fops,
			  struct module *owner)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);

	cdev_init(&pdata->cdev, fops);
	pdata->cdev.owner = owner;

	/*
	 * set parent to the feature device so that its refcount is
	 * decreased after the last refcount of cdev is gone, that
	 * makes sure the feature device is valid during device
	 * file's life-cycle.
	 */
	pdata->cdev.kobj.parent = &pdev->dev.kobj;
	return cdev_add(&pdata->cdev, pdev->dev.devt, 1);
}
EXPORT_SYMBOL_GPL(fpga_register_dev_ops);

void fpga_unregister_dev_ops(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);

	cdev_del(&pdata->cdev);
}
EXPORT_SYMBOL_GPL(fpga_unregister_dev_ops);

int fpga_port_id(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_port_header *port_hdr;
	struct feature_port_capability capability;

	port_hdr = get_feature_ioaddr_by_index(&pdev->dev,
					       PORT_FEATURE_ID_HEADER);
	WARN_ON(!port_hdr);

pr_info("LOG: readq: capability.csr = readq(&port_hdr->capability); ");
	capability.csr = readq(&port_hdr->capability);
	return capability.port_number;
}
EXPORT_SYMBOL_GPL(fpga_port_id);

/*
 * Enable Port by clear the port soft reset bit, which is set by default.
 * The AFU is unable to respond to any MMIO access while in reset.
 * __fpga_port_enable function should only be used after __fpga_port_disable
 * function.
 */
void __fpga_port_enable(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct feature_port_header *port_hdr;
	struct feature_port_control control;

	WARN_ON(!pdata->disable_count);

	if (--pdata->disable_count != 0)
		return;

	port_hdr = get_feature_ioaddr_by_index(&pdev->dev,
					       PORT_FEATURE_ID_HEADER);
	WARN_ON(!port_hdr);

pr_info("LOG: readq: control.csr = readq(&port_hdr->control); ");
	control.csr = readq(&port_hdr->control);
	control.port_sftrst = 0x0;
pr_info("LOG: writeq: writeq(control.csr, &port_hdr->control); ");
	writeq(control.csr, &port_hdr->control);
}
EXPORT_SYMBOL_GPL(__fpga_port_enable);

#define RST_POLL_INVL 10 /* us */
#define RST_POLL_TIMEOUT 1000 /* us */

int __fpga_port_disable(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct feature_port_header *port_hdr;
	struct feature_port_control control;

	if (pdata->disable_count++ != 0)
		return 0;

	port_hdr = get_feature_ioaddr_by_index(&pdev->dev,
					       PORT_FEATURE_ID_HEADER);
	WARN_ON(!port_hdr);

	/* Set port soft reset */
pr_info("LOG: readq: control.csr = readq(&port_hdr->control); ");
	control.csr = readq(&port_hdr->control);
	control.port_sftrst = 0x1;
pr_info("LOG: writeq: writeq(control.csr, &port_hdr->control); ");
	writeq(control.csr, &port_hdr->control);

	/*
	 * HW sets ack bit to 1 when all outstanding requests have been drained
	 * on this port and minimum soft reset pulse width has elapsed.
	 * Driver polls port_soft_reset_ack to determine if reset done by HW.
	 */
	control.port_sftrst_ack = 1;

	if (fpga_wait_register_field(port_sftrst_ack, control,
		&port_hdr->control, RST_POLL_TIMEOUT, RST_POLL_INVL)) {
		dev_err(&pdev->dev, "timeout, fail to reset device\n");
		return -ETIMEDOUT;
	}

	return 0;
}
EXPORT_SYMBOL_GPL(__fpga_port_disable);

static irqreturn_t fpga_msix_handler(int irq, void *arg)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct eventfd_ctx *trigger = arg;

	eventfd_signal(trigger, 1);
	return IRQ_HANDLED;
}

static int fpga_set_vector_signal(struct feature *feature, int vector, int fd)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct eventfd_ctx *trigger;
	int irq, ret;

	if (vector < 0 || vector >= feature->ctx_num)
		return -EINVAL;

	irq = feature->ctx[vector].irq;

	if (feature->ctx[vector].trigger) {
		free_irq(irq, feature->ctx[vector].trigger);
		kfree(feature->ctx[vector].name);
		eventfd_ctx_put(feature->ctx[vector].trigger);
		feature->ctx[vector].trigger = NULL;
	}

	if (fd < 0)
		return 0;

	feature->ctx[vector].name = kasprintf(GFP_KERNEL, "fpga-msix[%d](%s)",
						vector, feature->name);
	if (!feature->ctx[vector].name)
		return -ENOMEM;

	trigger = eventfd_ctx_fdget(fd);
	if (IS_ERR(trigger)) {
		kfree(feature->ctx[vector].name);
		return PTR_ERR(trigger);
	}

	ret = request_irq(irq, fpga_msix_handler, 0, feature->ctx[vector].name,
			  trigger);
	if (ret) {
		kfree(feature->ctx[vector].name);
		eventfd_ctx_put(trigger);
		return ret;
	}

	feature->ctx[vector].trigger = trigger;

	return 0;
}

int fpga_msix_set_block(struct feature *feature, unsigned int start,
			unsigned int count, int32_t *fds)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int i, j, ret = 0;

	if (start >= feature->ctx_num || start + count > feature->ctx_num)
		return -EINVAL;

	for (i = 0, j = start; i < count && !ret; i++, j++) {
		int fd = fds ? fds[i] : -1;

		ret = fpga_set_vector_signal(feature, j, fd);
	}

	if (ret) {
		for (--j; j >= (int)start; j--)
			fpga_set_vector_signal(feature, j, -1);
	}

	return ret;
}
EXPORT_SYMBOL_GPL(fpga_msix_set_block);

struct platform_device *feature_create_subdev(struct platform_device *pdev,
					      const char *name, void *data,
					      size_t length)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct platform_device_info pdevinfo;

	dev_info(&pdev->dev, "%s create %s subdev\n", __func__, name);

	memset(&pdevinfo, 0, sizeof(pdevinfo));

	pdevinfo.name		= name;
	pdevinfo.id		= PLATFORM_DEVID_AUTO;
	pdevinfo.parent		= &pdev->dev;
	pdevinfo.data		= data;
	pdevinfo.size_data	= length;

	return platform_device_register_full(&pdevinfo);
}
EXPORT_SYMBOL_GPL(feature_create_subdev);

void feature_destroy_subdev(struct platform_device *subdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	platform_device_unregister(subdev);
}
EXPORT_SYMBOL_GPL(feature_destroy_subdev);
