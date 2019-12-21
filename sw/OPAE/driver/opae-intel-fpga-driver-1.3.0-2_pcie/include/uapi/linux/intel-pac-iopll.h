// SPDX-License-Identifier: GPL-2.0
/*
 * Header File for the IOPLL driver for the Intel PAC
 *
 * Copyright 2018 Intel Corporation, Inc.
 */

#ifndef _UAPI_INTEL_PAC_IOPLL_H
#define _UAPI_INTEL_PAC_IOPLL_H

/*
 * IOPLL Configuration support.
 */
#define  IOPLL_MAX_FREQ         800
#define  IOPLL_MIN_FREQ         1

struct pll_config {
	unsigned int pll_freq_khz;
	unsigned int pll_m;
	unsigned int pll_n;
	unsigned int pll_c1;
	unsigned int pll_c0;
	unsigned int pll_lf;
	unsigned int pll_cp;
	unsigned int pll_rc;
};

#endif /* _UAPI_INTEL_PAC_IOPLL_H */
