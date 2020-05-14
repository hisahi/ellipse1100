/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Computer main header

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

#ifndef _E1100_E1100_H
#define _E1100_E1100_H

typedef enum VideoSystem {
    VS_NTSC, VS_PAL
} VideoSystem;

extern unsigned long VPU_CYCLES;
extern unsigned long CYC_PER_MS;
extern unsigned long CYC_PART_PER_MS;

extern VideoSystem e1100_vsys;
void e1100_init(VideoSystem sys);
void e1100_reset(void);
void e1100_change_system(VideoSystem sys);
void e1100_tick(void);
void e1100_free(void);

void e1100_step_instruction(void);

#endif /* _E1100_E1100_H */
