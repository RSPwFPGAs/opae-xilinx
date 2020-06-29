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
#ifndef _REG_ICAP_H_
#define _REG_ICAP_H_

#include <sys/stat.h>
#include <list>
#include <iostream>


class REG_Icap
{

public:
    REG_Icap( char *inMap );
    ~REG_Icap();

    void freezeShutDownMgr();
    void releaseShutDownMgr();

private:
    char *mMgmtMap;

    unsigned readReg(unsigned offset);
    int writeReg(unsigned regOffset, unsigned value);

};

#endif
