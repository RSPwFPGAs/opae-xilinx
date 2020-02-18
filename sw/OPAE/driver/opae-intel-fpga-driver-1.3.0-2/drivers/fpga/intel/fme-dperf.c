/*
 * Driver for FPGA Global Performance
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

#include "feature-dev.h"
#include "fme.h"

static ssize_t perf_obj_attr_show(struct kobject *kobj,
				  struct attribute *__attr, char *buf)
{
	struct perf_obj_attributte *attr = to_perf_obj_attr(__attr);
	struct perf_object *pobj = to_perf_obj(kobj);
	ssize_t ret = -EIO;

	if (attr->show)
		ret = attr->show(pobj, buf);
	return ret;
}

static ssize_t perf_obj_attr_store(struct kobject *kobj,
				   struct attribute *__attr,
				   const char *buf, size_t n)
{
	struct perf_obj_attributte *attr = to_perf_obj_attr(__attr);
	struct perf_object *pobj = to_perf_obj(kobj);
	ssize_t ret = -EIO;

	if (attr->store)
		ret = attr->store(pobj, buf, n);
	return ret;
}

static const struct sysfs_ops perf_obj_sysfs_ops = {
	.show = perf_obj_attr_show,
	.store = perf_obj_attr_store,
};

static void perf_obj_release(struct kobject *kobj)
{
	kfree(to_perf_obj(kobj));
}

static struct kobj_type perf_obj_ktype = {
	.sysfs_ops = &perf_obj_sysfs_ops,
	.release = perf_obj_release,
};

static ssize_t revision_show(struct perf_object *pobj, char *buf)
{
	struct feature_fme_dperf *dperf;
	struct feature_header header;

	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);
	header.csr = readq(&dperf->header);

	return scnprintf(buf, PAGE_SIZE, "%d\n", header.revision);
}
static PERF_OBJ_ATTR_RO(revision);

static ssize_t clock_show(struct perf_object *pobj, char *buf)
{
	struct feature_fme_dperf *dperf;
	struct feature_fme_dfpmon_clk_ctr clk;

	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);
	clk.afu_interf_clock = readq(&dperf->clk);

	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", clk.afu_interf_clock);
}
static PERF_OBJ_ATTR_RO(clock);

static struct attribute *clock_attrs[] = {
	&perf_obj_attr_revision.attr,
	&perf_obj_attr_clock.attr,
	NULL,
};

static struct attribute_group clock_attr_group = {
	.attrs = clock_attrs,
};

#define DPERF_TIMEOUT	30

static const struct attribute_group *perf_dev_attr_groups[] = {
	&clock_attr_group,
	NULL,
};

static bool fabric_pobj_is_enabled(struct perf_object *pobj,
				   struct feature_fme_dperf *dperf)
{
	struct feature_fme_dfpmon_fab_ctl ctl;

	ctl.csr = readq(&dperf->fab_ctl);

	if (ctl.port_filter == FAB_DISABLE_FILTER)
		return pobj->id == PERF_OBJ_ROOT_ID;

	return pobj->id == ctl.port_id;
}

static ssize_t read_fabric_counter(struct perf_object *pobj,
				   enum dperf_fab_events fab_event, char *buf)
{
	struct feature_platform_data *pdata = dev_get_platdata(pobj->fme_dev);
	struct feature_fme_dfpmon_fab_ctl ctl;
	struct feature_fme_dfpmon_fab_ctr ctr;
	struct feature_fme_dperf *dperf;
	u64 counter = 0;

	mutex_lock(&pdata->lock);
	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);

	/* if it is disabled, force the counter to return zero. */
	if (!fabric_pobj_is_enabled(pobj, dperf))
		goto exit;

	ctl.csr = readq(&dperf->fab_ctl);
	ctl.fab_evtcode = fab_event;
	writeq(ctl.csr, &dperf->fab_ctl);

	ctr.event_code = fab_event;

	if (fpga_wait_register_field(event_code, ctr,
				     &dperf->fab_ctr, DPERF_TIMEOUT, 1)) {
		dev_err(pobj->fme_dev, "timeout, unmatched VTd event type in counter registers.\n");
		mutex_unlock(&pdata->lock);
		return -ETIMEDOUT;
	}

	ctr.csr = readq(&dperf->fab_ctr);
	counter = ctr.fab_cnt;
exit:
	mutex_unlock(&pdata->lock);
	return scnprintf(buf, PAGE_SIZE, "0x%llx\n", counter);
}

#define FAB_SHOW(name, event)						\
static ssize_t name##_show(struct perf_object *pobj, char *buf)		\
{									\
	return read_fabric_counter(pobj, event, buf);			\
}									\
static PERF_OBJ_ATTR_RO(name)

FAB_SHOW(pcie0_read, DPERF_FAB_PCIE0_RD);
FAB_SHOW(pcie0_write, DPERF_FAB_PCIE0_WR);
FAB_SHOW(mmio_read, DPERF_FAB_MMIO_RD);
FAB_SHOW(mmio_write, DPERF_FAB_MMIO_WR);

static ssize_t fab_enable_show(struct perf_object *pobj, char *buf)
{
	struct feature_fme_dperf *dperf;
	int status;

	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);

	status = fabric_pobj_is_enabled(pobj, dperf);
	return scnprintf(buf, PAGE_SIZE, "%d\n", status);
}

/*
 * If enable one port or all port event counter in fabric, other
 * fabric event counter originally enabled will be disable automatically.
 */
static ssize_t fab_enable_store(struct perf_object *pobj,
				const char *buf, size_t n)
{
	struct feature_platform_data *pdata  = dev_get_platdata(pobj->fme_dev);
	struct feature_fme_dfpmon_fab_ctl ctl;
	struct feature_fme_dperf *dperf;
	bool state;

	if (strtobool(buf, &state))
		return -EINVAL;

	if (!state)
		return -EINVAL;

	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);

	/* if it is already enabled. */
	if (fabric_pobj_is_enabled(pobj, dperf))
		return n;

	mutex_lock(&pdata->lock);
	ctl.csr = readq(&dperf->fab_ctl);
	if (pobj->id == PERF_OBJ_ROOT_ID)
		ctl.port_filter = FAB_DISABLE_FILTER;
	else {
		ctl.port_filter = FAB_ENABLE_FILTER;
		ctl.port_id = pobj->id;
	}

	writeq(ctl.csr, &dperf->fab_ctl);
	mutex_unlock(&pdata->lock);

	return n;
}

static PERF_OBJ_ATTR(fab_enable, enable, 0644, fab_enable_show,
		     fab_enable_store);

static struct attribute *fabric_attrs[] = {
	&perf_obj_attr_pcie0_read.attr,
	&perf_obj_attr_pcie0_write.attr,
	&perf_obj_attr_mmio_read.attr,
	&perf_obj_attr_mmio_write.attr,
	&perf_obj_attr_fab_enable.attr,
	NULL,
};

static struct attribute_group fabric_attr_group = {
	.attrs = fabric_attrs,
};

static const struct attribute_group *fabric_attr_groups[] = {
	&fabric_attr_group,
	NULL,
};

static ssize_t fab_freeze_show(struct perf_object *pobj, char *buf)
{
	struct feature_fme_dperf *dperf;
	struct feature_fme_dfpmon_fab_ctl ctl;

	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);
	ctl.csr = readq(&dperf->fab_ctl);
	return scnprintf(buf, PAGE_SIZE, "%d\n", ctl.freeze);
}

static ssize_t fab_freeze_store(struct perf_object *pobj,
				const char *buf, size_t n)
{
	struct feature_platform_data *pdata = dev_get_platdata(pobj->fme_dev);
	struct feature_fme_dperf *dperf;
	struct feature_fme_dfpmon_fab_ctl ctl;
	bool state;

	if (strtobool(buf, &state))
		return -EINVAL;

	mutex_lock(&pdata->lock);
	dperf = get_feature_ioaddr_by_index(pobj->fme_dev,
					    FME_FEATURE_ID_GLOBAL_DPERF);
	ctl.csr = readq(&dperf->fab_ctl);
	ctl.freeze = state;
	writeq(ctl.csr, &dperf->fab_ctl);
	mutex_unlock(&pdata->lock);

	return n;
}

static PERF_OBJ_ATTR(fab_freeze, freeze, 0644, fab_freeze_show,
		     fab_freeze_store);

static struct attribute *fabric_top_attrs[] = {
	&perf_obj_attr_fab_freeze.attr,
	NULL,
};

static struct attribute_group fabric_top_attr_group = {
	.attrs = fabric_top_attrs,
};

static const struct attribute_group *fabric_top_attr_groups[] = {
	&fabric_attr_group,
	&fabric_top_attr_group,
	NULL,
};

static struct perf_object *
create_perf_obj(struct device *fme_dev, struct kobject *parent, int id,
		const struct attribute_group **groups, const char *name)
{
	struct perf_object *pobj;
	int ret;

	pobj = kzalloc(sizeof(*pobj), GFP_KERNEL);
	if (!pobj)
		return ERR_PTR(-ENOMEM);

	pobj->id = id;
	pobj->fme_dev = fme_dev;
	pobj->attr_groups = groups;
	INIT_LIST_HEAD(&pobj->node);
	INIT_LIST_HEAD(&pobj->children);

	if (id != PERF_OBJ_ROOT_ID)
		ret = kobject_init_and_add(&pobj->kobj, &perf_obj_ktype,
					   parent, "%s%d", name, id);
	else
		ret = kobject_init_and_add(&pobj->kobj, &perf_obj_ktype,
					   parent, "%s", name);
	if (ret)
		goto put_exit;

	if (pobj->attr_groups) {
		ret = sysfs_create_groups(&pobj->kobj, pobj->attr_groups);
		if (ret)
			goto put_exit;
	}

	return pobj;

put_exit:
	kobject_put(&pobj->kobj);
	return ERR_PTR(ret);
}

static void destroy_perf_obj(struct perf_object *pobj)
{
	struct perf_object *obj, *obj_tmp;

	list_for_each_entry_safe(obj, obj_tmp, &pobj->children, node)
		destroy_perf_obj(obj);

	list_del(&pobj->node);
	if (pobj->attr_groups)
		sysfs_remove_groups(&pobj->kobj, pobj->attr_groups);
	kobject_put(&pobj->kobj);
}

#define PERF_MAX_PORT_NUM	1

static int create_perf_fabric_obj(struct perf_object *perf_dev)
{
	struct perf_object *pobj;
	int i;

	pobj = create_perf_obj(perf_dev->fme_dev, &perf_dev->kobj,
			       PERF_OBJ_ROOT_ID, fabric_top_attr_groups,
			       "fabric");
	if (IS_ERR(pobj))
		return PTR_ERR(pobj);

	list_add(&pobj->node, &perf_dev->children);

	for (i = 0; i < PERF_MAX_PORT_NUM; i++) {
		struct perf_object *obj;

		obj = create_perf_obj(perf_dev->fme_dev, &pobj->kobj, i,
				      fabric_attr_groups, "port");
		if (IS_ERR(obj))
			return PTR_ERR(obj);

		list_add(&obj->node, &pobj->children);
	}

	return 0;
}

static struct perf_object *create_perf_dev(struct platform_device *pdev)
{
	return create_perf_obj(&pdev->dev, &pdev->dev.kobj,
			   PERF_OBJ_ROOT_ID, perf_dev_attr_groups, "dperf");
}

static int fme_dperf_init(struct platform_device *pdev, struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;
	struct perf_object *perf_dev;
	int ret;

	perf_dev = create_perf_dev(pdev);
	if (IS_ERR(perf_dev))
		return PTR_ERR(perf_dev);

	ret = create_perf_fabric_obj(perf_dev);
	if (ret) {
		destroy_perf_obj(perf_dev);
		return ret;
	}

	fme = fpga_pdata_get_private(pdata);
	fme->dperf_dev = perf_dev;
	return 0;
}

static void
fme_dperf_uinit(struct platform_device *pdev, struct feature *feature)
{
	struct feature_platform_data *pdata = dev_get_platdata(&pdev->dev);
	struct fpga_fme *fme;

	fme = fpga_pdata_get_private(pdata);
	destroy_perf_obj(fme->dperf_dev);
	fme->dperf_dev = NULL;
}

struct feature_ops global_dperf_ops = {
	.init = fme_dperf_init,
	.uinit = fme_dperf_uinit,
};
