#ifndef ICAP_H
#define ICAP_H

#include "fifo_icap.h"
#include <sys/stat.h>
#include <vector>


#define ICAP_BASE_ADDRESS 0x00012000
#define BAR_INDEX "0"


class ICAP
{
public:
    ICAP(const char *f );
    ~ICAP();
    int ProgramPRbit( const char *prfile);

    /* public to XSPI_Flasher and BPI_Flasher */
    static void* wordcopy(void *dst, const void* src, size_t bytes);
    static int icapRead(unsigned int pf_bar, unsigned long long offset, void *buffer, unsigned long long length);
    static int icapWrite(unsigned int pf_bar, unsigned long long offset, const void *buffer, unsigned long long length);

private:

    FIFO_Icap *micap;

    bool mapDevice(const char *f);
    static int pcieBarRead(unsigned int pf_bar, unsigned long long offset, void* buffer, unsigned long long length);
    static int pcieBarWrite(unsigned int pf_bar, unsigned long long offset, const void* buffer, unsigned long long length);

    char *mMgmtMap;
    int mFd;
    struct stat mSb;

};

#endif //
