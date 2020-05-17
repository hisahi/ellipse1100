; Ellipse Workstation 1100 (fictitious computer)
; ROM code (top-level)
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


.INCLUDE "e1100.asm"

.DEFINE _DEBUG 1

.MEMORYMAP
SLOTSIZE $10000
DEFAULTSLOT 0
SLOT 0 $0000
SLOT 1 $0000
SLOT 2 $0000
SLOT 3 $0000
SLOT 4 $0000
SLOT 5 $0000
SLOT 6 $0000
SLOT 7 $0000
.ENDME

.ROMBANKMAP
BANKSTOTAL 8
BANKSIZE $10000
BANKS 8
.ENDRO

.BANK 0 .SLOT 0

.ORGA $000000           ; DATA
NOTICE_START:
        .DB     "(C) ELLIPSE DATA ELECTRONICS.   1984/1985 v0.1.0"
        .DB     0
ROM_VERSION:
        .DW     $0100
NOTICE_END:
.ORGA $000040
DTA_PALETTE_START:
        .INCBIN "palette.bin"   ; DEFAULT PALETTE
DTA_PALETTE_END:
PIC_LOGO_START:
        .INCBIN "logo.bin"      ; BOOT LOGO "ELLIPSE" TEXT
PIC_LOGO_END:
PIC_LOGOI_START:
        .INCBIN "logoi.bin"     ; BOOT LOGO "ELLIPSE LOGO"
PIC_LOGOI_END:
PIC_FLOPPY_START:
        .INCBIN "floppy.bin"    ; "INSERT FLOPPY" LOGO
PIC_FLOPPY_END:

.ORGA $008000           ; CODE must start at $008000
ROMCODE:
        .INCLUDE "boot.asm"
        .INCLUDE "vec.asm"
        .INCLUDE "ints.asm"
        .INCLUDE "keytbls.asm"

.ORGA $00FFE4           ; NATIVE MODE INTERRUPT HANDLERS
        .DW INTH_COP            ; COP
        .DW INTH_BRK            ; BRK
        .DW INTH_ABORT          ; ABORT
        .DW INTH_NMI            ; NMI
        .DW ROMCODE             ; -
        .DW INTH_IRQ            ; IRQ

.ORGA $00FFF0           ; ROM CALL VECTOR;      JSL $00FFF0
        JML ROMVEC              ; 
.ORGA $00FFF4           ; EMULATION MODE INTERRUPT HANDLERS
        .DW INTH_E_COP          ; COP
        .DW INTH_E_BRK          ; BRK
        .DW INTH_E_ABORT        ; ABORT
        .DW INTH_E_NMI          ; NMI
        .DW ROMCODE             ; RESET
        .DW INTH_E_IRQ          ; IRQ

.BANK 1 .SLOT 1

.ORG $000000            ; FIXED-WIDTH TEXT, KEYBOARD, ML MONITOR

FIXFONT_START:
        .INCBIN "fixfont.bin"
FIXFONT_END:
        .INCLUDE "fixtext.asm"
        .INCLUDE "keyboard.asm"
        .INCLUDE "monitor.asm"
        
.BANK 2 .SLOT 2

.ORG $000000            ; ELLIPSE DOS



