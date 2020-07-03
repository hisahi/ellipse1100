; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS bootloader
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

.DEFINE LOADSECT $00
.DEFINE LOADTRK $02
.DEFINE CHUNK $04
.DEFINE CCT $06
.DEFINE SPT $08
.DEFINE BANK $0A

BOOTLOAD:
        SEI
        LDA     #MESSAGE_DOSBOOTING.w
        LDX     #0
        LDY     #0
        JSL     TEXT_WRSTRAT

; read DOS.SYS to bank $81
@GOT_FLOPPY:
        ACC8
        LDA     #$00
        PHA
        PLB

        ACC16
        LDA     #$3C00
        TCD
        STA     CCT.B

        ; load FSMB
        LDA     #1
        STZ     LOADTRK.B
        STA     LOADSECT.B 
        LDA     #$0080
        STA     BANK.B
        LDX     #$9800
        JSR     LOADSECTOR.W

        LDA     $809800.L
        CMP     #$4C45
        BNE     BOOTERROR
        LDA     $809802.L
        CMP     #$5346
        BNE     BOOTERROR

        LDA     $80981A.L
        BEQ     BOOTERROR
        STA     CHUNK.B
        
        LDA     $809814.L
        ASL     A
        STA     SPT.B

        LDX     #$0000
-       JSR     LOADCHUNK.W
        JSR     NEXTCHUNK.W
        BNE     -
        
@ALLREAD:
        LDA     #$81
        PHA
        PLB

        AXY16
        LDA     $0000.W
        CMP     #$4F44
        BNE     BOOTERROR
        LDA     $0002.W
        CMP     #$2E53
        BNE     BOOTERROR
        JML     $810004.L

BOOTERROR:
        LDA     #$01
        STA     EINTGNRC.L
        SEI
        LDA     #$80
        PHA
        PLB
        LDA     #MESSAGE_DOSERROR.W
        JSL     TEXT_WRSTR.L
        ACC8
-       WAI
        JSL     KEYB_UPDKEYSI.L
        JSL     KEYB_GETKEY.L
        BEQ     -
        BCC     -
@SYSRESET:
        LDA     #$00
        STA     VPUCNTRL.L
        DEC     A
        STA     ESYSSTAT.L
        STP

.ACCU 16
PREADJUSTLOADSECTOR:
        SEC
        SBC     SPT.B
        STA     LOADSECT.B
        INC     LOADTRK.B
ADJUSTLOADSECTOR:
        LDA     LOADSECT.B
        CMP     SPT.B
        BCS     PREADJUSTLOADSECTOR
LOADSECTOR:
        STX     DMA1DST.W
        LDA     #$0200
        STA     DMA1CNT.W
        LDA     #$7000          ; from $70 to make sure it uses I/O
        ORA     BANK.B
        STA     DMA1BNKS.W
        LDA     #FLP1DATA.W
        STA     DMA1SRC.W
        
        LDA     LOADSECT.B
        STA     FLP1SECT.W      ; sector, track, side
        LDA     LOADTRK.B
        CMP     #80
        BCC     +
        CLC
        ADC     #48
+       STA     FLP1TRCK.W      ; to 0

        ACC8

        LDA     #$61
        STA     FLP1STAT.W      ; start seek & read
@SEEKLOOP:
        BIT     FLP1STAT.W
        BVS     BOOTERROR
        BPL     @SEEKLOOP

        LDA     #$94
        STA     DMA1CTRL.W      ; start read
@READLOOP:
        BIT     DMA1STAT.W
        BMI     @READLOOP

        ACC16
        RTS

LOADCHUNK:
        LDA     #$0081
        STA     BANK.B
        LDA     CHUNK.B
        DEC     A
        ASL     A
        CLC
        ADC     $809838.L
        STA     LOADSECT.B
        STZ     LOADTRK.B
        JSR     ADJUSTLOADSECTOR.W
        INC     LOADSECT.B
        TXA
        CLC
        ADC     #$0200
        TAX
        JSR     LOADSECTOR.W
        TXA
        CLC
        ADC     #$0200
        TAX
        RTS

NEXTCHUNK:
        LDA     CHUNK.B
        XBA
        AND     #$FF
        PHX
        CMP     CCT.B
        BEQ     +
        STA     CCT.B
        LDX     #$A000
        INC     A
        INC     A
        STA     LOADSECT.B
        STZ     LOADTRK.B
        LDA     #$0080
        STA     BANK.B
        JSR     ADJUSTLOADSECTOR.W
+       LDA     CHUNK.B
        AND     #$00FF
        ASL     A
        TAX
        LDA     $80A000.L,X
        PLX
        STA     CHUNK.B
        CMP     #$FFFF
        RTS

MESSAGE_DOSBOOTING:
        .DB     "Loading Ellipse DOS...",13,0
MESSAGE_DOSERROR:
        .DB     "Load error",13,"Press any key to reset",13,0
