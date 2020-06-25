; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS console I/O functionality
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

DOSREADCONKEY:
        JSL     KEYB_UPDKEYSI.L
        AXY16
        LDA     #28
        LDX     #26
        JSL     KEYB_GETKEY.L
        ACC8
        BCC     ++
        BEQ     ++
        PHA
        LDA     DOSKEYBBUFR.W
        INC     A
        AND     #$0F
        CMP     DOSKEYBBUFL.W
        BEQ     @FULL
        STA     DOSKEYBBUFR.W
        DEC     A
        AND     #$0F
        TAX
        PLA
        STA     DOSKEYBBUF.W,X
++      AXY16
        RTS
@FULL   ; keyboard buffer is full
        PLA
        AXY16
        RTS

DOSREADCONCHAR:
        PHY
        PHX
        ENTERDOSRAM
        LDA     #$FF00
        STA     DOSIRQCOUNTER.B                 ; IRQ=0, KEYWAIT=1
@LOOP
        ACC8
        LDA     DOSIRQCOUNTER.B
        BNE     +
        WAI
+       LDA     #$00
        STA     DOSIRQCOUNTER.B                 ; IRQ=0, KEYWAIT=1
        LDA     DOSINNMI.B
        BEQ     +
        LDA     #0
        STA     DOSINNMI.B
        LDA     DOSFLASHCURSOR.W
        BEQ     +
        ACC16
        JSL     KEYB_INCTIMER.L
        JSL     TEXT_FLASHCUR.L
+       ACC16
        ; fill buffer
        JSR     DOSREADCONKEY.W
.ACCU 16
        LDA     DOSKEYBBUFL.W
        CMP     DOSKEYBBUFR.W
        BEQ     @LOOP
@GOTKEY:
        LDA     DOSKEYBBUFL.W
        TAX
        LDA     DOSKEYBBUF.W,X
        AND     #$00FF
        INX
        PHA
        TXA
        AND     #$0F
        STA     DOSKEYBBUFL.W
        LDA     #$0000
        STA     DOSIRQCOUNTER.B                 ; IRQ=0, KEYWAIT=0
        PLA
        EXITDOSRAM
        PLX
        PLY
        CMP     #0
        RTS

DOSREADCONLINE:
        PHX
        TYA
        DEC     A
        STA     DOSLD|DOSTMP1.L
        LDY     #0
-       JSR     DOSREADCONCHAR.W
        BEQ     @CR
        ACC8
        CMP     #$08
        BEQ     @BKSP
        PHA
        TYA
        CMP     DOSLD|DOSTMP1.L
        BEQ     +
        BCS     @BUFEND
+       PLA
        STA     $0000.W,X
        JSL     TEXT_WRCHR.L
        CMP     #$0D
        BEQ     @CR
        ACC16
        INX
        INY
        BRA     -
@CR     ACC16
        PLX
        RTS
@BKSP   ACC16
        CPY     #0
        BEQ     -
        DEX
        DEY
        JSL     TEXT_WRCHR.L
        BRA     -
@BUFEND 
.ACCU 8
        PLA
        CMP     #$0D
        BEQ     @CR
        BRA     -

DOSWRITECONCHAR:
        JSL     TEXT_WRCHR.L
        RTS

DOSWRITECONSTR:
        ACC8
-       LDA     $0000.W,X
        CMP     DOSLD|DOSFILESTRTERM.L
        BEQ     +
        JSL     TEXT_WRCHR.L
        INX
        BRA     -
+       ACC16
        RTS
