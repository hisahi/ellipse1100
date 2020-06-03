/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Debug code (disassembler)

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

#include <stdio.h>
#include "emulator.h"
#include "cpu.h"

typedef enum DisasmAddrMode
{
    disasm_addr_mode_none,
    disasm_addr_mode_acc,
    disasm_addr_mode_imm,
    disasm_addr_mode_immA,
    disasm_addr_mode_immX,
    disasm_addr_mode_wimm,
    disasm_addr_mode_dp,
    disasm_addr_mode_dpx,
    disasm_addr_mode_dpy,
    disasm_addr_mode_abs,
    disasm_addr_mode_absx,
    disasm_addr_mode_absy,
    disasm_addr_mode_abl,
    disasm_addr_mode_ablx,
    disasm_addr_mode_idp,
    disasm_addr_mode_idpx,
    disasm_addr_mode_idpy,
    disasm_addr_mode_idpl,
    disasm_addr_mode_idsy,
    disasm_addr_mode_idly,
    disasm_addr_mode_iabs,
    disasm_addr_mode_iabx,
    disasm_addr_mode_iabl,
    disasm_addr_mode_sr,
    disasm_addr_mode_bm
} DisasmAddrMode;

#define _I(x) #x
const char *disasm_mnemonics[] = {
    _I(BRK ), _I(ORA ), _I(COP ), _I(ORA ), _I(TSB ), _I(ORA ), _I(ASL ), _I(ORA ), _I(PHP ), _I(ORA ), _I(ASL ), _I(PHD ), _I(TSB ), _I(ORA ), _I(ASL ), _I(ORA ), 
    _I(BPL ), _I(ORA ), _I(ORA ), _I(ORA ), _I(TRB ), _I(ORA ), _I(ASL ), _I(ORA ), _I(CLC ), _I(ORA ), _I(INC ), _I(TCS ), _I(TRB ), _I(ORA ), _I(ASL ), _I(ORA ), 
    _I(JSR ), _I(AND ), _I(JSL ), _I(AND ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), _I(PLP ), _I(AND ), _I(ROL ), _I(PLD ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), 
    _I(BMI ), _I(AND ), _I(AND ), _I(AND ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), _I(SEC ), _I(AND ), _I(DEC ), _I(TSC ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), 

    _I(RTI ), _I(EOR ), _I(WDM ), _I(EOR ), _I(MVP ), _I(EOR ), _I(LSR ), _I(EOR ), _I(PHA ), _I(EOR ), _I(LSR ), _I(PHK ), _I(JMP ), _I(EOR ), _I(LSR ), _I(EOR ), 
    _I(BVC ), _I(EOR ), _I(EOR ), _I(EOR ), _I(MVN ), _I(EOR ), _I(LSR ), _I(EOR ), _I(CLI ), _I(EOR ), _I(PHY ), _I(TCD ), _I(JML ), _I(EOR ), _I(LSR ), _I(EOR ), 
    _I(RTS ), _I(ADC ), _I(PER ), _I(ADC ), _I(STZ ), _I(ADC ), _I(ROR ), _I(ADC ), _I(PLA ), _I(ADC ), _I(ROR ), _I(RTL ), _I(JMP ), _I(ADC ), _I(ROR ), _I(ADC ), 
    _I(BVS ), _I(ADC ), _I(ADC ), _I(ADC ), _I(STZ ), _I(ADC ), _I(ROR ), _I(ADC ), _I(SEI ), _I(ADC ), _I(PLY ), _I(TDC ), _I(JMP ), _I(ADC ), _I(ROR ), _I(ADC ), 

    _I(BRA ), _I(STA ), _I(BRL ), _I(STA ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), _I(DEY ), _I(BIT ), _I(TXA ), _I(PHB ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), 
    _I(BCC ), _I(STA ), _I(STA ), _I(STA ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), _I(TYA ), _I(STA ), _I(TXS ), _I(TXY ), _I(STZ ), _I(STA ), _I(STZ ), _I(STA ), 
    _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(TAY ), _I(LDA ), _I(TAX ), _I(PLB ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), 
    _I(BCS ), _I(LDA ), _I(LDA ), _I(LDA ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(CLV ), _I(LDA ), _I(TSX ), _I(TYX ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), 

    _I(CPY ), _I(CMP ), _I(REP ), _I(CMP ), _I(CPY ), _I(CMP ), _I(DEC ), _I(CMP ), _I(INY ), _I(CMP ), _I(DEX ), _I(WAI ), _I(CPY ), _I(CMP ), _I(DEC ), _I(CMP ), 
    _I(BNE ), _I(CMP ), _I(CMP ), _I(CMP ), _I(PEI ), _I(CMP ), _I(DEC ), _I(CMP ), _I(CLD ), _I(CMP ), _I(PHX ), _I(STP ), _I(JMP ), _I(CMP ), _I(DEC ), _I(CMP ), 
    _I(CPX ), _I(SBC ), _I(SEP ), _I(SBC ), _I(CPX ), _I(SBC ), _I(INC ), _I(SBC ), _I(INX ), _I(SBC ), _I(NOP ), _I(XBA ), _I(CPX ), _I(SBC ), _I(INC ), _I(SBC ), 
    _I(BEQ ), _I(SBC ), _I(SBC ), _I(SBC ), _I(PEA ), _I(SBC ), _I(INC ), _I(SBC ), _I(SED ), _I(SBC ), _I(PLX ), _I(XCE ), _I(JSR ), _I(SBC ), _I(INC ), _I(SBC ),
};

#define _A(x) disasm_addr_mode_##x
const DisasmAddrMode disasm_addr_modes[] = {
    _A( imm), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A( acc), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A(  dp), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A( acc), _A(none), _A( abs), _A(absx), _A(absx), _A(ablx),
    _A( abs), _A(idpx), _A( abl), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A( acc), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A( acc), _A(none), _A(absx), _A(absx), _A(absx), _A(ablx),
    
    _A(none), _A(idpx), _A( imm), _A(  sr), _A(  bm), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A( acc), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A(  bm), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A( abl), _A(absx), _A(absx), _A(ablx),
    _A(none), _A(idpx), _A( abs), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A( acc), _A(none), _A(iabs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(iabx), _A(absx), _A(absx), _A(ablx),
    
    _A( imm), _A(idpx), _A(wimm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpy), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A( abs), _A(absx), _A(absx), _A(ablx),
    _A(immX), _A(idpx), _A(immX), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpy), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(absx), _A(absx), _A(absy), _A(ablx),
    
    _A(immX), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( idp), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(iabl), _A(absx), _A(absx), _A(ablx),
    _A(immX), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A(immA), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( abs), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(iabx), _A(absx), _A(absx), _A(ablx)
};

void emulator_disasm_instr_am(DisasmAddrMode d)
{
    REG_8 a, b, c;
    if (d == disasm_addr_mode_immA)
        d = A_8b() ? disasm_addr_mode_imm : disasm_addr_mode_wimm;
    else if (d == disasm_addr_mode_immX)
        d = XY_8b() ? disasm_addr_mode_imm : disasm_addr_mode_wimm;

    switch (d)
    {
    case disasm_addr_mode_none:
        break;
    case disasm_addr_mode_acc:
        putchar('A');
        break;
    case disasm_addr_mode_imm:
        a = mem_read(cpu_inc_pc());
        printf("#$%02x", a);
        break;
    case disasm_addr_mode_wimm:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("#$%04x", a | (b << 8));
        break;
    case disasm_addr_mode_dp:
        a = mem_read(cpu_inc_pc());
        printf("$%02x", a);
        break;
    case disasm_addr_mode_dpx:
        a = mem_read(cpu_inc_pc());
        printf("$%02x,X", a);
        break;
    case disasm_addr_mode_dpy:
        a = mem_read(cpu_inc_pc());
        printf("$%02x,Y", a);
        break;
    case disasm_addr_mode_abs:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("$%04x", a | (b << 8));
        break;
    case disasm_addr_mode_absx:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("$%04x,X", a | (b << 8));
        break;
    case disasm_addr_mode_absy:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("$%04x,Y", a | (b << 8));
        break;
    case disasm_addr_mode_abl:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        c = mem_read(cpu_inc_pc());
        printf("$%06x", a | (b << 8) | (c << 16));
        break;
    case disasm_addr_mode_ablx:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        c = mem_read(cpu_inc_pc());
        printf("$%06x,X", a | (b << 8) | (c << 16));
        break;
    case disasm_addr_mode_idp:
        a = mem_read(cpu_inc_pc());
        printf("($%02x)", a);
        break;
    case disasm_addr_mode_idpx:
        a = mem_read(cpu_inc_pc());
        printf("($%02x,X)", a);
        break;
    case disasm_addr_mode_idpy:
        a = mem_read(cpu_inc_pc());
        printf("($%02x),Y", a);
        break;
    case disasm_addr_mode_idpl:
        a = mem_read(cpu_inc_pc());
        printf("[$%02x]", a);
        break;
    case disasm_addr_mode_idsy:
        a = mem_read(cpu_inc_pc());
        printf("($%02x,S),Y", a);
        break;
    case disasm_addr_mode_idly:
        a = mem_read(cpu_inc_pc());
        printf("[$%02x],Y", a);
        break;
    case disasm_addr_mode_iabs:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("($%04x)", a | (b << 8));
        break;
    case disasm_addr_mode_iabx:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("($%04x,X)", a | (b << 8));
        break;
    case disasm_addr_mode_iabl:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("[$%04x]", a | (b << 8));
        break;
    case disasm_addr_mode_sr:
        a = mem_read(cpu_inc_pc());
        printf("$%02x,S", a);
        break;
    case disasm_addr_mode_bm:
        a = mem_read(cpu_inc_pc());
        b = mem_read(cpu_inc_pc());
        printf("$%02x,$%02x", a, b);
        break;
    }
}

void emulator_disasm_instr(REG_16 pc)
{
    REG_16 oldPC = regs.PC;
    regs.PC = pc;
    REG_8 b = mem_read(cpu_inc_pc());
    printf("%s", disasm_mnemonics[b]);
    putchar(' ');
    emulator_disasm_instr_am(disasm_addr_modes[b]);
    putchar('\n');
    regs.PC = oldPC;
}
