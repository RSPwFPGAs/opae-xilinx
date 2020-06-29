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


#include <sys/mman.h>
#include <stddef.h>
#include <fcntl.h>
#include <unistd.h>
#include <cassert>
#include "icap.h"


ICAP::ICAP(const char *f)
{
    micap = nullptr;
    ricap = nullptr;
    mFd = 0;

    if( !mapDevice( f ) )
    {
        std::cout << "Failed to map pcie device." << std::endl;
    }

    micap = new FIFO_Icap(  mMgmtMap );
    ricap = new REG_Icap(   mMgmtMap );

}

ICAP::~ICAP()
{
    if( micap != nullptr )
    {
        delete micap;
        micap = nullptr;
    }
    if( ricap != nullptr )
    {
        delete ricap;
        ricap = nullptr;
    }

    if( mMgmtMap != nullptr )
    {
        munmap( mMgmtMap, mSb.st_size );
    }

    if( mFd > 0 )
    {
        close( mFd );
    }
}

int ICAP::ProgramPRbit(const char *fin)
{
    int retVal = -1;


    ricap->freezeShutDownMgr();
    retVal = micap->xclProgramPRbit( fin );
    ricap->releaseShutDownMgr();
    return retVal;
}

bool ICAP::mapDevice(const char *f)
{
    bool retVal = false;

    std::string mgmtDeviceName = f;
    std::cout << "mgmtDevice Name " << mgmtDeviceName << std::endl;
    std::string resourcePath;
    void *p;
    void *addr = (caddr_t)0;

    std::string devPath = "/sys/bus/pci/devices/" + mgmtDeviceName;

    resourcePath= devPath + "/resource" + BAR_INDEX;

    mFd = open( resourcePath.c_str(), O_RDWR );

    if( mFd > 0 ) {
        if( fstat( mFd, &mSb ) != -1 )
        {
            p = mmap( addr, mSb.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, mFd, 0 );
            if( p == MAP_FAILED )
            {
                std::cout << "mmap failed : " << errno << std::endl;
                perror( "mmap" );
                close( mFd );
            }
            else
            {
                mMgmtMap = (char *)p;
                retVal = true;
            }
        }
    }
    else
    {
        std::cout << "open sysfs failed\n";
    }

    return retVal;
}

int ICAP::pcieBarRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length)
{
    wordcopy(buffer, (void*)offset, length);
    return 0;
}

int ICAP::pcieBarWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length)
{
    wordcopy((void*)offset, buffer, length);
    return 0;
}

int ICAP::icapRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length)
{
    return pcieBarRead( pf_bar, ( offset + ICAP_BASE_ADDRESS ), buffer, length );
}

int ICAP::icapWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length)
{
    return pcieBarWrite( pf_bar, (offset + ICAP_BASE_ADDRESS ), buffer, length );
}

int ICAP::regRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length)
{
    return pcieBarRead( pf_bar, ( offset + 0 ), buffer, length );
}

int ICAP::regWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length)
{
    return pcieBarWrite( pf_bar, (offset + 0 ), buffer, length );
}

/*
 * wordcopy()
 *
 * Copy bytes word (32bit) by word.
 * Neither memcpy, nor std::copy work as they become byte copying on some platforms.
 */
void* ICAP::wordcopy(void *dst, const void* src, size_t bytes)
{
    // assert dest is 4 byte aligned
    assert((reinterpret_cast<intptr_t>(dst) % 4) == 0);

    using word = uint32_t;
    auto d = reinterpret_cast<word*>(dst);
    auto s = reinterpret_cast<const word*>(src);
    auto w = bytes/sizeof(word);

    for (size_t i=0; i<w; ++i)
    {
        d[i] = s[i];
    }

    return dst;
}
