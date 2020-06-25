; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS file I/O functionality
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

DOSREADFILECHAR:
        LDA     DOSLD|DOSACTIVEHANDLE.L
        BEQ     +
        CMP     #$0001
        BNE     @FILE
        JMP     DOSREADCONCHAR
+       LDA     #$FFFF
        RTS
@FILE   STP;TODO

DOSREADFILELINE:
        LDA     DOSLD|DOSACTIVEHANDLE.L
        BEQ     +
        CMP     #$0001
        BNE     ++
        JMP     DOSREADCONLINE
+       LDY     #0
        RTS
++      PHX
        TYA
        DEC     A
        STA     DOSLD|DOSTMP1.L
        LDY     #0
-       JSR     DOSREADFILECHAR@FILE.W
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
        TYA
        BRA     -
@CR     PLX
        RTS
@BKSP   CPX     #0
        BEQ     -
        DEX
        DEY
        BRA     -
@BUFEND 
.ACCU 8
        PLA
        CMP     #$0D
        BEQ     @CR
        BRA     -

.ACCU 16
DOSWRITEFILECHAR:
        PHA
        LDA     DOSLD|DOSACTIVEHANDLE.L
        BEQ     +
        CMP     #$0001
        BNE     ++
        PLA
        JMP     DOSWRITECONCHAR
+       RTS
++      PLA
@FILE   STP     ;TODO

DOSWRITEFILESTR:
        LDA     DOSLD|DOSACTIVEHANDLE.L
        BEQ     +
        CMP     #$0001
        BNE     ++
        JMP     DOSWRITECONSTR
+       RTS
++      LDA     $0000.W,X
        CMP     DOSLD|DOSFILESTRTERM.L
        BEQ     +
        PHX
        JSR     DOSWRITEFILECHAR@FILE.W
        PLX
        INX
        JMP     DOSWRITECONSTR
+       RTS
