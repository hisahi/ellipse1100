; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS I/O functions
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

DOSGETFILEHANDLE:
        TXA
        ASL     A
        TAX
        PHB
        ACC8
        LDA     DOSLD|DOSPROGBANK.L
        PHA
        PLB
        ACC16
        CPX     #$10
        BCS     @INVALIDINDEX
        LDA     $0020.W,X
-       STA     DOSLD|DOSACTIVEHANDLE.L
        PLB
        RTS
@INVALIDINDEX:
        LDA     #0
        BRA     -

DOSSTDINREAD:           ; $01 = read char from STDIN
        LDA     #CONMODENORMAL
        STA     DOSLD|DOSSTDINCONMODE.L
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        JMP     DOSREADFILECHAR
+       RTS

DOSSTDINREADQUIET:      ; $07 = read char from STDIN w/o echo
        LDA     #CONMODEQUIET
        STA     DOSLD|DOSSTDINCONMODE.L
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        JMP     DOSREADFILECHAR
+       RTS

DOSSTDINREADRAW:        ; $08 = raw read char from STDIN
        LDA     #CONMODERAW
        STA     DOSLD|DOSSTDINCONMODE.L
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        JMP     DOSREADFILECHAR
+       RTS

DOSSTDOUTWRITE:         ; $02 = write char to STDOUT
        PHA
        PHX
        LDX     #1
        JSR     DOSGETFILEHANDLE
        PLX
        PLA
        BCS     +
        JSR     DOSWRITEFILECHAR
+       RTS

DOSOUTPUTSTRING00:      ; $19 = output string ending in '\0'
        PHA
        PHX
        LDX     #1
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        ACC8
        LDA     #$00
        STA     DOSLD|DOSFILESTRTERM.L
        ACC16
        JSR     DOSWRITEFILESTR.W
+       PLA
        RTS

DOSOUTPUTSTRING24:      ; $09 = output string ending in '$'
        PHA
        PHX
        LDX     #1
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        ACC8
        LDA     #'$'
        STA     DOSLD|DOSFILESTRTERM.L
        ACC16
        JSR     DOSWRITEFILESTR.W
+       PLA
        RTS

DOSREADLINEINPUT:       ; $0A = read line of input
        PHA
        LDA     #CONMODEQUIET
        STA     DOSLD|DOSSTDINCONMODE.L
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        PLX
        BCS     +
        JSR     DOSREADFILELINE
+       PLA
        RTS

DOSINPUTSTATUS:         ; $0B = get input status
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        BEQ     +
        LDA     #$FFFF
        PLX
        RTS
+       PLX
        LDA     DOSBANKD|DOSKEYBBUFR.L
        CMP     DOSBANKD|DOSKEYBBUFL.L
        BNE     +
        LDA     #$0000
        RTS
+       LDA     #$FFFF
        RTS

DOSFLUSHSTDIN:          ; $0C = flush stdin
        PHA
        PHX
        LDX     #0
        JSR     DOSGETFILEHANDLE
        BEQ     +
        PLX
        PLA
        RTS
+       LDA     DOSBANKD|DOSKEYBBUFR.L
        STA     DOSBANKD|DOSKEYBBUFL.L
        PLX
        PLA
        RTS
