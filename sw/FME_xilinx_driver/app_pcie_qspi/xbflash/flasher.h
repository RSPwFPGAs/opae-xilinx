#ifndef FLASHER_H
#define FLASHER_H

#include "xspi.h"
#include <sys/stat.h>
#include <vector>

class Flasher
{
public:
    Flasher(const char *f );
    ~Flasher();
    int upgradeFirmware( const char *f1, const char *f2 );

    /* public to XSPI_Flasher and BPI_Flasher */
    static void* wordcopy(void *dst, const void* src, size_t bytes);
    static int flashRead(unsigned int pf_bar, unsigned long long offset, void *buffer, unsigned long long length);
    static int flashWrite(unsigned int pf_bar, unsigned long long offset, const void *buffer, unsigned long long length);

private:
    enum E_FlasherType {
        SPI,
    };

    E_FlasherType mType;
    XSPI_Flasher *mXspi;

    bool mapDevice(const char *f);
    static int pcieBarRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length);
    static int pcieBarWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length);

    char *mMgmtMap;
    int mFd;
    struct stat mSb;

};

#endif // FLASHER_H
