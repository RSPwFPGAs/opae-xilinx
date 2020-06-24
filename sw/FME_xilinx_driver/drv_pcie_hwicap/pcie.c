

#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/fs.h>
#include <linux/uaccess.h>   /* copy_to_user */
#include <linux/ioport.h>
#include <linux/kthread.h>
#include <linux/vmalloc.h>
#include "regs.h"
#include "pcie.h"


int PCIe_Open(struct inode *inode, struct file *filp)
{
	struct mgmt_char_dev *lro_char;
	struct mgmt_dev *lro;
	/* pointer to containing data structure of the character device inode */
	lro_char = container_of(inode->i_cdev, struct mgmt_char_dev, cdev);

	/* create a reference to our char device in the opened file */
	filp->private_data = lro_char;
	lro = lro_char->lro;
	BUG_ON(!lro);
	printk(KERN_INFO "/dev/xclmgmt0 %s opened by pid: %d\n", DRV_NAME, pid_nr(task_tgid(current)) );
#ifdef AXI_FIREWALL
	//mutex_lock(&lro->proc_mutex);
	//xclmgmt_list_add(lro_char->lro, task_tgid(current));// multi device been open
	//mutex_unlock(&lro->proc_mutex);
#endif
    return SUCCESS;
}


int PCIe_Release(struct inode *inode, struct file *filp)
{
	struct mgmt_dev *lro;
	struct mgmt_char_dev *lro_char = (struct mgmt_char_dev *)filp->private_data;
	BUG_ON(!lro_char);

	/* fetch device specific data stored earlier during open */
	printk(KERN_INFO "Closing node %s (0x%p, 0x%p) opened by pid: %d\n", DRV_NAME, inode, filp, pid_nr(task_tgid(current)) );
	lro = lro_char->lro;
	BUG_ON(!lro);
#ifdef AXI_FIREWALL
	//mutex_lock(&lro->proc_mutex);
	//xclmgmt_list_remove(lro_char->lro, task_tgid(current));
	//mutex_unlock(&lro->proc_mutex);
#endif
	
	return 0;

}


ssize_t PCIe_Write(struct file *filp, const char *buf, size_t count,
                       loff_t *f_pos)
{
	int ret = SUCCESS;
	return (ret);
}


ssize_t PCIe_Read(struct file *filp, char *buf, size_t count, loff_t *f_pos)
{
	struct mgmt_char_dev *lro_char = (struct mgmt_char_dev *)filp->private_data;
	struct mgmt_dev *lro;
	long result = 0;
	BUG_ON(!lro_char);
	lro = lro_char->lro;
	BUG_ON(!lro);
	struct hwicap_status st;
	st.hw_status = lro->hwicap_status;
	if (copy_to_user(buf,&st,sizeof(struct hwicap_status)))
	{
		printk(KERN_INFO "%s PCIe_Read err\n", __FUNCTION__);
		return -EFAULT;
	}	
	return (0);
}
void freezeAXIGate(struct mgmt_dev *lro)
{
	u8 w = 0x1;
	u32 t;

	BUG_ON(lro->axi_gate_frozen);
	printk(KERN_DEBUG "IOCTL %s:%d\n", __FILE__, __LINE__);


	iowrite8(w, lro->bar[PF_HWICAP_BAR] + AXI_GATE_OFFSET1);
	ndelay(500);
	iowrite8(w, lro->bar[PF_HWICAP_BAR] + AXI_GATE_OFFSET2);
	
	lro->axi_gate_frozen = 1;
	printk(KERN_DEBUG "%s: Froze AXI gate\n", DRV_NAME);

	t = 0xC;
	iowrite32(t, lro->bar[PF_HWICAP_BAR] + XHWICAP_CR);
	ndelay(20);
	printk(KERN_DEBUG "%s: Reset all register and cleared all FIFOs \n", DRV_NAME);

}

void freeAXIGate(struct mgmt_dev *lro)
{
	/*
	 * First pulse the OCL RESET. This is important for PR with multiple
	 * clocks as it resets the edge triggered clock converter FIFO
	 */
	u8 w = 0x0;
	u32 t;

	BUG_ON(!lro->axi_gate_frozen);
	iowrite8(w, lro->bar[PF_HWICAP_BAR] + AXI_GATE_OFFSET1);
	ndelay(500);
	iowrite8(w, lro->bar[PF_HWICAP_BAR] + AXI_GATE_OFFSET2);
	lro->axi_gate_frozen = 0;
	printk(KERN_DEBUG "%s: Un-froze AXI gate\n", DRV_NAME);

}
long bitstream_clear_icap(struct mgmt_dev *lro)
{
	long err = 0;
	const char *buffer;
	unsigned length;

//  printk(KERN_DEBUG "IOCTL %s:%d\n", __FILE__, __LINE__);
	buffer = lro->stash.clear_bitstream;
	if (!buffer)
		return 0;

	length = lro->stash.clear_bitstream_length;
	printk(KERN_INFO "%s: Downloading clearing bitstream of length 0x%x\n", DRV_NAME, length);
	//err = bitstream_icap(lro, buffer, length);

	vfree(lro->stash.clear_bitstream);
	lro->stash.clear_bitstream = 0;
	lro->stash.clear_bitstream_length = 0;
	printk(KERN_DEBUG "IOCTL %s:%d\n", __FILE__, __LINE__);

	//
	
	return err;
}

//real download function
static int hwicapWrite(struct mgmt_dev *lro, const u32 *word_buf, int size)
{
	u32 value = 0;
	int i = 0;

	//printk(KERN_INFO "IOCTL %s:%d:%d\n", __FILE__, __LINE__,size);

	for (i = 0; i < size; i++) 
	{
		value = be32_to_cpu(word_buf[i]);
		iowrite32(value, lro->bar[PF_HWICAP_BAR] + XHWICAP_WF);
	}
	//printk(KERN_INFO "IOCTL %s:%d\n", __FILE__, __LINE__);

	value = 0x1;
	iowrite32(value, lro->bar[PF_HWICAP_BAR] + XHWICAP_CR);
	for (i = 0; i < 20; i++) 
	{
		value = ioread32(lro->bar[PF_HWICAP_BAR] + XHWICAP_CR);
		//printk(KERN_INFO "XHWICAP_CR %x\n", value);
		if ((value & 0x1) == 0)
			return 0;
		ndelay(50);

	}

	printk(KERN_INFO "%d us timeout waiting for FPGA after writing %d dwords\n", 50 * 10, size);
	return -EIO;
}


static int bitstream_icap_helper(struct mgmt_dev *lro, const u32 *word_buffer, unsigned word_count)
{
	unsigned remain_word = word_count;
	unsigned word_written = 0;
	int wr_fifo_vacancy = 0;
	int err = 0;

	for (remain_word = word_count; remain_word > 0; remain_word -= word_written) 
	{
		wr_fifo_vacancy = ioread32(lro->bar[PF_HWICAP_BAR] + XHWICAP_WFV);
		if (wr_fifo_vacancy <= 0) 
		{
			lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
			printk(KERN_INFO "IOCTL %s:%d vacancy: %d:%0x\n", __FILE__, __LINE__, wr_fifo_vacancy,lro->bar[PF_HWICAP_BAR]);
			err = -EIO;
			break;
		}
		word_written = (wr_fifo_vacancy < remain_word) ? wr_fifo_vacancy : remain_word;
		if (hwicapWrite(lro, word_buffer, word_written) != 0) 
		{
			lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
			printk(KERN_INFO "hwicapWrite error %s:%d\n", __FILE__, __LINE__);
			err = -EIO;
			break;
		}
		word_buffer += word_written;
	}
	return err;
}

static int wait_for_done(struct mgmt_dev *lro)
{
	u32 w;
	int i = 0;

	printk(KERN_INFO "IOCTL %s:%d\n", __FILE__, __LINE__);
	for (i = 0; i < 1000; i++) {
		udelay(5);
		w = ioread32(lro->bar[PF_HWICAP_BAR] + XHWICAP_SR);
		printk(KERN_INFO "XHWICAP_SR %x\n", w);
		if (w & 0x5)
		{	
			printk(KERN_INFO "bitstream download success!!!\n");
			lro->hwicap_status = ICAP_DOWNLOAD_FINISH;
			return 0;
		}
	}
	printk(KERN_INFO "%d us timeout waiting for FPGA after bitstream download\n", 5 * 10);
	return -ETIMEDOUT;
}
static int bitstream_parse_header(const unsigned char *Data, unsigned int Size, XHwIcap_Bit_Header *Header)
{
	unsigned int I;
	unsigned int Len;
	unsigned int Tmp;
	unsigned int Index;

	/* Start Index at start of bitstream */
	Index = 0;

	/* Initialize HeaderLength.  If header returned early inidicates
	 * failure.
	 */
	Header->HeaderLength = XHI_BIT_HEADER_FAILURE;

	/* Get "Magic" length */
	Header->MagicLength = Data[Index++];
	Header->MagicLength = (Header->MagicLength << 8) | Data[Index++];

	/* Read in "magic" */
	for (I = 0; I < Header->MagicLength - 1; I++) {
		Tmp = Data[Index++];
		if (I%2 == 0 && Tmp != XHI_EVEN_MAGIC_BYTE)
			return -1;   /* INVALID_FILE_HEADER_ERROR */

		if (I%2 == 1 && Tmp != XHI_ODD_MAGIC_BYTE)
			return -1;   /* INVALID_FILE_HEADER_ERROR */

	}

	/* Read null end of magic data. */
	Tmp = Data[Index++];

	/* Read 0x01 (short) */
	Tmp = Data[Index++];
	Tmp = (Tmp << 8) | Data[Index++];

	/* Check the "0x01" half word */
	if (Tmp != 0x01)
		return -1;	 /* INVALID_FILE_HEADER_ERROR */



	/* Read 'a' */
	Tmp = Data[Index++];
	if (Tmp != 'a')
		return -1;	  /* INVALID_FILE_HEADER_ERROR	*/


	/* Get Design Name length */
	Len = Data[Index++];
	Len = (Len << 8) | Data[Index++];

	/* allocate space for design name and final null character. */
	Header->DesignName = kmalloc(Len, GFP_KERNEL);

	/* Read in Design Name */
	for (I = 0; I < Len; I++)
		Header->DesignName[I] = Data[Index++];


	if (Header->DesignName[Len-1] != '\0')
		return -1;

	/* Read 'b' */
	Tmp = Data[Index++];
	if (Tmp != 'b')
		return -1;	/* INVALID_FILE_HEADER_ERROR */


	/* Get Part Name length */
	Len = Data[Index++];
	Len = (Len << 8) | Data[Index++];

	/* allocate space for part name and final null character. */
	Header->PartName = kmalloc(Len, GFP_KERNEL);

	/* Read in part name */
	for (I = 0; I < Len; I++)
		Header->PartName[I] = Data[Index++];

	if (Header->PartName[Len-1] != '\0')
		return -1;

	/* Read 'c' */
	Tmp = Data[Index++];
	if (Tmp != 'c')
		return -1;	/* INVALID_FILE_HEADER_ERROR */


	/* Get date length */
	Len = Data[Index++];
	Len = (Len << 8) | Data[Index++];

	/* allocate space for date and final null character. */
	Header->Date = kmalloc(Len, GFP_KERNEL);

	/* Read in date name */
	for (I = 0; I < Len; I++)
		Header->Date[I] = Data[Index++];

	if (Header->Date[Len - 1] != '\0')
		return -1;

	/* Read 'd' */
	Tmp = Data[Index++];
	if (Tmp != 'd')
		return -1;	/* INVALID_FILE_HEADER_ERROR  */

	/* Get time length */
	Len = Data[Index++];
	Len = (Len << 8) | Data[Index++];

	/* allocate space for time and final null character. */
	Header->Time = kmalloc(Len, GFP_KERNEL);

	/* Read in time name */
	for (I = 0; I < Len; I++)
		Header->Time[I] = Data[Index++];

	if (Header->Time[Len - 1] != '\0')
		return -1;

	/* Read 'e' */
	Tmp = Data[Index++];
	if (Tmp != 'e')
		return -1;	/* INVALID_FILE_HEADER_ERROR */

	/* Get byte length of bitstream */
	Header->BitstreamLength = Data[Index++];
	Header->BitstreamLength = (Header->BitstreamLength << 8) | Data[Index++];
	Header->BitstreamLength = (Header->BitstreamLength << 8) | Data[Index++];
	Header->BitstreamLength = (Header->BitstreamLength << 8) | Data[Index++];
	Header->HeaderLength = Index;

	printk(KERN_INFO "%s: Design \"%s\"\n%s: Part \"%s\"\n%s: Timestamp \"%s %s\"\n%s: Raw data size 0x%x\n",
	       DRV_NAME, Header->DesignName, DRV_NAME, Header->PartName, DRV_NAME, Header->Time,
	       Header->Date, DRV_NAME, Header->BitstreamLength);

	return 0;
}

static int bitstream_ioctl_icap(struct mgmt_dev *lro, const char __user *bit_buf, unsigned long length)
{
	char *buffer = NULL;
	long err = 0;
	unsigned byte_read;
	unsigned numCharsRead = DMA_HWICAP_BITFILE_BUFFER_SIZE;
	XHwIcap_Bit_Header bit_header;
	
	printk(KERN_INFO "%s: Using kernel mode ICAP bitstream download framework\n", DRV_NAME);
	
	freezeAXIGate(lro);
	
	err = bitstream_clear_icap(lro);
	if (err)
		goto free_buffers;
	
	buffer = kmalloc(DMA_HWICAP_BITFILE_BUFFER_SIZE, GFP_KERNEL);

	if (!buffer) {
		err = -ENOMEM;
		goto free_buffers;
	}
	//parse bitstream header
	
	if (copy_from_user(buffer, bit_buf, DMA_HWICAP_BITFILE_BUFFER_SIZE)) 
	{
		lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
		err = -EFAULT;
		goto free_buffers;
	}
	
	if (bitstream_parse_header(buffer, DMA_HWICAP_BITFILE_BUFFER_SIZE, &bit_header))
	{
		lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
		err = -EINVAL;
		goto free_buffers;
	}
	
	if ((bit_header.HeaderLength + bit_header.BitstreamLength) > length) 
	{
		lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
		err = -EINVAL;
		goto free_buffers;
	}
	bit_buf += bit_header.HeaderLength;


	printk(KERN_INFO "bit HeaderLength:%d \n",bit_header.HeaderLength);
	printk(KERN_INFO "bit BitstreamLength:%d \n",bit_header.BitstreamLength);
	printk(KERN_INFO "bit DesignName:%s \n",bit_header.DesignName);
	printk(KERN_INFO "bit PartName:%s \n",bit_header.PartName);
	
	//clear icap
	iowrite32(0x1c,lro->bar[PF_HWICAP_BAR] + XHWICAP_CR);
	udelay(10);
	for (byte_read = 0; byte_read < length; byte_read += numCharsRead)
	{
		numCharsRead = length - byte_read;
		if (numCharsRead > DMA_HWICAP_BITFILE_BUFFER_SIZE)
			numCharsRead = DMA_HWICAP_BITFILE_BUFFER_SIZE;
		
		if (copy_from_user(buffer, bit_buf, numCharsRead)) 
		{
			lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
			err = -EFAULT;
			goto free_buffers;
		}

		bit_buf += numCharsRead;
		err = bitstream_icap_helper(lro, (u32 *)buffer, numCharsRead / 4);
		if (err) 
		{
			lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
			printk(KERN_INFO "err value AFTER bitstream_icap_helper call from bitstream_ioctl_icap: %ld", err);
			goto free_buffers;
		}
	}

	
	if (wait_for_done(lro)) 
	{
		err = -ETIMEDOUT;
		printk(KERN_INFO "err value wait for done failure: %ld", err);
		goto free_buffers;
	}
	
	
free_buffers:
	freeAXIGate(lro);
	kfree(buffer);
	printk(KERN_INFO "IOCTL %s:%d\n", __FILE__, __LINE__);
	return err;

}

int bitstream_ioctl(struct mgmt_dev *lro, const void __user *arg)
{
	int len = 0;
	struct fme_ioc_bitstream bitstream_obj;
	char __user *buffer;
	long err = 0;
	
	printk(KERN_INFO "%s: %s \n", DRV_NAME, __FUNCTION__);
	//copy length
	if (copy_from_user((void *)&bitstream_obj, arg, sizeof(struct fme_ioc_bitstream)))
	{
		lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
		printk(KERN_INFO "%s copy_from_user err: %ld\n", __FUNCTION__, err);
		return -EFAULT;
	}	
	
	len = bitstream_obj.len;
	buffer = (char __user *)bitstream_obj.buff;
	err = !access_ok(VERIFY_READ, buffer, bitstream_obj.len);
	if (err)
	{
		lro->hwicap_status = ICAP_DOWNLOAD_ERROR;
		printk(KERN_INFO "%s access_ok  err: %ld\n", __FUNCTION__, err);
		return -EFAULT;
	}
	lro->unique_id_last_bitstream = 0;
	bitstream_ioctl_icap(lro, buffer, len);
	
	
	printk(KERN_INFO "%s err: %ld\n", __FUNCTION__, err);
	return err;
}


static long PCIe_Ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{

    struct mgmt_char_dev *lro_char = (struct mgmt_char_dev *)file->private_data;
	struct mgmt_dev *lro;
	long result = 0;
	BUG_ON(!lro_char);
	lro = lro_char->lro;
	BUG_ON(!lro);

	printk(KERN_DEBUG "MGMT IOCTL request %u\n", cmd & 0xff);

	if (lro_char != lro->user_char_dev)
		return -ENOTTY;

	if (_IOC_TYPE(cmd) != XCLMGMT_IOC_MAGIC)
		return -ENOTTY;

	if (_IOC_DIR(cmd) & _IOC_READ)
		result = !access_ok(VERIFY_WRITE, (void __user *)arg, _IOC_SIZE(cmd));
	else if (_IOC_DIR(cmd) & _IOC_WRITE)
		result =  !access_ok(VERIFY_READ, (void __user *)arg, _IOC_SIZE(cmd));

	if (result)
		return -EFAULT;

	if(lro->busy)
		return -EBUSY;

	lro->busy = true;
	switch (cmd) 
	{
		case FME_IOC_ICAP_DOWNLOAD:
			lro->hwicap_status = ICAP_DOWNLOADING;
			result = bitstream_ioctl(lro, (void __user *)arg);
			break;
		default:
		printk(KERN_DEBUG "MGMT default IOCTL request %u\n", cmd & 0xff);
		result = -ENOTTY;
	}
	lro->busy = false;
	return result;//end
}
struct file_operations PCIe_opf = {
	.owner = THIS_MODULE,
    .read  =     PCIe_Read,
    .write  =    PCIe_Write,
    .unlocked_ioctl =  PCIe_Ioctl,
    .open   =   PCIe_Open,
    .release  =  PCIe_Release,
};


static struct mgmt_char_dev *create_char(struct mgmt_dev *lro, int bar)
{
	struct mgmt_char_dev *lro_char;
	int rc;

	printk(KERN_INFO "%s: %s \n", DRV_NAME, __FUNCTION__);
	
	/* allocate book keeping data structure */
	lro_char = kzalloc(sizeof(struct mgmt_char_dev), GFP_KERNEL);
	if (!lro_char)
		return NULL;

	/* dynamically pick a number into cdevno */
	lro_char->lro = lro;
	lro_char->bar = bar;
	
	/* couple the control device file operations to the character device */
	cdev_init(&lro_char->cdev, &PCIe_opf);
	lro_char->cdev.owner = THIS_MODULE;
	lro_char->cdev.dev = MKDEV(MAJOR(xclmgmt_devnode), lro->instance);
	rc = cdev_add(&lro_char->cdev, lro_char->cdev.dev, 1);
	if (rc < 0) {
		printk(KERN_INFO "cdev_add() = %d\n", rc);
		goto fail_add;
	}

	lro_char->sys_device = device_create(xclmgmt_class, &lro->pci_dev->dev, 
										lro_char->cdev.dev, NULL,DRV_NAME "%d", lro->instance);

	if (IS_ERR(lro_char->sys_device)) {
		rc = PTR_ERR(lro_char->sys_device);
		goto fail_device;
	}
	else
		goto success;
fail_device:
	cdev_del(&lro_char->cdev);
fail_add:
	kfree(lro_char);
	lro_char = NULL;
success:
	return lro_char;
}

/*
 * Unmap the BAR regions that had been mapped earlier using map_bars()
 */
static void unmap_bars(struct mgmt_dev *lro)
{
	int i;
	for (i = 0; i < PF_MAX_BAR; i++) {
		/* is this BAR mapped? */
		if (lro->bar[i]) {
			/* unmap BAR */
			pci_iounmap(lro->pci_dev, lro->bar[i]);
			/* mark as unmapped */
			lro->bar[i] = NULL;
		}
	}
}

static int map_bars(struct mgmt_dev *lro)
{
	int rc;
	int i;

	/* iterate through all the BARs */
	for (i = 0; i < PF_MAX_BAR; i++) {
		resource_size_t bar_length = pci_resource_len(lro->pci_dev, i);
		resource_size_t map_length = bar_length;
		lro->bar[i] = NULL;
		printk(KERN_INFO "%s: %s Idx: %d, bar len: %d \n", DRV_NAME, __FUNCTION__, i, (int)bar_length);

		/* skip non-present BAR2 and higher */
		if (!bar_length) continue;

		lro->bar[i] = pci_iomap(lro->pci_dev, i, map_length);
		printk(KERN_INFO "%s: %s Idx: %d, bar len: %0x \n", DRV_NAME, __FUNCTION__, i, (lro->bar[i]));
		if (!lro->bar[i]) {
			printk(KERN_INFO "Could not map BAR #%d. See bar_map_size option to reduce the map size.\n", i);
			rc = -EIO;
			goto fail;
		}

		lro->bar_map_size[i] = bar_length;
	}
	/* succesfully mapped all required BAR regions */
	rc = 0;
	goto success;
fail:
	/* unwind; unmap any BARs that we did map */
	unmap_bars(lro);
success:
	return rc;
}

static int destroy_sg_char(struct mgmt_char_dev *lro_char)
{
	BUG_ON(!lro_char);
	BUG_ON(!lro_char->lro);
	BUG_ON(!xclmgmt_class);
	BUG_ON(!lro_char->sys_device);
	if (lro_char->sys_device)
		device_destroy(xclmgmt_class, lro_char->cdev.dev);
	cdev_del(&lro_char->cdev);
	kfree(lro_char);
	return 0;
}

struct pci_dev *find_user_node(const struct pci_dev *pdev, const struct pci_device_id *id)
{
	unsigned int slot = PCI_SLOT(pdev->devfn);
	unsigned int func = PCI_FUNC(pdev->devfn);
	static struct pci_dev *from = NULL;

	printk(KERN_INFO "find_user_node (slot = %d, func = %d, vendor = 0x%04x, device = 0x%04x)\n",
	       slot, func, id->vendor, id->device);

	/* if we are function one then the zero
	 * function has the xdma node */
	if (func == 1)
		return pci_get_slot(pdev->bus, PCI_DEVFN(slot, func-1));

	/* Otherwise, we are likely in a virtualized environment so poke around for
	 * the correct device_id */
	if (from != NULL) {
		// pci_get_device will decrease the refcnt by one of the pci_dev
		// increase refcnt by one pre-emptively to prevent pre-mature deletion
		pci_dev_get(from);
	}

	/* Try to find the next device with the correct device id */
	/* This assumes that the devices are ordered after virtualization */
	from = pci_get_device(id->vendor, id->device+1, from);

	/* TODO: validate that both functions are on the same device */
	/* this could be some kind of loop back function or a unique identifier */
	return from;
}

static int PCIe_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
	int rc = 0;
	printk(KERN_INFO DRV_NAME "enter PCIe_probe......\n");

	u32 value;
	struct mgmt_dev *lro = NULL;
	
	printk(KERN_DEBUG "probe(pdev = 0x%p, pci_id = 0x%p)\n", pdev, id);

	rc = pci_enable_device(pdev);
	if (rc) {
		printk(KERN_DEBUG "pci_enable_device() failed, rc = %d.\n", rc);
		return rc;
	}

	/* allocate zeroed device book keeping structure */
	lro = kzalloc(sizeof(struct mgmt_dev), GFP_KERNEL);
	if (!lro) {
		printk(KERN_DEBUG "Could not kzalloc(xclmgmt_dev).\n");
		goto err_alloc;
	}

	/* create a device to driver reference */
	dev_set_drvdata(&pdev->dev, lro);
	/* create a driver to device reference */
	lro->pci_dev = pdev;
	printk(KERN_DEBUG "probe() lro = 0x%p\n", lro);
	value = lro->pci_dev->subsystem_device;
	printk(KERN_DEBUG "pci_indevice()\n");

	printk(KERN_DEBUG "pci_request_regions()\n");
	rc = pci_request_regions(pdev, DRV_NAME);
	/* could not request all regions? */
	if (rc) {
		printk(KERN_DEBUG "pci_request_regions() = %d, device in use?\n", rc);
		goto err_regions;
	}

	printk(KERN_DEBUG "map_bars()\n");
	/* map BARs */
	rc = map_bars(lro);
	if (rc){
		goto err_map;
	}
	
	/*create char device*/
	lro->instance = instance++;
	lro->user_char_dev = create_char(lro, PF_HWICAP_BAR);
	if (!lro->user_char_dev) {
		printk(KERN_DEBUG "create_char(user_char_dev) failed\n");
		goto err_cdev;
	}

	lro->stash.magic = 0xBBBBBBBBUL;

	lro->busy = false;//
	xclmgmt_dev_table[lro->instance] = lro;
	goto end;
	
err_user:
	destroy_sg_char(lro->user_char_dev);
err_cdev:
	xclmgmt_dev_table[lro->instance] = NULL;
	unmap_bars(lro);
err_map:
	pci_release_regions(pdev);
err_regions:
	kfree(lro);
	dev_set_drvdata(&pdev->dev, NULL);
err_alloc:
	pci_disable_device(pdev);
end:
	return rc;
	
}
/*

*/
static int sriov_config(struct pci_dev *pdev, int num_vfs)
{

	int rv;
	if (num_vfs > 4) 
	{
		pr_info("%s, clamp down # of VFs %d -> %d.\n",
			dev_name(&pdev->dev), num_vfs, 2);
		num_vfs = 4;
	}
	
	rv = pci_enable_sriov(pdev, num_vfs);
	if (rv) {
		pr_info("%s, enable sriov %d failed %d.\n",
			dev_name(&pdev->dev), num_vfs, rv);
		pci_disable_sriov(pdev);
		return 0;
	}
	
	return num_vfs;//write error: Invalid argument
}


static void PCIe_remove(struct pci_dev *pdev)
{
	printk(KERN_INFO DRV_NAME "enter PCIe_remove......\n");

	struct mgmt_dev *lro;
	printk(KERN_INFO "remove(0x%p)\n", pdev);
	
	if ((pdev == 0) || (dev_get_drvdata(&pdev->dev) == 0)) 
	{
		printk(KERN_INFO
		       "remove(dev = 0x%p) pdev->dev.driver_data = 0x%p\n",
		       pdev, dev_get_drvdata(&pdev->dev));
		return;
	}
	
	lro = (struct mgmt_dev *)dev_get_drvdata(&pdev->dev);
	printk(KERN_INFO "remove(dev = 0x%p) where pdev->dev.driver_data = 0x%p\n",pdev, lro);
	if (lro->pci_dev != pdev) 
	{
		printk(KERN_INFO"pdev->dev.driver_data->pci_dev (0x%08lx) != pdev (0x%08lx)\n",(unsigned long)lro->pci_dev, (unsigned long)pdev);
	}

	xclmgmt_dev_table[lro->instance] = NULL;


#ifdef AXI_FIREWALL
	mutex_lock(&lro->proc_mutex);
	xclmgmt_list_del(lro);
	mutex_unlock(&lro->proc_mutex);
#endif

	/* remove user character device */
	if (lro->user_char_dev) {
		destroy_sg_char(lro->user_char_dev);
		lro->user_char_dev = 0;
	}

	/* unmap the BARs */
	unmap_bars(lro);
	printk(KERN_INFO "Unmapping BARs.\n");
	pci_disable_device(pdev);
	pci_release_regions(pdev);

	kfree(lro);
	dev_set_drvdata(&pdev->dev, NULL);
	
}



static struct pci_driver pcie_driver = {
	.name = DRV_NAME,
	.id_table = pci_ids,
	.probe = PCIe_probe,
	.remove = PCIe_remove,
	.sriov_configure = sriov_config,
	/* resume, suspend are optional */
};

static int PCIe_init(void)
{
	int res;
	int i;

	printk(KERN_INFO DRV_NAME " %s init()\n", MGMT_MODULE_VERSION);
	for (i = 0; i < XCLMGMT_MINOR_COUNT; i++)
	{
		xclmgmt_dev_table[i] = NULL;
	}
	xclmgmt_class = class_create(THIS_MODULE, DRV_NAME);
	if (IS_ERR(xclmgmt_class))
	{
		return PTR_ERR(xclmgmt_class);
	}
	res = alloc_chrdev_region(&xclmgmt_devnode, XCLMGMT_MINOR_BASE,
				  XCLMGMT_MINOR_COUNT, DRV_NAME);
	if (res)
		goto alloc_err;

	res = pci_register_driver(&pcie_driver);//////////////////////////////////////
	if (!res)
		return 0;

	unregister_chrdev_region(xclmgmt_devnode, XCLMGMT_MINOR_COUNT);
alloc_err:
	printk(KERN_INFO DRV_NAME " init() err\n");
	class_destroy(xclmgmt_class);
	return res;
}

static void PCIe_exit(void)
{

 	printk(KERN_INFO DRV_NAME" exit()\n");
	
	/* unregister this driver from the PCI bus driver */
	pci_unregister_driver(&pcie_driver);
	unregister_chrdev_region(xclmgmt_devnode, XCLMGMT_MINOR_COUNT);
	class_destroy(xclmgmt_class);
}

module_init(PCIe_init);
module_exit(PCIe_exit);
MODULE_DESCRIPTION("Xilinx HWICAP driver");
MODULE_AUTHOR("xilinx");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:xilinx_hwicap");


