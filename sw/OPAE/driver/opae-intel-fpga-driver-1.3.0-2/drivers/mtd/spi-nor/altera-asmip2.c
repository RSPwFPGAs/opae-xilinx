/*
 * Copyright (C) 2017 Intel Corporation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <linux/iopoll-mod.h>
#include <linux/module.h>
#include <linux/mtd/altera-asmip2.h>
#include <linux/mtd/mtd.h>
#include <linux/mtd/spi-nor-mod.h>
#include <linux/of_device.h>

#define QSPI_ACTION_REG			0
#define QSPI_ACTION_RST			BIT(0)
#define QSPI_ACTION_EN			BIT(1)
#define QSPI_ACTION_SC			BIT(2)
#define QSPI_ACTION_CHIP_SEL_SFT	4
#define QSPI_ACTION_DUMMY_SFT		8
#define QSPI_ACTION_READ_BACK_SFT	16

#define QSPI_FIFO_CNT_REG		4
#define QSPI_FIFO_DEPTH			0x200
#define QSPI_FIFO_CNT_MSK		0x3ff
#define QSPI_FIFO_CNT_RX_SFT		0
#define QSPI_FIFO_CNT_TX_SFT		12

#define QSPI_DATA_REG			0x8

#define QSPI_POLL_TIMEOUT_US		10000000
#define QSPI_POLL_INTERVAL_US		5

struct altera_asmip2 {
	void __iomem *csr_base;
	u32 num_flashes;
	struct device *dev;
	struct altera_asmip2_flash *flash[ALTERA_ASMIP2_MAX_NUM_FLASH_CHIP];
	struct mutex bus_mutex;
};

struct altera_asmip2_flash {
	struct spi_nor nor;
	struct altera_asmip2 *q;
};

static int altera_asmip2_write_reg(struct spi_nor *nor, u8 opcode, u8 *val,
				    int len)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;
	u32 reg;
	int ret;

	if ((len + 1) > QSPI_FIFO_DEPTH) {
		dev_err(q->dev, "%s bad len %d > %d\n",
			__func__, len + 1, QSPI_FIFO_DEPTH);
		return -EINVAL;
	}

	writeb(opcode, q->csr_base + QSPI_DATA_REG);

	iowrite8_rep(q->csr_base + QSPI_DATA_REG, val, len);

	reg = QSPI_ACTION_EN | QSPI_ACTION_SC;

	writel(reg, q->csr_base + QSPI_ACTION_REG);

	ret = readl_poll_timeout(q->csr_base + QSPI_FIFO_CNT_REG, reg,
				 (((reg >> QSPI_FIFO_CNT_TX_SFT) &
				 QSPI_FIFO_CNT_MSK) == 0),
				 QSPI_POLL_INTERVAL_US, QSPI_POLL_TIMEOUT_US);
	if (ret)
		dev_err(q->dev, "%s timed out\n", __func__);

	reg = QSPI_ACTION_EN;

	writel(reg, q->csr_base + QSPI_ACTION_REG);

	return ret;
}

static int altera_asmip2_read_reg(struct spi_nor *nor, u8 opcode, u8 *val,
				   int len)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;
	u32 reg;
	int ret;

	if (len > QSPI_FIFO_DEPTH) {
		dev_err(q->dev, "%s bad len %d > %d\n",
			__func__, len, QSPI_FIFO_DEPTH);
		return -EINVAL;
	}

	writeb(opcode, q->csr_base + QSPI_DATA_REG);

	reg = QSPI_ACTION_EN | QSPI_ACTION_SC |
		(len << QSPI_ACTION_READ_BACK_SFT);

	writel(reg, q->csr_base + QSPI_ACTION_REG);

	ret = readl_poll_timeout(q->csr_base + QSPI_FIFO_CNT_REG, reg,
				 ((reg & QSPI_FIFO_CNT_MSK) == len),
				 QSPI_POLL_INTERVAL_US, QSPI_POLL_TIMEOUT_US);

	if (!ret)
		ioread8_rep(q->csr_base + QSPI_DATA_REG, val, len);
	else
		dev_err(q->dev, "%s timeout\n", __func__);

	writel(QSPI_ACTION_EN, q->csr_base + QSPI_ACTION_REG);

	return ret;
}

static inline void altera_asmip2_push_offset(struct altera_asmip2 *q,
					     struct spi_nor *nor,
					     loff_t offset)
{
	int i;
	u32 val;

	for (i = (nor->addr_width - 1) * 8; i >= 0; i -= 8) {
		val = (offset & (0xff << i)) >> i;
		writeb(val, q->csr_base + QSPI_DATA_REG);
	}
}

static ssize_t altera_asmip2_read(struct spi_nor *nor, loff_t from, size_t len,
				   u_char *buf)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;
	size_t bytes_to_read;
	u32 reg;
	int ret;

	bytes_to_read = min_t(size_t, len, QSPI_FIFO_DEPTH);

	writeb(nor->read_opcode, q->csr_base + QSPI_DATA_REG);

	altera_asmip2_push_offset(q, nor, from);

	reg = QSPI_ACTION_EN | QSPI_ACTION_SC |
		(10 << QSPI_ACTION_DUMMY_SFT) |
		(bytes_to_read << QSPI_ACTION_READ_BACK_SFT);

	writel(reg, q->csr_base + QSPI_ACTION_REG);

	ret = readl_poll_timeout(q->csr_base + QSPI_FIFO_CNT_REG, reg,
				 ((reg & QSPI_FIFO_CNT_MSK) ==
				 bytes_to_read), QSPI_POLL_INTERVAL_US,
				 QSPI_POLL_TIMEOUT_US);
	if (ret) {
		dev_err(q->dev, "%s timed out\n", __func__);
		bytes_to_read = 0;
	} else
		ioread8_rep(q->csr_base + QSPI_DATA_REG, buf, bytes_to_read);

	writel(QSPI_ACTION_EN, q->csr_base + QSPI_ACTION_REG);

	return bytes_to_read;
}

static ssize_t altera_asmip2_write(struct spi_nor *nor, loff_t to,
				    size_t len, const u_char *buf)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;
	size_t bytes_to_write;
	u32 reg;
	int ret;

	bytes_to_write = min_t(size_t, len,
			       (QSPI_FIFO_DEPTH - (nor->addr_width + 1)));

	writeb(nor->program_opcode, q->csr_base + QSPI_DATA_REG);

	altera_asmip2_push_offset(q, nor, to);

	iowrite8_rep(q->csr_base + QSPI_DATA_REG, buf, bytes_to_write);

	reg = QSPI_ACTION_EN | QSPI_ACTION_SC;

	writel(reg, q->csr_base + QSPI_ACTION_REG);

	ret = readl_poll_timeout(q->csr_base + QSPI_FIFO_CNT_REG, reg,
				 (((reg >> QSPI_FIFO_CNT_TX_SFT) &
				 QSPI_FIFO_CNT_MSK) == 0),
				 QSPI_POLL_INTERVAL_US, QSPI_POLL_TIMEOUT_US);

	if (ret) {
		dev_err(q->dev,
			"%s timed out waiting for fifo to clear\n",
			__func__);
		bytes_to_write = 0;
	}

	writel(QSPI_ACTION_EN, q->csr_base + QSPI_ACTION_REG);

	return bytes_to_write;
}

static int altera_asmip2_prep(struct spi_nor *nor, enum spi_nor_ops ops)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;

	mutex_lock(&q->bus_mutex);

	return 0;
}

static void altera_asmip2_unprep(struct spi_nor *nor, enum spi_nor_ops ops)
{
	struct altera_asmip2_flash *flash = nor->priv;
	struct altera_asmip2 *q = flash->q;

	mutex_unlock(&q->bus_mutex);
}

static int altera_asmip2_setup_banks(struct device *dev,
				      u32 bank, struct device_node *np)
{
	struct altera_asmip2 *q = dev_get_drvdata(dev);
	struct altera_asmip2_flash *flash;
	struct spi_nor *nor;
	int ret = 0;

	if (bank > q->num_flashes - 1)
		return -EINVAL;

	flash = devm_kzalloc(q->dev, sizeof(*flash), GFP_KERNEL);
	if (!flash)
		return -ENOMEM;

	q->flash[bank] = flash;
	flash->q = q;

	nor = &flash->nor;
	nor->dev = dev;
	nor->priv = flash;
	nor->mtd.priv = nor;
	spi_nor_set_flash_node(nor, np);

	/* spi nor framework*/
	nor->read_reg = altera_asmip2_read_reg;
	nor->write_reg = altera_asmip2_write_reg;
	nor->read = altera_asmip2_read;
	nor->write = altera_asmip2_write;
	nor->prepare = altera_asmip2_prep;
	nor->unprepare = altera_asmip2_unprep;

	ret = spi_nor_scan(nor, NULL, SPI_NOR_FAST);
	if (ret) {
		dev_err(nor->dev, "flash not found\n");
		return ret;
	}

	ret =  mtd_device_register(&nor->mtd, NULL, 0);

	return ret;
}

static int altera_asmip2_create(struct device *dev, void __iomem *csr_base)
{
	struct altera_asmip2 *q;
	u32 reg;

	q = devm_kzalloc(dev, sizeof(*q), GFP_KERNEL);
	if (!q)
		return -ENOMEM;

	q->dev = dev;
	q->csr_base = csr_base;

	mutex_init(&q->bus_mutex);

	dev_set_drvdata(dev, q);

	reg = readl(q->csr_base + QSPI_ACTION_REG);
	if (!(reg & QSPI_ACTION_RST)) {
		writel((reg | QSPI_ACTION_RST), q->csr_base + QSPI_ACTION_REG);
		dev_info(dev, "%s asserting reset\n", __func__);
		udelay(10);
	}

	writel((reg & ~QSPI_ACTION_RST), q->csr_base + QSPI_ACTION_REG);
	udelay(10);

	return 0;
}

static int altera_asmip2_add_bank(struct device *dev,
			 u32 bank, struct device_node *np)
{
	struct altera_asmip2 *q = dev_get_drvdata(dev);

	if (q->num_flashes >= ALTERA_ASMIP2_MAX_NUM_FLASH_CHIP)
		return -ENOMEM;

	q->num_flashes++;

	return altera_asmip2_setup_banks(dev, bank, np);
}

static int altera_asmip2_remove_banks(struct device *dev)
{
	struct altera_asmip2 *q = dev_get_drvdata(dev);
	struct altera_asmip2_flash *flash;
	int i;
	int ret = 0;

	if (!q)
		return -EINVAL;

	/* clean up for all nor flash */
	for (i = 0; i < q->num_flashes; i++) {
		flash = q->flash[i];
		if (!flash)
			continue;

		/* clean up mtd stuff */
		ret = mtd_device_unregister(&flash->nor.mtd);
		if (ret) {
			dev_err(dev, "error removing mtd\n");
			return ret;
		}
	}

	return 0;
}

static int altera_asmip2_probe_with_pdata(struct platform_device *pdev,
			     struct altera_asmip2_plat_data *qdata)
{
	struct device *dev = &pdev->dev;
	int ret, i;

	ret = altera_asmip2_create(dev, qdata->csr_base);

	if (ret) {
		dev_err(dev, "failed to create qspi device %d\n", ret);
		return ret;
	}

	for (i = 0; i < qdata->num_chip_sel; i++) {
		ret = altera_asmip2_add_bank(dev, i, NULL);
		if (ret) {
			dev_err(dev, "failed to add qspi bank %d\n", ret);
			break;
		}
	}

	return ret;
}

static int altera_asmip2_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct altera_asmip2_plat_data *qdata;
#ifdef CONFIG_OF
	struct device_node *np = pdev->dev.of_node;
	struct resource *res;
	void __iomem *csr_base;
	u32 bank;
	int ret;
	struct device_node *pp;
#endif

	qdata = dev_get_platdata(dev);

	if (qdata)
		return altera_asmip2_probe_with_pdata(pdev, qdata);

#ifdef CONFIG_OF
	if (!np) {
		dev_err(dev, "no device tree found %p\n", pdev);
		return -ENODEV;
	}

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	csr_base = devm_ioremap_resource(dev, res);
	if (IS_ERR(csr_base)) {
		dev_err(dev, "%s: ERROR: failed to map csr base\n", __func__);
		return PTR_ERR(csr_base);
	}

	ret = altera_asmip2_create(dev, csr_base);

	if (ret) {
		dev_err(dev, "failed to create qspi device\n");
		return ret;
	}

	for_each_available_child_of_node(np, pp) {
		of_property_read_u32(pp, "reg", &bank);
		if (bank >= ALTERA_ASMIP2_MAX_NUM_FLASH_CHIP) {
			dev_err(dev, "bad reg value %u >= %u\n", bank,
				ALTERA_ASMIP2_MAX_NUM_FLASH_CHIP);
			goto error;
		}

		if (altera_asmip2_add_bank(dev, bank, pp)) {
			dev_err(dev, "failed to add bank %u\n", bank);
			goto error;
		}
	}

	return 0;

error:
	altera_asmip2_remove_banks(dev);
	return -EIO;
#else
	return -EINVAL;
#endif
}

static int altera_asmip2_remove(struct platform_device *pdev)
{
	struct altera_asmip2 *q = dev_get_drvdata(&pdev->dev);

	mutex_destroy(&q->bus_mutex);

	return altera_asmip2_remove_banks(&pdev->dev);
}

static const struct of_device_id altera_asmip2_id_table[] = {
	{ .compatible = "altr,asmi-parallel2-spi-nor",},
	{}
};
MODULE_DEVICE_TABLE(of, altera_asmip2_id_table);

static struct platform_driver altera_asmip2_driver = {
	.driver = {
		.name = ALTERA_ASMIP2_DRV_NAME,
		.of_match_table = altera_asmip2_id_table,
	},
	.probe = altera_asmip2_probe,
	.remove = altera_asmip2_remove,
};
module_platform_driver(altera_asmip2_driver);

MODULE_AUTHOR("Matthew Gerlach <matthew.gerlach@linux.intel.com>");
MODULE_DESCRIPTION("Altera ASMI Parallel II");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:" ALTERA_ASMIP2_DRV_NAME);
