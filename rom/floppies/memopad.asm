; Ellipse Workstation 1100 (fictitious computer)
; Sample memo pad floppy image
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

.INCLUDE "floppyhd.asm"

BEGINNING:
        STZ     GOTNMI.W
        CLI
        LDA     #MESSAGE
        LDX     #0
        LDY     #0
        JSL     TEXT_WRSTRAT.L

        LDA     #NMICHECKKEYB.W
        LDX     #OLDNMI.W
        LDY     #$0080.W
        JSL     ROM_SWAPNMI.L
        
        ACC8                            ; enable VSYNC NMI & keyboard interrupt
        STA     IOBANK|EINTGNRC.L

        LDA     IOBANK|VPUCNTRL.L
        ORA     #$04
        STA     IOBANK|VPUCNTRL.L
        ACC16

@LOOP:
        ACC8
        JSL     KEYB_UPDKEYSI
        LDA     #28
        LDX     #26
        JSL     KEYB_GETKEY
        BEQ     +
        BCC     +
        JSL     TEXT_WRCHR
+       WAI
        LDA     GOTNMI.W
        BEQ     @LOOP
@DBG    JSL     KEYB_INCTIMER
        JSL     TEXT_FLASHCUR
        ACC16
        DEC     GOTNMI.W
        ACC8
        BRA     @LOOP

MESSAGE:
        .DB     "MEMO PAD", 13, 0

GOTNMI:
        .DW     0
OLDNMI:
        .DL     0

NMICHECKKEYB:
        PEA     $8080
        PLB
        PLB
        INC     GOTNMI.W
        JML     [OLDNMI.W]
