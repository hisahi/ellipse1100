/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Backend header

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

#ifndef _E1100_BACKEND_H
#define _E1100_BACKEND_H

#include <stdint.h>

typedef enum EmuPixelFormat
{
    PF_RGBA8888, PF_BGRA8888, PF_ABGR8888, PF_ARGB8888
} EmuPixelFormat;

// initialize emulator resources
void emu_init(const char* title);

// free emulator resources
void emu_free(void);

// signal to emulator that we should quit, emu_running should head to 0
void emu_close_quit(void);

// set window title
void emu_settitle(const char* title);

// center window on screen
void emu_center_window(void);

// whether we should continue running the emulator
int emu_running(void);

// return <>0 if new command line from terminal, returns buffer and length
int emu_term_hasline(const char** buf, size_t* sz);

// get time in ns passed since last call to this function
unsigned long emu_get_tick_ns(void);

// initialize screen with resolution WxH, output pixel format
void emu_scr_init(int w, int h, EmuPixelFormat* pf);

// set window (client/inner) size to WxH
void emu_set_window_size(int w, int h);

// free current screen
void emu_scr_kill(void);

// lock screen buffer, 0 if success, <>0 if fail
int emu_scr_lock(uint32_t** buf, int* pitch);

// unlock screen buffer and blit it
void emu_scr_unlock_blit(void);

// these two can call each other if necessary
void emu_delay_ms(unsigned long ms);
void emu_delay_ns(unsigned long long ns);

#endif /* _E1100_BACKEND_H */
