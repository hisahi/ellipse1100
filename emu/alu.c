/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
65c816 ALU implementation

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

#include "alu.h"
#include "cpu.h"

#define SET_P_C(c) (regs.P = (regs.P & ~P_C) | ((c) ? P_C : 0))
#define SET_P_CV(c,v) (regs.P = (regs.P & ~P_C & ~P_V) | \
                        ((c) ? P_C : 0) | ((v) ? P_V : 0))
#define UPDATE_P_Z(z) (regs.P = (regs.P & ~P_Z) | ((z) ? 0 : P_Z))

REG_8 alu_asl8(REG_8 v)
{
    SET_P_C(v & 0x80);
    return (REG_8)(v << 1);
}

REG_16 alu_asl16(REG_16 v)
{
    SET_P_C(v & 0x8000);
    return (REG_16)(v << 1);
}

REG_8 alu_lsr8(REG_8 v)
{
    SET_P_C(v & 1);
    return (REG_8)(v >> 1);
}

REG_16 alu_lsr16(REG_16 v)
{
    SET_P_C(v & 1);
    return (REG_16)(v >> 1);
}

REG_8 alu_rol8(REG_8 v)
{
    REG_8 oldC = regs.P & P_C;
    SET_P_C(v & 0x80);
    return (REG_8)(v << 1) | (oldC ? 1 : 0);
}

REG_16 alu_rol16(REG_16 v)
{
    REG_8 oldC = regs.P & P_C;
    SET_P_C(v & 0x8000);
    return (REG_16)(v << 1) | (oldC ? 1 : 0);
}

REG_8 alu_ror8(REG_8 v)
{
    REG_8 oldC = regs.P & P_C;
    SET_P_C(v & 1);
    return (REG_8)(v >> 1) | (oldC ? 0x80 : 0);
}

REG_16 alu_ror16(REG_16 v)
{
    REG_8 oldC = regs.P & P_C;
    SET_P_C(v & 1);
    return (REG_16)(v >> 1) | (oldC ? 0x8000 : 0);
}

void alu_A_adc8(REG_8 v)
{
    unsigned r;
    r = regs.A + v + ((regs.P & P_C) != 0);
    if (regs.P & P_D)
    {
        if ((r & 0xF) > 0x9) r += 0x6;
        if ((r & 0xF0) > 0x90) r += 0x60;
    }
    SET_P_CV(r > 0xFF, 0 != (0x80 & (regs.A ^ r)));
    SET_A(r & 0xFF);
    UPDATE_NZ_8(r & 0xFF);
}

void alu_A_adc16(REG_16 v)
{
    unsigned r;
    r = regs.A + v + ((regs.P & P_C) != 0);
    if (regs.P & P_D)
    {
        if ((r & 0xF) > 0x9) r += 0x6;
        if ((r & 0xF0) > 0x90) r += 0x60;
        if ((r & 0xF00) > 0x900) r += 0x600;
        if ((r & 0xF000) > 0x9000) r += 0x6000;
    }
    SET_P_CV(r > 0xFFFF, 0 != (0x8000 & (regs.A ^ r)));
    SET_A(r & 0xFFFF);
    UPDATE_NZ_16(r & 0xFFFF);
}

void alu_A_sbc8(REG_8 v)
{
    unsigned r;
    r = regs.A + ~v + ((regs.P & P_C) != 0);
    if (regs.P & P_D)
    {
        if ((r & 0xF) > 0x9) r += 0x6;
        if ((r & 0xF0) > 0x90) r += 0x60;
    }
    SET_P_CV(r > 0xFF, 0 != (0x80 & (regs.A ^ r)));
    SET_A(r & 0xFF);
    UPDATE_NZ_8(r & 0xFF);
}

void alu_A_sbc16(REG_16 v)
{
    unsigned r;
    r = regs.A + ~v + ((regs.P & P_C) != 0);
    if (regs.P & P_D)
    {
        if ((r & 0xF) > 0x9) r += 0x6;
        if ((r & 0xF0) > 0x90) r += 0x60;
        if ((r & 0xF00) > 0x900) r += 0x600;
        if ((r & 0xF000) > 0x9000) r += 0x6000;
    }
    SET_P_CV(r > 0xFFFF, 0 != (0x8000 & (regs.A ^ r)));
    SET_A(r & 0xFFFF);
    UPDATE_NZ_16(r & 0xFFFF);
}

void alu_A_bit8(REG_8 v)
{
    UPDATE_P_Z(GET_A() & v);
}

void alu_A_bit16(REG_16 v)
{
    UPDATE_P_Z(GET_A() & v);
}

REG_8 alu_cmp8(REG_8 r, REG_8 v)
{
    REG_8 d = r - v;
    SET_P_C((0x100 + r - v) >> 8);
    return d;
}

REG_16 alu_cmp16(REG_16 r, REG_16 v)
{
    REG_16 d = r - v;
    SET_P_C((0x10000 + r - v) >> 16);
    return d;
}

