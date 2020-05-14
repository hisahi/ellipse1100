/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
65c816 ALU header

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

#ifndef _E1100_ALU_H
#define _E1100_ALU_H

#include "cpu.h"

REG_8 alu_asl8(REG_8 v);
REG_16 alu_asl16(REG_16 v);
REG_8 alu_lsr8(REG_8 v);
REG_16 alu_lsr16(REG_16 v);
REG_8 alu_rol8(REG_8 v);
REG_16 alu_rol16(REG_16 v);
REG_8 alu_ror8(REG_8 v);
REG_16 alu_ror16(REG_16 v);

void alu_A_adc8(REG_8 v);
void alu_A_adc16(REG_16 v);
void alu_A_sbc8(REG_8 v);
void alu_A_sbc16(REG_16 v);
void alu_A_bit8(REG_8 v);
void alu_A_bit16(REG_16 v);
REG_8 alu_cmp8(REG_8 r, REG_8 v);
REG_16 alu_cmp16(REG_16 r, REG_16 v);

#endif /* _E1100_ALU_H */
