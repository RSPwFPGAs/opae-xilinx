/*
 * Backport kernel code for Intel FPGA driver
 *
 * Copyright 2016 Intel Corporation, Inc.
 *
 * Authors:
 *   Enno Luebbers <enno.luebbers@intel.com>
 *   Abelardo Jara-Berrocal <abelardo.jara-berrocal@intel.com>
 *   Tim Whisonant <tim.whisonant@intel.com>
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#ifndef __INTEL_BACKPORT_H
#define __INTEL_BACKPORT_H

#include <linux/version.h>
#include <linux/device.h>
#include <linux/stddef.h>
#include <linux/vfio.h> /* offsetofend in pre-4.1.0 kernels */
#include <linux/sysfs.h>
#include <linux/idr.h>
#include <linux/sched.h> /* current->mm in pre-4.0 kernels */

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,11,0)
#include <linux/sched/signal.h> /* rlimit function for 4.11 and later */
#endif

#include <linux/uuid.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(3,12,0)
#ifndef PAGE_ALIGNED
#define PAGE_ALIGNED(addr) IS_ALIGNED((unsigned long)(addr), PAGE_SIZE)
#endif

#define DEVICE_ATTR_RO(_name)						 \
	struct device_attribute dev_attr_##_name = __ATTR_RO(_name)

#define __ATTR_WO(_name) {						 \
		.attr = { .name = __stringify(_name), .mode = S_IWUSR }, \
		.store = _name##_store,					 \
	}

#define DEVICE_ATTR_WO(_name)						 \
	struct device_attribute dev_attr_##_name = __ATTR_WO(_name)

#define __ATTR_RW(_name) __ATTR(_name, (S_IWUSR | S_IRUGO),	         \
				_name##_show, _name##_store)

#define DEVICE_ATTR_RW(_name)						 \
	struct device_attribute dev_attr_##_name = __ATTR_RW(_name)

int sysfs_create_groups(struct kobject *kobj,
			const struct attribute_group **groups);

void sysfs_remove_groups(struct kobject *kobj,
			 const struct attribute_group **groups);

#endif /* LINUX_VERSION_CODE */

/* for ktime_get */
#if LINUX_VERSION_CODE <= KERNEL_VERSION(3,17,0)
#include <linux/hrtimer.h>
#else
#include <linux/timekeeping.h>
#endif /* LINUX_VERSION_CODE */

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,9,0)
#define ENABLE_AER 1
#endif /* LINUX_VERSION_CODE */

#if LINUX_VERSION_CODE < KERNEL_VERSION(3,12,0)
extern int sysfs_create_groups(struct kobject *kobj,
			       const struct attribute_group **groups);

extern void sysfs_remove_groups(struct kobject *kobj,
				const struct attribute_group **groups);
#endif /* LINUX_VERSION_CODE */

// TODO: Add external dependecy, introduced in recent kernel
extern int uuid_le_to_bin(const char *uuid, uuid_le *u);

/* backwards compatibility, don't use in new code */

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,13,0)
#define GUID_INIT_BE(a, b, c, d0, d1, d2, d3, d4, d5, d6, d7)		\
	((guid_t)							\
	 {{ ((a) >> 24) & 0xff, ((a) >> 16) & 0xff, ((a) >> 8) & 0xff, (a) & 0xff, \
	    ((b) >> 8) & 0xff, (b) & 0xff,				\
	    ((c) >> 8) & 0xff, (c) & 0xff,				\
	    (d0), (d1), (d2), (d3), (d4), (d5), (d6), (d7) }})		\

typedef guid_t uuid_be;
#define UUID_BE(a, b, c, d0, d1, d2, d3, d4, d5, d6, d7)	\
	GUID_INIT_BE(a, b, c, d0, d1, d2, d3, d4, d5, d6, d7)	\

#define NULL_UUID_BE							\
	UUID_BE(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00,	\
		0x00, 0x00, 0x00, 0x00)
#endif

#ifndef RHEL_RELEASE
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,14,0)
#ifdef CONFIG_PCI_MSI

int pci_msix_vec_count(struct pci_dev *dev);

int pci_enable_msix_range(struct pci_dev *dev, struct msix_entry *entries,
			 int minvec, int maxvec);

static inline int pci_enable_msix_exact(struct pci_dev *dev,
					struct msix_entry *entries, int nvec)
{
	int rc = pci_enable_msix_range(dev, entries, nvec, nvec);
	if (rc < 0)
		return rc;
	return 0;
}

#else

static inline int pci_msix_vec_count(struct pci_dev *dev)
{ return -ENOSYS; }

static inline int pci_enable_msix_exact(struct pci_dev *dev,
					struct msix_entry *entries, int nvec)
{ return -ENOSYS; }

#endif /* CONFIG_PCI_MSI */
#endif /* LINUX_VERSION_CODE */
#endif /* RHEL_RELEASE */

#ifndef u64_to_user_ptr
#define u64_to_user_ptr(x) (		\
{					\
	typecheck(u64, x);		\
	(void __user *)(uintptr_t)x;	\
}					\
)
#endif

#endif /* __INTEL_BACKPORT_H */
