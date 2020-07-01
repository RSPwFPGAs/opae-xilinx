/**
 * Author(s) : Bibo Yang
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
#include "reg_icap.h"
#include "icap.h"

#ifdef WINDOWS
#define __func__ __FUNCTION__
#endif

#define SHUTDOWNMGR_BASE_0 0x00008000
#define SHUTDOWNMGR_BASE_1 0x00009000
#define SHUTDOWNMGR_BASE_2 0x0000a000
#define SHUTDOWNMGR_BASE_3 0x0000b000
#define SDM_CSR_OFFSET 0x00 /* Control/Status Register */


REG_Icap::REG_Icap( char *inMap )
{
    mMgmtMap = inMap; // brought in from ICAP object
}

/**
 * @brief REG_Icap::~REG_Icap
 *
 * - munmap
 * - delete file descriptor
 */
REG_Icap::~REG_Icap()
{
}

void REG_Icap::freezeShutDownMgr() {
    writeReg((SHUTDOWNMGR_BASE_0 + SDM_CSR_OFFSET), 1);
    writeReg((SHUTDOWNMGR_BASE_1 + SDM_CSR_OFFSET), 1);
    writeReg((SHUTDOWNMGR_BASE_2 + SDM_CSR_OFFSET), 1);
    writeReg((SHUTDOWNMGR_BASE_3 + SDM_CSR_OFFSET), 1);
}

void REG_Icap::releaseShutDownMgr() {
    writeReg((SHUTDOWNMGR_BASE_0 + SDM_CSR_OFFSET), 0);
    writeReg((SHUTDOWNMGR_BASE_1 + SDM_CSR_OFFSET), 0);
    writeReg((SHUTDOWNMGR_BASE_2 + SDM_CSR_OFFSET), 0);
    writeReg((SHUTDOWNMGR_BASE_3 + SDM_CSR_OFFSET), 0);
}

unsigned REG_Icap::readReg(unsigned RegOffset) {
    unsigned value;
    if( ICAP::regRead( 0, (unsigned long long)mMgmtMap + RegOffset, &value, 4 ) != 0 ) {
        assert(0);
        std::cout << "read reg ERROR" << std::endl;
    }
    return value;
}

int REG_Icap::writeReg(unsigned RegOffset, unsigned value) {
    int status = ICAP::regWrite(0, (unsigned long long)mMgmtMap + RegOffset, &value, 4);
    if(status != 0) {
        assert(0);
        std::cout << "write reg ERROR " << std::endl;
    }
    return 0;
}
