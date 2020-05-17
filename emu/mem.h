/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Memory header

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

#ifndef _E1100_MEM_H
#define _E1100_MEM_H

#define _RAM_SIZE 1048576
#define _VRAM_SIZE 524288
#define _ROM_SIZE 524288
#define _ROM_MASK (_ROM_SIZE-1)

#if (_ROM_SIZE & _ROM_MASK) != 0
#error ROM size must be a power of two
#endif

#if _RAM_SIZE % 65536 != 0
#error RAM size must be a multiple of 64 KB
#endif

#include <stdint.h>

#include "emulator.h"

typedef uint32_t ADDR;
#define ADDR_MASK 0xFFFFFFU
#define ADDR_MASK16 0xFFFFU
#define MASK_ADDR(x) (ADDR_MASK & (x))
#define BANK_ADDR(b,a) (((b) << 16) | (ADDR_MASK16 & (a)))

extern BYTE stack_bank;

void mem_init(void);
BYTE mem_read(ADDR a);
BYTE mem_read_transp(ADDR a);
void mem_write(ADDR a, BYTE v);

char* mem_ptr_ram(void);
char* mem_ptr_vram(void);
char* mem_ptr_rom(void);

#endif /* _E1100_MEM_H */
