/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
65c816 CPU header

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

#ifndef _E1100_CPU_H
#define _E1100_CPU_H

#include <stdint.h>

#include "mem.h"
#include "coro.h"

#define CPU_HZ_NTSC 8053976
#define CPU_HZ_PAL 7758833

/* types */

typedef BYTE REG_8;
typedef uint16_t REG_16;

typedef REG_8 Read8(void);
typedef REG_16 Read16(void);
typedef void Write8(REG_8 val);
typedef void Write16(REG_16 val);

/* P flags */

#define P_N 0x80U /* ALU negative flag */
#define P_V 0x40U /* ALU signed overflow flag */
#define P_B 0x20U /* break flag (emulation mode) */
#define P_M 0x20U /* 16/8-bit A in native mode */
#define P_X 0x10U /* 16/8-bit X/Y in native mode */
#define P_D 0x08U /* BCD flag */
#define P_I 0x04U /* IRQ/COP mask */
#define P_Z 0x02U /* ALU zero flag */
#define P_C 0x01U /* ALU carry flag */

#define A_8b() (regs.E | (regs.P & P_M))
#define XY_8b() (regs.E | (regs.P & P_X))

/* registers */

typedef struct CPURegs {
    REG_16 A;
    REG_16 X;
    REG_16 Y;
    REG_16 S;
    REG_8 P;
    REG_16 PC;
    REG_16 D;
    REG_8 K;
    REG_8 B;
    char E;
} CPURegs;

extern CPURegs regs;
extern int irqDisable;
extern int cpuStp;
extern int cpuWai;
extern BYTE lastOpcode;

/* helpers */

#define GET_A() (A_8b() ? (regs.A & 0xFF) : (regs.A))
#define GET_X() (XY_8b() ? (regs.X & 0xFF) : (regs.X))
#define GET_Y() (XY_8b() ? (regs.Y & 0xFF) : (regs.Y))

#define CANCEL cpu_should_cancel_instruction

#define SET_A(v) ( regs.A = CANCEL() ? regs.A \
                    : A_8b() ? ((regs.A & 0xFF00) | ((v) & 0xFF)) : (v) )
#define SET_X(v) ( regs.X = CANCEL() ? regs.X \
                    : XY_8b() ? ((regs.X & 0xFF00) | (v) & 0xFF) : (v) )
#define SET_Y(v) ( regs.Y = CANCEL() ? regs.Y \
                    : XY_8b() ? ((regs.Y & 0xFF00) | (v) & 0xFF) : (v) )
#define SET_P(v) ( regs.P = CANCEL() ? regs.P : (v) )
#define SET_D(v) ( regs.D = CANCEL() ? regs.D : (v) )
#define SET_B(v) ( regs.B = CANCEL() ? regs.B : (v) )
#define SET_K(v) ( regs.K = CANCEL() ? regs.K : (v) )

#define UPDATE_Z_8(v) SET_P((regs.P & ~P_Z) | ((v) ? 0 : P_Z))
#define UPDATE_Z_16(v) SET_P((regs.P & ~P_Z) | ((v) ? 0 : P_Z))
#define UPDATE_NZ_8(v) SET_P((regs.P & ~P_Z & ~P_N) | \
                (((v) >> 7) ? P_N : 0) | ((v) ? 0 : P_Z))
#define UPDATE_NZ_16(v) SET_P((regs.P & ~P_Z & ~P_N) | \
                (((v) >> 15) ? P_N : 0) | ((v) ? 0 : P_Z))
#define UPDATE_NV_8(v) \
        SET_P((regs.P & ~P_N & ~P_V) | ((((v) >> 7) & 1) ? P_N : 0) \
                                     | ((((v) >> 6) & 1) ? P_V : 0))
#define UPDATE_NV_16(v) \
        SET_P((regs.P & ~P_N & ~P_V) | ((((v) >> 15) & 1) ? P_N : 0) \
                                     | ((((v) >> 14) & 1) ? P_V : 0))

#define CODE_ADDR(x) ((regs.K << 16) | ((x) & 0xFFFF))
#define DATA_ADDR(x) ((regs.B << 16) | ((x) & 0xFFFF))
#define STACK_ADDR() (regs.E ? (0x0100 | (regs.S & 0xFF)) : regs.S)

/* wrap & addressing modes */

#define GET_ADDR(am) (am.v.addr)

typedef enum AddrModeFlags {
    AM_NOFLAGS = 0,
    AM_NOWRAP = 0,
    AM_WRAP_8 = 1,
    AM_WRAP_16 = 2,
    AM_INC_PC = 4
} AddrModeFlags;

typedef struct AddrModeBM {
    REG_8 dstb;
    REG_8 srcb;
} AddrModeBM;

typedef union AddrModeUnion {
    ADDR addr;
    AddrModeBM bm;
} AddrModeUnion;

typedef struct AddrMode {
    void (*decode)(struct AddrMode* am);
    AddrModeUnion v;
    AddrModeFlags flags;
} AddrMode;

/* methods */

typedef void (*cpu_instr)(AddrMode am);

void cpu_init(void);
void cpu_cycle(void);
ADDR cpu_inc_pc(void);
void cpu_free(void);
int cpu_should_cancel_instruction();
int cpu_should_abort_instruction();

void cpu_reset(void);
void cpu_irq(void);
void cpu_nmi(void);
void cpu_cop(void);
void cpu_abort(void);
int cpu_halted(void);

void cpu_push8(REG_8 v);
void cpu_push16(REG_16 v);
void cpu_push24(ADDR a);
REG_8 cpu_pull8(void);
REG_16 cpu_pull16(void);
ADDR cpu_pull24(void);

#define END_CYCLE_NOABORT() coro_yield()
#define END_CYCLE() { \
        if (cpu_should_abort_instruction()) return; \
        coro_yield(); \
        irqDisable = regs.P & P_I; \
    }
#define cpu_mem_write(a, v) \
        if(!cpu_should_cancel_instruction()) mem_write(a, v)

/* debug stuff */

extern int cpu_debug;
extern int cpu_debug_instr;
#define CPU_DEBUG_ENDINSTR() { \
        if (cpu_debug_instr) \
            if (!--cpu_debug_instr) \
                END_CYCLE_NOABORT(); \
    }
void emulator_disasm_instr(REG_16 pc);

/* addressing modes */

extern const AddrMode cpu_addr_none;
extern const AddrMode cpu_addr_imm;
extern const AddrMode cpu_addr_dp;
extern const AddrMode cpu_addr_dpx;
extern const AddrMode cpu_addr_dpy;
extern const AddrMode cpu_addr_idp;
extern const AddrMode cpu_addr_idpx;
extern const AddrMode cpu_addr_idpy;
extern const AddrMode cpu_addr_idpl;
extern const AddrMode cpu_addr_idly;
extern const AddrMode cpu_addr_idsy;
extern const AddrMode cpu_addr_sr;
extern const AddrMode cpu_addr_abs;
extern const AddrMode cpu_addr_absx;
extern const AddrMode cpu_addr_absy;
extern const AddrMode cpu_addr_abl;
extern const AddrMode cpu_addr_ablx;
extern const AddrMode cpu_addr_iabs;
extern const AddrMode cpu_addr_iabx;
extern const AddrMode cpu_addr_iabl;
extern const AddrMode cpu_addr_bm;

/* coroutines */

void cpu_am_decode(AddrMode* am);
REG_8 cpu_am_read8(AddrMode* am);
void cpu_am_write8(AddrMode* am, REG_8 v);
REG_16 cpu_am_read16(AddrMode* am);
REG_16 cpu_am_read16_noinc(AddrMode* am);
void cpu_am_write16(AddrMode* am, REG_16 v);

void cpu_instruction_ADC(AddrMode am);
void cpu_instruction_AND(AddrMode am);
void cpu_instruction_ASL(AddrMode am);
void cpu_instruction_ASLa(AddrMode am);
void cpu_instruction_BCC(AddrMode am);
void cpu_instruction_BCS(AddrMode am);
void cpu_instruction_BEQ(AddrMode am);
void cpu_instruction_BIT(AddrMode am);
void cpu_instruction_BITi(AddrMode am);
void cpu_instruction_BMI(AddrMode am);
void cpu_instruction_BNE(AddrMode am);
void cpu_instruction_BPL(AddrMode am);
void cpu_instruction_BRA(AddrMode am);
void cpu_instruction_BRK(AddrMode am);
void cpu_instruction_BRL(AddrMode am);
void cpu_instruction_BVC(AddrMode am);
void cpu_instruction_BVS(AddrMode am);
void cpu_instruction_CLC(AddrMode am);
void cpu_instruction_CLD(AddrMode am);
void cpu_instruction_CLI(AddrMode am);
void cpu_instruction_CLV(AddrMode am);
void cpu_instruction_CMP(AddrMode am);
void cpu_instruction_COP(AddrMode am);
void cpu_instruction_CPX(AddrMode am);
void cpu_instruction_CPY(AddrMode am);
void cpu_instruction_DEC(AddrMode am);
void cpu_instruction_DECa(AddrMode am);
void cpu_instruction_DEX(AddrMode am);
void cpu_instruction_DEY(AddrMode am);
void cpu_instruction_EOR(AddrMode am);
void cpu_instruction_INC(AddrMode am);
void cpu_instruction_INCa(AddrMode am);
void cpu_instruction_INX(AddrMode am);
void cpu_instruction_INY(AddrMode am);
void cpu_instruction_JML(AddrMode am);
void cpu_instruction_JMP(AddrMode am);
void cpu_instruction_JSL(AddrMode am);
void cpu_instruction_JSR(AddrMode am);
void cpu_instruction_JSRx(AddrMode am);
void cpu_instruction_LDA(AddrMode am);
void cpu_instruction_LDX(AddrMode am);
void cpu_instruction_LDY(AddrMode am);
void cpu_instruction_LSR(AddrMode am);
void cpu_instruction_LSRa(AddrMode am);
void cpu_instruction_MVN(AddrMode am);
void cpu_instruction_MVP(AddrMode am);
void cpu_instruction_NOP(AddrMode am);
void cpu_instruction_ORA(AddrMode am);
void cpu_instruction_PEA(AddrMode am);
void cpu_instruction_PER(AddrMode am);
void cpu_instruction_PHA(AddrMode am);
void cpu_instruction_PHB(AddrMode am);
void cpu_instruction_PHD(AddrMode am);
void cpu_instruction_PHK(AddrMode am);
void cpu_instruction_PHP(AddrMode am);
void cpu_instruction_PHX(AddrMode am);
void cpu_instruction_PHY(AddrMode am);
void cpu_instruction_PLA(AddrMode am);
void cpu_instruction_PLB(AddrMode am);
void cpu_instruction_PLD(AddrMode am);
void cpu_instruction_PLP(AddrMode am);
void cpu_instruction_PLX(AddrMode am);
void cpu_instruction_PLY(AddrMode am);
void cpu_instruction_REP(AddrMode am);
void cpu_instruction_ROL(AddrMode am);
void cpu_instruction_ROLa(AddrMode am);
void cpu_instruction_ROR(AddrMode am);
void cpu_instruction_RORa(AddrMode am);
void cpu_instruction_RTI(AddrMode am);
void cpu_instruction_RTL(AddrMode am);
void cpu_instruction_RTS(AddrMode am);
void cpu_instruction_SBC(AddrMode am);
void cpu_instruction_SEC(AddrMode am);
void cpu_instruction_SED(AddrMode am);
void cpu_instruction_SEI(AddrMode am);
void cpu_instruction_SEP(AddrMode am);
void cpu_instruction_STA(AddrMode am);
void cpu_instruction_STP(AddrMode am);
void cpu_instruction_STX(AddrMode am);
void cpu_instruction_STY(AddrMode am);
void cpu_instruction_STZ(AddrMode am);
void cpu_instruction_TAX(AddrMode am);
void cpu_instruction_TAY(AddrMode am);
void cpu_instruction_TCD(AddrMode am);
void cpu_instruction_TCS(AddrMode am);
void cpu_instruction_TDC(AddrMode am);
void cpu_instruction_TRB(AddrMode am);
void cpu_instruction_TSB(AddrMode am);
void cpu_instruction_TSC(AddrMode am);
void cpu_instruction_TSX(AddrMode am);
void cpu_instruction_TXA(AddrMode am);
void cpu_instruction_TXS(AddrMode am);
void cpu_instruction_TXY(AddrMode am);
void cpu_instruction_TYA(AddrMode am);
void cpu_instruction_TYX(AddrMode am);
void cpu_instruction_WAI(AddrMode am);
void cpu_instruction_WDM(AddrMode am);
void cpu_instruction_XBA(AddrMode am);
void cpu_instruction_XCE(AddrMode am);

#endif /* _E1100_CPU_H */
