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
        LDA     #$01
        STA     DOSFREEBANKS.W,X
        STA     DOSFREEBANKS.W+1,X
        ACC16
        RTS

DOSALLOCRAMBANK_MEM:
        ACC8
        LDA     #$05
        BRA     DOSALLOCRAMBANK_EXEC@STA
DOSALLOCRAMBANK_EXEC:
        ACC8
        LDA     #$8F
@STA    STA     DOSTMP1.B
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
+       LDA     DOSTMP1.B
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

.ACCU 8
DOSALLOCMEM_BANKINIT:
        LDA     #$05
        STA     DOSFREEBANKS.W,Y
        PHB
        PHA
        PLB
        ACC16
        STZ     $0000.W
        STZ     $0002.W
        STZ     $0004.W
        STZ     $0006.W
        PLB
        BRA     DOSALLOCMEM_INT_BANK

.ACCU 16
; Y=bank&$7F
; C=0 X=offset
; C=1
;
; memory allocation
;               $00     job ID          $00     if free
;               $04     next block header or 0 if end of chain
;               $06     previous block header or 0 if beginning
;
DOSALLOCMEM_INT_BANK:
        ACC8
        PHB
        LDA     DOSFREEBANKS.W,Y
        BEQ     DOSALLOCMEM_BANKINIT
        CMP     #5
        BEQ     @CHECKOK
        BRL     @NOTAVL
@CHECKOK:
        TYA
        PHA
        PLB
        LDX     #0
        ACC16
@BANKLOOP:
        LDA     $0000.W,X
        BNE     @NOTFREE

        TXA
        EOR     #$FFFF
        INC     A
        SEC
        SBC     #$08
        CLC
        ADC     $0004.W,X

        CMP     DOSLD|DOSTMP1.L
        BCS     @FOUNDBLK

@NOTFREE:
        LDA     $0004.W,X
        BNE     +
        BRL     @NOTAVL
+       TAX
        BRA     @BANKLOOP
@FOUNDBLK:
        PHA
        SEC
        SBC     DOSLD|DOSTMP1.L
        CMP     #8
        BCC     @NOADJ
        PLA

        TXA
        CLC
        ADC     DOSLD|DOSTMP1.L
        PHX
        TAX
        STZ     $0000.W,X
        STZ     $0002.W,X
        LDA     1,S             ; old X
        STA     $0006.W,X
        PHX
        TAX
        LDA     $0004.W,X
        PLX
        STA     $0004.W,X
        STA     DOSTMP2.B
        TXA
        PLX
        STA     $0004.W,X
        PHX
        LDX     DOSTMP2.B
        BEQ     +
        STA     $0006.W,X
+       PLX

        PHA
@NOADJ:
        LDA     DOSLD|DOSPROGBANK.L
        AND     #$FF
        STA     $0000.W,X
        PLA
        PLB
        CLC
        RTS
@NOTAVL:
        PLB
        ACC16
        SEC
        RTS

.ACCu 16
DOSFREEMEM_INT:
        ACC8
        PHB
        TYA
        PHA
        STA     DOSLD|DOSTMP1.L
        PLB
        ACC16

        ; is previous block free? merge if so
        LDA     $0006.W,X
        BEQ     +++
        LDA     $0004.W,X
        STA     DOSLD|DOSTMP2.L
        PHX
        TAX
        LDA     $0000.W,X
        BNE     ++
        LDA     DOSLD|DOSTMP2.L
        STA     $0004.W,X

        BEQ     +
        PHX
        TAX
        LDA     1,S
        STA     $0006.W,X
        PLX
+
        PLA
        BRA     +++
++      PLX
+++
        ; is next block free? merge if so
        LDA     $0004.W,X
        BEQ     +++
        PHX
        TAX
        LDA     $0000.W,X
        BNE     ++
        LDA     $0004.W,X
        STA     DOSLD|DOSTMP2.L
        BEQ     +
        PHX
        TAX
        LDA     3,S
        STA     $0006.W,X
        PLX
+
        LDA     DOSLD|DOSTMP2.L
        STA     $0004.W,X
++      PLX
+++
        ; mark block as free
        STZ     $0000.W,X

        ; is memory bank all free now? free if it so
        CLC
        LDX     #0
        BNE     +
        LDA     $0004.W,X
        BNE     +
        LDA     $0006.W,X
        BNE     +
        SEC
+
        ACC16
        PLB
        BCC     +
        LDA     DOSLD|DOSTMP1.L
        AND     #$FF
        TAX
        JSR     DOSUNALLOCRAMBANK.W
+       CLC
        RTS

.ACCU 16
DOSALLOCMEM:            ; $3A = allocate memory
        ENTERDOSRAM
        CPX     #65529
        BCS     @NOMEM
        STX     DOSTMP1.B

        LDY     #0
-       JSR     DOSALLOCMEM_INT_BANK
        BCC     @OK
        INY
        CPY     #16
        BCS     -

@NOMEM  LDA     #DOS_ERR_OUT_OF_MEMORY
        EXITDOSRAM
        SEC
        RTS

@OK     TYA
        AND     #$007F
        ORA     #$0080
        TAY
        EXITDOSRAM
        CLC
        RTS

DOSFREEMEM:             ; $3B = free memory allocation
        TXA
        PHX
        PHY
        ENTERDOSRAM
        SEC
        SBC     #$08
        TAX
        JSR     DOSFREEMEM_INT.W
        EXITDOSRAM
        PLY
        PLX
        CLC
        RTS
