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

.DEFINE DOSBOOTTMP $803C00
.DEFINE DOSBOOTTMP2 $803C02

BOOTLOAD:
        SEI
        LDA     #0
        STA     DOSBOOTTMP.L

        LDA     #MESSAGE_DOSBOOTING.w
        LDX     #0
        LDY     #0
        JSL     TEXT_WRSTRAT

; read 64 KB DOS.SYS to bank $81
@GOT_FLOPPY:
        ACC8
        LDA     #$00
        PHA
        PLB

        LDA     #$0080
        STA     DOSBOOTTMP2.L

        AXY8
        LDY     #10
        LDX     #0
        BRA     @SECTORLOOP
@TRACKLOOP:
        LDY     #0
@SECTORLOOP:
        ACC16
        LDA     #$0200
        STA     DMA0CNT
        LDA     #$7081          ; from $70 to make sure it uses I/O
        STA     DMA0BNKS
        LDA     #FLP1DATA.W
        STA     DMA0SRC
        LDA     DOSBOOTTMP.L
        STA     DMA0DST
        ACC8

        STY     FLP1SECT        ; sector, track, side
        STX     FLP1TRCK        ; to 0
        LDA     #$61
        STA     FLP1STAT        ; start seek & read
@SEEKLOOP:
        BIT     FLP1STAT
        BVS     @BOOTERROR
        BPL     @SEEKLOOP

@SEEKDONE:
        ; read with DMA
        LDA     #$94
        STA     DMA0CTRL
-       BIT     FLP1STAT
        BVS     @BOOTERROR
        BIT     DMA0STAT
        BMI     -

        ACC16
        LDA     DOSBOOTTMP.L
        CLC
        ADC     #$0200
        STA     DOSBOOTTMP.L
        ACC8

        LDA     DOSBOOTTMP2.L
        DEC     A
        STA     DOSBOOTTMP2.L
        BEQ     @ALLREAD
        INY
        CPY     #16
        BCC     @SECTORLOOP
        INX
        BRA     @TRACKLOOP
        
@ALLREAD:
        LDA     #$81
        PHA
        PLB

        AXY16
        LDA     $0000.W
        CMP     #$4F44
        BNE     @BOOTERROR
        LDA     $0002.W
        CMP     #$2E53
        BNE     @BOOTERROR
        JML     $810004.L

@BOOTERROR:
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
        LDA     #$FF
        STA     ESYSSTAT.L
        STP

MESSAGE_DOSBOOTING:
        .DB     "Loading Ellipse DOS...",13,0
MESSAGE_DOSERROR:
        .DB     "Load error",13,"Press any key to reset",13,0
