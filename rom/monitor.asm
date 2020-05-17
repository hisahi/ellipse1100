; Ellipse Workstation 1100 (fictitious computer)
; ROM code (machine language monitor)
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

.BANK 1

.ORG $8000

; KEYCODETABLE, KEYB_APPLY_CAPS_TO_KEY in keytbls.asm

.DEFINE OLDREGB  $2F00
.DEFINE OLDREGD  $2F02
.DEFINE OLDREGK  $2F04
.DEFINE OLDREGP  $2F06
.DEFINE OLDREGPC $2F08
.DEFINE MCURADDR $2F10
.DEFINE MCURBANK $2F12
.DEFINE MNREGD   $2F14
.DEFINE MNREGP   $2F16
.DEFINE MNREGB   $2F17
.DEFINE MNREGACC $2F18
.DEFINE MNREGX   $2F1A
.DEFINE MNREGY   $2F1C
.DEFINE MNREGS   $2F1E
.DEFINE MNLINELN $2F20
.DEFINE MNLINEPS $2F22
.DEFINE MONTMP1  $2F30
.DEFINE MONTMP2  $2F32
.DEFINE MONTMP3  $2F34
.DEFINE MONTMP4  $2F36
.DEFINE MONBRKOL $2F38
.DEFINE MONNMIOL $2F3B
.DEFINE MONINNMI $2F3E
.DEFINE MONBLINK $2F40
.DEFINE MONBUF   $2F80

.DEFINE PROMPTLINELEN $3F

MLMONITOR:                      ; enter with JSL
        PHP
        PHB
        PHD
        AXY16
        LDA     #$2F00
        PHA
        PLD
        ACC8
        LDA     #$80
        PHA
        PLB
        ; stack: D B P PC K
        LDA     3,S
        STA     OLDREGB.W
        LDA     4,S
        STA     OLDREGP.W
        LDA     7,S
        STA     OLDREGK.W
        ACC16
        LDA     1,S
        STA     OLDREGD.W
        LDA     5,S
        STA     OLDREGPC.W

        STZ     MONINNMI.W

        LDA     #MLMONBRK.W
        LDX     #MONBRKOL.W
        LDY     #$0001.W
        JSL     ROM_SWAPBRK.L

        LDA     #MLMONNMI.W
        LDX     #MONNMIOL.W
        LDY     #$0001.W
        JSL     ROM_SWAPNMI.L

        ACC8                    ; enable VSYNC NMI and keyboard IRQ
        LDA     IOBANK|VPUCNTRL.L
        ORA     #$04
        STA     IOBANK|VPUCNTRL.L
        LDA     IOBANK|EINTGNRC.L
        ORA     #$01
        STA     IOBANK|EINTGNRC.L
        ACC16

        STZ     MONBLINK.W

        LDA     #$C000
        STA     MCURADDR.W
        LDA     #$0081
        STA     MCURBANK.W
        LDA     #$03FF
        STA     MNREGS.W
        XBA
        STA     MNREGP.W
        STZ     MNREGACC.W
        STZ     MNREGX.W
        STZ     MNREGY.W
        STZ     MNREGD.W
        CLI
@LOOP:
        JSR     MONITORPROMPT
.ACCU 16
        LDA     #0
        ACC8
        LDA     MONBUF.W
        CMP     #$0D
        BEQ     @LOOP
        AND     #$DF
        CMP     #$41
        BCC     @UNKCMD
        CMP     #$5B
        BCS     @UNKCMD
        SEC
        SBC     #$41
        ASL     A
        TAX
        JSR     (MONITORROUTINES,X)
        JMP     @LOOP

@UNKCMD:
        JSR     MONITORERROR 
        BRA     @LOOP

MONITORERROR:
        ACC8
        PHB
        LDA     #$01
        PHA
        PLB
        ACC16
        LDA     #MONITORMSGERROR
        JSL     TEXT_WRSTR
        PLB
        RTS

MONITORROUTINES:
        .DW     MONITORERROR                    ; A
        .DW     MONITORERROR                    ; B
        .DW     MONITORERROR                    ; C
        .DW     MONITORERROR                    ; D
        .DW     MONITORERROR                    ; E
        .DW     MONITORERROR                    ; F
        .DW     MONITORERROR                    ; G
        .DW     MONITORERROR                    ; H
        .DW     MONITORERROR                    ; I
        .DW     MONITORERROR                    ; J
        .DW     MONITORERROR                    ; K
        .DW     MONITORERROR                    ; L
        .DW     MONITORERROR                    ; M
        .DW     MONITORERROR                    ; N
        .DW     MONITORERROR                    ; O
        .DW     MONITORERROR                    ; P
        .DW     MONITOREXIT                     ; Q
        .DW     MONITORERROR                    ; R
        .DW     MONITORERROR                    ; S
        .DW     MONITORERROR                    ; T
        .DW     MONITORERROR                    ; U
        .DW     MONITORERROR                    ; V
        .DW     MONITORERROR                    ; W
        .DW     MONITORERROR                    ; X
        .DW     MONITORERROR                    ; Y
        .DW     MONITORERROR                    ; Z

MONITORPROMPT:
        ACC16
        STZ     MNLINELN.W
        STZ     MNLINEPS.W
        DEC     MONBLINK.W
        LDA     #$0D
        JSL     TEXT_WRCHR.L
        LDA     #$3F
        JSL     TEXT_WRCHR.L
@LOOP:
        JSL     KEYB_UPDKEYSI.L
        LDA     #28
        LDX     #26
        JSL     KEYB_GETKEY.L
        ACC16
        BEQ     @LOOP
        BCC     @LOOP
        CMP     #$09
        BEQ     @NORMAL
        CMP     #$0D
        BEQ     @CR
        CMP     #$08
        BEQ     @BKSP
        CMP     #$1E
        BEQ     @ARRLEFT
        CMP     #$1F
        BEQ     @ARRRIGHT
        CMP     #$7F
        BEQ     @LOOP
        CMP     #$20
        BCC     @LOOP
@NORMAL:
        LDX     MNLINELN.W
        CPX     #PROMPTLINELEN
        BCS     @LOOP
        STA     MONBUF.W,X
        INC     MNLINEPS.W
        INX
        STX     MNLINELN.W
        JSL     TEXT_WRCHR
        BRA     @LOOP
@ARRLEFT:
        LDX     MNLINEPS.W
        BEQ     @LOOP
        DEC     MNLINEPS.W
        JSL     TEXT_WRCHR
        BRA     @LOOP
@ARRRIGHT:
        LDX     MNLINEPS.W
        CPX     MNLINELN.W
        BCS     @LOOP
        INC     MNLINEPS.W
        JSL     TEXT_WRCHR
        BRA     @LOOP
@BKSP:
        LDX     MNLINEPS.W
        BEQ     @LOOP
        STA     MONBUF.W,X
        DEX
        STX     MNLINEPS.W
        DEC     MNLINELN.W
        JSL     TEXT_WRCHR
        BRL     @LOOP
@CR:
        LDX     MNLINELN.W
        STA     MONBUF.W,X
        INX
        STX     MNLINELN.W
        STZ     MONBLINK.W
        RTS

MONITOREXIT:
        AXY16

        LDX     #MONBRKOL.W
        LDY     #$0001.W
        JSL     ROM_UNSWAPBRK.L

        LDX     #MONNMIOL.W
        LDY     #$0001.W
        JSL     ROM_UNSWAPNMI.L

        ACC8
        LDA     #$01
        STA     IOBANK|EINTGNRC.L
        LDA     #$00
        STA     IOBANK|VPUCNTRL.L
        LDA     #$80
        PHA
        PLB
        LDA     OLDREGK.W
        PHA
        ACC16
        LDA     OLDREGPC.W
        PHA
        ACC8
        LDA     OLDREGP.W
        PHA
        LDA     OLDREGB.W
        PHA
        ACC16
        LDA     OLDREGD.W
        PHA
        PLD
        PLB
        PLP
        RTL

MLMONBRK:
        SETB16  $80
        JML     [MONBRKOL.W]

MLMONNMI:
        SETB16  $01
        LDA     MONINNMI.W
        BNE     @NMIRET
        DEC     MONINNMI.W
        JSL     KEYB_INCTIMER
        SETB16  $80
        LDA     MONBLINK.W
        BEQ     +
        JSL     TEXT_FLASHCUR
+       STZ     MONINNMI.W
        BRA     +
@NMIRET SETB16  $80
+       JML     [MONNMIOL.W]

MONITORMSGERROR:
        .DB     13,"=ERROR=",0
