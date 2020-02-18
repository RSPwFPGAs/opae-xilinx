// SPDX-License-Identifier: GPL-2.0
/*
 * Driver for Avalon Memory Mapped Interface to BMC
 *
 * Copyright (C) 2018 Intel Corporation. All rights reserved.
 */

#include <linux/avmmi-bmc.h>
#include <linux/fs.h>
#include <linux/iopoll-mod.h>
#include <linux/uaccess.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <uapi/linux/ipmi_msgdefs.h>
#include <uapi/linux/avmmi-bmc.h>

#include "backport.h"

#define ADDR_OFFSET		0x8
#define ADDR_RBIT		BIT_ULL(17)
#define ADDR_WBIT		BIT_ULL(16)
#define ADDR_MSK		0xffff

#define RDATA_OFFSET		0x10
#define RDATA_VALID		BIT(8)
#define RDATA_MSK		0xff

#define WDATA_OFFSET		0x18
#define WDATA_MSK		0xff

#define POLL_US			5
#define TIMEOUT_US		10000000

#define MEM_START		0x1000
#define MEM_SIZE		0x1000
#define MEM_END			(MEM_START + MEM_SIZE - 1)
#define CNT_LEN			2
#define MAX_PACKET_SIZE         min_t(int, ((MEM_SIZE >> 1) - CNT_LEN), 1024)

#define REQUEST_COUNT_ADDRESS	MEM_START
#define REQUEST_ADDRESS		(REQUEST_COUNT_ADDRESS + CNT_LEN)
#define RESPONSE_COUNT_ADDRESS	(MEM_START + (MEM_SIZE >> 1))
#define RESPONSE_ADDRESS        (RESPONSE_COUNT_ADDRESS + CNT_LEN)

#define IPMI_NETFN_OEM_GROUP			0x2e
#define IPMI_GET_DEVICE_SDR_INFO		0x20
#define IPMI_GET_DEVICE_SDR_INFO_SDR_CNT_OP	0x01

#define IPMI_GET_DEVICE_SDR			0x21
#define IPMI_GET_SENSOR_READING			0x2d
#define IPMI_LAST_RECORD_ID			0xffff
#define IPMI_ID_STRLEN_MSK			0x1f
#define SDR_CHUNK_SIZE				20

#define IANA_BW					0x007b18
#define IANA_BW_0				(IANA_BW & 0xff)
#define IANA_BW_1				((IANA_BW >> 8) & 0xff)
#define IANA_BW_2				((IANA_BW >> 16) & 0xff)

#define BW_RD_WR_LAST_ERROR			0x2
#define BW_SETTING_READ_RESET_CAUSE		0x6

#define BW_READ					0x0a
#define BW_READ_SETTING				0x08
#define BW_BL_CMD				0x64
#define BW_MAX_MSG_SIZE				40

struct msg_hdr {
	u8 netfn_lun;
	u8 seq;
	u8 cmd;
};

struct bw_powerdown_cause_req {
	struct msg_hdr hdr;
	u8 iana[3];
	u8 dev;
	u8 offset[4];
	u8 count;
};

struct bw_bmc_reset_cause_req {
	struct msg_hdr hdr;
	u8 iana[3];
	u8 dev;
};

struct bw_bmc_bl_req {
	struct msg_hdr hdr;
	u8 iana[3];
	u8 bl_cmd;
};

#define BW_BL_CMD_VERSION			0x00
#define BW_BL_JUMP_OTHER			0x01

struct bw_bmc_bl_rsp {
	struct msg_hdr hdr;
	u8 ccode;
	u8 iana[3];
	u8 bl_result;
};

struct bw_bmc_bl_ver_rsp {
	struct bw_bmc_bl_rsp bl_rsp;
	u8 ver0;
	u8 ver1;
	u8 act_app;
};

#define BW_BL_ACT_APP_MAIN			0x01
#define BW_BL_ACT_APP_BL			0x02
#define BW_BL_JUMP_PAUSE_MS			1000

struct bw_bmc_bl_jump_req {
	struct bw_bmc_bl_req bl_req;
	u8 app;
};

struct get_sensor_req {
	struct msg_hdr hdr;
	u8 sensor_num;
};

struct get_sdr_info_req {
	struct msg_hdr hdr;
	u8 operation;
};

struct get_sdr_info_resp {
	struct msg_hdr hdr;
	u8 ccode;
	u8 count;
	u8 flags;
	u8 change_indicator[4];
};

struct get_sdr_req {
	struct msg_hdr hdr;
	u8 reservation_id[2];
	u8 record_id[2];
	u8 offset;
	u8 count;
};

struct get_sdr_resp {
	struct msg_hdr hdr;
	u8 ccode;
	u8 next_record[2];
	u8 data[256];
};

struct sensor_record_header {
	u8 record_id[2];
	u8 sdr_version;
	u8 record_type;
	u8 record_len;
};

struct full_sensor_record {
	struct sensor_record_header header;
	u8 sensor_owner_id;
	u8 sensor_owner_lun;
	u8 sensor_number;
	u8 entity_id;
	u8 entity_instance;
	u8 sensor_initialization;
	u8 sensor_capabilities;
	u8 sensor_type;
	u8 event_type;
	u8 event_mask[6];
	u8 sensor_units;
	u8 sensor_base;
	u8 sensor_mod;
	u8 linearization;
	u8 m;
	u8 m_tolerance;
	u8 b;
	u8 b_accuracy;
	u8 accuracy;
	u8 r_exp_b_exp;
	u8 flags;
	u8 nominal_reading;
	u8 normal_max;
	u8 normal_min;
	u8 sensor_max_reading;
	u8 sensor_min_reading;
	u8 thresholds[6];
	u8 hysteresis[2];
	u8 reserved[2];
	u8 oem;
	u8 id_strlen;
	u8 id_string[32];
};

struct avmmi_priv {
	struct mutex bus_mutex; /* ensure only one transaction at a time */
	struct miscdevice miscdev;
	int num_sdr;
	struct full_sensor_record *sdrs;
};

static int avmmi_get_sdr(struct platform_device *pdev);

static int avmmi_read8(struct platform_device *pdev, u16 addr, u8 *val)
{
	struct avmmi_plat_data *qdata = dev_get_platdata(&pdev->dev);
	u64 rdata, address;
	int ret;

	address = (addr & ADDR_MSK) | ADDR_RBIT;
	writeq(address, qdata->csr_base + ADDR_OFFSET);

	ret = readq_poll_timeout(qdata->csr_base + RDATA_OFFSET, rdata,
				 rdata & RDATA_VALID, POLL_US, TIMEOUT_US);
	if (ret)
		dev_err(&pdev->dev, "%s readq_poll_timeout failed %d\n",
			__func__, ret);
	else
		*val = rdata & RDATA_MSK;

	return ret;
}

static int avmmi_read8s(struct platform_device *pdev, u16 addr, u8 *buf,
			u16 len)
{
	int ret = -EINVAL;

	while (len--) {
		ret = avmmi_read8(pdev, addr++, buf++);
		if (ret)
			break;
	}

	return ret;
}

static int avmmi_write8(struct platform_device *pdev, u16 addr, u8 val)
{
	struct avmmi_plat_data *qdata = dev_get_platdata(&pdev->dev);
	u64 address;

	writeq((u64)val, qdata->csr_base + WDATA_OFFSET);

	address = (ADDR_MSK & addr) | ADDR_WBIT;

	writeq(address, qdata->csr_base + ADDR_OFFSET);

	return 0;
}

static int avmmi_write8s(struct platform_device *pdev, u16 addr,
			 u8 *buf, u16 len)
{
	int ret = -EINVAL;

	while (len--) {
		ret = avmmi_write8(pdev, addr++, *(buf++));
		if (ret)
			break;
	}

	return ret;
}

static int avmmi_send_one(struct platform_device *pdev, u8 *txbuf,
			  u16 txlen, u8 *rxbuf, u16 rxlen)
{
	struct avmmi_priv *priv = dev_get_drvdata(&pdev->dev);
	u16 count, last_count;
	u64 poll_cnt;
	int ret;

	if (!priv)
		return -ENODEV;

	if (txlen > MAX_PACKET_SIZE)
		return -EINVAL;

	mutex_lock(&priv->bus_mutex);

	avmmi_write8s(pdev, REQUEST_ADDRESS, txbuf, txlen);
	avmmi_write8s(pdev, REQUEST_COUNT_ADDRESS, (u8 *)&txlen, sizeof(txlen));

	poll_cnt = 0;
	do {
		ret = avmmi_read8s(pdev, REQUEST_COUNT_ADDRESS,
				   (u8 *)&count, sizeof(count));
		if (ret)
			goto exit;

		if (count) {
			udelay(POLL_US);
			poll_cnt += POLL_US;
		}
	} while (count && (poll_cnt < TIMEOUT_US));

	if (count) {
		dev_err(&pdev->dev, "%s count %d\n", __func__, count);
		ret = -ETIMEDOUT;
		goto exit;
	}

	dev_dbg(&pdev->dev, "%s RA cleared\n", __func__);

	poll_cnt = 0;
	last_count = 0;
	do {
		ret = avmmi_read8s(pdev, RESPONSE_COUNT_ADDRESS,
				   (u8 *)&count, sizeof(count));
		if (ret)
			goto exit;

		if (!count || (count != last_count)) {
			last_count = count;
			count = 0;
			udelay(POLL_US);
			poll_cnt += POLL_US;
		}
	} while (!count && (poll_cnt < TIMEOUT_US));

	if (!count) {
		dev_err(&pdev->dev, "%s no response count\n", __func__);
		ret = -ETIMEDOUT;
		goto exit;
	}

	dev_dbg(&pdev->dev, "%s %d expected %d\n", __func__, count, rxlen);

	if (count <= MAX_PACKET_SIZE && count <= rxlen) {
		ret = avmmi_read8s(pdev, RESPONSE_ADDRESS, rxbuf, count);
		if (ret)
			goto exit;

		ret = count;
	} else {
		ret = -ENOMEM;
	}

	count = 0;
	avmmi_write8s(pdev, RESPONSE_COUNT_ADDRESS,
		      (u8 *)&count, sizeof(count));

exit:
	mutex_unlock(&priv->bus_mutex);

	return ret;
}

static ssize_t device_id_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	struct msg_hdr cmd;
	int ret;

	cmd.netfn_lun = IPMI_NETFN_APP_REQUEST << 2;
	cmd.cmd = IPMI_GET_DEVICE_ID_CMD;

	ret = avmmi_send_one(to_platform_device(dev), (u8 *)&cmd, sizeof(cmd),
			     (u8 *)buf, PAGE_SIZE);
	if (ret < 0)
		return scnprintf(buf, PAGE_SIZE, "BMC comm failure: %d\n", ret);

	return ret;
}

static DEVICE_ATTR_RO(device_id);

static ssize_t power_down_cause_show(struct device *dev,
				     struct device_attribute *attr, char *buf)
{
	struct bw_powerdown_cause_req cmd;
	int ret;

	memset(&cmd, 0, sizeof(cmd));

	cmd.hdr.netfn_lun = IPMI_NETFN_OEM_GROUP << 2;
	cmd.hdr.cmd = BW_READ;
	cmd.iana[0] = IANA_BW_0;
	cmd.iana[1] = IANA_BW_1;
	cmd.iana[2] = IANA_BW_2;
	cmd.dev = BW_RD_WR_LAST_ERROR;
	cmd.count = BW_MAX_MSG_SIZE;

	ret = avmmi_send_one(to_platform_device(dev), (u8 *)&cmd, sizeof(cmd),
			     (u8 *)buf, PAGE_SIZE);

	if (ret < 0)
		return scnprintf(buf, PAGE_SIZE, "BMC comm failure: %d\n", ret);

	return ret;
}

static DEVICE_ATTR_RO(power_down_cause);

static ssize_t reset_cause_show(struct device *dev,
				struct device_attribute *attr, char *buf)
{
	struct bw_bmc_reset_cause_req cmd;
	int ret;

	memset(&cmd, 0, sizeof(cmd));

	cmd.hdr.netfn_lun = IPMI_NETFN_OEM_GROUP << 2;
	cmd.hdr.cmd = BW_READ_SETTING;
	cmd.iana[0] = IANA_BW_0;
	cmd.iana[1] = IANA_BW_1;
	cmd.iana[2] = IANA_BW_2;
	cmd.dev = BW_SETTING_READ_RESET_CAUSE;

	ret = avmmi_send_one(to_platform_device(dev), (u8 *)&cmd, sizeof(cmd),
			     (u8 *)buf, PAGE_SIZE);

	if (ret < 0)
		return scnprintf(buf, PAGE_SIZE, "BMC comm failure: %d\n", ret);

	return ret;
}

static DEVICE_ATTR_RO(reset_cause);

static ssize_t sensors_show(struct device *dev,
			    struct device_attribute *attr, char *buf)
{
	struct avmmi_priv *priv = dev_get_drvdata(dev);
	struct full_sensor_record *fsr = priv->sdrs;
	struct get_sensor_req cmd;
	ssize_t total = 0;
	int i, ret;

	cmd.hdr.netfn_lun = IPMI_NETFN_SENSOR_EVENT_REQUEST << 2;
	cmd.hdr.cmd = IPMI_GET_SENSOR_READING;

	for (i = 0; i < priv->num_sdr; i++, fsr++) {
		cmd.sensor_num = fsr->sensor_number;
		ret = avmmi_send_one(to_platform_device(dev),
				     (u8 *)&cmd, sizeof(cmd),
				     (u8 *)(buf + total), PAGE_SIZE - total);

		dev_dbg(dev, "%s ret %d\n", __func__, ret);

		if (ret < 0)
			return scnprintf(buf, PAGE_SIZE,
					 "BMC comm failure on %d: %d\n",
					 i, ret);

		total += ret;
	}

	return total;
}

static  DEVICE_ATTR_RO(sensors);

static ssize_t sdr_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	struct avmmi_priv *priv = dev_get_drvdata(dev);
	struct full_sensor_record *fsr = priv->sdrs;
	ssize_t total = 0;
	int len, i;

	avmmi_get_sdr(to_platform_device(dev));

	for (i = 0; i < priv->num_sdr; i++, fsr++) {
		len = sizeof(struct sensor_record_header) +
			fsr->header.record_len;

		memcpy(buf + total, fsr, len);
		total += len;
	}

	return total;
}

static DEVICE_ATTR_RO(sdr);

static struct attribute *avmmi_attrs[] = {
	&dev_attr_device_id.attr,
	&dev_attr_power_down_cause.attr,
	&dev_attr_reset_cause.attr,
	&dev_attr_sensors.attr,
	&dev_attr_sdr.attr,
	NULL,
};

static struct attribute_group avmmi_attr_group = {
	.name = "bmc_info",
	.attrs = avmmi_attrs,
};

static int avmmi_get_sdr_count(struct platform_device *pdev, u8 *cnt)
{
	struct get_sdr_info_resp rsp;
	struct get_sdr_info_req req;
	int ret;

	memset(&req, 0, sizeof(req));
	memset(&rsp, 0, sizeof(rsp));

	req.hdr.netfn_lun = IPMI_NETFN_SENSOR_EVENT_REQUEST << 2;
	req.hdr.cmd = IPMI_GET_DEVICE_SDR_INFO;
	req.operation = IPMI_GET_DEVICE_SDR_INFO_SDR_CNT_OP;

	ret = avmmi_send_one(pdev, (u8 *)&req, sizeof(req),
			     (u8 *)&rsp, sizeof(rsp));
	if (ret < 0) {
		dev_err(&pdev->dev, "%s failed bmc comm %d\n", __func__, ret);
		return ret;
	}

	if (rsp.ccode != 0) {
		dev_err(&pdev->dev, "%s bad completion code %d\n",
			__func__, rsp.ccode);
		return -EIO;
	}

	dev_dbg(&pdev->dev, "%s cnt %d flg 0x%x\n",
		__func__, rsp.count, rsp.flags);

	*cnt = rsp.count;

	return 0;
}

static int avmmi_bl_version(struct platform_device *pdev, u16 *version,
			    u8 *act_app)
{
	struct bw_bmc_bl_ver_rsp rsp;
	struct bw_bmc_bl_req cmd;
	int ret;

	memset(&cmd, 0, sizeof(cmd));
	cmd.hdr.netfn_lun = IPMI_NETFN_OEM_GROUP << 2;
	cmd.hdr.cmd = BW_BL_CMD;
	cmd.iana[0] = IANA_BW_0;
	cmd.iana[1] = IANA_BW_1;
	cmd.iana[2] = IANA_BW_2;
	cmd.bl_cmd = BW_BL_CMD_VERSION;

	ret = avmmi_send_one(pdev, (u8 *)&cmd, sizeof(cmd),
			     (u8 *)&rsp, sizeof(rsp));
	if (ret < 0) {
		dev_err(&pdev->dev, "%s failed bmc comm %d\n", __func__, ret);
		return ret;
	}

	if (rsp.bl_rsp.ccode != 0) {
		dev_err(&pdev->dev, "%s bad completion code %d\n",
			__func__, rsp.bl_rsp.ccode);
		return -EIO;
	}

	if (rsp.bl_rsp.bl_result != 0) {
		dev_err(&pdev->dev, "%s bad BL result code %d\n",
			__func__, rsp.bl_rsp.bl_result);
		return -EIO;
	}

	*act_app = rsp.act_app;

	*version = (rsp.ver1 << 8) | rsp.ver0;

	dev_dbg(&pdev->dev, "%s BL ver %d 0x%x act %d\n", __func__,
		*version, *version, *act_app);

	return 0;
}

static int avmmi_bl_jump(struct platform_device *pdev, int app)
{
	struct bw_bmc_bl_jump_req cmd;
	struct bw_bmc_bl_rsp rsp;
	u16 bl_verion;
	u8 act_app;
	int ret;

	memset(&cmd, 0, sizeof(cmd));

	cmd.bl_req.hdr.netfn_lun = IPMI_NETFN_OEM_GROUP << 2;
	cmd.bl_req.hdr.cmd = BW_BL_CMD;
	cmd.bl_req.iana[0] = IANA_BW_0;
	cmd.bl_req.iana[1] = IANA_BW_1;
	cmd.bl_req.iana[2] = IANA_BW_2;
	cmd.bl_req.bl_cmd = BW_BL_JUMP_OTHER;

	cmd.app = app;

	ret = avmmi_send_one(pdev, (u8 *)&cmd, sizeof(cmd),
			     (u8 *)&rsp, sizeof(rsp));
	if (ret < 0) {
		dev_err(&pdev->dev, "%s failed bmc comm %d\n", __func__, ret);
		return ret;
	}

	if (rsp.ccode != 0) {
		dev_err(&pdev->dev, "%s bad completion code %d\n",
			__func__, rsp.ccode);
		return -EIO;
	}

	if (rsp.bl_result != 0) {
		dev_err(&pdev->dev, "%s bad BL result code %d\n",
			__func__, rsp.bl_result);
		return -EIO;
	}

	mdelay(BW_BL_JUMP_PAUSE_MS);

	ret = avmmi_bl_version(pdev, &bl_verion, &act_app);

	if (ret) {
		dev_err(&pdev->dev, "%s failed to be BL version %d\n",
			__func__, ret);
	} else if (act_app != app) {
		dev_err(&pdev->dev, "%s app failed to switch %d != %d\n",
			__func__, act_app, app);
		ret = -EINVAL;
	}
	return ret;
}


static int avmmi_get_one_sdr(struct platform_device *pdev, u16 *record_id,
			     struct full_sensor_record *sdr)
{
	int ret, i, loops, left_to_read = sizeof(*sdr);
	struct sensor_record_header *sr_hdr;
	struct get_sdr_resp rsp;
	struct get_sdr_req req;
	u8 *dst = (u8 *)sdr;
	size_t total = 0;

	loops = sizeof(*sdr) / SDR_CHUNK_SIZE;

	if (loops % SDR_CHUNK_SIZE)
		loops++;

	memset(&req, 0, sizeof(req));

	req.hdr.netfn_lun = IPMI_NETFN_SENSOR_EVENT_REQUEST << 2;
	req.hdr.cmd = IPMI_GET_DEVICE_SDR;
	req.record_id[0] = *record_id & 0xff;
	req.record_id[1] = (*record_id >> 8) & 0xff;
	req.count = SDR_CHUNK_SIZE;

	for (i = 0; (left_to_read > 0) && (i < loops); i++) {
		if (req.count > left_to_read)
			req.count = left_to_read;

		memset(&rsp, 0, sizeof(rsp));

		ret = avmmi_send_one(pdev, (u8 *)&req, sizeof(req),
				     (u8 *)&rsp, sizeof(rsp));
		if (ret < 0) {
			dev_err(&pdev->dev, "%s failed bmc comm %d\n",
				__func__, ret);
			return ret;
		}

		if (rsp.ccode != 0) {
			dev_err(&pdev->dev, "%s bad completion code %d\n",
				__func__, rsp.ccode);
			return ret;
		}

		if (i == 0) {
			sr_hdr = (struct sensor_record_header *)rsp.data;
			left_to_read = sizeof(*sr_hdr) +
				sr_hdr->record_len - req.count;

			dev_dbg(&pdev->dev, "%s sr len %d left %d\n",
				__func__, sr_hdr->record_len, left_to_read);
		} else {
			left_to_read -= req.count;
		}

		memcpy(dst + req.offset, rsp.data, req.count);
		total += req.count;

		req.offset += req.count;
		req.hdr.seq = (i + 1) << 2;
	}

	*record_id = rsp.next_record[0] | (rsp.next_record[1] << 8);

	dev_dbg(&pdev->dev, "%s next record is 0x%04x total %zu strlen %d\n",
		__func__, *record_id, total,
		sdr->id_strlen & IPMI_ID_STRLEN_MSK);

	return 0;
}

static int avmmi_get_sdr(struct platform_device *pdev)
{
	struct avmmi_priv *priv = dev_get_drvdata(&pdev->dev);
	int ret = -EINVAL, i;
	u16 record_id = 0;

	for (i = 0; i < priv->num_sdr; i++) {
		ret = avmmi_get_one_sdr(pdev, &record_id, &priv->sdrs[i]);
		if (ret)
			break;
	}

	return ret;
}

static struct avmmi_priv *file_to_avmmi_priv(struct file *file)
{
	return container_of(file->private_data, struct avmmi_priv, miscdev);
}

static long avmmi_bmc_ioctl(struct file *file, unsigned int cmd,
			    unsigned long param)
{
	struct avmmi_priv *priv = file_to_avmmi_priv(file);
	struct platform_device *pdev;
	struct avmmi_bmc_xact xact;
	u8 buf[MAX_PACKET_SIZE];
	unsigned long minsz;
	int ret = 0;

	if (cmd != AVMMI_BMC_XACT)
		return -EINVAL;

	pdev = to_platform_device(priv->miscdev.parent);

	dev_dbg(priv->miscdev.parent, "%s 0x%x\n", __func__, cmd);

	memset(&xact, 0, sizeof(xact));
	memset(buf, 0, sizeof(buf));

	minsz = offsetofend(struct avmmi_bmc_xact, rxbuf);

	if (copy_from_user(&xact, (const void __user *)param, minsz))
		return -EFAULT;

	if (xact.argsz < minsz)
		return -EINVAL;

	if (xact.txlen > sizeof(buf) || xact.rxlen > sizeof(buf))
		return -ENOMEM;

	if (!access_ok(VERIFY_READ, u64_to_user_ptr(xact.txbuf), xact.txlen))
		return -EFAULT;

	if (!access_ok(VERIFY_WRITE, u64_to_user_ptr(xact.rxbuf), xact.rxlen))
		return -EFAULT;

	if (copy_from_user(buf, u64_to_user_ptr(xact.txbuf), xact.txlen))
		return -EFAULT;

	ret = avmmi_send_one(pdev, buf, xact.txlen, buf, xact.rxlen);
	if (ret < 0) {
		dev_err(&pdev->dev, "%s avmmi_send_one failed %d\n",
			__func__, ret);
		return ret;
	}

	if (ret != xact.rxlen) {
		dev_err(&pdev->dev, "%s rlen mismatch %d != %d\n",
			__func__, ret, xact.rxlen);
		return -EINVAL;
	}

	if (copy_to_user(u64_to_user_ptr(xact.rxbuf), buf, xact.rxlen))
		return -EFAULT;

	return 0;
}

static const struct file_operations avmmi_bmc_fops = {
	.owner = THIS_MODULE,
	.open = nonseekable_open,
	.llseek = noop_llseek,
	.unlocked_ioctl = avmmi_bmc_ioctl
};

static int avmmi_probe(struct platform_device *pdev)
{
	struct avmmi_priv *priv;
	u8 cnt, act_app;
	u16 bl_ver;
	int ret;

	priv = devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);

	if (!priv)
		return -ENOMEM;

	dev_dbg(&pdev->dev, "%s %s\n", __func__, dev_name(&pdev->dev));

	priv->miscdev.minor = MISC_DYNAMIC_MINOR;
	priv->miscdev.name = dev_name(&pdev->dev);
	priv->miscdev.parent = &pdev->dev;
	priv->miscdev.fops = &avmmi_bmc_fops;

	ret = misc_register(&priv->miscdev);
	if (ret) {
		dev_err(&pdev->dev, "%s misc_register failed %d\n",
			__func__, ret);
		return ret;
	}

	mutex_init(&priv->bus_mutex);
	dev_set_drvdata(&pdev->dev, priv);

	ret = avmmi_bl_version(pdev, &bl_ver, &act_app);

	if (ret) {
		dev_err(&pdev->dev, "%s failed to get BMC BL version. %s",
				__func__, "BMC FW update required!\n");
		goto error;
	}

	if (act_app != BW_BL_ACT_APP_MAIN) {
		ret = avmmi_bl_jump(pdev, BW_BL_ACT_APP_MAIN);
		if (ret) {
			dev_err(&pdev->dev, "%s failed to put BMC %s",
				__func__, "in main application\n");
			/* return 0 to all FW to be updated */
			return 0;
		}
	}

	ret = avmmi_get_sdr_count(pdev, &cnt);
	if (ret)
		goto error;

	priv->num_sdr = cnt;

	priv->sdrs = devm_kzalloc(&pdev->dev,
				  sizeof(struct full_sensor_record) * cnt,
				  GFP_KERNEL);
	if (!priv->sdrs)
		goto error;

	avmmi_get_sdr(pdev);

	ret = sysfs_create_group(&pdev->dev.kobj, &avmmi_attr_group);
	if (ret) {
		dev_err(&pdev->dev, "%s sysfs_create_group failed %d\n",
			__func__, ret);
		goto error;
	}

	return 0;

error:
	misc_deregister(&priv->miscdev);
	mutex_destroy(&priv->bus_mutex);

	return ret;
}

static int avmmi_remove(struct platform_device *pdev)
{
	struct avmmi_priv *priv = dev_get_drvdata(&pdev->dev);

	misc_deregister(&priv->miscdev);
	mutex_destroy(&priv->bus_mutex);
	sysfs_remove_group(&pdev->dev.kobj, &avmmi_attr_group);

	return 0;
}

static struct platform_driver avmmi_driver = {
	.driver = {
		.name = AVMMI_BMC_DRV_NAME,
	},
	.probe = avmmi_probe,
	.remove = avmmi_remove,
};

module_platform_driver(avmmi_driver);

MODULE_AUTHOR("Matthew Gerlach <matthew.gerlach@linux.intel.com>");
MODULE_DESCRIPTION("Avalon Memory Mapped Interface to BMC");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:" AVMMI_BMC_DRV_NAME);
