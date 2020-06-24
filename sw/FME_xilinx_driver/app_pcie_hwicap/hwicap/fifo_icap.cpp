/**
 * Copyright (C) 2016-2020 Xilinx, Inc
 * Author(s) : Sonal Santan
 *           : Hem Neema
 *           : Ryan Radjabi
 *
 * Licensed under the Apache License, Version 2.0 (the "License"). You may
 * not use this file except in compliance with the License. A copy of the
 * License is located at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

#include <iostream>
#include <string>
#include <fstream>
#include <cassert>
#include <thread>
#include <cstring>
#include <vector>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio.h>
#include <stddef.h>
#include "fifo_icap.h"
#include "icap.h"

#ifdef WINDOWS
#define __func__ __FUNCTION__
#endif



//#define FLASH_BASE_ADDRESS BPI_FLASH_OFFSET
#define PAGE_SIZE 256


/* Register offsets for the XHwIcap device. */
#define XHI_GIER_OFFSET    0x1C  /* Device Global Interrupt Enable Reg */
#define XHI_IPISR_OFFSET 0x20  /* Interrupt Status Register */
#define XHI_IPIER_OFFSET 0x28  /* Interrupt Enable Register */
#define XHI_WF_OFFSET 0x100 /* Write FIFO */
#define XHI_RF_OFFSET 0x104 /* Read FIFO */
#define XHI_SZ_OFFSET 0x108 /* Size Register */
#define XHI_CR_OFFSET 0x10C /* Control Register */
#define XHI_SR_OFFSET 0x110 /* Status Register */
#define XHI_WFV_OFFSET 0x114 /* Write FIFO Vacancy Register */
#define XHI_RFO_OFFSET 0x118 /* Read FIFO Occupancy Register */

/* Device Global Interrupt Enable Register (GIER) bit definitions */

#define XHI_GIER_GIE_MASK 0x80000000 /* Global Interrupt enable Mask */




FIFO_Icap::FIFO_Icap( char *inMap )
{
    mMgmtMap = inMap; // brought in from ICAP object
}

/**
 * @brief FIFO_Icap::~FIFO_Icap
 *
 * - munmap
 * - delete file descriptor
 */
FIFO_Icap::~FIFO_Icap()
{
}



int FIFO_Icap::xclProgramPRbit(const char *prFile) {
    //  if (mLogStream.is_open()) {
    //    mLogStream << __func__ << ", " << std::this_thread::get_id() << ", " << prFile << std::endl;
    //  }

    std::streampos size;
    char * inbuffer;
    uint32_t tmpdata;
    uint32_t i = 0;

    //clearBuffers();
    //recordList.clear();

    if (!mMgmtMap)
        return -EACCES;

    std::string line;
    std::ifstream prStream(prFile, std::ios::in|std::ios::binary|std::ios::ate);
    if (prStream.is_open()) {
        size = prStream.tellg();
        inbuffer = new char [size];
        prStream.seekg(0, std::ios::beg);
        prStream.read(inbuffer, size);
        prStream.close();
        std::cout << "Read PR file to buffer" << std::endl;
        std::cout << "  size:" << size << " Bytes" << std::endl;
    } else {
        std::cout << "Unable to open rp file" << std::endl;
            return -1;
    }


    for (i=0; i<(size); i=i+4) {
        tmpdata = 0;
        tmpdata += (inbuffer[i]<<24) & 0xff000000;
        tmpdata += (inbuffer[i+1]<<16) & 0x00ff0000;
        tmpdata += (inbuffer[i+2]<<8) & 0x0000ff00;
        tmpdata += (inbuffer[i+3]) & 0x000000ff;
        writeReg(XHI_WF_OFFSET, tmpdata);
        if ((i%64 == 0) &&(i>0)) {
            writeReg(XHI_CR_OFFSET, 1);

        }
    }
    writeReg(XHI_CR_OFFSET, 1);

    return 0;

}

unsigned FIFO_Icap::readReg(unsigned RegOffset) {
    unsigned value;
    if( ICAP::icapRead( 0, (unsigned long long)mMgmtMap + RegOffset, &value, 4 ) != 0 ) {
        assert(0);
        std::cout << "read reg ERROR" << std::endl;
    }
    return value;
}

int FIFO_Icap::writeReg(unsigned RegOffset, unsigned value) {
    int status = ICAP::icapWrite(0, (unsigned long long)mMgmtMap + RegOffset, &value, 4);
    if(status != 0) {
        assert(0);
        std::cout << "write reg ERROR " << std::endl;
    }
    return 0;
}
