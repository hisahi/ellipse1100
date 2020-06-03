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

#include "mem.h"
#include "io.h"
#include "e1100.h"
#include "floppy.h"
#include "vpu.h"

BYTE active_int;
dma_channel io_dma[4];
static BYTE keymatrix[16];
static BYTE genericint = 0;

void io_raise_irq(BYTE s)
{
    active_int = s;
    cpu_irq();
}

void io_raise_nmi(BYTE s)
{
    active_int = s;
    cpu_nmi();
}

#define IO_KEYB_IRQ_ENABLED() (1 & genericint)

inline void io_keyb_update_caps(BYTE c)
{
    keymatrix[0] = c ? (keymatrix[0] | 0x20) : (keymatrix[0] & ~0x20);
}

inline void io_keyb_keydown(BYTE k)
{
    keymatrix[EXTRACT_KEY_CODE_COL(k)] |= (1U << EXTRACT_KEY_CODE_ROW(k));
    if (IO_KEYB_IRQ_ENABLED()) io_raise_irq(0x0c);
}

inline void io_keyb_keyup(BYTE k)
{
    keymatrix[EXTRACT_KEY_CODE_COL(k)] &= ~(1U << EXTRACT_KEY_CODE_ROW(k));
    if (IO_KEYB_IRQ_ENABLED()) io_raise_irq(0x0c);
}

#define DMA_GET_ENABLE(d) (1 & ((d)->control >> 7))
#define DMA_IS_DST_FIXED(d) (1 & ((d)->control >> 3))
#define DMA_IS_SRC_FIXED(d) (1 & ((d)->control >> 2))
#define DMA_SHOULD_NMI(d) (1 & ((d)->control >> 1))
#define DMA_SHOULD_IRQ(d) (1 & (d)->control)
#define DMA_IS_COPYING(d) (1 & ((d)->status >> 7))
#define DMA_SET_COPYING(d,v) ((d)->status = ((d)->status & 0x7F) | (v ? 0x80 : 0))

static inline void dma_cycle_copy(dma_channel* c, BYTE n)
{
    if (DMA_GET_ENABLE(c) && DMA_IS_COPYING(c))
    {
        mem_write(BANK_ADDR(c->dstbnk, c->dst), 
                mem_read_transp(BANK_ADDR(c->srcbnk, c->src)));
        ++c->copied;
        if (!DMA_IS_DST_FIXED(c)) ++c->dst;
        if (!DMA_IS_SRC_FIXED(c)) ++c->src;

        if (!(--c->count))
        {
            DMA_SET_COPYING(c, 0);
            if (DMA_SHOULD_NMI(c))
                io_raise_nmi(n);
            else if (DMA_SHOULD_IRQ(c))
                io_raise_irq(n);
        }
    }
}

inline void dma_cycle(void)
{
    dma_cycle_copy(io_dma + 0, 0x08);
    dma_cycle_copy(io_dma + 1, 0x09);
    dma_cycle_copy(io_dma + 2, 0x0a);
    dma_cycle_copy(io_dma + 3, 0x0b);
}

BYTE io_dma_bread(dma_channel* c, int r)
{
    r &= 15;
    switch (r)
    {
    case 0:         return c->control;
    case 1:         return c->status;
    case 2:         return 0xFF & (c->copied);
    case 3:         return 0xFF & (c->copied >> 8);
    case 8:         return c->dstbnk;
    case 9:         return c->srcbnk;
    case 10:        return 0xFF & (c->lcount);
    case 11:        return 0xFF & (c->lcount >> 8);
    case 12:        return 0xFF & (c->dst);
    case 13:        return 0xFF & (c->dst >> 8);
    case 14:        return 0xFF & (c->src);
    case 15:        return 0xFF & (c->src >> 8);
    }
}

void io_dma_bwrite(dma_channel* c, int r, BYTE v)
{
    r &= 15;
    switch (r)
    {
    case 0:
        c->control = v & 0x8F;
        if (v & 0x10)
            c->copied = 0;
        if (v & 0x80)
        {
            c->count = c->lcount;
            DMA_SET_COPYING(c, 1);
#if _DMA_DEBUG
            printf("DMA#%d got job: $%04x bytes, $%02x:%04x => $%02x:%04x"
                   " (flags = $%02x)\n",
                   c->id, c->count, c->srcbnk, c->src, c->dstbnk, c->dst,
                   c->control);
#endif
        }
        break;
    case 8:
        c->dstbnk = v; break;
    case 9:
        c->srcbnk = v; break;
    case 10:
        c->lcount = (c->lcount & 0xFF00) | v;
        c->count = c->lcount;
        break;
    case 11:
        c->lcount = (c->lcount & 0xFF) | (v << 8);
        c->count = c->lcount;
        break;
    case 12:
        c->dst = (c->dst & 0xFF00) | v;
        break;
    case 13:
        c->dst = (c->dst & 0xFF) | (v << 8);
        break;
    case 14:
        c->src = (c->src & 0xFF00) | v;
        break;
    case 15:
        c->src = (c->src & 0xFF) | (v << 8);
        break;
    }
}   

void dma_reset(void)
{
    io_dma[0].control = io_dma[0].status = 0; io_dma[0].id = 0;
    io_dma[1].control = io_dma[1].status = 0; io_dma[1].id = 1;
    io_dma[2].control = io_dma[2].status = 0; io_dma[2].id = 2;
    io_dma[3].control = io_dma[3].status = 0; io_dma[3].id = 3;
}

void io_reset(void)
{
    dma_reset();
    genericint = 0;
}

void io_init(void)
{
    memset(keymatrix, 0, sizeof(keymatrix));
    io_reset();
}

BYTE io_system_status(void)
{
    return e1100_vsys == VS_PAL ? 1 : 0;
}

BYTE io_read(ADDR p)
{
    p &= 255;

    switch (p)
    {
    case 0:     return io_system_status();
    case 1:     return 0x80 | stack_bank;
    case 2:     return active_int;
    case 3:     return 0x7F + (_RAM_SIZE >> 16);
    case 4:     return genericint;
    case 16: case 17: case 18: case 19:
    case 20: case 21: case 22: case 23:
    case 24: case 25: case 26: case 27:
    case 28: case 29: case 30: case 31:
        return keymatrix[p & 15];
    case 40: case 41: case 42: case 43:
    case 44: case 45: case 46: case 47:
        return floppy_read((p >> 2) & 1, p & 3);
    case 48:
        return vpu_control_read();
    }

    if ((p & 192) == 64)
        return io_dma_bread(io_dma + ((p >> 4) & 3), p & 15);
    return (BYTE)0xFF;
}

void io_write(ADDR p, BYTE v)
{
    p &= 255;
    switch (p)
    {
    case 0:
        if (v == 0xFF) e1100_reset();
        break;
    case 1:     stack_bank = 0x80 | v; break;
    case 4:     genericint = v; break;
    case 40: case 41: case 42: case 43:
    case 44: case 45: case 46: case 47:
        floppy_write((p >> 2) & 1, p & 3, v); break;
    case 48:
        vpu_control_write(v); break;
    }

    if ((p & 192) == 64)
        io_dma_bwrite(io_dma + ((p >> 4) & 3), p & 15, v);
}
