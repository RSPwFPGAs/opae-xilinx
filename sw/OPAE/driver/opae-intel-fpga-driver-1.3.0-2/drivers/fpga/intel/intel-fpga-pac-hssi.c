/*
 * Driver for FPGA Management Engine which implements all FPGA platform
 * level management features.
 *
 * Copyright 2018 Intel Corporation, Inc.
 *
 * This work is licensed under the terms of the GNU GPL version 2. See
 * the COPYING file in the top-level directory.
 *
 */

#include <linux/module.h>
#include <linux/iopoll-mod.h>
#include <linux/platform_device.h>
#include <linux/bitops.h>

#include "backport.h"
#include "pac-hssi.h"

/* Serial number and EEPROM data caching */
#define I2C_SERIAL_NUMBER_LEN	16	/* 16 bytes / 128 bits */
#define I2C_EEPROM_LEN		512	/* 512 bytes in EEPROM */
#define HSSI_DATA_SERIAL	BIT(0)	/* Indicates serial number cached */
#define HSSI_DATA_EEPROM	BIT(1)	/* Indicates eeprom data cached */
struct pac_hssi {
	void __iomem *csr_base;
	struct device *dev; /* Will this actually get used? */
	struct mutex bus_mutex;
	u8 eeprom[I2C_EEPROM_LEN];
	u8 serial_number[I2C_SERIAL_NUMBER_LEN];
	u8 data_flags;
};

/* Nios Aux bus CSR addresses */
#define HSSI_AUX_PRMGMT_CMD		0x4 /* PR Management command */
#define HSSI_AUX_PRMGMT_DIN		0x5 /* PR Management data in */
#define HSSI_AUX_PRMGMT_DOUT		0x6 /* PR Management data out */
#define HSSI_AUX_LOCAL_CMD		0x7 /* Local Command */
#define HSSI_AUX_LOCAL_DIN		0x8 /* Local data in */
#define HSSI_AUX_LOCAL_DOUT		0x9 /* Local data out */

#define HSSI_I2C_CTRL_AND_LEDS		0x10 /* Control and LED register */
#define FPGA_I2C_MASTER_L		BIT(10) /* Master enable (assert low) */

#define MAC_ID_I2C_DATA_INTERFACE	0x11 /* I2C data interface register */
#define I2C_SDA				BIT(0)	/* Serial Data Line */
#define I2C_SCL				BIT(1)	/* Serial Clock Line */

/*
 * I2C device addressing - see p. 10 of http://ww1.microchip.com/downloads/
 * en/DeviceDoc/Atmel-8766-SEEPROM-AT24CS04-08-Datasheet.pdf
 */
#define I2C_DEVADDR_MASK	0xf7	/* Seven address bits */
#define I2C_DEVICE_READ		BIT(0)	/* Set for read; clear for write */
#define I2C_SERIAL_NUMBER_DEV	0xb0	/* Base address for Serial Number */
#define I2C_EEPROM_DEV		0xa0	/* Base address for EEPROM */
#define I2C_SERIAL_WORD_OFFSET	0x80	/* Word offset for Serial Number */

#define I2C_RESET_CYCLE_CNT	9	/* Reset requires 9 bus cycles */

/* Acknowledge bit polling / state */
#define HSSI_WRITE_POLL_INVL_US		10	/* Write poll interval */
#define HSSI_WRITE_POLL_TIMEOUT_US	100000	/* Write poll timeout */
#define ACK_STATE_SET	1		/* Acknowledge bit active */
#define ACK_STATE_CLR	0		/* Acknowledge bit cleared */

/* HSSI Control Commands */
#define HSSI_CTRL_CMD_NO_REQ	0	/* no request */
#define HSSI_CTRL_CMD_SW_RD	0x8	/* software register read request */
#define HSSI_CTRL_CMD_SW_WR	0x10	/* software register write request */
#define HSSI_CTRL_CMD_AUX_RD	0x40	/* aux bus read request */
#define HSSI_CTRL_CMD_AUX_WR	0x80	/* aux bus write request */

#define HSSI_DO_WRITE	0x10000		/* local/aux write request */
#define HSSI_DO_READ	0x20000		/* local/aux read request */

/* Nios local bus CSRs */
#define NIOS_LBUS_PRMGMT_RAME_ENA	0x3
#define NIOS_LBUS_RECONFIG_CMD_ADDR	0x8
#define NIOS_LBUS_RECONFIG_WR_DATA	0x9
#define NIOS_LBUS_RECONFIG_RD_DATA	0xa

/* Nios soft commands */
#define NIOS_CHANGE_HSSI_MODE		0x8
#define NIOS_TX_EQ_WRITE		0x9
#define NIOS_TX_EQ_READ			0xa
#define NIOS_HSSI_INIT			0xb

/* NIOS HSSI Interface to AFU */
#define NIOS_MAC_RX_ALIGNMENT_EN	BIT(0)
#define NIOS_PRMGMT_ASYNC_RST		BIT(1)

#define PR_MGMT_RST		0x1	/* Partial region management reset */

/* HSSI Ethernet Definitions */
#define HSSI_MODE_10G	0x1	/* Set the nios to mode 1 (10GbE Mode) */
#define HSSI_MODE_40G	0x2	/* Set the nios to mode 2 (40GbE Mode) */
#define HSSI_CHAN_MAX	3	/* Valid channels: 0 - 3 */
#define HSSI_PARM_MAX	7	/* Valid parameters: 0 - 7 */
#define HSSI_TUNE_STRLEN	0x8	/* Maximum length tuning string */
#define HSSI_TUNE_HEX		16	/* Expect hex values in tuning string */

static u8 eq_tune_max[] = { /* Valid parameter tuning values */
	0x1f, 0x7, 0x7, 0x7f, 0x3f, 0x3f, 0x1f, 0x1f
};

/* The following three definitions are specific to the 10Gb AFU. */
#define PR_TX_RST_BIT		BIT(0)
#define PR_RX_RST_BIT		BIT(1)
#define PR_CSR_RST_BIT		BIT(2)

/* The following two definitions are specific to the 40Gb AFU */
#define PR_40G_MAC_CORE_RST	BIT(0)
#define PR_40G_MAC_CSR_RST	BIT(1)

#define HSSI_RESET_DELAY_MS	1	/* Delay to follow reset writes */
#define HSSI_SET_MODE_DELAY_MS	10	/* Delay to follow mode change */

/* sysfs config values to specify 10G vs 40G AFU */
#define HSSI_ETH_SPEED_10G	10	/* 10Gb Ethernet */
#define HSSI_ETH_SPEED_40G	40	/* 40Gb Ethernet */

/* DFE Kick Start definitions */
#define AVMM_ARB_CTRL_ADDR	0x0
#define ADAPT_TRIG_REQUEST_ADDR	0x100
#define PDB_FXTAP_EN_ADDR	0x123
#define SEL_FXTAP_DEC_ADDR	0x124
#define DFE_FXTAP_EN_ADDR	0x148
#define ADAPT_CTRL_ADDR		0X149
#define CTLE_EN_ADDR		0x14b
#define ADP_STATUS_SEL_ADDR	0x14c
#define DFE_MODE_ADDR		0x14d
#define DFE_FXTAP_BYPASS_ADDR	0x15b
#define VREF_BYPASS_ADDR	0x15e
#define VGA_BYPASS_SEL_ADDR	0x160
#define CTLE_ADAPT_CYCLE_ADDR	0x163
#define CTLE_EQZ_1S_BYPASS_ADDR	0x166
#define CTLE_EQZ_4S_BYPASS_ADDR	0x167
#define TEST_MUX_ADDR		0x171
#define ADP_DFE_TAP_ADDR	0x176
#define TX_RX_CAL_STATUS	0x281
#define PDB_FXTAP_EN_MASK	0x0E
#define ADAPT_SLICERS_EN	BIT(1)
#define DFE_FIX_TAP_4_TO_7_EN	BIT(3)
#define DFE_FIX_TAP_8_TO_11_EN	BIT(2)

#define DFE_FXTAP_EN_MASK		GENMASK(4, 0)
#define DFE_FIX_TAP_1_to_7_ADAPT_EN	BIT(0)
#define DFE_FIX_TAP_8_to_11_ADAPT_EN	BIT(1)
#define VREF_ADAPT_EN			BIT(2)
#define VGA_ADAPT_EN			BIT(3)
#define CTLE_ADAPT_EN			BIT(4)

#define CTLE_EN_MASK		0x80
#define DFE_FXTAP_BYPASS_MASK	0x15
#define VREF_BYPASS_MASK	BIT(0)

#define VGA_BYPASS_SEL		BIT(0)
#define CTLE_EQZ_1S_BYPASS	BIT(0)
#define CTLE_EQZ_4S_BYPASS	BIT(0)
#define CTLE_ADAPT_CYCLE_MASK	GENMASK(7, 5)
#define DFE_MODE_MASK		GENMASK(3, 0)
#define DFT_ENABLE		BIT(5)
#define TX_CAL_BUSY		BIT(0)

#define AVMM_ARB_CTRL_UCTRLR	BIT(0) /* AVMM controlled by microcontroller */
#define ADAPT_CTRL_DPRIO	BIT(4)
#define ADAPT_TRIG_REQUEST_EN	BIT(6)
#define AVMM_BUSY		BIT(2)

#define TEST_MUX_MASK		GENMASK(4, 1)
#define TEST_MUX_DATA		0x16
#define ADP_STATUS_SEL_MASK	GENMASK(5, 0)
#define ADP_STATUS_SEL_30	GENMASK(4, 1)
#define ADP_STATUS_SEL_31	GENMASK(4, 0)
#define ADP_STATUS_SEL_32	0x20

#define DFE_KICKSTART_INTERVAL_MS	10
#define DFE_KICKSTART_TO_MS		10000

/* FME HSSI Control */
struct hssi_eth_ctrl {
	union {
		u64 csr;
		struct {
			u32 data:32;		/* HSSI data */
			u16 address:16;		/* HSSI address */
			/*
			 * HSSI command
			 * 0x0 - No request
			 * 0x08 - SW register RD request
			 * 0x10 - SW register WR request
			 * 0x40 - Auxiliar bus RD request
			 * 0x80 - Auxiliar bus WR request
			 */
			u16 cmd:16;
		};
	};
};

/* FME HSSI Status */
struct hssi_eth_stat {
	union {
		u64 csr;
		struct {
			u32 data:32;		/* HSSI data */
			u8  acknowledge:1;	/* HSSI acknowledge */
			u8  spare:1;		/* HSSI spare */
			u32 rsvd:30;		/* Reserved */
		};
	};
};

/* FME HSSI FEATURE */
struct hssi_eth_regs {
	struct hssi_eth_ctrl	hssi_control;
	struct hssi_eth_stat	hssi_status;
};

static void hssi_eth_ctrl_write(struct pac_hssi *hssi, u16 cmd,
				u16 addr, u32 data)
{
	struct hssi_eth_regs *hssi_regs = hssi->csr_base;
	struct hssi_eth_ctrl hssi_eth_ctrl = { { 0 } };

	hssi_eth_ctrl.cmd = cmd;
	hssi_eth_ctrl.address = addr;
	hssi_eth_ctrl.data = data;
	writeq(hssi_eth_ctrl.csr, &hssi_regs->hssi_control);
	dev_dbg(hssi->dev, "Wrote 0x%lx to HSSI Ctrl\n",
		(unsigned long)hssi_eth_ctrl.csr);
}

static int hssi_await_ack_state(struct pac_hssi *hssi, bool ack_state)
{
	struct hssi_eth_regs *hssi_regs = hssi->csr_base;
	struct hssi_eth_stat hssi_eth_stat = { { 0 } };
	u8 ack = ack_state ? ACK_STATE_SET : ACK_STATE_CLR;

	/* Poll for the expected state of acknowlege bit */
	readq_poll_timeout(&hssi_regs->hssi_status.csr, hssi_eth_stat.csr,
			   hssi_eth_stat.acknowledge == ack,
			   HSSI_WRITE_POLL_INVL_US, HSSI_WRITE_POLL_TIMEOUT_US);
	if (hssi_eth_stat.acknowledge != ack) {
		dev_err(hssi->dev, "timeout, HSSI ack=%d not received\n", ack);
		return -ETIMEDOUT;
	}
	return 0;
}

static u32 hssi_eth_stat_data_read(struct pac_hssi *hssi)
{
	struct hssi_eth_regs *hssi_regs = hssi->csr_base;
	struct hssi_eth_stat hssi_eth_stat = { { 0 } };

	hssi_eth_stat.csr = readq(&hssi_regs->hssi_status);
	dev_dbg(hssi->dev, "Read 0x%lx from HSSI Stat\n",
		(unsigned long)hssi_eth_stat.csr);
	return hssi_eth_stat.data;
}

static int hssi_cmd_read(struct pac_hssi *hssi, u16 cmd, u16 addr, u32 *retval)
{
	int err;

	hssi_eth_ctrl_write(hssi, cmd, addr, 0);
	err = hssi_await_ack_state(hssi, ACK_STATE_SET);
	if (err)
		return err;

	*retval = hssi_eth_stat_data_read(hssi);

	hssi_eth_ctrl_write(hssi, HSSI_CTRL_CMD_NO_REQ, 0, 0);
	return hssi_await_ack_state(hssi, ACK_STATE_CLR);
}

static int hssi_cmd_write(struct pac_hssi *hssi, u16 cmd, u16 addr, u32 data)
{
	int err;

	hssi_eth_ctrl_write(hssi, cmd, addr, data);
	err = hssi_await_ack_state(hssi, ACK_STATE_SET);
	if (err)
		return err;

	hssi_eth_ctrl_write(hssi, HSSI_CTRL_CMD_NO_REQ, 0, 0);
	return hssi_await_ack_state(hssi, ACK_STATE_CLR);
}

enum hssi_nios_args {
	NIOS_FN_CMD    = 1,
	NIOS_FN_ARG0   = 2,
	NIOS_FN_ARG1   = 3,
	NIOS_FN_ARG2   = 4,
	NIOS_FN_ARG3   = 5,
	NIOS_FN_RESULT = 6
};

static int hssi_nios_soft_fn(struct pac_hssi *hssi, u32 cmd,
			     u32 arg0, u32 arg1, u32 arg2, u32 arg3,
			     u32 *retval)
{
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_SW_WR, NIOS_FN_ARG0, arg0);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_SW_WR, NIOS_FN_ARG1, arg1);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_SW_WR, NIOS_FN_ARG2, arg2);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_SW_WR, NIOS_FN_ARG3, arg3);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_SW_WR, NIOS_FN_CMD, cmd);
	if (err)
		return err;

	return hssi_cmd_read(hssi, HSSI_CTRL_CMD_SW_RD, NIOS_FN_RESULT, retval);
}

static int hssi_aux_cmd_write(struct pac_hssi *hssi, u16 cmd, u16 din,
			      u32 addr, u32 data)
{
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR, din, data);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR, cmd, addr);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR, cmd, 0x0);
}

static inline int hssi_local_write(struct pac_hssi *hssi, u16 addr, u32 data)
{
	return hssi_aux_cmd_write(hssi, HSSI_AUX_LOCAL_CMD, HSSI_AUX_LOCAL_DIN,
				  HSSI_DO_WRITE | addr, data);
}

static inline int hssi_local_read(struct pac_hssi *hssi, u16 addr, u32 *retval)
{
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     HSSI_AUX_LOCAL_CMD, addr);
	if (err)
		return err;

	return hssi_cmd_read(hssi, HSSI_CTRL_CMD_AUX_RD,
			     HSSI_AUX_LOCAL_DOUT, retval);
}

static inline int hssi_prmgmt_write(struct pac_hssi *hssi, u16 addr, u32 data)
{
	return hssi_aux_cmd_write(hssi, HSSI_AUX_PRMGMT_CMD,
				  HSSI_AUX_PRMGMT_DIN,
				  HSSI_DO_WRITE | addr, data);
}

static int hssi_set_mode(struct pac_hssi *hssi, unsigned char mode)
{
	int err;
	u32 retval;

	err = hssi_local_write(hssi, NIOS_LBUS_PRMGMT_RAME_ENA,
			       NIOS_PRMGMT_ASYNC_RST);
	if (err)
		return err;

	err = hssi_nios_soft_fn(hssi, NIOS_CHANGE_HSSI_MODE, mode, 0, 0, 0,
				&retval);
	if (err)
		return err;

	err = hssi_nios_soft_fn(hssi, NIOS_HSSI_INIT, 0, 0, 0, 0, &retval);
	if (err)
		return err;

	err = hssi_local_write(hssi, NIOS_LBUS_PRMGMT_RAME_ENA, 0x0);
	if (err)
		return err;

	err = hssi_local_write(hssi, NIOS_LBUS_PRMGMT_RAME_ENA,
			       NIOS_MAC_RX_ALIGNMENT_EN);
	if (err)
		return err;

	msleep(HSSI_SET_MODE_DELAY_MS);
	return 0;
}

static int set_hssi_mode_10gb_with_afu_reset(struct pac_hssi *hssi)
{
	int err = 0;

	err = hssi_prmgmt_write(hssi, PR_MGMT_RST,
				PR_CSR_RST_BIT | PR_RX_RST_BIT | PR_TX_RST_BIT);
	if (err)
		return err;

	err = hssi_set_mode(hssi, HSSI_MODE_10G);
	if (err)
		return err;

	err = hssi_prmgmt_write(hssi, PR_MGMT_RST,
				PR_CSR_RST_BIT | PR_RX_RST_BIT);
	if (err)
		return err;

	msleep(HSSI_RESET_DELAY_MS);

	err = hssi_prmgmt_write(hssi, PR_MGMT_RST, PR_CSR_RST_BIT);
	if (err)
		return err;

	msleep(HSSI_RESET_DELAY_MS);

	err =  hssi_prmgmt_write(hssi, PR_MGMT_RST, 0x0);
	if (err)
		return err;

	msleep(HSSI_RESET_DELAY_MS);

	return 0;
}

static int set_hssi_mode_40gb_with_afu_reset(struct pac_hssi *hssi)
{
	int err = 0;

	err = hssi_prmgmt_write(hssi, PR_MGMT_RST,
				PR_40G_MAC_CORE_RST | PR_40G_MAC_CSR_RST);
	if (err)
		return err;

	err = hssi_set_mode(hssi, HSSI_MODE_40G);
	if (err)
		return err;

	err = hssi_prmgmt_write(hssi, PR_MGMT_RST, 0x0);
	if (err)
		return err;

	msleep(HSSI_RESET_DELAY_MS);

	return 0;
}

/*
 * The config sysfs file touches the AFU reset lines, which is not
 * friendly towards possible customer implementations of 10G and
 * 40G AFUs. Therefore config is being deprecated in favor of
 * config_qsfp0, which does not touch the AFU resets.
 */
static ssize_t config_store(struct device *dev, struct device_attribute *attr,
			    const char *buf, size_t count)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	u8 hssi_eth_speed;
	int err;

	dev_warn(hssi->dev, "The HSSI config sysfs file is deprecated.\n");
	dev_warn(hssi->dev, "Please use the config_qsfp0 file instead.\n");

	err = kstrtou8(buf, 0, &hssi_eth_speed);
	if (err)
		return err;

	mutex_lock(&hssi->bus_mutex);

	if (hssi_eth_speed == HSSI_ETH_SPEED_10G)
		err = set_hssi_mode_10gb_with_afu_reset(hssi);
	else if (hssi_eth_speed == HSSI_ETH_SPEED_40G)
		err = set_hssi_mode_40gb_with_afu_reset(hssi);
	else
		err = -EINVAL;

	mutex_unlock(&hssi->bus_mutex);

	return err ? err : count;
}
static DEVICE_ATTR_WO(config);

static ssize_t config_qsfp0_store(struct device *dev,
				  struct device_attribute *attr,
				  const char *buf, size_t count)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	u8 hssi_eth_speed;
	int err;

	err = kstrtou8(buf, 0, &hssi_eth_speed);
	if (err)
		return err;

	mutex_lock(&hssi->bus_mutex);

	if (hssi_eth_speed == HSSI_ETH_SPEED_10G)
		err = hssi_set_mode(hssi, HSSI_MODE_10G);
	else if (hssi_eth_speed == HSSI_ETH_SPEED_40G)
		err = hssi_set_mode(hssi, HSSI_MODE_40G);
	else
		err = -EINVAL;

	mutex_unlock(&hssi->bus_mutex);
	return err ? err : count;
}

static struct device_attribute dev_attr_config_qsfp0 =
	__ATTR(config, 0200, NULL, config_qsfp0_store);

static int hssi_i2c_enable(struct pac_hssi *hssi)
{
	u32 value;
	int err;

	err = hssi_cmd_read(hssi, HSSI_CTRL_CMD_AUX_RD,
			    HSSI_I2C_CTRL_AND_LEDS, &value);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      HSSI_I2C_CTRL_AND_LEDS,
			      value & ~FPGA_I2C_MASTER_L);
}

static int hssi_i2c_disable(struct pac_hssi *hssi)
{
	u32 value;
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL | I2C_SDA);
	if (err)
		return err;

	err = hssi_cmd_read(hssi, HSSI_CTRL_CMD_AUX_RD,
			    HSSI_I2C_CTRL_AND_LEDS, &value);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      HSSI_I2C_CTRL_AND_LEDS,
			      value | FPGA_I2C_MASTER_L);
}

static int hssi_maci2c_start(struct pac_hssi *hssi)
{
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL | I2C_SDA);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      MAC_ID_I2C_DATA_INTERFACE, 0);
}

static int hssi_maci2c_stop(struct pac_hssi *hssi)
{
	int err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL | I2C_SDA);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      MAC_ID_I2C_DATA_INTERFACE, I2C_SDA);
}

static int hssi_maci2c_rdbeat(struct pac_hssi *hssi, u8 *retval)
{
	int err;
	u32 value;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SDA);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL | I2C_SDA);
	if (err)
		return err;

	err = hssi_cmd_read(hssi, HSSI_CTRL_CMD_AUX_RD,
			    MAC_ID_I2C_DATA_INTERFACE, &value);
	if (err)
		return err;
	*retval = value & I2C_SDA;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      MAC_ID_I2C_DATA_INTERFACE, I2C_SDA);
}

static int hssi_maci2c_wrbeat(struct pac_hssi *hssi, u8 data_bit)
{
	int err;

	data_bit &= I2C_SDA;
	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, data_bit);
	if (err)
		return err;

	err = hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			     MAC_ID_I2C_DATA_INTERFACE, I2C_SCL | data_bit);
	if (err)
		return err;

	return hssi_cmd_write(hssi, HSSI_CTRL_CMD_AUX_WR,
			      MAC_ID_I2C_DATA_INTERFACE, data_bit);
}

static int hssi_maci2c_rdbyte(struct pac_hssi *hssi, u8 *byte)
{
	int i, err;
	u8 bit;

	*byte = 0;
	for (i = 7; i >= 0; i--) {
		err = hssi_maci2c_rdbeat(hssi, &bit);
		if (err)
			break;
		*byte |= (bit << i);
	}
	return err;
}

static int hssi_maci2c_wrbyte(struct pac_hssi *hssi, u8 byte)
{
	int i, err;

	for (i = 7; i >= 0; i--) {
		err = hssi_maci2c_wrbeat(hssi, (byte >> i) & I2C_SDA);
		if (err)
			break;
	}
	return err;
}

static int hssi_maci2c_reset(struct pac_hssi *hssi)
{
	int i, err;
	u8 value;

	err = hssi_maci2c_start(hssi);
	if (err)
		return err;

	for (i = 0; i < I2C_RESET_CYCLE_CNT; i++) {
		err = hssi_maci2c_rdbeat(hssi, &value);
		if (err)
			return err;
	}

	err = hssi_maci2c_start(hssi);
	if (err)
		return err;

	return hssi_maci2c_stop(hssi);
}

static int hssi_maci2c_read_dev(struct pac_hssi *hssi, u8 device, int addr,
				unsigned char *buf, size_t len)
{
	int i, err;
	u8 byte;

	err = hssi_maci2c_start(hssi);
	if (err)
		return err;

	err = hssi_maci2c_wrbyte(hssi, device & I2C_DEVADDR_MASK);
	if (err)
		return err;

	err = hssi_maci2c_rdbeat(hssi, &byte);
	if (err)
		return err;

	if (byte) {
		dev_err(hssi->dev, "I2C ACK bit not clear! (0)");
		return -ETIMEDOUT;
	}

	err = hssi_maci2c_wrbyte(hssi, addr & I2C_DEVADDR_MASK);
	if (err)
		return err;

	err = hssi_maci2c_rdbeat(hssi, &byte);
	if (err)
		return err;

	if (byte) {
		dev_err(hssi->dev, "I2C ACK bit not clear! (1)");
		return -ETIMEDOUT;
	}

	err = hssi_maci2c_stop(hssi);
	if (err)
		return err;

	err = hssi_maci2c_start(hssi);
	if (err)
		return err;

	err = hssi_maci2c_wrbyte(hssi, (device & I2C_DEVADDR_MASK) |
				 I2C_DEVICE_READ);
	if (err)
		return err;

	err = hssi_maci2c_rdbeat(hssi, &byte);
	if (err)
		return err;

	if (byte) {
		dev_err(hssi->dev, "I2C ACK bit not clear! (2)");
		return -ETIMEDOUT;
	}

	for (i = 0; i < len; i++) {
		err = hssi_maci2c_rdbyte(hssi, &buf[i]);
		if (err)
			return err;

		if (i < (len - 1)) {
			err = hssi_maci2c_wrbeat(hssi, 0); /* ACK */
			if (err)
				return err;
		}
	}
	return hssi_maci2c_stop(hssi);
}

static int write_serdes(struct pac_hssi *hssi, u8 chan, u16 addr,
			u32 bitmask, u32 val)
{
	int err = 0;
	u32 curr, data;

	data = (chan << 10) | addr;
	err = hssi_local_write(hssi, NIOS_LBUS_RECONFIG_CMD_ADDR,
			       data | HSSI_DO_READ);
	if (err)
		return err;

	err = hssi_local_read(hssi, NIOS_LBUS_RECONFIG_RD_DATA, &curr);
	if (err)
		return err;

	curr &= ~bitmask;
	curr |= (val & bitmask);

	err = hssi_local_write(hssi, NIOS_LBUS_RECONFIG_WR_DATA, curr);
	if (err)
		return err;

	return hssi_local_write(hssi, NIOS_LBUS_RECONFIG_CMD_ADDR,
				data | HSSI_DO_WRITE);
}

static int read_serdes(struct pac_hssi *hssi, u8 chan, u16 addr, u32 *retval)
{
	int err = 0;

	err = hssi_local_write(hssi, NIOS_LBUS_RECONFIG_CMD_ADDR,
			       (chan << 10) | addr | HSSI_DO_READ);
	if (err)
		return err;

	return hssi_local_read(hssi, NIOS_LBUS_RECONFIG_RD_DATA, retval);
}

static int prep_adaptation(struct pac_hssi *hssi, u8 chan)
{
	int err;

	err = write_serdes(hssi, chan, PDB_FXTAP_EN_ADDR,
			   PDB_FXTAP_EN_MASK, ADAPT_SLICERS_EN |
			   DFE_FIX_TAP_4_TO_7_EN |
			   DFE_FIX_TAP_8_TO_11_EN);
	if (err)
		return err;

	err = write_serdes(hssi, chan, DFE_FXTAP_EN_ADDR,
			   DFE_FXTAP_EN_MASK,
			   DFE_FIX_TAP_1_to_7_ADAPT_EN |
			   DFE_FIX_TAP_8_to_11_ADAPT_EN |
			   VREF_ADAPT_EN | VGA_ADAPT_EN |
			   CTLE_ADAPT_EN);
	if (err)
		return err;

	err = write_serdes(hssi, chan, CTLE_EN_ADDR, CTLE_EN_MASK, 0);
	if (err)
		return err;

	err = write_serdes(hssi, chan, DFE_FXTAP_BYPASS_ADDR,
			   DFE_FXTAP_BYPASS_MASK, 0);
	if (err)
		return err;

	err = write_serdes(hssi, chan, VREF_BYPASS_ADDR,
			   VREF_BYPASS_MASK, 0);
	if (err)
		return err;

	err = write_serdes(hssi, chan, VGA_BYPASS_SEL_ADDR,
			   VGA_BYPASS_SEL, VGA_BYPASS_SEL);
	if (err)
		return err;

	err = write_serdes(hssi, chan, CTLE_EQZ_1S_BYPASS_ADDR,
			   CTLE_EQZ_1S_BYPASS, CTLE_EQZ_1S_BYPASS);
	if (err)
		return err;

	err = write_serdes(hssi, chan, CTLE_EQZ_4S_BYPASS_ADDR,
			   CTLE_EQZ_4S_BYPASS, CTLE_EQZ_4S_BYPASS);
	if (err)
		return err;

	err = write_serdes(hssi, chan, CTLE_ADAPT_CYCLE_ADDR,
			   CTLE_ADAPT_CYCLE_MASK, 0);
	if (err)
		return err;

	/* Disable hold on Fixed tap */
	err = write_serdes(hssi, chan, DFE_MODE_ADDR, DFE_MODE_MASK, 0);
	if (err)
		return err;

	return write_serdes(hssi, chan, SEL_FXTAP_DEC_ADDR, DFT_ENABLE, 0);
}

static int trigger_adaptation(struct pac_hssi *hssi, u8 chan)
{
	int err;

	err = write_serdes(hssi, chan, ADAPT_CTRL_ADDR,
			   ADAPT_CTRL_DPRIO, ADAPT_CTRL_DPRIO);
	if (err)
		return err;

	err = write_serdes(hssi, chan, ADAPT_TRIG_REQUEST_ADDR,
			   ADAPT_TRIG_REQUEST_EN, ADAPT_TRIG_REQUEST_EN);
	if (err)
		return err;

	return write_serdes(hssi, chan, AVMM_ARB_CTRL_ADDR,
			   AVMM_ARB_CTRL_UCTRLR, AVMM_ARB_CTRL_UCTRLR);
}

static int poll_adaptation_complete(struct pac_hssi *hssi, u8 chan)
{
	unsigned int time = 0;
	u32 value;
	int err;

	do {
		msleep(DFE_KICKSTART_INTERVAL_MS);
		err = read_serdes(hssi, chan, TX_RX_CAL_STATUS,
				  &value);
		if (err)
			return err;

		time += DFE_KICKSTART_INTERVAL_MS;
	} while ((value & AVMM_BUSY) && (time <= DFE_KICKSTART_TO_MS));

	if (value & AVMM_BUSY) {
		dev_err(hssi->dev, "DFE Kickstart timed out");
		dev_err(hssi->dev, "Chan %u: 0x%08x\n", chan, value);
		return -ETIMEDOUT;
	}

	return 0;
}

static int read_tap(struct pac_hssi *hssi, u8 chan, u8 tap_select, u32 *retval)
{
	int err;

	err = write_serdes(hssi, chan, ADP_STATUS_SEL_ADDR,
			   ADP_STATUS_SEL_MASK, tap_select);
	if (err)
		return err;

	return read_serdes(hssi, chan, ADP_DFE_TAP_ADDR, retval);
}

static ssize_t
board_id_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	int err;

	mutex_lock(&hssi->bus_mutex);
	if (!(hssi->data_flags & HSSI_DATA_SERIAL)) {
		hssi_i2c_enable(hssi);
		err = hssi_maci2c_reset(hssi);
		if (err)
			goto error;
		err = hssi_maci2c_read_dev(hssi, I2C_SERIAL_NUMBER_DEV,
					   I2C_SERIAL_WORD_OFFSET,
					   hssi->serial_number,
					   I2C_SERIAL_NUMBER_LEN);
		if (err)
			goto error;
		hssi_i2c_disable(hssi);
		hssi->data_flags |= HSSI_DATA_SERIAL;
	}
	mutex_unlock(&hssi->bus_mutex);
	memcpy(buf, hssi->serial_number, I2C_SERIAL_NUMBER_LEN);
	return I2C_SERIAL_NUMBER_LEN;

error:
	hssi_i2c_disable(hssi);
	mutex_unlock(&hssi->bus_mutex);
	return err;
}
static DEVICE_ATTR_RO(board_id);

static ssize_t
eeprom_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	int err;

	mutex_lock(&hssi->bus_mutex);
	if (!(hssi->data_flags & HSSI_DATA_EEPROM)) {
		hssi_i2c_enable(hssi);
		err = hssi_maci2c_reset(hssi);
		if (err)
			goto error;
		err = hssi_maci2c_read_dev(hssi, I2C_EEPROM_DEV, 0,
					   hssi->eeprom, I2C_EEPROM_LEN);
		if (err)
			goto error;
		hssi_i2c_disable(hssi);
		hssi->data_flags |= HSSI_DATA_EEPROM;
	}
	mutex_unlock(&hssi->bus_mutex);
	memcpy(buf, hssi->eeprom, I2C_EEPROM_LEN);
	return I2C_EEPROM_LEN;

error:
	hssi_i2c_disable(hssi);
	mutex_unlock(&hssi->bus_mutex);
	return err;
}
static DEVICE_ATTR_RO(eeprom);

static int eq_tune_get_token(const char **sp, char c, u8 *value)
{
	int err = 0;
	char *cp;

	cp = strnchr(*sp, HSSI_TUNE_STRLEN, c);
	if (!cp)
		return -EINVAL;

	*cp = '\0';
	err = kstrtou8(*sp, HSSI_TUNE_HEX, value);

	*sp = cp + 1;
	return err;
}

static ssize_t equalizer_tune_store(struct device *dev,
				    struct device_attribute *attr,
				    const char *buf, size_t count)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	u8 parm, value, chan;
	const char **sp;
	u32 retval;
	size_t len;
	int err;

	len = strnlen(buf, PAGE_SIZE);
	if (len > HSSI_TUNE_STRLEN)
		return -EINVAL;

	sp = &buf;
	err = eq_tune_get_token(sp, ':', &chan);
	if (err)
		return err;

	err = eq_tune_get_token(sp, '=', &parm);
	if (err)
		return err;

	err = eq_tune_get_token(sp, '\n', &value);
	if (err)
		return err;

	if (chan > HSSI_CHAN_MAX || parm > HSSI_PARM_MAX)
		return -EINVAL;

	if (value > eq_tune_max[parm]) {
		dev_err(hssi->dev, "equalizer_tune: Invalid tuning value\n");
		return -EINVAL;
	}

	mutex_lock(&hssi->bus_mutex);
	err = hssi_nios_soft_fn(hssi, NIOS_TX_EQ_WRITE, chan, parm, value,
				0, &retval);
	mutex_unlock(&hssi->bus_mutex);
	return err ? err : count;
}

static ssize_t equalizer_tune_show(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	u8 chan, parm;
	size_t count = 0;
	u32 value;
	int err;

	mutex_lock(&hssi->bus_mutex);
	for (chan = 0; chan <= HSSI_CHAN_MAX; chan++) {
		for (parm = 0; parm <= HSSI_PARM_MAX; parm++) {
			err = hssi_nios_soft_fn(hssi, NIOS_TX_EQ_READ, chan,
						parm, 0, 0, &value);
			if (err)
				goto error;
			count += scnprintf(buf + count, PAGE_SIZE - count,
					   "%x:%x=%x\n", chan, parm, value);
		}
	}

error:
	mutex_unlock(&hssi->bus_mutex);
	return err ? err : count;
}
static DEVICE_ATTR_RW(equalizer_tune);

static ssize_t dfe_kickstart_store(struct device *dev,
				   struct device_attribute *attr,
				   const char *buf, size_t count)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	int err;
	u8 chan;

	mutex_lock(&hssi->bus_mutex);

	for (chan = 0; chan <= HSSI_CHAN_MAX; chan++) {
		err = prep_adaptation(hssi, chan);
		if (err)
			goto error;

		err = trigger_adaptation(hssi, chan);
		if (err)
			goto error;

		err = poll_adaptation_complete(hssi, chan);
		if (err)
			goto error;
	}

error:
	mutex_unlock(&hssi->bus_mutex);
	return err ? err : count;
}

static ssize_t dfe_kickstart_show(struct device *dev,
				  struct device_attribute *attr,
				  char *buf)
{
	struct pac_hssi *hssi = dev_get_drvdata(dev);
	size_t count = 0;
	u32 value;
	int err;
	u8 chan;

	mutex_lock(&hssi->bus_mutex);
	for (chan = 0; chan <= HSSI_CHAN_MAX; chan++) {
		err = write_serdes(hssi, chan, TEST_MUX_ADDR,
				   TEST_MUX_MASK, TEST_MUX_DATA);
		if (err)
			return err;

		err = read_tap(hssi, chan, ADP_STATUS_SEL_30, &value);
		if (err)
			goto error;

		count += scnprintf(buf + count, PAGE_SIZE - count,
				   "chan%d: 0x%x", chan, value);

		err = read_tap(hssi, chan, ADP_STATUS_SEL_31, &value);
		if (err)
			goto error;

		count += scnprintf(buf + count, PAGE_SIZE - count,
				   " 0x%x", value);

		err = read_tap(hssi, chan, ADP_STATUS_SEL_32, &value);
		if (err)
			goto error;

		count += scnprintf(buf + count, PAGE_SIZE - count,
				   " 0x%x\n", value);
	}

error:
	mutex_unlock(&hssi->bus_mutex);
	return err ? err : count;
}
static DEVICE_ATTR_RW(dfe_kickstart);

static struct attribute *hssi_qsfp0_attrs[] = {
	&dev_attr_config_qsfp0.attr,
	&dev_attr_equalizer_tune.attr,
	&dev_attr_dfe_kickstart.attr,
	NULL,
};

static struct attribute *hssi_mgmt_attrs[] = {
	&dev_attr_config.attr,
	&dev_attr_board_id.attr,
	&dev_attr_eeprom.attr,
	&dev_attr_equalizer_tune.attr,
	&dev_attr_dfe_kickstart.attr,
	NULL,
};

static const struct attribute *hssi_board_attrs[] = {
	&dev_attr_board_id.attr,
	&dev_attr_eeprom.attr,
	NULL,
};

static const struct attribute_group hssi_mgmt_attr_group = {
	.name	= "hssi_mgmt",
	.attrs	= hssi_mgmt_attrs,
};

static const struct attribute_group hssi_qsfp0_attr_group = {
	.name	= "qsfp0",
	.attrs	= hssi_qsfp0_attrs,
};

static int intel_pac_hssi_probe(struct platform_device *pdev)
{
	struct pac_hssi_plat_data *hdata;
	struct device *dev = &pdev->dev;
	struct pac_hssi *hssi;
	int err;

	hdata = dev_get_platdata(&pdev->dev);
	if (!hdata)
		return -ENODEV;

	hssi = devm_kzalloc(dev, sizeof(*hssi), GFP_KERNEL);
	if (!hssi)
		return -ENOMEM;

	hssi->csr_base = hdata->csr_base;
	hssi->dev = dev;
	mutex_init(&hssi->bus_mutex);
	dev_set_drvdata(dev, hssi);

	err = sysfs_create_files(&pdev->dev.kobj, hssi_board_attrs);
	if (err)
		goto exit;

	err = sysfs_create_group(&pdev->dev.kobj, &hssi_qsfp0_attr_group);
	if (err)
		goto cleanup_board_attrs;

	err = sysfs_create_group(&pdev->dev.kobj, &hssi_mgmt_attr_group);
	if (!err)
		return 0;

	sysfs_remove_group(&pdev->dev.kobj, &hssi_qsfp0_attr_group);

cleanup_board_attrs:
	sysfs_remove_files(&pdev->dev.kobj, hssi_board_attrs);

exit:
	mutex_destroy(&hssi->bus_mutex);
	return err;
}

static int intel_pac_hssi_remove(struct platform_device *pdev)
{
	struct pac_hssi *hssi = dev_get_drvdata(&pdev->dev);

	sysfs_remove_files(&pdev->dev.kobj, hssi_board_attrs);
	sysfs_remove_group(&pdev->dev.kobj, &hssi_qsfp0_attr_group);
	sysfs_remove_group(&pdev->dev.kobj, &hssi_mgmt_attr_group);
	mutex_destroy(&hssi->bus_mutex);
	return 0;
}

static struct platform_driver intel_pac_hssi_driver = {
	.driver = {
		.name = PAC_HSSI_DRV_NAME,
	},
	.probe = intel_pac_hssi_probe,
	.remove = intel_pac_hssi_remove,
};
module_platform_driver(intel_pac_hssi_driver);

MODULE_AUTHOR("Russ Weight <russell.h.weight@linux.intel.com>");
MODULE_DESCRIPTION("Intel Ethernet HSSI");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:" PAC_HSSI_DRV_NAME);
