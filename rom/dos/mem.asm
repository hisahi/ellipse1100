; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS memory functions
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

DOSINITMISCBUFFERS:
        STZ     DOSSTRINGCACHE.W
        STZ     DOSENVTABLE.W
        LDX     #DOSPATHSTRSIZE
-       DEX
        DEX
        STZ     DOSPATHSTR.W,X
        BPL     -
        LDY     #0
-       LDA     #$FFFF
        STA     DOSFILETABLE.W,Y
        TYA
        CLC
        ADC     #$0030
        TAY
        CPY     #$0400
        BCC     -
        ACC8
        LDA     IOBANK|ERAMBANK.L
        ACC16
        AND     #$7F
        INC     A
        STA     DOSTMP1.W
        LDX     #$007F
        ACC8
        LDA     #$FF
-       STA     DOSFREEBANKS.W,X
        DEX
        CPX     DOSTMP1.W
        BCS     -
        LDA     #$00
-       STA     DOSFREEBANKS.W,X
        DEX
        BPL     -
        LDA     #$FF
        STA     DOSFREEBANKS.W,X
        STA     DOSFREEBANKS.W+1,X
        ACC16
        RTS

; assumes DB=DOSBANKD
; C=1 if no more RAM banks available
; C=0 if A is next free bank 
; clobbers X
DOSALLOCRAMBANK:
        ACC8
        LDX     #2
-       BIT     DOSFREEBANKS.W,X
        BPL     +
        INX
        CPX     #$80
        BCC     -
        ACC16
        LDA     #DOS_ERR_OUT_OF_MEMORY
        SEC
        RTS
.ACCU 8
+       LDA     #$FF
        STA     DOSFREEBANKS.W,X
        ACC16
        TXA
        ORA     #$80
        AND     #$FF
        CLC
        RTS

; assumes DB=DOSBANKD
; X=RAM bank to free (clobbered)
DOSUNALLOCRAMBANK:
        ACC16
        TXA
        AND     #$007F
        TAX
        CPX     #2
        BCC     +
        ACC8
        STZ     DOSFREEBANKS.W,X
        ACC16
+       RTS

; copy memory from B:X to string buffer and terminate
; X contains length
DOSCOPYBXSTRBUF:
        ACC8
        TXY
        LDX     #0
-       CPX     #$FF
        BCS     +
        LDA     $0000,Y
        BEQ     +
        STA     DOSBANKD|DOSSTRINGCACHE.L,X
        INX
        INY
        BRA     -
+       LDA     #0
        STA     DOSBANKD|DOSSTRINGCACHE.L,X
        ACC16
        RTS

; copy memory from B:X to string buffer in uppercase and terminate
; X contains length
DOSCOPYBXSTRBUFUC:
        ACC8
        TXY
        LDX     #0
-       CPX     #$FF
        BCS     +
        LDA     $0000,Y
        BEQ     +
        JSR     DOSCHARUC
        STA     DOSBANKD|DOSSTRINGCACHE.L,X
        INX
        INY
        BRA     -
+       LDA     #0
        STA     DOSBANKD|DOSSTRINGCACHE.L,X
        ACC16
        RTS

; wipe some parts of the buffer after the terminator
DOSWIPEBUFFERLEFTOVER:
        ACC8
        LDX     #0
        DEX
-       INX
        LDA     DOSSTRINGCACHE.W,X
        BNE     -
        LDA     #0
-       INX
        STA     DOSSTRINGCACHE.W,X
        CPX     #17
        BCC     -
        ACC16
        RTS

.ACCU 8
; make character uppercase
DOSCHARUC:
        CMP     #'a'
        BCC     +
        CMP     #'z'+1
        BCS     +
        AND     #$DF
+       RTS

.ACCU 16
DOSALLOCMEM:            ; $3A = allocate memory
DOSFREEMEM:             ; $3B = free memory allocation
