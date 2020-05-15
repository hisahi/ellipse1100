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

#include <stdint.h>
#include <stdlib.h>

#include "coro.h"
#include "cpu.h"
#include "mem.h"
#include "emulator.h"
#include "e1100.h"

CPURegs regs;
static char reset;
static char interrupt;
int is_init;
int cpuStp;
int cpuWai;
int irqDisable;
static coroutine cpu_coro;
REG_16 oldS;
ADDR lastAddrPC;
BYTE lastOpcode = 0;
static long long rancyc = 0;
static long long runcyc = 0;
int cpu_debug = _CPU_ALWAYS_DEBUG;
int cpu_debug_instr = 0;

CPURegs regs_abort;

#define I_ABORT 4
#define I_NMI 2
#define I_IRQ 1

void cpu_instruction_loop(void);

inline void cpu_end_cycle(void)
{
    ++rancyc;
    e1100_post_cpu_cycle();
    if (paused || --runcyc <= 0)
    {
        coro_yield();
        if (runcyc <= 0)
            runcyc = 1;
    }
}

inline unsigned long cpu_run_cycles(unsigned long cycles)
{
    rancyc = 0;
    runcyc = cycles;
    coro_resume(&cpu_coro);
    return rancyc;
}

void cpu_init(void)
{
    if (is_init) return;

    is_init = 1;
    irqDisable = 1;
    coro_create(&cpu_coro, &cpu_instruction_loop);
    cpu_reset();
}

void cpu_free(void)
{
    coro_destroy(&cpu_coro);
    coro_quit();
}

inline void cpu_reset(void)
{
    reset = 1;
}

void cpu_irq(void)
{
    interrupt |= I_IRQ;
}

void cpu_nmi(void)
{
    interrupt |= I_NMI;
}

void cpu_abort(void)
{
    interrupt |= I_ABORT;
    if (!(interrupt & I_ABORT))
        regs_abort = regs;
}

inline int cpu_halted(void)
{
    return cpuWai | cpuStp;
}

inline ADDR cpu_inc_pc(void)
{
    return CODE_ADDR(regs.PC++);
}

void cpu_push8_noabort(REG_8 v)
{
    mem_write(regs.S--, v);
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
    END_CYCLE_NOABORT();
}

void cpu_push8(REG_8 v)
{
    mem_write(regs.S--, v);
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
    END_CYCLE();
}

void cpu_push16(REG_16 v)
{
    cpu_push8((REG_8)((v >> 8) & 0xFF));
    cpu_push8((REG_8)(v & 0xFF));
}

void cpu_push24(ADDR a)
{
    cpu_push8((REG_8)((a >> 16) & 0xFF));
    cpu_push8((REG_8)((a >> 8) & 0xFF));
    cpu_push8((REG_8)(a & 0xFF));
}

REG_8 cpu_pull8_noabort(void)
{
    REG_8 v;
    ++regs.S;
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
    v = mem_read(regs.S);
    END_CYCLE_NOABORT();
    return v;
}

REG_8 cpu_pull8(void)
{
    REG_8 v;
    ++regs.S;
    if (regs.E) regs.S = 0x0100 | (regs.S & 0xFF);
    v = mem_read(regs.S);
    END_CYCLE_NOABORT();
    return v;
}

REG_16 cpu_pull16(void)
{
    REG_8 a, b, c;
    a = cpu_pull8();
    b = cpu_pull8();
    return (REG_16)(a | (b << 8));
}

ADDR cpu_pull24(void)
{
    REG_8 a, b, c;
    a = cpu_pull8();
    b = cpu_pull8();
    c = cpu_pull8();
    return (ADDR)(a | (b << 8) | (c << 16));
}

/* the big tables */

#define _I(x) &cpu_instruction_##x
cpu_instr cpu_instr_table[] = {
    _I(BRK ), _I(ORA ), _I(COP ), _I(ORA ), _I(TSB ), _I(ORA ), _I(ASL ), _I(ORA ), _I(PHP ), _I(ORA ), _I(ASLa), _I(PHD ), _I(TSB ), _I(ORA ), _I(ASL ), _I(ORA ), 
    _I(BPL ), _I(ORA ), _I(ORA ), _I(ORA ), _I(TRB ), _I(ORA ), _I(ASL ), _I(ORA ), _I(CLC ), _I(ORA ), _I(INCa), _I(TCS ), _I(TRB ), _I(ORA ), _I(ASL ), _I(ORA ), 
    _I(JSR ), _I(AND ), _I(JSL ), _I(AND ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), _I(PLP ), _I(AND ), _I(ROLa), _I(PLD ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), 
    _I(BMI ), _I(AND ), _I(AND ), _I(AND ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), _I(SEC ), _I(AND ), _I(DECa), _I(TSC ), _I(BIT ), _I(AND ), _I(ROL ), _I(AND ), 

    _I(RTI ), _I(EOR ), _I(WDM ), _I(EOR ), _I(MVP ), _I(EOR ), _I(LSR ), _I(EOR ), _I(PHA ), _I(EOR ), _I(LSRa), _I(PHK ), _I(JMP ), _I(EOR ), _I(LSR ), _I(EOR ), 
    _I(BVC ), _I(EOR ), _I(EOR ), _I(EOR ), _I(MVN ), _I(EOR ), _I(LSR ), _I(EOR ), _I(CLI ), _I(EOR ), _I(PHY ), _I(TCD ), _I(JML ), _I(EOR ), _I(LSR ), _I(EOR ), 
    _I(RTS ), _I(ADC ), _I(PER ), _I(ADC ), _I(STZ ), _I(ADC ), _I(ROR ), _I(ADC ), _I(PLA ), _I(ADC ), _I(RORa), _I(RTL ), _I(JMP ), _I(ADC ), _I(ROR ), _I(ADC ), 
    _I(BVS ), _I(ADC ), _I(ADC ), _I(ADC ), _I(STZ ), _I(ADC ), _I(ROR ), _I(ADC ), _I(SEI ), _I(ADC ), _I(PLY ), _I(TDC ), _I(JMP ), _I(ADC ), _I(ROR ), _I(ADC ), 

    _I(BRA ), _I(STA ), _I(BRL ), _I(STA ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), _I(DEY ), _I(BITi), _I(TXA ), _I(PHB ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), 
    _I(BCC ), _I(STA ), _I(STA ), _I(STA ), _I(STY ), _I(STA ), _I(STX ), _I(STA ), _I(TYA ), _I(STA ), _I(TXS ), _I(TXY ), _I(STZ ), _I(STA ), _I(STZ ), _I(STA ), 
    _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(TAY ), _I(LDA ), _I(TAX ), _I(PLB ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), 
    _I(BCS ), _I(LDA ), _I(LDA ), _I(LDA ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), _I(CLV ), _I(LDA ), _I(TSX ), _I(TYX ), _I(LDY ), _I(LDA ), _I(LDX ), _I(LDA ), 

    _I(CPY ), _I(CMP ), _I(REP ), _I(CMP ), _I(CPY ), _I(CMP ), _I(DEC ), _I(CMP ), _I(INY ), _I(CMP ), _I(DEX ), _I(WAI ), _I(CPY ), _I(CMP ), _I(DEC ), _I(CMP ), 
    _I(BNE ), _I(CMP ), _I(CMP ), _I(CMP ), _I(PEA ), _I(CMP ), _I(DEC ), _I(CMP ), _I(CLD ), _I(CMP ), _I(PHX ), _I(STP ), _I(JML ), _I(CMP ), _I(DEC ), _I(CMP ), 
    _I(CPX ), _I(SBC ), _I(SEP ), _I(SBC ), _I(CPX ), _I(SBC ), _I(INC ), _I(SBC ), _I(INX ), _I(SBC ), _I(NOP ), _I(XBA ), _I(CPX ), _I(SBC ), _I(INC ), _I(SBC ), 
    _I(BEQ ), _I(SBC ), _I(SBC ), _I(SBC ), _I(PEA ), _I(SBC ), _I(INC ), _I(SBC ), _I(SED ), _I(SBC ), _I(PLX ), _I(XCE ), _I(JSRx), _I(SBC ), _I(INC ), _I(SBC ),
};

#define _A(x) &cpu_addr_##x
const AddrMode* cpu_addr_table[] = {
    _A( imm), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A(  dp), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A( abs), _A(absx), _A(absx), _A(ablx),
    _A(none), _A(idpx), _A(none), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(absx), _A(absx), _A(absx), _A(ablx),
    
    _A(none), _A(idpx), _A(none), _A(  sr), _A(  bm), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A(  bm), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A( abl), _A(absx), _A(absx), _A(ablx),
    _A(none), _A(idpx), _A( abs), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A(iabs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(iabx), _A(absx), _A(absx), _A(ablx),
    
    _A( imm), _A(idpx), _A(none), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpy), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A( abs), _A(absx), _A(absx), _A(ablx),
    _A( imm), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( dpx), _A( dpx), _A( dpy), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(absx), _A(absx), _A(absy), _A(ablx),
    
    _A( imm), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( idp), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(iabl), _A(absx), _A(absx), _A(ablx),
    _A( imm), _A(idpx), _A( imm), _A(  sr), _A(  dp), _A(  dp), _A(  dp), _A(idpl), _A(none), _A( imm), _A(none), _A(none), _A( abs), _A( abs), _A( abs), _A( abl),
    _A( imm), _A(idpy), _A( idp), _A(idsy), _A( abs), _A( dpx), _A( dpx), _A(idly), _A(none), _A(absy), _A(none), _A(none), _A(none), _A(absx), _A(absx), _A(ablx)
};

/* interrupts */

void cpu_do_reset(void)
{
    reset = 0;
#if _INTERRUPT_DEBUG
    if (cpu_debug) emu_puts("--- RESET ---\n");
#endif
    regs.E = 1;
    regs.K = regs.B = 0;
    regs.D = 0;
    regs.P = (regs.P | P_I | P_M | P_X) & ~P_D;
    regs.S = 0x0100 | (regs.S & 0xFF);
    regs.X &= 0xFF;
    regs.Y &= 0xFF;
    regs.a_8b = regs.xy_8b = 1;
    cpuStp = cpuWai = 0;
    interrupt = 0;

    END_CYCLE_NOABORT(); END_CYCLE_NOABORT();

    regs.PC = mem_read(0xFFFC); END_CYCLE_NOABORT();
    regs.PC |= mem_read(0xFFFD) << 8; END_CYCLE_NOABORT();

    END_CYCLE_NOABORT(); END_CYCLE_NOABORT();
    /* reset takes 6 cycles */
    
    if (cpu_debug) CPU_DEBUG_ENDINSTR();
}

void cpu_standard_interrupt(ADDR addr)
{
    mem_read(CODE_ADDR(regs.PC)); END_CYCLE_NOABORT();
    mem_read(CODE_ADDR(regs.PC + 1)); END_CYCLE_NOABORT();
    if (!regs.E)
    {
        cpu_push8_noabort(regs.K);
        regs.K = 0;
    }
    cpu_push8_noabort((REG_8)((regs.PC >> 8) & 0xFF));
    cpu_push8_noabort((REG_8)(regs.PC & 0xFF));
    cpu_push8_noabort(regs.P);
    regs.PC = mem_read(addr); END_CYCLE_NOABORT();
    regs.PC |= mem_read(addr + 1) << 8; END_CYCLE_NOABORT();
    regs.P = (regs.P | P_I) & ~P_D;
    
    if (cpu_debug) CPU_DEBUG_ENDINSTR();
}

void cpu_do_abort(void)
{
#if _INTERRUPT_DEBUG
    if (cpu_debug) emu_puts("--- ABORT ---\n");
#endif

    interrupt &= ~I_ABORT;
    cpuWai = 0;
    regs = regs_abort;
    regs.PC = lastAddrPC;
    regs.S = oldS;

    cpu_standard_interrupt(!regs.E ? 0xFFE8 : 0xFFF8);
}

void cpu_do_nmi(void)
{
#if _INTERRUPT_DEBUG
    if (cpu_debug) emu_puts("--- NMI ---\n");
#endif
    interrupt &= ~I_NMI;
    cpuWai = 0;

    cpu_standard_interrupt(!regs.E ? 0xFFEA : 0xFFFA);
}

void cpu_do_irq(void)
{
#if _INTERRUPT_DEBUG
    if (cpu_debug) emu_puts("--- IRQ ---\n");
#endif
    interrupt &= ~I_IRQ;
    cpuWai = 0;

    if (irqDisable) return;
    cpu_standard_interrupt(!regs.E ? 0xFFEE : 0xFFFE);
}

inline int cpu_should_cancel_instruction()
{
    return interrupt & I_ABORT;
}

inline int cpu_should_abort_instruction()
{
    return reset;
}

/* main loop */

void cpu_instruction_loop(void)
{
    REG_8 ib;
    AddrMode am;
    ++runcyc;

    for (;;)
    {
        if (reset) 
            { cpu_do_reset(); continue; }
        else if (cpuStp)
        {
            END_CYCLE_NOABORT();
            continue;
        }
        else if (interrupt & I_ABORT)
            { cpu_do_abort(); continue; }
        else if (interrupt & I_NMI)
            { cpu_do_nmi(); continue; }
        else if (interrupt & I_IRQ)
            { cpu_do_irq(); continue; }
        if (cpuWai)
        {
            END_CYCLE_NOABORT();
            continue;
        }

        if (breakpoint_enabled)
        {
            if (regs.PC == breakpoint_addr)
            {
                emu_pause_debug();
                END_CYCLE_NOABORT();
            }
        }

        // fetch instruction
        oldS = regs.S;
        lastAddrPC = CODE_ADDR(regs.PC);
        lastOpcode = ib = mem_read(cpu_inc_pc());
        END_CYCLE_NOABORT();
        // decode & execute
        (*cpu_instr_table[ib])(am = *cpu_addr_table[ib]);

        if (cpu_debug)
            CPU_DEBUG_ENDINSTR();
    }
    
    emu_fail("Infinite loop exited");
}
