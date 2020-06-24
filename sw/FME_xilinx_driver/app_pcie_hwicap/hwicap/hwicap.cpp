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
#include <unistd.h>
#include <getopt.h>
#include "icap.h"

const char* HelpMessage = "hwicap: Incorrect usage. Try 'hwicap -d device -f dynamic_bin'.";

struct T_Arguments
{
    char *infile = nullptr;
    const char *devIdx;
    bool isValid = true;
};

T_Arguments parseArguments( int argc, char *argv[] );

int main( int argc, char *argv[] )
{
    std::cout <<"hwicap -- Xilinx Board HWICAP Utility" << std::endl;

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

    ICAP icap( args.devIdx );
    if( icap.ProgramPRbit(args.infile) != 0 )
    {
        std::cout << "hwicap failed." << std::endl;
        return -1;
    }
    else
    {
        std::cout << "hwicap completed succesfully. " << std::endl;
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
    while( ( opt = getopt( argc, argv, "d:f:" ) ) != -1 )
    {
        switch( opt )
        {
        case 'd':
            //args.devIdx = atoi( optarg );
	          args.devIdx = optarg;
            break;
        case 'f':
            args.infile = optarg;
            break;
        //case 'n':
        //    args.file2 = optarg;
        //    break;
        default:
            std::cout << HelpMessage << std::endl;
            args.isValid = false;
            break;
        }
    }

    if( args.isValid )
    {
        if( args.infile == nullptr )
        {
            args.isValid = false;
        }
    }

    return args;
}
