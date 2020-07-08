import time
from opae import fpga

NLB0 = "C6AA954A-9B91-4A37-ABC1-1D9F0709DCC3"

def cl_align(addr):
    return addr >> 6

print "PyOPAE sample of Xilinx CDMA IP."

tokens = fpga.enumerate(type=fpga.ACCELERATOR, guid=NLB0)
assert tokens, "Could not enumerate accelerator: {}".format(NlB0)

with fpga.open(tokens[0], fpga.OPEN_SHARED) as handle:
    src = fpga.allocate_shared_buffer(handle, 4096)
    dst = fpga.allocate_shared_buffer(handle, 4096)

    print "I buffer physical address 0x%016x" %(src.io_address())
    print "O buffer physical address 0x%016x" %(dst.io_address())   
   
    handle.write_csr64(0x10018, cl_align(src.io_address())) # cacheline-aligned
    handle.write_csr64(0x10020, cl_align(dst.io_address())) # cacheline-aligned
    handle.write_csr32(0x10028, 4096)
    r32_val = handle.read_csr32(0x10004)
    while r32_val & 0x2 != 0x2:
        time.sleep(0.001)
        r32_val = handle.read_csr32(0x10004)

print "PyOPAE sample done."

