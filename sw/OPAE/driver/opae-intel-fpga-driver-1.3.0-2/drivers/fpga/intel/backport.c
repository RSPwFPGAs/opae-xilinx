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

#include "backport.h"

#if LINUX_VERSION_CODE < KERNEL_VERSION(3,12,0)
int sysfs_create_groups(struct kobject *kobj,
			       const struct attribute_group **groups)
{
	int error = 0;
	int i;

	if (!groups)
		return 0;

	for (i = 0; groups[i]; i++) {
		error = sysfs_create_group(kobj, groups[i]);
		if (error) {
			while (--i >= 0)
				sysfs_remove_group(kobj, groups[i]);
			break;
		}
	}
	return error;
}

void sysfs_remove_groups(struct kobject *kobj,
				const struct attribute_group **groups)
{
	int i;

	if (!groups)
		return;
	for (i = 0; groups[i]; i++)
		sysfs_remove_group(kobj, groups[i]);
}

#endif /* LINUX_VERSION_CODE */


#ifndef RHEL_RELEASE
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,14,0)
#ifdef CONFIG_PCI_MSI

#ifndef msix_table_size
#define msix_table_size(flags) ((flags & PCI_MSIX_FLAGS_QSIZE) + 1)
#endif /* msix_table_size */

int pci_msix_vec_count(struct pci_dev *dev)
{
	u16 control;

	if (!dev->msix_cap)
		return -EINVAL;

	pci_read_config_word(dev, dev->msix_cap + PCI_MSIX_FLAGS, &control);
	return msix_table_size(control);
}
EXPORT_SYMBOL(pci_msix_vec_count);

int pci_enable_msix_range(struct pci_dev *dev, struct msix_entry *entries,
			 int minvec, int maxvec)
{
	int nvec = maxvec;
	int rc;

	if (maxvec < minvec)
		return -ERANGE;

	do {
		rc = pci_enable_msix(dev, entries, nvec);
		if (rc < 0) {
			return rc;
		} else if (rc > 0) {
			if (rc < minvec)
				return -ENOSPC;
			nvec = rc;
		}

	} while (rc);

	return nvec;
}
EXPORT_SYMBOL(pci_enable_msix_range);

#endif /* CONFIG_PCI_MSI */
#endif /* LINUX_VERSION_CODE */
#endif /* RHEL_RELEASE */
