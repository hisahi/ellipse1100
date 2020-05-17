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

.ORG $4000

.DEFINE KEYBIO $7010

; KEYCODETABLE, KEYB_APPLY_CAPS_TO_KEY in keytbls.asm

.DEFINE KEYB_TMP_NMI $0EEA
.DEFINE KEYB_NMI_TIMER $0EEC
.DEFINE KEYB_TMP3 $0EEE
.DEFINE KEYB_TMP2 $0EF0
.DEFINE KEYB_KEYDOWNX $0EF2
.DEFINE KEYB_TMP $0EF4
.DEFINE KEYB_NEWKEYPRESSED $0EF8
.DEFINE KEYB_NEWKEYPRESSEDL ($800000|KEYB_NEWKEYPRESSED)
.DEFINE KEYB_KEYDOWNTICKS $0EFA
.DEFINE KEYB_KEYMODIFIER1 $0EFC         ; SC------ (shift, caps)
.DEFINE KEYB_KEYMODIFIER2 $0EFD         ; CA------ (ctrl, alt)
.DEFINE KEYB_KEYDOWN $0EFE
.DEFINE KEYB_KEYDOWNL ($800000|KEYB_KEYDOWN)
; characters
.DEFINE KEYB_KEYCACHE $0F00

.MACRO ENTERKEYBRAM
        PHB
        PHD
        ACC8
        LDA     #$00
        PHA
        PLB
        ACC16
        LDA     #$0E00
        TCD
.ENDM

.MACRO EXITKEYBRAM
        PLD
        PLB
.ENDM

; get currently pressed key in A
; supply value in A to check key repeat (higher value to repeat slower)
; supply value in X to apply new repeat value (if A=12, X=10
;                                               means 2 ticks to repeat again)
; carry set if it is a new key
; A is set to be 8-bit!
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

KEYB_INC_NMI_TIMER:
        PHP
        ACC8
        LDA     #$01
        STA     KEYB_NMI_TIMER.L
        PLP
        RTS

; returns A 00000000ScCA0000
;                   Shift, caps, Ctrl, Alt
KEYB_GET_MODIFIERS:
        PHP
        ACC16
        LDA     #0
        ACC8
        LDA     $800000|KEYB_KEYMODIFIER2.L
        LSR     A
        LSR     A
        ORA     $800000|KEYB_KEYMODIFIER2.L
        PLP
        RTS

KEYB_UPDATE_KEYS:
        PHP
        AXY16
        ENTERKEYBRAM
        DEC     KEYB_NMI_TIMER&$FF.B
        BRA     KEYB_UPDATE_KEYS_IMMEDIATE@INNER
; updates key buffers
; X, Y preserved, A clobbered
KEYB_UPDATE_KEYS_IMMEDIATE:
        PHP
        AXY16
        ENTERKEYBRAM
@INNER:
        PHX
        PHY
        STZ     KEYB_NEWKEYPRESSED&$FF.B        ; set "new key pressed" to 0
        STZ     KEYB_KEYMODIFIER1&$FF.B         ; also KEYB_KEYMODIFIER2
        LDA     #0
        ACC8

        LDA     KEYB_NMI_TIMER&$FF.B
        STA     KEYB_TMP_NMI&$FF.B

; update modifiers (Ctrl, Shift, Alt, caps)
        LDA     KEYBIO.W                        ; bit 3 = Ctrl, bit 4 = LSh,
                                                ; bit 5 = Caps
        ASL     A
        ASL     A
        ASL     A
        BCC     @NOCAPS                         ; C = caps
        PHA
        LDA     KEYB_KEYMODIFIER1&$FF.B
        ORA     #$40                            ; caps: KM1 |= 0x40
        STA     KEYB_KEYMODIFIER1&$FF.B
        PLA
@NOCAPS:
        ASL     A
        BCC     @NOLSHIFT                       ; C = left shift
        PHA
        LDA     KEYB_KEYMODIFIER1&$FF.B
        ORA     #$80                            ; shift: KM1 |= 0x80
        STA     KEYB_KEYMODIFIER1&$FF.B
        PLA
@NOLSHIFT:
        ASL     A
        BCC     @NOCTRL                         ; C = ctrl
        LDA     KEYB_KEYMODIFIER2&$FF.B
        ORA     #$80                            ; ctrl: KM2 |= 0x80
        STA     KEYB_KEYMODIFIER2&$FF.B
@NOCTRL:
        LDA     KEYBIO+1.W                      ; bit 5 = LAlt
        AND     #$20
        BEQ     @NOLALT
        LDA     KEYB_KEYMODIFIER2&$FF.B
        ORA     #$40                            ; alt: KM2 |= 0x40
        STA     KEYB_KEYMODIFIER2&$FF.B
        BRA     @NORALT
@NOLALT:
        LDA     KEYBIO+11                       ; bit 5 = RAlt
        AND     #$20
        BEQ     @NORALT
        LDA     KEYB_KEYMODIFIER2&$FF.B
        ORA     #$40                            ; alt: KM2 |= 0x40
        STA     KEYB_KEYMODIFIER2&$FF.B
@NORALT:
        LDA     KEYBIO+13                       ; bit 4 = Rshift
        AND     #$10
        BEQ     @NORSHIFT
        LDA     KEYB_KEYMODIFIER1&$FF.B
        ORA     #$80                            ; shift: KM1 |= 0x80
        STA     KEYB_KEYMODIFIER1&$FF.B
@NORSHIFT:

; update main keyboard cache

        ACC8
        LDX     #15
@KEYLOOP:
        STX     KEYB_TMP3&$FF.B
        LDA     KEYBIO.W,X                      ; load A with key matrix value
        TAY
        TXA                                     ; \
        ASL     A                               ; |
        ASL     A                               ; |
        ASL     A                               ; |
        TAX                                     ; / X = X << 3
        STX     KEYB_TMP2&$FF.B
        TYA
.REPEAT 8
        LSR     A                           ; move lowest bit to C
        STA     KEYB_TMP&$FF.B                  ; save old A (remaining bits)
        BIT     KEYB_KEYMODIFIER1&$FF.B         ; check if CAPS applies
        BVC     +                               ; move to (next) + if no caps
        LDA     KEYB_APPLY_CAPS_TO_KEY.W,X      ; <>$00 if caps should matter
        BEQ     +                               ; else skip to (next) +
        TXA                                     ; \
        EOR     #$80                            ; | X ^= 0x80
        TAX                                     ; /
+       BIT     KEYB_KEYMODIFIER1&$FF.B         ; check if SHIFT applies
        BPL     +                               ; move to (next) + if no shift
        TXA                                     ; \
        EOR     #$80                            ; | X ^= 0x80
        TAX                                     ; /
+       LDA     KEYCODETABLE.W,X                ; load key's ASCII code
        BEQ     ++++                            ; if 0, skip to store... 
        TAY                                     ; ...else put it in Y
        LDX     KEYB_TMP2&$FF.B                 ; restore original shifted X
        LDA     #0                              ; storing #0 to cache if key up
        ; the next instruction checks C which should still have the lowest bit
        BCC     +++                             ; key is not down? go to +++
        DEC     A                               ; A = #$FF. key is down
        CPY     #$0080                          ; if Y >= $0080
        BCS     ++++                            ; skip to cache store (++++)
        CPX     KEYB_KEYDOWNX&$FF.B             ; is "current key" this key?
        BEQ     +                               ; if it is, go to (next) +
        LDA     KEYB_KEYCACHE.W,X               ; get old key cache value
        BNE     ++++                            ; key already down? go to ++++
        STZ     KEYB_KEYDOWNTICKS&$FF.B         ; zero out key down ticks
        STY     KEYB_KEYDOWN&$FF.B              ; store new current key
        STX     KEYB_KEYDOWNX&$FF.B             ; and "scan code"
        LDA     #$FF                            ; load #$FF again to store to
        STA     KEYB_NEWKEYPRESSED&$FF.B        ; "new key pressed"
        BRA     _f                              ; skip some redundant insrts
+       LDA     KEYB_TMP_NMI&$FF.B          ; check NMI timer
        BEQ     ++                              ; increase key down ticks
__      INC     KEYB_KEYDOWNTICKS&$FF.B         ; only if NMI timer <>0
++      LDA     #$FF                            ; load #$FF again to store to
        BRA     ++++                            ; cache, and go to ++++
+++     CPX     KEYB_KEYDOWNX&$FF.B         ; key up is "current code"?
        BNE     ++++                            ; if not, skip
        STZ     KEYB_KEYDOWN&$FF.B              ; \ zero out "current code"
        DEC     (KEYB_KEYDOWNX+1)&$FF.B         ; cur. "scan" = $FFxx (invalid)
++++    LDX     KEYB_TMP2&$FF.B             ; restore original shifted X
        STA     KEYB_KEYCACHE.W,X               ; store $00 or $FF to cache
        LDA     KEYB_TMP&$FF.B                  ; restore remaining bits
        INX
        STX     KEYB_TMP2&$FF.B
.ENDR
        LDX     KEYB_TMP3&$FF.B             ; restore unshifted X
        DEX
        BMI     @KEYLOOPEND
        JMP     @KEYLOOP
@KEYLOOPEND:
        PLY
        PLX
        STZ     KEYB_NMI_TIMER&$FF.B
        EXITKEYBRAM
        PLP
        RTS

.ORG $7FE8
KEYB_GET_MODIFIERS_TRAMPOLINE:
        JSR     KEYB_GET_MODIFIERS.W
        RTL
.ORG $7FEC
KEYB_INC_NMI_TIMER_TRAMPOLINE:
        JSR     KEYB_INC_NMI_TIMER.W
        RTL
.ORG $7FF0
KEYB_UPDATE_KEYS_IMMEDIATE_TRAMPOLINE:
        JSR     KEYB_UPDATE_KEYS_IMMEDIATE.W
        RTL
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
