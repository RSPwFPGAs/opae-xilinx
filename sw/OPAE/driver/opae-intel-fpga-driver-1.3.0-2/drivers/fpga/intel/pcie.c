/*
 * Driver for the PCIe device which locates between CPU and accelerated
 * function units(AFUs) and allows them to communicate with each other.
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Zhang Yi <Yi.Z.Zhang@intel.com>
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

#include <linux/pci.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/stddef.h>
#include <linux/errno.h>
#include <linux/aer.h>
#include <linux/uuid.h>
#include <linux/kdev_t.h>
#include <linux/mfd/core.h>
#include <linux/mtd/altera-asmip2.h>

#include "backport.h"
#include "pac-hssi.h"
#include "pac-iopll.h"
#include "feature-dev.h"

#define DRV_VERSION	"0.14.0"
#define DRV_NAME	"intel-fpga-pci"

static DEFINE_MUTEX(fpga_id_mutex);

enum fpga_id_type {
	/*
	 * fpga parent device id allocation and mapping, parent device
	 * is the container of fme device and port device
	 */
	PARENT_ID,
	/* fme id allocation and mapping */
	FME_ID,
	/* port id allocation and mapping */
	PORT_ID,
	FPGA_ID_MAX,
};

/* it is protected by fpga_id_mutex */
static struct idr fpga_ids[FPGA_ID_MAX];

struct cci_drvdata {
	int device_id;
	struct device *fme_dev;

	struct mutex lock;
	struct list_head port_dev_list;
	/* number of released ports which can be configured as VF  */
	int released_port_num;

	struct list_head regions;

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
	struct msix_entry *msix_entries;
#endif
};

struct cci_pci_region {
	int bar;
	void __iomem *ioaddr;

	struct list_head node;
};

static void fpga_ids_init(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int i;

	for (i = 0; i < ARRAY_SIZE(fpga_ids); i++)
		idr_init(fpga_ids + i);
}

static void fpga_ids_destroy(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int i;

	for (i = 0; i < ARRAY_SIZE(fpga_ids); i++)
		idr_destroy(fpga_ids + i);
}

static int alloc_fpga_id(enum fpga_id_type type, struct device *dev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int id;

	WARN_ON(type >= FPGA_ID_MAX);
	mutex_lock(&fpga_id_mutex);
	id = idr_alloc(fpga_ids + type, dev, 0, 0, GFP_KERNEL);
	mutex_unlock(&fpga_id_mutex);
	return id;
}

static void free_fpga_id(enum fpga_id_type type, int id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	WARN_ON(type >= FPGA_ID_MAX);
	mutex_lock(&fpga_id_mutex);
	idr_remove(fpga_ids + type, id);
	mutex_unlock(&fpga_id_mutex);
}

static void cci_pci_add_port_dev(struct pci_dev *pdev,
				 struct platform_device *port_dev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct feature_platform_data *pdata = dev_get_platdata(&port_dev->dev);

	mutex_lock(&drvdata->lock);
	list_add(&pdata->node, &drvdata->port_dev_list);
	get_device(&pdata->dev->dev);
	mutex_unlock(&drvdata->lock);
}

static void cci_pci_remove_port_devs(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct feature_platform_data *pdata, *ptmp;

	mutex_lock(&drvdata->lock);
	list_for_each_entry_safe(pdata, ptmp, &drvdata->port_dev_list, node) {
		struct platform_device *port_dev = pdata->dev;

		/* the port should be unregistered first. */
		WARN_ON(device_is_registered(&port_dev->dev));
		list_del(&pdata->node);
		free_fpga_id(PORT_ID, port_dev->id);
		put_device(&port_dev->dev);
	}
	mutex_unlock(&drvdata->lock);
}

static struct platform_device *cci_pci_lookup_port_by_id(struct pci_dev *pdev,
							 int port_id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct feature_platform_data *pdata;

	list_for_each_entry(pdata, &drvdata->port_dev_list, node)
		if (fpga_port_check_id(pdata->dev, &port_id))
			return pdata->dev;

	return NULL;
}

/* info collection during feature dev build. */
struct build_feature_devs_info {
	struct pci_dev *pdev;

	/*
	 * PCI BAR mapping info. Parsing feature list starts from
	 * BAR 0 and switch to different BARs to parse Port
	 */
	void __iomem *ioaddr;
	void __iomem *ioend;
	int current_bar;

	/* points to FME header where the port offset is figured out. */
	void __iomem *pfme_hdr;

	/* the container device for all feature devices */
	struct device *parent_dev;

	/* current feature device */
	struct platform_device *feature_dev;
};

static void cci_pci_release_regions(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct cci_pci_region *tmp, *region;

	list_for_each_entry_safe(region, tmp, &drvdata->regions, node) {
		list_del(&region->node);
		if (region->ioaddr)
			pci_iounmap(pdev, region->ioaddr);
		devm_kfree(&pdev->dev, region);
	}
}

static void __iomem *cci_pci_ioremap_bar(struct pci_dev *pdev, int bar)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct cci_pci_region *region;

	list_for_each_entry(region, &drvdata->regions, node)
		if (region->bar == bar) {
			dev_info(&pdev->dev, "BAR %d region exists\n", bar);
			return region->ioaddr;
		}

	region = devm_kzalloc(&pdev->dev, sizeof(*region), GFP_KERNEL);
	if (!region)
		return NULL;

	region->bar = bar;
	region->ioaddr = pci_ioremap_bar(pdev, bar);
	if (!region->ioaddr) {
		dev_err(&pdev->dev, "can't ioremap memory from BAR %d.\n", bar);
		devm_kfree(&pdev->dev, region);
		return NULL;
	}

	list_add(&region->node, &drvdata->regions);
	return region->ioaddr;
}

static int parse_start_from(struct build_feature_devs_info *binfo, int bar)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	binfo->ioaddr = cci_pci_ioremap_bar(binfo->pdev, bar);
	if (!binfo->ioaddr)
		return -ENOMEM;

	binfo->current_bar = bar;
	binfo->ioend = binfo->ioaddr + pci_resource_len(binfo->pdev, bar);
	return 0;
}

static int parse_start(struct build_feature_devs_info *binfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	/* fpga feature list starts from BAR 0 */
	return parse_start_from(binfo, 0);
}

/* switch the memory mapping to BAR# @bar */
static int parse_switch_to(struct build_feature_devs_info *binfo, int bar)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	return parse_start_from(binfo, bar);
}

static int attach_port_dev(struct platform_device *pdev, int port_id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_fme_header *fme_hdr;
	struct feature_fme_port port;
	struct device *pci_dev = fpga_feature_dev_to_pcidev(pdev);
	struct cci_drvdata *drvdata = dev_get_drvdata(pci_dev);
	struct platform_device *port_dev;
	int ret;

	fme_hdr = get_feature_ioaddr_by_index(&pdev->dev,
					      FME_FEATURE_ID_HEADER);

	mutex_lock(&drvdata->lock);
pr_info("LOG: readq: port.csr = readq(&fme_hdr->port[port_id]); ");
	port.csr = readq(&fme_hdr->port[port_id]);
	if (port.afu_access_control == FME_AFU_ACCESS_VF) {
		dev_info(&pdev->dev, "port_%d has already been turned to VF.\n",
			port_id);
		mutex_unlock(&drvdata->lock);
		return -EBUSY;
	}

	port_dev = cci_pci_lookup_port_by_id(to_pci_dev(pci_dev), port_id);
	if (!port_dev) {
		dev_err(&pdev->dev, "port_%d is not detected.\n", port_id);
		ret = -EINVAL;
		goto exit;
	}

	if (device_is_registered(&port_dev->dev)) {
		dev_info(pci_dev, "port_%d is not released.\n", port_id);
		ret = -EBUSY;
		goto exit;
	}

	dev_info(pci_dev, "now re-assign port_%d:%s\n", port_id, port_dev->name);

	ret = platform_device_add(port_dev);
	if (ret)
		goto exit;

	get_device(&port_dev->dev);
	feature_dev_use_end(dev_get_platdata(&port_dev->dev));
	drvdata->released_port_num--;
exit:
	mutex_unlock(&drvdata->lock);
	return ret;
}

static int detach_port_dev(struct platform_device *pdev, int port_id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct device *dev = fpga_feature_dev_to_pcidev(pdev);
	struct cci_drvdata *drvdata = dev_get_drvdata(dev);
	struct platform_device *port_dev;
	int ret;

	mutex_lock(&drvdata->lock);
	port_dev = cci_pci_lookup_port_by_id(to_pci_dev(dev), port_id);
	if (!port_dev) {
		dev_err(&pdev->dev, "port_%d is not detected.\n", port_id);
		ret = -EINVAL;
		goto exit;
	}

	if (!device_is_registered(&port_dev->dev)) {
		dev_info(&pdev->dev,
		   "port_%d is released or already assigned a VF.\n", port_id);
		ret = -EBUSY;
		goto exit;
	}

	ret = feature_dev_use_excl_begin(dev_get_platdata(&port_dev->dev));
	if (ret)
		goto exit;

	platform_device_del(port_dev);
	put_device(&port_dev->dev);
	drvdata->released_port_num++;
exit:
	mutex_unlock(&drvdata->lock);
	return ret;
}

static int
config_port(struct platform_device *pdev, u32 port_id, bool release)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	/* Todo: some potential check */
	if (release)
		return detach_port_dev(pdev, port_id);

	return attach_port_dev(pdev, port_id);
}

static struct platform_device *fpga_for_each_port(struct platform_device *pdev,
		     void *data, int (*match)(struct platform_device *, void *))
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct device *pci_dev = fpga_feature_dev_to_pcidev(pdev);
	struct cci_drvdata *drvdata = dev_get_drvdata(pci_dev);
	struct feature_platform_data *pdata;
	struct platform_device *port_dev;

	mutex_lock(&drvdata->lock);
	list_for_each_entry(pdata, &drvdata->port_dev_list, node) {
		port_dev = pdata->dev;

		if (match(port_dev, data) && get_device(&port_dev->dev))
			goto exit;
	}
	port_dev = NULL;
exit:
	mutex_unlock(&drvdata->lock);
	return port_dev;
}

static struct build_feature_devs_info *
build_info_alloc_and_init(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct build_feature_devs_info *binfo;

	binfo = devm_kzalloc(&pdev->dev, sizeof(*binfo), GFP_KERNEL);
	if (binfo)
		binfo->pdev = pdev;

	return binfo;
}

static enum fpga_id_type feature_dev_id_type(struct platform_device *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	if (!strcmp(pdev->name, FPGA_FEATURE_DEV_FME))
		return FME_ID;

	if (!strcmp(pdev->name, FPGA_FEATURE_DEV_PORT))
		return PORT_ID;

	WARN_ON(1);
	return FPGA_ID_MAX;
}

/*
 * register current feature device, it is called when we need to switch to
 * another feature parsing or we have parsed all features
 */
static int build_info_commit_dev(struct build_feature_devs_info *binfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;

	if (!binfo->feature_dev)
		return 0;

	ret = platform_device_add(binfo->feature_dev);
	if (!ret) {
		struct cci_drvdata *drvdata;

		drvdata = dev_get_drvdata(&binfo->pdev->dev);
		if (feature_dev_id_type(binfo->feature_dev) == PORT_ID)
			cci_pci_add_port_dev(binfo->pdev, binfo->feature_dev);
		else
			drvdata->fme_dev = get_device(&binfo->feature_dev->dev);

		/*
		 * reset it to avoid build_info_free() freeing their resource.
		 *
		 * The resource of successfully registered feature devices
		 * will be freed by platform_device_unregister(). See the
		 * comments in build_info_create_dev().
		 */
		binfo->feature_dev = NULL;
	}

	return ret;
}

static int
build_info_create_dev(struct build_feature_devs_info *binfo,
		      enum fpga_id_type type, int feature_nr, const char *name)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct platform_device *fdev;
	struct resource *res;
	struct feature_platform_data *pdata;
	enum fpga_devt_type devt_type = FPGA_DEVT_FME;
	int ret;

	if (type == PORT_ID)
		devt_type = FPGA_DEVT_PORT;

	/* we will create a new device, commit current device first */
	ret = build_info_commit_dev(binfo);
	if (ret)
		return ret;

	/*
	 * we use -ENODEV as the initialization indicator which indicates
	 * whether the id need to be reclaimed
	 */
	fdev = binfo->feature_dev = platform_device_alloc(name, -ENODEV);
	if (!fdev)
		return -ENOMEM;

	fdev->id = alloc_fpga_id(type, &fdev->dev);
	if (fdev->id < 0)
		return fdev->id;

	fdev->dev.parent = binfo->parent_dev;
	fdev->dev.devt = fpga_get_devt(devt_type, fdev->id);

	/*
	 * we need not care the memory which is associated with the
	 * platform device. After call platform_device_unregister(),
	 * it will be automatically freed by device's
	 * release() callback, platform_device_release().
	 */
	pdata = feature_platform_data_alloc_and_init(fdev, feature_nr);
	if (!pdata)
		return -ENOMEM;

	if (type == FME_ID) {
		pdata->config_port = config_port;
		pdata->fpga_for_each_port = fpga_for_each_port;
	}

	/*
	 * the count should be initialized to 0 to make sure
	 *__fpga_port_enable() following __fpga_port_disable()
	 * works properly.
	 */
	WARN_ON(pdata->disable_count);

	fdev->dev.platform_data = pdata;
	fdev->num_resources = feature_nr;
	fdev->resource = kcalloc(feature_nr, sizeof(*res), GFP_KERNEL);
	if (!fdev->resource)
		return -ENOMEM;

	return 0;
}

static int remove_feature_dev(struct device *dev, void *data)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct platform_device *pdev = to_platform_device(dev);

	platform_device_unregister(pdev);
	return 0;
}

static int remove_parent_dev(struct device *dev, void *data)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	/* remove platform devices attached in the parent device */
	device_for_each_child(dev, NULL, remove_feature_dev);
	device_unregister(dev);
	return 0;
}

static void remove_all_devs(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	/* remove parent device and all its children. */
	device_for_each_child(&pdev->dev, NULL, remove_parent_dev);
}

static void build_info_free(struct build_feature_devs_info *binfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	if (!IS_ERR_OR_NULL(binfo->parent_dev))
		remove_all_devs(binfo->pdev);

	/*
	 * it is a valid id, free it. See comments in
	 * build_info_create_dev()
	 */
	if (binfo->feature_dev && binfo->feature_dev->id >= 0)
		free_fpga_id(feature_dev_id_type(binfo->feature_dev),
			     binfo->feature_dev->id);

	platform_device_put(binfo->feature_dev);

	devm_kfree(&binfo->pdev->dev, binfo);
}

static int
build_info_add_sub_feature(struct build_feature_devs_info *binfo,
			   int feature_id, const char *feature_name,
			   resource_size_t resource_size, void __iomem *start,
			   unsigned int vec_start, unsigned int vec_cnt)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
	struct cci_drvdata *drvdata = dev_get_drvdata(&binfo->pdev->dev);
	struct msix_entry *msix_entries = drvdata->msix_entries;
#endif
	struct platform_device *fdev = binfo->feature_dev;
	struct feature_platform_data *pdata = dev_get_platdata(&fdev->dev);
	struct resource *res = &fdev->resource[feature_id];
	struct feature_irq_ctx *ctx = NULL;
	int i;

	res->start = pci_resource_start(binfo->pdev, binfo->current_bar) +
		start - binfo->ioaddr;
	res->end = res->start + resource_size - 1;
	res->flags = IORESOURCE_MEM;
	res->name = feature_name;

	/*
	 * Add interrupt information for the feature which support interrupt.
	 */
	if (vec_cnt) {
		ctx = devm_kcalloc(&binfo->pdev->dev, vec_cnt,
						sizeof(*ctx), GFP_KERNEL);
		if (!ctx)
			return -ENOMEM;

		for (i = 0; i < vec_cnt; i++)
#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
			ctx[i].irq = msix_entries[vec_start + i].vector;
#else
			ctx[i].irq = pci_irq_vector(binfo->pdev, vec_start + i);
#endif
	}

	feature_platform_data_add(pdata, feature_id, feature_name, feature_id,
				  start, ctx, vec_cnt);

	return 0;
}

struct feature_info {
	const char *name;
	resource_size_t resource_size;
	int feature_index;
	int revision_id;
	unsigned int vec_start;
	unsigned int vec_cnt;
};

/* indexed by fme feature IDs which are defined in 'enum fme_feature_id'. */
static struct feature_info fme_features[] = {
	{
		.name = FME_FEATURE_HEADER,
		.resource_size = sizeof(struct feature_fme_header),
		.feature_index = FME_FEATURE_ID_HEADER,
		.revision_id = FME_HEADER_REVISION
	},
	{
		.name = FME_FEATURE_THERMAL_MGMT,
		.resource_size = sizeof(struct feature_fme_thermal),
		.feature_index = FME_FEATURE_ID_THERMAL_MGMT,
		.revision_id = FME_THERMAL_MGMT_REVISION
	},
	{
		.name = FME_FEATURE_POWER_MGMT,
		.resource_size = sizeof(struct feature_fme_power),
		.feature_index = FME_FEATURE_ID_POWER_MGMT,
		.revision_id = FME_POWER_MGMT_REVISION
	},
	{
		.name = FME_FEATURE_GLOBAL_IPERF,
		.resource_size = sizeof(struct feature_fme_iperf),
		.feature_index = FME_FEATURE_ID_GLOBAL_IPERF,
		.revision_id = FME_GLOBAL_IPERF_REVISION
	},
	{
		.name = FME_FEATURE_GLOBAL_ERR,
		.resource_size = sizeof(struct feature_fme_err),
		.feature_index = FME_FEATURE_ID_GLOBAL_ERR,
		.revision_id = FME_GLOBAL_ERR_REVISION
	},
	{
		.name = FME_FEATURE_PR_MGMT,
		.resource_size = sizeof(struct feature_fme_pr),
		.feature_index = FME_FEATURE_ID_PR_MGMT,
		.revision_id = FME_PR_MGMT_REVISION
	},
	{
		.name = FME_FEATURE_HSSI_ETH,
		.resource_size = FME_FEATURE_HSSI_ETH_SIZE,
		.feature_index = FME_FEATURE_ID_HSSI_ETH,
		.revision_id = FME_HSSI_ETH_REVISION
	},
	{
		.name = FME_FEATURE_GLOBAL_DPERF,
		.resource_size = sizeof(struct feature_fme_dperf),
		.feature_index = FME_FEATURE_ID_GLOBAL_DPERF,
		.revision_id = FME_GLOBAL_DPERF_REVISION
	},
	{
		.name = FME_FEATURE_QSPI_FLASH,
		.resource_size = ALTERA_ASMIP2_RESOURCE_SIZE,
		.feature_index = FME_FEATURE_ID_QSPI_FLASH,
		.revision_id = FME_QSPI_REVISION
	},
	{
		.name = FME_FEATURE_EMIF_MGMT,
		.resource_size = sizeof(struct feature_fme_emif),
		.feature_index = FME_FEATURE_ID_EMIF_MGMT,
		.revision_id = FME_EMIF_MGMT_REVISION
	},
	{
		.name = FME_FEATURE_PAC_HSSI_ETH,
		.resource_size = PAC_HSSI_RESOURCE_SIZE,
		.feature_index = FME_FEATURE_ID_PAC_HSSI_ETH,
		.revision_id = FME_HSSI_ETH_REVISION
	},
	{
		.name = FME_FEATURE_S10_SDM_MB,
		.resource_size = sizeof(struct feature_fme_s10_sdm_mb),
		.feature_index = FME_FEATURE_ID_S10_SDM_MB,
		.revision_id = 0,
	},
	{
		.name = FME_FEATURE_AVMMI_BMC,
		.resource_size = FME_FEATURE_AVMMI_BMC_SIZE,
		.feature_index = FME_FEATURE_ID_AVMMI_BMC,
		.revision_id = 0
	},
};

static struct feature_info port_features[] = {
	{
		.name = PORT_FEATURE_HEADER,
		.resource_size = sizeof(struct feature_port_header),
		.feature_index = PORT_FEATURE_ID_HEADER,
		.revision_id = PORT_HEADER_REVISION
	},
	{
		.name = PORT_FEATURE_ERR,
		.resource_size = sizeof(struct feature_port_error),
		.feature_index = PORT_FEATURE_ID_ERROR,
		.revision_id = PORT_ERR_REVISION
	},
	{
		.name = PORT_FEATURE_UMSG,
		.resource_size = sizeof(struct feature_port_umsg),
		.feature_index = PORT_FEATURE_ID_UMSG,
		.revision_id = PORT_UMSG_REVISION
	},
	{
		.name = PORT_FEATURE_UINT,
		.resource_size = sizeof(struct feature_port_uint),
		.feature_index = PORT_FEATURE_ID_UINT,
		.revision_id = PORT_UINT_REVISION
	},
	{
		.name = PORT_FEATURE_STP,
		.resource_size = PORT_FEATURE_STP_REGION_SIZE,
		.feature_index = PORT_FEATURE_ID_STP,
		.revision_id = PORT_STP_REVISION
	},
	{
		.name = PORT_FEATURE_IOPLL,
		.resource_size = PAC_IOPLL_RESOURCE_SIZE,
		.feature_index = PORT_FEATURE_ID_IOPLL,
		.revision_id = PORT_IOPLL_REVISION
	},
	{
		.name = PORT_FEATURE_UAFU,
		/* UAFU feature size should be read from PORT_CAP.MMIOSIZE.
		 * Will set uafu feature size while parse port device.
		 */
		.resource_size = 0,
		.feature_index = PORT_FEATURE_ID_UAFU,
		.revision_id = PORT_UAFU_REVISION
	},
};

static int
create_feature_instance(struct build_feature_devs_info *binfo,
			void __iomem *start, struct feature_info *finfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header *hdr = start;

	if (binfo->ioend - start < finfo->resource_size)
		return -EINVAL;

	if (finfo->revision_id != SKIP_REVISION_CHECK
		&& hdr->revision > finfo->revision_id) {
		dev_info(&binfo->pdev->dev,
		"feature %s revision :default:%x, now at:%x, mis-match.\n",
		finfo->name, finfo->revision_id, hdr->revision);
	}

	return build_info_add_sub_feature(binfo, finfo->feature_index,
			finfo->name, finfo->resource_size, start,
			finfo->vec_start, finfo->vec_cnt);
}

static int parse_feature_fme(struct build_feature_devs_info *binfo,
			     void __iomem *start)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&binfo->pdev->dev);
	int ret;

	ret = build_info_create_dev(binfo, FME_ID, fme_feature_num(),
					FPGA_FEATURE_DEV_FME);
	if (ret)
		return ret;

	if (drvdata->fme_dev) {
		dev_err(&binfo->pdev->dev, "Multiple FMEs are detected.\n");
		return -EINVAL;
	}

	return create_feature_instance(binfo, start,
				       &fme_features[FME_FEATURE_ID_HEADER]);
}

static void parse_feature_irqs(struct build_feature_devs_info *binfo,
			       void __iomem *start, struct feature_info *finfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int vec_cnt;

	finfo->vec_start = 0;
	finfo->vec_cnt = 0;

	vec_cnt = pci_msix_vec_count(binfo->pdev);
	if (vec_cnt <= 0)
		return;

	if (!strcmp(finfo->name, PORT_FEATURE_UINT)) {
		struct feature_port_uint *port_uint = start;
		struct feature_port_uint_cap uint_cap;

pr_info("LOG: readq: uint_cap.csr = readq(&port_uint->capability); ");
		uint_cap.csr = readq(&port_uint->capability);
		if (uint_cap.intr_num) {
			finfo->vec_start = uint_cap.first_vec_num;
			finfo->vec_cnt = uint_cap.intr_num;
		} else
			dev_info(&binfo->pdev->dev, "UAFU doesn't support interrupt\n");

	} else if (!strcmp(finfo->name, PORT_FEATURE_ERR)) {
		struct feature_port_error *port_err = start;
		struct feature_port_err_capability port_err_cap;

pr_info("LOG: readq: uint_cap.csr = readq(&port_uint->capability); ");
		port_err_cap.csr = readq(&port_err->error_capability);
		if (port_err_cap.support_intr) {
			finfo->vec_start = port_err_cap.intr_vector_num;
			finfo->vec_cnt = 1;
		} else
			dev_info(&binfo->pdev->dev, "Port error doesn't support interrupt\n");

	} else if (!strcmp(finfo->name, FME_FEATURE_GLOBAL_ERR)) {
		struct feature_fme_err *fme_err = start;
		struct feature_fme_error_capability fme_err_cap;

pr_info("LOG: readq: fme_err_cap.csr = readq(&fme_err->fme_err_capability); ");
		fme_err_cap.csr = readq(&fme_err->fme_err_capability);
		if (fme_err_cap.support_intr) {
			finfo->vec_start = fme_err_cap.intr_vector_num;
			finfo->vec_cnt = 1;
		} else
			dev_info(&binfo->pdev->dev, "FME error doesn't support interrupt\n");
	}

	if (finfo->vec_start + finfo->vec_cnt > vec_cnt) {
		finfo->vec_start = 0;
		finfo->vec_cnt = 0;
		dev_err(&binfo->pdev->dev, "Inconsistent interrupt number on HW\n");
	}
}

static int parse_feature_fme_private(struct build_feature_devs_info *binfo,
				     struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header header;

pr_info("LOG: readq: header.csr = readq(hdr); ");
	header.csr = readq(hdr);

	if (header.id >= ARRAY_SIZE(fme_features)) {
		dev_info(&binfo->pdev->dev, "FME feature id %x is not supported yet.\n",
			 header.id);
		return 0;
	}

	parse_feature_irqs(binfo, hdr, &fme_features[header.id]);

	check_features_header(binfo->pdev, hdr, FPGA_DEVT_FME, header.id);

	return create_feature_instance(binfo, hdr, &fme_features[header.id]);
}

static int parse_feature_port(struct build_feature_devs_info *binfo,
			     void __iomem *start)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;

	ret = build_info_create_dev(binfo, PORT_ID, port_feature_num(),
					FPGA_FEATURE_DEV_PORT);
	if (ret)
		return ret;

	return create_feature_instance(binfo, start,
				       &port_features[PORT_FEATURE_ID_HEADER]);
}

static void enable_port_uafu(struct build_feature_devs_info *binfo,
			     void __iomem *start)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	enum port_feature_id id = PORT_FEATURE_ID_UAFU;
	struct feature_port_header *port_hdr;
	struct feature_port_capability capability;
	struct feature_port_control control;

	port_hdr = (struct feature_port_header *)start;
pr_info("LOG: readq: capability.csr = readq(&port_hdr->capability); ");
	capability.csr = readq(&port_hdr->capability);
pr_info("LOG: readq: control.csr = readq(&port_hdr->control); ");
	control.csr = readq(&port_hdr->control);
	port_features[id].resource_size = capability.mmio_size << 10;
pr_info("port_features[%d].resource_size = 0x%x ", id, port_features[id].resource_size);

	/*
	 * From SAS spec, to Enable UAFU, we should reset related port,
	 * or the whole mmio space in this UAFU will be invalid
	 */
	if (port_features[id].resource_size)
		fpga_port_reset(binfo->feature_dev);
}

static int parse_feature_port_private(struct build_feature_devs_info *binfo,
				      struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header header;
	enum port_feature_id id;

pr_info("LOG: readq: header.csr = readq(hdr); ");
	header.csr = readq(hdr);
	/*
	 * the region of port feature id is [0x10, 0x13], + 1 to reserve 0
	 * which is dedicated for port-hdr.
	 */
	id = (header.id & 0x000f) + 1;

	if (id >= ARRAY_SIZE(port_features)) {
		dev_info(&binfo->pdev->dev, "Port feature id %x is not supported yet.\n",
			 header.id);
		return 0;
	}

	parse_feature_irqs(binfo, hdr, &port_features[id]);

	check_features_header(binfo->pdev, hdr, FPGA_DEVT_PORT, id);

	return create_feature_instance(binfo, hdr, &port_features[id]);
}

static int parse_feature_port_afu(struct build_feature_devs_info *binfo,
				  struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	enum port_feature_id id = PORT_FEATURE_ID_UAFU;
	int ret;

pr_info("port_features[%d].resource_size = 0x%x ", id, port_features[id].resource_size);
	if (port_features[id].resource_size) {
		ret = create_feature_instance(binfo, hdr, &port_features[id]);
		port_features[id].resource_size = 0;
	} else {
		dev_err(&binfo->pdev->dev, "the uafu feature header is mis-configured.\n");
		ret = -EINVAL;
	}

	return ret;
}

static int parse_feature_afu(struct build_feature_devs_info *binfo,
			     struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	if (!binfo->feature_dev) {
		dev_err(&binfo->pdev->dev, "this AFU does not belong to any FIU.\n");
		return -EINVAL;
	}

	switch (feature_dev_id_type(binfo->feature_dev)) {
	case PORT_ID:
		return parse_feature_port_afu(binfo, hdr);
	default:
		dev_info(&binfo->pdev->dev, "AFU belonging to FIU %s is not supported yet.\n",
			 binfo->feature_dev->name);
	}

	return 0;
}

static int parse_feature_fiu(struct build_feature_devs_info *binfo,
			     struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header header;
	struct feature_fiu_header *fiu_hdr, fiu_header;
	void __iomem *start = hdr;
	int ret;

pr_info("LOG: readq: header.csr = readq(hdr); ");
	header.csr = readq(hdr);

	switch (header.id) {
	case FEATURE_FIU_ID_FME:
		ret = parse_feature_fme(binfo, hdr);
		check_features_header(binfo->pdev, hdr, FPGA_DEVT_FME, 0);
		binfo->pfme_hdr = hdr;
		if (ret)
			return ret;
		break;
	case FEATURE_FIU_ID_PORT:
		ret = parse_feature_port(binfo, hdr);
		check_features_header(binfo->pdev, hdr, FPGA_DEVT_PORT, 0);
		enable_port_uafu(binfo, hdr);
		if (ret)
			return ret;
		break;
	default:
		dev_info(&binfo->pdev->dev, "FIU ID %d is not supported yet.\n",
			 header.id);
	}

	/* Check FIU's next_afu pointer to AFU */
	fiu_hdr = (struct feature_fiu_header *)(hdr + 1);
pr_info("LOG: readq: fiu_header.csr = readq(&fiu_hdr->csr); ");
	fiu_header.csr = readq(&fiu_hdr->csr);

	if (fiu_header.next_afu) {
		start += fiu_header.next_afu;
		return parse_feature_afu(binfo, start);
	}

	dev_info(&binfo->pdev->dev, "No AFUs detected on FIU %d\n",
		header.id);

	return 0;
}

static int parse_feature_private(struct build_feature_devs_info *binfo,
				 struct feature_header *hdr)
{

pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header header;

pr_info("LOG: readq: header.csr = readq(hdr); ");
	header.csr = readq(hdr);

	if (!binfo->feature_dev) {
		dev_err(&binfo->pdev->dev, "the private feature %x does not belong to any AFU.\n",
			header.id);
		return -EINVAL;
	}

	switch (feature_dev_id_type(binfo->feature_dev)) {
	case FME_ID:
		return parse_feature_fme_private(binfo, hdr);
	case PORT_ID:
		return parse_feature_port_private(binfo, hdr);
	default:
		dev_info(&binfo->pdev->dev, "private feature %x belonging to AFU %s is not supported yet.\n",
			 header.id, binfo->feature_dev->name);
	}
	return 0;
}

static int parse_feature(struct build_feature_devs_info *binfo,
			 struct feature_header *hdr)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header header;
	int ret = 0;
	
pr_info("LOG: readq: header.csr = readq(hdr); ");
	header.csr = readq(hdr);

	switch (header.type) {
	case FEATURE_TYPE_AFU:
		ret = parse_feature_afu(binfo, hdr);
		break;
	case FEATURE_TYPE_PRIVATE:
		ret = parse_feature_private(binfo, hdr);
		break;
	case FEATURE_TYPE_FIU:
		ret = parse_feature_fiu(binfo, hdr);
		break;
	default:
		dev_info(&binfo->pdev->dev,
			 "Feature Type %x is not supported.\n", hdr->type);
	};

	return ret;
}

static int
parse_feature_list(struct build_feature_devs_info *binfo, void __iomem *start)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_header *hdr, header;
	void __iomem *end = binfo->ioend;
	int ret = 0;

	for (; start < end; start += header.next_header_offset) {
		if (end - start < sizeof(*hdr)) {
			dev_err(&binfo->pdev->dev, "The region is too small to contain a feature.\n");
			ret =  -EINVAL;
			break;
		}
pr_info("LOG: call_stack: %s, for_loop", __func__);
		hdr = (struct feature_header *)start;
		ret = parse_feature(binfo, hdr);
		if (ret)
			break;

pr_info("LOG: readq: header.csr = readq(hdr); ");
		header.csr = readq(hdr);
		if (header.eol || !header.next_header_offset)
			break;
	}

	return ret;
}

static int parse_ports_from_fme(struct build_feature_devs_info *binfo)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_fme_header *fme_hdr;
	struct feature_fme_port port;
	int i = 0, ret = 0;

	if (binfo->pfme_hdr == NULL) {
		dev_info(&binfo->pdev->dev, "VF is detected.\n");
		return ret;
	}

	fme_hdr = binfo->pfme_hdr;

	do {
pr_info("LOG: readq: port.csr = readq(&fme_hdr->port[i]); ");
		port.csr = readq(&fme_hdr->port[i]);
		if (!port.port_implemented)
			break;

		ret = parse_switch_to(binfo, port.port_bar);
		if (ret)
			break;

		ret = parse_feature_list(binfo,
				binfo->ioaddr + port.port_offset);
		if (ret)
			break;
	} while (++i < MAX_FPGA_PORT_NUM);

	return ret;
}

static int create_init_drvdata(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata;

	drvdata = devm_kzalloc(&pdev->dev, sizeof(*drvdata), GFP_KERNEL);
	if (!drvdata)
		return -ENOMEM;

	drvdata->device_id = alloc_fpga_id(PARENT_ID, NULL);
	if (drvdata->device_id < 0) {
		int ret = drvdata->device_id;

		devm_kfree(&pdev->dev, drvdata);
		return ret;
	}

	mutex_init(&drvdata->lock);
	INIT_LIST_HEAD(&drvdata->port_dev_list);
	INIT_LIST_HEAD(&drvdata->regions);

	dev_set_drvdata(&pdev->dev, drvdata);
	return 0;
}

static void destroy_drvdata(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);

	if (drvdata->fme_dev) {
		/* fme device should be unregistered first. */
		WARN_ON(device_is_registered(drvdata->fme_dev));
		free_fpga_id(FME_ID, to_platform_device(drvdata->fme_dev)->id);
		put_device(drvdata->fme_dev);
	}

	cci_pci_remove_port_devs(pdev);
	cci_pci_release_regions(pdev);
	dev_set_drvdata(&pdev->dev, NULL);
	free_fpga_id(PARENT_ID, drvdata->device_id);
	devm_kfree(&pdev->dev, drvdata);
}

static struct class *fpga_class;

struct device *fpga_create_parent_dev(struct pci_dev *pdev, int id)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct device *dev;

	dev = device_create(fpga_class, &pdev->dev, MKDEV(0, 0), NULL,
			    "intel-fpga-dev.%d", id);
	if (IS_ERR(dev)) {
		dev_err(&pdev->dev, "create parent device failed %ld.\n",
			PTR_ERR(dev));
		return dev;
	}

	/*
	 * it is safe to modify some device fields here as:
	 *   a) the device is not attached to any bus, i.e, no driver
	 *      will match with this device;
	 *   b) it is a single device, i.e, no child will access its
	 *      resource.
	 */
	dev->dma_mask = pdev->dev.dma_mask;
	dev->dma_parms = pdev->dev.dma_parms;
	dev->coherent_dma_mask = pdev->dev.coherent_dma_mask;
	return dev;
}

static int cci_pci_create_feature_devs(struct pci_dev *pdev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pdev->dev);
	struct build_feature_devs_info *binfo;
	int ret;

	binfo = build_info_alloc_and_init(pdev);
	if (!binfo)
		return -ENOMEM;

	binfo->parent_dev = fpga_create_parent_dev(pdev, drvdata->device_id);
	if (IS_ERR(binfo->parent_dev)) {
		ret = PTR_ERR(binfo->parent_dev);
		goto free_binfo_exit;
	}

	ret = parse_start(binfo);
	if (ret)
		goto free_binfo_exit;

	ret = parse_feature_list(binfo, binfo->ioaddr);
	if (ret)
		goto free_binfo_exit;

	ret = parse_ports_from_fme(binfo);
	if (ret)
		goto free_binfo_exit;

	ret = build_info_commit_dev(binfo);
	if (ret)
		goto free_binfo_exit;

	/*
	 * everything is okay, reset ->parent_dev to stop it being
	 * freed by build_info_free()
	 */
	binfo->parent_dev = NULL;

free_binfo_exit:
	build_info_free(binfo);
	return ret;
}

/* PCI Device ID */
#define PCIe_DEVICE_ID_RCiEP0_MCP         0xBCBD
#define PCIe_DEVICE_ID_RCiEP0_SKX_P       0xBCC0
#define PCIe_DEVICE_ID_RCiEP0_DCP         0x09C4
#define PCIe_DEVICE_ID_DCP_0B2B           0x0B2B

/* VF Device */
#define PCIe_DEVICE_ID_VF_MCP             0xBCBF
#define PCIe_DEVICE_ID_VF_SKX_P           0xBCC1
#define PCIe_DEVICE_ID_VF_DCP             0x09C5
#define PCIe_DEVICE_ID_VF_DCP_0B2C        0x0B2C

static struct pci_device_id cci_pcie_id_tbl[] = {
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_RCiEP0_MCP),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_VF_MCP),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_RCiEP0_SKX_P),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_VF_SKX_P),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_RCiEP0_DCP),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_VF_DCP),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_DCP_0B2B),},
	{PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCIe_DEVICE_ID_VF_DCP_0B2C),},
	{0,}
};
MODULE_DEVICE_TABLE(pci, cci_pcie_id_tbl);

static void port_config_vf(struct device *fme_dev, int port_id, bool is_vf)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct feature_fme_header *fme_hdr;
	struct feature_fme_port port;
	int type = is_vf ? FME_AFU_ACCESS_VF : FME_AFU_ACCESS_PF;

	fme_hdr = get_feature_ioaddr_by_index(fme_dev,
		FME_FEATURE_ID_HEADER);

	WARN_ON(!fme_hdr);

pr_info("LOG: readq: port.csr = readq(&fme_hdr->port[port_id]); ");
	port.csr = readq(&fme_hdr->port[port_id]);
	WARN_ON(!port.port_implemented);

	port.afu_access_control = type;
pr_info("LOG: writeq(port.csr, &fme_hdr->port[port_id]);");
	writeq(port.csr, &fme_hdr->port[port_id]);
}

static int cci_pci_sriov_configure(struct pci_dev *pcidev, int num_vfs)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;
	int vf_ports = 0;
	struct device *fme_dev;
	struct cci_drvdata *drvdata = dev_get_drvdata(&pcidev->dev);
	struct list_head *port_list = &drvdata->port_dev_list;
	struct feature_platform_data *pdata;

	mutex_lock(&drvdata->lock);

	fme_dev = drvdata->fme_dev;
	WARN_ON(!fme_dev);

	if (drvdata->released_port_num < num_vfs) {
		ret = -EBUSY;
		goto unlock_exit;
	}

	if (!num_vfs)
		pci_disable_sriov(pcidev);

	list_for_each_entry(pdata, port_list, node) {
		int id = fpga_port_id(pdata->dev);

		if (device_is_registered(&pdata->dev->dev))
			continue;

		if (!num_vfs) {
			port_config_vf(fme_dev, id, false);
			dev_info(&pcidev->dev, "port_%d is turned to PF.\n", id);
			continue;
		}

		port_config_vf(fme_dev, id, true);
		dev_info(&pcidev->dev, "port_%d is turned to VF.\n", id);
		if (++vf_ports == num_vfs)
			break;
	}

	if (num_vfs) {
		ret = pci_enable_sriov(pcidev, num_vfs);
		if (ret) {
			list_for_each_entry(pdata, port_list, node) {
				int id = fpga_port_id(pdata->dev);

				if (device_is_registered(&pdata->dev->dev))
					continue;

				port_config_vf(fme_dev, id, false);
			}

			goto unlock_exit;
		}
	}

	ret = num_vfs;
unlock_exit:
	mutex_unlock(&drvdata->lock);
	return ret;
}

static int cci_pci_alloc_irq(struct pci_dev *pcidev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
	struct cci_drvdata *drvdata = dev_get_drvdata(&pcidev->dev);
	int i = 0;
#endif
	int nvec = pci_msix_vec_count(pcidev);
	int ret = 0;

	if (nvec <= 0) {
		dev_info(&pcidev->dev, "fpga interrupt not supported\n");
		return 0;
	}

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
	drvdata->msix_entries = devm_kmalloc(&pcidev->dev,
					     (sizeof(struct msix_entry) * nvec),
					     GFP_KERNEL);
	if (!drvdata->msix_entries)
		return -ENOMEM;

	for (i = 0; i < nvec; i++) {
		drvdata->msix_entries[i].entry = i;
		drvdata->msix_entries[i].vector = 0;
	}

	ret = pci_enable_msix_exact(pcidev, drvdata->msix_entries, nvec);
	if (ret) {
		devm_kfree(&pcidev->dev, drvdata->msix_entries);
		drvdata->msix_entries = NULL;
		return ret;
	}
#else
	ret = pci_alloc_irq_vectors(pcidev, nvec, nvec, PCI_IRQ_MSIX);
	if (ret < 0)
		return ret;
#endif

	return 0;
}

static void cci_pci_free_irq(struct pci_dev *pcidev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
#if LINUX_VERSION_CODE < KERNEL_VERSION(4,8,0)
	struct cci_drvdata *drvdata = dev_get_drvdata(&pcidev->dev);

	if (drvdata->msix_entries) {
		pci_disable_msix(pcidev);
		devm_kfree(&pcidev->dev, drvdata->msix_entries);
		drvdata->msix_entries = NULL;
	}
#else
	pci_free_irq_vectors(pcidev);
#endif
}

static
int cci_pci_probe(struct pci_dev *pcidev, const struct pci_device_id *pcidevid)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;

	ret = pci_enable_device(pcidev);
	if (ret < 0) {
		dev_err(&pcidev->dev, "Failed to enable device %d.\n", ret);
		goto exit;
	}

	ret = pci_enable_pcie_error_reporting(pcidev);
	if (ret && ret != -EINVAL)
		dev_info(&pcidev->dev, "PCIE AER unavailable %d.\n", ret);

	ret = pci_request_regions(pcidev, DRV_NAME);
	if (ret) {
		dev_err(&pcidev->dev, "Failed to request regions.\n");
		goto disable_error_report_exit;
	}

	pci_set_master(pcidev);
	pci_save_state(pcidev);

	if (!dma_set_mask(&pcidev->dev, DMA_BIT_MASK(64))) {
		dma_set_coherent_mask(&pcidev->dev, DMA_BIT_MASK(64));
	} else if (!dma_set_mask(&pcidev->dev, DMA_BIT_MASK(32))) {
		dma_set_coherent_mask(&pcidev->dev, DMA_BIT_MASK(32));
	} else {
		ret = -EIO;
		dev_err(&pcidev->dev, "No suitable DMA support available.\n");
		goto release_region_exit;
	}

	ret = create_init_drvdata(pcidev);
	if (ret)
		goto release_region_exit;

	ret = cci_pci_alloc_irq(pcidev);
	if (ret)
		goto destroy_drvdata_exit;

	ret = cci_pci_create_feature_devs(pcidev);
	if (ret)
		goto free_irq_exit;

	return 0;

free_irq_exit:
	cci_pci_free_irq(pcidev);
destroy_drvdata_exit:
	destroy_drvdata(pcidev);
release_region_exit:
	pci_release_regions(pcidev);
disable_error_report_exit:
	pci_disable_pcie_error_reporting(pcidev);
	pci_disable_device(pcidev);
exit:
	return ret;
}

static
void cci_pci_remove(struct pci_dev *pcidev)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	struct cci_drvdata *drvdata = dev_get_drvdata(&pcidev->dev);
	struct feature_platform_data *pdata;
	struct pid_info *pid;
	unsigned int timeout;

	mutex_lock(&drvdata->lock);
	list_for_each_entry(pdata, &drvdata->port_dev_list, node) {
		mutex_lock(&pdata->lock);
		list_for_each_entry(pid, &pdata->pid_list, node)
			kill_pid(pid->pid, SIGHUP, 1);
		pdata->unplug = 1;
		mutex_unlock(&pdata->lock);

		timeout = 10;	/* 10ms */
		while (timeout) {
			mutex_lock(&pdata->lock);
			if (!pdata->open_count) {
				mutex_unlock(&pdata->lock);
				break;
			}
			mutex_unlock(&pdata->lock);
			timeout--;
			mdelay(1);
		};

		if (!timeout)
			dev_err(&pcidev->dev, "unplug/remove device failed.\n");
	}
	mutex_unlock(&drvdata->lock);

	/* disable sriov. */
	if (dev_is_pf(&pcidev->dev))
		cci_pci_sriov_configure(pcidev, 0);

	remove_all_devs(pcidev);

	pci_disable_pcie_error_reporting(pcidev);

	cci_pci_free_irq(pcidev);
	destroy_drvdata(pcidev);
	pci_release_regions(pcidev);
	pci_disable_device(pcidev);
}

static struct pci_driver cci_pci_driver = {
	.name = DRV_NAME,
	.id_table = cci_pcie_id_tbl,
	.probe = cci_pci_probe,
	.remove = cci_pci_remove,
	.sriov_configure = cci_pci_sriov_configure
};

static int __init ccidrv_init(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	int ret;

	pr_info("Intel(R) FPGA PCIe Driver: Version %s\n", DRV_VERSION);

	fpga_ids_init();

	ret = fpga_chardev_init();
	if (ret)
		goto exit_ids;

	fpga_class = class_create(THIS_MODULE, "fpga");
	if (IS_ERR(fpga_class)) {
		ret = PTR_ERR(fpga_class);
		goto exit_chardev;
	}

	ret = pci_register_driver(&cci_pci_driver);
	if (ret) {
		class_destroy(fpga_class);
exit_chardev:
		fpga_chardev_uinit();
exit_ids:
		fpga_ids_destroy();
	}

	return ret;
}

static void __exit ccidrv_exit(void)
{
pr_info("LOG: call_stack: %s: %4d: %s", __FILE__, __LINE__, __func__);
	pci_unregister_driver(&cci_pci_driver);
	class_destroy(fpga_class);
	fpga_chardev_uinit();
	fpga_ids_destroy();
}

module_init(ccidrv_init);
module_exit(ccidrv_exit);

MODULE_DESCRIPTION("FPGA PCIe Device Drive");
MODULE_AUTHOR("Intel Corporation");
MODULE_LICENSE("GPL v2");
