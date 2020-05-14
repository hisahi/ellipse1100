/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
VPU header

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

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "e1100.h"
#include "mem.h"
#include "vpu.h"
#include "backend.h"
#include "io.h"

static VPUMode mode = MODE0;
static size_t tick;
static size_t totsize;
static char* vram;
static uint32_t* scrbuffer;
static uint32_t* dst;
static EmuPixelFormat pixf;
static int pitch;
static int cur_x, cur_y;
static int screen_w;
static int screen_h;
static int screen_on;
static BYTE sprite_collisions;
static unsigned long long frames = 0;
int vpu_raise_nmi = 0;

VPUMode vpu_get_mode(void)
{
    return mode;
}

void vpu_set_mode(VPUMode m)
{
    mode = m;
    switch (mode)
    {
    case MODE0:
        emu_scr_init(
            screen_w = 512,
            screen_h = 384,
            &pixf);
        break;
    case MODE1:
        emu_scr_init(
            screen_w = 1024,
            screen_h = 768,
            &pixf);
        break;
    }
    totsize = screen_w * screen_h * 4;
    vpu_reset();
#if _DEBUG_MODE
    switch (pixf)
    {
    case PF_RGBA8888: emu_puts("Preferred pixel format: RGBA8888"); break;
    case PF_BGRA8888: emu_puts("Preferred pixel format: BGRA8888"); break;
    case PF_ABGR8888: emu_puts("Preferred pixel format: ABGR8888"); break;
    case PF_ARGB8888: emu_puts("Preferred pixel format: ARGB8888"); break;
    }
#endif
}

void vpu_lock(void)
{
    uint32_t* buf;
    scrbuffer = !emu_scr_lock(&buf, &pitch) ? buf : NULL;
    pitch >>= 2;
}

void vpu_unlock_blit(void)
{
    if (scrbuffer)
    {
        emu_scr_unlock_blit();
        scrbuffer = NULL;
    }
}

void vpu_init(void)
{
    tick = 0;
    vram = mem_ptr_vram();
    vpu_set_mode(MODE0);

    vpu_lock();
    vpu_reset();
    vpu_unlock_blit();
}

static inline void vpu_vsync(void)
{
    if (vpu_raise_nmi)
        io_raise_nmi(0x02);
    ++frames;
}

BYTE vpu_control_read(void)
{
    return (vpu_raise_nmi << 2) | (screen_on << 1) | mode;
}

void vpu_control_write(BYTE v)
{
    unsigned newmode;
    vpu_raise_nmi = 1 & (v >> 2);
    screen_on = 1 & (v >> 1);
    newmode = 1 & (v >> 0);
    if (newmode != mode)
        vpu_set_mode(newmode);
}

static inline int vpu_sprite_visible(int n)
{
    return 0; // TODO
}

static inline BYTE vpu_sprite_get_pixel(int n)
{
    return 0; // TODO
}

static inline void vpu_sprite_update_collision(BYTE sc)
{
    sprite_collisions |= sc;   
}

#define PUTPIX(r, g, b) { \
    switch (pixf) { \
    case PF_RGBA8888: *dst++ = 0x000000FF | ((r<<24)|(g<<16)|(b<< 8)); break; \
    case PF_BGRA8888: *dst++ = 0x000000FF | ((b<<24)|(g<<16)|(r<< 8)); break; \
    case PF_ARGB8888: *dst++ = 0xFF000000 | ((r<<16)|(g<< 8)|(b    )); break; \
    case PF_ABGR8888: *dst++ = 0xFF000000 | ((b<<16)|(g<< 8)|(r    )); break; \
    } \
}

void vpu_reset(void)
{
    tick = 0;
    screen_on = 1;
    vpu_raise_nmi = 0;
}

inline void vpu_cycle(void)
{
    static BYTE q, l, h, r, g, b, tmp, sc, scb;
    static int collisions;
    
    if (tick == 0) // about to start rendering for this frame?
    {
        vpu_unlock_blit();
        vpu_lock();
        dst = scrbuffer;
    }
    if (tick < VPU_PIXELS && dst)
    {
        if (!screen_on)
        {
            switch (mode)
            {
            case MODE1:
                PUTPIX(0, 0, 0);
                PUTPIX(0, 0, 0);
                PUTPIX(0, 0, 0);
            case MODE0:
                PUTPIX(0, 0, 0);
            }
        }
        else
        {
            cur_x = tick & 511, cur_y = tick >> 9;
            q = vram[tick];
            switch (mode)
            {
            case MODE0:
                for (b = 0; b < 8; ++b)
                    if (vpu_sprite_visible(b))
                    {
                        if (tmp = vpu_sprite_get_pixel(b))
                        {
                            q = tmp;
                            sc |= (1 << b), ++scb;
                        }
                    }
                h = vram[VPU_PALETTE + (q << 1)];
                l = vram[VPU_PALETTE + (q << 1) + 1];
                r = (l & 0x1F) << 3; r |= r >> 5;
                g = ((h & 3) << 6) | ((l & 0xE0) >> 2); g |= g >> 5;
                b = (h & 0x7C) << 1; b |= b >> 5;
                PUTPIX(r, g, b);
                if (tick & 511 == 511) // pitch adjust
                    dst += pitch - 512;
                break;
            case MODE1:
                r = 85 * ((q) & 3);
                g = 85 * ((q >> 2) & 3);
                b = 85 * ((q >> 4) & 3);
                h = 85 * ((q >> 6) & 3);
                PUTPIX(r, r, r);
                PUTPIX(g, g, g);
                PUTPIX(b, b, b);
                PUTPIX(h, h, h);
                if (tick & 1023 == 1023) // pitch adjust
                    dst += pitch - 1024;
            }

            if (scb > 1)
                vpu_sprite_update_collision(sc);
        }
    }

    ++tick;
    if (tick == VPU_PIXELS) // finished rendering for this frame?
    {
        vpu_vsync();
    }
    else if (tick >= VPU_CYCLES) // restart rendering now?
    {
        tick = 0;
        sprite_collisions = 0;
    }
}

void vpu_free(void)
{
}

const char* vpu_get_screen(size_t* size)
{
    *size = scrbuffer ? (pitch * screen_h) : 0;
    return (char*)scrbuffer;
}
