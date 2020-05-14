; Ellipse Workstation 1100 (fictitious computer)
; ROM code (fixed-width text code)
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
; DMA0 is reserved for text mode

.DEFINE TEXT_TMP1 $1000
.DEFINE TEXT_TMP2 $1002
.DEFINE TEXT_TMP3 $1004
.DEFINE TEXT_TMP4 $1006
.DEFINE TEXT_TMP5 $80100A
.DEFINE TEXT_TMP6 $100C
.DEFINE TEXT_TMP7 $100E
.DEFINE TEXT_BGCOLOR_D $80
; characters
.DEFINE TEXT_VRAM_CH $1100
; colors
.DEFINE TEXT_VRAM_CL $2000

.MACRO ENTERTEXTRAM
        PHB
        PHD
        ACC8
        LDA     #$80
        PHA
        PLB
        ACC16
        LDA     #$1000
        TCD
.ENDM

.MACRO EXITTEXTRAM
        PLD
        PLB
.ENDM

.MACRO X_Y_TO_TEXT_VRAM_OFFSET
        ;       A = X * Y + 80
        STX     TEXT_TMP2.W
        TYA
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        STA     TEXT_TMP1.W
        ASL     A
        ASL     A
        CLC
        ADC     TEXT_TMP1.W
        CLC
        ADC     TEXT_TMP2.W
        TAX
.ENDM

.ACCU 16
TEXT_UPDATE_CHARACTER_RAW:
        ; A = X + Y * 80
        X_Y_TO_TEXT_VRAM_OFFSET

TEXT_UPDATE_CHARACTER_KNOWN_OFFSET:
; load font data
        LDA     TEXT_VRAM_CH,X
        AND     #$FF.w
        ASL     A
        ASL     A
        ASL     A
        STA     TEXT_TMP7.W
        LDA     TEXT_VRAM_CL,X
        STA     TEXT_TMP1.W

; now use x,y values to compute target screen address and store it to
;     TEXT_TMP3 (address), TEXT_TMP4 (bank)
        LDA     TEXT_TMP2.W             ; X coordinate
        ASL     A                       ; A = A * 6
        STA     TEXT_TMP4.W
        ASL     A
        CLC
        ADC     TEXT_TMP4.W
        CLC
        ADC     #16
        STA     TEXT_TMP3.W
        TYA                             ; Y coordinate
        LSR     A                       ; A = (A >> 4) & 3
        LSR     A
        LSR     A
        LSR     A
        AND     #3
        ORA     #$40
        STA     TEXT_TMP4.W
        TYA                             ; Y coordinate
        AND     #$0F                    ; A = (A & 0x0F) << 12
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        XBA    
        CLC
        ADC     TEXT_TMP3.W             ; A += (X << 3 + 16)
        STA     TEXT_TMP3.W

        TAY
        LDX     TEXT_TMP7.W
; X contains address to character bitmap (low byte)
; Y is target location in graphics VRAM
; A is clobbered
TEXT_DRAW_CHARACTER:
        ACC8
        LDA     TEXT_BGCOLOR_D.B
        PHA
        LDA     TEXT_TMP1.B
        PHA
; switch data bank to destination VRAM bank
        PHB
        LDA     TEXT_TMP4.W
        PHA
        PLB
.REPEAT 8
        ACC8
        LDA     ($010000|FIXFONT_START).L,X
        XBA
.REPEAT 6
        LDA     3,S
        XBA
        ASL     A
        BCC     +
        XBA
        LDA     2,S
        .DB     $89     ; skip next XBA      
+       XBA
        STA     $0000.W,Y
        INY
.ENDR
        INX
        ACC16
        TYA
        CLC
        ADC     #$0200-6
        TAY
.ENDR
@ENDCHAR:
        PLB
        PLA
        RTS
        
; X, Y are coordinates
; clobbers A, X, Y
TEXT_UPDATE_CHARACTER:
        PHP
        AXY16
        ENTERTEXTRAM
        JSR     TEXT_UPDATE_CHARACTER
        EXITTEXTRAM
        PLP
        RTS

; clobbers A
TEXT_CLEAR_BUFFER:
        PHP
        AXY16
        CLD
        ENTERTEXTRAM
        STZ     TEXT_TMP1.w
; set up DMA to clear screen
        SEI                     ; disable interrupts
        LDX     #$0003
        LDA     #TEXT_TMP1.w
        STA.w   DMA0SRC         ; copy from TEXT_TMP1
        LDA     #TEXT_VRAM_CH.w
        STA.w   DMA0DST         ;        to TEXT_VRAM
        LDA     #$8080.w        ; bank setup
        STA.w   DMA0BNKS
        LDA     #$1E00.w        ; copy total of $1E00 bytes
        STA.w   DMA0CNT
        ACC8
        LDA     #$94.b          ; enable DMA
        STA     DMA0CTRL        ; fixed SRC address, changing DST address
-       BIT     DMA0STAT
        BMI     -
        EXITTEXTRAM
        PLP
        RTS

TEXT_CLEAR_SCREEN:
        JSR     TEXT_CLEAR_BUFFER
; clobbers A, X, Y
TEXT_UPDATE_ENTIRE_SCREEN:
        PHP
        ENTERTEXTRAM
@NOPHP:
        AXY16
        LDY     #48
        STY     TEXT_TMP6.W
@YLOOP:
        DEC     TEXT_TMP6.W
        LDX     #80
@XLOOP:
        DEX
        PHX
        LDY     TEXT_TMP6.W
        JSR     TEXT_UPDATE_CHARACTER_RAW
        PLX
        BNE     @XLOOP
        LDY     TEXT_TMP6.W
        BNE     @YLOOP
        EXITTEXTRAM
        PLP
        RTS

; X, Y = coordinates
; A = character to write
; A, X, Y clobbered
;       B must be $80
TEXT_WRITE_CHARACTER:
        STA     TEXT_TMP6.W
@NOSTA:
        ACC16
        X_Y_TO_TEXT_VRAM_OFFSET
        ACC8
        LDA     TEXT_TMP6.W
        STA     $800000|TEXT_VRAM_CH,X
        LDA     TEXT_FGCOLOR.W
        STA     $800000|TEXT_VRAM_CL,X
        ACC16
        JMP     TEXT_UPDATE_CHARACTER_KNOWN_OFFSET
        ;       leaves with ACC16
        
; X, Y = coordinates
; B:A = pointer to text, must end in 0
; A, X, Y preserved
TEXT_WRITE_STRING:
        PHP
        CLD
        ACC16
        PHA
@NEXTCHAR:
        PHY
        PHX
        STA     TEXT_TMP5.L
        ACC8
        TAX
        LDA     0.W,X
        BEQ     @END
        STA     TEXT_TMP6.W
        PLX
        PHX
@ENTERWCH:
        ENTERTEXTRAM
        JSR     TEXT_WRITE_CHARACTER@NOSTA
        EXITTEXTRAM
@EXITWCH:
.ACCU 16
        PLX
        PLY
        INX
        CPX     #80
        BCC     @NONEWLINE
        LDX     #0
        INY
@NONEWLINE:
        LDA     TEXT_TMP5.L
        INC     A
        BRA     @NEXTCHAR
@END:
        ACC16
        PLY
        PLX
        PLA
        PLP
        RTS

.ORG $FFE8
TEXT_CLEAR_BUFFER_TRAMPOLINE:
        JSR     TEXT_CLEAR_BUFFER.w
        RTL
.ORG $FFEC
TEXT_CLEAR_SCREEN_TRAMPOLINE:
        JSR     TEXT_CLEAR_SCREEN.w
        RTL
.ORG $FFF0
TEXT_WRITE_STRING_TRAMPOLINE:
        JSR     TEXT_WRITE_STRING.w
        RTL

