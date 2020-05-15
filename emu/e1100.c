/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Computer main implementation

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

#include "e1100.h"
#include "cpu.h"
#include "vpu.h"
#include "mem.h"
#include "io.h"
#include "floppy.h"

VideoSystem e1100_vsys;
unsigned long VPU_CYCLES;
unsigned long CYC_PER_MS;
unsigned long CYC_PART_PER_MS;
static unsigned long long cycles;

void e1100_init(VideoSystem sys)
{
    cpu_init();
    vpu_init();
    mem_init();
    io_init();
    cycles = 0;
    e1100_change_system(sys);
}

void e1100_reset(void)
{
    cpu_reset();
    vpu_reset();
    io_reset();
    floppy_reset();
}

void e1100_free(void)
{
    cpu_free();
    vpu_free();
}

inline unsigned long e1100_run(unsigned long c)
{
    unsigned long tmp = cpu_run_cycles(c);
    cycles += tmp;
    return tmp;
}

void e1100_post_cpu_cycle(void)
{
    dma_cycle();
#ifdef SLOWDOWN
    for (int i = 0; i < SLOWDOWN; ++i)
#else
#endif
    {
        vpu_cycle();
        vpu_cycle();
    }
}

unsigned long e1100_step_instruction(void)
{
    unsigned long tmp = 0;
    cpu_debug = 1;
    cpu_debug_instr = 1;
    while (cpu_debug_instr && !cpu_halted())
        tmp += e1100_run(1);
    cpu_debug = _CPU_ALWAYS_DEBUG;
    return tmp;
}

void e1100_change_system(VideoSystem sys)
{
    unsigned long hz;
    int pal = sys == VS_PAL;
    e1100_vsys = sys;
    hz = pal ? CPU_HZ_PAL : CPU_HZ_NTSC;

    VPU_CYCLES = pal ? VPU_CYC_PAL : VPU_CYC_NTSC;
    CYC_PER_MS = hz / MS_PER_S;
    CYC_PART_PER_MS = hz % MS_PER_S;
}
