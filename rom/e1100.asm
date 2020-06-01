; Ellipse Workstation 1100 (fictitious computer)
; Header for memory mapped I/O addresses, etc.
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
;       .INCLUDE "e1100.asm"
;

; valid banks for I/O: $00 or $70-$7F

.DEFINE IOBANK   $700000 EXPORT
.DEFINE ESYSSTAT $7000 EXPORT
.DEFINE ESTKBANK $7001 EXPORT
.DEFINE EIDEVNUM $7002 EXPORT
.DEFINE ERAMBANK $7003 EXPORT
.DEFINE EINTGNRC $7004 EXPORT
.DEFINE KEYBMTRX $7010 EXPORT
.DEFINE FLP1STAT $7028 EXPORT
.DEFINE FLP1SECT $7029 EXPORT
.DEFINE FLP1TRCK $702A EXPORT
.DEFINE FLP1DATA $702B EXPORT
.DEFINE FLP2STAT $702C EXPORT
.DEFINE FLP2SECT $702D EXPORT
.DEFINE FLP2TRCK $702E EXPORT
.DEFINE FLP2DATA $702F EXPORT
.DEFINE VPUCNTRL $7030 EXPORT
.DEFINE DMA0CTRL $7040 EXPORT
.DEFINE DMA0STAT $7041 EXPORT
.DEFINE DMA0CCNT $7042 EXPORT
.DEFINE DMA0BNKS $7048 EXPORT
.DEFINE DMA0CNT  $704A EXPORT
.DEFINE DMA0DST  $704C EXPORT
.DEFINE DMA0SRC  $704E EXPORT
.DEFINE DMA1CTRL $7050 EXPORT
.DEFINE DMA1STAT $7051 EXPORT
.DEFINE DMA1CCNT $7052 EXPORT
.DEFINE DMA1BNKS $7058 EXPORT
.DEFINE DMA1CNT  $705A EXPORT
.DEFINE DMA1DST  $705C EXPORT
.DEFINE DMA1SRC  $705E EXPORT
.DEFINE DMA2CTRL $7060 EXPORT
.DEFINE DMA2STAT $7061 EXPORT
.DEFINE DMA2CCNT $7062 EXPORT
.DEFINE DMA2BNKS $7068 EXPORT
.DEFINE DMA2CNT  $706A EXPORT
.DEFINE DMA2DST  $706C EXPORT
.DEFINE DMA2SRC  $706E EXPORT
.DEFINE DMA3CTRL $7070 EXPORT
.DEFINE DMA3STAT $7071 EXPORT
.DEFINE DMA3CCNT $7072 EXPORT
.DEFINE DMA3BNKS $7078 EXPORT
.DEFINE DMA3CNT  $707A EXPORT
.DEFINE DMA3DST  $707C EXPORT
.DEFINE DMA3SRC  $707E EXPORT

; text mode renderer memory & jump vectors
; DMA0 is reserved for text mode

.DEFINE TEXT_BGCOLOR $801080
.DEFINE TEXT_FGCOLOR $801082

.DEFINE TEXT_MVCURX $013FDC
.DEFINE TEXT_UPDCHR $013FE0
.DEFINE TEXT_FLASHCUR $013FE4
.DEFINE TEXT_CLRBUF $013FE8
.DEFINE TEXT_CLRSCR $013FEC
.DEFINE TEXT_WRSTRAT $013FF0
.DEFINE TEXT_WRCHR $013FF4
.DEFINE TEXT_WRSTR $013FF8
.DEFINE TEXT_MVCUR $013FFC

.DEFINE KEYB_GETMODS $017FE8
.DEFINE KEYB_INCTIMER $017FEC
.DEFINE KEYB_UPDKEYSI $017FF0
.DEFINE KEYB_GETKEY $017FF4
.DEFINE KEYB_RESETBUF $017FF8
.DEFINE KEYB_UPDKEYS $017FFC

.DEFINE ROM_SWAPBRK $00FC00.L
.DEFINE ROM_SWAPNMI $00FD00.L
.DEFINE ROM_SWAPIRQ $00FE00.L

.DEFINE ROM_UNSWAPBRK $00FCC0.L
.DEFINE ROM_UNSWAPNMI $00FDC0.L
.DEFINE ROM_UNSWAPIRQ $00FEC0.L

; addresses to software-configurable interrupt handlers
.DEFINE SWRAMCOP $80FFF1 EXPORT
.DEFINE SWRAMBRK $80FFF5 EXPORT
.DEFINE SWRAMIRQ $80FFF9 EXPORT
.DEFINE SWRAMNMI $80FFFD EXPORT

; helper macros

.MACRO ACC8             ; set A to be 8b
        SEP     #$20
.ENDM
.MACRO ACC16            ; set A to be 16b
        REP     #$20
.ENDM
.MACRO XY8              ; set X,Y to be 8b
        SEP     #$10
.ENDM
.MACRO XY16             ; set X,Y to be 16b
        REP     #$10
.ENDM
.MACRO AXY8             ; set A,X,Y to be 8b
        SEP     #$30
.ENDM
.MACRO AXY16            ; set A,X,Y to be 16b
        REP     #$30
.ENDM

.MACRO SETB8            ; set A to 8b and copy value to B; clobbers A
        ACC8
        LDA     #\1
        PHA
        PLB
.ENDM

.MACRO SETB16           ; set A to 16b and copy value to B; clobbers A
        SETB8   \1
        ACC16
.ENDM

.MACRO SETBD8           ; set A to 8b and copy values to B and D; clobbers A
        ACC16
        LDA     #\2
        PHA
        PLD
        ACC8
        LDA     #\1
        PHA
        PLB
.ENDM

.MACRO SETBD16          ; set A to 16b and copy values to B and D; clobbers A
        ACC8
        LDA     #\1
        PHA
        PLB
        ACC16
        LDA     #\2
        PHA
        PLD
.ENDM

.MACRO DOSCALL
        JSL     $810000
.ENDM
