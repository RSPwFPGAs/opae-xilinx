// SPDX-License-Identifier: GPL-2.0
/*
 * Driver for the IOPLL of the Intel Programmable Acceleration Card
 * (PAC). This driver allows user code to read and to set the optimal
 * clock frequency to drive logic for a given Accelerator Functional
 * Unit (AFU).
 *
 * Copyright (C) 2018 Intel Corporation, Inc.
 */

#include <linux/module.h>
#include <linux/iopoll-mod.h>
#include <linux/platform_device.h>
#include <uapi/linux/intel-pac-iopll.h>

#include "backport.h"
#include "pac-iopll.h"

#define IOPLL_WRITE_POLL_INVL_US	10	/* Write poll interval */
#define IOPLL_WRITE_POLL_TIMEOUT_US	1000000	/* Write poll timeout */

/*
 * Control and status registers for the IOPLL
 * https://www.altera.com/en_US/pdfs/literature/hb/stratix-10/ug-s10-clkpll.pdf
 * Section 7.2
 */
#define CFG_PLL_M_HIGH_SHIFT		8
#define CFG_PLL_M_BYPASS_EN_SHIFT	16
#define CFG_PLL_M_EVEN_DUTY_EN_SHIFT	17
#define CFG_PLL_M_EVEN_DUTY_EN_MASK	0x01
#define PLL_M_HIGH_ADDR			0x104
#define PLL_M_HIGH_MASK			0xFF
#define PLL_M_LOW_ADDR			0x107
#define PLL_M_LOW_MASK			0xFF
#define PLL_M_BYPASS_EN_ADDR		0x105
#define PLL_M_BYPASS_EN_MASK		0x01
#define PLL_M_EVEN_DUTY_EN_ADDR		0x106
#define PLL_M_EVEN_DUTY_EN_SHIFT	7

#define CFG_PLL_N_HIGH_SHIFT		8
#define CFG_PLL_N_BYPASS_EN_SHIFT	16
#define CFG_PLL_N_EVEN_DUTY_EN_SHIFT	17
#define CFG_PLL_N_EVEN_DUTY_EN_MASK	0x01
#define PLL_N_HIGH_ADDR			0x100
#define PLL_N_HIGH_MASK			0xFF
#define PLL_N_LOW_ADDR			0x102
#define PLL_N_LOW_MASK			0xFF
#define PLL_N_BYPASS_EN_ADDR		0x101 /* Same as PLL_CP1_ADDR */
#define PLL_N_BYPASS_EN_MASK		0x01
#define PLL_N_EVEN_DUTY_EN_ADDR		0x101 /* Same as PLL_CP1_ADDR */
#define PLL_N_EVEN_DUTY_EN_SHIFT	7

#define CFG_PLL_C0_HIGH_SHIFT		8
#define CFG_PLL_C0_BYPASS_EN_SHIFT	16
#define CFG_PLL_C0_EVEN_DUTY_EN_SHIFT	17
#define CFG_PLL_C0_EVEN_DUTY_EN_MASK	0x01
#define PLL_C0_HIGH_ADDR		0x11b
#define PLL_C0_HIGH_MASK		0xFF
#define PLL_C0_LOW_ADDR			0x11e
#define PLL_C0_LOW_MASK			0xFF
#define PLL_C0_BYPASS_EN_ADDR		0x11c
#define PLL_C0_BYPASS_EN_MASK		0x01
#define PLL_C0_EVEN_DUTY_EN_ADDR	0x11d
#define PLL_C0_EVEN_DUTY_EN_SHIFT	7

#define CFG_PLL_C1_HIGH_SHIFT		8
#define CFG_PLL_C1_BYPASS_EN_SHIFT	16
#define CFG_PLL_C1_EVEN_DUTY_EN_SHIFT	17
#define CFG_PLL_C1_EVEN_DUTY_EN_MASK	0x01
#define PLL_C1_HIGH_ADDR		0x11f
#define PLL_C1_HIGH_MASK		0xFF
#define PLL_C1_LOW_ADDR			0x122
#define PLL_C1_LOW_MASK			0xFF
#define PLL_C1_BYPASS_EN_ADDR		0x120
#define PLL_C1_BYPASS_EN_MASK		0x01
#define PLL_C1_EVEN_DUTY_EN_ADDR	0x121
#define PLL_C1_EVEN_DUTY_EN_SHIFT	7

#define CFG_PLL_CP1_MASK		0x07
#define PLL_CP1_ADDR			0x101 /* Same as PLL_N_BYPASS_EN_ADDR */
#define PLL_CP1_SHIFT			4

#define CFG_PLL_CP2_SHIFT		3
#define CFG_PLL_CP2_MASK		0x07
#define PLL_CP2_ADDR			0x10d
#define PLL_CP2_SHIFT			5

#define CFG_PLL_LF_SHIFT		6
#define CFG_PLL_LF_MASK			0xFF
#define PLL_LF_ADDR			0x10a
#define PLL_LF_SHIFT			3

#define CFG_PLL_RC_MASK			0x03
#define PLL_RC_SHIFT			1

#define PLL_REQUEST_CAL_ADDR		0x149
#define PLL_REQUEST_CALIBRATION		BIT(6)

#define PLL_ENABLE_CAL_ADDR		0x14a
#define PLL_ENABLE_CALIBRATION		0x03

#define IOPLL_MEASURE_LOW		0
#define IOPLL_MEASURE_HIGH		1
#define IOPLL_MEASURE_DELAY_MS		4
#define IOPLL_RESET_DELAY_MS		1
#define IOPLL_CAL_DELAY_MS		1
#define	FREQ_IN_KHZ(freq)		((freq) * 10)

struct iopll_freq_cmd0 {
	union {
		u64 csr;
		struct {
			u32 data:32;		/* IOPLL CMD write data */
			u16 address:10;		/* IOPLL CMD address */
			u8 rsvd1:2;		/* Reserved */
			u8 do_write:1;		/* IOPLL Write Operation */
			u8 rsvd2:3;		/* Reserved */
			u8 sequence_no:2;	/* IOPLL sequence number */
			u16 rsvd3:2;		/* Reserved */
			u8 reset_n:1;		/* mmmach machine reset_n */
			u16 rsvd4:3;		/* Reserved */
			u8 management_reset:1;	/* IOPLL management reset */
			u8 iopll_reset:1;	/* IOPLL reset */
			u16 rsvd5:6;		/* Reserved */
		};
	};
};

struct iopll_freq_cmd1 {
	union {
		u64 csr;
		struct {
			u32 rsvd1:32;		/* Reserved */
			u8 clk_measure:1;	/* Measure clk: 0=1x, 1=2x */
			u32 rsvd2:31;		/* Reserved */
		};
	};
};

struct iopll_freq_sts0 {
	union {
		u64 csr;
		struct {
			u32 data:32;		/* IOPLL CMD write data */
			u16 address:10;		/* IOPLL CMD address */
			u8 rsvd1:2;		/* Reserved */
			u8 do_write:1;		/* IOPLL Write Operation */
			u8 rsvd2:3;		/* Reserved */
			u8 sequence_no:2;	/* IOPLL sequence number */
			u16 rsvd3:2;		/* Reserved */
			u8 reset_n:1;		/* mmmach machine reset_n */
			u8 rsvd4:3;		/* Reserved */
			u8 management_reset:1;	/* IOPLL management reset */
			u8 iopll_reset:1;	/* IOPLL reset */
			u8 rsvd5:2;		/* Reserved */
			u8 locked:1;		/* IOPLL locked */
			u8 rsvd6:2;		/* Reserved */
			u8 mmmach_error:1;	/* mmmach error */
		};
	};
};

struct iopll_freq_sts1 {
	union {
		u64 csr;
		struct {
			u32 frequency:17;	/* frequency in 10 kHz units */
			u16 rsvd1:15;		/* Reserved */
			u8 clk_measure:1;	/* Measure clk: 0=1x, 1=2x */
			u32 rsvd2:27;		/* Reserved */
			u8 version:4;		/* User clock version */
		};
	};
};

struct port_iopll_regs {
	struct iopll_freq_cmd0 iopll_cmd0;
	struct iopll_freq_cmd1 iopll_cmd1;
	struct iopll_freq_sts0 iopll_sts0;
	struct iopll_freq_sts1 iopll_sts1;
};

struct pac_iopll {
	void __iomem *csr_base;
	struct device *dev;
	struct mutex iopll_mutex;	/* Serialize access to iopll */
};

static int iopll_reset(struct pac_iopll *iopll)
{
	struct port_iopll_regs *iopll_regs = iopll->csr_base;
	struct iopll_freq_cmd0 uclk_freq_cmd0 = { { 0 } };
	struct iopll_freq_sts0 uclk_freq_sts0;

	dev_dbg(iopll->dev, "Reset IOPLL\n");

	/* Assert all resets */
	uclk_freq_cmd0.iopll_reset = 1;
	uclk_freq_cmd0.management_reset = 1;
	uclk_freq_cmd0.reset_n = 0;
	writeq(uclk_freq_cmd0.csr, &iopll_regs->iopll_cmd0);

	msleep(IOPLL_RESET_DELAY_MS);

	/* De-assert the iopll reset only */
	uclk_freq_cmd0.iopll_reset = 0;
	writeq(uclk_freq_cmd0.csr, &iopll_regs->iopll_cmd0);

	msleep(IOPLL_RESET_DELAY_MS);

	/* De-assert the remaining resets */
	uclk_freq_cmd0.management_reset = 0;
	uclk_freq_cmd0.reset_n = 1;
	writeq(uclk_freq_cmd0.csr, &iopll_regs->iopll_cmd0);

	msleep(IOPLL_RESET_DELAY_MS);

	uclk_freq_sts0.csr = readq(&iopll_regs->iopll_sts0);

	if (!uclk_freq_sts0.locked) {
		dev_err(iopll->dev, "IOPLL NOT locked after reset\n");
		return -EBUSY;
	}

	return 0;
}

static int iopll_read_freq(struct pac_iopll *iopll, u8 clock_sel, u32 *freq)
{
	struct port_iopll_regs *iopll_regs = iopll->csr_base;
	struct iopll_freq_cmd1 uclk_freq_cmd1 = { { 0 } };
	struct iopll_freq_sts1 uclk_freq_sts1;
	struct iopll_freq_sts0 uclk_freq_sts0;

	dev_dbg(iopll->dev, "Read Frequency: %d\n", clock_sel);

	uclk_freq_sts0.csr = readq(&iopll_regs->iopll_sts0);
	if (!uclk_freq_sts0.locked) {
		dev_err(iopll->dev, "IOPLL is NOT locked!\n");
		return -EBUSY;
	}

	uclk_freq_cmd1.clk_measure = clock_sel;
	writeq(uclk_freq_cmd1.csr, &iopll_regs->iopll_cmd1);

	msleep(IOPLL_MEASURE_DELAY_MS);

	uclk_freq_sts1.csr = readq(&iopll_regs->iopll_sts1);

	*freq = uclk_freq_sts1.frequency;
	return 0;
}

static int iopll_write(struct pac_iopll *iopll, u16 address, u32 data, u8 seq)
{
	struct port_iopll_regs *iopll_regs = iopll->csr_base;
	struct iopll_freq_cmd0 uclk_freq_cmd0 = { { 0 } };
	struct iopll_freq_sts0 uclk_freq_sts0;
	int ret;

	seq &= 0x3;

	uclk_freq_cmd0.data = data;
	uclk_freq_cmd0.address = address;
	uclk_freq_cmd0.do_write = 1;
	uclk_freq_cmd0.sequence_no = seq;
	uclk_freq_cmd0.reset_n = 1;
	uclk_freq_cmd0.management_reset = 0;
	uclk_freq_cmd0.iopll_reset = 0;
	writeq(uclk_freq_cmd0.csr, &iopll_regs->iopll_cmd0);

	ret = readq_poll_timeout(&iopll_regs->iopll_sts0.csr,
				 uclk_freq_sts0.csr,
				 uclk_freq_sts0.sequence_no == seq,
				 IOPLL_WRITE_POLL_INVL_US,
				 IOPLL_WRITE_POLL_TIMEOUT_US);
	if (ret)
		dev_err(iopll->dev, "Timeout on IOPLL write\n");

	return ret;
}

static int iopll_read(struct pac_iopll *iopll, u16 address, u32 *retval, u8 seq)
{
	struct port_iopll_regs *iopll_regs = iopll->csr_base;
	struct iopll_freq_cmd0 uclk_freq_cmd0;
	struct iopll_freq_sts0 uclk_freq_sts0;
	int ret;

	seq &= 0x3;

	uclk_freq_cmd0.data = 0;
	uclk_freq_cmd0.address = address;
	uclk_freq_cmd0.do_write = 0;
	uclk_freq_cmd0.sequence_no = seq;
	uclk_freq_cmd0.reset_n = 1;
	uclk_freq_cmd0.management_reset = 0;
	uclk_freq_cmd0.iopll_reset = 0;
	writeq(uclk_freq_cmd0.csr, &iopll_regs->iopll_cmd0);

	/* Poll for the expected state of acknowlege bit */
	ret = readq_poll_timeout(&iopll_regs->iopll_sts0.csr,
				 uclk_freq_sts0.csr,
				 uclk_freq_sts0.sequence_no == seq,
				 IOPLL_WRITE_POLL_INVL_US,
				 IOPLL_WRITE_POLL_TIMEOUT_US);

	if (ret)
		dev_err(iopll->dev, "Timeout on IOPLL read\n");
	else
		*retval = uclk_freq_sts0.data;

	return ret;
}

static int iopll_m_write(struct pac_iopll *iopll, u32 cfg_pll_m, u8 *seq)
{
	int ret;

	ret = iopll_write(iopll, PLL_M_HIGH_ADDR,
			  (cfg_pll_m >> CFG_PLL_M_HIGH_SHIFT) & PLL_M_HIGH_MASK,
			  (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_M_LOW_ADDR, cfg_pll_m & PLL_M_LOW_MASK,
			  (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_M_BYPASS_EN_ADDR,
			  (cfg_pll_m >> CFG_PLL_M_BYPASS_EN_SHIFT) &
			  PLL_M_BYPASS_EN_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_M_EVEN_DUTY_EN_ADDR,
			  ((cfg_pll_m >> CFG_PLL_M_EVEN_DUTY_EN_SHIFT) &
			  CFG_PLL_M_EVEN_DUTY_EN_MASK) <<
			  PLL_M_EVEN_DUTY_EN_SHIFT, (*seq)++);

done:
	return ret;
}

static int iopll_n_write(struct pac_iopll *iopll, u32 cfg_pll_n,
			 u32 cfg_pll_cp, u8 *seq)
{
	int ret;

	ret = iopll_write(iopll, PLL_N_HIGH_ADDR,
			  (cfg_pll_n >> CFG_PLL_N_HIGH_SHIFT) & PLL_N_HIGH_MASK,
			  (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_N_LOW_ADDR,
			  cfg_pll_n & PLL_N_LOW_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_N_BYPASS_EN_ADDR,
			  (((cfg_pll_n >> CFG_PLL_N_EVEN_DUTY_EN_SHIFT) &
			  CFG_PLL_N_EVEN_DUTY_EN_MASK) <<
			  PLL_N_EVEN_DUTY_EN_SHIFT) |
			  ((cfg_pll_cp & CFG_PLL_CP1_MASK) << PLL_CP1_SHIFT) |
			  ((cfg_pll_n >> CFG_PLL_N_BYPASS_EN_SHIFT) &
			  PLL_N_BYPASS_EN_MASK), (*seq)++);

done:
	return ret;
}

static int iopll_c0_write(struct pac_iopll *iopll, u32 cfg_pll_c0, u8 *seq)
{
	int ret;

	ret = iopll_write(iopll, PLL_C0_HIGH_ADDR,
			  (cfg_pll_c0 >> CFG_PLL_C0_HIGH_SHIFT) &
			  PLL_C0_HIGH_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C0_LOW_ADDR,
			  cfg_pll_c0 & PLL_C0_LOW_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C0_BYPASS_EN_ADDR,
			  (cfg_pll_c0 >> CFG_PLL_C0_BYPASS_EN_SHIFT) &
			  PLL_C0_BYPASS_EN_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C0_EVEN_DUTY_EN_ADDR,
			  ((cfg_pll_c0 >> CFG_PLL_C0_EVEN_DUTY_EN_SHIFT) &
			  CFG_PLL_C0_EVEN_DUTY_EN_MASK) <<
			  PLL_C0_EVEN_DUTY_EN_SHIFT, (*seq)++);

done:
	return ret;
}

static int iopll_c1_write(struct pac_iopll *iopll, u32 cfg_pll_c1, u8 *seq)
{
	int ret;

	ret = iopll_write(iopll, PLL_C1_HIGH_ADDR,
			  (cfg_pll_c1 >> CFG_PLL_C1_HIGH_SHIFT) &
			 PLL_C1_HIGH_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C1_LOW_ADDR,
			  cfg_pll_c1 & PLL_C1_LOW_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C1_BYPASS_EN_ADDR,
			  (cfg_pll_c1 >> CFG_PLL_C1_BYPASS_EN_SHIFT) &
			  PLL_C1_BYPASS_EN_MASK, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_C1_EVEN_DUTY_EN_ADDR,
			  ((cfg_pll_c1 >> CFG_PLL_C1_EVEN_DUTY_EN_SHIFT) &
			  CFG_PLL_C1_EVEN_DUTY_EN_MASK) <<
			  PLL_C1_EVEN_DUTY_EN_SHIFT, (*seq)++);

done:
	return ret;
}

static int iopll_set_freq(struct pac_iopll *iopll,
			  struct pll_config *iopll_config, u8 *seq)
{
	int ret;

	dev_dbg(iopll->dev, "Set Frequency\n");

	ret = iopll_m_write(iopll, iopll_config->pll_m, seq);
	if (ret)
		goto done;

	ret = iopll_n_write(iopll, iopll_config->pll_n,
			    iopll_config->pll_cp, seq);
	if (ret)
		goto done;

	ret = iopll_c0_write(iopll, iopll_config->pll_c0, seq);
	if (ret)
		goto done;

	ret = iopll_c1_write(iopll, iopll_config->pll_c1, seq);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_CP2_ADDR,
			  ((iopll_config->pll_cp >> CFG_PLL_CP2_SHIFT) &
			  CFG_PLL_CP2_MASK) << PLL_CP2_SHIFT, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_LF_ADDR,
			  (((iopll_config->pll_lf >> CFG_PLL_LF_SHIFT) &
			  CFG_PLL_LF_MASK) << PLL_LF_SHIFT) |
			  ((iopll_config->pll_rc & CFG_PLL_RC_MASK) <<
			  PLL_RC_SHIFT), (*seq)++);
done:
	return ret;
}

static int iopll_calibrate(struct pac_iopll *iopll, u8 *seq)
{
	u32 status;
	int ret;

	dev_dbg(iopll->dev, "Request Calibration\n");

	/* Request IOPLL Calibration */
	ret = iopll_read(iopll, PLL_REQUEST_CAL_ADDR,
			 &status, (*seq)++);
	if (ret)
		goto done;

	ret = iopll_write(iopll, PLL_REQUEST_CAL_ADDR,
			  status | PLL_REQUEST_CALIBRATION, (*seq)++);
	if (ret)
		goto done;

	/* Enable calibration interface */
	ret = iopll_write(iopll, PLL_ENABLE_CAL_ADDR, PLL_ENABLE_CALIBRATION,
			  (*seq)++);
	msleep(IOPLL_CAL_DELAY_MS);
done:
	return ret;
}

static ssize_t frequency_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	struct pac_iopll *iopll = dev_get_drvdata(dev);
	u32 low_freq, high_freq;
	int err;

	dev_dbg(dev, "Userclk Frequency Show.\n");
	mutex_lock(&iopll->iopll_mutex);

	err = iopll_read_freq(iopll, IOPLL_MEASURE_HIGH, &high_freq);
	if (err)
		goto done;

	err = iopll_read_freq(iopll, IOPLL_MEASURE_LOW, &low_freq);

done:
	mutex_unlock(&iopll->iopll_mutex);
	return err ? err : scnprintf(buf, PAGE_SIZE, "%u %u\n",
				     FREQ_IN_KHZ(low_freq),
				     FREQ_IN_KHZ(high_freq));
}

static ssize_t frequency_store(struct device *dev,
			       struct device_attribute *attr,
			       const char *buf, size_t count)
{
	struct pll_config *iopll_config = (struct pll_config *)buf;
	struct pac_iopll *iopll = dev_get_drvdata(dev);
	u8 seq = 1;	/* Don't start with zero */
	int err;

	dev_dbg(dev, "Userclk Frequency Store.\n");
	if (count != sizeof(struct pll_config))
		return -EINVAL;

	if ((iopll_config->pll_freq_khz > IOPLL_MAX_FREQ * 1000) ||
	    (iopll_config->pll_freq_khz < IOPLL_MIN_FREQ * 1000))
		return -EINVAL;

	mutex_lock(&iopll->iopll_mutex);

	err = iopll_set_freq(iopll, iopll_config, &seq);
	if (err)
		goto done;

	err = iopll_reset(iopll);
	if (err)
		goto done;

	err = iopll_calibrate(iopll, &seq);

done:
	mutex_unlock(&iopll->iopll_mutex);
	return err ? err : count;
}
static DEVICE_ATTR_RW(frequency);

static struct attribute *port_iopll_attrs[] = {
	&dev_attr_frequency.attr,
	NULL,
};

static struct attribute_group iopll_attr_group = {
	.name	= "userclk",
	.attrs	= port_iopll_attrs,
};

static int intel_pac_iopll_probe(struct platform_device *pdev)
{
	struct pac_iopll_plat_data *iopll_data;
	struct device *dev = &pdev->dev;
	struct pac_iopll *iopll;

	iopll_data = dev_get_platdata(&pdev->dev);
	if (!iopll_data)
		return -ENODEV;

	iopll = devm_kzalloc(dev, sizeof(*iopll), GFP_KERNEL);
	if (!iopll)
		return -ENOMEM;

	iopll->csr_base = iopll_data->csr_base;
	iopll->dev = dev;
	mutex_init(&iopll->iopll_mutex);
	dev_set_drvdata(dev, iopll);

	return sysfs_create_group(&pdev->dev.kobj, &iopll_attr_group);
}

static int intel_pac_iopll_remove(struct platform_device *pdev)
{
	struct pac_iopll *iopll = dev_get_drvdata(&pdev->dev);

	sysfs_remove_group(&pdev->dev.kobj, &iopll_attr_group);
	mutex_destroy(&iopll->iopll_mutex);
	return 0;
}

static struct platform_driver intel_pac_iopll_driver = {
	.driver = {
		.name = PAC_IOPLL_DRV_NAME,
	},
	.probe = intel_pac_iopll_probe,
	.remove = intel_pac_iopll_remove,
};
module_platform_driver(intel_pac_iopll_driver);

MODULE_AUTHOR("Russ Weight <russell.h.weight@linux.intel.com>");
MODULE_DESCRIPTION("Intel PAC IOPLL");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:" PAC_IOPLL_DRV_NAME);
