/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Memory implementation

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

#include <string.h>

#include "io.h"
#include "mem.h"

char ram[_RAM_SIZE];
char vram[_VRAM_SIZE];
char rom[_ROM_SIZE];
BYTE stack_bank;

void mem_init(void)
{
    memset(ram, 0, sizeof(ram));
    memset(vram, 0, sizeof(vram));
    memset(rom, 0, sizeof(rom));
    stack_bank = 0;
}

char* mem_ptr_ram(void)
{
    return ram;
}

char* mem_ptr_vram(void)
{
    return vram;
}

char* mem_ptr_rom(void)
{
    return rom;
}

inline BYTE mem_read_transp(ADDR a)
{
    int hightwo = a >> 22;
    a &= 0x3FFFFFU;
    switch (hightwo)
    {
    case 0: /* ROM */
        return rom[a & _ROM_MASK];
    case 1: /* I/O or VRAM */
        return (a >= _VRAM_SIZE) ? io_read(a) : vram[a];
    case 2: case 3: /* RAM */
        return (a >= _RAM_SIZE) ? (BYTE)-1 : ram[a];
    }
}

BYTE mem_read(ADDR a)
{
    int bank = a >> 16;
    if (bank == 0)
    {
        if (a < 0x0400)
        {
            if (stack_bank)
                return mem_read(BANK_ADDR(stack_bank, a));
            else
                return ram[BANK_ADDR(stack_bank, a)];
        }
        else if (a < 0x7000)
            return ram[a];
        else if (a < 0x8000)
            return io_read(a);
        else
            return rom[a];
    }

    return mem_read_transp(a);
}

void mem_write(ADDR a, BYTE v)
{
    int bank = a >> 16, hightwo = a >> 22;
    a &= 0x3FFFFFU;
    if (bank == 0)
    {
        if (a < 0x0400)
        {
            if (stack_bank)
                mem_write(BANK_ADDR(stack_bank, a), v);
            else
                ram[BANK_ADDR(stack_bank, a)] = v;
        }
        else if (a < 0x7000)
            ram[a] = v;
        else if (a < 0x8000)
            io_write(a & 0x0FFF, v);
        return;
    }

    switch (hightwo)
    {
    case 0: /* ROM */
        break;
    case 1: /* I/O, VRAM */
        if (a >= _VRAM_SIZE) /* I/O */
        {
            io_write(a, v);
        }
        else /* VRAM */
            vram[a] = v;
        break;
    case 2: case 3: /* RAM */
        if (a < _RAM_SIZE)
            ram[a] = v;
    }
}
