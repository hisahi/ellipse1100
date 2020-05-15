; Ellipse Workstation 1100 (fictitious computer)
; ROM code (keyboard code)
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
.ORG $4000

; matrix code to ASCII key code conversion
; one row of 8 bytes is one column of matrix, starting from bit 0 to 7
; special codes: $80 CTRL $81 LShift $82 LAlt $83 Caps $84 Aux1
;                         $91 RShift $92 RAlt          $94 Aux2
;                $00 unconnected
KEYCODETABLE:
        .DB     $10, $60, $09, $80, $81, $83, $28, $2F
        .DB     $11, $31, $71, $61, $94, $82, $37, $39
        .DB     $12, $32, $77, $73, $7A, $20, $34, $36
        .DB     $13, $33, $65, $64, $78, $00, $31, $33
        .DB     $14, $34, $72, $66, $63, $00, $30, $00
        .DB     $15, $35, $74, $67, $76, $00, $00, $00
        .DB     $16, $36, $79, $68, $62, $00, $00, $00
        .DB     $17, $37, $75, $6A, $6E, $00, $00, $00
        .DB     $18, $38, $69, $6B, $6D, $00, $29, $2A
        .DB     $19, $39, $6F, $6C, $2C, $00, $38, $2D
        .DB     $1A, $30, $70, $3B, $2E, $00, $35, $2B
        .DB     $00, $2D, $5B, $27, $2F, $92, $32, $0D
        .DB     $00, $3D, $5D, $84, $00, $00, $00, $00
        .DB     $00, $7E, $00, $0D, $91, $00, $00, $00
        .DB     $00, $08, $00, $00, $1E, $00, $00, $00
        .DB     $00, $7F, $0E, $1C, $1F, $1D, $00, $00
; if shift held
KEYCODETABLE_SHIFT:
        .DB     $10, $7E, $09, $80, $81, $83, $28, $2F
        .DB     $11, $21, $51, $41, $94, $82, $37, $39
        .DB     $12, $40, $57, $53, $5A, $20, $34, $36
        .DB     $13, $23, $45, $44, $58, $00, $31, $33
        .DB     $14, $24, $52, $46, $43, $00, $30, $00
        .DB     $15, $25, $54, $47, $56, $00, $00, $00
        .DB     $16, $5E, $59, $48, $42, $00, $00, $00
        .DB     $17, $26, $55, $4A, $4E, $00, $00, $00
        .DB     $18, $2A, $49, $4B, $4D, $00, $29, $2A
        .DB     $19, $28, $4F, $4C, $3C, $00, $38, $2D
        .DB     $1A, $29, $50, $3A, $3E, $00, $35, $2B
        .DB     $00, $5F, $7B, $22, $3F, $92, $32, $0D
        .DB     $00, $2B, $7D, $84, $00, $00, $00, $00
        .DB     $00, $7C, $00, $0D, $91, $00, $00, $00
        .DB     $00, $08, $00, $00, $1E, $00, $00, $00
        .DB     $00, $7F, $0E, $1C, $1F, $1D, $00, $00
; if caps should apply to char code
KEYB_APPLY_CAPS_TO_KEY:
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,1,1,0,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,0,0,0,0
        .DB     0,0,1,0,0,0,0,0
        .DB     0,0,1,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0

.DEFINE KEYB_TMP3 $0EEE
.DEFINE KEYB_TMP2 $0EF0
.DEFINE KEYB_KEYDOWNX $0EF2
.DEFINE KEYB_TMP $0EF4
.DEFINE KEYB_NEWKEYPRESSED $0EF8
.DEFINE KEYB_NEWKEYPRESSEDL $800EF8
.DEFINE KEYB_KEYDOWNTICKS $0EFA
.DEFINE KEYB_KEYMODIFIER1 $0EFC         ; SC------ (shift, caps)
.DEFINE KEYB_KEYMODIFIER2 $0EFD         ; CA------ (ctrl, alt)
.DEFINE KEYB_KEYDOWN $0EFE
.DEFINE KEYB_KEYDOWNL $800EFE
; characters
.DEFINE KEYB_KEYCACHE $0F00

.MACRO ENTERKEYBRAM
        PHD
        PHB
        ACC8
        LDA     #$80
        PHA
        PLB
        ACC16
        LDA     #$0000
        TCD
.ENDM

.MACRO EXITKEYBRAM
        PLB
        PLD
.ENDM

; get currently pressed key in A
; supply value in A to check key repeat (higher value to repeat slower)
; supply value in X to apply new repeat value (if A=12, X=10
;                                               means 2 ticks to repeat again)
; carry set if it is a new key
; A will be set to 8-bit if it already isn't
KEYB_GET_PRESSED_KEY:
        ACC8
        CMP     $800000|KEYB_KEYDOWNTICKS.L
        BCS     +
        TXA
        STA     $800000|KEYB_KEYDOWNTICKS.L
        SEC
        BRA     ++
+       LDA     KEYB_NEWKEYPRESSEDL.L
        ASL     A
++      LDA     KEYB_KEYDOWNL.L
        RTS

; reset key data
KEYB_RESET_BUFFER:
        PHP
        AXY16
        ENTERKEYBRAM
        STZ     KEYB_KEYMODIFIER1.W
        STZ     KEYB_KEYDOWN.W
        STZ     KEYB_KEYDOWNTICKS.W
        STZ     TEXT_CURSORTICKS.W
        STZ     KEYB_KEYDOWNX.W
        DEC     KEYB_KEYDOWNX.W
        EXITKEYBRAM
        PLP
        RTS

; updates key buffers
; X, Y preserved, A clobbered
KEYB_UPDATE_KEYS:
        PHP
        AXY16
        ENTERKEYBRAM
        PHX
        PHY
        STZ     KEYB_NEWKEYPRESSED.W            ; set "new key pressed" to 0
        STZ     KEYB_KEYMODIFIER1.W             ; also KEYB_KEYMODIFIER2
        ACC8

; update modifiers (Ctrl, Shift, Alt, caps)
        LDA     KEYBMTRX.L                      ; bit 3 = Ctrl, bit 4 = LSh,
                                                ; bit 5 = Caps
        ASL     A
        ASL     A
        ASL     A
        BCC     @NOCAPS                         ; C = caps
        PHA
        LDA     KEYB_KEYMODIFIER1.W
        ORA     #$40                            ; caps: KM1 |= 0x40
        STA     KEYB_KEYMODIFIER1.W
        PLA
@NOCAPS:
        ASL     A
        BCC     @NOLSHIFT                       ; C = left shift
        PHA
        LDA     KEYB_KEYMODIFIER1.W
        ORA     #$80                            ; shift: KM1 |= 0x80
        STA     KEYB_KEYMODIFIER1.W
        PLA
@NOLSHIFT:
        ASL     A
        BCC     @NOCTRL                         ; C = ctrl
        LDA     KEYB_KEYMODIFIER2.W
        ORA     #$80                            ; ctrl: KM2 |= 0x80
        STA     KEYB_KEYMODIFIER2.W
@NOCTRL:
        LDA     KEYBMTRX+1.L                    ; bit 5 = LAlt
        AND     #$20
        BEQ     @NOLALT
        LDA     KEYB_KEYMODIFIER2.W
        ORA     #$40                            ; alt: KM2 |= 0x40
        STA     KEYB_KEYMODIFIER2.W
        BRA     @NORALT
@NOLALT:
        LDA     KEYBMTRX+11.L                   ; bit 5 = RAlt
        AND     #$20
        BEQ     @NORALT
        LDA     KEYB_KEYMODIFIER2.W
        ORA     #$40                            ; alt: KM2 |= 0x40
        STA     KEYB_KEYMODIFIER2.W
@NORALT:
        LDA     KEYBMTRX+13.L                   ; bit 4 = Rshift
        AND     #$10
        BEQ     @NORSHIFT
        LDA     KEYB_KEYMODIFIER1.W
        ORA     #$80                            ; shift: KM1 |= 0x80
        STA     KEYB_KEYMODIFIER1.W
@NORSHIFT:

; update main keyboard cache

        ACC8
        LDX     #15
@KEYLOOP:
        STX     KEYB_TMP3.W
        LDA     KEYBMTRX.L,X                    ; load A with key matrix value
        TAY
        TXA                                     ; \
        ASL     A                               ; |
        ASL     A                               ; |
        ASL     A                               ; |
        TAX                                     ; / X = X << 3
        STX     KEYB_TMP2.W
        TYA
.REPEAT 8
        LSR     A                           ; move lowest bit to C
        PHA                                     ; save old A (remaining bits)
        BIT     KEYB_KEYMODIFIER1               ; check if CAPS applies
        BVC     +                               ; move to (next) + if no caps
        LDA     KEYB_APPLY_CAPS_TO_KEY.L,X      ; <>$00 if caps should matter
        BEQ     +                               ; else skip to (next) +
        TXA                                     ; \
        EOR     #$80                            ; | X ^= 0x80
        TAX                                     ; /
+       BIT     KEYB_KEYMODIFIER1               ; check if SHIFT applies
        BPL     +                               ; move to (next) + if no shift
        TXA                                     ; \
        EOR     #$80                            ; | X ^= 0x80
        TAX                                     ; /
+       LDA     KEYCODETABLE.L,X                ; load key's ASCII code
        BEQ     ++++                            ; if 0, skip to store... 
        TAY                                     ; ...else put it in Y
        LDX     KEYB_TMP2.W                     ; restore original shifted X
        LDA     #0                              ; storing #0 to cache if key up
        ; the next instruction checks C which should still have the lowest bit
        BCC     +++                             ; key is not down? go to +++
        DEC     A                               ; A = #$FF. key is down
        CPY     #$0080                          ; if Y >= $0080
        BCS     ++++                            ; skip to cache store (++++)
        CPX     KEYB_KEYDOWNX.W                 ; is "current key" this key?
        BEQ     ++                              ; if it is, go to (next) ++
        LDA     KEYB_KEYCACHE.W,X               ; get old key cache value
        BNE     ++++                            ; key already down? go to ++++
        STZ     KEYB_KEYDOWNTICKS.W             ; zero out key down ticks
        STY     KEYB_KEYDOWN.W                  ; store new current key
        STX     KEYB_KEYDOWNX.W                 ; and "scan code"
        LDA     #$FF                            ; load #$FF again to store to
        STA     KEYB_NEWKEYPRESSED.W            ; "new key pressed"
        BRA     ++++                            ; skip some redundant insrts
++      INC     KEYB_KEYDOWNTICKS.W         ; increase key down ticks
        LDA     #$FF                            ; load #$FF again to store to
        BRA     ++++                            ; cache, and go to ++++
+++     CPX     KEYB_KEYDOWNX.W             ; key up is "current code"?
        BNE     ++++                            ; if not, skip
        STZ     KEYB_KEYDOWN.W                  ; \ zero out "current code"
        DEC     KEYB_KEYDOWNX+1.W               ; cur. "scan" = $FFxx (invalid)
++++    LDX     KEYB_TMP2.W                 ; restore original shifted X
        STA     KEYB_KEYCACHE.W,X               ; store $00 or $FF to cache
        PLA                                     ; restore remaining bits
        INX
        STX     KEYB_TMP2.W
.ENDR
        LDX     KEYB_TMP3.W                 ; restore unshifted X
        DEX
        BMI     @KEYLOOPEND
        JMP     @KEYLOOP
@KEYLOOPEND:
        PLY
        PLX
        EXITKEYBRAM
        PLP
        LDA     KEYB_KEYDOWNL.L
        RTS

.ORG $7FF4
KEYB_GET_PRESSED_KEY_TRAMPOLINE:
        JSR     KEYB_GET_PRESSED_KEY.W
        RTL
.ORG $7FF8
KEYB_RESET_BUFFER_TRAMPOLINE:
        JSR     KEYB_RESET_BUFFER.W
        RTL
.ORG $7FFC
KEYB_UPDATE_KEYS_TRAMPOLINE:
        JSR     KEYB_UPDATE_KEYS.W
        RTL
