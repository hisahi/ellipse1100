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

#ifndef _E1100_VPU_H
#define _E1100_VPU_H

#define VPU_CYC_NTSC 268466
#define VPU_CYC_PAL 310353
#define VPU_PIXELS 196608
#define VPU_PALETTE VPU_PIXELS

typedef enum VPUMode {
    MODE0, MODE1
} VPUMode;

extern int vpu_raise_nmi;

VPUMode vpu_get_mode(void);
void vpu_set_mode(VPUMode m);
void vpu_init(void);
void vpu_cycle(void);
void vpu_reset(void);
void vpu_free(void);
const char* vpu_get_screen(size_t* size);

#endif /* _E1100_VPU_H */
