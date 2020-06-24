#include "flasher.h"
#include <sys/mman.h>
#include <stddef.h>
#include <fcntl.h>
#include <unistd.h>
#include <cassert>

#define FLASH_BASE_ADDRESS 0x00013000
#define BAR_INDEX "0"

Flasher::Flasher(const char *f)
{
    mXspi = nullptr;
    mFd = 0;

    if( !mapDevice( f ) )
    {
        std::cout << "Failed to map pcie device." << std::endl;
    }
    mType = SPI;    
    switch( mType )
    {
    case SPI:
        mXspi = new XSPI_Flasher(  mMgmtMap );
        break;
    default:
        break;
    }
}

Flasher::~Flasher()
{
    if( mXspi != nullptr )
    {
        delete mXspi;
        mXspi = nullptr;
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

int Flasher::upgradeFirmware(const char *f1, const char *f2)
{
    int retVal = -1;
    mType = SPI;
    switch( mType )
    {
    case SPI:
        if( f2 == nullptr )
        {
            retVal = mXspi->xclUpgradeFirmwareXSpi( f1 );
        }
        else
        {
            retVal = mXspi->xclUpgradeFirmware2( f1, f2 );
        }
        break;
    default:
        std::cout << "ERROR: Invalid programming type." << std::endl;
        retVal = -1;
        break;
    }
    return retVal;
}

bool Flasher::mapDevice(const char *f)
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

int Flasher::pcieBarRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length)
{
    wordcopy(buffer, (void*)offset, length);
    return 0;
}

int Flasher::pcieBarWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length)
{
    wordcopy((void*)offset, buffer, length);
    return 0;
}

int Flasher::flashRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length)
{
    return pcieBarRead( pf_bar, ( offset + FLASH_BASE_ADDRESS ), buffer, length );
}

int Flasher::flashWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length)
{
    return pcieBarWrite( pf_bar, (offset + FLASH_BASE_ADDRESS ), buffer, length );
}

/*
 * wordcopy()
 *
 * Copy bytes word (32bit) by word.
 * Neither memcpy, nor std::copy work as they become byte copying on some platforms.
 */
void* Flasher::wordcopy(void *dst, const void* src, size_t bytes)
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

 
