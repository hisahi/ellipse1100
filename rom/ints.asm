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
        PLD
        PLB
        PLY
        PLX
        PLA
INTH_RTI:
        RTI

INTH_BRK:                       ; BRK native handler, jump to SW handler
        ACC8
        BIT     IN_SWAPBRK.W
        BMI     INTH_RTI
        AXY16
        CLD
        PHA
        PHX
        PHY
        PHB
        PHD
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002         ; load interrupt device number
        AND     #$FF.W
        JML     SWRAMBRK-1      ; jump to trampoline

INTH_NMI:                       ; NMI native handler, jump to SW handler
        ACC8
        BIT     IN_SWAPNMI.W
        BMI     INTH_RTI
        AXY16
        CLD
        PHA
        PHX
        PHY
        PHB
        PHD
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
        PHB
        PHD     
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002         ; load interrupt device number
        AND     #$FF.W
        JML     SWRAMIRQ-1      ; jump to trampoline

INTH_COP:                       ; COP native handler, ignore
INTH_E_COP:                     ; COP emulation handler, ignore
INTH_ABORT:                     ; ABORT native handler, ignore
INTH_E_ABORT:                   ; ABORT emulation handler, ignore
        RTI

INTH_E_BRK:                     ; BRK emulation handler
        CLD
        CLC
        XCE                     ; jump to native after disabling E
        PHK
        PEA     INTH_E_NMI_RET
        PHP
        JMP     INTH_BRK

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
; A = 16-bit addr to interrupt handler                          Y = bank
; X = 16-bit addr to where the previous interrupt handler       B = bank
;                              address will be stored
; A, X, Y clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPBRK:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPBRKL.L           ; / set SWAPBRK latch to >=$80
        ROL     A                       ; restore old A
        XY8                             ; 8-bit index registers
        PHY                             ; save old Y
        AXY16                           ; 16-bit A, X, Y
        TAY                             ; move A to Y, we will need that value
        CMP     SWRAMBRK.L              ; same as current int handler?
        BNE     @DIFFADDR               ; if not, just store as before
        ACC8                            ; 8-bit acc to check bank
        PLA                             ; restore original Y to A
        CMP     SWRAMBRK+2.L            ; same as old bank?
        BEQ     @EXIT                   ; if so, just exit
        PHA                             ; else push it back as we'll PLA later
        ACC16                           ; 16-bit acc to continue
@DIFFADDR:
        LDA     SWRAMBRK.L              ; get old 16-bit int handler addr
        STA     $0000.W,X               ; store at B:(X)
        TYA                             ; restore old A value
        STA     SWRAMBRK.L              ; set new 16-bit int handler addr
        ACC8                            ; 8-bit A again
        LDA     SWRAMBRK+2.L            ; get old int handler bank
        STA     $0002.W,X               ; store at B:(X+2)
        PLA                             ; restore original Y to A
        STA     SWRAMBRK+2.L            ; set new int handler bank
@EXIT   LDA     #0                      ; \
        STA     IN_SWAPBRKL.L           ; / zero SWAPBRK latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FCC0
; restore old BRK handler from B:X
UNSWAPBRK:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPBRKL.L           ; / set SWAPBRK latch to >=$80
        ROL     A                       ; restore old A
        AXY16                           ; 16-bit A, X, Y
        LDA     $0000.W,X               ; get addr at B:X
        STA     SWRAMBRK.L              ; set new int handler address
        ACC8                            ; 8-bit A to get/set bank
        LDA     $0002.W,X               ; get bank at B:(X+2)
        STA     SWRAMBRK+2.L            ; set new int handler bank
        LDA     #0                      ; \
        STA     IN_SWAPBRKL.L           ; / zero SWAPBRK latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FD00
; A = 16-bit addr to interrupt handler                          Y = bank
; X = 16-bit addr to where the previous interrupt handler       B = bank
;                              address will be stored
; A, X, Y clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPNMI:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPNMIL.L           ; / set SWAPNMI latch to >=$80
        ROL     A                       ; restore old A
        XY8                             ; 8-bit index registers
        PHY                             ; save old Y
        AXY16                           ; 16-bit A, X, Y
        TAY                             ; move A to Y, we will need that value
        CMP     SWRAMNMI.L              ; same as current int handler?
        BNE     @DIFFADDR               ; if not, just store as before
        ACC8                            ; 8-bit acc to check bank
        PLA                             ; restore original Y to A
        CMP     SWRAMNMI+2.L            ; same as old bank?
        BEQ     @EXIT                   ; if so, just exit
        PHA                             ; else push it back as we'll PLA later
        ACC16                           ; 16-bit acc to continue
@DIFFADDR:
        LDA     SWRAMNMI.L              ; get old 16-bit int handler addr
        STA     $0000.W,X               ; store at B:(X)
        TYA                             ; restore old A value
        STA     SWRAMNMI.L              ; set new 16-bit int handler addr
        ACC8                            ; 8-bit A again
        LDA     SWRAMNMI+2.L            ; get old int handler bank
        STA     $0002.W,X               ; store at B:(X+2)
        PLA                             ; restore original Y to A
        STA     SWRAMNMI+2.L            ; set new int handler bank
@EXIT   LDA     #0                      ; \
        STA     IN_SWAPNMIL.L           ; / zero SWAPNMI latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FDC0
; restore old NMI handler from B:X
UNSWAPNMI:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPNMIL.L           ; / set SWAPNMI latch to >=$80
        ROL     A                       ; restore old A
        AXY16                           ; 16-bit A, X, Y
        LDA     $0000.W,X               ; get addr at B:X
        STA     SWRAMNMI.L              ; set new int handler address
        ACC8                            ; 8-bit A to get/set bank
        LDA     $0002.W,X               ; get bank at B:(X+2)
        STA     SWRAMNMI+2.L            ; set new int handler bank
        LDA     #0                      ; \
        STA     IN_SWAPNMIL.L           ; / zero SWAPNMI latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FE00
; A = 16-bit addr to interrupt handler                          Y = bank
; X = 16-bit addr to where the previous interrupt handler       B = bank
;                              address will be stored
; A, X, Y clobbered
;       NEW INT ROUTINE MUST JMP [...] INTO WHEREVER X POINTS!!!
SWAPIRQ:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPIRQL.L           ; / set SWAPIRQ latch to >=$80
        ROL     A                       ; restore old A
        XY8                             ; 8-bit index registers
        PHY                             ; save old Y
        AXY16                           ; 16-bit A, X, Y
        TAY                             ; move A to Y, we will need that value
        CMP     SWRAMIRQ.L              ; same as current int handler?
        BNE     @DIFFADDR               ; if not, just store as before
        ACC8                            ; 8-bit acc to check bank
        PLA                             ; restore original Y to A
        CMP     SWRAMIRQ+2.L            ; same as old bank?
        BEQ     @EXIT                   ; if so, just exit
        PHA                             ; else push it back as we'll PLA later
        ACC16                           ; 16-bit acc to continue
@DIFFADDR:
        LDA     SWRAMIRQ.L              ; get old 16-bit int handler addr
        STA     $0000.W,X               ; store at B:(X)
        TYA                             ; restore old A value
        STA     SWRAMIRQ.L              ; set new 16-bit int handler addr
        ACC8                            ; 8-bit A again
        LDA     SWRAMIRQ+2.L            ; get old int handler bank
        STA     $0002.W,X               ; store at B:(X+2)
        PLA                             ; restore original Y to A
        STA     SWRAMIRQ+2.L            ; set new int handler bank
@EXIT   LDA     #0                      ; \
        STA     IN_SWAPIRQL.L           ; / zero SWAPIRQ latch
        PLP                             ; restore old P
        RTL                             ; return

.org $FEC0
; restore old IRQ handler from B:X
UNSWAPIRQ:
        PHP                             ; save old P
        SEI                             ; disable IRQs just in case
        ACC8                            ; 8-bit accumulator
        SEC                             ; \
        ROR     A                       ; |
        STA     IN_SWAPIRQL.L           ; / set SWAPIRQ latch to >=$80
        ROL     A                       ; restore old A
        AXY16                           ; 16-bit A, X, Y
        LDA     $0000.W,X               ; get addr at B:X
        STA     SWRAMIRQ.L              ; set new int handler address
        ACC8                            ; 8-bit A to get/set bank
        LDA     $0002.W,X               ; get bank at B:(X+2)
        STA     SWRAMIRQ+2.L            ; set new int handler bank
        LDA     #0                      ; \
        STA     IN_SWAPIRQL.L           ; / zero SWAPIRQ latch
        PLP                             ; restore old P
        RTL                             ; return
