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
.DEFINE TEXT_TMP6L $80100C
.DEFINE TEXT_TMP7 $100E
.DEFINE TEXT_BGCOLOR_D $80
.DEFINE TEXT_CURSORX $1010
.DEFINE TEXT_CURSORY $1012
.DEFINE TEXT_CURSORXL $801010
.DEFINE TEXT_CURSORYL $801012
.DEFINE TEXT_CURSORTICKS $1014
.DEFINE TEXT_CURSORON $1016
.DEFINE TEXT_CURSORMOVED $1018
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

.MACRO ENTERTEXTRAM8
        PHB
        PHD
        ACC16
        LDA     #$1000
        TCD
        ACC8
        LDA     #$80
        PHA
        PLB
.ENDM

.MACRO EXITTEXTRAM
        PLD
        PLB
.ENDM

.MACRO X_Y_TO_TEXT_VRAM_OFFSET
        ;       A = X * Y + 80
        STX     $FF&TEXT_TMP2.B
        TYA
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        STA     $FF&TEXT_TMP1.B
        ASL     A
        ASL     A
        CLC
        ADC     $FF&TEXT_TMP1.B
        CLC
        ADC     $FF&TEXT_TMP2.B
        TAX
.ENDM

.MACRO A_Y_TO_VIDEO_VRAM_OFFSET
        ASL     A                       ; A = A * 6
        STA     $FF&TEXT_TMP4.B
        ASL     A
        CLC
        ADC     $FF&TEXT_TMP4.B
        CLC
        ADC     #16
        STA     $FF&TEXT_TMP3.B
        TYA                             ; Y coordinate
        LSR     A                       ; A = (A >> 4) & 3
        LSR     A
        LSR     A
        LSR     A
        AND     #3
        ORA     #$40
        STA     $FF&TEXT_TMP4.B
        TYA                             ; Y coordinate
        AND     #$0F                    ; A = (A & 0x0F) << 12
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        XBA    
        CLC
        ADC     $FF&TEXT_TMP3.B         ; A += (X << 3 + 16)
        STA     $FF&TEXT_TMP3.B
.ENDM

.ACCU 16
TEXT_UPDATE_CHARACTER_AT_CURSOR:
        LDX     $FF&TEXT_CURSORX.B
        LDY     $FF&TEXT_CURSORY.B
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
        STA     $FF&TEXT_TMP7.B
        LDA     TEXT_VRAM_CL,X
        STA     $FF&TEXT_TMP1.B

; now use x,y values to compute target screen address and store it to
;     TEXT_TMP3 (address), TEXT_TMP4 (bank)
        LDA     $FF&TEXT_TMP2.B          ; X coordinate
        A_Y_TO_VIDEO_VRAM_OFFSET

TEXT_UPDATE_CHARACTER_KNOWN_VRAM_ADDR:
        TAY
        LDX     $FF&TEXT_TMP7.B
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
        LDA     $FF&TEXT_TMP4.B
        PHA
        PLB
        ACC16
        PHD
        LDA     #0
        PHA
        PLD
.REPEAT 8 INDEX YOFF
        ACC8
        LDA     ($010000|FIXFONT_START).L,X
        XBA
        PHX
        LDA     7,S
        TAX
.REPEAT 6 INDEX XOFF
        TXA
        XBA
        ASL     A
        XBA
        BCC     +
        LDA     6,S   
+       STA     $00.B,Y
.IFLE XOFF 5
        INY
.ENDIF
.ENDR
        PLX
        ACC16
.IFLE YOFF 7
        INX
        TYA
        CLC
        ADC     #$0200-5
        TAY
.ENDIF
.ENDR
@ENDCHAR:
        PLD
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

.MACRO TEXT_SCROLL_DMA ARGS BANKS, SRCADDR, DSTADDR, COUNT, FLAGS
        ; use DMA 0 to move VRAM_CH and VRAM_CL up a row
        ACC16
        LDA     #SRCADDR.w
        STA     DMA0SRC.w
        LDA     #DSTADDR.w
        STA     DMA0DST.w
        LDA     #BANKS.w        ; bank setup
        STA     DMA0BNKS.w
        LDA     #COUNT.w        ; copy total of $1E00 - 80 bytes
        STA     DMA0CNT.w
        ACC8
        LDA     #$90|FLAGS.b    ; enable DMA
        STA     DMA0CTRL.w
-       BIT     DMA0STAT.w
        BMI     -
.ENDM

; on correct bank
TEXT_SCROLL_UP_LINE:
        XY16
        PHP
        ACC8
        PHB
        LDA     #$00            ; switch to bank 0 for easier DMA
        PHA
        PLB
        SEI                     ; disable interrupts

        ; use DMA 0 to move VRAM_CH and VRAM_CL up a row
        TEXT_SCROLL_DMA         $8080, TEXT_VRAM_CH+80, TEXT_VRAM_CH, $1DB0, 0

        ; make blank row in VRAM_CH and VRAM_CL
        LDX     #80
@XLOOP:
        DEX
        STZ     TEXT_VRAM_CL+47*80.W,X
        STZ     TEXT_VRAM_CH+47*80.W,X
        BNE     @XLOOP

        ; do VRAM scrolling DMA
        TEXT_SCROLL_DMA         $4040, $1000, $0000, $F000, 0
        TEXT_SCROLL_DMA         $4140, $0000, $F000, $1000, 0
        TEXT_SCROLL_DMA         $4141, $1000, $0000, $F000, 0
        TEXT_SCROLL_DMA         $4241, $0000, $F000, $1000, 0
        TEXT_SCROLL_DMA         $4242, $1000, $0000, $F000, 0
        TEXT_SCROLL_DMA         $8042, $FFFF&TEXT_BGCOLOR, $F000, $1000, 4

        PLB
        PLP

        RTS

TEXT_CURSOR_UPDATE:
        ACC16
        ;       bring out cursor on next update
        LDX     #$001F
        STX     TEXT_CURSORTICKS.W
        INC     TEXT_CURSORMOVED.W
        LDX     TEXT_CURSORX.W
        BMI     @GOUPLINE
        CPX     #80
        BCC     @NONEWLINE
        LDX     #0
        STX     TEXT_CURSORX.W
        INC     TEXT_CURSORY.W
@NONEWLINE:
        LDX     TEXT_CURSORY.W
        BMI     @GOUPLINE
        CPX     #48
        BCC     @OK
; we need to scroll up by line
        JSR     TEXT_SCROLL_UP_LINE.W
        LDX     #47
        STX     TEXT_CURSORY.W
@OK:
        RTS
@GOUPLINE:
        LDX     #79
        STX     TEXT_CURSORX.W
        DEC     TEXT_CURSORY.W
        BPL     @OK
        STX     TEXT_CURSORY.W
        BRA     @OK

; X, Y = coordinates
; A = character to write (should be 8-bit)
; A, X, Y clobbered
;       B must be $80
TEXT_WRITE_STRING_CHARACTER:
.ACCU 8
        STA     TEXT_TMP6.W
@NOSTA:
        CMP     #32.B
        BCC     @SPECIAL
        ACC16
@INNER:
        LDX     TEXT_CURSORX.W
        LDY     TEXT_CURSORY.W
        X_Y_TO_TEXT_VRAM_OFFSET
        ACC8
        LDA     TEXT_TMP6.W
        STA     TEXT_VRAM_CH.W,X
        LDA     TEXT_FGCOLOR.W
        STA     TEXT_VRAM_CL.W,X
        ACC16
        JSR     TEXT_UPDATE_CHARACTER_KNOWN_OFFSET
        INC     TEXT_CURSORX.W
        JMP     TEXT_CURSOR_UPDATE
        ;       leaves with ACC16
@SPECIAL:
        ACC16
        AND     #$00FF
        ASL     A
        TAX
        JMP     (TEXT_WRITE_SPECIAL_CHARS.W,X)

TEXT_WRITE_SPECIAL_CHARS:
        .DW     @NONE        ;  0 \NUL
        .DW     @NONE        ;  1 ???
        .DW     @NONE        ;  2 ???
        .DW     @NONE        ;  3 ???
        .DW     @NONE        ;  4 ???
        .DW     @NONE        ;  5 ???
        .DW     @NONE        ;  6 ???
        .DW     @NONE        ;  7 ???
        .DW     @BKSP        ;  8 BKSP
        .DW     @TAB         ;  9 TAB
        .DW     @CR          ; 10 LF
        .DW     @NONE        ; 11 ???
        .DW     @NONE        ; 12 ???
        .DW     @CR          ; 13 CR
        .DW     @NONE        ; 14 ???
        .DW     @NONE        ; 15 ???
        .DW     @NONE        ; 16 ???
        .DW     @NONE        ; 17 ???
        .DW     @NONE        ; 18 ???
        .DW     @NONE        ; 19 ???
        .DW     @NONE        ; 20 ???
        .DW     @NONE        ; 21 ???
        .DW     @NONE        ; 22 ???
        .DW     @NONE        ; 23 ???
        .DW     @NONE        ; 24 ???
        .DW     @NONE        ; 25 ???
        .DW     @NONE        ; 26 ???
        .DW     @NONE        ; 27 ???
        .DW     @AUP         ; 28 arrow up
        .DW     @ADN         ; 29 arrow down
        .DW     @ALT         ; 30 arrow left
        .DW     @ART         ; 31 arrow right

@NONE:
        JMP     TEXT_CURSOR_UPDATE
@CR:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        INC     TEXT_CURSORY.W
        LDX     #0
        STX     TEXT_CURSORX.W
        JMP     TEXT_CURSOR_UPDATE
@TAB:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        LDA     TEXT_CURSORX.W
        CLC
        ADC     #8
        AND     #$F8
        STA     TEXT_CURSORX.W
        JMP     TEXT_CURSOR_UPDATE
@BKSP:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        DEC     TEXT_CURSORX.W
        JSR     TEXT_CURSOR_UPDATE
        LDX     TEXT_CURSORX.W
        LDY     TEXT_CURSORY.W
        X_Y_TO_TEXT_VRAM_OFFSET
        ACC8
        STZ     TEXT_VRAM_CH.W,X
        ACC16
        JMP     TEXT_UPDATE_CHARACTER_KNOWN_OFFSET
@AUP:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        LDY     TEXT_CURSORY.W
        BEQ     +
        DEC     TEXT_CURSORY.W
+       JMP     TEXT_CURSOR_UPDATE
@ADN:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        LDY     TEXT_CURSORY.W
        CPY     #47
        BCS     +
        INC     TEXT_CURSORY.W
+       JMP     TEXT_CURSOR_UPDATE
@ALT:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        LDX     TEXT_CURSORX.W
        BNE     +
        LDY     TEXT_CURSORY.W
        BNE     +
        JMP     TEXT_CURSOR_UPDATE
+       DEC     TEXT_CURSORX.W
        JMP     TEXT_CURSOR_UPDATE
@ART:
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        LDX     TEXT_CURSORX.W
        CPX     #79
        BCC     +
        LDY     TEXT_CURSORY.W
        CPY     #47
        BCC     +
        JMP     TEXT_CURSOR_UPDATE
+       INC     TEXT_CURSORX.W
        JMP     TEXT_CURSOR_UPDATE

; A = character to write
; A, X, Y preserved
TEXT_WRITE_CHAR_AT_CURSOR:
        PHP    
        XY16
        ACC8
        STA     TEXT_TMP6.W
        ENTERTEXTRAM8
        LDA     TEXT_TMP6.W
        JSR     TEXT_WRITE_STRING_CHARACTER@NOSTA
        EXITTEXTRAM
        PLP
        RTS

TEXT_UPDATE_CHAR_AT_CURSOR:
        PHP    
        AXY16
        PHA
        PHX
        PHY
        ENTERTEXTRAM
        JSR     TEXT_UPDATE_CHARACTER_AT_CURSOR
        EXITTEXTRAM
        AXY16
        PLY
        PLX
        PLA
        PLP
        RTS

; X, Y = coordinates
; A, X, Y preserved
TEXT_MOVE_CURSOR:
        PHP
        AXY16
        PHA
        TXA
        AND     #$FF
        STA     TEXT_CURSORXL.L
        TYA
        AND     #$FF
        STA     TEXT_CURSORYL.L
        PHX
        PHY
        JSR     TEXT_CURSOR_UPDATE
        PLY
        PLX
        PLA
        PLP
        RTS

; X, Y = coordinates
; B:A = pointer to text, must end in 0
; A, X, Y preserved
TEXT_WRITE_STRING:
        JSR     TEXT_MOVE_CURSOR

; B:A = pointer to text, must end in 0
; A, X, Y preserved
TEXT_WRITE_STRING_AT_CURSOR:
        PHP
        CLD
        ACC16
        PHA
        PHX
        PHY
@NEXTCHAR:
        STA     TEXT_TMP5.L
        TAX
        ACC8
        LDA     0.W,X
        BEQ     @END
        STA     TEXT_TMP6L.L
@ENTERWCH:
        ENTERTEXTRAM8
        LDA     TEXT_TMP6.W
        JSR     TEXT_WRITE_STRING_CHARACTER
.ACCU 16
        EXITTEXTRAM
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

; flash cursor
; all registers preserved
TEXT_FLASH_CURSOR:
        PHP
        AXY16
        PHA
        ACC8
        ENTERTEXTRAM
        LDA     TEXT_CURSORMOVED.W
        BNE     @COULDREALLYFLASH
        LDA     KEYB_KEYDOWN.W
        BEQ     @REALLYFLASH
        STZ     TEXT_CURSORTICKS.W
        STZ     TEXT_CURSORON.W
        BRA     @RET
@COULDREALLYFLASH:
        STZ     TEXT_CURSORMOVED.W
@REALLYFLASH:
        LDA     TEXT_CURSORTICKS.W
        INC     A
        AND     #$3F
        STA     TEXT_CURSORTICKS.W
        BEQ     @BLINKCHAR
        CMP     #$20
        BEQ     @BLINKCHAR
@RET:   EXITTEXTRAM
        AXY16
        PLA
        PLP
        RTS
@BLINKCHAR:
.ACCU 8
        LDA     $FFFF&TEXT_BGCOLOR.W
        EOR     $FFFF&TEXT_FGCOLOR.W
        STA     TEXT_TMP5.W
        STA     TEXT_TMP5+1.W
        ACC16
        LDA     TEXT_CURSORX.W
        LDY     TEXT_CURSORY.W
        A_Y_TO_VIDEO_VRAM_OFFSET
        ACC8
        LDX     TEXT_TMP3.W
        PHB
        LDA     TEXT_TMP4.W
        PHA
        PLB
        ACC16
.REPEAT 8 INDEX OFFSETY
.REPEAT 3 INDEX OFFSETX
        LDA     $0000+OFFSETX*2+OFFSETY*512.W,X
        EOR     $800000|TEXT_TMP5.L
        STA     $0000+OFFSETX*2+OFFSETY*512.W,X
.ENDR
.ENDR
        PLB
        JMP     @RET

.ORG $3FE0
TEXT_UPDATE_CHAR_AT_CURSOR_TRAMPOLINE:
        JSR     TEXT_UPDATE_CHAR_AT_CURSOR.W
        RTL
.ORG $3FE4
TEXT_FLASH_CURSOR_TRAMPOLINE:
        JSR     TEXT_FLASH_CURSOR.W
        RTL
.ORG $3FE8
TEXT_CLEAR_BUFFER_TRAMPOLINE:
        JSR     TEXT_CLEAR_BUFFER.w
        RTL
.ORG $3FEC
TEXT_CLEAR_SCREEN_TRAMPOLINE:
        JSR     TEXT_CLEAR_SCREEN.w
        RTL
.ORG $3FF0
TEXT_WRITE_STRING_TRAMPOLINE:
        JSR     TEXT_WRITE_STRING.w
        RTL
.ORG $3FF4
TEXT_WRITE_CHAR_AT_CURSOR_TRAMPOLINE:
        JSR     TEXT_WRITE_CHAR_AT_CURSOR.w
        RTL
.ORG $3FF8
TEXT_WRITE_STRING_AT_CURSOR_TRAMPOLINE:
        JSR     TEXT_WRITE_STRING_AT_CURSOR.w
        RTL
.ORG $3FFC
TEXT_MOVE_CURSOR_TRAMPOLINE:
        JSR     TEXT_MOVE_CURSOR.w
        RTL

