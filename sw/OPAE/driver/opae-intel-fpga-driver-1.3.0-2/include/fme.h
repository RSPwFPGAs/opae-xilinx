/*
 * FPGA Management Engine Drier Header
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Kang Luwei <luwei.kang@intel.com>
 *   Xiao Guangrong <guangrong.xiao@intel.com>
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

#ifndef __INTEL_FME_PR_H
#define __INTEL_FME_PR_H

#include "backport.h"
#define PERF_OBJ_ROOT_ID	(~0)

struct perf_object {
	/*
	 * instance id. PERF_OBJ_ROOT_ID indicates it is a parent
	 * object which counts performance counters for all instances.
	 */
	int id;

	/* the sysfs files are associated with this object. */
	const struct attribute_group **attr_groups;

	/* the fme feature device. */
	struct device *fme_dev;

	/*
	 * they are used to construct parent-children hierarchy.
	 *
	 * 'node' is used to link itself to parent's children list.
	 * 'children' is used to link its children objects together.
	 */
	struct list_head node;
	struct list_head children;

	struct kobject kobj;
};

struct fpga_fme {
	u8  port_id;
	u64 pr_err;
	u32 capability;
	int pr_bandwidth;
	bool pr_avx512;
	struct device *dev_err;
	struct perf_object *iperf_dev;
	struct perf_object *dperf_dev;
	struct feature_platform_data *pdata;
};

struct perf_obj_attributte {
	struct attribute attr;
	ssize_t (*show)(struct perf_object *pobj, char *buf);
	ssize_t (*store)(struct perf_object *pobj,
			 const char *buf, size_t n);
};

#define to_perf_obj_attr(_attr)					\
		container_of(_attr, struct perf_obj_attributte, attr)
#define to_perf_obj(_kobj)					\
		container_of(_kobj, struct perf_object, kobj)

#define PERF_OBJ_ATTR(_name, _filename, _mode, _show, _store)	\
struct perf_obj_attributte perf_obj_attr_##_name =		\
	__ATTR(_filename, _mode, _show, _store)
#define PERF_OBJ_ATTR_RW(_name)					\
	struct perf_obj_attributte perf_obj_attr_##_name = __ATTR_RW(_name)
#define PERF_OBJ_ATTR_RO(_name)					\
	struct perf_obj_attributte perf_obj_attr_##_name = __ATTR_RO(_name)
#define PERF_OBJ_ATTR_WO(_name)					\
	struct perf_obj_attributte perf_obj_attr_##_name = __ATTR_WO(_name)

extern struct feature_ops global_error_ops;
extern struct feature_ops pr_mgmt_ops;
extern struct feature_ops global_iperf_ops;
extern struct feature_ops global_dperf_ops;
#endif
