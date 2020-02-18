/* SPDX-License-Identifier: GPL-2.0 */
/*
 * User APIs for Avalon Memory Mapped Interface to BMC
 *
 * Copyright (C) 2018 Intel Corporation. All rights reserved.
 */

#ifndef _UAPI_LINUX_AVMMI_BMC_H
#define _UAPI_LINUX_AVMMI_BMC_H

#include <linux/types.h>
#include <linux/ioctl.h>

#define AVMMI_BMC_MAGIC 0x76

struct avmmi_bmc_xact {
	__u32 argsz;		/* Structure length */
	__u16 txlen;
	__u16 rxlen;
	__u64 txbuf;
	__u64 rxbuf;
};

#define AVMMI_BMC_XACT _IOWR(AVMMI_BMC_MAGIC, 0, struct avmmi_bmc_xact)

#endif
