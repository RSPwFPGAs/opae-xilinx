/*
 * xbflash
 */

#include <iostream>
#include <unistd.h>
#include <getopt.h>
#include "flasher.h"

const char* HelpMessage = "xbflash: Incorrect usage. Try 'xbflash [-d device] -m primary_mcs [-n secondary_mcs]'.";

struct T_Arguments
{
    char *file1 = nullptr;
    char *file2 = nullptr;
    const char *devIdx;
    bool isValid = true;
};

T_Arguments parseArguments( int argc, char *argv[] );

int main( int argc, char *argv[] )
{
    std::cout <<"XBFLASH -- Xilinx Board Flash Utility" << std::endl;

    if( getuid() && geteuid() )
    {
        std::cout << "ERROR: flash operation requires root privileges" << std::endl; // todo move this to a header of common messages
        return -EACCES;
    }

    T_Arguments args = parseArguments( argc, argv );
    if( !args.isValid )
    {
        std::cout << HelpMessage << std::endl;
        return -1;
    }

    Flasher flasher( args.devIdx );
    if( flasher.upgradeFirmware( args.file1, args.file2 ) != 0 )
    {
        std::cout << "XBFlash failed." << std::endl;
        return -1;
    }
    else
    {
        std::cout << "XBFlash completed succesfully. Please reboot device for flash to complete." << std::endl;
        return 0;
    }
}

T_Arguments parseArguments( int argc, char *argv[] )
{
    T_Arguments args;
    int opt;
    if( argc <= 1 )
    {
        args.isValid = false;
    }
    while( ( opt = getopt( argc, argv, "d:m:n:" ) ) != -1 )
    {
        switch( opt )
        {
        case 'd':
            //args.devIdx = atoi( optarg );
	    args.devIdx = optarg;
            break;
        case 'm':
            args.file1 = optarg;
            break;
        case 'n':
            args.file2 = optarg;
            break;
        default:
            std::cout << HelpMessage << std::endl;
            args.isValid = false;
            break;
        }
    }

    if( args.isValid )
    {
        if( args.file1 == nullptr )
        {
            args.isValid = false;
        }
    }

    return args;
}
