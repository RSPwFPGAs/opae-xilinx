#include "afu.h"

static void port_check_reg(struct device *dev, void __iomem *addr,
				const char *reg_name, u64 dflt)
{
	u64 value = readq(addr);

	if (value != dflt)
		dev_dbg(dev, "%s: incorrect value 0x%llx vs defautl 0x%llx\n",
				reg_name, (unsigned long long)value,
				(unsigned long long)dflt);
}

struct feature_port_header hdr_dflt = {
	.port_mailbox		= 0x0000000000000000,
	.scratchpad		= 0x0000000000000000,
	.capability = {
		.csr		= 0x0000000100010000,
	},
	.control = {
		/* Port Reset Bit is cleared in PCIe driver */
		.csr		= 0x0000000000000004,
	},
	.status = {
		.csr		= 0x0000000000000000,
	},
	.rsvd2			= 0x0000000000000000,
	.user_clk_freq_cmd0	= 0x0000000000000000,
	.user_clk_freq_cmd1	= 0x0000000000000000,
	.user_clk_freq_sts0	= 0x0000000000000000,
	.user_clk_freq_sts1	= 0x0000000000000000,
};

int port_hdr_test(struct platform_device *pdev, struct feature *feature)
{
	struct feature_port_header *port_hdr = feature->ioaddr;

	/* Check if default value of hardware registers matches with spec */
	port_check_reg(&pdev->dev, &port_hdr->port_mailbox,
			"hdr:port_mailbox", hdr_dflt.port_mailbox);
	port_check_reg(&pdev->dev, &port_hdr->scratchpad,
			"hdr:scratchpad", hdr_dflt.scratchpad);
	port_check_reg(&pdev->dev, &port_hdr->capability,
			"hdr:capability", hdr_dflt.capability.csr);
	port_check_reg(&pdev->dev, &port_hdr->control,
			"hdr:control", hdr_dflt.control.csr);
	port_check_reg(&pdev->dev, &port_hdr->status,
			"hdr:status", hdr_dflt.status.csr);
	port_check_reg(&pdev->dev, &port_hdr->rsvd2,
			"hdr:rsvd2", hdr_dflt.rsvd2);
	port_check_reg(&pdev->dev, &port_hdr->user_clk_freq_cmd0,
			"hdr:user_clk_cmd0", hdr_dflt.user_clk_freq_cmd0);
	port_check_reg(&pdev->dev, &port_hdr->user_clk_freq_cmd1,
			"hdr:user_clk_cmd1", hdr_dflt.user_clk_freq_cmd1);
	port_check_reg(&pdev->dev, &port_hdr->user_clk_freq_sts0,
			"hdr:user_clk_sts0", hdr_dflt.user_clk_freq_sts0);
	port_check_reg(&pdev->dev, &port_hdr->user_clk_freq_sts1,
			"hdr:user_clk_sts1", hdr_dflt.user_clk_freq_sts1);

	dev_dbg(&pdev->dev, "%s finished\n", __func__);

	return 0;
}

struct feature_port_error err_dflt = {
	.error_mask = {
		.csr		= 0x0000000000000000,
	},
	.port_error = {
		.csr		= 0x0000000000000000,
	},
	.port_first_error = {
		.csr		= 0x0000000000000000,
	},
	.malreq0 = {
		.header_lsb	= 0x0000000000000000,
	},
	.malreq1 = {
		.header_msb	= 0x0000000000000000,
	},
	.port_debug = {
		.port_debug	= 0x0000000000000000,
	},
};

int port_err_test(struct platform_device *pdev, struct feature *feature)
{
	struct feature_port_error *port_err = feature->ioaddr;

	port_check_reg(&pdev->dev, &port_err->error_mask,
			"err:error_mask", err_dflt.error_mask.csr);
	port_check_reg(&pdev->dev, &port_err->port_error,
			"err:port_error", err_dflt.port_error.csr);
	port_check_reg(&pdev->dev, &port_err->port_first_error,
			"err:port_first_err", err_dflt.port_first_error.csr);
	port_check_reg(&pdev->dev, &port_err->malreq0,
			"err:malreq0", err_dflt.malreq0.header_lsb);
	port_check_reg(&pdev->dev, &port_err->malreq1,
			"err:malreq1", err_dflt.malreq1.header_msb);
	port_check_reg(&pdev->dev, &port_err->port_debug,
			"err:port_debug", err_dflt.port_debug.port_debug);

	dev_dbg(&pdev->dev, "%s finished\n", __func__);
	return 0;
}

struct feature_port_umsg umsg_dflt = {
	.capability = {
		.csr		= 0x0000000000000008,
	},
	.baseaddr = {
		.csr		= 0x0000000000000000,
	},
	.mode = {
		.csr		= 0x0000000000000000,
	},
};

int port_umsg_test(struct platform_device *pdev, struct feature *feature)
{
	struct feature_port_umsg *port_umsg = feature->ioaddr;

	port_check_reg(&pdev->dev, &port_umsg->capability,
				"umsg:capaiblity", umsg_dflt.capability.csr);
	port_check_reg(&pdev->dev, &port_umsg->baseaddr,
				"umsg:baseaddr", umsg_dflt.baseaddr.csr);
	port_check_reg(&pdev->dev, &port_umsg->mode,
				"umsg:mode", umsg_dflt.mode.csr);

	dev_dbg(&pdev->dev, "%s finished\n", __func__);
	return 0;
}

struct feature_port_stp stp_dflt = {
	.stp_status = {
		.csr		= 0x0000000000000000,
	},
};

int port_stp_test(struct platform_device *pdev,	struct feature *feature)
{
	struct feature_port_stp *port_stp = feature->ioaddr;

	port_check_reg(&pdev->dev, &port_stp->stp_status,
				"stp:stp_csr", stp_dflt.stp_status.csr);

	dev_dbg(&pdev->dev, "%s finished\n", __func__);
	return 0;
}
