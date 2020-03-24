import time
from opae import fpga

NLB0 = "C6AA954A-9B91-4A37-ABC1-1D9F0709DCC3"

def cl_align(addr):
    return addr >> 6

tokens = fpga.enumerate(type=fpga.ACCELERATOR, guid=NLB0)
assert tokens, "Could not enumerate accelerator: {}".format(NlB0)

with fpga.open(tokens[0], fpga.OPEN_SHARED) as handle:
    src = fpga.allocate_shared_buffer(handle, 4096)
    dst = fpga.allocate_shared_buffer(handle, 4096)
    
    handle.write_csr64(0x1018, cl_align(src.io_address())) # cacheline-aligned
    handle.write_csr64(0x1020, cl_align(dst.io_address())) # cacheline-aligned
    handle.write_csr32(0x1028, 4096)
    r32_val = handle.read_csr32(0x1004)
    while r32_val & 0x2 != 0x2:
        time.sleep(0.001)
        r32_val = handle.read_csr32(0x1004)

