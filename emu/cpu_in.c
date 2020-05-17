/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
65c816 CPU implementation

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
#include "mem.h"
#include "alu.h"
#include "emulator.h"

void cpu_instruction_NOP(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_WDM(AddrMode am)
{
    mem_read(cpu_inc_pc()); END_CYCLE();
#if _WDM_IS_DEBUG
    emu_pause_debug();
#endif
}

void cpu_instruction_STP(AddrMode am)
{
    cpuStp = 1;
    END_CYCLE_NOABORT();
    END_CYCLE_NOABORT();
}

void cpu_instruction_WAI(AddrMode am)
{
    cpuWai = 1;
    END_CYCLE_NOABORT();
    END_CYCLE_NOABORT();
}

void cpu_instruction_BRK(AddrMode am)
{
    if (cpu_debug) printf("BRK encountered at $%02x:%04x\n", regs.K, regs.PC);
    ADDR r = regs.E ? 0xFFFE : 0xFFE6;
    mem_read(cpu_inc_pc()); END_CYCLE();
    if (!regs.E)
    {
        cpu_push8(regs.K);
        regs.K = 0;
    }
    cpu_push16(regs.PC);
    cpu_push8(regs.P | (regs.E ? P_B : 0));
    SET_P((regs.P | P_I) & ~P_D);
    regs.PC = mem_read(r); END_CYCLE();
    regs.PC |= mem_read(r + 1) << 8; END_CYCLE();
}

void cpu_instruction_COP(AddrMode am)
{
    ADDR r = regs.E ? 0xFFF4 : 0xFFE4;
    mem_read(cpu_inc_pc()); END_CYCLE();
    if (!regs.E)
    {
        cpu_push8(regs.K);
        regs.K = 0;
    }
    cpu_push16(regs.PC);
    cpu_push8(regs.P);
    SET_P((regs.P | P_I) & ~P_D);
    regs.PC = mem_read(r); END_CYCLE();
    regs.PC |= mem_read(r + 1) << 8; END_CYCLE();
}

void cpu_instruction_RTI(AddrMode am)
{
    mem_read(cpu_inc_pc()); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    SET_P(cpu_pull8());
    regs.PC = cpu_pull8();
    regs.PC |= cpu_pull8() << 8;
    if (!regs.E)
        regs.K = cpu_pull8();
}

void cpu_instruction_LDA(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        SET_A(cpu_am_read8(&am));
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(cpu_am_read16(&am));
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_LDX(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
    {
        SET_X(cpu_am_read8(&am));
        UPDATE_NZ_8(GET_X());
    }
    else
    {
        SET_X(cpu_am_read16(&am));
        UPDATE_NZ_16(GET_X());
    }
}

void cpu_instruction_LDY(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
    {
        SET_Y(cpu_am_read8(&am));
        UPDATE_NZ_8(GET_Y());
    }
    else
    {
        SET_Y(cpu_am_read16(&am));
        UPDATE_NZ_16(GET_Y());
    }
}

void cpu_instruction_STA(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
        cpu_am_write8(&am, GET_A());
    else
        cpu_am_write16(&am, GET_A());
}

void cpu_instruction_STX(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
        cpu_am_write8(&am, GET_X());
    else
        cpu_am_write16(&am, GET_X());
}

void cpu_instruction_STY(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
        cpu_am_write8(&am, GET_Y());
    else
        cpu_am_write16(&am, GET_Y());
}

void cpu_instruction_STZ(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
        cpu_am_write8(&am, 0);
    else
        cpu_am_write16(&am, 0);
}

void cpu_instruction_XCE(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    // swap P_C and E
    regs.P ^= regs.E;
    regs.E ^= regs.P & P_C;
    regs.P ^= regs.E;
    if (regs.E)
    {
        regs.X &= 0xFF;
        regs.Y &= 0xFF;
        regs.S = 0x0100 | (regs.S & 0xFF);
        regs.P |= P_M | P_X;
        regs.a_8b = regs.xy_8b = 1;
    }
}

void cpu_instruction_XBA(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (!CANCEL()) regs.A = (regs.A << 8) | (regs.A >> 8);
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    UPDATE_NZ_8(regs.A & 0xFF);
}

void cpu_instruction_ASLa(AddrMode am)
{
    if (A_8b())
    {
        SET_A(alu_asl8(GET_A()));
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(alu_asl16(GET_A()));
        UPDATE_NZ_16(GET_A());
    }
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_LSRa(AddrMode am)
{
    if (A_8b())
    {
        SET_A(alu_lsr8(GET_A()));
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(alu_lsr16(GET_A()));
        UPDATE_NZ_16(GET_A());
    }
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_ROLa(AddrMode am)
{
    if (A_8b())
    {
        SET_A(alu_rol8(GET_A()));
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(alu_rol16(GET_A()));
        UPDATE_NZ_16(GET_A());
    }
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_RORa(AddrMode am)
{
    if (A_8b())
    {
        SET_A(alu_ror8(GET_A()));
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(alu_ror16(GET_A()));
        UPDATE_NZ_16(GET_A());
    }
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_ASL(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        tmp8 = alu_asl8(tmp8);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        tmp16 = alu_asl16(tmp16);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_LSR(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        tmp8 = alu_lsr8(tmp8);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        tmp16 = alu_lsr16(tmp16);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_ROL(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        tmp8 = alu_rol8(tmp8);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        tmp16 = alu_rol16(tmp16);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_ROR(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        tmp8 = alu_ror8(tmp8);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        tmp16 = alu_ror16(tmp16);
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_AND(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        SET_A(GET_A() & cpu_am_read8(&am)); END_CYCLE();
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(GET_A() & cpu_am_read16(&am)); END_CYCLE();
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_EOR(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        SET_A(GET_A() ^ cpu_am_read8(&am)); END_CYCLE();
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(GET_A() ^ cpu_am_read16(&am)); END_CYCLE();
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_ORA(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        SET_A(GET_A() | cpu_am_read8(&am)); END_CYCLE();
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(GET_A() | cpu_am_read16(&am)); END_CYCLE();
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_ADC(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        alu_A_adc8(cpu_am_read8(&am)); END_CYCLE();
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        alu_A_adc16(cpu_am_read16(&am)); END_CYCLE();
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_SBC(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        alu_A_sbc8(cpu_am_read8(&am)); END_CYCLE();
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        alu_A_sbc16(cpu_am_read16(&am)); END_CYCLE();
        UPDATE_NZ_16(GET_A());
    }
}

static inline void cpu_instruction_do_branch(REG_8 offset)
{
    REG_16 oldPC = regs.PC;
    END_CYCLE();
    if (offset & 0x80)
        regs.PC -= (~offset + 1) & 0xFF;
    else
        regs.PC += offset;
    if (regs.E && (regs.PC & 0xFF00) != (oldPC & 0xFF00))
    {
        mem_read(CODE_ADDR((oldPC & 0xFF00) | (regs.PC & 0xFF))); END_CYCLE();
    }
}

void cpu_instruction_BRA(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    cpu_instruction_do_branch(offset);
}

void cpu_instruction_BCC(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (!(regs.P & P_C)) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BCS(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (regs.P & P_C) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BNE(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (!(regs.P & P_Z)) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BEQ(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (regs.P & P_Z) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BVC(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (!(regs.P & P_V)) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BVS(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (regs.P & P_V) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BPL(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (!(regs.P & P_N)) cpu_instruction_do_branch(offset);
}
void cpu_instruction_BMI(AddrMode am)
{
    cpu_am_decode(&am);
    REG_8 offset = cpu_am_read8(&am);
    if (regs.P & P_N) cpu_instruction_do_branch(offset);
}

void cpu_instruction_BRL(AddrMode am)
{
    REG_16 offset;
    offset = mem_read(cpu_inc_pc()); END_CYCLE();
    offset |= mem_read(cpu_inc_pc()) << 8; END_CYCLE();
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (offset & 0x8000)
        regs.PC -= (~offset + 1) & 0xFFFF;
    else
        regs.PC += offset;
}

void cpu_instruction_CLC(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P & ~P_C);
}

void cpu_instruction_CLD(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P & ~P_D);
}

void cpu_instruction_CLI(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P & ~P_I);
}

void cpu_instruction_CLV(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P & ~P_V);
}

void cpu_instruction_SEC(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P | P_C);
}

void cpu_instruction_SED(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P | P_D);
}

void cpu_instruction_SEI(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_P(regs.P | P_I);
}

void cpu_instruction_REP(AddrMode am)
{
    REG_8 tmp8;
    cpu_am_decode(&am);
    tmp8 = cpu_am_read8(&am); END_CYCLE();
    if (regs.E) tmp8 |= 0x30;
    SET_P(regs.P & ~tmp8);
}

void cpu_instruction_SEP(AddrMode am)
{
    REG_8 tmp8;
    cpu_am_decode(&am);
    tmp8 = cpu_am_read8(&am); END_CYCLE();
    if (regs.E) tmp8 &= 0xCF;
    SET_P(regs.P | tmp8);
}

void cpu_instruction_CMP(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8 = alu_cmp8(GET_A(), cpu_am_read8(&am));
        UPDATE_NZ_8(tmp8);
    }
    else
    {
        REG_16 tmp16 = alu_cmp16(GET_A(), cpu_am_read16(&am));
        UPDATE_NZ_16(tmp16);
    }
}

void cpu_instruction_CPX(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
    {
        REG_8 tmp8 = alu_cmp8(GET_X(), cpu_am_read8(&am));
        UPDATE_NZ_8(tmp8);
    }
    else
    {
        REG_16 tmp16 = alu_cmp16(GET_X(), cpu_am_read16(&am));
        UPDATE_NZ_16(tmp16);
    }
}

void cpu_instruction_CPY(AddrMode am)
{
    cpu_am_decode(&am);
    if (XY_8b())
    {
        REG_8 tmp8 = alu_cmp8(GET_Y(), cpu_am_read8(&am));
        UPDATE_NZ_8(tmp8);
    }
    else
    {
        REG_16 tmp16 = alu_cmp16(GET_Y(), cpu_am_read16(&am));
        UPDATE_NZ_16(tmp16);
    }
}

void cpu_instruction_BIT(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 r8 = cpu_am_read8(&am);
        alu_A_bit8(r8);
        UPDATE_NV_8(r8);
    }
    else
    {
        REG_16 r16 = cpu_am_read16(&am);
        alu_A_bit16(r16);
        UPDATE_NV_16(r16);
    }
}

void cpu_instruction_BITi(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 r8 = cpu_am_read8(&am);
        alu_A_bit8(r8);
    }
    else
    {
        REG_16 r16 = cpu_am_read16(&am);
        alu_A_bit16(r16);
    }
}

void cpu_instruction_TRB(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        UPDATE_Z_8(GET_A() & tmp8);
        tmp8 &= ~GET_A();
        cpu_am_read8(&am); END_CYCLE();
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        UPDATE_Z_16(GET_A() & tmp16);
        tmp16 &= ~GET_A();
        cpu_am_read8(&am); END_CYCLE();
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_TSB(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        UPDATE_Z_8(GET_A() & tmp8);
        tmp8 |= GET_A();
        cpu_am_read8(&am); END_CYCLE();
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        UPDATE_Z_16(GET_A() & tmp16);
        tmp16 |= GET_A();
        cpu_am_read8(&am); END_CYCLE();
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_DECa(AddrMode am)
{
    SET_A(GET_A() - 1);
    if (A_8b())
        UPDATE_NZ_8(GET_A());
    else
        UPDATE_NZ_16(GET_A());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_DEX(AddrMode am)
{
    SET_X(GET_X() - 1);
    if (XY_8b())
        UPDATE_NZ_8(GET_X());
    else
        UPDATE_NZ_16(GET_X());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_DEY(AddrMode am)
{
    SET_Y(GET_Y() - 1);
    if (XY_8b())
        UPDATE_NZ_8(GET_Y());
    else
        UPDATE_NZ_16(GET_Y());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_DEC(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        --tmp8;
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        --tmp16;
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_INCa(AddrMode am)
{
    SET_A(GET_A() + 1);
    if (A_8b())
        UPDATE_NZ_8(GET_A());
    else
        UPDATE_NZ_16(GET_A());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_INX(AddrMode am)
{
    SET_X(GET_X() + 1);
    if (XY_8b())
        UPDATE_NZ_8(GET_X());
    else
        UPDATE_NZ_16(GET_X());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_INY(AddrMode am)
{
    SET_Y(GET_Y() + 1);
    if (XY_8b())
        UPDATE_NZ_8(GET_Y());
    else
        UPDATE_NZ_16(GET_Y());
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_INC(AddrMode am)
{
    cpu_am_decode(&am);
    if (A_8b())
    {
        REG_8 tmp8;
        tmp8 = cpu_am_read8(&am); END_CYCLE();
        ++tmp8;
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_8(tmp8);
        cpu_am_write8(&am, tmp8); END_CYCLE();
    }
    else
    {
        REG_16 tmp16;
        tmp16 = cpu_am_read16_noinc(&am); END_CYCLE();
        ++tmp16;
        cpu_am_read8(&am); END_CYCLE();
        UPDATE_NZ_16(tmp16);
        cpu_am_write16(&am, tmp16); END_CYCLE();
    }
}

void cpu_instruction_JMP(AddrMode am)
{
    cpu_am_decode(&am);
    regs.PC = (REG_16)(GET_ADDR(am) & 0xFFFF);
}

void cpu_instruction_JML(AddrMode am)
{
    cpu_am_decode(&am);
    regs.PC = (REG_16)(GET_ADDR(am) & 0xFFFF);
    SET_K((REG_8)(GET_ADDR(am) >> 16));
}

void cpu_instruction_JSR(AddrMode am)
{
    REG_8 lo, hi;
    lo = mem_read(cpu_inc_pc()); END_CYCLE();
    if (regs.E)
        mem_read(0x0100 | (regs.S & 0xFF));
    else
        mem_read(regs.S);
    END_CYCLE();
    cpu_push16(regs.PC);
    hi = mem_read(cpu_inc_pc());
    END_CYCLE();
    regs.PC = (REG_16)(lo | (hi << 8));
}

void cpu_instruction_JSRx(AddrMode am)
{
    REG_8 lo, hi;
    ADDR addr;
    lo = mem_read(cpu_inc_pc()); END_CYCLE();
    if (regs.E)
        mem_read(0x0100 | (regs.S & 0xFF));
    else
        mem_read(regs.S);
    END_CYCLE();
    cpu_push16(regs.PC);
    hi = mem_read(cpu_inc_pc());
    END_CYCLE();
    addr = ((hi << 8) | lo) + GET_X();
    lo = mem_read(CODE_ADDR(addr)); END_CYCLE();
    hi = mem_read(CODE_ADDR(addr + 1)); END_CYCLE();
    regs.PC = (REG_16)(lo | (hi << 8));
}

void cpu_instruction_JSL(AddrMode am)
{
    REG_8 lo, hi;
    lo = mem_read(cpu_inc_pc()); END_CYCLE();
    if (regs.E) // errant memory read
        mem_read(0x0100 | (regs.S & 0xFF));
    else
        mem_read(regs.S);
    END_CYCLE();
    hi = mem_read(cpu_inc_pc());
    END_CYCLE();
    cpu_push8(regs.K);
    cpu_push16(regs.PC);
    SET_K(mem_read(cpu_inc_pc()));
    END_CYCLE();
    regs.PC = (REG_16)(lo | (hi << 8));
}

void cpu_instruction_RTS(AddrMode am)
{
    mem_read(cpu_inc_pc()); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    regs.PC = cpu_pull8();
    regs.PC |= cpu_pull8() << 8;
    mem_read(cpu_inc_pc()); END_CYCLE();
}

void cpu_instruction_RTL(AddrMode am)
{
    mem_read(cpu_inc_pc()); END_CYCLE();
    regs.PC = cpu_pull8();
    regs.PC |= cpu_pull8() << 8;
    regs.K = cpu_pull8();
    mem_read(cpu_inc_pc()); END_CYCLE();
}

void cpu_instruction_PHA(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (A_8b())
        cpu_push8(GET_A());
    else
        cpu_push16(GET_A());
}

void cpu_instruction_PHX(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (XY_8b())
        cpu_push8(GET_X());
    else
        cpu_push16(GET_X());
}

void cpu_instruction_PHY(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (XY_8b())
        cpu_push8(GET_Y());
    else
        cpu_push16(GET_Y());
}

void cpu_instruction_PLA(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    if (A_8b())
    {
        SET_A(cpu_pull8());
        UPDATE_NZ_8(GET_A());
    }
    else
    {
        SET_A(cpu_pull16());
        UPDATE_NZ_16(GET_A());
    }
}

void cpu_instruction_PLX(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    if (XY_8b())
    {
        SET_X(cpu_pull8());
        UPDATE_NZ_8(GET_X());
    }
    else
    {
        SET_X(cpu_pull16());
        UPDATE_NZ_16(GET_X());
    }
}

void cpu_instruction_PLY(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    if (XY_8b())
    {
        SET_Y(cpu_pull8());
        UPDATE_NZ_8(GET_Y());
    }
    else
    {
        SET_Y(cpu_pull16());
        UPDATE_NZ_16(GET_Y());
    }
}

void cpu_instruction_PHB(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    cpu_push8(regs.B);
}

void cpu_instruction_PHD(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    cpu_push16(regs.D);
}

void cpu_instruction_PHK(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    cpu_push8(regs.K);
}

void cpu_instruction_PHP(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    cpu_push8(regs.P);
}

void cpu_instruction_PLB(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    SET_B(cpu_pull8());
    UPDATE_NZ_8(regs.B);
}

void cpu_instruction_PLD(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    SET_D(cpu_pull16());
    UPDATE_NZ_16(regs.D);
}

void cpu_instruction_PLP(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    mem_read(STACK_ADDR()); END_CYCLE();
    SET_P(cpu_pull8());
    UPDATE_NZ_8(regs.P);
}

void cpu_instruction_TAX(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_X(regs.A); // not a typo. the full 16b A is copied even if A is 8b
}

void cpu_instruction_TAY(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_Y(regs.A); // not a typo. the full 16b A is copied even if A is 8b
}

void cpu_instruction_TXA(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_A(GET_X());
}

void cpu_instruction_TXY(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_Y(GET_X());
}

void cpu_instruction_TYA(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_A(GET_Y());
}

void cpu_instruction_TYX(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_X(GET_Y());
}

void cpu_instruction_TSX(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_X(regs.S);
}

void cpu_instruction_TXS(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    regs.S = GET_X();
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
}

void cpu_instruction_TCD(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    SET_D(regs.A);
}

void cpu_instruction_TCS(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    regs.S = regs.A;
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
}

void cpu_instruction_TDC(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (!CANCEL())
        regs.A = regs.D;
}

void cpu_instruction_TSC(AddrMode am)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    if (!CANCEL())
        regs.A = regs.S;
}

void cpu_instruction_PEA(AddrMode am) /* also PEI */
{
    cpu_am_decode(&am);
    cpu_push16(GET_ADDR(am));
}

void cpu_instruction_PER(AddrMode am)
{
    cpu_am_decode(&am);
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
    cpu_push16(GET_ADDR(am) + regs.PC);
}

void cpu_instruction_MVN(AddrMode am)
{
    REG_8 tmp;
    ADDR addr;
    cpu_am_decode(&am);
    SET_D(am.v.bm.dstb);
    tmp = mem_read(BANK_ADDR(am.v.bm.srcb, GET_X())); END_CYCLE();
    cpu_mem_write(DATA_ADDR(GET_Y()), tmp); END_CYCLE();
    SET_X(GET_X() + 1); SET_Y(GET_Y() + 1);
    mem_read(addr); END_CYCLE();
    if (!CANCEL())
        if (regs.A--)       // post-decrement is intended; A=0 copies one byte
            regs.PC -= 3;   // repeat instruction (3B long)
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}

void cpu_instruction_MVP(AddrMode am)
{
    REG_8 tmp;
    ADDR addr;
    cpu_am_decode(&am);
    SET_D(am.v.bm.dstb);
    tmp = mem_read(BANK_ADDR(am.v.bm.srcb, GET_X())); END_CYCLE();
    cpu_mem_write(DATA_ADDR(GET_Y()), tmp); END_CYCLE();
    SET_X(GET_X() - 1); SET_Y(GET_Y() - 1);
    mem_read(addr); END_CYCLE();
    if (!CANCEL())
        if (regs.A--)       // post-decrement is intended; A=0 copies one byte
            regs.PC -= 3;   // repeat instruction (3B long)
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE();
}
