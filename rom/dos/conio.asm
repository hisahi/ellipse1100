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

DOSREADCONCHAR:
        PHY
        PHX
@WAI
        WAI
        LDA     DOSLD|DOSINNMI.W
        BEQ     +
        LDA     #0
        STA     DOSLD|DOSINNMI.W
        LDA     DOSBANKD|DOSFLASHCURSOR.L
        BEQ     +
        JSL     TEXT_FLASHCUR.L
+       LDA     DOSBANKD|DOSKEYBBUFL.L
        CMP     DOSBANKD|DOSKEYBBUFR.L
        BEQ     @WAI
        LDA     DOSBANKD|DOSKEYBBUFL.L
        TAX
        LDA     DOSBANKD|DOSKEYBBUF.L,X
        INX
        PHA
        TXA
        AND     #$0F
        STA     DOSBANKD|DOSKEYBBUFL.L
        PLA
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
-       JSR     DOSREADCONCHAR
        BEQ     @CR
        ACC8
        CMP     #$08
        BEQ     @BKSP
        PHA
        TYA
        CMP     DOSLD|DOSTMP1.L
        BCS     @BUFEND
        PLA
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
