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

.DEFINE BOOT_BACKGROUND_COLOR $55
.DEFINE BOOT_DISK_MSG_X 26
.DEFINE BOOT_DISK_MSG_Y 28
.DEFINE COPYRIGHT_MSG_X 16
.DEFINE COPYRIGHT_MSG_Y 46

        SEI
        CLD
        CLC                     ; \ enter native mode 
        XCE                     ; / starting with 8-bit A, X, Y
        AXY16
        JSR     CHECKSUM

ALMOSTRESET:
        XY16
        ACC8

        LDA     #$00.B
        PHA
        PLB                     ; B = 0

        AXY16
        LDA     #$0000
        TCD                     ; D = 0
        LDA     #$03FF
        TCS                     ; S to $03FF

        ACC8
; reset HW registers
        STZ     EINTGNRC.W      ; disable interrupts
        STZ     DMA0CTRL.W      ; reset DMA #0-#3
        STZ     DMA1CTRL.W
        STZ     DMA2CTRL.W
        STZ     DMA3CTRL.W
        LDA     #%01000000      ; reset floppy drives
        STA     FLP1STAT.W
        STA     FLP2STAT.W
        ACC16

; copy palette to VRAM using DMA0
        LDA     #$0043          ; from bank $00 to $43
        STA     DMA0BNKS.W
        LDX     #DTA_PALETTE_START
        STX     DMA0SRC.W
        STZ     DMA0DST.W
        LDA     #(DTA_PALETTE_END - DTA_PALETTE_START)
        STA     DMA0CNT.W
        ACC8
        LDA     #$0091          ; enable DMA & IRQ when over; we will WAI
        STA     DMA0CTRL.W
-       BIT     DMA0STAT.W
        BMI     -

        LDA     #$02.B
        STA     VPUCNTRL.W
        LDA     #BOOT_BACKGROUND_COLOR.B
        JSR     FAST_SCREEN_FILL.W

; set up interrupt trampolines
        LDA     #$80.B          ; RAM bank #$80
        PHA
        PLB
        
        ; set text mode background color background color
        LDA     #BOOT_BACKGROUND_COLOR.b
        STA     $FFFF&TEXT_BGCOLOR.w

        LDA     #$5C.B          ; JML $BBHHLL
        STA     $FFFF&(SWRAMCOP-1).w
        STA     $FFFF&(SWRAMBRK-1).w
        STA     $FFFF&(SWRAMNMI-1).w
        STA     $FFFF&(SWRAMIRQ-1).w
        ; default setting to bank 0
        STZ     $FFFF&(SWRAMCOP+2).w
        STZ     $FFFF&(SWRAMBRK+2).w
        STZ     $FFFF&(SWRAMNMI+2).w
        STZ     $FFFF&(SWRAMIRQ+2).w

        AXY16
; set up interrupt trampolies to INTH_RET
        LDA     #INTH_RET.w
        STA     $FFFF&SWRAMCOP.w
        STA     $FFFF&SWRAMBRK.w
        STA     $FFFF&SWRAMNMI.w
        STA     $FFFF&SWRAMIRQ.w

        STZ     IN_SWAPBRK.W
        STZ     IN_SWAPIRQ.W
        STZ     IN_SWAPNMI.W
        STZ     TEXT_CURSORON.W

        ACC8
        ; set text mode background color foreground to $7F
        LDA     #$7F
        STA     $FFFF&TEXT_FGCOLOR.w

        LDA     #$00.B
        PHA
        PLB                     ; B = 0

        AXY16
        STZ     FLP1SECT.W      ; sector, track, side all to 0

; copy ELLIPSE text logo to screen
        LDX     #42
        LDA     #PIC_LOGO_START.w
        STA     DMA0SRC.W       ; copy from logo image in ROM
        LDY     #$3080          ; ...    to $41:3080
        STY     DMA0DST.W
        LDA     #$0041          ; bank setup
        STA     DMA0BNKS.W
@LOGOLOOP:
        LDA     #$0100
        STA     DMA0CNT.W       ; copy total of 256 bytes
        LDA     #$0091          ; enable DMA & IRQ when over; we will WAI
        STA     DMA0CTRL.W
        WAI                     ; wait until end of DMA
        TYA
        CLC     
        ADC     #$0200          ; make sure we start on the same X coordinate
        STA     DMA0DST
        TAY
        DEX
        BNE     @LOGOLOOP

; copy ELLIPSE image logo to screen
        LDX     #96
        LDA     #PIC_LOGOI_START
        STA     DMA0SRC.W       ; copy from logo image in ROM
        LDY     #$40D0          ; ...    to $40:40D0
        STY     DMA0DST.W
        LDA     #$0040          ; bank setup
        STA     DMA0BNKS.W
@LOGOILOOP:
        LDA     #$0060
        STA     DMA0CNT.W       ; copy total of 96 bytes
        LDA     #$0091          ; enable DMA & IRQ when over; we will WAI
        STA     DMA0CTRL.W
        WAI                     ; wait until end of DMA
        TYA
        CLC     
        ADC     #$0200          ; make sure we start on the same X coordinate
        STA     DMA0DST
        TAY
        DEX
        BNE     @LOGOILOOP

; copy copyright message to RAM
        STZ     DMA0SRC.W       ; copy from logo image in ROM
        STZ     DMA0DST.W
        LDA     #$0080          ; bank setup
        STA     DMA0BNKS.W
        LDA     #$0031
        STA     DMA0CNT.W       ; copy total of 49 bytes
        LDA     #$0091          ; enable DMA & IRQ when over; we will WAI
        STA     DMA0CTRL.W
        WAI                     ; wait until end of DMA

; write copyright message to screen
        ACC8
        PHB
        LDA     #$80
        PHA
        PLB
        ACC16
        LDX     #COPYRIGHT_MSG_X
        LDY     #COPYRIGHT_MSG_Y
        LDA     #$0000
        JSL     TEXT_WRSTRAT
        PLB

.IF _DEBUG != 0
        LDX     #COPYRIGHT_MSG_X
        LDY     #25
        LDA     #MESSAGE_DEBUG
        JSL     TEXT_WRSTRAT
.ENDIF

; write menu message to screen
        LDA     #MESSAGE_OPENMENU.w
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #1+BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTRAT

.IF _DEBUG != 0
        ; development build; skip waiting period
        BRA     @SKIPWAIT
.ENDIF

@SECOND_WAIT:
; wait for about a second
        ; enable VPU v-sync NMI
        ACC8
        LDA     VPUCNTRL.W
        ORA     #$04
        STA     VPUCNTRL.W
        ACC16
        LDX     #80
-       WAI
        DEX
        BNE     -
        ; disable VPU v-sync NMI
        ACC8
        LDA     VPUCNTRL.W
        AND     #$FB
        STA     VPUCNTRL.W

@SKIPWAIT:     
        ACC8

; enable keyboard interrupt
        LDA     #$01
        STA     EINTGNRC.W

        JSL     KEYB_UPDKEYS
        JSL     KEYB_GETMODS
        AND     #$10
        BNE     BIOS_MENU

; set up floppy drive I to do IRQs
        LDA     #%01100000      ; enable IRQ
        STA     FLP1STAT

FIRSTFLOPPYCHECK:
        JSR     CHECK_FLOPPY_DISK
        BEQ     +
        JMP     GOT_FLOPPY
+
; copy "insert floppy" image to screen
        PHP
        AXY16
        LDA     #MESSAGE_INSERTDISK.w
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTRAT

        LDX     #96
        LDA     #PIC_FLOPPY_START.W
        STA     DMA0SRC.W       ; copy from floppy image in ROM
        LDY     #$04DE          ; ...    to $42:04DE
        STY     DMA0DST.W
        LDA     #$0042          ; bank setup
        STA     DMA0BNKS.W
@FLOPPYLOOP:
        LDA     #96
        STA     DMA0CNT.W       ; copy total of 64 bytes
        ACC8
        LDA     #$0091          ; enable DMA & IRQ when over; we will WAI
        STA     DMA0CTRL.W
-       BIT     DMA0STAT.W      ; wait until end of DMA
        BMI     -
        ACC16
        TYA
        CLC     
        ADC     #$0200          ; make sure we start on the same X coordinate
        STA     DMA0DST
        TAY
        DEX
        BNE     @FLOPPYLOOP
        PLP
        
        JSL     KEYB_RESETBUF
        ACC8
WAIT_FLOPPY_LOOP:
        JSL     KEYB_UPDKEYS
        JSL     KEYB_GETMODS
        AND     #$10
        BNE     BIOS_MENU

        JSR     CHECK_FLOPPY_DISK
        BNE     GOT_FLOPPY
@IRQWAI:
        WAI
        BRA     WAIT_FLOPPY_LOOP

BIOS_MENU:
        ACC8
        LDA     #0              ; disable floppy IRQ
        STA     FLP1STAT
        STA     TEXT_BGCOLOR.L
        XY16
        JSR     FAST_SCREEN_FILL.W
        
        CLC
        JSL     TEXT_CLRSCR.L

        ACC8
        PHB
        LDA     #$08
        PHA
        PLB

        ACC16
        LDX     #COPYRIGHT_MSG_X
        LDY     #4
        LDA     #$0000
        JSL     TEXT_WRSTRAT
        PLB

.IF _DEBUG != 0
        LDX     #COPYRIGHT_MSG_X
        LDY     #5
        LDA     #MESSAGE_DEBUG.W
        JSL     TEXT_WRSTRAT
.ENDIF
        LDA     #MESSAGE_MENU_CHECKSUM.W
        LDX     #54
        LDY     #6
        JSL     TEXT_WRSTRAT

        LDA     $07FFFE.L
        JSL     WRITE_HEX_WORD

        LDA     #MESSAGE_MENU.w
        LDX     #0
        LDY     #6
        JSL     TEXT_WRSTRAT

        JMP     BIOS_MENU_LOOP

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
        JSL     TEXT_WRSTRAT
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
        JSL     TEXT_WRSTRAT
        ACC8
        JMP     WAIT_FLOPPY_LOOP@IRQWAI
GOT_FLOPPY_NOBOOT:
        ACC16
        LDA     #MESSAGE_DISKNONBOOTABLE.w
        LDX     #BOOT_DISK_MSG_X.w
        LDY     #BOOT_DISK_MSG_Y.w
        JSL     TEXT_WRSTRAT
        ACC8
        JMP     WAIT_FLOPPY_LOOP@IRQWAI

GOT_FLOPPY_CHECK_BOOT:
.ACCU 16
        LDA     $800000.L
        CMP     #$4C45.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800002.L
        CMP     #$494C.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800004.L
        CMP     #$5350.W
        BNE     GOT_FLOPPY_NOBOOT
        LDA     $800006.L
        CMP     #$4045.W
        BNE     GOT_FLOPPY_NOBOOT

@IS_BOOTABLE:
        SEI
        ACC8
        ;       set text mode background color to $00
        LDA     #$00
        STA     TEXT_BGCOLOR.L
        
        ; disable many hardware interrupts
        STA     EINTGNRC.L

        ;       clear text mode VRAM
        CLC
        JSL     TEXT_CLRBUF
        LDA     #$0000
        ;       clear the entire screen
        ACC8
        JSR     FAST_SCREEN_FILL
        JSL     KEYB_RESETBUF
        
        ACC8
        LDA     #$80
        PHA
        PLB

        AXY16
        LDA     #$0000
        TCD
        LDA     #$03FF.w
        TCS                     ; S to $03FF
        JML     $800008
        STP

BIOS_MENU_LOOP:
        ACC8
        JSL     KEYB_UPDKEYS
        JSL     KEYB_GETKEY
        BEQ     +
        BCC     +
        CMP     #$10
        BEQ     BIOS_MENU_REBOOT
        BIT     $0F44.W
        BMI     BIOS_MENU_MONITOR
+       WAI
        BRA     BIOS_MENU_LOOP

BIOS_MENU_REBOOT:
        ACC8
        CLC
        JSL     TEXT_CLRBUF
        JMP     ALMOSTRESET

BIOS_MENU_MONITOR:
        JSL     MLMONITOR.L
        CLC
        JSL     TEXT_CLRBUF
        JMP     ALMOSTRESET

CHECK_FLOPPY_DISK:
        LDA     FLP1STAT.W
        AND     #%00011100.B
        RTS

FAST_SCREEN_FILL:               ; assumes 8-bit A, 16-bit X, Y
        ACC8
        STA     $80102A.L
        PHP
        CLD
        SEI                     ; disable interrupts
        AXY16
        LDX     #$0003
        LDA     #$102A
        STA     DMA0SRC.W       ; copy from $80:102A
        STZ     DMA0DST.W       ;        to $40:0000
        LDY     #$8040          ; bank setup
@FSLOOP:
        STY     DMA0BNKS.W
        STZ     DMA0CNT.W       ; copy total of 64K bytes
        LDA     #$0094          ; enable DMA
        STA     DMA0CTRL.W      ; fixed SRC address, changing DST address
-       BIT     DMA0CTRL.W      ; wait until end of DMA
        BMI     -
        INY                     ; increase target bank
        DEX
        BNE     @FSLOOP
        PLP
        RTS

.DEFINE CHECKSUM_MINBANK $08
.DEFINE CHECKSUM_MAXBANK $0F
.ACCU 16
.INDEX 16
CHECKSUM:
        LDA     #0
        LDX     #0
-       
.REPEAT CHECKSUM_MAXBANK-CHECKSUM_MINBANK+1 INDEX BINDEX
        CLC
        ADC     (CHECKSUM_MINBANK+BINDEX)<<16.L,X
.ENDR
        INX
        INX
        BNE     -
        CMP     #0
        BNE     CHECKSUM_FAIL
        RTS
CHECKSUM_FAIL:                  ; this is bad, display red screen
        ACC8
        LDA     #$02.B
        STA     VPUCNTRL.W
        LDA     #00
        JSR     FAST_SCREEN_FILL
        AXY16
        LDA     #$1F00
        STA     $430000.L
        STP

WRITE_HEX_BYTE:
        PHA
        
        AND     #$F0
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        TAX
        LDA     TEXT_HEXDIGITS.L,X
        JSL     TEXT_WRCHR

        LDA     1,S
        
        AND     #$0F
        TAX
        LDA     TEXT_HEXDIGITS.L,X
        JSL     TEXT_WRCHR

        PLA
        RTL

WRITE_HEX_BYTE8:
.ACCU 8
        PHA
        XBA
        LDA     #0
        XBA
        
        AND     #$F0
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        TAX
        LDA     TEXT_HEXDIGITS.L,X
        JSL     TEXT_WRCHR

        LDA     1,S
        
        AND     #$0F
        TAX
        LDA     TEXT_HEXDIGITS.L,X
        JSL     TEXT_WRCHR

        PLA
        RTL

WRITE_HEX_WORD:
        XBA
        JSL     WRITE_HEX_BYTE
        XBA
        JMP     WRITE_HEX_BYTE

TEXT_HEXDIGITS:
        .DB     "0123456789ABCDEF"
.IF _DEBUG != 0
MESSAGE_DEBUG:
        .DB     "FOR TESTING PURPOSES ONLY",0
.ENDIF
MESSAGE_BLANK:
        .DB     "                            ",0
MESSAGE_INSERTDISK:
        .DB     "INSERT BOOT DISK IN DRIVE #1",0
MESSAGE_DISKNONBOOTABLE:
        .DB     "INSERT BOOT DISK IN DRIVE #1",0
MESSAGE_OPENMENU:
        .DB     "       -ALT- FOR MENU       ",0
MESSAGE_DISKNOTVALID:
        .DB     "         DISK ERROR         ",0

MESSAGE_MENU_CHECKSUM:
        .DB     "ROM CHECKSUM $",0
MESSAGE_MENU:
        .DB     "    ","ELLIPSE 1100 MENU",13,13
        .DB     "    ","  -ESC-",9,9,"BOOT FROM FLOPPY",13
        .DB     13
        .DB     "    ","  -B-",9,9,"BASIC",13
        .DB     "    ","  -M-",9,9,"MONITOR",13
.IF _DEBUG != 0
        .DB     13
        .DB     "    ","  -Q-",9,9,"RAM TEST",13
.ENDIF
        .DB     0
