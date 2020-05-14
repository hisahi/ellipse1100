/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
65c816 CPU implementation; addressing modes

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

#include "cpu.h"

void cpu_am_null(AddrMode* am) /* instrs without addresses, or acc */
{
    /* undefined behavior, program should not try read/write with this mode */
}

void cpu_am_decode_imm(AddrMode* am) /* #$NN */
{
    am->flags = AM_WRAP_16 | AM_INC_PC;
    am->v.addr = CODE_ADDR(regs.PC);
}

void cpu_am_decode_dp(AddrMode* am) /* $NN */
{
    if (regs.E && (regs.D & 0xFF) == 0)
    {
        am->flags = AM_WRAP_8;
        am->v.addr = (0xFF00 & regs.D) | mem_read(cpu_inc_pc());
    }
    else
    {
        am->flags = AM_WRAP_16;
        am->v.addr = 0xFFFF & (regs.D + mem_read(cpu_inc_pc()));
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
    }
    END_CYCLE();
}

void cpu_am_decode_dpx(AddrMode* am) /* $NN,X */
{
    if (regs.E && (regs.D & 0xFF) == 0)
    {
        am->flags = AM_WRAP_8;
        am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
        am->v.addr = (regs.D & 0xFF00) | (am->v.addr & 0xFF);
        mem_read(am->v.addr); END_CYCLE();
        am->v.addr = (am->v.addr & 0xFF00) | ((am->v.addr + GET_X()) & 0xFF);
    }
    else
    {
        am->flags = AM_WRAP_16;
        am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
        am->v.addr = (am->v.addr + regs.D) & 0xFFFF;
        mem_read(am->v.addr); END_CYCLE();
        am->v.addr = 0xFFFF & (am->v.addr + GET_X());
    }
}

void cpu_am_decode_dpy(AddrMode* am) /* $NN,Y */
{
    if (regs.E && (regs.D & 0xFF) == 0)
    {
        am->flags = AM_WRAP_8;
        am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
        am->v.addr = (regs.D & 0xFF00) | (am->v.addr & 0xFF);
        mem_read(am->v.addr); END_CYCLE();
        am->v.addr = (am->v.addr & 0xFF00) | ((am->v.addr + GET_Y()) & 0xFF);
    }
    else
    {
        am->flags = AM_WRAP_16;
        am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
        am->v.addr = (am->v.addr + regs.D) & 0xFFFF;
        mem_read(am->v.addr); END_CYCLE();
        am->v.addr = 0xFFFF & (am->v.addr + GET_Y());
    }
}

void cpu_am_decode_abs(AddrMode* am) /* $NNNN */
{
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = DATA_ADDR((mem_read(cpu_inc_pc()) << 8) | am->v.addr); END_CYCLE();
}

void cpu_am_decode_absx(AddrMode* am) /* $NNNN,X */
{
    REG_16 tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()) + GET_X(); END_CYCLE();
    tmp = am->v.addr & 0x1FF00U;
    am->v.addr = DATA_ADDR((mem_read(cpu_inc_pc()) << 8) | (am->v.addr & 0xFFU)); END_CYCLE();
    if (tmp | !XY_8b())
    {
        mem_read(CODE_ADDR(regs.PC - 1)); END_CYCLE();
        am->v.addr = MASK_ADDR(am->v.addr + tmp);
    }
}

void cpu_am_decode_absy(AddrMode* am) /* $NNNN,X */
{
    REG_16 tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()) + GET_Y(); END_CYCLE();
    tmp = am->v.addr & 0x1FF00U;
    am->v.addr = DATA_ADDR((mem_read(cpu_inc_pc()) << 8) | (am->v.addr & 0xFFU)); END_CYCLE();
    if (tmp | !XY_8b())
    {
        mem_read(CODE_ADDR(regs.PC - 1)); END_CYCLE();
        am->v.addr = MASK_ADDR(am->v.addr + tmp);
    }
}

void cpu_am_decode_abl(AddrMode* am) /* $NNNNNN */
{
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr |= (mem_read(cpu_inc_pc()) << 8); END_CYCLE();
    am->v.addr |= (mem_read(cpu_inc_pc()) << 16); END_CYCLE();
}

void cpu_am_decode_ablx(AddrMode* am) /* $NNNNNN,X */
{
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr |= (mem_read(cpu_inc_pc()) << 8); END_CYCLE();
    am->v.addr |= (mem_read(cpu_inc_pc()) << 16); END_CYCLE();
    am->v.addr = MASK_ADDR(am->v.addr + GET_X());
}

void cpu_am_decode_idp(AddrMode* am) /* ($NN) */
{
    ADDR lo, hi;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    if (regs.E && 0 == (regs.D & 0xFF))
    {
        lo = (regs.D & 0xFF00) | am->v.addr;
        hi = (regs.D & 0xFF00) | ((lo + 1) & 0xFF);
    }
    else
    {
        lo = (regs.D + am->v.addr) & 0xFFFF;
        hi = (lo + 1) & 0xFFFF;
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
    }
    am->v.addr = mem_read(lo); END_CYCLE();
    am->v.addr = DATA_ADDR((mem_read(hi) << 8) | am->v.addr); END_CYCLE();
}

void cpu_am_decode_idpx(AddrMode* am) /* ($NN,X) */
{
    ADDR lo, hi;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    mem_read(am->v.addr); END_CYCLE();
    if (regs.E && 0 == (regs.D & 0xFF))
    {
        lo = (regs.D & 0xFF00) | ((am->v.addr + GET_X()) & 0xFF);
        hi = (regs.D & 0xFF00) | ((lo + 1) & 0xFF);
    }
    else
    {
        lo = (regs.D + am->v.addr + GET_X()) & 0xFFFF;
        hi = (lo + 1) & 0xFFFF;
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
    }
    am->v.addr = mem_read(lo); END_CYCLE();
    am->v.addr = DATA_ADDR((mem_read(hi) << 8) | am->v.addr); END_CYCLE();
}

void cpu_am_decode_idpy(AddrMode* am) /* ($NN),Y */
{
    ADDR lo, hi;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    if (regs.E && 0 == (regs.D & 0xFF))
    {
        lo = (regs.D & 0xFF00) | am->v.addr;
        hi = (regs.D & 0xFF00) | ((lo + 1) & 0xFF);
    }
    else
    {
        lo = (regs.D + am->v.addr) & 0xFFFF;
        hi = (lo + 1) & 0xFFFF;
        if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
    }
    am->v.addr = mem_read(lo); END_CYCLE();
    // unadjusted final address
    lo = DATA_ADDR(((mem_read(hi) << 8) | am->v.addr));
    // adjusted final address (with Y)
    hi = DATA_ADDR(((mem_read(hi) << 8) | am->v.addr)) + GET_Y();
    // low byte correct, rest might not be
    am->v.addr = (lo & 0xFFFF00) | (hi & 0xFF);
    // are the rest not correct?
    if (am->v.addr != hi || !XY_8b())
    {
        // spend extra read + cycle if so
        mem_read(am->v.addr); END_CYCLE();
        am->v.addr = hi;
    }
}

void cpu_am_decode_idpl(AddrMode* am) /* [$NN] */
{
    ADDR tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = (am->v.addr + regs.D) & 0xFFFF;
    tmp = mem_read(am->v.addr); END_CYCLE();
    am->v.addr = (am->v.addr + 1) & 0xFFFF;
    tmp |= mem_read(am->v.addr) << 8; END_CYCLE();
    am->v.addr = (am->v.addr + 1) & 0xFFFF;
    tmp |= mem_read(am->v.addr) << 16; END_CYCLE();
    am->v.addr = tmp;
    if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
}

void cpu_am_decode_idly(AddrMode* am) /* [$NN],Y */
{
    ADDR tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = (am->v.addr + regs.D) & 0xFFFF;
    tmp = mem_read(am->v.addr); END_CYCLE();
    am->v.addr = (am->v.addr + 1) & 0xFFFF;
    tmp |= mem_read(am->v.addr) << 8; END_CYCLE();
    am->v.addr = (am->v.addr + 1) & 0xFFFF;
    tmp |= mem_read(am->v.addr) << 16; END_CYCLE();
    am->v.addr = MASK_ADDR(tmp + GET_Y());
    if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
}

void cpu_am_decode_idsy(AddrMode* am) /* ($NN,S),Y */
{
    ADDR lo, hi;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    mem_read((regs.S & 0xFF00) | ((am->v.addr + regs.S) & 0xFF)); END_CYCLE();
    lo = (am->v.addr + regs.S) & 0xFFFF;
    mem_read(lo); END_CYCLE();
    hi = (lo + 1) & 0xFFFF;
    am->v.addr = mem_read(lo); END_CYCLE();
    am->v.addr = DATA_ADDR((mem_read(hi) << 8) | am->v.addr) + GET_Y(); END_CYCLE();
    if (regs.D & 0xFF) { mem_read(am->v.addr); END_CYCLE(); }
}

void cpu_am_decode_iabs(AddrMode* am) /* ($NNNN) */
{
    ADDR tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = (mem_read(cpu_inc_pc()) << 8) | am->v.addr; END_CYCLE();
    tmp = mem_read(am->v.addr); END_CYCLE();
    am->v.addr = tmp | mem_read((am->v.addr + 1) & 0xFFFF) << 8; END_CYCLE();
}

void cpu_am_decode_iabx(AddrMode* am) /* ($NNNN,X) */
{
    ADDR tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = (mem_read(cpu_inc_pc()) << 8) | am->v.addr; END_CYCLE();
    mem_read(CODE_ADDR((am->v.addr & 0xFFFF) | (0xFF & (am->v.addr + GET_X())))); END_CYCLE();
    am->v.addr = 0xFFFF & (am->v.addr + GET_X());
    tmp = mem_read(CODE_ADDR(am->v.addr)); END_CYCLE();
    am->v.addr = tmp | mem_read(CODE_ADDR(am->v.addr + 1)) << 8; END_CYCLE();
}

void cpu_am_decode_iabl(AddrMode* am) /* [$NNNN] */
{
    ADDR tmp;
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.addr = (mem_read(cpu_inc_pc()) << 8) | am->v.addr; END_CYCLE();
    tmp = mem_read(am->v.addr); END_CYCLE();
    tmp |= mem_read((am->v.addr + 1) & 0xFFFF) << 8; END_CYCLE();
    am->v.addr = tmp | (mem_read((am->v.addr + 2) & 0xFFFF) << 16); END_CYCLE();
}

void cpu_am_decode_sr(AddrMode* am) /* $NN,S */
{
    am->flags = AM_NOWRAP;
    am->v.addr = mem_read(cpu_inc_pc()); END_CYCLE();
    mem_read((0xFF00 & regs.S) | (0xFF & (am->v.addr + regs.S))); END_CYCLE();
    am->v.addr = 0xFFFF & (am->v.addr + regs.S);
}

void cpu_am_decode_bm(AddrMode* am) /* $NN,$MM */
{
    am->flags = AM_NOWRAP;
    am->v.bm.dstb = mem_read(cpu_inc_pc()); END_CYCLE();
    am->v.bm.srcb = mem_read(cpu_inc_pc()); END_CYCLE();
}

const AddrMode cpu_addr_none = { cpu_am_null };
const AddrMode cpu_addr_imm = { cpu_am_decode_imm };
const AddrMode cpu_addr_dp = { cpu_am_decode_dp };
const AddrMode cpu_addr_dpx = { cpu_am_decode_dpx };
const AddrMode cpu_addr_dpy = { cpu_am_decode_dpy };
const AddrMode cpu_addr_abs = { cpu_am_decode_abs };
const AddrMode cpu_addr_absx = { cpu_am_decode_absx };
const AddrMode cpu_addr_absy = { cpu_am_decode_absy };
const AddrMode cpu_addr_abl = { cpu_am_decode_abl };
const AddrMode cpu_addr_ablx = { cpu_am_decode_ablx };
const AddrMode cpu_addr_idp = { cpu_am_decode_idp };
const AddrMode cpu_addr_idpx = { cpu_am_decode_idpx };
const AddrMode cpu_addr_idpy = { cpu_am_decode_idpy };
const AddrMode cpu_addr_idpl = { cpu_am_decode_idpl };
const AddrMode cpu_addr_idly = { cpu_am_decode_idly };
const AddrMode cpu_addr_idsy = { cpu_am_decode_idsy };
const AddrMode cpu_addr_iabs = { cpu_am_decode_iabs };
const AddrMode cpu_addr_iabx = { cpu_am_decode_iabx };
const AddrMode cpu_addr_iabl = { cpu_am_decode_iabl };
const AddrMode cpu_addr_sr = { cpu_am_decode_sr };
const AddrMode cpu_addr_bm = { cpu_am_decode_bm };

static inline ADDR cpu_increment_addr(AddrMode* am)
{
    ADDR next = am->v.addr + 1;
    if (am->flags & AM_WRAP_8)
        next = (am->v.addr & 0xFFFF00U) | (next & 0xFFU);
    else if (am->flags & AM_WRAP_16)
        next = (am->v.addr & 0xFF0000U) | (next & 0xFFFFU);
    am->v.addr = MASK_ADDR(next);
}

inline void cpu_am_decode(AddrMode* am)
{
    am->decode(am);
}

inline REG_8 cpu_am_read8(AddrMode* am)
{
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    return mem_read(am->v.addr);
}

inline void cpu_am_write8(AddrMode* am, REG_8 v)
{
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    cpu_mem_write(am->v.addr, v);
}

REG_16 cpu_am_read16(AddrMode* am)
{
    ADDR a;
    REG_8 tmp;
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    tmp = mem_read(am->v.addr);
    END_CYCLE_NOABORT();
    cpu_increment_addr(am);
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    return tmp | (mem_read(am->v.addr) << 8);
}

REG_16 cpu_am_read16_noinc(AddrMode* am)
{
    ADDR a = am->v.addr;
    REG_16 wtmp = cpu_am_read16(am);
    am->v.addr = a;
    return wtmp;
}

void cpu_am_write16(AddrMode* am, REG_16 v)
{
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    cpu_mem_write(am->v.addr, (REG_8)(v & 0xFF));
    END_CYCLE();
    cpu_increment_addr(am);
    if (am->flags & AM_INC_PC) cpu_inc_pc();
    cpu_mem_write(am->v.addr, (REG_8)(v >> 8));
}
