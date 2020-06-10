; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS execution/task functions
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

DOSLOADEXEC:
        ACC8
        LDA     DOSTMP7.B
        STA     DOSIOBANK.B
        ACC16
        LDY     #$1E
        LDA     (DOSTMP5.B),Y
        STA     DOSTMP8.B
        LDX     #$0100
-       PHX
        LDY     DOSTMP8.B
        JSR     DOSLOADCHUNK.W
        BCS     @ERRC
        LDX     DOSTMP8.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERRC
        STX     DOSTMP8.B
        CPX     #$FFFF
        BEQ     +
        PLA
        CLC
        ADC     #$0400
        TAX
        BRA     -
+       PLA
        ACC8
        LDA     #$80
        STA     DOSIOBANK.B
        ACC16
        CLC
        LDA     #0
        RTS
@ERRC   PLX
@ERR    PHA
        ACC8
        LDA     #$80
        STA     DOSIOBANK.B
        ACC16
        PLA
        SEC
        RTS

DOSLAUNCH:              ; $38 = launch program
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        AXY16
        LDA     1,S
        TAX
        LDA     3,S
        TAY
        ENTERDOSRAM
        JSR     DOSPAGEINDIR.W
        JSR     DOSRESOLVEPATHFILE.W
        BCS     @ERR
        JSR     DOSALLOCRAMBANK.W
        BCS     @ERR
        STA     DOSTMP7.B
        ACC16
        LDA     DOSNEXTFILEOFF.B
        CLC
        ADC     #DIRCHUNKCACHE.W
        STA     DOSTMP5.B
        LDY     #$1A
        LDA     (DOSTMP5.B),Y
        CMP     #65280
        BCC     +
        LDA     #DOS_ERR_EXEC_TOO_LARGE
        BRA     @ERR
+       INY
        INY
        LDA     (DOSTMP5.B),Y
        BEQ     +
        LDA     #DOS_ERR_EXEC_TOO_LARGE
@ERR    EXITDOSRAM
        PLY
        PLX
        SEC
        RTS
+       ; load executable into memory
        JSR     DOSLOADEXEC.W
        BCS     @ERR

        ; prepare executable header
                ; stack: X, Y, B, D
        LDA     4,S
        STA     DOSTMP8.B

        ; copy command line from B:X
        LDA     #$0081
        STA     DOSTMP6.B
        ACC8
        PHB     ; stack: X, Y, B, D, B
        LDA     4,S
        PHA
        PLB

        ACC16
        LDY     #0
        LDA     (DOSTMP8.B),Y
        STA     DOSTMP3.B
        ACC8

        LDY     #0
-       LDA     (DOSTMP3.B),Y
        STA     [DOSTMP6.B],Y
        BEQ     +
        INY
        CPY     #$7E
        BCC     -
        LDA     #0
        STA     [DOSTMP6.B],Y
+       ; store length of command line
        ACC16
        DEC     DOSTMP6.B
        ACC8
        TYA
        LDY     #0
        STA     [DOSTMP6.B],Y
        ACC16

        ; copy environment pointer
        LDA     #$0007
        STA     DOSTMP6.B
        INC     DOSTMP8.B
        INC     DOSTMP8.B
        LDA     (DOSTMP8.B),Y
        BEQ     ++
        ; non-zero pointer, apply
        LDY     #0
        STA     [DOSTMP6.B],Y
        ACC8
        PHB
        PLA
        LDY     #2
        CMP     #$81
        BNE     +
        DEC     A
+       STA     [DOSTMP6.B],Y
        BRA     +++
++      ; inherit from current process
        ; stack: ORIG_ADDR(24), DOSCALLEXIT(16), X, Y, B, D, B
        ACC8
        ; load old program bank
        LDA     12,S
        PHA
        PLB
        LDY     #0
        LDA     $0007.W
        STA     [DOSTMP6.B],Y
        INY
        LDA     $0008.W
        STA     [DOSTMP6.B],Y
        INY
        LDA     $0009.W
        STA     [DOSTMP6.B],Y
+++     ACC16
        PLB
        
        ; stack: ORIG_ADDR(24), DOSCALLEXIT(16), X, Y, B, D

        ; initialize local process file list
        LDA     #$0020
        STA     DOSTMP6.B
        LDA     #$0000
        LDY     #30
-       STA     [DOSTMP6.B],Y
        DEY
        DEY
        BPL     -

        ; initialize stdin, stdout, stderr
        LDY     #0
        LDA     #$0001
        STA     [DOSTMP6.B],Y
        LDY     #2
        STA     [DOSTMP6.B],Y
        LDY     #4
        STA     [DOSTMP6.B],Y
        
        STZ     DOSTMP6.B
        ; job ID
        LDY     #$0E
        LDA     DOSTMP7.B
        AND     #$7F
        STA     [DOSTMP6.B],Y

        ; DOS version
        LDY     #0
        JSR     DOSGETVER.W
        STA     [DOSTMP6.B],Y
        
        ; stack pointer
        ACC8
        LDA     IOBANK|ESTKBANK.L
        LDY     #$06
        STA     [DOSTMP6.B],Y

        ; discard old X, Y from stack
        PLX     ; D
        PLA     ; B
        PLY     ; wasted
        PLY     ; wasted
        PHA     ; B
        PHX     ; D
        
        ; stack: ORIG_ADDR(24), DOSCALLEXIT(16), B, D

        ACC16

        TSC
        LDY     #$04
        STA     [DOSTMP6.B],Y

        LDA     #$0079
        STA     DOSTMP6.B

        ; trampoline
        LDY     #0
        LDA     #((DOSBUSY&$FF)<<8)|$8F          ; STA ...|DOSBUSY.L
        STA     [DOSTMP6.B],Y
        LDA     #(DOSLD>>8)                      ; ... DOSLD...
        LDY     #2
        STA     [DOSTMP6.B],Y
        LDA     #$004C                           ; JMP... abs
        LDY     #4
        STA     [DOSTMP6.B],Y
        LDA     #$0100
        LDY     #5
        STA     [DOSTMP6.B],Y

        LDX     #0
        LDY     #0
        ACC8
        LDA     #$5C
        STA     DOSTMP5+1.B
        LDA     DOSTMP7.B
        PHA     ; store bank since we need it later
        PHA
        PLB
        ; stack: ORIG_ADDR(24), DOSCALLEXIT(16), B, D, B
        AXY16
        LDA     #0
        TCD
DOSJUMPPROG:
        JSL     DOSLD|DOSTMP5+1.L    ; go to STA+JML vector and
                                     ; start running program
DOSJUMPPROGRTL:
        ; in case the program RTLs
        AXY16
        LDA     #$0000
        PEA     $0000
        PEA     $0000

; assumed stack: RTL24(K8 PC16) RTS16
DOSTERMINATE:           ; $00 = terminate program
        ACC8
        STA     DOSLD|DOSLASTEXITCODE.L
        ; set data bank to be equal to program bank
        LDA     5,S
        PHA
        PLB
        ACC16
        AND     #$FF
        TAY
        ACC8
        ; restore old stack bank
        LDA     $0006.W
        STA     IOBANK|ESTKBANK.L
        ; restore old stack pointer
        ACC16
        LDA     $0004.W
        TCS
        EXITDOSRAM
        ENTERDOSRAM
        ACC16
        STY     DOSTMP8.B
        LDA     #$0020
        STA     DOSTMP7.B
@CLOSEFILEHANDLES:
        ; close file handles
        PHY
        LDY     #0
-       LDA     [DOSTMP7.B],Y
        CMP     #DOSFILETABLE
        BCC     +
        TAX
        PHY
        LDA     #$FFFF
        JSR     DOSCLOSEHANDLE.W
        PLY
+       INY
        INY
        CPY     #$0020
        BCC     -
        PLY
        ; TODO: free allocated blocks
        ; free program bank
        TYX
        JSR     DOSUNALLOCRAMBANK.W

DOSLAUNCHRETURN:
        JSR     DOSWRITEBACK.W
        EXITDOSRAM
DOSGETEXITCODE:         ; $39 = get exit code
        ACC8
        LDA     DOSLD|DOSLASTEXITCODE.L
        ACC16
        AND     #$FF
        CLC
        RTS
