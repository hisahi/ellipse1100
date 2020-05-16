; Ellipse Workstation 1100 (fictitious computer)
; ROM code (interrupt handlers)
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

.DEFINE IN_SWAPBRK $0E80
.DEFINE IN_SWAPIRQ $0E82
.DEFINE IN_SWAPNMI $0E84

.DEFINE IN_SWAPBRKL $800E80
.DEFINE IN_SWAPIRQL $800E82
.DEFINE IN_SWAPNMIL $800E84

INTH_RET:
        AXY16
        PLY
        PLX
        PLA
INTH_RTI:
        RTI

INTH_NMI:                       ; NMI native handler, jump to SW handler
        ACC8
        BIT     IN_SWAPNMI.W
        BMI     INTH_RTI
        AXY16
        CLD
        PHA
        PHX
        PHY
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002         ; load interrupt device number
        AND     #$FF.W
        JML     SWRAMNMI-1      ; jump to trampoline
INTH_IRQ:                       ; IRQ native handler, jump to SW handler
        ACC8
        BIT     IN_SWAPIRQ.W
        BMI     INTH_RTI
        AXY16
        CLD
        PHA
        PHX
        PHY          
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002         ; load interrupt device number
        AND     #$FF.W
        JML     SWRAMIRQ-1      ; jump to trampoline

INTH_COP:                       ; COP native handler, ignore
INTH_E_COP:                     ; COP emulation handler, ignore
INTH_BRK:                       ; BRK native handler, ignore
INTH_E_BRK:                     ; BRK emulation handler, ignore
INTH_ABORT:                     ; ABORT native handler, ignore
INTH_E_ABORT:                   ; ABORT emulation handler, ignore
        RTI

INTH_E_NMI:                     ; NMI emulation handler
        CLD
        CLC
        XCE                     ; jump to native after disabling E
        PHK
        PEA     INTH_E_NMI_RET
        PHP
        JMP     INTH_NMI
INTH_E_NMI_RET:
        SEC
        XCE
        RTI

INTH_E_IRQ:                     ; IRQ emulation handler
        CLD
        CLC
        XCE                     ; jump to native after disabling E
        PHK
        PEA     INTH_E_NMI_RET
        PHP
        JMP     INTH_IRQ

.org $FC00
; A = 16-bit addr to interrupt handler
; X = 16-bit addr to where the previous interrupt handler
;                              address will be stored
; Y = bank for both A and X (shared between the two, high byte ignored)
; all three clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPBRK:
        PHP                             ; save old P
        PHB                             ; save old data bank
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPBRKL.L           ; / set SWAPBRK latch to >=$80
        ROL     A                       ; restore old A
        XY8                             ; 8-bit index registers
        PHY                             ; move bank from Y
        PLB                             ; to the data bank register
        AXY16                           ; 16-bit A, X, Y
        TAY                             ; move A to Y, we will need that value
        LDA     SWRAMBRK.L              ; get old 16-bit int handler addr
        STA     $0000.W,X               ; store at B:(X)
        TYA                             ; restore old A value
        STA     SWRAMBRK.L              ; set new 16-bit int handler addr
        ACC8                            ; 8-bit A again
        LDA     SWRAMBRK+2.L            ; get old int handler bank
        STA     $0002.W,X               ; store at B:(X+2)
        PHB                             ; move current data bank (original Y)
        PLA                             ;     to register A
        STA     SWRAMBRK+2.L            ; set new int handler bank
        PLB                             ; restore old data bank
        LDA     #0                      ; \
        STA     IN_SWAPBRKL.L           ; / zero SWAPBRK latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FD00
; A = 16-bit addr to interrupt handler
; X = 16-bit addr to where the previous interrupt handler
;                              address will be stored
; Y = bank for both A and X (shared between the two, high byte ignored)
; all three clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPNMI:                ; see SWAPBRK for comments
        PHP
        PHB
        SEI
        ACC8
        SEC
        ROR     A
        STA     IN_SWAPNMIL.L
        ROL     A
        XY8
        PHY
        PLB
        AXY16
        TAY
        LDA     SWRAMNMI.L
        STA     $0000.W,X
        TYA
        STA     SWRAMNMI.L
        ACC8
        LDA     SWRAMNMI+2.L
        STA     $0002.W,X
        PHB
        PLA
        STA     SWRAMNMI+2.L
        PLB
        LDA     #0
        STA     IN_SWAPNMIL.L
        PLP
        RTL

.org $FE00
; A = 16-bit addr to interrupt handler
; X = 16-bit addr to where the previous interrupt handler
;                              address will be stored
; Y = bank for both A and X (shared between the two, high byte ignored)
; all three clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPIRQ:                ; see SWAPBRK for comments
        PHP
        PHB
        SEI
        ACC8
        SEC
        ROR     A
        STA     IN_SWAPIRQL.L
        ROL     A
        XY8
        PHY
        PLB
        AXY16
        TAY
        LDA     SWRAMIRQ.L
        STA     $0000.W,X
        TYA
        STA     SWRAMIRQ.L
        ACC8
        LDA     SWRAMIRQ+2.L
        STA     $0002.W,X
        PHB
        PLA
        STA     SWRAMIRQ+2.L
        PLB
        LDA     #0
        STA     IN_SWAPIRQL.L
        PLP
        RTL
