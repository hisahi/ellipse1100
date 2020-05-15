/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Computer I/O header

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

#ifndef _E1100_IO_H
#define _E1100_IO_H

#include "cpu.h"
#include "mem.h"

#define MAKE_KEY_CODE(m, c) ((BYTE)(((m) << 4) | (c)))
#define EXTRACT_KEY_CODE_ROW(k) ((k) & 7)
#define EXTRACT_KEY_CODE_COL(k) (((k) >> 4) & 15)

void io_init(void);
BYTE io_read(ADDR p);
void io_write(ADDR p, BYTE v);
void dma_cycle(void);
void io_reset(void);
void io_keyb_update_caps(BYTE c);
void io_keyb_keydown(BYTE k);
void io_keyb_keyup(BYTE k);
void io_raise_irq(BYTE s);
void io_raise_nmi(BYTE s);

typedef struct dma_channel {
    unsigned char control;
    unsigned char status;
    REG_16 copied;
    REG_16 count;
    REG_16 lcount;
    REG_16 dst;
    REG_16 src;
    REG_8 dstbnk;
    REG_8 srcbnk;
    int id;
} dma_channel;

#endif /* _E1100_IO_H */
