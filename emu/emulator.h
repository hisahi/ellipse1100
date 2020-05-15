/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Main emulator header file

Copyright (c) 2020 Sampo Hippeläinen (hisahi)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef _E1100_EMULATOR_H
#define _E1100_EMULATOR_H

#include <stdint.h>

#define _DEBUG_MODE 1

#define _CPU_ALWAYS_DEBUG _DEBUG_MODE
#define _WDM_IS_DEBUG _DEBUG_MODE
#define _INTERRUPT_DEBUG 0
#define _DMA_DEBUG 0
#define _FLOPPY_DEBUG 0
// #define SLOWDOWN 4

#define MS_PER_S 1000ULL
#define NS_PER_MS 1000000ULL
#define NS_PER_S (MS_PER_S*NS_PER_MS)

#define MAX_PATH_NAME 33000

extern int paused;
extern int breakpoint_enabled;
extern unsigned int breakpoint_addr;
extern unsigned long long total_cycles;
extern unsigned long long total_ms;

typedef uint8_t BYTE;

void emu_fail(const char * reason);
void emu_pause(void);
void emu_unpause(void);
void emu_pause_debug(void);
void emulator_dump_state(void);

#endif /* _E1100_EMULATOR_H */
