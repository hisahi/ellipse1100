; Ellipse Workstation 1100 (fictitious computer)
; ROM code (initial boot)
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

.DEFINE BOOT_DISK_MSG_X 30
.DEFINE BOOT_DISK_MSG_Y 28
.DEFINE BOOT_BACKGROUND_COLOR $55

        SEI
        CLC                     ; \ enter native mode 
        XCE                     ; / starting with 8-bit A, X, Y
        LDA.b   #$00
        PHA
        PLB                     ; B = 0

        AXY16
        LDA.w   #$0000
        TCD                     ; D = 0
        LDA.w   #$03FF
        TCS                     ; S to $03FF

; copy palette to VRAM using DMA0
        LDA.w   #$0043          ; from bank $00 to $43
        STA.w   DMA0BNKS
        LDX.w   #DTA_PALETTE_START
        STX.w   DMA0SRC
        STZ.w   DMA0DST
        LDA.w   #(DTA_PALETTE_END - DTA_PALETTE_START)
        STA.w   DMA0CNT
        LDA.w   #$0091          ; enable DMA & IRQ when over; we will WAI
        STA.w   DMA0CTRL
        WAI                     ; wait until end of DMA

        ACC8
        LDA     #BOOT_BACKGROUND_COLOR.b
        JSR     FAST_SCREEN_FILL

; set up interrupt trampolines
        PHB
        LDA     #$80.b          ; RAM bank #$80
        PHA
        PLB
        
        ; set text mode background color background color
        LDA     #BOOT_BACKGROUND_COLOR.b
        STA     $FFFF&TEXT_BGCOLOR.w

        LDA     #$5C.b          ; JML $BBHHLL
        STA     $FFFF&(SWRAMCOP-1).w
        STA     $FFFF&(SWRAMBRK-1).w
        STA     $FFFF&(SWRAMNMI-1).w
        STA     $FFFF&(SWRAMIRQ-1).w
        ; default setting to bank 0
        STZ     $FFFF&(SWRAMCOP+2).w
        STZ     $FFFF&(SWRAMBRK+2).w
        STZ     $FFFF&(SWRAMNMI+2).w
        STZ     $FFFF&(SWRAMIRQ+2).w
        ; set text mode background color foreground to $7F
        LDA     #$7F
        STA     $FFFF&TEXT_FGCOLOR.w

        AXY16

; set up interrupt trampolies to INTH_RET (PLA; RTI in ROM)
        LDA     #INTH_RET.w
        STA     $FFFF&SWRAMCOP.w
        STA     $FFFF&SWRAMBRK.w
        STA     $FFFF&SWRAMNMI.w
        STA     $FFFF&SWRAMIRQ.w

        PLB                     ; restore ROM bank

; copy ELLIPSE logo to screen
        LDX     #42
        LDA     #PIC_LOGO_START
        STA.w   DMA0SRC         ; copy from logo image in ROM
        LDY.w   #$0080          ; ...    to $41:0080
        STY.w   DMA0DST
        LDA     #$0041          ; bank setup
        STA.w   DMA0BNKS
@LOGOLOOP:
        LDA.w   #$0100
        STA.w   DMA0CNT         ; copy total of 256 bytes
        LDA.w   #$0091          ; enable DMA & IRQ when over; we will WAI
        STA.w   DMA0CTRL
        WAI                     ; wait until end of DMA
        TYA
        CLC     
        ADC     #$0200          ; make sure we start on the same X coordinate
        STA     DMA0DST
        TAY
        DEX
        BNE     @LOGOLOOP

; set up floppy drive I to do IRQs
        STZ     FLP1SECT        ; sector, track, side all to 0
        ACC8                    ; make A 8-bit again
        LDA     #%01100000      ; enable IRQ
        STA     FLP1STAT

FIRSTFLOPPYCHECK:
        JSR     CHECK_FLOPPY_DISK
        BNE     GOT_FLOPPY

; copy "insert floppy" image to screen
        PHP
        AXY16
        LDA     #MESSAGE_INSERTDISK.w
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTR

        LDX     #96
        LDA     #PIC_FLOPPY_START
        STA.w   DMA0SRC         ; copy from floppy image in ROM
        LDY.w   #$04D0          ; ...    to $42:20C0
        STY.w   DMA0DST
        LDA     #$0042          ; bank setup
        STA.w   DMA0BNKS
@FLOPPYLOOP:
        LDA.w   #96
        STA.w   DMA0CNT         ; copy total of 64 bytes
        LDA.w   #$0091          ; enable DMA & IRQ when over; we will WAI
        STA.w   DMA0CTRL
        WAI                     ; wait until end of DMA
        TYA
        CLC     
        ADC     #$0200          ; make sure we start on the same X coordinate
        STA     DMA0DST
        TAY
        DEX
        BNE     @FLOPPYLOOP
        PLP

WAIT_FLOPPY_LOOP:
        JSR     CHECK_FLOPPY_DISK
        BNE     GOT_FLOPPY
@IRQWAI:
        WAI
        BRA     WAIT_FLOPPY_LOOP

GOT_FLOPPY:                     ; read first sector of floppy
.ACCU 8
        STZ     FLP1SECT        ; sector, track, side
        STZ     FLP1TRCK        ; to 0
        LDA     #$61
        STA     FLP1STAT        ; start seek & read

        ACC16
        LDA     #MESSAGE_BLANK.w
        LDX     #BOOT_DISK_MSG_X
        LDY     #BOOT_DISK_MSG_Y
        JSL     TEXT_WRSTR
        ACC8
@SEEKLOOP:
        BIT     FLP1STAT
        BVS     GOT_FLOPPY_ERR
        BPL     @SEEKLOOP

@SEEKDONE:
        ; read with DMA
        AXY16
        LDA     #FLP1DATA
        STA     DMA0SRC
        STZ     DMA0DST
        LDA     #$0200
        STA     DMA0CNT
        LDA     #$7080          ; from $70 to make sure it uses I/O
        STA     DMA0BNKS
        LDA     #$0095          ; turn on DMA & IRQ, fixed src address
        STA     DMA0CTRL
        ACC8
-       BIT     FLP1STAT
        BVS     GOT_FLOPPY_ERR
        BIT     DMA0STAT
        BMI     -

        AXY16
        BRA     GOT_FLOPPY_CHECK_BOOT

GOT_FLOPPY_ERR:
        ACC8
        LDA     FLP1DATA
        CMP     #2
        ACC16
        BEQ     @NODISK
        LDA     #MESSAGE_DISKNOTVALID.w
        BRA     @GENERIC
@NODISK:
        LDA     #MESSAGE_INSERTDISK.w
@GENERIC:
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTR
        ACC8
        JMP     WAIT_FLOPPY_LOOP@IRQWAI
GOT_FLOPPY_NOBOOT:
        ACC16
        LDA     #MESSAGE_DISKNONBOOTABLE.w
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTR
        ACC8
        JMP     WAIT_FLOPPY_LOOP@IRQWAI

GOT_FLOPPY_CHECK_BOOT:
.ACCU 16
        LDA     $800000
        CMP     #$4C45.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800002
        CMP     #$494C.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800004
        CMP     #$5350.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800006
        CMP     #$4045.W
        BNE     GOT_FLOPPY_NOBOOT

@IS_BOOTABLE:
        SEI
        ACC8
        ;       set text mode background color to $00
        LDA     #$00
        STA     TEXT_BGCOLOR.l
        ;       clear text mode VRAM

        ;       clear the entire screen
        JSL     TEXT_CLRBUF
        LDA     #$0000
        ACC8
        JSR     FAST_SCREEN_FILL
        
        ACC8
        LDA     #$80
        PHA
        PLB

        AXY16
        LDA     #$8000
        PHA
        PLD
        LDA     #$03FF.w
        TCS                     ; S to $03FF
        JML     $800008

CHECK_FLOPPY_DISK:
        LDA     FLP1STAT
        AND     #%00011100.b
        RTS

FAST_SCREEN_FILL:               ; assumes 8-bit A, 16-bit X, Y
        STA     $800000.l
        PHP
        CLD
        SEI                     ; disable interrupts
        AXY16
        LDX     #$0003
        STZ.w   DMA0SRC         ; copy from $80:0000
        STZ.w   DMA0DST         ;        to $40:0000
        LDY     #$8040          ; bank setup
@FSLOOP:
        STY.w   DMA0BNKS
        STZ.w   DMA0CNT         ; copy total of 64K bytes
        LDA.w   #$0094          ; enable DMA
        STA.w   DMA0CTRL        ; fixed SRC address, changing DST address
-       BIT     DMA0CTRL        ; wait until end of DMA
        BMI     -
        INY                     ; increase target bank
        DEX
        BNE     @FSLOOP
        PLP
        RTS

MESSAGE_BLANK:
        .DB     "                    ",0
MESSAGE_INSERTDISK:
        .DB     "  INSERT BOOT DISK  ",0
MESSAGE_DISKNONBOOTABLE:
        .DB     "  INSERT BOOT DISK  ",0
MESSAGE_DISKNOTVALID:
        .DB     "     DISK ERROR     ",0
