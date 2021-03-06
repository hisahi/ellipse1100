; Ellipse Workstation 1100 (fictitious computer)
; Header for bootable SD (960KB) floppy
; 
; Copyright (c) 2020 Sampo Hippeläinen (hisahi)
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; 
; Written for the WLA-DX assembler
;

.INCLUDE "e1100.asm"

.IFNDEF FDSECTORS
.DEFINE FDSECTORS 12
.ENDIF

.DEFINE BANKCOUNT (FDSECTORS*5/4)

.MEMORYMAP
SLOTSIZE $10000
DEFAULTSLOT 0
SLOT 0 $0000
.ENDME

.ROMBANKMAP
BANKSTOTAL BANKCOUNT
BANKSIZE $10000
BANKS BANKCOUNT
.ENDRO

.ACCU 16
.INDEX 16

.BANK 0 .SLOT 0

.ORGA $000000           ; DATA
.IFDEF NOBOOT
        .DB     "ELLIPSE."
.ELSE
        .DB     "ELLIPSE@"
.ENDIF
